module Viewport exposing (
  Viewport, MouseEvent, panningWidth, panningHeight, restViewport
  , updateViewportMouseDown, updateViewportMouseMove, zoomIn, zoomOut
  , getCursorStyle, panningSquareTranslation, getViewbox, initializeViewport
  , centerOn)
import Tuple


-- VIEWPORT
type Viewport = 
  Resting Viewbox |
  Moving Viewbox MouseCoordinates

type alias Viewbox = 
  { minX: Int
  , minY: Int
  , length: Int
  , width: Int
  }

svgWidth: Int
svgWidth = 800

svgLength: Int
svgLength = 800

minXMinValue: Int
minXMinValue =
  negate (floor (toFloat svgWidth / 2))

minXMaxValue: Int -> Int
minXMaxValue width =
  floor (toFloat svgWidth / 2) - width

minYMinValue: Int
minYMinValue =
  negate (floor (toFloat svgLength / 2))

minYMaxValue: Int -> Int
minYMaxValue length =
  floor (toFloat svgLength / 2) - length

type alias MouseCoordinates = (Int, Int)

centerOn: (Float, Float) -> Viewport -> Viewport
centerOn coords viewport =
  let
    width = 400
    length = 400
    xTranslation = 200
    yTranslation = 200
    minX = floor (Tuple.first coords) - xTranslation
    minY = floor (Tuple.second coords) - yTranslation
  in
    case viewport of 
      Resting _ -> Resting (Viewbox (validMinX minX width) (validMinY minY length) length width)
      Moving _ _ -> viewport

validMinX: Int -> Int -> Int
validMinX minX width =
  let
    maxValue = minXMaxValue width
  in 
    if minX < minXMinValue then
      minXMinValue
    else if minX > maxValue then
      maxValue
    else
      minX

validMinY: Int -> Int -> Int
validMinY minY length =
  let
    maxValue = minYMaxValue length
  in 
    if minY < minYMinValue then
      minXMinValue
    else if minY > maxValue then
      maxValue
    else
      minY


initializeViewport: Viewport
initializeViewport =
  Resting (Viewbox -200 -200 400 400)

getViewbox: Viewport -> String
getViewbox viewport =
  case viewport of
    Resting box -> assembleViewbox box
    Moving box _ -> assembleViewbox box

assembleViewbox: Viewbox -> String
assembleViewbox box =
   String.fromInt box.minX ++ " " ++  String.fromInt box.minY ++ " " ++  String.fromInt box.width ++ " " ++  String.fromInt box.length

updateViewportMouseDown: MouseEvent -> Viewport -> Viewport
updateViewportMouseDown mouseEvent viewport =
  case viewport of
    Resting box -> Moving box (mouseEvent.offsetX, mouseEvent.offsetY)
    Moving box coordinates ->  Moving (updateViewbox mouseEvent coordinates box) (mouseEvent.offsetX, mouseEvent.offsetY)

updateViewportMouseMove: MouseEvent -> Viewport -> Viewport
updateViewportMouseMove mouseEvent viewport =
  case viewport of
    Resting box -> Resting box
    Moving box coordinates ->  Moving (updateViewbox mouseEvent coordinates box) (mouseEvent.offsetX, mouseEvent.offsetY)

updateViewbox: MouseEvent -> (Int, Int) -> Viewbox -> Viewbox
updateViewbox mouseEvent priorCoords viewbox =
  let
    xChange = Tuple.first priorCoords - mouseEvent.offsetX
    yChange = Tuple.second priorCoords - mouseEvent.offsetY
  in
    Viewbox (calcXCoord viewbox xChange) (calcYCoord viewbox yChange) viewbox.length viewbox.width

zoomIn: Viewport -> Viewport
zoomIn viewport =
  case viewport of
    Resting viewbox -> Resting (zoomInViewbox viewbox)
    Moving _ _ -> viewport

zoomInViewbox: Viewbox -> Viewbox
zoomInViewbox viewbox =
  let
    newWidthHeight = viewbox.width - 100
    edgeConstraint = 300
  in
    if newWidthHeight < edgeConstraint then
      Viewbox viewbox.minX viewbox.minY edgeConstraint edgeConstraint
    else
      Viewbox viewbox.minX viewbox.minY newWidthHeight newWidthHeight
  
