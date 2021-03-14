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
  , hover
  , stopHover
  )

import Graph
import Note
import Slipbox

type Discovery
  = ViewDiscussion Discussion SelectedNote Graph.Graph HoverNote
  | ChooseDiscussion FilterInput
  | DesignateDiscussionEntryPoint SelectedNote String


type alias Discussion = Note.Note
type alias SelectedNote = Note.Note
type alias FilterInput = String
type alias HoverNote = Maybe Note.Note

type DiscoveryView
  = ViewDiscussionView Discussion SelectedNote Graph.Graph HoverNote
  | ChooseDiscussionView String
  | DesignateDiscussionEntryPointView String String

init : Discovery
init =
  ChooseDiscussion ""

view : Discovery -> DiscoveryView
view discovery =
  case discovery of
    ViewDiscussion discussion selectedNote graph hoverNote ->
      ViewDiscussionView discussion selectedNote graph hoverNote

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
    Nothing

selectNote : Note.Note -> Discovery -> Discovery
selectNote note discovery =
  case discovery of
    ViewDiscussion discussion _ graph hoverNote -> ViewDiscussion discussion note graph hoverNote
    _ -> discovery

hover : Note.Note -> Discovery -> Discovery
hover note discovery =
  case discovery of
    ViewDiscussion discussion selectedNote graph _ -> ViewDiscussion discussion selectedNote graph <| Just note
    _ -> discovery

stopHover : Discovery -> Discovery
stopHover discovery =
  case discovery of
    ViewDiscussion discussion selectedNote graph _ -> ViewDiscussion discussion selectedNote graph Nothing
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
    ViewDiscussion _ selectedNote _ _ ->
      DesignateDiscussionEntryPoint selectedNote ""
    _ -> discovery