module Slipbox exposing (Slipbox, NoteRecord, LinkRecord, initialize, 
  selectNote, dismissNote, stopHoverNote, searchSlipbox, SearchResult,
  getGraphElements, GraphNote, GraphLink, getSelectedNotes, DescriptionNote
  , DescriptionLink, NoteId, hoverNote, CreateNoteRecord, CreateLinkRecord
  , HistoryAction, getHistory, createNote, MakeNoteRecord, MakeLinkRecord
  , createLink, LinkFormData, LinkNoteChoice, sourceSelected, targetSelected)

import Force
import Set

--Types
type Slipbox = Slipbox (List Note) (List Link) (List Action) LinkForm

type alias Note =
  { id : NoteId
  , content : String
  , source : String
  , noteType: NoteType
  , x : Float
  , y : Float
  , vx : Float
  , vy : Float
  , selected : Selected
  , hover : Hover
  }

type alias Link = 
  { source: NoteId
  , target: NoteId
  , id: LinkId
  }

type Action =
  CreateNote HistoryId Undone HistoryNote |
  CreateLink HistoryId Undone HistoryLink

type alias HistoryId = Int

type alias Undone = Bool

type alias HistoryNote =
  { id : NoteId
  , content : String
  , source : String
  , noteType: String
  }

type alias HistoryLink =
  { source: NoteId
  , target: NoteId
  , id: LinkId
  }

type alias HistoryAction =
  { id : HistoryId
  , undone : Bool
  , summary : String
  }

type Selected = 
  Selected |
  NotSelected

type Hover =
  Hover |
  NotHover

type alias NoteId = Int
type NoteType = Regular | Index
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

type alias NoteRecord = 
  { id : Int
  , content : String
  , source : String
  , noteType: String
  }

type alias MakeNoteRecord =
  { content : String
  , source : String
  , noteType : String
  }

type alias CreateNoteRecord =
  { id : Int
  , action : NoteRecord
  }

type alias CreateLinkRecord =
  { id : Int
  , action : LinkRecord
  }

type alias SearchResult = 
  { id : NoteId
  , x : Float
  , y : Float
  , color : String
  , content : String
  }

type alias GraphNote =
  { id: NoteId
  , x : Float
  , y : Float
  , color : String 
  , shouldAnimate : Bool
  }

type alias GraphLink = 
  { sourceId: NoteId
  , sourceX: Float
  , sourceY: Float
  , targetId: NoteId
  , targetX: Float
  , targetY: Float
  , id: LinkId
  }

type alias DescriptionNote =
  { id : NoteId
  , x : Float
  , y : Float 
  , content : String
  , source : String 
  , links : (List DescriptionLink)
  }

type alias DescriptionLink =
  { target : NoteId
  , targetX : Float
  , targetY : Float
  }

type alias LinkFormData =
  { shown: Bool
  , sourceChoices: (List LinkNoteChoice)
  , targetChoices: (List LinkNoteChoice)
  , canSubmit: Bool
  }

type alias LinkNoteChoice =
  { value: NoteId
  , display: String
  }

type LinkForm =
  Hidden |
  NoSelections |
  SourceSelected NoteId |
  TargetSelected NoteId |
  ReadyToSubmit Selections

type alias Selections =
  { source: NoteId
  , target: NoteId
  }

type alias FormNote =
  { id: NoteId
  , linkedNotes: (List NoteId)
  }

-- Invariants
summaryLengthMin: Int
summaryLengthMin = 20

-- Methods

-- Returns Slipbox
initialize: (List NoteRecord) -> (List LinkRecord) -> ((List CreateNoteRecord), (List CreateLinkRecord)) -> Slipbox
initialize notes links (noteRecords, linkRecords) =
  let
    l =  initializeLinks links
  in
    Slipbox (initializeNotes notes l) l (initializeHistory (noteRecords, linkRecords)) Hidden

selectNote: NoteId -> Slipbox -> Slipbox
selectNote noteId slipbox =
  case slipbox of 
    Slipbox notes links actions form -> handleSelectNote noteId notes links actions form

