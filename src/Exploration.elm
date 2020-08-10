module Exploration exposing (..)

import Browser
import Html exposing (Html, div, input, text, button)
import Html.Attributes exposing (id, placeholder, value)
import Html.Events exposing (onInput, onClick, onMouseLeave, onMouseEnter)
import Svg exposing (Svg, svg, circle, line, rect, animate)
import Svg.Attributes exposing (width, height, viewBox, cx, cy, r, x1, y1, x2, y2, style, transform, attributeName, dur, values, repeatCount)
import Svg.Events exposing (on, onMouseUp, onMouseOut)
import Json.Decode exposing (Decoder, int, map, field, map2)

-- Modules
import Viewport as V
import Slipbox as S

-- MAIN

main =
  Browser.sandbox { init = init, update = update, view = view }

-- MODEL
type Model = Model S.Slipbox Search V.Viewport

init : Model
init =
  Model (S.initialize initNoteData initLinkData) (Shown "") V.initialize

initNoteData : List S.NoteRecord
initNoteData = 
  [ S.NoteRecord 1 "What is the Elm langauge?" "" "index"
  , S.NoteRecord 2 "Why does some food taste better than others?" "" "index"
  , S.NoteRecord 3 "Note 0" "" "note"]

initLinkData: List S.LinkRecord
initLinkData =
  [
    S.LinkRecord 1 3 1
  ]

-- SEARCH
type Search = 
  Shown Query |
  Hidden Query

type alias Query = String

toggle: Search -> Search
toggle search =
  case search of
    Shown query -> Hidden query
    Hidden query -> Shown query

updateSearch: String -> Search -> Search
updateSearch query search =
  case search of
    Shown _ -> Shown query
    Hidden _ -> Hidden query

shouldShowSearch: Search -> Bool
shouldShowSearch search =
  case search of
    Shown _ -> True
    Hidden _ -> False

getSearchString: Search -> String
getSearchString search =
  case search of 
    Shown str -> str
    Hidden str -> str

-- UPDATE

type Msg = 
  ToggleSearch |
  UpdateSearch String |
  PanningStart V.MouseEvent |
  IfPanningShift V.MouseEvent |
  PanningStop |
  ZoomIn |
  ZoomOut |
  NoteSelect S.NoteId (Float, Float) |
  NoteDismiss S.NoteId |
  NoteHighlight S.NoteId |
  NoteRemoveHighlights

update : Msg -> Model -> Model
update msg model =
  case msg of 
    ToggleSearch -> handleToggleSearch model
    UpdateSearch query -> handleUpdateSearch query model
    PanningStart mouseEvent -> handlePanningStart mouseEvent model
    IfPanningShift mouseEvent -> handleIfPanningShift mouseEvent model
    PanningStop -> handlePanningStop model
    ZoomIn -> handleZoomIn model
    ZoomOut -> handleZoomOut model
    NoteSelect note coords -> handleNoteSelect note coords model
    NoteDismiss note -> handleNoteDismiss note model
    NoteHighlight note -> handleNoteHighlight note model
    NoteRemoveHighlights -> handleNoteRemoveHighlights model

handleToggleSearch: Model -> Model
handleToggleSearch model =
  case model of 
    Model slipbox search viewport ->
      Model slipbox (toggle search) viewport

handleUpdateSearch: String -> Model -> Model
handleUpdateSearch query model =
  case model of 
    Model slipbox search viewport ->
      Model slipbox (updateSearch query search) viewport
  
handlePanningStart: V.MouseEvent -> Model -> Model
handlePanningStart mouseEvent model =
  case model of
    Model slipbox search viewport ->
      Model slipbox search (V.startPanning mouseEvent viewport)

handleIfPanningShift: V.MouseEvent -> Model -> Model
handleIfPanningShift mouseEvent model =
  case model of 
    Model slipbox search viewport ->
      Model slipbox search (V.shiftIfPanning mouseEvent viewport)

handlePanningStop: Model -> Model
handlePanningStop model =
  case model of
    Model slipbox search viewport ->
      Model slipbox search (V.stopPanning viewport)

handleZoomIn: Model -> Model
handleZoomIn model =
  case model of 
    Model slipbox search viewport ->
      Model slipbox search (V.zoomIn viewport)

handleZoomOut: Model -> Model
handleZoomOut model =
  case model of
    Model slipbox search viewport ->
      Model slipbox search (V.zoomOut viewport)

handleNoteSelect: S.NoteId -> (Float, Float) -> Model -> Model
handleNoteSelect noteId coords model =
  case model of
    Model slipbox search viewport->
      Model (S.selectNote noteId slipbox) search (V.centerOn coords viewport)

handleNoteDismiss: S.NoteId -> Model -> Model
handleNoteDismiss noteId model =
  case model of
    Model slipbox query viewport->
      Model (S.dismissNote noteId slipbox) query viewport

handleNoteHighlight: S.NoteId -> Model -> Model
handleNoteHighlight noteId model =
  case model of
    Model slipbox query viewport->
      Model (S.hoverNote noteId slipbox) query viewport

handleNoteRemoveHighlights: Model -> Model
handleNoteRemoveHighlights model =
  case model of
    Model slipbox query viewport->
      Model (S.stopHoverNote slipbox) query viewport

