module Source exposing 
  ( Source, getTitle
  , getAuthor, getCreated
  , getUpdated, getContent
  , contains, is
  , createSource
  , updateContent
  , updateTitle
  , updateAuthor
  , sorter
  )

type Source = Source Info
type alias Info = 
  { id : Int
  , title : String
  , author : String
  , created : Int
  , updated : Int
  , content : String 
  }

sorter: Sort -> (Source.Source -> Source.Source -> Order)
Source.getId: Source -> Int
Source.getTitle: Source -> String
Source.getAuthor: Source -> String
Source.getCreated: Source -> Int
Source.getUpdated: Source -> Int
Source.getContent: Source -> String