handleSelectNote: NoteId -> (List Note) -> (List Link) -> (List Action) -> LinkForm -> Slipbox
handleSelectNote noteId notes links actions form =
  let
    newNotes = List.map (\note -> selectNoteById noteId note) notes
  in
    Slipbox newNotes links actions (selectionsChange form newNotes links)

dismissNote: NoteId -> Slipbox -> Slipbox
dismissNote noteId slipbox =
  case slipbox of 
    Slipbox notes links actions form -> handleDismissNote noteId notes links actions form

handleDismissNote: NoteId -> (List Note) -> (List Link) -> (List Action) -> LinkForm -> Slipbox
handleDismissNote noteId notes links actions form =
  let
    newNotes = List.map (\note -> unselectNoteById noteId note) notes
  in 
    Slipbox newNotes links actions (selectionsChange form newNotes links)

hoverNote: NoteId -> Slipbox -> Slipbox
hoverNote noteId slipbox =
  case slipbox of 
    Slipbox notes links history form-> Slipbox (List.map (\note -> hoverNoteById noteId note) notes) links history form

stopHoverNote: Slipbox -> Slipbox
stopHoverNote slipbox =
  case slipbox of 
    Slipbox notes links history form -> Slipbox (List.map (\note -> {note | hover = NotHover}) notes) links history form

createNote: MakeNoteRecord -> Slipbox -> Slipbox
createNote note slipbox =
  case slipbox of
     Slipbox notes links actions form -> handleCreateNote note notes links actions form

handleCreateNote: MakeNoteRecord -> (List Note) -> (List Link) -> (List Action) -> LinkForm -> Slipbox
handleCreateNote makeNoteRecord notes links actions form =
  let
    newNote = toNoteRecord makeNoteRecord notes
    newNoteList = addNoteToNotes newNote notes links
  in
    Slipbox (List.sortWith noteSorterDesc newNoteList) links (addNoteToActions newNote actions) form

createLink: Slipbox -> Slipbox
createLink slipbox =
  case slipbox of 
    Slipbox notes links actions form -> createLinkHandler (maybeLinkRecordFromForm form) notes links actions form
  
createLinkHandler: (Maybe MakeLinkRecord) -> (List Note) -> (List Link) -> (List Action) -> LinkForm -> Slipbox
createLinkHandler maybeMakeLinkRecord notes links actions form =
  case maybeMakeLinkRecord of
    Just makeLinkRecord -> createLinkHandlerFork makeLinkRecord notes links actions form
    Nothing -> removeSelectionsFork notes links actions form

createLinkHandlerFork: MakeLinkRecord -> (List Note) -> (List Link) -> (List Action) -> LinkForm -> Slipbox
createLinkHandlerFork makeLinkRecord notes links actions form =
  case toMaybeLink makeLinkRecord links notes of
    Just link -> addLinkToSlipbox link notes links actions form
    Nothing -> removeSelectionsFork notes links actions form

removeSelectionsFork: (List Note) -> (List Link) -> (List Action) -> LinkForm -> Slipbox
removeSelectionsFork notes links actions form =
  Slipbox notes links actions (removeSelections form notes links)

addLinkToSlipbox: Link -> (List Note) -> (List Link) -> (List Action) -> LinkForm -> Slipbox
addLinkToSlipbox link notes links actions form =
  let
    newLinks =  addLinkToLinks link links
  in
    Slipbox 
      (sortNotes (initSimulation notes newLinks))
      newLinks
      (addLinkToActions link actions)
      (removeSelections form notes links)

sourceSelected: String -> Slipbox -> Slipbox
sourceSelected source slipbox =
  case slipbox of
    Slipbox notes links actions form -> Slipbox notes links actions (addSource source form)

targetSelected: String -> Slipbox -> Slipbox
targetSelected target slipbox =
  case slipbox of
    Slipbox notes links actions form -> Slipbox notes links actions (addTarget target form)

