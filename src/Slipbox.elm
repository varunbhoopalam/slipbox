module Slipbox exposing (Slipbox, LinkRecord, initialize
  , selectNote, dismissNote, stopHoverNote, searchSlipbox
  , getGraphElements, GraphNote, GraphLink, getSelectedNotes, DescriptionNote
  , DescriptionLink, hoverNote, CreateNoteRecord, CreateLinkRecord
  , getHistory, createNote, MakeNoteRecord, MakeLinkRecord
  , createLink, sourceSelected, targetSelected, getLinkFormData
  , startEditState, discardEdits, submitEdits, contentUpdate
  , sourceUpdate, deleteNote, deleteLink, undo, redo, ActionResponse
  , EditNoteRecordWrapper, isCompleted, tick, buildSaveRequest
  , save, canSave)

import Simulation
import LinkForm
import Note
import Action
import Debug
import Json.Encode as Encode

--Types
type Slipbox = Slipbox Content

type alias Content =
  { notes: List Note.Note
  , links: List Link
  , actions: List Action.Action
  , form: LinkForm.LinkForm
  , state: Simulation.State Int
  }

type alias Link = 
  { source: Int
  , target: Int
  , id: LinkId
  }

type alias LinkId = Int

type alias LinkRecord =
  { source: Int
  , target: Int
  , id: Int
  }

type alias MakeLinkRecord =
  { source: Int
  , target: Int
  }

type alias MakeNoteRecord =
  { content : String
  , source : String
  , noteType : String
  }

type alias CreateNoteRecord =
  { id : Int
  , action : Note.NoteRecord
  }

type alias CreateLinkRecord =
  { id : Int
  , action : LinkRecord
  }

type alias GraphNote =
  { id: Note.NoteId
  , idInt: Int
  , x : Float
  , y : Float
  , variant : String 
  , shouldAnimate : Bool
  }

type alias GraphLink = 
  { sourceId: Int
  , sourceX: Float
  , sourceY: Float
  , targetId: Int
  , targetX: Float
  , targetY: Float
  , id: LinkId
  }

type alias DescriptionNote =
  { id : Note.NoteId
  , x : Float
  , y : Float 
  , content : String
  , source : String 
  , inEdit: Bool
  , links : (List DescriptionLink)
  }

type alias DescriptionLink =
  { id : Note.NoteId
  , idInt : Int
  , x : Float
  , y : Float
  , linkId: Int
  }

type alias EditNoteRecordWrapper = 
  { id: Int
  , action: Action.EditNoteRecord
  }
type alias ActionResponse =
  { create_note: (List CreateNoteRecord)
  , edit_note: (List EditNoteRecordWrapper)
  , delete_note: (List CreateNoteRecord)
  , create_link: (List CreateLinkRecord)
  , delete_link: (List CreateLinkRecord)
  }

-- Methods

-- Returns Slipbox
initialize: (List Note.NoteRecord) -> (List LinkRecord) -> ActionResponse -> Slipbox
initialize notes links response =
  let
    l =  initializeLinks links
    (state, newNotes) = initializeNotes notes l
  in
    Slipbox (Content newNotes l (actionsInit response) LinkForm.initLinkForm state)

selectNote: Note.NoteId -> Slipbox -> Slipbox
selectNote noteId slipbox =
  case slipbox of 
    Slipbox content -> 
      let
        newNotes = selectById noteId content.notes
      in
      Slipbox 
        { content | notes = newNotes
        , form = getFormNotes newNotes content.links |> LinkForm.selectionsChange content.form
        }

dismissNote: Note.NoteId -> Slipbox -> Slipbox
dismissNote noteId slipbox =
  case slipbox of 
    Slipbox content -> 
      let
        newNotes = unSelectById noteId content.notes
      in
        Slipbox
          { content | notes = newNotes
          , form = getFormNotes newNotes content.links |> LinkForm.selectionsChange content.form
          }

hoverNote: Note.NoteId -> Slipbox -> Slipbox
hoverNote noteId slipbox =
  case slipbox of 
    Slipbox content -> Slipbox {content | notes = List.map (hoverById noteId) content.notes}

stopHoverNote: Slipbox -> Slipbox
stopHoverNote slipbox =
  case slipbox of 
    Slipbox content -> Slipbox {content | notes = List.map Note.unHover content.notes}