-- VIEW
view : Model -> Html Msg
view model =
  case model of 
    Model slipbox search viewport ->
      div []
        [ div [id "Graph-container", style "padding: 16px; border: 4px solid black"] 
          [ searchBox slipbox search
          , noteNetwork slipbox viewport
          , panningVisual viewport
          , button [ onClick ZoomOut ] [ text "-" ]
          , button [ onClick ZoomIn ] [ text "+" ]
          , selectedNotes slipbox]
        , div [id "History-Queue"] [ text "History Queue"]
        ]

searchBox : S.Slipbox -> Search -> Html Msg
searchBox slipbox search =
  if shouldShowSearch search then
    searchBoxShown slipbox (getSearchString search)
  else
    questionButton

questionButton: Html Msg
questionButton = 
  button [ onClick ToggleSearch ] [ text "S" ]

searchBoxShown: S.Slipbox -> String -> Html Msg
searchBoxShown slipbox searchString =
  div [] 
    [ input [placeholder "Find Note", value searchString, onInput UpdateSearch] []
    , searchResults slipbox searchString
    , questionButton
    ]

searchResults: S.Slipbox -> String -> Html Msg
searchResults slipbox searchString =
  div 
    [ style "border: 4px solid black; padding: 16px;"] 
    (List.map toResultPane (S.searchSlipbox searchString slipbox))

toResultPane: S.SearchResult -> Html Msg
toResultPane sr =
  let 
    backgroundColor = "background-color:" ++ sr.color ++ ";"
    styleString = "border: 1px solid black;margin-bottom: 16px;cursor:pointer;" ++ backgroundColor
  in
    div 
      [style styleString
      , onClick (NoteSelect sr.id (sr.x, sr.y))
      ] 
      [text sr.content]

noteNetwork: S.Slipbox -> V.Viewport -> Svg Msg
noteNetwork slipbox viewport =
  svg
    [ width V.svgWidthString
    , height V.svgLengthString
    , viewBox (V.getViewbox viewport)
    , style "border: 4px solid black;"
    ]
    (graphElements (S.getGraphElements slipbox))

graphElements: ((List S.GraphNote),(List S.GraphLink)) -> (List (Svg Msg))
graphElements (notes, links) =
  List.map toSvgCircle notes ++ List.map toSvgLine links

toSvgCircle: S.GraphNote -> Svg Msg
toSvgCircle note =
  circle 
    [ cx (String.fromFloat note.x)
    , cy (String.fromFloat note.y) 
    , r "5"
    , style ("Cursor:Pointer;" ++ "fill:" ++ note.color ++ ";")
    , onClick (NoteSelect note.id (note.x, note.y))
    ]
    (handleCircleAnimation note.shouldAnimate)

handleCircleAnimation: Bool -> (List (Svg Msg))
handleCircleAnimation shouldAnimate =
  if shouldAnimate then
    [circleAnimation]
  else
    []

circleAnimation: Svg Msg
circleAnimation = animate [attributeName "r", values "5;9;5", dur "3s", repeatCount "indefinite"] []

toSvgLine: S.GraphLink -> Svg Msg
toSvgLine link =
  line 
    [x1 (String.fromFloat link.sourceX)
    , y1 (String.fromFloat link.sourceY)
    , x2 (String.fromFloat link.targetX)
    , y2 (String.fromFloat link.targetY)
    , style "stroke:rgb(0,0,0);stroke-width:2"
    ] 
    []

panningVisual: V.Viewport -> Svg Msg
panningVisual viewport =
  panningSvg (V.getPanningAttributes viewport)
      
panningSvg: V.PanningAttributes -> Svg Msg
panningSvg attr =
  svg 
    [ width attr.svgWidth
    , height attr.svgHeight
    , style "border: 4px solid black;"
    ] 
    [
      rect 
        [ width attr.rectWidth
        , height attr.rectHeight
        , style attr.rectStyle
        , transform attr.rectTransform
        , on "mousemove" mouseMoveDecoder
        , on "mousedown" mouseDownDecoder
        , onMouseUp PanningStop
        , onMouseOut PanningStop
        ] 
        []
    ]

offsetXDecoder: Decoder Int
offsetXDecoder = field "offsetX" int

offsetYDecoder: Decoder Int
offsetYDecoder =field "offsetY" int

mouseEventDecoder: Decoder V.MouseEvent
mouseEventDecoder = map2 V.MouseEvent offsetXDecoder offsetYDecoder

mouseMoveDecoder: Decoder Msg
mouseMoveDecoder = map IfPanningShift mouseEventDecoder

mouseDownDecoder: Decoder Msg
mouseDownDecoder = map PanningStart mouseEventDecoder

selectedNotes: S.Slipbox -> Html Msg
selectedNotes slipbox =
  div 
    [style "border: 4px solid black; padding: 16px;"] 
    (List.map toDescription (S.getSelectedNotes slipbox))

toDescription: S.DescriptionNote -> Html Msg
toDescription note =
  div [] [
    button [onClick (NoteDismiss note.id)] [text "-"]
    , div 
      [ style "border: 1px solid black;margin-bottom: 16px;cursor:pointer;"
      , onClick (NoteSelect note.id (note.x, note.y))
      , onMouseEnter (NoteHighlight note.id)
      , onMouseLeave NoteRemoveHighlights
      ] 
      [ Html.text note.content
      , Html.text note.source
      , div [] (List.map toClickableLink note.links)
      ]
  ]

toClickableLink: S.DescriptionLink -> Html Msg
toClickableLink link =
  div 
    [ onClick (NoteSelect link.target (link.targetX, link.targetY))] 
    [ Html.text (String.fromInt link.target)]