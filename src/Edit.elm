module Edit exposing
  ( Edit
  , init
  , EditView(..)
  , view
  , toSelectNote
  , select
  , updateInput
  , confirmBreakLink
  , selectNoteOnGraph
  , cancel
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
  | ConfirmBreakLink PreviousNoteSelected Link.Link Graph.Graph SelectedNote

init : Edit
init = SelectNote ""

type alias Filter = String
type alias NoteLinkTuple = ( Note.Note, Link.Link )
type alias DirectlyLinkedDiscussions = Maybe ( List NoteLinkTuple )
type alias ConnectedNotes = Maybe ( List NoteLinkTuple )
type alias Discussion = Note.Note
type alias SelectedNote = Note.Note
type alias PreviousNoteSelected = Note.Note

type EditView
  = ViewSelectNote Filter
  | ViewNoteSelected Note.Note ( Maybe Source.Source ) DirectlyLinkedDiscussions ConnectedNotes
  | ViewConfirmBreakLink Link.Link Graph.Graph SelectedNote

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

    ConfirmBreakLink _ link graph selectedNote -> ViewConfirmBreakLink link graph selectedNote

toSelectNote : Edit -> Edit
toSelectNote edit =
  case edit of
    SelectNote _ -> edit
    _ -> SelectNote ""

select : Note.Note -> Edit
select note = NoteSelected note

updateInput : String -> Edit -> Edit
updateInput input edit =
  case edit of
    SelectNote _ -> SelectNote input
    _ -> edit

confirmBreakLink : Note.Note -> Link.Link -> Slipbox.Slipbox -> Edit
confirmBreakLink note link slipbox =
  ConfirmBreakLink
    note
    link
    ( Graph.simulatePositions <| Slipbox.getDiscussionTreeWithCollapsedDiscussions note slipbox )
    note

selectNoteOnGraph : Note.Note -> Edit -> Edit
selectNoteOnGraph note edit =
  case edit of
    ConfirmBreakLink pn link graph _ -> ConfirmBreakLink pn link graph note
    _ -> edit

cancel : Edit -> Edit
cancel edit =
  case edit of
    ConfirmBreakLink previousNoteSelected _ _ _ ->
      NoteSelected previousNoteSelected
    _ -> edit