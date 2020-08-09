module Exploration exposing (..)

import Browser
import Html exposing (Html, div, input, text, button)
import Html.Attributes exposing (id, placeholder, value)
import Html.Events exposing (onInput, onClick)
import Svg exposing (Svg, svg, circle, line, rect, animate)
import Svg.Attributes exposing (width, height, viewBox, cx, cy, r, x1, y1, x2, y2, style, transform, attributeName, dur, values, repeatCount)
import Svg.Events exposing (on, onMouseUp, onMouseOut)
import Json.Decode exposing (Decoder, int, map, field, map2)
import Viewport exposing (..)
import Set
import Html.Events exposing (onMouseLeave, onMouseEnter)
import Notes exposing (..)

-- MAIN

main =
  Browser.sandbox { init = init, update = update, view = view }

-- MODEL

type Model = Model Graph QuestionQuery Viewport


init : Model
init =
  Model (initializeGraph initNoteData initLinkData) (Shown "") initialize

initNoteData : List Note
initNoteData = 
  [ Note 1 "What is the Elm langauge?" "" "index"
  , Note 2 "Why does some food taste better than others?" "" "index"
  , Note 3 "Note 0" "" "note"]

initLinkData: List LinkRecord
initLinkData =
  [
    LinkRecord 1 3 1
  ]

-- GRAPH
type Graph = Graph Notes Links

selectNote: NoteId -> Graph -> Graph
selectNote noteId graph =
  case graph of 
    Graph notes links -> Graph (selectOnNote noteId notes) links

dismissNote: NoteId -> Graph -> Graph
dismissNote noteId graph =
  case graph of 
    Graph notes links -> Graph (unselectNote noteId notes) links

initializeGraph: (List Note) -> (List LinkRecord) -> Graph
initializeGraph notes links =
  Graph (initializeNotes notes links) (initializeLinks links)

getNotes: Graph -> (List PositionNote)
getNotes graph =
  case graph of
    Graph notes _ -> get notes

getLinkViews: Graph -> List LinkView
getLinkViews graph =
  case graph of
    Graph notes links ->
      case links of
        Links linkList -> 
          List.map (\link -> linkToLinkView link notes) linkList 

type alias DescriptiveNote = 
  { id : NoteId
  , content : Content
  , source : Source
  , noteType: NoteType
  , linkedNotes : (List NoteId)
  , selected : Selected
  , x : Float
  , y : Float
  , vx : Float
  , vy : Float
  , hover: Hover
  }

getSelectedNoteDescriptions: Graph -> (List DescriptiveNote)
getSelectedNoteDescriptions graph =
  case graph of
    Graph notes links -> List.map (\note -> toDescriptiveNote note links) (getSelectedNotes notes)

toDescriptiveNote: PositionNote -> Links -> DescriptiveNote
toDescriptiveNote note links =
  DescriptiveNote note.id note.content note.source note.noteType (getLinkedNotes note.id links) note.selected note.x note.y note.vx note.vy note.hover

hoverNote: PositionNote -> Graph -> Graph
hoverNote pn graph =
  case graph of 
    Graph notes links -> Graph (hoverOnNote pn notes) links

notHoverNote: Graph -> Graph
notHoverNote graph =
  case graph of 
    Graph notes links -> Graph (clearHover notes) links

circleChildren: PositionNote -> (List (Svg Msg))
circleChildren pn =
  if  shouldAnimateNoteCircle pn == True then
    [animate [attributeName "r", values "5;9;5", dur "3s", repeatCount "indefinite"] []]
  else
    []

-- LINKS
type Links = Links (List Link)
type alias Link = 
  { source: NoteId
  , target: NoteId
  , id: LinkId
  }

initializeLinks: (List LinkRecord) -> Links
initializeLinks l =
  Links (List.map (\lr -> Link lr.source lr.target lr.id) l)

type LinkView = 
  BadLink |
  LinkView LinkViewRecord

type alias LinkViewRecord = 
  { sourceId: NoteId
  , sourceX: Float
  , sourceY: Float
  , targetId: NoteId
  , targetX: Float
  , targetY: Float
  , id: LinkId
  }

getLinkedNotes: NoteId -> Links -> (List Int)
getLinkedNotes noteId links =
  case links of
    Links linkList -> Set.toList (Set.fromList (List.filterMap (\link -> maybeGetLinkedNoteId noteId link) linkList))

