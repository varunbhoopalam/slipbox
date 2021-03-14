module SourceTitle exposing
  ( SourceTitle
  , validateNewSourceTitle
  , sourceTitle
  , getTitle
  , encode
  )

type SourceTitle
  = HasSource String
  | NoSource

validateNewSourceTitle : ( List String ) -> String -> Bool
validateNewSourceTitle existingTitles title =
  isValid title && allExistingTitlesAreDifferent existingTitles title

sourceTitle : String -> SourceTitle
sourceTitle title =
  if isValid title then
    HasSource title
  else
    NoSource

getTitle : SourceTitle -> Maybe String
getTitle st =
  case st of
    HasSource title -> Just title
    NoSource -> Nothing

encode : SourceTitle -> String
encode st =
  case st of
    HasSource title -> title
    NoSource -> noSourceEncoding

-- HELPER
isValid : String -> Bool
isValid title = titleIsNotEmpty title && titleIsNotNA title

noSourceEncoding = "n/a"
titleIsNotEmpty title = not <| String.isEmpty title
titleIsNotNA title = ( String.toLower title ) /= noSourceEncoding
titlesAreDifferent title = ( \t -> (String.toLower t ) /= (String.toLower title ) )
allExistingTitlesAreDifferent existingTitles title =
  List.all
    ( titlesAreDifferent title )
    existingTitles