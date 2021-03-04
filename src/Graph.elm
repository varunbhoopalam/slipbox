module Graph exposing
  ( Graph
  , NotePosition
  , simulatePositions
  )

import Link
import Note
import Force

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

simulatePositions : ( List Note.Note, List Link.Link ) -> Graph
simulatePositions (notes, links) =
  let
    toEntity note =
      let
        id = Note.getId note
        init = Force.entity id 1
      in
      { id = id
      , x = init.x
      , y = init.y
      , vx = init.vx
      , vy = init.vy
      , note = note
      }
    entities = List.map toEntity notes
    state =
      Force.simulation
        [ Force.manyBody (List.map (\n -> n.id) entities)
        , Force.links <| List.map (\link -> ( Link.getSourceId link, Link.getTargetId link)) links
        , Force.center 0 0
        ]
    notePositions = Force.computeSimulation state entities
  in
  Graph notePositions links