module Link exposing 
  ( Link, getSource
  , getTarget, is
  , create
  )

import Note
import IdGenerator
import IdGenerator exposing (IdGenerator)
type Link = Link Info

getInfo : Link -> Info
getInfo link =
  case link of
    Link info -> info

type alias Info = 
  { id: Int
  , sourceId: NoteId
  , targetId: NoteId
  }

-- TODO
-- init: 

getSource : Link -> (List Note.Note) -> (Maybe Note.Note)
getSource link notes =
  List.head <| List.filter (Note.is <| getSourceId link) notes

getTarget : Link -> (List Note.Note) -> (Maybe Note.Note)
getTarget link notes =
  List.head <| List.filter (Note.is <| getTargetId link) notes

is : Link -> Link -> Bool
is link1 link2 =
  getId link1 == getId link2

isAssociated : Note.Note -> Link -> Bool
isAssociated note link =
  getSourceId link |> Note.is note || getTargetId link |> Note.is note

create : IdGenerator.IdGenerator -> Note.Note -> Note.Note -> ( Link, IdGenerator.IdGenerator )
create generator sourceNote targetNote =
  let
      (id , idGenerator) = IdGenerator.generateId generator
  in
  (Link <| Info id sourceNote targetNote, idGenerator)