createNote: MakeNoteRecord -> Slipbox -> Slipbox
createNote note slipbox =
  case slipbox of
    Slipbox content -> 
      let
        newNote = toNoteRecord note content.notes
        (state, newNotes) = addNoteToNotes newNote content.notes content.links
      in
        Slipbox 
          { content | notes = sortNotes newNotes
          , actions = addNoteToActions newNote content.actions
          , state = state
          }


createLink: Slipbox -> Slipbox
createLink slipbox =
  case slipbox of 
    Slipbox content -> 
      case (LinkForm.maybeProspectiveLink content.form) of
        Just (source, target) ->
          case toMaybeLink (MakeLinkRecord source target) content.links content.notes of
            Just link -> createLink_ link content
            Nothing -> removeSelections content
        Nothing -> removeSelections content    

sourceSelected: String -> Slipbox -> Slipbox
sourceSelected source slipbox =
  case slipbox of
    Slipbox content -> Slipbox {content | form = LinkForm.addSource source content.form}

targetSelected: String -> Slipbox -> Slipbox
targetSelected target slipbox =
  case slipbox of
    Slipbox content -> Slipbox {content | form = LinkForm.addTarget target content.form}

startEditState: Note.NoteId -> Slipbox -> Slipbox
startEditState noteId slipbox =
  case slipbox of
    Slipbox content -> Slipbox {content | notes = startEditStateById noteId content.notes }

discardEdits: Note.NoteId -> Slipbox -> Slipbox
discardEdits noteId slipbox =
  case slipbox of
    Slipbox content -> Slipbox {content | notes = discardEditsById noteId content.notes }

submitEdits: Note.NoteId -> Slipbox -> Slipbox
submitEdits noteId slipbox =
  case slipbox of
    Slipbox content -> 
      case findNote noteId content.notes of
        Nothing -> slipbox
        Just note -> 
          let
            extract = Note.extract note
          in
            case extract.selected.edits of
              Nothing -> slipbox
              Just edits -> 
                if wasEdited edits extract then
                  Slipbox 
                    {content | notes = submitEditsById extract.id content.notes
                    , actions = addEditNoteToActions edits extract content.actions 
                    }
                else
                  slipbox


contentUpdate: String -> Note.NoteId -> Slipbox -> Slipbox
contentUpdate noteContent noteId slipbox =
  case slipbox of
    Slipbox content -> Slipbox {content | notes = contentUpdateById noteContent noteId content.notes }

sourceUpdate: String -> Note.NoteId -> Slipbox -> Slipbox
sourceUpdate source noteId slipbox =
  case slipbox of
    Slipbox content -> Slipbox {content | notes = sourceUpdateById source noteId content.notes } 

deleteNote: Note.NoteId -> Slipbox -> Slipbox
deleteNote noteId slipbox =
  case slipbox of
    Slipbox content -> 
      case findNote noteId content.notes of
        Just note -> deleteNote_ note content
        Nothing -> Slipbox content 


deleteNote_: Note.Note -> Content -> Slipbox
deleteNote_ note content =
  let
    extract = Note.extract note
    associatedLinks = getLinksForNote extract.intId content.links
    notesAfterNoteRemoval = deleteNoteById extract.id content.notes
    newLinks = removeAssociatedLinks (List.map (\link -> link.id) associatedLinks) content.links
    (newState, newNotes) = initSimulation notesAfterNoteRemoval newLinks
  in
    Slipbox 
      {content | notes = newNotes
      , links = newLinks
      , actions = addDeleteNoteActionHandler extract associatedLinks content.actions
      , form = getFormNotes newNotes newLinks |> LinkForm.selectionsChange content.form
      , state = newState
      }

deleteLink: Int -> Slipbox -> Slipbox
deleteLink linkId slipbox =
  case slipbox of
    Slipbox content -> 
      case findLink linkId content.links of
        Just link -> deleteLink_ link content
        Nothing -> slipbox

deleteLink_: Link -> Content -> Slipbox
deleteLink_ link content =
  let
    newLinks = removeLinkById link.id content.links
    (newState, newNotes) = initSimulation content.notes newLinks
  in
    Slipbox 
      {content | notes = newNotes
      , links = newLinks 
      , actions = addDeleteLink link content.actions
      , form = getFormNotes newNotes newLinks |> LinkForm.selectionsChange content.form
      , state = newState
      }

