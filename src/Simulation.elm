module Simulation exposing (SimulationRecord, init, simulate)

import Force
import Debug

type alias SimulationRecord =
  { id: Int
  , x: Float
  , y: Float
  , vx: Float
  , vy: Float
  }

init: Int -> SimulationRecord
init id =
  let
    entity = Force.entity id 1
  in
    SimulationRecord id entity.x entity.y entity.vx entity.vy

simulate: (List SimulationRecord) -> (List (Int, Int)) -> (List SimulationRecord)
simulate records links =
  -- List.map toSimulationRecord (Force.computeSimulation (stateBuilder records links) records)
  List.map toSimulationRecord (Tuple.second (Force.tick (stateBuilder records links) records))

stateBuilder: (List SimulationRecord) -> (List (Int, Int)) -> Force.State Int
stateBuilder records links =
  Force.simulation 
        [ Force.manyBodyStrength -30 (List.map (\n -> n.id) records)
        , Force.links links
        , Force.center 0 0
        ]

toSimulationRecord: (Force.Entity Int { }) -> SimulationRecord
toSimulationRecord entity =
  SimulationRecord entity.id entity.x entity.y entity.vx entity.vy