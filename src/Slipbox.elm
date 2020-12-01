module Slipbox exposing 
  ( Slipbox, initialize
  , getNotesAndLinks
  , getNotes, getSources
  , getItems, getLinkedNotes
  , getNotesThatCanLinkToNote
  , getNotesAssociatedToSource
  , compressNote, expandNote
  , openNote, openSource
  , newNoteForm, newSourceForm
  , dismissItem, deleteNote
  , deleteSource, createNote
  , createSource
  , submitNoteEdits
  , submitSourceEdits
  , addLink, removeLink
  , updateItem, undo
  , redo, tick, save
  , getHistory
  , simulationIsCompleted
  )

import Simulation
import Note
import Link
import Action
import Item
import Source

--Types
type Slipbox = Slipbox Content

type alias Content =
  { notes: List Note.Note
  , links: List Link.Link
  , actions: List Action.Action
  , items: List Item.Item
  , sources: List Source.Source
  , state: Simulation.State Int
  }

getContent : Slipbox -> Content
getContent slipbox =
  case slipbox of 
    Slipbox content -> content

-- Returns Slipbox

initialize : (List Note.NoteRecord) -> (List LinkRecord) -> ActionResponse -> Slipbox
-- initialize notes links response =
--   let
--     l =  initializeLinks links
--     (state, newNotes) = initializeNotes notes l
--   in
--     Slipbox (Content newNotes l (actionsInit response) LinkForm.initLinkForm state)

getNotesAndLinks : (Maybe String) -> Slipbox -> ((List Note.Note), (List Link.Link))
getNotesAndLinks maybeSearch slipbox =
  let
      content = getContent slipbox
  in
  case maybeSearch of
    Just search -> 
      let
        filteredNotes = List.filter (Note.contains search) content.notes
      in
      ( filteredNotes, List.filter ( Link.isRelevant <| List.map Note.getId filteredNotes ) content.links )
    Nothing -> ( content.notes, content.links )

getNotes : (Maybe String) -> Slipbox -> (List Note.Note)
getNotes maybeSearch slipbox =
  case maybeSearch of
    Just search -> List.filter (Note.contains search) <| notes <| getContent slipbox
    Nothing -> notes <| getContent slipbox

getSources : (Maybe String) -> Slipbox -> (List Source.Source)
getSources maybeSearch slipbox =
  case maybeSearch of
    Just search -> List.filter (Source.contains search) <| sources <| getContent slipbox
    Nothing -> sources <| getContent slipbox

getItems : Slipbox -> (List Item.Item)
getItems slipbox =
  items <| getContent slipbox

getLinkedNotes : Note.Note -> Slipbox -> (List Note.Note)
getLinkedNotes note slipbox =
  let
      content = getContent slipbox
  in
  List.filter ( Note.isLinked content.links note ) content.notes

getNotesThatCanLinkToNote : Note.Note -> Slipbox -> (List Note.Note)
getNotesThatCanLinkToNote note slipbox =
  let
      content = getContent slipbox
  in
  List.filter ( Note.canLink content.links note ) content.notes

getNotesAssociatedToSource : Source.Source -> Slipbox -> (List Note.Note)
getNotesAssociatedToSource source slipbox =
  List.filter ( Note.isAssociated source ) <| notes <| getContent slipbox

compressNote: Note.Note -> Slipbox -> Slipbox
expandNote: Note.Note -> Slipbox -> Slipbox
openNote: Note.Note -> Slipbox -> Slipbox
openSource: Source.Source -> Slipbox -> Slipbox
newNoteForm: Slipbox -> Slipbox
newSourceForm: Slipbox -> Slipbox
dismissItem: Int -> Slipbox -> Slipbox
deleteNote: Int -> Slipbox -> Slipbox
  -- let
  --   extract = Note.extract note
  --   associatedLinks = getLinksForNote extract.intId content.links
  --   notesAfterNoteRemoval = deleteNoteById extract.id content.notes
  --   newLinks = removeAssociatedLinks (List.map (\link -> link.id) associatedLinks) content.links
  --   (newState, newNotes) = initSimulation notesAfterNoteRemoval newLinks
  -- in
  --   Slipbox 
  --     {content | notes = newNotes
  --     , links = newLinks
  --     , actions = addDeleteNoteActionHandler extract associatedLinks content.actions
  --     , form = getFormNotes newNotes newLinks |> LinkForm.selectionsChange content.form
  --     , state = newState
  --     }
deleteSource: Int -> Slipbox -> Slipbox
createNote: Int -> Slipbox -> Slipbox
  -- case slipbox of
  --   Slipbox content -> 
  --     let
  --       newNote = toNoteRecord note content.notes
  --       (state, newNotes) = addNoteToNotes newNote content.notes content.links
  --     in
  --       Slipbox 
  --         { content | notes = sortNotes newNotes
  --         , actions = addNoteToActions newNote content.actions
  --         , state = state
  --         }
createSource: Int -> Slipbox -> Slipbox
submitNoteEdits: Int -> Slipbox -> Slipbox
submitSourceEdits: Int -> Slipbox -> Slipbox
createLink: Int -> Slipbox -> Slipbox
  -- case slipbox of 
  --   Slipbox content -> 
  --     case (LinkForm.maybeProspectiveLink content.form) of
  --       Just (source, target) ->
  --         case toMaybeLink (MakeLinkRecord source target) content.links content.notes of
  --           Just link -> createLink_ link content
  --           Nothing -> removeSelections content
  --       Nothing -> removeSelections content    