undo: Int -> Slipbox -> Slipbox
undo actionId slipbox =
  case slipbox of
    Slipbox content -> 
      let
        recordsToBeUndone = List.filter (Action.shouldUndo actionId) content.actions |> List.map Action.record_
        undoneActions = undoActionsById actionId content.actions
      in
        case List.foldr undoRecord slipbox recordsToBeUndone of
          Slipbox content_ -> Slipbox {content_ | actions = undoneActions}

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

redo: Int -> Slipbox -> Slipbox
redo actionId slipbox =
  case slipbox of
    Slipbox content -> 
      let
        recordsToBeRedone = List.map Action.record_ (List.filter (Action.shouldRedo actionId) content.actions)
        redoneActions = redoActionsById actionId content.actions
      in
        case List.foldr redoRecord slipbox recordsToBeRedone of
          Slipbox content_ -> Slipbox {content_ | actions = redoneActions }

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

tick: Slipbox -> Slipbox
tick slipbox =
  case slipbox of
     Slipbox content -> 
      let
        (newState, simRecords) = List.map Note.extract content.notes
          |> List.map toSimulationRecord
          |> Simulation.tick content.state
      in
        Slipbox 
          {content | notes = List.map (noteUpdateWrapper simRecords) content.notes
          , state = newState
          }

save: Slipbox -> Slipbox
save slipbox =
  case slipbox of
    Slipbox content -> Slipbox {content | actions = List.map Action.save content.actions}

-- Publicly Exposed Doesn't Return Slipbox
searchSlipbox: String -> Slipbox -> (List Note.Extract)
searchSlipbox query slipbox =
  case slipbox of
     Slipbox content -> 
      content.notes
        |> List.filter (Note.search query)
        |> List.map Note.extract
  
getGraphElements: Slipbox -> ((List GraphNote), (List GraphLink))
getGraphElements slipbox =
  case slipbox of
    Slipbox content -> 
      ( List.map toGraphNote (List.map Note.extract content.notes)
      , List.filterMap (\link -> toGraphLink link content.notes) content.links)

getSelectedNotes: Slipbox -> (List DescriptionNote)
getSelectedNotes slipbox =
  case slipbox of 
    Slipbox content -> 
      content.notes
       |> List.filter Note.isSelected
       |> List.map (toDescriptionNote content.notes content.links)

getHistory: Slipbox -> (List Action.Summary)
getHistory slipbox =
  case slipbox of
    Slipbox content -> List.map Action.summary content.actions

getLinkFormData: Slipbox -> LinkForm.LinkFormData
getLinkFormData slipbox =
  case slipbox of
    Slipbox content -> 
      LinkForm.linkFormData (getFormNotes content.notes content.links) content.form

isCompleted: Slipbox -> Bool
isCompleted slipbox =
  case slipbox of
    Slipbox content -> Simulation.isCompleted content.state

buildSaveRequest: Slipbox -> Encode.Value
buildSaveRequest slipbox =
  case slipbox of
    Slipbox content -> toSaveRequest content.actions

canSave: Slipbox -> Bool
canSave slipbox =
  case slipbox of 
    Slipbox content -> 
      let
        unsavedActions = List.filter (\a -> Action.actionIsSaved a |> not) content.actions 
      in
        List.length unsavedActions > 0

-- Helpers

toSaveRequest: (List Action.Action) -> Encode.Value
toSaveRequest actions =
  Encode.object 
    [ ("create_note", List.filterMap getIfCreate actions |> Encode.list saveRequestNoteToValue)
    , ("edit_note", List.filterMap getIfEdit actions |> Encode.list saveRequestNoteEditToValue)
    , ("delete_note", List.filterMap getIfDelete actions |> Encode.list saveRequestNoteToValue)
    , ("create_link", List.filterMap getIfCreateLink actions |> Encode.list saveRequestLinkToValue)
    , ("delete_link", List.filterMap getIfDeleteLink actions |> Encode.list saveRequestLinkToValue)
    ]

saveRequestNoteToValue: Action.SaveRequestNote -> Encode.Value
saveRequestNoteToValue record =
  Encode.object
    [ ("action_id", Encode.int record.action_id)
    , ("id_", Encode.int record.id_)
    , ("content", Encode.string record.content)
    , ("source", Encode.string record.source)
    , ("variant", Encode.string record.variant)
    ]

