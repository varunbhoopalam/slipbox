module IdGenerator exposing 
  ( IdGenerator
  , init
  , generateId
  )

type IdGenerator = IdGenerator Int

init : Int -> IdGenerator
init id =
  IdGenerator id

generateId : IdGenerator -> (Int, IdGenerator)
generateId generator =
  case generator of
    IdGenerator id -> ( id, IdGenerator <| id + 1 )