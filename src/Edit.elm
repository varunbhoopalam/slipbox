module Edit exposing
  ( Edit
  , init
  , EditView(..)
  , view
  , toSelectNote
  , toAddLinksFlow
  , select
  , updateInput
  , toConfirmBreakLink
  , selectNoteOnGraph
  , cancel
  , confirm
  , hover
  , stopHover
  , chooseDiscussion
  , toChooseDiscussion
  , addLink
  , cancelAddLink
  )

import Graph
import Link
import Note
import Slipbox
import Source
import SourceTitle

type Edit
  = SelectNote Filter
  | NoteSelected Note.Note
  | DiscussionSelected Note.Note
  | ConfirmBreakLink PreviousNoteSelected Link.Link Graph.Graph SelectedNote HoveredNote
  | AddLinkChooseDiscussion Filter Note.Note NotesDesignatedForLink
  | AddLinkDiscussionChosen PreviousNoteSelected Discussion Graph.Graph SelectedNote HoveredNote NotesDesignatedForLink

init : Edit
init = SelectNote ""

type alias Filter = String
type alias NoteLinkTuple = ( Note.Note, Link.Link )
type alias DirectlyLinkedDiscussions = Maybe ( List NoteLinkTuple )
type alias ConnectedNotes = Maybe ( List NoteLinkTuple )
type alias Discussion = Note.Note
type alias SelectedNote = Note.Note
type alias HoveredNote = Maybe Note.Note
type alias PreviousNoteSelected = Note.Note
type alias NotesDesignatedForLink = List Note.Note
type alias NotesAlreadyLinked = List Note.Note
type alias SelectedNoteIsLinked = Bool

type EditView
  = ViewSelectNote Filter
  | ViewNoteSelected Note.Note ( Maybe Source.Source ) DirectlyLinkedDiscussions ConnectedNotes
  | ViewDiscussionSelected Note.Note ConnectedNotes
  | ViewConfirmBreakLink Link.Link Graph.Graph SelectedNote HoveredNote
  | AddLinkChooseDiscussionView
  | AddLinkDiscussionChosenView PreviousNoteSelected Discussion Graph.Graph SelectedNote HoveredNote NotesDesignatedForLink NotesAlreadyLinked SelectedNoteIsLinked

view : Slipbox.Slipbox -> Edit -> EditView
view slipbox edit =
  case edit of
    SelectNote filter -> ViewSelectNote filter

    NoteSelected note ->
      let
        source =
          case SourceTitle.getTitle <| Note.getSource note of
            Nothing -> Nothing
            Just sourceTitle ->
              List.head <| Slipbox.getSources ( Just sourceTitle ) slipbox
        linkedNodes = Slipbox.getLinkedNotes note slipbox
        linkedDiscussions = List.filter ( \(n,_) -> Note.getVariant n == Note.Discussion ) linkedNodes
        linkedNotes = List.filter ( \(n,_) -> Note.getVariant n == Note.Regular ) linkedNodes
        lambda list = if List.isEmpty list then Nothing else Just list
      in
      ViewNoteSelected
        note
        source
        ( lambda linkedDiscussions )
        ( lambda linkedNotes )

    DiscussionSelected discussion ->
      let
        linkedNodes = Slipbox.getLinkedNotes discussion slipbox
        linkedNotes = List.filter ( \(n,_) -> Note.getVariant n == Note.Regular ) linkedNodes
        lambda list = if List.isEmpty list then Nothing else Just list
      in
      ViewDiscussionSelected
        discussion
        ( lambda linkedNotes )

    ConfirmBreakLink _ link graph selectedNote hoveredNote ->
      ViewConfirmBreakLink link graph selectedNote hoveredNote

    AddLinkChooseDiscussion filter note createdLinks ->
      AddLinkChooseDiscussionView


    AddLinkDiscussionChosen previousNoteSelected discussion graph selectedNote hoveredNote createdLinks ->
      AddLinkDiscussionChosenView
        previousNoteSelected
        discussion
        graph
        selectedNote
        hoveredNote
        createdLinks
        ( previousNoteSelected :: ( List.map Tuple.first <| Slipbox.getLinkedNotes previousNoteSelected slipbox ) )
        ( List.any ( Note.is selectedNote ) createdLinks)


toSelectNote : Edit -> Edit
toSelectNote edit =
  case edit of
    SelectNote _ -> edit
    _ -> SelectNote ""