saveRequestNoteEditToValue: Action.SaveRequestNoteEdit -> Encode.Value
saveRequestNoteEditToValue record =
  Encode.object
    [ ("action_id", Encode.int record.action_id)
    , ("id_", Encode.int record.id_)
    , ("new_content", Encode.string record.new_content)
    , ("old_content", Encode.string record.old_content)
    , ("new_source", Encode.string record.new_source)
    , ("old_source", Encode.string record.old_source)
    , ("variant", Encode.string record.variant)
    ]

saveRequestLinkToValue: Action.SaveRequestLink -> Encode.Value
saveRequestLinkToValue record =
  Encode.object
    [ ("action_id", Encode.int record.action_id)
    , ("id_", Encode.int record.id_)
    , ("source", Encode.int record.source)
    , ("target", Encode.int record.target)
    ]

getIfCreate: Action.Action -> (Maybe Action.SaveRequestNote)
getIfCreate action =
  case Action.extract action of
     Action.CreateNoteSave record -> Just record
     Action.EditNoteSave _ -> Nothing
     Action.DeleteNoteSave _ -> Nothing
     Action.CreateLinkSave _ -> Nothing
     Action.DeleteLinkSave _ -> Nothing
     Action.AlreadySaved -> Nothing

getIfEdit: Action.Action -> (Maybe Action.SaveRequestNoteEdit)
getIfEdit action =
  case Action.extract action of
     Action.CreateNoteSave _ -> Nothing
     Action.EditNoteSave record -> Just record
     Action.DeleteNoteSave _ -> Nothing
     Action.CreateLinkSave _ -> Nothing
     Action.DeleteLinkSave _ -> Nothing
     Action.AlreadySaved -> Nothing

getIfDelete: Action.Action -> (Maybe Action.SaveRequestNote)
getIfDelete action =
  case Action.extract action of
     Action.CreateNoteSave _ -> Nothing
     Action.EditNoteSave _ -> Nothing
     Action.DeleteNoteSave record -> Just record
     Action.CreateLinkSave _ -> Nothing
     Action.DeleteLinkSave _ -> Nothing
     Action.AlreadySaved -> Nothing

getIfCreateLink: Action.Action -> (Maybe Action.SaveRequestLink)
getIfCreateLink action =
  case Action.extract action of
     Action.CreateNoteSave _ -> Nothing
     Action.EditNoteSave _ -> Nothing
     Action.DeleteNoteSave _ -> Nothing
     Action.CreateLinkSave record -> Just record
     Action.DeleteLinkSave _ -> Nothing
     Action.AlreadySaved -> Nothing

getIfDeleteLink: Action.Action -> (Maybe Action.SaveRequestLink)
getIfDeleteLink action =
  case Action.extract action of
     Action.CreateNoteSave _ -> Nothing
     Action.EditNoteSave _ -> Nothing
     Action.DeleteNoteSave _ -> Nothing
     Action.CreateLinkSave _ -> Nothing
     Action.DeleteLinkSave record -> Just record
     Action.AlreadySaved -> Nothing

initializeNotes: (List Note.NoteRecord) -> (List Link) -> (Simulation.State Int, (List Note.Note))
initializeNotes notes links =
  let
    (state, newNotes) = initSimulation (List.map Note.init notes) links
  in
    (state, sortNotes newNotes)

sortNotes: (List Note.Note) -> (List Note.Note)
sortNotes notes =
  List.sortWith Note.sortDesc notes

toSimulationRecord: Note.Extract -> Simulation.SimulationRecord
toSimulationRecord extract =
  Simulation.SimulationRecord extract.intId extract.x extract.y extract.vx extract.vy

toLinkTuple: Link -> (Int, Int)
toLinkTuple link =
  (link.source, link.target)

noteUpdateWrapper: (List Simulation.SimulationRecord) -> Note.Note -> Note.Note
noteUpdateWrapper simRecords note =
  let
    extract = Note.extract note
    maybeSimRecord = List.head (List.filter (\sr -> sr.id == extract.intId) simRecords)
  in
    case maybeSimRecord of
      Just simRecord -> Note.update simRecord note
      Nothing -> note

initSimulation: (List Note.Note) -> (List Link) -> (Simulation.State Int, (List Note.Note))
initSimulation notes links =
  let
    (state, simRecords) = Simulation.simulate 
      (List.map toSimulationRecord (List.map Note.extract notes))
      (List.map toLinkTuple links)
  in
    (state, List.map (noteUpdateWrapper simRecords) notes)

