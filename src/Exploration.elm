module Exploration exposing (..)

import Browser
import Html exposing (Html, Attribute, div, input, text)
import Html.Attributes exposing (id)
import Force exposing (entity)


-- MAIN


main =
  Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type Model = Model Notes


init : Model
init =
  Model (initializeNotes [ Note 1 "Question 0" "" "index", Note 2 "Question 1" "" "index", Note 3 "Note 0" "" "note"])

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
  Notes (List.indexedMap initializePosition l)

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

getIndexQuestions: Notes -> (List ViewNote)
getIndexQuestions n =
  case n of
    Notes positionNotes -> positionNotes
      |> List.filter (\note -> note.noteType == Index)
      |> List.map toViewNote

toViewNote: PositionNote -> ViewNote
toViewNote pn =
  ViewNote pn.id pn.content pn.source
-- UPDATE

type Msg
  = Change String


update : Msg -> Model -> Model
update _ model =
  model

-- VIEW


view : Model -> Html Msg
view m =
  div []
    [ div [id "Question-Filter"] (questionFilterView m)
    , div [id "Control-Ship"] [ text "Control Ship" ]
    , div [id "History-Queue"] [ text "History Queue"]
    ]

questionFilterView: Model -> List (Html Msg)
questionFilterView m =
  case m of
    Model n -> n
      |> getIndexQuestions
      >> List.map divFromViewNote 


divFromViewNote: ViewNote -> Html Msg
divFromViewNote v =
  div [] [text v.content]