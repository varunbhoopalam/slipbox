module Source exposing 
  ( Source, getTitle
  , getAuthor, getContent
  , contains, is
  , createSource
  , updateContent
  , updateTitle
  , updateAuthor
  , encode
  )

import IdGenerator
import Json.Encode

type Source = Source Info
type alias Info = 
  { id : Int
  , title : String
  , author : String
  , content : String 
  }
type alias SourceContent =
  { title : String
  , author : String
  , content : String
  }

getInfo : Source -> Info
getInfo source =
  case source of Source info -> info

getTitle : Source -> String
getTitle source =
  .title <| getInfo source

getAuthor : Source -> String
getAuthor source =
  .author <| getInfo source

getContent : Source -> String
getContent source =
  .content <| getInfo source

contains : String -> Source -> Bool
contains input source =
  let
      info = getInfo source
      lowerInput = String.toLower input
      has = \s -> String.contains (String.toLower input) <| String.toLower s
  in
  has info.title || has info.author || has info.content

is : Source -> Source -> Bool
is source1 source2 =
  .id <| getInfo source1 == .id <| getInfo source2

createSource : IdGenerator.IdGenerator -> SourceContent -> ( Source, IdGenerator.IdGenerator)
createSource generator content =
  let
      ( id, idGenerator ) = IdGenerator.generateId generator
      info = Info id content.title content.author content.content
  in
  ( Source info, idGenerator )

updateContent : String -> Source -> Source
updateContent input source =
  let
      info = getInfo source
  in
    Source { info | content = input}

updateAuthor : String -> Source -> Source
updateAuthor input source =
  let
      info = getInfo source
  in
    Source { info | author = input}

updateTitle : String -> Source -> Source
updateTitle input source =
  let
      info = getInfo source
  in
    Source { info | title = input}

encode : Source -> Json.Encode.Value
encode source =
  let
    info = getInfo source
  in
  Json.Encode.object
    [ ( "id", Json.Encode.int info.id )
    , ( "title", Json.Encode.string info.title )
    , ( "author", Json.Encode.string info.author )
    , ( "content", Json.Encode.string info.content )
    ]