toGraphNote: Note.Extract -> GraphNote
toGraphNote extract =
  GraphNote extract.id extract.intId extract.x extract.y extract.variant extract.selected.hover

initializeLinks: (List LinkRecord) -> (List Link)
initializeLinks linkRecords =
  List.sortWith linkSorterDesc (List.map (\lr -> Link lr.source lr.target lr.id) linkRecords)

linkSorterDesc: (Link -> Link -> Order)
linkSorterDesc linkA linkB =
  case compare linkA.id linkB.id of
    LT -> GT
    EQ -> EQ
    GT -> LT

toGraphLink: Link -> (List Note.Note) -> (Maybe GraphLink)
toGraphLink link notes =
  let
      source = findNoteByInt link.source notes
      target = findNoteByInt link.target notes
  in
    Maybe.map3 graphLinkBuilder source target (Just link.id)

actionsInit: ActionResponse -> (List Action.Action)
actionsInit response =
  List.sortWith Action.sortDesc 
    (List.map createNoteAction response.create_note 
    ++ List.map (\n -> Action.editNote n.id n.action) response.edit_note
    ++ List.map deleteNoteAction response.delete_note
    ++ List.map (\n -> Action.createLink n.id n.action) response.create_link
    ++ List.map (\n -> Action.deleteLink n.id n.action) response.delete_link
    )
    |> List.map Action.save

createNoteAction: CreateNoteRecord -> Action.Action
createNoteAction note =
  Action.createNote note.id 
    (Action.CreateNoteRecord note.action.id note.action.content note.action.source note.action.noteType)

deleteNoteAction: CreateNoteRecord -> Action.Action
deleteNoteAction note =
  Action.deleteNote note.id 
    (Action.CreateNoteRecord note.action.id note.action.content note.action.source note.action.noteType)
    
graphLinkBuilder: Note.Note -> Note.Note -> LinkId -> GraphLink
graphLinkBuilder source target id =
  let
    sourceExtract = Note.extract source
    targetExtract = Note.extract target
  in
  GraphLink sourceExtract.intId sourceExtract.x sourceExtract.y targetExtract.intId targetExtract.x targetExtract.y id

toDescriptionNote: (List Note.Note) -> (List Link) -> Note.Note -> DescriptionNote
toDescriptionNote notes links note =
  let
    extract = Note.extract note
  in
    DescriptionNote 
      extract.id 
      extract.x 
      extract.y 
      extract.content 
      extract.source 
      extract.selected.inEdit
      (getDescriptionLinks notes extract.intId links)

getDescriptionLinks: (List Note.Note) -> Int -> (List Link) -> (List DescriptionLink)
getDescriptionLinks notes noteId links =
  List.map toDescriptionLink (getLinkedNotes notes noteId links)

toDescriptionLink: (Note.Note, Link) -> DescriptionLink
toDescriptionLink (note, link) =
  let
    extract = Note.extract note
  in
    DescriptionLink extract.id extract.intId extract.x extract.y link.id

getLinkedNotes: (List Note.Note) -> Int -> (List Link) -> (List (Note.Note, Link))
getLinkedNotes notes noteId links =
  List.filterMap (\l -> linkWrapper (maybeNoteFromLink notes noteId l) l) links

linkWrapper: (Maybe Note.Note) -> Link -> (Maybe (Note.Note, Link))
linkWrapper maybeNote link =
  Maybe.map2 toNoteLinkTuple maybeNote (Just link) 

toNoteLinkTuple: Note.Note -> Link -> (Note.Note, Link)
toNoteLinkTuple note link = (note, link)

maybeNoteFromLink: (List Note.Note) -> Int -> Link -> (Maybe (Note.Note))
maybeNoteFromLink notes noteId link =
  if link.source == noteId then 
    findNoteByInt link.target notes
  else if link.target == noteId then 
    findNoteByInt link.source notes
  else 
    Nothing

getLinksForNote: Int -> (List Link) -> (List Link)
getLinksForNote noteId links =
  List.filterMap (getMaybeLink noteId) links

getMaybeLink: Int -> Link -> (Maybe Link)
getMaybeLink noteId link =
  if link.source == noteId then 
    Just link
  else if link.target == noteId then 
    Just link
  else 
    Nothing

findNote: Note.NoteId -> (List Note.Note) -> (Maybe Note.Note)
findNote noteId notes =
  List.head (List.filter (Note.isNote noteId) notes)