-- Publicly Exposed for View
searchSlipbox: String -> Slipbox -> (List SearchResult)
searchSlipbox searchString slipbox =
  case slipbox of
     Slipbox notes _ _ _-> 
      notes
        |> List.filter (\note -> String.contains searchString note.content)
        |> List.map toSearchResult
  
getGraphElements: Slipbox -> ((List GraphNote), (List GraphLink))
getGraphElements slipbox =
  case slipbox of
    Slipbox notes links _ _ -> 
      ( List.map toGraphNote notes
      , List.filterMap (\link -> toGraphLink link notes) links)

getSelectedNotes: Slipbox -> (List DescriptionNote)
getSelectedNotes slipbox =
  case slipbox of 
    Slipbox notes links _ _ -> 
      notes
       |> List.filter (\note -> note.selected == Selected )
       |> List.map (\note -> toDescriptionNote notes note links)

getHistory: Slipbox -> (List HistoryAction)
getHistory slipbox =
  case slipbox of
    Slipbox _ _ history _ -> List.map toHistoryAction history

-- Helpers
initializeNotes: (List NoteRecord) -> (List Link) -> (List Note)
initializeNotes notes links =
  sortNotes (initSimulation (List.indexedMap initializePosition notes) links)

type UnsortedNotes = UnsortedNotes (List Note)

initSimulation: (List Note) -> (List Link) -> UnsortedNotes
initSimulation notes links =
  let
    state = 
      Force.simulation 
        [ Force.manyBodyStrength -10 (List.map (\n -> n.id) notes)
        , Force.links (List.map (\l -> (l.source, l.target)) links)
        , Force.center 0 0
        ]
  in
    UnsortedNotes (Force.computeSimulation state notes)

sortNotes: UnsortedNotes -> (List Note)
sortNotes unsortedNotes =
  case unsortedNotes of
    UnsortedNotes notes -> (List.sortWith noteSorterDesc notes)

noteSorterDesc: (Note -> Note -> Order)
noteSorterDesc noteA noteB =
  case compare noteA.id noteB.id of
       LT -> GT
       EQ -> EQ
       GT -> LT

initializePosition: Int -> NoteRecord -> Note
initializePosition index note =
  let
    positions = Force.entity index 1
  in
    Note note.id note.content note.source (noteType note.noteType) positions.x positions.y positions.vx positions.vy NotSelected NotHover

createNewNote: Int -> NoteRecord -> Note
createNewNote index note =
  let
    positions = Force.entity index 1
  in
    Note note.id note.content note.source (noteType note.noteType) positions.x positions.y positions.vx positions.vy Selected NotHover

noteType: String -> NoteType
noteType s =
  if s == "index" then
    Index
  else
    Regular

selectNoteById: NoteId -> Note -> Note
selectNoteById noteId note =
  if  note.id == noteId then
    {note | selected = Selected}
  else
    note

unselectNoteById: NoteId -> Note -> Note
unselectNoteById noteId note =
  if  note.id == noteId then
    {note | selected = NotSelected}
  else
    note

hoverNoteById: NoteId -> Note -> Note
hoverNoteById noteId note =
  if  note.id == noteId then
    {note | hover = Hover}
  else
    {note | hover = NotHover}

noteColor: NoteType -> String
noteColor notetype =
  case notetype of
    Regular -> "rgba(137, 196, 244, 1)"
    Index -> "rgba(250, 190, 88, 1)"

shouldAnimateNoteCircle: Hover -> Bool
shouldAnimateNoteCircle hover =
  case hover of
     Hover -> True
     NotHover -> False

toSearchResult: Note -> SearchResult
toSearchResult pn =
  SearchResult pn.id pn.x pn.y (noteColor pn.noteType) pn.content

toGraphNote: Note -> GraphNote
toGraphNote pn =
  GraphNote pn.id pn.x pn.y (noteColor pn.noteType) (shouldAnimateNoteCircle pn.hover)

initializeLinks: (List LinkRecord) -> (List Link)
initializeLinks linkRecords =
  List.sortWith linkSorterDesc (List.map (\lr -> Link lr.source lr.target lr.id) linkRecords)

