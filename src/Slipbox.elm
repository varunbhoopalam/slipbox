module Slipbox exposing (Slipbox, LinkRecord, initialize
  , selectNote, dismissNote, stopHoverNote, searchSlipbox
  , getGraphElements, GraphNote, GraphLink, getSelectedNotes, DescriptionNote
  , DescriptionLink, hoverNote, CreateNoteRecord, CreateLinkRecord
  , getHistory, createNote, MakeNoteRecord, MakeLinkRecord
  , createLink, sourceSelected, targetSelected, getLinkFormData
  , startEditState, discardEdits, submitEdits, contentUpdate
  , sourceUpdate, deleteNote, deleteLink, undo, redo, ActionResponse
  , EditNoteRecordWrapper, isCompleted, tick)

import Simulation
import LinkForm
import Note
import Action
import Debug

--Types
type Slipbox = Slipbox (List Note.Note) (List Link) (List Action.Action) LinkForm.LinkForm (Simulation.State Int)

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
    Slipbox newNotes l (actionsInit response) LinkForm.initLinkForm state

selectNote: Note.NoteId -> Slipbox -> Slipbox
selectNote noteId slipbox =
  case slipbox of 
    Slipbox notes links actions form state-> 
      Slipbox (selectById noteId notes) links actions 
        (LinkForm.selectionsChange form (getFormNotes (selectById noteId notes) links)) state

dismissNote: Note.NoteId -> Slipbox -> Slipbox
dismissNote noteId slipbox =
  case slipbox of 
    Slipbox notes links actions form state -> 
      Slipbox (unSelectById noteId notes) links actions 
        (LinkForm.selectionsChange form (getFormNotes (unSelectById noteId notes) links))
        state

hoverNote: Note.NoteId -> Slipbox -> Slipbox
hoverNote noteId slipbox =
  case slipbox of 
    Slipbox notes links actions form state -> Slipbox (List.map (hoverById noteId) notes) links actions form state

stopHoverNote: Slipbox -> Slipbox
stopHoverNote slipbox =
  case slipbox of 
    Slipbox notes links history form state -> Slipbox (List.map Note.unHover notes) links history form state

createNote: MakeNoteRecord -> Slipbox -> Slipbox
createNote note slipbox =
  case slipbox of
     Slipbox notes links actions form _ -> handleCreateNote note notes links actions form

handleCreateNote: MakeNoteRecord -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
handleCreateNote makeNoteRecord notes links actions form =
  let
    newNote = toNoteRecord makeNoteRecord notes
    (state, newNotes) = addNoteToNotes newNote notes links
  in
    Slipbox (sortNotes newNotes) links (addNoteToActions newNote actions) form state

createLink: Slipbox -> Slipbox
createLink slipbox =
  case slipbox of 
    Slipbox notes links actions form state -> createLinkHandler (LinkForm.maybeProspectiveLink form) notes links actions state
  
createLinkHandler: (Maybe (Int, Int)) -> (List Note.Note) -> (List Link) -> (List Action.Action) -> (Simulation.State Int) -> Slipbox
createLinkHandler maybeTuple notes links actions state =
  case maybeTuple of
    Just (source, target) -> createLinkHandlerFork (MakeLinkRecord source target) notes links actions state
    Nothing -> removeSelectionsFork notes links actions state

createLinkHandlerFork: MakeLinkRecord -> (List Note.Note) -> (List Link) -> (List Action.Action) -> (Simulation.State Int) -> Slipbox
createLinkHandlerFork makeLinkRecord notes links actions state =
  case toMaybeLink makeLinkRecord links notes of
    Just link -> addLinkToSlipbox link notes links actions
    Nothing -> removeSelectionsFork notes links actions state

removeSelectionsFork: (List Note.Note) -> (List Link) -> (List Action.Action) -> (Simulation.State Int)-> Slipbox
removeSelectionsFork notes links actions state =
  Slipbox notes links actions (LinkForm.removeSelections (getFormNotes notes links)) state

addLinkToSlipbox: Link -> (List Note.Note) -> (List Link) -> (List Action.Action) -> Slipbox
addLinkToSlipbox link notes links actions =
  let
    newLinks =  link :: links
    (state, newNotes) = initSimulation notes newLinks
  in
    Slipbox 
      newNotes
      newLinks
      (addLinkToActions link actions)
      (LinkForm.removeSelections (getFormNotes notes links))
      state

