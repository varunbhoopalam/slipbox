module Main exposing (..)

import Browser
import Time exposing (now, posixToMillis)
import Html exposing (s)

-- MAIN
main = Browser.sandbox { init = init, update = update, view = view }

-- MODEL
type Model = Page

-- PAGE
type alias Page = 
  { slipbox : Slipbox
  , widgets : Widgets
  , noteView : NoteView
  }

-- SLIPBOX

type alias Slipbox = 
  { notes: Notes
  , connections: Connections
  , graph: Graph
  , history: History 
  , descriptionQueue: DescriptionQueue
  }


--Update Graph as well after implementing
createNote: Slipbox -> Note -> Slipbox
createNote s n =
  if (isMember n s.notes) == true then
    s
  else
    { s | notes = add s.notes n
    , history = addHistoricalAction s.history CreateNote n
    }
--Update Graph as well after implementing
removeNote: Slipbox -> Note -> Slipbox
removeNote s n =
  if (isMember n s.notes) == true then
    { s | notes = remove s.notes n
    , history = addHistoricalAction s.history DeleteNote n
    }
  else
    s

updateNote: Slipbox -> Note -> Slipbox
updateNote s updatedNote =
  let
      maybeNoteToBeUpdated = findNote s.notes updatedNote
  in
    case maybeNote of
      Just noteToBeUpdated ->
        if (equals noteToBeUpdated updatedNote) then
          s
        else
          {s | notes = 
            s.notes
              |> remove noteToBeUpdated
              |> add updatedNote
          , history = addHistoricalAction s.history Update noteToBeUpdated updatedNote}
      Nothing ->
        s

-- createConnection: Slipbox -> Connection -> Slipbox
-- deleteConnection: Slipbox -> Connection -> Slipbox
  
-- undo: Slipbox -> HistoryId -> Slipbox
-- redo: Slipbox -> HistoryId -> Slipbox
-- getQuestions: Slipbox -> (List Display)
-- getHistory: Slipbox -> History
-- getDescriptions: Slipbox -> (List Display)
-- initialize: Notes -> Connections -> History -> Slipbox
-- updateGraph
-- getNoteAndConnectionPositions

-- NOTES
type alias Notes = List Note
type alias Note = 
  {id : NoteId
  , content : Content
  , source : Source
  , noteType: NoteType}
type alias Description = String
type alias NoteId = Int
type NoteType = Regular | Index

type alias Content = String
type alias Source = String


add: Notes -> Note -> Notes
add notes note =
  note :: notes
remove: Notes -> Note -> Notes
remove notes note =
  List.filter (\x -> x.id == note.id) notes

findNote: Notes -> Note -> Maybe Note
findNote notes note =
  List.head (List.filter (\x -> x.id == note.id) notes)

createNote: Content -> Source -> NoteType -> Note
createNote = c s n
  Note generateId c s n

isMember: Notes -> Note -> Boolean
isMember notes note =
  List.member note.id (List.map (\x -> x.id) notes)

equals: Note -> Note -> Boolean
equals n1 n2 =
  n1 == n2

-- description: Notes -> Note -> Description

-- CONNECTIONS 
type alias Connections = List Connection
type alias Connection = {from : NoteId , to : NoteId , id : ConnectionId}
type alias ConnectionId = Int

addConnection: Connections -> Connection -> Connections
addConnection connections c =
  c :: connections
removeConnection: Connections -> ConnectionId -> Connections
removeConnection connections id =
  List.filter (\x -> x.id == id) connections

-- GRAPH  --From Elm Community Graph and Elm-Visualization
-- type alias Graph = Graph Entity ()
-- initialize: Nodes -> Edges -> Graph



-- HISTORY
-- An item added to history is added to the top of the stack
-- Undoing a history item undoes every HistoricalAction above it in order from latest added to stack to undone action
-- Redoing a HistoricalAction restores the action from earliest added to stack to restored action

type History =
  List HistoricalActions

type Action =
  CreateNote Note |
  CreateConnection Connection |
  Update NoteToBeUpdated UpdatedNote|
  DeleteNote Note |
  DeleteConnection Connection

type alias HistoricalAction =
  { id: HistoryId
  , action : Action
  , reverted: Bool
  }

type alias HistoryId = Int

addHistoricalAction: History -> Action -> History
addHistoricalAction h a =
  HistoricalAction generateId a False :: h
-- undo: History -> HistoryId -> History
-- redo: History -> HistoryId -> History
-- read: History -> HistoryId -> HistoricalAction
-- readAll: History -> List HistoricalActions
-- summary: HistoricalAction -> (???) --Will need to figure out the view for this particular one


-- ID
generateId: Int
generateId =
  posixToMillis now


-- INIT  

-- init: Model      

-- UPDATE
-- update : 

-- VIEW
-- view : Model -> Html Msg
-- view model