linkSorterDesc: (Link -> Link -> Order)
linkSorterDesc linkA linkB =
  case compare linkA.id linkB.id of
    LT -> GT
    EQ -> EQ
    GT -> LT

toGraphLink: Link -> (List Note) -> (Maybe GraphLink)
toGraphLink link notes =
  let
      source = findNote link.source notes
      target = findNote link.target notes
  in
    Maybe.map3 graphLinkBuilder source target (Just link.id)

initializeHistory: ((List CreateNoteRecord), (List CreateLinkRecord)) -> (List Action)
initializeHistory (noteRecords, linkRecords) =
  List.sortWith actionSorterDesc (List.map createNoteAction noteRecords ++ List.map createLinkAction linkRecords)

createNoteAction: CreateNoteRecord -> Action
createNoteAction note =
  CreateNote note.id False (HistoryNote note.action.id note.action.content note.action.source note.action.noteType)

createLinkAction: CreateLinkRecord -> Action
createLinkAction link =
  CreateLink link.id False (Link link.action.source link.action.target link.action.id)

actionSorterDesc: (Action -> Action -> Order)
actionSorterDesc actionA actionB =
  let
      idA = getHistoryId actionA
      idB = getHistoryId actionB
  in
    case compare idA idB of
       LT -> GT
       EQ -> EQ
       GT -> LT

getHistoryId: Action -> HistoryId
getHistoryId action =
  case action of 
    CreateNote id _ _ -> id
    CreateLink id _ _ -> id
    
graphLinkBuilder: Note -> Note -> LinkId -> GraphLink
graphLinkBuilder source target id =
  GraphLink source.id source.x source.y target.id target.x target.y id

toDescriptionNote: (List Note) -> Note -> (List Link) -> DescriptionNote
toDescriptionNote notes note links =
  DescriptionNote note.id note.x note.y note.content note.source (getDescriptionLinks notes note.id links)

getDescriptionLinks: (List Note) -> NoteId -> (List Link) -> (List DescriptionLink)
getDescriptionLinks notes noteId links =
  List.map toDescriptionLink (uniqueLinkParts (getLinkParts notes noteId links))

toDescriptionLink: (Int, Float, Float) -> DescriptionLink
toDescriptionLink (noteId, x, y) =
  DescriptionLink noteId x y

getLinkParts: (List Note) -> NoteId -> (List Link) -> (List (Int, Float, Float))
getLinkParts notes noteId links =
  List.filterMap (\link -> maybeGetDescriptionLinkParts notes noteId link) links

uniqueLinkParts: (List (Int, Float, Float)) -> (List (Int, Float, Float))
uniqueLinkParts linkParts = Set.toList (Set.fromList linkParts)

maybeGetDescriptionLinkParts: (List Note) -> NoteId -> Link -> (Maybe (Int, Float, Float))
maybeGetDescriptionLinkParts notes noteId link =
  if link.source == noteId then 
    Maybe.map toLinkParts (findNote link.target notes)
  else if link.target == noteId then 
    Maybe.map toLinkParts (findNote link.source notes)
  else 
    Nothing

toLinkParts: Note -> (Int, Float, Float)
toLinkParts note = (note.id, note.x, note.y)

findNote: NoteId -> (List Note) -> (Maybe Note)
findNote noteId notes =
  List.head (List.filter (\note -> note.id == noteId) notes)

toHistoryAction: Action -> HistoryAction
toHistoryAction action = 
  case action of
    CreateNote id undone historyNote -> HistoryAction id undone (createNoteSummary historyNote)
    CreateLink id undone historyLink -> HistoryAction id undone (createLinkSummary historyLink)

createNoteSummary: HistoryNote -> String
createNoteSummary note =
  "Create Note:" ++  String.fromInt note.id ++
  " with Content: " ++  String.slice 0 summaryLengthMin note.content ++ "..."

createLinkSummary: HistoryLink -> String
createLinkSummary link =
  "Create Link:" ++  String.fromInt link.id ++ 
  " from Source:" ++  String.fromInt link.source ++ 
  " to Target:" ++  String.fromInt link.target

