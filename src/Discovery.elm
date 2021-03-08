module Discovery exposing
  ( Discovery
  , init
  , view
  , DiscoveryView(..)
  , viewDiscussion
  , selectNote
  , back
  , updateInput
  , submit
  , startNewDiscussion
  )

import Graph
import Note
import Slipbox

type Discovery
  = ViewDiscussion Discussion SelectedNote Graph.Graph
  | ChooseDiscussion FilterInput
  | DesignateDiscussionEntryPoint SelectedNote String


type alias Discussion = Note.Note
type alias SelectedNote = Note.Note
type alias FilterInput = String

type DiscoveryView
  = ViewDiscussionView Discussion SelectedNote Graph.Graph
  | ChooseDiscussionView String
  | DesignateDiscussionEntryPointView String String

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

    DesignateDiscussionEntryPoint selectedNote discussionInput ->
      DesignateDiscussionEntryPointView (Note.getContent selectedNote) discussionInput

viewDiscussion : Discussion -> Slipbox.Slipbox -> Discovery -> Discovery
viewDiscussion discussion slipbox _ =
  ViewDiscussion
    discussion
    discussion
    ( Graph.simulatePositions
      <| Slipbox.getDiscussionTreeWithCollapsedDiscussions discussion slipbox )

selectNote : Note.Note -> Discovery -> Discovery
selectNote note discovery =
  case discovery of
    ViewDiscussion discussion _ graph -> ViewDiscussion discussion note graph
    _ -> discovery

back : Discovery -> Discovery
back discovery =
  case discovery of
    ChooseDiscussion _ -> discovery
    _ -> init

updateInput : String -> Discovery -> Discovery
updateInput input discovery =
  case discovery of
    ChooseDiscussion _ -> ChooseDiscussion input
    DesignateDiscussionEntryPoint note _ -> DesignateDiscussionEntryPoint note input
    _ -> discovery

submit : Slipbox.Slipbox -> Discovery -> ( Slipbox.Slipbox, Discovery )
submit slipbox discovery =
  case discovery of
    DesignateDiscussionEntryPoint selectedNote discussionInput ->
      let
        ( slipboxWithNewDiscussion, discussion ) = Slipbox.addDiscussion discussionInput slipbox
        newSlipbox = Slipbox.addLink discussion selectedNote slipboxWithNewDiscussion
      in
      ( newSlipbox, viewDiscussion discussion newSlipbox discovery )
    _ -> ( slipbox, discovery )

startNewDiscussion : Discovery -> Discovery
startNewDiscussion discovery =
  case discovery of
    ViewDiscussion _ selectedNote _ ->
      DesignateDiscussionEntryPoint selectedNote ""
    _ -> discovery