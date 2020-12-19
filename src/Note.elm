module Note exposing 
  ( Note
  , getId
  , getX
  , getY
  , getVx
  , getVy
  , getVariant
  , getGraphState
  , getContent
  , getTransform
  , getSource
  , contains
  , isAssociated
  , is
  , compress
  , expand
  , updateContent
  , updateSource
  , updateVariant
  , updateX
  , updateY
  , updateVx
  , updateVy
  , GraphState(..)
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
import Force

type Note = Note Info
getInfo : Note -> Info 
getInfo note =
  case note of Note content -> content
type alias Info =
  { id : NoteId
  , content : String
  , source : String
  , variant : Variant
  , graphState : GraphState
  , x : Float
  , y : Float
  , vx : Float
  , vy : Float
  }
type alias NoteId = Int
type Variant = Regular | Index
type GraphState = Compressed Int | Expanded Int Int
type alias NoteRecord = 
  { content : String
  , source : String
  , variant: Variant
  }

getId : Note -> NoteId
getId note =
  .id <| getInfo note

getX : Note -> Float
getX note =
  .x <| getInfo note
getY : Note -> Float
getY note =
  .y <| getInfo note

getVx : Note -> Float
getVx note =
  .vx <| getInfo note

getVy : Note -> Float
getVy note =
  .vy <| getInfo note

getVariant : Note -> Variant
getVariant note =
  .variant <| getInfo note

getGraphState : Note -> GraphState
getGraphState note =
  .graphState <| getInfo note

getContent : Note -> String
getContent note =
  .content <| getInfo note

getTransform : Note -> String
getTransform note =
  let
      info = getInfo note
      x = String.fromFloat info.x
      y = String.fromFloat info.y
  in
  String.concat [ "translate(", x, " ", y, ")" ]

getSource : Note -> String
getSource note =
  .source <| getInfo note

contains : String -> Note -> Bool
contains string note =
  let
      info = getInfo note
      has = \s -> String.contains (String.toLower string) <| String.toLower s
  in
  has info.content || has info.source

isAssociated : Source.Source -> Note -> Bool
isAssociated source note =
  Source.getTitle source == getSource note

is : Note -> Note -> Bool
is note1 note2 =
  (getId note1) == (getId note2)

isNoteFromId : Int -> Note -> Bool
isNoteFromId id note =
  getId note == id

compress : Note -> Note
compress note =
  let
      info = getInfo note
  in
  Note { info | graphState = Compressed 5 }

expand : Note -> Note
expand note =
  let
      info = getInfo note
  in
  Note { info | graphState = Expanded 100 100 }

create : IdGenerator.IdGenerator -> NoteRecord -> ( Note, IdGenerator.IdGenerator)
create generator record =
  let
      (id, idGenerator) = IdGenerator.generateId generator
  in
  
  ( Note <| Info
    id
    record.content
    record.source
    record.variant
    ( Compressed 5 )
    0 0 0 0
  , idGenerator
  )

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
  Note { info | source = source }

updateVariant : Variant -> Note -> Note
updateVariant variant note =
  let
      info = getInfo note
  in
  Note { info | variant = variant }

updateX : Float -> Note -> Note
updateX x note =
  let
      info = getInfo note
  in
  Note { info | x = x }

updateY : Float -> Note -> Note
updateY y note =
  let
      info = getInfo note
  in
  Note { info | y = y }

updateVx : Float -> Note -> Note
updateVx vx note =
  let
      info = getInfo note
  in
  Note { info | vx = vx }

updateVy : Float -> Note -> Note
updateVy vy note =
  let
      info = getInfo note
  in
  Note { info | vy = vy }

encode : Note -> Json.Encode.Value
encode note =
  let
    info = getInfo note
  in
  Json.Encode.object
    [ ( "id", Json.Encode.int info.id )
    , ( "content", Json.Encode.string info.content )
    , ( "source", Json.Encode.string info.source )
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
  let
    record = Force.entity id 1
  in
  Note <| Info
    id
    content
    source
    (stringToVariant variant)
    ( Compressed 5 )
    record.x
    record.y
    record.vx
    record.vy

variantStringRepresentation : Variant -> String
variantStringRepresentation variant =
  case variant of
    Regular -> "regular"
    Index -> "index"

stringToVariant : String -> Variant
stringToVariant string =
  case string of
    "regular" -> Regular
    "index" -> Index
    _ -> Regular