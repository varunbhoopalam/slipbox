module Slipbox exposing (Slipbox, LinkRecord, initialize
  , selectNote, dismissNote, stopHoverNote, searchSlipbox, SearchResult
  , getGraphElements, GraphNote, GraphLink, getSelectedNotes, DescriptionNote
  , DescriptionLink, hoverNote, CreateNoteRecord, CreateLinkRecord
  , getHistory, createNote, MakeNoteRecord, MakeLinkRecord
  , createLink, sourceSelected, targetSelected, getLinkFormData
  , startEditState, discardEdits, submitEdits, contentUpdate
  , sourceUpdate, deleteNote, deleteLink, undo, redo)

import Simulation
import LinkForm
import Note
import Action
import Debug

--Types
type Slipbox = Slipbox (List Note.Note) (List Link) (List Action.Action) LinkForm.LinkForm

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

type alias SearchResult = 
  { id : Note.NoteId
  , idInt: Int
  , x : Float
  , y : Float
  , variant : String
  , content : String
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

-- Methods

-- Returns Slipbox
initialize: (List Note.NoteRecord) -> (List LinkRecord) -> ((List CreateNoteRecord), (List CreateLinkRecord)) -> Slipbox
initialize notes links (noteRecords, linkRecords) =
  let
    l =  initializeLinks links
  in
    Slipbox (initializeNotes notes l) l (actionsInit (noteRecords, linkRecords)) LinkForm.initLinkForm

selectNote: Note.NoteId -> Slipbox -> Slipbox
selectNote noteId slipbox =
  case slipbox of 
    Slipbox notes links actions form -> 
      Slipbox (selectById noteId notes) links actions 
        (LinkForm.selectionsChange form (getFormNotes (selectById noteId notes) links))

dismissNote: Note.NoteId -> Slipbox -> Slipbox
dismissNote noteId slipbox =
  case slipbox of 
    Slipbox notes links actions form -> 
      Slipbox (unSelectById noteId notes) links actions 
      (LinkForm.selectionsChange form (getFormNotes (unSelectById noteId notes) links))

hoverNote: Note.NoteId -> Slipbox -> Slipbox
hoverNote noteId slipbox =
  case slipbox of 
    Slipbox notes links actions form-> Slipbox (List.map (hoverById noteId) notes) links actions form

stopHoverNote: Slipbox -> Slipbox
stopHoverNote slipbox =
  case slipbox of 
    Slipbox notes links history form -> Slipbox (List.map Note.unHover notes) links history form

createNote: MakeNoteRecord -> Slipbox -> Slipbox
createNote note slipbox =
  case slipbox of
     Slipbox notes links actions form -> handleCreateNote note notes links actions form

handleCreateNote: MakeNoteRecord -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
handleCreateNote makeNoteRecord notes links actions form =
  let
    newNote = toNoteRecord makeNoteRecord notes
    newNoteList = addNoteToNotes newNote notes links
  in
    Slipbox (sortNotes newNoteList) links (addNoteToActions newNote actions) form

createLink: Slipbox -> Slipbox
createLink slipbox =
  case slipbox of 
    Slipbox notes links actions form -> createLinkHandler (LinkForm.maybeProspectiveLink form) notes links actions
  
createLinkHandler: (Maybe (Int, Int)) -> (List Note.Note) -> (List Link) -> (List Action.Action) -> Slipbox
createLinkHandler maybeTuple notes links actions =
  case maybeTuple of
    Just (source, target) -> createLinkHandlerFork (MakeLinkRecord source target) notes links actions
    Nothing -> removeSelectionsFork notes links actions

createLinkHandlerFork: MakeLinkRecord -> (List Note.Note) -> (List Link) -> (List Action.Action) -> Slipbox
createLinkHandlerFork makeLinkRecord notes links actions =
  case toMaybeLink makeLinkRecord links notes of
    Just link -> addLinkToSlipbox link notes links actions
    Nothing -> removeSelectionsFork notes links actions

removeSelectionsFork: (List Note.Note) -> (List Link) -> (List Action.Action) -> Slipbox
removeSelectionsFork notes links actions =
  Slipbox notes links actions (LinkForm.removeSelections (getFormNotes notes links))

addLinkToSlipbox: Link -> (List Note.Note) -> (List Link) -> (List Action.Action) -> Slipbox
addLinkToSlipbox link notes links actions =
  let
    newLinks =  link :: links
  in
    Slipbox 
      (initSimulation notes newLinks)
      newLinks
      (addLinkToActions link actions)
      (LinkForm.removeSelections (getFormNotes notes links))

sourceSelected: String -> Slipbox -> Slipbox
sourceSelected source slipbox =
  case slipbox of
    Slipbox notes links actions form -> Slipbox notes links actions (LinkForm.addSource source form)

targetSelected: String -> Slipbox -> Slipbox
targetSelected target slipbox =
  case slipbox of
    Slipbox notes links actions form -> Slipbox notes links actions (LinkForm.addTarget target form)

startEditState: Note.NoteId -> Slipbox -> Slipbox
startEditState noteId slipbox =
  case slipbox of
    Slipbox notes links actions form ->
      Slipbox (startEditStateById noteId notes) links actions form

discardEdits: Note.NoteId -> Slipbox -> Slipbox
discardEdits noteId slipbox =
  case slipbox of
    Slipbox notes links actions form ->
      Slipbox (discardEditsById noteId notes) links actions form

submitEdits: Note.NoteId -> Slipbox -> Slipbox
submitEdits noteId slipbox =
  case slipbox of
    Slipbox notes links actions form -> submitEditsHandler noteId notes links actions form

submitEditsHandler: Note.NoteId -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
submitEditsHandler noteId notes links actions form =
  case findNote noteId notes of
    Just note -> submitEditsNoteFound note notes links actions form
    Nothing -> Slipbox notes links actions form

submitEditsNoteFound: Note.Note -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
submitEditsNoteFound note notes links actions form =
  let
    extract = Note.extract note
  in
    editHandler extract notes links actions form

editHandler: Note.Extract -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
editHandler extract notes links actions form =
  case extract.selected.edits of
    Just edits -> editMadeHandler edits extract notes links actions form
    Nothing -> Slipbox notes links actions form

editMadeHandler: Note.Edits -> Note.Extract -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
editMadeHandler edits extract notes links actions form =
  if wasEdited edits extract then
    Slipbox (submitEditsById extract.id notes) links (addEditNoteToActions edits extract actions) form
  else
    Slipbox notes links actions form

contentUpdate: String -> Note.NoteId -> Slipbox -> Slipbox
contentUpdate content noteId slipbox =
  case slipbox of
    Slipbox notes links actions form ->
      Slipbox (contentUpdateById content noteId notes) links actions form 

sourceUpdate: String -> Note.NoteId -> Slipbox -> Slipbox
sourceUpdate source noteId slipbox =
  case slipbox of
    Slipbox notes links actions form ->
      Slipbox (sourceUpdateById source noteId notes) links actions form 

deleteNote: Note.NoteId -> Slipbox -> Slipbox
deleteNote noteId slipbox =
  case slipbox of
    Slipbox notes links actions form -> deleteNoteHandler noteId notes links actions form  

deleteNoteHandler: Note.NoteId -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
deleteNoteHandler noteId notes links actions form =
  case findNote noteId notes of
    Just note -> deleteNoteFoundHandler note notes links actions form
    Nothing -> Slipbox notes links actions form

deleteNoteFoundHandler: Note.Note -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
deleteNoteFoundHandler note notes links actions form =
  let
    extract = Note.extract note
    associatedLinks = getLinksForNote extract.intId links
    newNotes = deleteNoteById extract.id notes
    newLinks = removeAssociatedLinks (List.map (\link -> link.id) associatedLinks) links
  in
    Slipbox 
      (initSimulation newNotes newLinks)
      newLinks
      (addDeleteNoteActionHandler extract associatedLinks actions) 
      (LinkForm.selectionsChange form (getFormNotes notes links))

deleteLink: Int -> Slipbox -> Slipbox
deleteLink linkId slipbox =
  case slipbox of
    Slipbox notes links actions form -> deleteLinkHandler linkId notes links actions form

deleteLinkHandler: Int -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
deleteLinkHandler linkId notes links actions form =
  case findLink linkId links of
    Just link -> deleteLinkFoundHandler link notes links actions form
    Nothing -> Slipbox notes links actions form

deleteLinkFoundHandler: Link -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
deleteLinkFoundHandler link notes links actions form =
  let
    newLinks = (removeLinkById link.id links)
  in
    Slipbox 
      (initSimulation notes newLinks) 
      newLinks 
      (addDeleteLink link actions)
      (LinkForm.selectionsChange form (getFormNotes notes newLinks))

undo: Int -> Slipbox -> Slipbox
undo actionId slipbox =
  case slipbox of
    Slipbox notes links actions form -> undoHandler actionId notes links actions form

undoHandler: Int -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
undoHandler actionId notes links actions form =
  let
    recordsToBeUndone = List.map Action.record_ (List.filter (Action.shouldUndo actionId) actions)
    undoneSlipbox = List.foldr undoRecord (Slipbox notes links actions form) recordsToBeUndone
    undoneActions = undoActionsById actionId actions
    _ = Debug.log (Debug.toString recordsToBeUndone) 10000
  in
    case undoneSlipbox of
      Slipbox notes_ links_ _ form_ -> Slipbox notes_ links_ undoneActions form_

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
    Slipbox notes links actions form -> redoHandler actionId notes links actions form

redoHandler: Int -> (List Note.Note) -> (List Link) -> (List Action.Action) -> LinkForm.LinkForm -> Slipbox
redoHandler actionId notes links actions form =
  let
    recordsToBeRedone = List.map Action.record_ (List.filter (Action.shouldRedo actionId) actions)
    redoneSlipbox = List.foldr redoRecord (Slipbox notes links actions form) recordsToBeRedone
    redoneActions = redoActionsById actionId actions
  in
    case redoneSlipbox of
      Slipbox notes_ links_ _ form_ -> Slipbox notes_ links_ redoneActions form_

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

-- Publicly Exposed for View
searchSlipbox: String -> Slipbox -> (List SearchResult)
searchSlipbox query slipbox =
  case slipbox of
     Slipbox notes _ _ _-> 
      notes
        |> List.filter (Note.search query)
        |> List.map Note.extract
        |> List.map toSearchResult
  
getGraphElements: Slipbox -> ((List GraphNote), (List GraphLink))
getGraphElements slipbox =
  case slipbox of
    Slipbox notes links _ _ -> 
      ( List.map toGraphNote (List.map Note.extract notes)
      , List.filterMap (\link -> toGraphLink link notes) links)

getSelectedNotes: Slipbox -> (List DescriptionNote)
getSelectedNotes slipbox =
  case slipbox of 
    Slipbox notes links _ _ -> 
      notes
       |> List.filter Note.isSelected
       |> List.map (toDescriptionNote notes links)

getHistory: Slipbox -> (List Action.Summary)
getHistory slipbox =
  case slipbox of
    Slipbox _ _ actions _ -> List.map Action.summary actions

getLinkFormData: Slipbox -> LinkForm.LinkFormData
getLinkFormData slipbox =
  case slipbox of
    Slipbox notes links _ form -> 
      LinkForm.linkFormData (getFormNotes notes links) form

-- Helpers
initializeNotes: (List Note.NoteRecord) -> (List Link) -> (List Note.Note)
initializeNotes notes links =
  sortNotes (initSimulation (List.map Note.init notes) links)

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

initSimulation: (List Note.Note) -> (List Link) -> (List Note.Note)
initSimulation notes links =
  let
    simRecords = Simulation.simulate 
      (List.map toSimulationRecord (List.map Note.extract notes))
      (List.map toLinkTuple links)
  in
    List.map (noteUpdateWrapper simRecords) notes

toSearchResult: Note.Extract -> SearchResult
toSearchResult extract =
  SearchResult extract.id extract.intId extract.x extract.y extract.variant extract.content

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

actionsInit: ((List CreateNoteRecord), (List CreateLinkRecord)) -> (List Action.Action)
actionsInit (noteRecords, linkRecords) =
  List.sortWith Action.sortDesc 
    (List.map createNoteAction noteRecords ++ List.map createLinkAction linkRecords)
    |> List.map Action.save

createNoteAction: CreateNoteRecord -> Action.Action
createNoteAction note =
  Action.createNote note.id 
    (Action.CreateNoteRecord note.action.id note.action.content note.action.source note.action.noteType)

createLinkAction: CreateLinkRecord -> Action.Action
createLinkAction link =
  Action.createLink link.id 
    (Action.CreateLinkRecord link.action.id link.action.source link.action.target)
    
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
  case maybeNote of
    Just note -> Just (note, link)
    Nothing -> Nothing

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

addNoteToNotes: Note.NoteRecord -> (List Note.Note) -> (List Link) -> (List Note.Note)
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
    deleteNoteAction = toDeleteNoteAction (nextActionId newActions) extract
    actionsWithDeleteNote = deleteNoteAction :: newActions
    deleteLinkActions = List.indexedMap (\index link -> toDeleteLinkAction ((nextActionId actionsWithDeleteNote) + index) link) links
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
    Slipbox notes links actions form ->
      Slipbox (sortNotes (addNoteToNotes note notes links)) links actions form

createLinkInternal: Link -> Slipbox -> Slipbox
createLinkInternal link slipbox =
  case slipbox of
    Slipbox notes links actions _ -> 
      Slipbox 
        (initSimulation notes (link :: links))
        (link :: links)
        actions
        (LinkForm.removeSelections (getFormNotes notes links))

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