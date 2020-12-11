module IdGenerator exposing 
  ( IdGenerator
  , init
  , generateId
  , encode
  , decode
  )

import Json.Decode
import Json.Encode

type IdGenerator = IdGenerator Int

init : Int -> IdGenerator
init id =
  IdGenerator id

generateId : IdGenerator -> (Int, IdGenerator)
generateId generator =
  case generator of
    IdGenerator id -> ( id, IdGenerator <| id + 1 )

encode : IdGenerator -> Json.Encode.Value
encode idGenerator =
  Json.Encode.int <| getId idGenerator

decode : Json.Decode.Decoder IdGenerator
decode = Json.Decode.map init Json.Decode.int

-- HELPER

getId : IdGenerator -> Int
getId idGenerator =
  case idGenerator of IdGenerator id -> id