toNoteRecord: MakeNoteRecord -> (List Note) -> NoteRecord
toNoteRecord note notes =
  NoteRecord (getNextNoteId notes) note.content note.source note.noteType

getNextNoteId: (List Note) -> Int
getNextNoteId notes = 
  case List.head notes of
    Just note -> note.id + 1
    Nothing -> 1

addNoteToNotes: NoteRecord -> (List Note) -> (List Link) -> (List Note)
addNoteToNotes note notes links =
  sortNotes (initSimulation ( createNewNote note.id note :: notes) links)

addNoteToActions : NoteRecord -> (List Action) -> (List Action)
addNoteToActions note actions =
  CreateNote (getNextHistoryId actions) False (toHistoryNote note) :: actions

getNextHistoryId : (List Action) -> Int
getNextHistoryId actions =
  case List.head actions of
    Just action -> 
      case action of 
        CreateNote historyId _ _ -> historyId + 1
        CreateLink historyId _ _ -> historyId + 1
    Nothing -> 1

toHistoryNote: NoteRecord -> HistoryNote
toHistoryNote note =
  HistoryNote note.id note.content note.source note.noteType

addLinkToLinks: Link -> (List Link) -> (List Link)
addLinkToLinks link links =
  link :: links

addLinkToActions: Link -> (List Action) -> (List Action)
addLinkToActions link actions =
  CreateLink (getNextHistoryId actions) False (toHistoryLink link) :: actions

toHistoryLink: Link -> HistoryLink
toHistoryLink link =
  HistoryLink link.source link.target link.id

toMaybeLink: MakeLinkRecord -> (List Link) -> (List Note) -> (Maybe Link)
toMaybeLink makeLinkRecord links notes =
  let
      source = makeLinkRecord.source
      target = makeLinkRecord.target
  in
  
  if linkRecordIsValid source target notes then
    Just (Link source target (nextLinkId links))
  else 
    Nothing

linkRecordIsValid: Int -> Int -> (List Note) -> Bool
linkRecordIsValid source target notes =
  noteExists source notes && noteExists target notes

noteExists: Int -> (List Note) -> Bool
noteExists noteId notes =
  List.member noteId (List.map (\note -> note.id) notes)

nextLinkId: (List Link) -> Int
nextLinkId links =
  let
    mLink = List.head links
  in
    case mLink of
      Just link -> link.id + 1
      Nothing -> 1

selectionsChange: LinkForm -> (List Note) -> (List Link) -> LinkForm
selectionsChange form notes links =
  let
    formNotes = getFormNotes notes links
  in
  case form of
     Hidden -> noneSelectedHandler formNotes
     NoSelections -> noneSelectedHandler formNotes
     SourceSelected noteId -> sourceSelectedHandler noteId formNotes
     TargetSelected noteId -> targetSelectedHandler noteId formNotes
     ReadyToSubmit selections -> readyToSubmitHandler selections formNotes

removeSelections: LinkForm -> (List Note) -> (List Link) -> LinkForm
removeSelections form notes links =
  let
    formNotes = getFormNotes notes links
  in
  case form of
     Hidden -> noneSelectedHandler formNotes
     NoSelections -> noneSelectedHandler formNotes
     SourceSelected _ -> noneSelectedHandler formNotes
     TargetSelected _ -> noneSelectedHandler formNotes
     ReadyToSubmit _ -> noneSelectedHandler formNotes

addSource: String -> LinkForm -> LinkForm
addSource source form =
  case String.toInt source of
    Just intSource -> addSourceHandler intSource form
    Nothing -> form

addSourceHandler: Int -> LinkForm -> LinkForm
addSourceHandler source form =
  case form of
    Hidden -> Hidden
    NoSelections -> SourceSelected source
    SourceSelected _ -> SourceSelected source
    TargetSelected target -> ReadyToSubmit (Selections source target)
    ReadyToSubmit prior -> ReadyToSubmit (Selections source prior.target)