zoomOut: Viewport -> Viewport
zoomOut viewport =
  case viewport of
    Resting viewbox -> Resting (zoomOutViewbox viewbox)
    Moving _ _ -> viewport

zoomOutViewbox: Viewbox -> Viewbox
zoomOutViewbox viewbox = 
  let
    shouldCalcX = shouldCalcXCoordinate viewbox
    shouldCalcY = shouldCalcYCoordinate viewbox
    change = 10
  in
    if shouldCalcX && shouldCalcY then
      Viewbox (calcXCoord viewbox change) (calcYCoord viewbox change) (expandLength viewbox.length) (expandWidth viewbox.width)
    else if shouldCalcX then
      Viewbox (calcXCoord viewbox change) viewbox.minY (expandLength viewbox.length) (expandWidth viewbox.width)
    else if shouldCalcY then
      Viewbox viewbox.minX (calcYCoord viewbox change) (expandLength viewbox.length) (expandWidth viewbox.width)
    else
      Viewbox viewbox.minX viewbox.minY (expandLength viewbox.length) (expandWidth viewbox.width)

expandWidth: Int -> Int
expandWidth edge =
  if edge + 100 > svgWidth then  
    svgWidth
  else
    edge + 100

expandLength: Int -> Int
expandLength edge =
  if edge + 100 > svgLength then  
    svgLength
  else
    edge + 100

shouldCalcXCoordinate: Viewbox -> Bool
shouldCalcXCoordinate viewbox =
  viewbox.width + viewbox.minX > floor ( toFloat svgWidth / 2)

shouldCalcYCoordinate: Viewbox -> Bool
shouldCalcYCoordinate viewbox =
  viewbox.length + viewbox.minY > floor ( toFloat svgLength / 2)

calcXCoord: Viewbox -> Int -> Int
calcXCoord viewbox change =
  let
    newMinX = viewbox.minX - (change * 10)
  in
    if newMinX + viewbox.width > floor (toFloat svgWidth / 2) then
      viewbox.minX
    else if newMinX < negate (floor(toFloat svgWidth / 2)) then
      viewbox.minX
    else
      newMinX

calcYCoord: Viewbox -> Int -> Int
calcYCoord viewbox change =
  let
    newMinY = viewbox.minY - (change * 10)
  in
    if newMinY + viewbox.length > floor (toFloat svgLength / 2) then
      viewbox.minY
    else if newMinY < negate (floor(toFloat svgWidth / 2)) then
      viewbox.minY
    else
      newMinY  

restViewport: Viewport -> Viewport
restViewport viewport =
  case viewport of
    Resting box -> Resting box
    Moving box _ -> Resting box

getCursorStyle: Viewport -> String
getCursorStyle viewport =
  case viewport of
    Resting _ -> "cursor: grab;"
    Moving _ _ -> "cursor: grabbing;"

panningSquareTranslation: Viewport -> String
panningSquareTranslation viewport =
  case viewport of 
    Resting viewbox -> viewBoxToTranslation viewbox
    Moving viewbox _ -> viewBoxToTranslation viewbox

viewBoxToTranslation: Viewbox -> String
viewBoxToTranslation viewbox =
  let
    x = toFloat (viewbox.minX + 400) / 10
    y = toFloat (viewbox.minY + 400) / 10
  in
    "translate(" ++ String.fromFloat x ++ "," ++ String.fromFloat y ++ ")"

panningWidth: Viewport -> String
panningWidth viewport =
  case viewport of
    Resting viewbox -> String.fromInt (floor (toFloat viewbox.width / 10))
    Moving viewbox _ -> String.fromInt (floor (toFloat viewbox.width / 10))

panningHeight: Viewport -> String
panningHeight viewport =
  case viewport of
    Resting viewbox -> String.fromInt (floor (toFloat viewbox.length / 10))
    Moving viewbox _ -> String.fromInt (floor (toFloat viewbox.length / 10))

type alias MouseEvent =
    { offsetX : Int
    , offsetY : Int
    }