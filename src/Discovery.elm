module Discovery exposing
  ( Discovery
  , init
  , view
  , DiscoveryView(..)
  , viewDiscussion
  )

import Graph
import Note
import Slipbox

type Discovery
  = ViewDiscussion Discussion SelectedNote Graph.Graph
  | ChooseDiscussion FilterInput

type alias Discussion = Note.Note
type alias SelectedNote = Note.Note
type alias FilterInput = String

type DiscoveryView
  = ViewDiscussionView Discussion SelectedNote Graph.Graph
  | ChooseDiscussionView FilterInput

init : Discovery
init =
  ChooseDiscussion ""

view : Discovery -> DiscoveryView
view discovery =
  case discovery of
    ViewDiscussion discussion selectedNote graph ->
      ViewDiscussionView discussion selectedNote graph

    ChooseDiscussion filterInput ->
      ChooseDiscussionView filterInput

viewDiscussion : Note.Note -> Slipbox.Slipbox -> Discovery -> Discovery
viewDiscussion discussion slipbox _ =
  ViewDiscussion
    discussion
    discussion
    ( Graph.simulatePositions
      <| Slipbox.getAllNotesAndLinksInQuestionTree discussion slipbox )