addTarget: String -> LinkForm -> LinkForm
addTarget target form =
  case String.toInt target of
    Just intTarget -> addTargetHandler intTarget form
    Nothing -> form

addTargetHandler: Int -> LinkForm -> LinkForm
addTargetHandler target form =
  case form of
    Hidden -> Hidden
    NoSelections -> TargetSelected target
    SourceSelected source -> ReadyToSubmit (Selections source target)
    TargetSelected _ -> TargetSelected target
    ReadyToSubmit prior -> ReadyToSubmit (Selections prior.source target)

noneSelectedHandler: (List FormNote) -> LinkForm
noneSelectedHandler notes =
  if canCreateLink notes then
    NoSelections
  else
    Hidden

sourceSelectedHandler: NoteId -> (List FormNote) -> LinkForm
sourceSelectedHandler noteId notes =
  if canCreateLink notes && inFormNotes noteId notes then
    SourceSelected noteId
  else 
    noneSelectedHandler notes

targetSelectedHandler: NoteId -> (List FormNote) -> LinkForm
targetSelectedHandler noteId notes =
  if canCreateLink notes && inFormNotes noteId notes then
    TargetSelected noteId
  else
    noneSelectedHandler notes

readyToSubmitHandler: Selections -> (List FormNote) -> LinkForm
readyToSubmitHandler selections notes =
  let
    sourceId = selections.source
    targetId = selections.target
  in
    if canCreateLink notes && inFormNotes sourceId notes && inFormNotes targetId notes then
      ReadyToSubmit selections
    else if canCreateLink notes && inFormNotes sourceId notes then
      SourceSelected sourceId
    else if canCreateLink notes && inFormNotes targetId notes then
      TargetSelected targetId
    else 
      noneSelectedHandler notes

inFormNotes: NoteId -> (List FormNote) -> Bool
inFormNotes noteId notes =
  List.member noteId (List.map (\n -> n.id) notes)

getPossibleLinks: FormNote -> (List FormNote) -> (Set.Set NoteId)
getPossibleLinks note notes =
  let
    existingNoteConnections = Set.fromList note.linkedNotes
    selectedNotes = Set.fromList (List.map (\n -> n.id) notes)
  in
    Set.diff selectedNotes existingNoteConnections

canCreateLink: (List FormNote) -> Bool
canCreateLink notes =
  List.foldl (+) 0 (possibleLinksListCount notes) > 0

possibleLinksListCount: (List FormNote) -> (List Int)

possibleLinksListCount notes =
  List.map Set.size (possibleLinksList notes)

possibleLinksList: (List FormNote) -> (List (Set.Set NoteId))
possibleLinksList notes =
  List.map (\mappedNote -> getPossibleLinks mappedNote (removeFormNote mappedNote.id notes)) notes

removeFormNote: NoteId -> (List FormNote) -> (List FormNote)
removeFormNote noteId notes = List.filter (\note -> note.id /= noteId) notes

getFormNotes: (List Note) -> (List Link) -> (List FormNote)
getFormNotes notes links =
  notes
    |> List.filter (\note -> note.selected == Selected )
    |> List.map (\note -> toFormNote note links)

toFormNote: Note -> (List Link) -> FormNote
toFormNote note links =
  FormNote note.id (getNoteIds note.id links) 

getNoteIds: NoteId -> (List Link) -> (List Int)
getNoteIds noteId links =
  List.filterMap (\link -> maybeGetNoteId noteId link) links

maybeGetNoteId: NoteId -> Link -> (Maybe Int)
maybeGetNoteId noteId link =
  if link.source == noteId then 
    Just link.target
  else if link.target == noteId then 
    Just link.source
  else 
    Nothing

maybeLinkRecordFromForm: LinkForm -> (Maybe MakeLinkRecord)
maybeLinkRecordFromForm form =
  case form of
     Hidden -> Nothing
     NoSelections -> Nothing
     SourceSelected _ -> Nothing
     TargetSelected _ -> Nothing
     ReadyToSubmit selections -> Just (MakeLinkRecord selections.source selections.target)