sourceSelected: String -> Slipbox -> Slipbox
sourceSelected source slipbox =
  case slipbox of
    Slipbox notes links actions form state -> Slipbox notes links actions (LinkForm.addSource source form) state

targetSelected: String -> Slipbox -> Slipbox
targetSelected target slipbox =
  case slipbox of
    Slipbox notes links actions form state -> Slipbox notes links actions (LinkForm.addTarget target form) state

startEditState: Note.NoteId -> Slipbox -> Slipbox
startEditState noteId slipbox =
  case slipbox of
    Slipbox notes links actions form state ->
      Slipbox (startEditStateById noteId notes) links actions form state

discardEdits: Note.NoteId -> Slipbox -> Slipbox
discardEdits noteId slipbox =
  case slipbox of
    Slipbox notes links actions form state ->
      Slipbox (discardEditsById noteId notes) links actions form state 

submitEdits: Note.NoteId -> Slipbox -> Slipbox
submitEdits noteId slipbox =
  case slipbox of
    Slipbox notes links actions form state -> submitEditsHandler noteId notes links actions form state

submitEditsHandler: Note.NoteId -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> (Simulation.State Int) -> Slipbox
submitEditsHandler noteId notes links actions form state =
  case findNote noteId notes of
    Just note -> submitEditsNoteFound note notes links actions form state
    Nothing -> Slipbox notes links actions form state

submitEditsNoteFound: Note.Note -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> (Simulation.State Int) -> Slipbox
submitEditsNoteFound note notes links actions form state =
  let
    extract = Note.extract note
  in
    editHandler extract notes links actions form state

editHandler: Note.Extract -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> (Simulation.State Int) -> Slipbox
editHandler extract notes links actions form state =
  case extract.selected.edits of
    Just edits -> editMadeHandler edits extract notes links actions form state
    Nothing -> Slipbox notes links actions form state

editMadeHandler: Note.Edits -> Note.Extract -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> (Simulation.State Int) -> Slipbox
editMadeHandler edits extract notes links actions form state =
  if wasEdited edits extract then
    Slipbox (submitEditsById extract.id notes) links (addEditNoteToActions edits extract actions) form state
  else
    Slipbox notes links actions form state

contentUpdate: String -> Note.NoteId -> Slipbox -> Slipbox
contentUpdate content noteId slipbox =
  case slipbox of
    Slipbox notes links actions form state ->
      Slipbox (contentUpdateById content noteId notes) links actions form state 

sourceUpdate: String -> Note.NoteId -> Slipbox -> Slipbox
sourceUpdate source noteId slipbox =
  case slipbox of
    Slipbox notes links actions form state ->
      Slipbox (sourceUpdateById source noteId notes) links actions form state 

deleteNote: Note.NoteId -> Slipbox -> Slipbox
deleteNote noteId slipbox =
  case slipbox of
    Slipbox notes links actions form state -> deleteNoteHandler noteId notes links actions form state  

deleteNoteHandler: Note.NoteId -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> (Simulation.State Int) -> Slipbox
deleteNoteHandler noteId notes links actions form state =
  case findNote noteId notes of
    Just note -> deleteNoteFoundHandler note notes links actions form
    Nothing -> Slipbox notes links actions form state

deleteNoteFoundHandler: Note.Note -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
deleteNoteFoundHandler note notes links actions form =
  let
    extract = Note.extract note
    associatedLinks = getLinksForNote extract.intId links
    notesAfterNoteRemoval = deleteNoteById extract.id notes
    newLinks = removeAssociatedLinks (List.map (\link -> link.id) associatedLinks) links
    (state, newNotes) = initSimulation notesAfterNoteRemoval newLinks
    
  in
    Slipbox 
      newNotes
      newLinks
      (addDeleteNoteActionHandler extract associatedLinks actions) 
      (LinkForm.selectionsChange form (getFormNotes notes links))
      state

deleteLink: Int -> Slipbox -> Slipbox
deleteLink linkId slipbox =
  case slipbox of
    Slipbox notes links actions form state -> deleteLinkHandler linkId notes links actions form state

deleteLinkHandler: Int -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> (Simulation.State Int) -> Slipbox
deleteLinkHandler linkId notes links actions form state =
  case findLink linkId links of
    Just link -> deleteLinkFoundHandler link notes links actions form
    Nothing -> Slipbox notes links actions form state