maybeGetLinkedNoteId: NoteId -> Link -> (Maybe NoteId)
maybeGetLinkedNoteId noteId link =
  if link.source == noteId then 
    Just link.target
  else if link.target == noteId then 
    Just link.source
  else 
    Nothing

linkToLinkView: Link -> Notes -> LinkView
linkToLinkView link notes =
  let
    maybeSource = findNote link.source notes
    maybeTarget = findNote link.target notes
    maybeLinkViewRecord = Maybe.map3 linkViewRecord maybeSource maybeTarget (Just link.id)
  in
    case maybeLinkViewRecord of
      Just r -> LinkView r
      Nothing -> BadLink
    
linkViewRecord: PositionNote -> PositionNote -> LinkId -> LinkViewRecord
linkViewRecord source target id =
  LinkViewRecord source.id source.x source.y target.id target.x target.y id

-- QuestionFilter
type QuestionQuery = 
  Shown String |
  Hidden String

reverseQuestionQueryState: QuestionQuery -> QuestionQuery
reverseQuestionQueryState q =
  case q of
    Shown s -> Hidden s
    Hidden s -> Shown s

updateQuestionQuery: String -> QuestionQuery -> QuestionQuery
updateQuestionQuery s q =
  case q of
    Shown _ -> Shown s
    Hidden _ -> Hidden s

-- UPDATE

type Msg = 
  Change String |
  ShowQuestionList |
  MouseMove MouseEvent |
  MouseDown MouseEvent |
  MouseUp |
  MouseOut |
  ZoomIn |
  ZoomOut |
  SelectDescription PositionNote |
  DismissDescription PositionNote |
  MouseEnterDesc PositionNote |
  MouseLeaveDesc

update : Msg -> Model -> Model
update msg model =
  case model of
    Model graph query viewport->
      case msg of 
        ShowQuestionList -> Model graph (reverseQuestionQueryState query) viewport
        Change str -> Model graph (updateQuestionQuery str query) viewport
        MouseUp -> Model graph query (stopPanning viewport)
        MouseDown e -> Model graph query (startPanning e viewport)
        MouseMove e -> Model graph query (shiftIfPanning e viewport)
        MouseOut -> Model graph query (stopPanning viewport)
        ZoomIn -> Model graph query (zoomIn viewport)
        ZoomOut -> Model graph query (zoomOut viewport)
        SelectDescription note -> handleSelectDescription note model
        DismissDescription note -> handleDismissDescription note model
        MouseEnterDesc note -> handleMouseEnterDesc note model
        MouseLeaveDesc -> handleMouseLeaveDesc model

handleMouseEnterDesc: PositionNote -> Model -> Model
handleMouseEnterDesc note model =
  case model of
    Model graph query viewport->
      Model (hoverNote note graph) query viewport

handleMouseLeaveDesc: Model -> Model
handleMouseLeaveDesc model =
  case model of
    Model graph query viewport->
      Model (notHoverNote graph) query viewport

handleSelectDescription: PositionNote -> Model -> Model
handleSelectDescription note model =
  case model of
    Model graph query viewport->
      Model (selectNote note.id graph) query (centerOn (note.x, note.y) viewport)

handleDismissDescription: PositionNote -> Model -> Model
handleDismissDescription note model =
  case model of
    Model graph query viewport->
      Model (dismissNote note.id graph) query viewport

-- VIEW
view : Model -> Html Msg
view m =
  div []
    [ div [id "Graph-container", style "padding: 16px; border: 4px solid black"] 
      [ questionView m
      , graphView m
      , panningVisual m
      , zoomOutButton
      , zoomInButton
      , descriptionQueue m]
    , div [id "History-Queue"] [ text "History Queue"]
    ]

descriptionQueue: Model -> Html Msg
descriptionQueue m =
  case m of
    Model graph _ _ ->
      div [style "border: 4px solid black; padding: 16px;"] (List.map toDescription (getSelectedNoteDescriptions graph))

toPositionNote: DescriptiveNote -> PositionNote
toPositionNote note =
  PositionNote note.id note.content note.source note.noteType note.x note.y note.vx note.vy note.selected note.hover

