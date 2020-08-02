module Exploration exposing (..)

import Browser
import Html exposing (Html, div, input, text, button)
import Html.Attributes exposing (id, placeholder, value)
import Html.Events exposing (onInput, onClick)
import Force exposing (entity, computeSimulation, manyBody, simulation)
import Svg exposing (Svg, svg, circle, line)
import Svg.Attributes exposing (width, height, viewBox, cx, cy, r, x1, y1, x2, y2, style)

-- MAIN

main =
  Browser.sandbox { init = init, update = update, view = view }

-- MODEL

type Model = Model Notes QuestionQuery Links


init : Model
init =
  Model (initializeNotes initNoteData) (Shown "") (initializeLinks initLinkData)

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

-- NOTES
type Notes = Notes (List PositionNote)
type alias PositionNote =
  { id : NoteId
  , content : Content
  , source : Source
  , noteType: NoteType
  , x : Float
  , y : Float
  , vx : Float
  , vy : Float
  }

type alias Note = 
  { id : NoteId
  , content : Content
  , source : Source
  , noteType: String
  }

type alias ViewNote =
  { id : NoteId
  , content : Content
  , source : Source
  }

type alias NoteId = Int
type alias Content = String
type NoteType = Regular | Index
type alias Source = String

initializeNotes: (List Note) -> Notes
initializeNotes l =
  Notes (initSimulation (List.indexedMap initializePosition l))

initSimulation: (List PositionNote) -> (List PositionNote)
initSimulation l =
  let
    state = simulation [manyBody (List.map (\n -> n.id) l)]
  in
    computeSimulation state l

initializePosition: Int -> Note -> PositionNote
initializePosition index note =
  let
    positions = entity index 1
  in
    PositionNote note.id note.content note.source (noteType note.noteType) positions.x positions.y positions.vx positions.vy

noteType: String -> NoteType
noteType s =
  if s == "index" then
    Index
  else
    Regular

getNotes: Notes -> (List PositionNote)
getNotes n =
  case n of
    Notes pn -> pn

getIndexQuestions: Notes -> (List ViewNote)
getIndexQuestions n =
  case n of
    Notes positionNotes -> positionNotes
      |> List.filter (\note -> note.noteType == Index)
      |> List.map toViewNote

toViewNote: PositionNote -> ViewNote
toViewNote pn =
  ViewNote pn.id pn.content pn.source

findNote: NoteId -> Notes -> Maybe PositionNote
findNote id n =
  case n of
    Notes noteList ->
      List.head (List.filter (\note -> note.id == id) noteList)

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

-- LINKS
type Links = Links (List Link)
type alias Link = 
  { source: NoteId
  , target: NoteId
  , id: LinkId
  }

type alias LinkRecord =
  { source: NoteId
  , target: NoteId
  , id: LinkId
  }

type alias LinkId = Int

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

getLinkViews: Links -> Notes -> List LinkView
getLinkViews links notes = 
  case links of
    Links linkList -> 
      List.map (\link -> linkToLinkView link notes) linkList 

linkToLinkView: Link -> Notes -> LinkView
linkToLinkView link notes =
  let
    maybeSource = findNote link.source notes
    maybeTarget = findNote link.target notes
  in
    case maybeSource of
      Just source -> 
        case maybeTarget of 
          Just target ->
            LinkView (LinkViewRecord source.id source.x source.y target.id target.x target.y link.id)
          Nothing -> BadLink
      Nothing -> BadLink

-- UPDATE

type Msg = 
  Change String |
  ShowQuestionList


update : Msg -> Model -> Model
update msg model =
  case model of
    Model n q l ->
      case msg of 
        ShowQuestionList -> Model n (reverseQuestionQueryState q) l
        Change s -> Model n (updateQuestionQuery s q) l

-- VIEW


view : Model -> Html Msg
view m =
  div []
    [ div [id "Questions"] [questionView m]
    , div [id "Graph"] [ graphView m ]
    , div [id "History-Queue"] [ text "History Queue"]
    ]

graphView: Model -> Svg Msg
graphView m =
  case m of
    Model n _ l-> 
      svg
        [ width "500"
        , height "500"
        , viewBox "-250 -250 500 500"
        ]
        ( List.map noteCircles (getNotes n) ++
         List.map linkLine (getLinkViews l n))

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
  circle [cx (String.fromFloat pn.x), cy (String.fromFloat pn.y) , r "5"] []
  
questionView : Model -> Html Msg
questionView m =
  case m of 
    Model n q _->
      case q of
        Shown query -> div [] 
          [ questionFilter query
          , div [id "Question List"] (questionList n query)
          , questionButton
          ]
        Hidden _ -> questionButton

questionButton: Html Msg
questionButton = 
  button [ id "Show Question Button", onClick ShowQuestionList ] [ text "Q" ]

questionFilter: String -> Html Msg 
questionFilter s = 
  input [placeholder "Question Filter", value s, onInput Change] []

questionList: Notes -> String -> List (Html Msg)
questionList n query =
  n 
    |> getIndexQuestions 
    |> List.filter (\note -> String.contains query note.content)
    |> List.map divFromViewNote 

divFromViewNote: ViewNote -> Html Msg
divFromViewNote v =
  div [] [text v.content]