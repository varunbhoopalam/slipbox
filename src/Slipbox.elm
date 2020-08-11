module Slipbox exposing (Slipbox, NoteRecord, LinkRecord, initialize, 
  selectNote, dismissNote, stopHoverNote, searchSlipbox, SearchResult,
  getGraphElements, GraphNote, GraphLink, getSelectedNotes, DescriptionNote
  , DescriptionLink, NoteId, hoverNote, CreateNoteRecord, CreateLinkRecord
  , HistoryAction, getHistory, createNote, MakeNoteRecord, MakeLinkRecord
  , createLink)

import Force
import Set

--Types
type Slipbox = Slipbox (List Note) (List Link) (List Action)

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

-- Invariants
summaryLengthMin: Int
summaryLengthMin = 20


-- UNSORTED-NOTES: Notes must be sorted. Simulation must always return UnsortedNotes type
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

-- Methods

initialize: (List NoteRecord) -> (List LinkRecord) -> ((List CreateNoteRecord), (List CreateLinkRecord)) -> Slipbox
initialize notes links (noteRecords, linkRecords) =
  let
    l =  initializeLinks links
  in
    Slipbox (initializeNotes notes l) l (initializeHistory (noteRecords, linkRecords))

initializeLinks: (List LinkRecord) -> (List Link)
initializeLinks linkRecords =
  List.sortWith linkSorterDesc (List.map (\lr -> Link lr.source lr.target lr.id) linkRecords)

initializeNotes: (List NoteRecord) -> (List Link) -> (List Note)
initializeNotes notes links =
  sortNotes (initSimulation (List.indexedMap initializePosition notes) links)

initializePosition: Int -> NoteRecord -> Note
initializePosition index note =
  let
    positions = Force.entity index 1
  in
    Note note.id note.content note.source (noteType note.noteType) positions.x positions.y positions.vx positions.vy NotSelected NotHover

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

linkSorterDesc: (Link -> Link -> Order)
linkSorterDesc linkA linkB =
  case compare linkA.id linkB.id of
    LT -> GT
    EQ -> EQ
    GT -> LT

getHistoryId: Action -> HistoryId
getHistoryId action =
  case action of 
    CreateNote id _ _ -> id
    CreateLink id _ _ -> id

noteType: String -> NoteType
noteType s =
  if s == "index" then
    Index
  else
    Regular

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

selectNote: NoteId -> Slipbox -> Slipbox
selectNote noteId slipbox =
  case slipbox of 
    Slipbox notes links history -> Slipbox (List.map (\note -> selectNoteById noteId note) notes) links history

selectNoteById: NoteId -> Note -> Note
selectNoteById noteId note =
  if  note.id == noteId then
    {note | selected = Selected}
  else
    note

dismissNote: NoteId -> Slipbox -> Slipbox
dismissNote noteId slipbox =
  case slipbox of 
    Slipbox notes links history -> Slipbox (List.map (\note -> unselectNoteById noteId note) notes) links history

unselectNoteById: NoteId -> Note -> Note
unselectNoteById noteId note =
  if  note.id == noteId then
    {note | selected = NotSelected}
  else
    note

hoverNote: NoteId -> Slipbox -> Slipbox
hoverNote noteId slipbox =
  case slipbox of 
    Slipbox notes links history -> Slipbox (List.map (\note -> hoverNoteById noteId note) notes) links history

hoverNoteById: NoteId -> Note -> Note
hoverNoteById noteId note =
  if  note.id == noteId then
    {note | hover = Hover}
  else
    {note | hover = NotHover}

stopHoverNote: Slipbox -> Slipbox
stopHoverNote slipbox =
  case slipbox of 
    Slipbox notes links history -> Slipbox (List.map (\note -> {note | hover = NotHover}) notes) links history

searchSlipbox: String -> Slipbox -> (List SearchResult)
searchSlipbox searchString slipbox =
  case slipbox of
     Slipbox notes _ _-> 
      notes
        |> List.filter (\note -> String.contains searchString note.content)
        |> List.map toSearchResult

toSearchResult: Note -> SearchResult
toSearchResult pn =
  SearchResult pn.id pn.x pn.y (noteColor pn.noteType) pn.content

getGraphElements: Slipbox -> ((List GraphNote), (List GraphLink))
getGraphElements slipbox =
  case slipbox of
    Slipbox notes links _ -> 
      ( List.map toGraphNote notes
      , List.filterMap (\link -> toGraphLink link notes) links)

toGraphNote: Note -> GraphNote
toGraphNote pn =
  GraphNote pn.id pn.x pn.y (noteColor pn.noteType) (shouldAnimateNoteCircle pn.hover)

toGraphLink: Link -> (List Note) -> (Maybe GraphLink)
toGraphLink link notes =
  let
      source = findNote link.source notes
      target = findNote link.target notes
  in
    Maybe.map3 graphLinkBuilder source target (Just link.id)
    
graphLinkBuilder: Note -> Note -> LinkId -> GraphLink
graphLinkBuilder source target id =
  GraphLink source.id source.x source.y target.id target.x target.y id

getSelectedNotes: Slipbox -> (List DescriptionNote)
getSelectedNotes slipbox =
  case slipbox of 
    Slipbox notes links _ -> 
      notes
       |> List.filter (\note -> note.selected == Selected )
       |> List.map (\note -> toDescriptionNote notes note links)

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

getHistory: Slipbox -> (List HistoryAction)
getHistory slipbox =
  case slipbox of
    Slipbox _ _ history -> List.map toHistoryAction history

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

createNote: MakeNoteRecord -> Slipbox -> Slipbox
createNote note slipbox =
  case slipbox of
     Slipbox notes links actions -> handleCreateNote note notes links actions

handleCreateNote: MakeNoteRecord -> (List Note) -> (List Link) -> (List Action) -> Slipbox
handleCreateNote makeNoteRecord notes links actions =
  let
    newNote = toNoteRecord makeNoteRecord notes
    newNoteList = addNoteToNotes newNote notes links
  in
    Slipbox (List.sortWith noteSorterDesc newNoteList) links (addNoteToActions newNote actions)

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
  sortNotes (initSimulation ( initializePosition note.id note :: notes) links)

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

createLink: MakeLinkRecord -> Slipbox -> Slipbox
createLink link slipbox =
  case slipbox of 
    Slipbox notes links actions -> createLinkHandler link notes links actions
  
createLinkHandler: MakeLinkRecord -> (List Note) -> (List Link) -> (List Action) -> Slipbox
createLinkHandler makeLinkRecord notes links actions =
  let
    maybeLink = toMaybeLink makeLinkRecord links notes
  in 
    case maybeLink of
      Just link -> addLinkToSlipbox link notes links actions
      Nothing -> Slipbox notes links actions

addLinkToSlipbox: Link -> (List Note) -> (List Link) -> (List Action) -> Slipbox
addLinkToSlipbox link notes links actions =
  let
    newLinks =  addLinkToLinks link links
  in
    Slipbox 
      (sortNotes (initSimulation notes newLinks))
      newLinks
      (addLinkToActions link actions)

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