toDescription: DescriptiveNote -> Html Msg
toDescription dn =
  div [] [
    button [onClick (DismissDescription (toPositionNote dn))] [text "-"]
    , div 
      [ style "border: 1px solid black;margin-bottom: 16px;cursor:pointer;"
      , onClick (SelectDescription (toPositionNote dn))
      , onMouseEnter (MouseEnterDesc (toPositionNote dn))
      , onMouseLeave MouseLeaveDesc
      ] 
      [Html.text dn.content, Html.text dn.source, linkListDiv dn.linkedNotes]
  ]

linkListDiv: (List Int) -> Html Msg
linkListDiv list =
  div [] (List.map (\link -> Html.text (String.fromInt link)) list)

graphView: Model -> Svg Msg
graphView m =
  case m of
    Model graph _ viewport -> 
      svg
        [ width svgWidthString
        , height svgLengthString
        , viewBox (getViewbox viewport)
        , style "border: 4px solid black;"
        ]
        ( List.map noteCircles (getNotes graph) ++
         List.map linkLine (getLinkViews graph))

panningVisual: Model -> Svg Msg
panningVisual m =
  case m of
    Model _ _ viewport -> panningSvg viewport
      
panningSvg: Viewport -> Svg Msg
panningSvg viewport =
  let
    attr = getPanningAttributes viewport
  in
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
          , onMouseUp MouseUp
          , onMouseOut MouseOut
          ] 
          []
      ]
  

linkLine: LinkView -> Svg Msg
linkLine lv =
  case lv of
    BadLink -> line [] []
    LinkView lvr ->
      line 
        [x1 (String.fromFloat lvr.sourceX)
        , y1 (String.fromFloat lvr.sourceY)
        , x2 (String.fromFloat lvr.targetX)
        , y2 (String.fromFloat lvr.targetY)
        , style "stroke:rgb(0,0,0);stroke-width:2"
        ] 
        []

noteCircles: PositionNote -> Svg Msg
noteCircles pn =
  let
    color = noteColor pn.noteType
    fill = "fill:" ++ color ++ ";"
    styleString = "Cursor:Pointer;" ++ fill
  in
    circle 
      [ cx (String.fromFloat pn.x)
      , cy (String.fromFloat pn.y) 
      , r "5"
      , style styleString
      , onClick (SelectDescription pn)
      ]
      (circleChildren pn)
  
questionView : Model -> Html Msg
questionView m =
  case m of 
    Model graph q _ ->
      case q of
        Shown query -> div [] 
          [ questionFilter query
          , div 
            [ id "Question List"
            , style "border: 4px solid black; padding: 16px;"] 
            (questionList graph query)
          , questionButton
          ]
        Hidden _ -> questionButton

zoomInButton: Html Msg
zoomInButton =
  button [ onClick ZoomIn ] [ text "+" ]

zoomOutButton: Html Msg
zoomOutButton =
  button [ onClick ZoomOut ] [ text "-" ]

questionButton: Html Msg
questionButton = 
  button [ id "Show Question Button", onClick ShowQuestionList ] [ text "Q" ]

questionFilter: String -> Html Msg 
questionFilter s = 
  input [placeholder "Find Note", value s, onInput Change] []

questionList: Graph -> String -> List (Html Msg)
questionList graph query =
  graph 
    |> getNotes 
    |> List.filter (\note -> String.contains query note.content)
    |> List.map divFromNote 

divFromNote: PositionNote -> Html Msg
divFromNote v =
  let 
    color = noteColor v.noteType
    backgroundColor = "background-color:" ++ color ++ ";"
    styleString = "border: 1px solid black;margin-bottom: 16px;cursor:pointer;" ++ backgroundColor
  in
    div 
      [style styleString
      , onClick (SelectDescription v)
      ] 
      [text v.content]

offsetXDecoder: Decoder Int
offsetXDecoder = 
  field "offsetX" int

offsetYDecoder: Decoder Int
offsetYDecoder =
  field "offsetY" int

mouseEventDecoder: Decoder MouseEvent
mouseEventDecoder =
  map2 MouseEvent offsetXDecoder offsetYDecoder

mouseMoveDecoder: Decoder Msg
mouseMoveDecoder =
  map MouseMove mouseEventDecoder

mouseDownDecoder: Decoder Msg
mouseDownDecoder =
  map MouseDown mouseEventDecoder