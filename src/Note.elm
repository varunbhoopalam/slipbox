module Note exposing 
  ( Note
  , getId
  , getVariant
  , getContent
  , getSource
  , contains
  , isAssociated
  , is
  , updateContent
  , updateSource
  , updateVariant
  , Variant(..)
  , isNoteFromId
  , create
  , encode
  , decode
  )

import IdGenerator
import IdGenerator exposing (IdGenerator)
import Json.Decode
import Json.Encode
import Source
import SourceTitle

type Note = Note Info
getInfo : Note -> Info 
getInfo note =
  case note of Note content -> content
type alias Info =
  { id : NoteId
  , content : String
  , sourceTitle : SourceTitle.SourceTitle
  , variant : Variant
  }
type alias NoteId = Int
type Variant = Regular | Discussion
type alias NoteRecord =
  { content : String
  , source : String
  , variant: Variant
  }

getId : Note -> NoteId
getId note =
  .id <| getInfo note

getVariant : Note -> Variant
getVariant note =
  .variant <| getInfo note

getContent : Note -> String
getContent note =
  .content <| getInfo note

getSource : Note -> SourceTitle.SourceTitle
getSource note =
  .sourceTitle <| getInfo note

contains : String -> Note -> Bool
contains string note =
  let
      info = getInfo note
      has = \s -> String.contains (String.toLower string) <| String.toLower s
      containsSourceTitle =
        case SourceTitle.getTitle info.sourceTitle of
          Just sourceTitle -> has sourceTitle
          Nothing -> False
  in
  has info.content || containsSourceTitle

isAssociated : Source.Source -> Note -> Bool
isAssociated source note =
  case SourceTitle.getTitle <| getSource note of
    Just sourceTitle -> Source.getTitle source == sourceTitle
    Nothing -> False

is : Note -> Note -> Bool
is note1 note2 =
  (getId note1) == (getId note2)

isNoteFromId : Int -> Note -> Bool
isNoteFromId id note =
  getId note == id

create : IdGenerator.IdGenerator -> NoteRecord -> ( Note, IdGenerator.IdGenerator)
create generator record =
  let
      (id, idGenerator) = IdGenerator.generateId generator
  in
  ( note_ id record.content record.source (variantStringRepresentation record.variant ), idGenerator )

updateContent : String -> Note -> Note
updateContent content note =
  let
      info = getInfo note
  in
  Note { info | content = content }

updateSource : String -> Note -> Note
updateSource source note =
  let
      info = getInfo note
  in
  Note { info | sourceTitle = SourceTitle.sourceTitle source }

updateVariant : Variant -> Note -> Note
updateVariant variant note =
  let
      info = getInfo note
  in
  Note { info | variant = variant }

encode : Note -> Json.Encode.Value
encode note =
  let
    info = getInfo note
  in
  Json.Encode.object
    [ ( "id", Json.Encode.int info.id )
    , ( "content", Json.Encode.string info.content )
    , ( "source", Json.Encode.string <| SourceTitle.encode info.sourceTitle )
    , ( "variant", Json.Encode.string <| variantStringRepresentation info.variant )
    ]

decode : Json.Decode.Decoder Note
decode =
  Json.Decode.map4
    note_
    ( Json.Decode.field "id" Json.Decode.int )
    ( Json.Decode.field "content" Json.Decode.string )
    ( Json.Decode.field "source" Json.Decode.string )
    ( Json.Decode.field "variant" Json.Decode.string )

-- Helper
note_ : Int -> String -> String -> String -> Note
note_ id content source variant =
  Note <| Info
    id
    content
    ( SourceTitle.sourceTitle source )
    ( stringToVariant variant )

variantStringRepresentation : Variant -> String
variantStringRepresentation variant =
  case variant of
    Regular -> "regular"
    Discussion -> "index"

stringToVariant : String -> Variant
stringToVariant string =
  case string of
    "regular" -> Regular
    "index" -> Discussion
    _ -> Regular