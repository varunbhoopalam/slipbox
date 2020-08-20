module Viewport exposing (
  Viewport, MouseEvent, stopPanning, getPanningAttributes
  , startPanning, shiftIfPanning, zoomIn, zoomOut
  , getCursorStyle, getViewbox, initialize, centerOn
  , svgWidthString, svgLengthString, PanningAttributes)
import Tuple

-- TYPES
type Viewport = 
  Resting Viewbox |
  Moving Viewbox MouseCoordinates

type alias Viewbox = 
  { minX: Int
  , minY: Int
  , length: Int
  , width: Int
  }

type alias MouseCoordinates = (Int, Int)

type alias MouseEvent =
  { offsetX : Int
  , offsetY : Int
  }

type alias PanningAttributes =
  { svgWidth: String
  , svgHeight: String
  , rectWidth: String
  , rectHeight: String
  , rectStyle: String
  , rectTransform: String
  }

-- CONSTANTS

svgWidth: Int
svgWidth = 900

svgWidthString: String
svgWidthString = String.fromInt svgWidth

svgLength: Int
svgLength = 900

svgLengthString: String
svgLengthString = String.fromInt svgLength

panningFactor: Int
panningFactor = 10

zoomFactor: Int
zoomFactor = 100

-- INVARIANTS

xMin: Int
xMin =
  negate (floor (toFloat svgWidth / 2))

xMax: Int -> Int
xMax width =
  floor (toFloat svgWidth / 2) - width

yMin: Int
yMin =
  negate (floor (toFloat svgLength / 2))

yMax: Int -> Int
yMax length =
  floor (toFloat svgLength / 2) - length

xBounded: Int -> Int -> Int
xBounded minX width =
  let
    maxValue = xMax width
  in 
    if minX < xMin then
      xMin
    else if minX > maxValue then
      maxValue
    else
      minX

yBounded: Int -> Int -> Int
yBounded minY length =
  let
    maxValue = yMax length
  in 
    if minY < yMin then
      xMin
    else if minY > maxValue then
      maxValue
    else
      minY

edgeLenConstraint: Int
edgeLenConstraint = 300

-- METHODS

initialize: Viewport
initialize =
  Resting (Viewbox -300 -300 600 600)

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
      Resting _ -> Resting (Viewbox (xBounded minX width) (yBounded minY length) length width)
      Moving _ _ -> viewport

getViewbox: Viewport -> String
getViewbox viewport =
  case viewport of
    Resting box -> assembleViewbox box
    Moving box _ -> assembleViewbox box

assembleViewbox: Viewbox -> String
assembleViewbox box =
   String.fromInt box.minX ++ " " ++  String.fromInt box.minY ++ " " ++  String.fromInt box.width ++ " " ++  String.fromInt box.length

shiftViewbox: MouseEvent -> (Int, Int) -> Viewbox -> Viewbox
shiftViewbox mouseEvent coords viewbox =
  let
    xChange = (Tuple.first coords - mouseEvent.offsetX) * panningFactor
    yChange = (Tuple.second coords - mouseEvent.offsetY) * panningFactor
  in
    Viewbox 
      (xBounded (viewbox.minX - xChange)  viewbox.width)
      (yBounded (viewbox.minY - yChange)  viewbox.length)
      viewbox.length
      viewbox.width

startPanning: MouseEvent -> Viewport -> Viewport
startPanning mouseEvent viewport =
  case viewport of
    Resting box -> Moving box (mouseEvent.offsetX, mouseEvent.offsetY)
    Moving box coordinates ->  Moving (shiftViewbox mouseEvent coordinates box) (mouseEvent.offsetX, mouseEvent.offsetY)

shiftIfPanning: MouseEvent -> Viewport -> Viewport
shiftIfPanning mouseEvent viewport =
  case viewport of
    Resting box -> Resting box
    Moving box coordinates ->  Moving (shiftViewbox mouseEvent coordinates box) (mouseEvent.offsetX, mouseEvent.offsetY)

stopPanning: Viewport -> Viewport
stopPanning viewport =
  case viewport of
    Resting box -> Resting box
    Moving box _ -> Resting box

zoomIn: Viewport -> Viewport
zoomIn viewport =
  case viewport of
    Resting viewbox -> Resting (zoomInViewbox viewbox)
    Moving _ _ -> viewport

zoomInViewbox: Viewbox -> Viewbox
zoomInViewbox viewbox =
  let
    edgeLen = viewbox.width - zoomFactor
  in
    if edgeLen < edgeLenConstraint then
      Viewbox viewbox.minX viewbox.minY edgeLenConstraint edgeLenConstraint
    else
      Viewbox viewbox.minX viewbox.minY edgeLen edgeLen
  
zoomOut: Viewport -> Viewport
zoomOut viewport =
  case viewport of
    Resting viewbox -> Resting (zoomOutViewbox viewbox)
    Moving _ _ -> viewport

zoomOutViewbox: Viewbox -> Viewbox
zoomOutViewbox viewbox = 
  let
    width = expandWidth viewbox.width
    length = expandLength viewbox.length
  in
    Viewbox (xBounded viewbox.minX width) (yBounded viewbox.minY length) length width
  

expandWidth: Int -> Int
expandWidth edge =
  let
      newEdge = edge + zoomFactor
  in
    if newEdge > svgWidth then  
      svgWidth
    else
      newEdge

expandLength: Int -> Int
expandLength edge =
  let
      newEdge = edge + zoomFactor
  in
    if newEdge > svgLength then  
      svgLength
    else
      newEdge

getPanningAttributes: Viewport -> PanningAttributes
getPanningAttributes viewport =
  case viewport of
    Resting viewbox -> panningAttributes viewbox "cursor: grab;"
    Moving viewbox _ -> panningAttributes viewbox "cursor: grabbing;"

panningAttributes: Viewbox -> String -> PanningAttributes
panningAttributes viewbox cursor =
  PanningAttributes 
    (String.fromInt (svgWidth // panningFactor))
    (String.fromInt (svgLength // panningFactor))
    (String.fromInt (viewbox.width // panningFactor))
    (String.fromInt (viewbox.length // panningFactor))
    ("fill:rgb(220,220,220);stroke-width:3;stroke:rgb(0,0,0);" ++ cursor)
    (viewBoxToTranslation viewbox)

getCursorStyle: Viewport -> String
getCursorStyle viewport =
  case viewport of
    Resting _ -> "cursor: grab;"
    Moving _ _ -> "cursor: grabbing;"

viewBoxToTranslation: Viewbox -> String
viewBoxToTranslation viewbox =
  let
    x = (viewbox.minX + (svgWidth // 2)) // panningFactor
    y = (viewbox.minY + (svgLength // 2)) // panningFactor
  in
    "translate(" ++ String.fromInt x ++ "," ++ String.fromInt y ++ ")"