findNoteByInt: Int -> (List Note.Note) -> (Maybe Note.Note)
findNoteByInt noteId notes =
  List.head (List.filter (Note.isNoteInt noteId) notes)

toNoteRecord: MakeNoteRecord -> (List Note.Note) -> Note.NoteRecord
toNoteRecord note notes =
  Note.NoteRecord (getNextNoteId notes) note.content note.source note.noteType

getNextNoteId: (List Note.Note) -> Int
getNextNoteId notes = 
  case List.head notes of
    Just note -> Note.subsequentNoteId note
    Nothing -> 1

addNoteToNotes: Note.NoteRecord -> (List Note.Note) -> (List Link) -> (Simulation.State Int, (List Note.Note))
addNoteToNotes note notes links =
  initSimulation ( Note.init note :: notes) links

addNoteToActions : Note.NoteRecord -> (List Action.Action) -> (List Action.Action)
addNoteToActions note actions =
  let
    newActions = List.filter (\a -> not (Action.shouldRemove a)) actions
  in
    Action.createNote 
      (nextActionId newActions) 
      (Action.CreateNoteRecord note.id note.content note.source note.noteType) :: newActions

addEditNoteToActions: Note.Edits -> Note.Extract -> (List Action.Action) -> (List Action.Action)
addEditNoteToActions edits extract actions =
  let
    newActions = List.filter (\a -> not (Action.shouldRemove a)) actions
  in
    Action.editNote 
      (nextActionId newActions) 
      (toEditNoteRecord edits extract) :: newActions

toEditNoteRecord: Note.Edits -> Note.Extract -> Action.EditNoteRecord
toEditNoteRecord edits extract =
  Action.EditNoteRecord extract.intId extract.content edits.content extract.source edits.source extract.variant


nextActionId: (List Action.Action) -> Int
nextActionId actions =
  case List.head actions of
    Just action -> Action.subsequentActionId action
    Nothing -> 1

addLinkToActions: Link -> (List Action.Action) -> (List Action.Action)
addLinkToActions link actions =
  let
    newActions = List.filter (\a -> not (Action.shouldRemove a)) actions
  in
  Action.createLink 
    (nextActionId newActions) 
    (Action.CreateLinkRecord link.id link.source link.target)
    :: newActions

toMaybeLink: MakeLinkRecord -> (List Link) -> (List Note.Note) -> (Maybe Link)
toMaybeLink makeLinkRecord links notes =
  let
      source = makeLinkRecord.source
      target = makeLinkRecord.target
  in
  
  if linkRecordIsValid source target notes then
    Just (Link source target (nextLinkId links))
  else 
    Nothing

linkRecordIsValid: Int -> Int -> (List Note.Note) -> Bool
linkRecordIsValid source target notes =
  noteExists source notes && noteExists target notes

noteExists: Int -> (List Note.Note) -> Bool
noteExists noteId notes =
  let
    extracts = List.map Note.extract notes
  in
  List.member noteId (List.map (\note -> note.intId) extracts)

nextLinkId: (List Link) -> Int
nextLinkId links =
  let
    mLink = List.head links
  in
    case mLink of
      Just link -> link.id + 1
      Nothing -> 1

getFormNotes: (List Note.Note) -> (List Link) -> (List LinkForm.FormNote)
getFormNotes notes links =
  notes
    |> List.filter Note.isSelected
    |> List.map (\note -> toFormNote note links)

toFormNote: Note.Note -> (List Link) -> LinkForm.FormNote
toFormNote note links =
  let
    extract = Note.extract note
  in
    LinkForm.FormNote extract.intId extract.content (Note.isIndex note) (getNoteIds extract.intId links)

getNoteIds: Int -> (List Link) -> (List Int)
getNoteIds noteId links =
  List.filterMap (\link -> maybeGetNoteId noteId link) links

maybeGetNoteId: Int -> Link -> (Maybe Int)
maybeGetNoteId noteId link =
  if link.source == noteId then 
    Just link.target
  else if link.target == noteId then 
    Just link.source
  else 
    Nothing

wasEdited: Note.Edits -> Note.Extract -> Bool
wasEdited edits extract = extract.content /= edits.content || extract.source /= edits.source

removeAssociatedLinks: (List LinkId) -> (List Link) -> (List Link)
removeAssociatedLinks linkIds links =
  List.filter (\link -> not (List.member link.id linkIds)) links

