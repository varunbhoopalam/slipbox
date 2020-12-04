module Note exposing 
  ( Note, getId
  , getX, getY
  , getVariant, getGraphState
  , getContent, getTransform
  , contains, isLinked
  , isLinked, canLink
  , isAssociated, is
  , compress, expand
  , note, updateContent
  , updateSource, updateVariant
  , GraphState, Variant
  )

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
type GraphState = Compressed | Expanded
type alias NoteRecord = 
  { id : Int
  , content : String
  , source : String
  , noteType: String
  }

getId : Note -> NoteId
getId note =
  id <| getInfo note

getX : Note -> Float
getX note =
  x <| getInfo note
getY : Note -> Float
getY note =
  y <| getInfo note
  
getVariant : Note -> Variant
getVariant note =
  variant <| getInfo note

getGraphState : Note -> GraphState
getGraphState note =
  graphState <| getInfo note

getContent : Note -> String
getContent note =
  content <| getInfo note

getTransform : Note -> String
getTransform note =
  let
      info = getInfo note
      x = String.fromFloat info.x
      y = String.fromFloat info.y
  in
  String.concat [ "translate(", x, " ", y, ")" ]
getSource: Note -> String
contains: String -> Bool
isLinked: (List Link.Link) -> Note -> Bool
canLink: (List Link.Link) -> Note -> Bool
isAssociated: Source.Source -> Note -> Bool
is: Note -> Note -> Bool
is note1 note2 =
  (getId note1) == (getId note2)

  compress: Note -> Note
  expand: Note -> Note
  create: NoteContent -> Note
  updateContent: String -> Note -> Note
  updateSource: String -> Note -> Note
  updateVariant: Variant -> Note -> Note
-- TODO
-- init: NoteRecord -> Note
-- init record =
--   toNote (Simulation.init record.id) record

-- TODO
-- update: Simulation.SimulationRecord -> Note -> Note
-- update simRecord note =
--   case note of
--     Note content -> Note {content | x = simRecord.x , y = simRecord.y, vx = simRecord.vx, vy = simRecord.vy}
--     Selected content sContent -> Selected {content | x = simRecord.x , y = simRecord.y, vx = simRecord.vx, vy = simRecord.vy} sContent

-- Exposed Functions
-- sortDesc: (Note -> Note -> Order)
-- sortDesc noteA noteB =
--   case compare (getId noteA) (getId noteB) of
--        LT -> GT
--        EQ -> EQ
--        GT -> LT