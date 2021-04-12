module Explore exposing
  ( Explore
  , init
  , ExploreView
  , view
  , hover
  , stopHover
  )

import Graph
import Note
import Slipbox

type Explore
  = ErrorStateNoDiscussions
  | ForceDirectedGraph Graph.Graph HoveredNote

type alias HoveredNote = Maybe Note.Note

-- Note: This graph will not have anything selected, all will always be regular notes.
-- If someone clicks a note it will simply open that discussion in discovery mode

init : Slipbox.Slipbox -> Explore
init slipbox =
  let discussions = Slipbox.getDiscussions Nothing slipbox
  in
  if List.isEmpty discussions then
    ErrorStateNoDiscussions
  else
    ForceDirectedGraph
      ( Graph.simulatePositions <| Slipbox.getAllDiscussionsAndLinksBetweenDiscussions slipbox )
      Nothing