addDeleteNoteActionHandler: (Note.Extract) -> (List Link) -> (List Action.Action) -> (List Action.Action)
addDeleteNoteActionHandler extract links actions =
  let
    newActions = List.filter (\a -> not (Action.shouldRemove a)) actions
    deleteNoteActionn = toDeleteNoteAction (nextActionId newActions) extract
    actionsWithDeleteNote = deleteNoteActionn :: newActions
    deleteLinkActions = List.indexedMap (\index link -> toDeleteLinkAction (nextActionId actionsWithDeleteNote + index) link) links
  in
    List.sortWith Action.sortDesc (List.append deleteLinkActions actionsWithDeleteNote)
    
toDeleteLinkAction: Int -> Link -> Action.Action
toDeleteLinkAction historyId link =
  Action.deleteLink historyId (Action.DeleteLinkRecord link.id link.source link.target)

toDeleteNoteAction: Int -> Note.Extract -> Action.Action
toDeleteNoteAction historyId extract =
  Action.deleteNote historyId (Action.DeleteNoteRecord extract.intId extract.content extract.source extract.variant)

findLink: LinkId -> (List Link) -> (Maybe Link)
findLink linkId links =
  List.head (List.filter (isLink linkId) links)

addDeleteLink: Link -> (List Action.Action) -> (List Action.Action)
addDeleteLink link actions =
  let
    newActions = List.filter (\a -> not (Action.shouldRemove a)) actions
  in
    Action.deleteLink 
      (nextActionId newActions)
      (Action.DeleteLinkRecord link.id link.source link.target) :: newActions

isLink: Int -> Link -> Bool
isLink linkId link = linkId == link.id


--Refactor this function out
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

removeSelections: Content -> Slipbox
removeSelections content =
  Slipbox {content | form = getFormNotes content.notes content.links |> LinkForm.removeSelections}

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


-- Operate By ID
doIfInstance: (b -> a -> Bool) -> (a -> a) -> b -> a -> a
doIfInstance verified transform id instance =
  if verified id instance then
    transform instance
  else 
    instance

removeLinkById: Int -> (List Link) -> (List Link)
removeLinkById linkId links =
  List.filter (\l -> not (isLink linkId l)) links

deleteNoteById: Note.NoteId -> (List Note.Note) -> (List Note.Note)
deleteNoteById noteId notes =
  List.filter (\l -> not (Note.isNote noteId l)) notes

undoActionsById: Int -> (List Action.Action) -> (List Action.Action)
undoActionsById actionId actions = 
  List.map (doIfInstance Action.shouldUndo Action.undo actionId) actions

redoActionsById: Int -> (List Action.Action) -> (List Action.Action)
redoActionsById actionId actions = 
  List.map (doIfInstance Action.shouldRedo Action.redo actionId) actions

sourceUpdateById: String -> Note.NoteId -> (List Note.Note) -> (List Note.Note)
sourceUpdateById source noteId notes =
    List.map (doIfInstance Note.isNote (Note.sourceUpdate source) noteId) notes

contentUpdateById: String -> Note.NoteId -> (List Note.Note) -> (List Note.Note)
contentUpdateById content noteId notes =
    List.map (doIfInstance Note.isNote (Note.contentUpdate content) noteId) notes

submitEditsById: Note.NoteId -> (List Note.Note) -> (List Note.Note)
submitEditsById noteId notes =
  List.map (doIfInstance Note.isNote Note.submitEdits noteId) notes

discardEditsById: Note.NoteId -> (List Note.Note) -> (List Note.Note)
discardEditsById noteId notes =
  List.map (doIfInstance Note.isNote Note.discardEdits noteId) notes

startEditStateById: Note.NoteId -> (List Note.Note) -> (List Note.Note)
startEditStateById noteId notes =
  List.map (doIfInstance Note.isNote Note.startEditState noteId) notes

selectById: Note.NoteId -> (List Note.Note) -> (List Note.Note)
selectById noteId notes =
  List.map (doIfInstance Note.isNote Note.select noteId) notes

unSelectById: Note.NoteId -> (List Note.Note) -> (List Note.Note)
unSelectById noteId notes =
  List.map (doIfInstance Note.isNote Note.unSelect noteId) notes

hoverById: Note.NoteId -> Note.Note -> Note.Note
hoverById noteId note =
  if Note.isNote noteId note then
    Note.hover note
  else
    Note.unHover note