deleteLink: Int -> Slipbox -> Slipbox
  -- let
  --   newLinks = removeLinkById link.id content.links
  --   (newState, newNotes) = initSimulation content.notes newLinks
  -- in
  --   Slipbox 
  --     {content | notes = newNotes
  --     , links = newLinks 
  --     , actions = addDeleteLink link content.actions
  --     , form = getFormNotes newNotes newLinks |> LinkForm.selectionsChange content.form
  --     , state = newState
  --     }
updateItem: Int -> Item.UpdateAction -> Slipbox -> Slipbox
undo: Int -> Slipbox -> Slipbox
-- undo actionId slipbox =
--   case slipbox of
--     Slipbox content -> 
--       let
--         recordsToBeUndone = List.filter (Action.shouldUndo actionId) content.actions |> List.map Action.record_
--         undoneActions = undoActionsById actionId content.actions
--       in
--         case List.foldr undoRecord slipbox recordsToBeUndone of
--           Slipbox content_ -> Slipbox {content_ | actions = undoneActions}
redo: Int -> Slipbox -> Slipbox
-- redo actionId slipbox =
--   case slipbox of
--     Slipbox content -> 
--       let
--         recordsToBeRedone = List.map Action.record_ (List.filter (Action.shouldRedo actionId) content.actions)
--         redoneActions = redoActionsById actionId content.actions
--       in
--         case List.foldr redoRecord slipbox recordsToBeRedone of
--           Slipbox content_ -> Slipbox {content_ | actions = redoneActions }
tick: Slipbox -> Slipbox
-- tick slipbox =
--   case slipbox of
--      Slipbox content -> 
--       let
--         (newState, simRecords) = List.map Note.extract content.notes
--           |> List.map toSimulationRecord
--           |> Simulation.tick content.state
--       in
--         Slipbox 
--           {content | notes = List.map (noteUpdateWrapper simRecords) content.notes
--           , state = newState
--           }
save: Slipbox -> Slipbox
-- save slipbox =
--   case slipbox of
--     Slipbox content -> Slipbox {content | actions = List.map Action.save content.actions}
getHistory: Slipbox -> (List Action.Summary)
-- getHistory slipbox =
--   case slipbox of
--     Slipbox content -> List.map Action.summary content.actions
simulationIsCompleted: Slipbox -> Bool
-- isCompleted slipbox =
--   case slipbox of
--     Slipbox content -> Simulation.isCompleted content.state

-- Helper Functions
undoRecord: Action.Record_ -> Slipbox -> Slipbox
undoRecord action slipbox =
  case action of
    Action.CreateNote_ record -> deleteNote (Note.toNoteId record.id) slipbox
    Action.EditNote_ record -> 
      slipbox
        |> startEditState (Note.toNoteId record.id) 
        |> contentUpdate record.formerContent (Note.toNoteId record.id) 
        |> sourceUpdate record.formerSource (Note.toNoteId record.id)
        |> submitEdits (Note.toNoteId record.id)
    Action.DeleteNote_ record -> createNoteInternal (Note.NoteRecord record.id record.content record.source record.variant) slipbox
    Action.CreateLink_ record -> deleteLink record.id slipbox
    Action.DeleteLink_ record -> createLinkInternal (Link record.source record.target record.id) slipbox


redoRecord: Action.Record_ -> Slipbox -> Slipbox
redoRecord action slipbox =
  case action of
    Action.CreateNote_ record -> createNoteInternal (Note.NoteRecord record.id record.content record.source record.variant) slipbox
    Action.EditNote_ record -> 
      slipbox
        |> startEditState (Note.toNoteId record.id) 
        |> contentUpdate record.currentContent (Note.toNoteId record.id) 
        |> sourceUpdate record.currentSource (Note.toNoteId record.id)
        |> submitEdits (Note.toNoteId record.id)
    Action.DeleteNote_ record -> deleteNote (Note.toNoteId record.id) slipbox
    Action.CreateLink_ record -> createLinkInternal (Link record.source record.target record.id) slipbox
    Action.DeleteLink_ record -> deleteLink record.id slipbox

sortNotes: (List Note.Note) -> (List Note.Note)
sortNotes notes =
  List.sortWith Note.sortDesc notes

toSimulationRecord: Note.Extract -> Simulation.SimulationRecord
toSimulationRecord extract =
  Simulation.SimulationRecord extract.intId extract.x extract.y extract.vx extract.vy

toLinkTuple: Link -> (Int, Int)
toLinkTuple link =
  (link.source, link.target)

initSimulation: (List Note.Note) -> (List Link) -> (Simulation.State Int, (List Note.Note))
initSimulation notes links =
  let
    (state, simRecords) = Simulation.simulate 
      (List.map toSimulationRecord (List.map Note.extract notes))
      (List.map toLinkTuple links)
  in
    (state, List.map (noteUpdateWrapper simRecords) notes)

createLinkInternal: Link -> Slipbox -> Slipbox
createLinkInternal link slipbox =
  case slipbox of
    Slipbox content -> createLink_ link content

createNoteInternal: Note.NoteRecord -> Slipbox -> Slipbox
createNoteInternal note slipbox =
  case slipbox of
    Slipbox content -> 
      let
        (state, newNotes) = addNoteToNotes note content.notes content.links
      in
        Slipbox 
          { content | notes = sortNotes newNotes
          , state = state
          }

createLink_: Link -> Content -> Slipbox
createLink_ link content =
  let
    newLinks =  link :: content.links
    (newState, newNotes) = initSimulation content.notes newLinks
  in
    Slipbox 
      {content | notes = newNotes
      , links = newLinks
      , actions = addLinkToActions link content.actions
      , form = getFormNotes newNotes newLinks |> LinkForm.removeSelections
      , state = newState}  