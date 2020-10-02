module Simulation exposing (SimulationRecord, init, simulate, tick, State, isCompleted)

import Force
import Debug

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

init: Int -> SimulationRecord
init id =
  let
    entity = Force.entity id 1
  in
    SimulationRecord id entity.x entity.y entity.vx entity.vy

simulate: (List SimulationRecord) -> (List (Int, Int)) -> (State Int, (List SimulationRecord))
simulate records links =
  Force.tick (stateBuilder records links) records |> toStateRecordTuple

tick: State Int -> List SimulationRecord -> (State Int, (List SimulationRecord))
tick state records = Force.tick (extract state) records |> toStateRecordTuple

isCompleted: State Int -> Bool
isCompleted state = 
  extract state |> Force.isCompleted

-- HELPERS

stateBuilder: (List SimulationRecord) -> (List (Int, Int)) -> Force.State Int
stateBuilder records links =
  Force.simulation
        [ Force.manyBodyStrength -15 (List.map (\n -> n.id) records)
        , Force.links links
        , Force.center 0 0
        ]

toSimulationRecord: (Force.Entity Int { }) -> SimulationRecord
toSimulationRecord entity =
  SimulationRecord entity.id entity.x entity.y entity.vx entity.vy

extract: State Int -> Force.State Int
extract state =
  case state of
     State simState -> simState

toStateRecordTuple: (Force.State Int, List (Force.Entity Int { })) -> (State Int, (List SimulationRecord))
toStateRecordTuple (simState,records) = (State simState, List.map toSimulationRecord records)