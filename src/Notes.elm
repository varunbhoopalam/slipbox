module Notes exposing (Notes, initializePosition, selectOnNote, 
  getSelectedNotes, hoverOnNote, clearHover, findNote, NoteId,
  NoteType, Selected, Hover, Content, Source, PositionNote,
  Note, noteColor, get, shouldAnimateNoteCircle,
  LinkRecord, initializeNotes, LinkId, unselectNote)

import Force exposing (entity, computeSimulation, manyBody, simulation, links, center)

--Types
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
  , selected : Selected
  , hover : Hover
  }

type Selected = 
  Selected |
  NotSelected

type Hover =
  Hover |
  NotHover

type alias Note = 
  { id : NoteId
  , content : Content
  , source : Source
  , noteType: String
  }

type alias NoteId = Int
type alias Content = String
type NoteType = Regular | Index
type alias Source = String

type alias LinkRecord =
  { source: NoteId
  , target: NoteId
  , id: LinkId
  }

type alias LinkId = Int

-- Invariants

-- Order is descending by id and does not change
-- Only one note can have hover at a time
-- ID is distinct
-- Note must also be selected to have hover
-- x and y are bounded by viewport bounds

-- Methods

initSimulation: (List PositionNote) -> (List LinkRecord) -> (List PositionNote)
initSimulation notes linkRecords =
  let
    state = 
      simulation 
        [ manyBody (List.map (\n -> n.id) notes)
        , links (List.map (\l -> (l.source, l.target)) linkRecords)
        , center 0 0
        ]
  in
    computeSimulation state notes

initializeNotes: (List Note) -> (List LinkRecord) -> Notes
initializeNotes notes links =
  Notes (initSimulation (List.indexedMap initializePosition notes) links)

get: Notes -> (List PositionNote)
get notes =
  case notes of
    Notes positionNotes -> positionNotes

initializePosition: Int -> Note -> PositionNote
initializePosition index note =
  let
    positions = entity index 1
  in
    PositionNote note.id note.content note.source (noteType note.noteType) positions.x positions.y positions.vx positions.vy NotSelected NotHover

noteType: String -> NoteType
noteType s =
  if s == "index" then
    Index
  else
    Regular

selectOnNote: NoteId -> Notes -> Notes
selectOnNote noteId notes =
  case notes of 
    Notes pns -> Notes (List.map (\note -> selectNoteById noteId note) pns)

unselectNote: NoteId -> Notes -> Notes
unselectNote noteId notes =
  case notes of 
    Notes pns -> Notes (List.map (\note -> unselectNoteById noteId note) pns)

getSelectedNotes: Notes -> (List PositionNote)
getSelectedNotes notes =
  case notes of 
    Notes positionNotes -> List.filter (\note -> note.selected == Selected ) positionNotes

hoverOnNote: PositionNote -> Notes -> Notes
hoverOnNote pn notes =
  case notes of 
    Notes pns ->
      Notes (List.map (\note -> hoverNoteById pn.id note) pns)

clearHover: Notes -> Notes
clearHover notes =
  case notes of 
    Notes pns ->
      Notes (List.map (\note -> {note | hover = NotHover}) pns)

selectNoteById: NoteId -> PositionNote -> PositionNote
selectNoteById noteId note =
  if  note.id == noteId then
    {note | selected = Selected}
  else
    note

unselectNoteById: NoteId -> PositionNote -> PositionNote
unselectNoteById noteId note =
  if  note.id == noteId then
    {note | selected = NotSelected}
  else
    note

hoverNoteById: NoteId -> PositionNote -> PositionNote
hoverNoteById noteId note =
  if  note.id == noteId then
    {note | hover = Hover}
  else
    {note | hover = NotHover}

findNote: NoteId -> Notes -> Maybe PositionNote
findNote id n =
  case n of
    Notes noteList ->
      List.head (List.filter (\note -> note.id == id) noteList)

noteColor: NoteType -> String
noteColor notetype =
  case notetype of
    Regular -> "rgba(137, 196, 244, 1)"
    Index -> "rgba(250, 190, 88, 1)"

shouldAnimateNoteCircle: PositionNote -> Bool
shouldAnimateNoteCircle pn =
  case pn.hover of
     Hover -> True
     NotHover -> False