toAddLinksFlow : Edit -> Edit
toAddLinksFlow edit =
  case edit of
    NoteSelected note -> AddLinkChooseDiscussion "" note []
    _ -> edit

select : Note.Note -> Edit
select note =
  case Note.getVariant note of
    Note.Regular -> NoteSelected note
    Note.Discussion -> DiscussionSelected note

updateInput : String -> Edit -> Edit
updateInput input edit =
  case edit of
    SelectNote _ -> SelectNote input
    AddLinkChooseDiscussion _ psn notesToLink -> AddLinkChooseDiscussion input psn notesToLink
    _ -> edit

toConfirmBreakLink : Note.Note -> Link.Link -> Slipbox.Slipbox -> Edit
toConfirmBreakLink note link slipbox =
  ConfirmBreakLink
    note
    link
    ( Graph.simulatePositions <| Slipbox.getDiscussionTreeWithCollapsedDiscussions note slipbox )
    note
    Nothing

selectNoteOnGraph : Note.Note -> Edit -> Edit
selectNoteOnGraph note edit =
  case edit of
    ConfirmBreakLink pn link graph _ hoveredNote ->
      ConfirmBreakLink pn link graph note hoveredNote
    _ -> edit

cancel : Edit -> Edit
cancel edit =
  case edit of
    ConfirmBreakLink previousNoteSelected _ _ _ _ ->
      NoteSelected previousNoteSelected
    AddLinkChooseDiscussion _ previousNoteSelected _ ->
      NoteSelected previousNoteSelected
    _ -> edit

confirm : Slipbox.Slipbox -> Edit -> ( Slipbox.Slipbox, Edit )
confirm slipbox edit =
  case edit of
    ConfirmBreakLink previousNoteSelected link _ _ _ ->
      ( Slipbox.breakLink link slipbox, NoteSelected previousNoteSelected )

    AddLinkChooseDiscussion _ previousNoteSelected notesToLink ->
      ( List.foldl ( Slipbox.addLink previousNoteSelected ) slipbox notesToLink, NoteSelected previousNoteSelected )

    _ -> ( slipbox, edit )

hover : Note.Note -> Edit -> Edit
hover note edit =
  case edit of
    ConfirmBreakLink pn link graph selectedNote _ ->
      ConfirmBreakLink pn link graph selectedNote <| Just note
    AddLinkDiscussionChosen pn discussion graph selectedNote _ notesToLink ->
      AddLinkDiscussionChosen pn discussion graph selectedNote ( Just note ) notesToLink
    _ -> edit

stopHover : Edit -> Edit
stopHover edit =
  case edit of
    ConfirmBreakLink pn link graph selectedNote _ ->
      ConfirmBreakLink pn link graph selectedNote Nothing
    AddLinkDiscussionChosen pn discussion graph selectedNote _ notesToLink ->
      AddLinkDiscussionChosen pn discussion graph selectedNote Nothing notesToLink
    _ -> edit

chooseDiscussion : Note.Note -> Slipbox.Slipbox -> Edit -> Edit
chooseDiscussion discussion slipbox edit =
  case edit of
    AddLinkChooseDiscussion _ note createdLinks ->
      AddLinkDiscussionChosen
        note
        discussion
        ( Graph.simulatePositions <| Slipbox.getDiscussionTreeWithCollapsedDiscussions discussion slipbox )
        discussion
        Nothing
        createdLinks
    _ -> edit

toChooseDiscussion : Edit -> Edit
toChooseDiscussion edit =
  case edit of
    NoteSelected note ->
      AddLinkChooseDiscussion "" note []
    AddLinkDiscussionChosen pns _ _ _ _ notesToLink ->
      AddLinkChooseDiscussion "" pns notesToLink

addLink : Edit -> Edit
addLink edit =
  case edit of
    AddLinkDiscussionChosen pns discussion graph selectedNote hoverNote notesToLink ->
      AddLinkDiscussionChosen pns discussion graph selectedNote hoverNote ( selectedNote :: notesToLink )
    _ -> edit

cancelAddLink :  Edit -> Edit
cancelAddLink edit =
  case edit of
    AddLinkDiscussionChosen pns discussion graph selectedNote hoverNote notesToLink ->
      AddLinkDiscussionChosen pns discussion graph selectedNote hoverNote <|
        List.filter (\n -> not <| Note.is selectedNote n ) notesToLink
    _ -> edit