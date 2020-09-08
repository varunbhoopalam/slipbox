module Input exposing (Input, init, update, get)

type Input = Input String

init: Input
init = Input ""

update: String -> Input -> Input
update query search =
  case search of Input _ -> Input query

get: Input -> String
get search =
  case search of Input str -> str