deleteLinkFoundHandler: Link -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
deleteLinkFoundHandler link notes links actions form =
  let
    newLinks = removeLinkById link.id links
    (state, newNotes) = initSimulation notes newLinks
  in
    Slipbox 
      newNotes
      newLinks 
      (addDeleteLink link actions)
      (LinkForm.selectionsChange form (getFormNotes notes newLinks))
      state

undo: Int -> Slipbox -> Slipbox
undo actionId slipbox =
  case slipbox of
    Slipbox notes links actions form state -> undoHandler actionId notes links actions form state

undoHandler: Int -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> (Simulation.State Int) -> Slipbox
undoHandler actionId notes links actions form state =
  let
    recordsToBeUndone = List.map Action.record_ (List.filter (Action.shouldUndo actionId) actions)
    undoneSlipbox = List.foldr undoRecord (Slipbox notes links actions form state) recordsToBeUndone
    undoneActions = undoActionsById actionId actions
  in
    case undoneSlipbox of
      Slipbox notes_ links_ _ form_ state_ -> Slipbox notes_ links_ undoneActions form_ state_

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
    Slipbox notes links actions form state -> redoHandler actionId notes links actions form state

redoHandler: Int -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> (Simulation.State Int) -> Slipbox
redoHandler actionId notes links actions form state =
  let
    recordsToBeRedone = List.map Action.record_ (List.filter (Action.shouldRedo actionId) actions)
    redoneSlipbox = List.foldr redoRecord (Slipbox notes links actions form state) recordsToBeRedone
    redoneActions = redoActionsById actionId actions
  in
    case redoneSlipbox of
      Slipbox notes_ links_ _ form_ state_ -> Slipbox notes_ links_ redoneActions form_ state_

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
     Slipbox notes links actions form state -> tickHandler notes links actions form state

tickHandler: (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Simulation.State Int -> Slipbox
tickHandler notes links actions form state =
  let
    (newState, simRecords) = Simulation.tick state (List.map toSimulationRecord (List.map Note.extract notes))
  in
    Slipbox (List.map (noteUpdateWrapper simRecords) notes) links actions form newState
  

-- Publicly Exposed Doesn't Return Slipbox
searchSlipbox: String -> Slipbox -> (List Note.Extract)
searchSlipbox query slipbox =
  case slipbox of
     Slipbox notes _ _ _ _-> 
      notes
        |> List.filter (Note.search query)
        |> List.map Note.extract
  
getGraphElements: Slipbox -> ((List GraphNote), (List GraphLink))
getGraphElements slipbox =
  case slipbox of
    Slipbox notes links _ _ _ -> 
      ( List.map toGraphNote (List.map Note.extract notes)
      , List.filterMap (\link -> toGraphLink link notes) links)

getSelectedNotes: Slipbox -> (List DescriptionNote)
getSelectedNotes slipbox =
  case slipbox of 
    Slipbox notes links _ _ _ -> 
      notes
       |> List.filter Note.isSelected
       |> List.map (toDescriptionNote notes links)

getHistory: Slipbox -> (List Action.Summary)
getHistory slipbox =
  case slipbox of
    Slipbox _ _ actions _ _ -> List.map Action.summary actions

getLinkFormData: Slipbox -> LinkForm.LinkFormData
getLinkFormData slipbox =
  case slipbox of
    Slipbox notes links _ form _ -> 
      LinkForm.linkFormData (getFormNotes notes links) form

isCompleted: Slipbox -> Bool
isCompleted slipbox =
  case slipbox of
    Slipbox _ _ _ _ state -> Simulation.isCompleted state

-- Helpers
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

createNoteInternal: Note.NoteRecord -> Slipbox -> Slipbox
createNoteInternal note slipbox =
  case slipbox of 
    Slipbox notes links actions form _ -> createNoteInternal_ note notes links actions form

createNoteInternal_: Note.NoteRecord -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
createNoteInternal_ note notes links actions form =
  let
    (state, newNotes) = addNoteToNotes note notes links
  in
    Slipbox newNotes links actions form state


createLinkInternal: Link -> Slipbox -> Slipbox
createLinkInternal link slipbox =
  case slipbox of
    Slipbox notes links actions _ _ -> createLinkInternal_ link notes links actions

createLinkInternal_: Link -> (List Note.Note) -> (List Link) -> (List Action.Action) -> Slipbox
createLinkInternal_ link notes links actions =
  let
    newLinks = link :: links
    (state, newNotes) = initSimulation notes newLinks
  in
    Slipbox newNotes newLinks actions (LinkForm.removeSelections (getFormNotes newNotes newLinks)) state

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