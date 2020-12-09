module Viewport exposing 
  ( Viewport, initialize
  , getWidth, getHeight
  , getViewbox
  , getPanningAttributes
  , PanningAttributes
  , getState, State
  , startMove, move
  , stopMove, changeZoom 
  , updateSvgContainerDimensions
  )

import Note

type Viewport = Viewport Info
getInfo : Viewport -> Info
getInfo viewport =
  case viewport of 
    Viewport info -> info
type alias Info = 
  { state : State
  , viewbox : Viewbox
  , svgContainer : SvgContainer
  }
type State = Moving MouseEvent | Stationary
type alias Viewbox = 
  { minX: Int
  , minY: Int
  , width: Int
  , height: Int
  }
type alias SvgContainer = { width : Int, height : Int }

initialize : SvgContainer -> Viewport
initialize container =
  Viewport <| Info
    Stationary
    (initializeViewbox container)
    container

getSvgContainerWidth : Viewport -> String
getSvgContainerWidth viewport =
  String.fromInt <| width <| svgContainer <| getInfo viewport

getSvgContainerHeight : Viewport -> String
getSvgContainerHeight viewport =
  String.fromInt <| height <| svgContainer <| getInfo viewport

getViewbox : Viewport -> String
getViewbox viewport =
  let
      box = viewbox <| getInfo viewport
  in
  String.fromInt box.minX ++ " " ++  String.fromInt box.minY ++ " " ++  String.fromInt box.width ++ " " ++  String.fromInt box.height

type alias PanningAttributes =
  { bottomRight : String
  , outerWidth : String
  , outerHeight : String
  , innerWidth : String
  , innerHeight : String
  , innerStyle : String
  , innerTransform : String
  }
getPanningAttributes : Viewport -> (List Note.Note) -> ( Maybe PanningAttributes )
getPanningAttributes viewport notes =
  let
      maybeExtremes = getNotePositionExtremes notes
      info = getInfo viewport
  in
  case maybeExtremes of
    Just extremes ->
      if allNotesInView extremes info.viewbox then
        let
            outerWidth = viewbox.height // 4
            outerHeight = outerWidth
            padding = viewbox.height // 20
            xTranslation = (viewboxMaxX viewbox) - ( outerWidth + padding )
            yTranslation = ( viewboxMaxY viewbox ) - ( outerHeight + padding )
            totalXLength = extremes.maxX - extremes.minX
            totalYLength = extremes.maxY - extremes.minY

            xScalingFactor = outerWidth / totalXLength
            yScalingFactor = outerHeight / totalYLength
        in
        Just <| PanningAttributes
          "translate(" ++ String.fromInt xTranslation ++ "," ++ String.fromInt yTranslation ++ ")"
          ( String.fromInt outerWidth )
          ( String.fromInt outerHeight )
          ( info.viewbox.width * xScalingFactor )
          ( info.viewbox.height * yScalingFactor )
          "fill:rgb(220,220,220);stroke-width:3;stroke:rgb(0,0,0);"
          ( "translate(" 
            ++ (String.fromInt <| info.viewbox.minX * xScalingFactor) 
            ++ "," 
            ++ (String.fromInt <| info.viewbox.minY * yScalingFactor)
            ++ ")" 
          )
      else 
        Nothing
    Nothing -> Nothing

getState : Viewport -> State
getState viewport =
  state <| getInfo viewport

startMove : MouseEvent -> Viewport -> Viewport
startMove event viewport =
  let
      info = getInfo viewport
  in
  case info.state of
    Stationary -> Viewport { info | state = Moving event }
    _ -> viewport
  
move : MouseEvent -> ( List Note.Note ) -> Viewport -> Viewport
move currentMouseEvent notes viewport =
  let
      info = getInfo viewport
  in
  case info.state of
    Moving previousMouseEvent -> 
      if allNotesInView extremes info.viewbox then
        viewport
      else
        Viewport { info | viewbox = shiftViewbox previousMouseEvent currentMouseEvent extremes viewbox }
    _ -> viewport

stopMove : Viewport -> Viewport
stopMove viewport =
  let
      info = getInfo viewport
  in
  case info.state of
    Moving _ -> Viewport { info | state = Stationary }
    _ -> viewport

-- TODO
-- changeZoom : WheelEvent -> ( List Note.Note ) -> Viewport -> Viewport

updateSvgContainerDimensions : SvgContainer -> Viewport -> Viewport
updateSvgContainerDimensions svgContainer viewport =
  let
      info = getInfo viewport
  in
  Viewport { info | svgContainer = svgContainer }

-- HELPER
initializeViewbox : SvgContainer -> Viewbox
initializeViewbox container =
 Viewbox (negate (container.width // 2)) (negate (container.height // 2)) container.width container.height

type alias PositionExtremes =
  { minX : Double
  , minY : Double
  , maxX : Double
  , maxY : Double
  }
getNotePositionExtremes : ( List Note.Note ) -> (Maybe PositionExtremes)
getNotePositionExtremes notes =
  let
      xList = List.map Note.getX notes
      yList = List.map Note.getY notes
    
  in
  Maybe.map4 
    PositionExtremes
    ( List.minimum xList )
    ( List.minimum yList )
    ( List.maximum xList )
    ( List.maximum yList )

allNotesInView : PositionExtremes -> Viewbox -> Bool
allNotesInView extremes viewbox =
  let
      noNotesLeftOfViewbox = viewbox.minX < extremes.minX
      noNotesRightOfViewbox = viewboxMaxX viewbox > extremes.maxX
      noNotesAboveViewbox = viewbox.minY < extremes.minY
      noNotesBelowViewbox = viewboxMaxY viewbox > extremes.maxY
  in
  noNotesLeftOfViewbox || noNotesRightOfViewbox || noNotesAboveViewbox || noNotesBelowViewbox

viewboxMaxX : Viewbox -> Int
viewboxMaxX viewbox =
  viewbox.minX + viewbox.width

viewboxMaxY : Viewbox -> Int
viewboxMaxY viewbox =
  viewbox.minY + viewbox.length

shiftViewbox : MouseEvent -> MouseEvent -> PositionExtremes -> Viewbox -> Viewbox
shiftViewbox currentMouseEvent previousMouseEvent extremes viewbox =
  let
    xChange = (previousMouseEvent.offsetX - currentMouseEvent.offsetX)
    yChange = (previousMouseEvent.offsetY - currentMouseEvent.offsetY)
    xMinBound = Int.min extremes.minX viewbox.minX
    xMaxBound = Int.max extremes.maxX <| viewboxMaxX viewbox
    yMinBound = Int.min extremes.minY viewbox.minY
    yMaxBound = Int.max extremes.maxY <| viewboxMaxY viewbox
  in
  { viewbox | minX = shiftPointWithBounds xMinBound xMaxBound <| viewbox.minX - xChange
  , minY = shiftPointWithBounds yMinBound yMaxBound <| viewbox.minY - yChange
  } 

shiftPointWithBounds : Int -> Int -> Int -> Int
shiftPointWithBounds lowerBound upperBound pointAfterShift =
  let
      belowLowerBound = pointAfterShift <= xMin
      aboveUpperBound = pointAfterShift >= upperBound 
  in 
  if belowLowerBound then
    lowerBound
  else if aboveUpperBound then
    upperBound
  else
    pointAfterShift