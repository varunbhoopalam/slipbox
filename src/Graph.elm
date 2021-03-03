module Graph exposing
  ( Graph
  , NotePosition
  )

import Link
import Note

type alias Graph =
  { positions :  List NotePosition
  , links : List Link.Link
  }

type alias NotePosition =
  { id : Int
  , note : Note.Note
  , x : Float
  , y : Float
  , vx : Float
  , vy : Float
  }