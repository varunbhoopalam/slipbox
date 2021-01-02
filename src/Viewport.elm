module Viewport exposing 
  ( Viewport
  , initialize
  , getViewbox
  , getPanningAttributes
  , PanningAttributes
  , getState
  , State(..)
  , startMove
  , move
  , stopMove
  , updateSvgContainerDimensions
  , MouseEvent
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
  }

type alias MouseEvent =
  { offsetX : Int
  , offsetY : Int
  }

type State = Moving MouseEvent | Stationary

type alias Viewbox =
  { minX: Int
  , minY: Int
  , width: Int
  , height: Int
  }

initialize : Viewport
initialize =
  Viewport <| Info
    Stationary
    initializeViewbox

getViewbox : Viewport -> String
getViewbox viewport =
  let
      box = .viewbox <| getInfo viewport
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
      viewbox = info.viewbox
  in
  case maybeExtremes of
    Just extremes ->
      if not <| allNotesInView extremes viewbox then
        let
            outerWidth = viewbox.height // 4
            outerHeight = outerWidth
            padding = viewbox.height // 20
            xTranslation = (viewboxMaxX viewbox) - ( outerWidth + padding )
            yTranslation = ( viewboxMaxY viewbox ) - ( outerHeight + padding )
            totalXLength = floor <| extremes.maxX - extremes.minX
            totalYLength = floor <| extremes.maxY - extremes.minY

            xScalingFactor = outerWidth // totalXLength
            yScalingFactor = outerHeight // totalYLength
        in
        Just <| PanningAttributes
          ( "translate(" ++ String.fromInt xTranslation ++ "," ++ String.fromInt yTranslation ++ ")" )
          ( String.fromInt outerWidth )
          ( String.fromInt outerHeight )
          ( String.fromInt <| info.viewbox.width // xScalingFactor )
          ( String.fromInt <| info.viewbox.height // yScalingFactor )
          "fill:rgb(220,220,220);stroke-width:3;stroke:rgb(0,0,0);"
          ( "translate(" 
            ++ (String.fromInt <| info.viewbox.minX // xScalingFactor)
            ++ "," 
            ++ (String.fromInt <| info.viewbox.minY // yScalingFactor)
            ++ ")" 
          )
      else 
        Nothing
    Nothing -> Nothing

getState : Viewport -> State
getState viewport =
  .state <| getInfo viewport

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
      maybeExtremes = getNotePositionExtremes notes
  in
  case info.state of
    Moving previousMouseEvent ->
      case maybeExtremes of
        Just extremes ->
          Viewport { info | viewbox = shiftViewbox previousMouseEvent currentMouseEvent extremes info.viewbox }
        Nothing -> viewport
    _ -> viewport

stopMove : Viewport -> Viewport
stopMove viewport =
  let
      info = getInfo viewport
  in
  case info.state of
    Moving _ -> Viewport { info | state = Stationary }
    _ -> viewport

updateSvgContainerDimensions : ( Int, Int ) -> Viewport -> Viewport
updateSvgContainerDimensions ( width, height ) viewport =
  case viewport of
    Viewport info ->
      let
        viewbox = info.viewbox
      in
      Viewport { info | viewbox = { viewbox | width = width, height = height } }


-- HELPER
initializeViewbox : Viewbox
initializeViewbox =
  let
    initialWidth = 400
    initialHeight = 400
  in
  Viewbox (negate (initialWidth // 2)) (negate (initialHeight // 2)) initialWidth initialHeight

type alias PositionExtremes =
  { minX : Float
  , minY : Float
  , maxX : Float
  , maxY : Float
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
      noNotesLeftOfViewbox = viewbox.minX < floor extremes.minX
      noNotesRightOfViewbox = viewboxMaxX viewbox > floor extremes.maxX
      noNotesAboveViewbox = viewbox.minY < floor extremes.minY
      noNotesBelowViewbox = viewboxMaxY viewbox > floor extremes.maxY
  in
  noNotesLeftOfViewbox || noNotesRightOfViewbox || noNotesAboveViewbox || noNotesBelowViewbox

viewboxMaxX : Viewbox -> Int
viewboxMaxX viewbox =
  viewbox.minX + viewbox.width

viewboxMaxY : Viewbox -> Int
viewboxMaxY viewbox =
  viewbox.minY + viewbox.height

shiftViewbox : MouseEvent -> MouseEvent -> PositionExtremes -> Viewbox -> Viewbox
shiftViewbox currentMouseEvent previousMouseEvent extremes viewbox =
  let
    xChange = (previousMouseEvent.offsetX - currentMouseEvent.offsetX)
    yChange = (previousMouseEvent.offsetY - currentMouseEvent.offsetY)
    xMinBound = min ( floor extremes.minX ) viewbox.minX
    xMaxBound = max ( floor extremes.maxX ) <| viewboxMaxX viewbox
    yMinBound = min ( floor extremes.minY ) viewbox.minY
    yMaxBound = max ( floor extremes.maxY ) <| viewboxMaxY viewbox
  in
  { viewbox | minX = shiftPointWithBounds xMinBound xMaxBound <| viewbox.minX - xChange
  , minY = shiftPointWithBounds yMinBound yMaxBound <| viewbox.minY - yChange
  }

shiftPointWithBounds : Int -> Int -> Int -> Int
shiftPointWithBounds lowerBound upperBound pointAfterShift =
  let
      belowLowerBound = pointAfterShift <= lowerBound
      aboveUpperBound = pointAfterShift >= upperBound 
  in 
  if belowLowerBound then
    lowerBound
  else if aboveUpperBound then
    upperBound
  else
    pointAfterShift