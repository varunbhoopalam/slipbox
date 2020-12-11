module Link exposing 
  ( Link
  , is
  , isSource
  , isTarget
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
  , sourceId: Int
  , targetId: Int
  }

-- TODO
-- init:

isSource : Link -> Note.Note -> Bool
isSource link note =
  Note.isNoteFromId (getSourceId link) note

isTarget : Link -> Note.Note -> Bool
isTarget link note =
  Note.isNoteFromId (getTargetId link) note

is : Link -> Link -> Bool
is link1 link2 =
  getId link1 == getId link2

create : IdGenerator.IdGenerator -> Note.Note -> Note.Note -> ( Link, IdGenerator.IdGenerator )
create generator sourceNote targetNote =
  let
      (id , idGenerator) = IdGenerator.generateId generator
  in
  (Link <| Info id sourceNote targetNote, idGenerator)

getId : Link -> Int
getId link =
  .id <| getInfo link

getSourceId : Link -> Int
getSourceId link =
  .sourceId <| getInfo link

getTargetId : Link -> Int
getTargetId link =
  .targetId <| getInfo link