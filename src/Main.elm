module Main exposing (..)

import Browser
import Time exposing (now, posixToMillis)
import Notes as N
-- import Html exposing (s)
import Force as F

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
  { notes: N.Notes
  , connections: Connections
  , graph: Graph
  , history: History 
  , descriptionQueue: DescriptionQueue
  }


--Update Graph as well after implementing
createNote: Slipbox -> N.Note -> Slipbox
createNote s n =
  if N.isMember n s.notes == true then
    s
  else
    { s | notes = add s.notes n
    , history = addHistoricalAction s.history CreateNote n
    }
--Update Graph as well after implementing
removeNote: Slipbox -> N.Note -> Slipbox
removeNote s n =
  if N.isMember n s.notes == true then
    { s | notes = N.remove s.notes n
    , history = addHistoricalAction s.history DeleteNote n
    }
  else
    s

updateNote: Slipbox -> N.Note -> Slipbox
updateNote s updatedNote =
  let
      maybeNoteToBeUpdated = N.get s.notes updatedNote
  in
    case maybeNoteToBeUpdated of
      Just noteToBeUpdated ->
        if N.equals noteToBeUpdated updatedNote then
          s
        else
          {s | notes = 
            s.notes
              |> N.remove noteToBeUpdated
              |> N.add updatedNote
          , history = addHistoricalAction s.history Update noteToBeUpdated updatedNote}
      Nothing ->
        s

--Update Graph as well after implementing

createConnection: Slipbox -> Connection -> Slipbox
createConnection s c =
  if isMember s.connections c then
    s
  else
    {s | connections = addConnection s.connections c
    , history = addHistoricalAction CreateConnection c
    }

--Update Graph as well after implementing
deleteConnection: Slipbox -> Connection -> Slipbox
deleteConnection s c =
  if isMember s.connections c then
    {s | connections = removeConnection s.connections c
    , history = addHistoricalAction DeleteConnection c
    }
  else 
    s

-- undo: Slipbox -> HistoryId -> Slipbox
-- redo: Slipbox -> HistoryId -> Slipbox
getQuestions: Slipbox -> (N.Notes)
getQuestions s =
  N.getIndexQuestions s.notes
-- getHistory: Slipbox -> History
-- getDescriptions: Slipbox -> (List Display)
-- initialize: Notes -> Connections -> History -> Slipbox
-- updateGraph
-- getNoteAndConnectionPositions

-- CONNECTIONS 
type alias Connections = List Connection
type alias Connection = 
  {from : N.NoteId 
  , to : N.NoteId 
  , id : ConnectionId
  }
type alias ConnectionId = Int

addConnection: Connections -> Connection -> Connections
addConnection connections c =
  c :: connections
removeConnection: Connections -> Connection -> Connections
removeConnection connections connection =
  List.filter (\x -> x.id == connection.id) connections

isMember: Connections -> Connection -> Bool 
isMember connections c =
  List.member c.id List.map (\x -> x.id) connections

-- GRAPH
-- Can the list of entity handle node and edge positions?
-- Do we represent edges as forces between nodes as well?
  -- So if we delete an edge we have to delete thfat force as well?
type alias Graph = List F.Entity LinkForce CenteringForce ManyBodyForce 
type alias LinkForce = F.Force
type alias CenteringForce = F.Force
type alias ManyBodyForce = F.Force

initialize: N.Notes -> Connections -> Graph
initialize n c =
  let 
    noteIds = List.map (\x -> x.id) n
    linkedForce = F.links (List.map (\x -> (x.from, x.to)) c)
    centeringForce = F.center 0 0
    manyBodyForce = F.manyBody noteIds
  in
    Graph F.entity noteIds linkedForce centeringForce manyBodyForce


-- HISTORY
-- An item added to history is added to the top of the stack
-- Undoing a history item undoes every HistoricalAction above it in order from latest added to stack to undone action
-- Redoing a HistoricalAction restores the action from earliest added to stack to restored action

type alias History = List HistoricalActions

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

-- DescriptionQueue


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