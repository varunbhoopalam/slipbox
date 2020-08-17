module Note exposing (Note, NoteId, NoteRecord, Extract, SelectedExtract, Edits,
  init, isNote, select, unSelect, 
  hover, unHover, subsequentNoteId, 
  sortDesc, extract, isSelected,
  isIndex, search, update, isNoteInt,
  startEditState, discardEdits, submitEdits,
  contentUpdate, sourceUpdate, toNoteId)

import Simulation

type Note = 
  Note NoteContent |
  Selected NoteContent SelectedContent

type alias NoteContent =
  { id : NoteId
  , content : String
  , source : String
  , variant : Variant
  , x : Float
  , y : Float
  , vx : Float
  , vy : Float
  }

type alias SelectedContent =
  { hover: Bool
  , editState: EditState
  }

type alias EditContent =
  { content: String
  , source: String
  }

type Variant = Regular | Index

type EditState =
  InEdit EditContent |
  NotInEdit

type alias NoteRecord = 
  { id : Int
  , content : String
  , source : String
  , noteType: String
  }

type alias Extract =
  { id : NoteId
  , intId : Int
  , content : String
  , source : String
  , variant : String
  , x : Float
  , y : Float
  , vx : Float
  , vy : Float
  , selected: SelectedExtract
  }

type alias SelectedExtract =
  { selected: Bool
  , hover: Bool
  , inEdit: Bool
  , edits: (Maybe Edits)
  }

type alias Edits =
  { content: String
  , source: String
  }

-- Exposed Functions
sortDesc: (Note -> Note -> Order)
sortDesc noteA noteB =
  case compare (getNoteIdComparable noteA) (getNoteIdComparable noteB) of
       LT -> GT
       EQ -> EQ
       GT -> LT

init: NoteRecord -> Note
init record =
  toNote (Simulation.init record.id) record

isNote: NoteId -> Note -> Bool
isNote noteId note =
  case note of
    Note content -> equals noteId content.id
    Selected content _ -> equals noteId content.id

isNoteInt: Int -> Note -> Bool
isNoteInt noteId note =
  case note of
    Note content -> noteId == extractNoteId content.id
    Selected content _ -> noteId == extractNoteId content.id

isSelected: Note -> Bool
isSelected note =
  case note of
    Note _ -> False
    Selected _ _ -> True

select: Note -> Note
select note =
  case note of
    Note content -> Selected content defaultSelectedContent
    Selected _ _ -> note

unSelect: Note -> Note
unSelect note =
  case note of
    Note _ -> note
    Selected content _ -> Note content

hover: Note -> Note
hover note =
  case note of 
    Note _ -> note
    Selected content selectedContent -> Selected content (SelectedContent True selectedContent.editState)

unHover: Note -> Note
unHover note =
  case note of 
    Note _ -> note
    Selected content selectedContent -> Selected content (SelectedContent False selectedContent.editState)

subsequentNoteId: Note -> Int
subsequentNoteId note = 
  case note of
    Note content -> extractNoteId content.id + 1
    Selected content _ -> extractNoteId content.id + 1

extract: Note -> Extract
extract note =
  case note of
    Note content -> buildExtract content
    Selected content sContent -> buildSelectedExtract content sContent

isIndex: Note -> Bool
isIndex note =
  case note of
     Note content -> content.variant == Index
     Selected content _ -> content.variant == Index

search: String -> Note -> Bool
search query note =
  case note of
    Note content -> String.contains query content.source || String.contains query content.content
    Selected content _ -> String.contains query content.source || String.contains query content.content

update: Simulation.SimulationRecord -> Note -> Note
update simRecord note =
  case note of
    Note content -> Note {content | x = simRecord.x , y = simRecord.y, vx = simRecord.vx, vy = simRecord.vy}
    Selected content sContent -> Selected {content | x = simRecord.x , y = simRecord.y, vx = simRecord.vx, vy = simRecord.vy} sContent

startEditState: Note -> Note
startEditState note =
  case note of
    Note _ -> note
    Selected content sContent -> 
      case sContent.editState of
        InEdit _ -> note
        NotInEdit -> 
          Selected 
            content 
            { sContent | editState = 
              InEdit (EditContent content.content content.source)
            }

discardEdits: Note -> Note
discardEdits note =
  case note of
    Note _ -> note
    Selected content sContent -> 
      case sContent.editState of
        InEdit _ ->           
          Selected content { sContent | editState = NotInEdit }
        NotInEdit -> note

submitEdits: Note -> Note
submitEdits note =
  case note of
    Note _ -> note
    Selected content sContent -> 
      case sContent.editState of
        InEdit eContent ->           
          Selected 
            { content | content = eContent.content, source = eContent.source } 
            { sContent | editState = NotInEdit }
        NotInEdit -> note

sourceUpdate: String -> Note -> Note
sourceUpdate source note =
  case note of
    Note _ -> note
    Selected content sContent -> 
      case sContent.editState of
        InEdit eContent-> 
          Selected content {sContent | editState = InEdit {eContent | source = source}}
        NotInEdit -> note

contentUpdate: String -> Note -> Note
contentUpdate newContent note =
  case note of
    Note _ -> note
    Selected content sContent -> 
      case sContent.editState of
        InEdit eContent-> 
          Selected content {sContent | editState = InEdit {eContent | content = newContent}}
        NotInEdit -> note

-- Helper

getNoteIdComparable: Note -> Int
getNoteIdComparable note = 
  extractNoteId (getNoteId note)

getNoteId: Note -> NoteId
getNoteId note =
  case note of 
    Note content -> content.id
    Selected content _ -> content.id

toNote: Simulation.SimulationRecord -> NoteRecord -> Note
toNote simRecord record =
  Note 
    (NoteContent (toNoteId record.id) record.content record.source (toVariant record.noteType) simRecord.x simRecord.y simRecord.vx simRecord.vy)

toVariant: String -> Variant
toVariant s =
  if s == "index" then
    Index
  else
    Regular

variantToString: Variant -> String
variantToString variant =
  case variant of
     Index -> "index"
     Regular -> "regular"

defaultSelectedContent: SelectedContent
defaultSelectedContent = SelectedContent False NotInEdit

buildExtract: NoteContent -> Extract
buildExtract content =
  Extract 
    content.id 
    (extractNoteId content.id) 
    content.content 
    content.source 
    (variantToString content.variant)
    content.x
    content.y
    content.vx
    content.vy
    extractNotSelectedBuilder

extractNotSelectedBuilder: SelectedExtract 
extractNotSelectedBuilder = SelectedExtract False False False Nothing

buildSelectedExtract: NoteContent -> SelectedContent -> Extract
buildSelectedExtract content sContent =
  case sContent.editState of
    InEdit eContent ->
      Extract 
        content.id 
        (extractNoteId content.id) 
        content.content 
        content.source 
        (variantToString content.variant)
        content.x
        content.y
        content.vx
        content.vy
        (SelectedExtract True sContent.hover True (Just (Edits eContent.content eContent.source)))
    NotInEdit ->
      Extract 
        content.id 
        (extractNoteId content.id) 
        content.content 
        content.source 
        (variantToString content.variant)
        content.x
        content.y
        content.vx
        content.vy
        (SelectedExtract True sContent.hover False Nothing)

-- NoteId
type NoteId = NoteId Int

extractNoteId: NoteId -> Int
extractNoteId noteId =
  case noteId of
    NoteId id -> id

toNoteId: Int -> NoteId
toNoteId i = NoteId i

equals: NoteId -> NoteId -> Bool
equals noteIdA noteIdB =
  extractNoteId noteIdA == extractNoteId noteIdB