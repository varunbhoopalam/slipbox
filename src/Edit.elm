module Edit exposing
  ( Edit
  , init
  , EditView(..)
  , view
  , toSelectNote
  , select
  , updateInput
  , toConfirmBreakLink
  , selectNoteOnGraph
  , cancel
  , confirm
  , hover
  , stopHover
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

type EditView
  = ViewSelectNote Filter
  | ViewNoteSelected Note.Note ( Maybe Source.Source ) DirectlyLinkedDiscussions ConnectedNotes
  | ViewDiscussionSelected Note.Note ConnectedNotes
  | ViewConfirmBreakLink Link.Link Graph.Graph SelectedNote HoveredNote

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

toSelectNote : Edit -> Edit
toSelectNote edit =
  case edit of
    SelectNote _ -> edit
    _ -> SelectNote ""

select : Note.Note -> Edit
select note =
  case Note.getVariant note of
    Note.Regular -> NoteSelected note
    Note.Discussion -> DiscussionSelected note

updateInput : String -> Edit -> Edit
updateInput input edit =
  case edit of
    SelectNote _ -> SelectNote input
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
    _ -> edit

confirm : Slipbox.Slipbox -> Edit -> ( Slipbox.Slipbox, Edit )
confirm slipbox edit =
  case edit of
    ConfirmBreakLink previousNoteSelected link _ _ _ ->
      ( Slipbox.breakLink link slipbox, NoteSelected previousNoteSelected )
    _ -> ( slipbox, edit )

hover : Note.Note -> Edit -> Edit
hover note edit =
  case edit of
    ConfirmBreakLink pn link graph selectedNote _ ->
      ConfirmBreakLink pn link graph selectedNote <| Just note
    _ -> edit

stopHover : Edit -> Edit
stopHover edit =
  case edit of
    ConfirmBreakLink pn link graph selectedNote _ ->
      ConfirmBreakLink pn link graph selectedNote Nothing
    _ -> edit