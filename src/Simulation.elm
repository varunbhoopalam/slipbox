module Simulation exposing
  ( SimulationRecord
  , initNote
  , simulation
  , tick
  , State
  , isCompleted)

import Force
import Link
import Note

-- TYPES

type alias SimulationRecord =
  { id: Int
  , x: Float
  , y: Float
  , vx: Float
  , vy: Float
  }

type State comparable = State (Force.State comparable)

-- EXPOSED

initNote : Int -> SimulationRecord
initNote id =
  let
    entity = Force.entity id 1
  in
    SimulationRecord id entity.x entity.y entity.vx entity.vy

simulation : ( List Note.Note ) -> ( List Link.Link ) -> ( State Int, (List Note.Note) )
simulation notes links =
  let
    entities = List.map toEntity notes
    state = stateBuilder entities links
  in
  Force.tick state entities |> toStateRecordTuple

tick : ( List Note.Note ) -> State Int -> ( State Int, (List Note.Note) )
tick notes state =
  let
    entities = List.map toEntity notes
  in
   Force.tick (extract state) entities |> toStateRecordTuple

isCompleted: State Int -> Bool
isCompleted state = 
  extract state |> Force.isCompleted

-- HELPERS

stateBuilder : ( List (Force.Entity Int { note : Note.Note })) -> ( List Link.Link ) -> Force.State Int
stateBuilder entities links =
  Force.simulation
        [ Force.manyBodyStrength -15 (List.map (\n -> n.id) entities)
        , Force.links <| List.map (\link -> ( Link.getSourceId link, Link.getTargetId link)) links
        , Force.center 0 0
        ]

toEntity : Note.Note -> (Force.Entity Int { note : Note.Note })
toEntity note =
  { id = Note.getId note, x = Note.getX note, y = Note.getY note, vx = Note.getVx note, vy = Note.getVy note, note = note }

updateNote: (Force.Entity Int { note : Note.Note }) -> Note.Note
updateNote entity =
  Note.updateX entity.x <| Note.updateY entity.y <| Note.updateVx entity.vx <| Note.updateVy entity.vy entity.note

extract : State Int -> Force.State Int
extract state =
  case state of
     State simState -> simState

toStateRecordTuple : ( Force.State Int, List ( Force.Entity Int { note : Note.Note } ) ) -> ( State Int, (List Note.Note) )
toStateRecordTuple ( simState, records ) =
  ( State simState
  , List.map updateNote records
  )