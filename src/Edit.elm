module Edit exposing
  ( Edit
  , init
  , EditView(..)
  , view
  , toSelectNote
  , select
  )

import Note
import Slipbox
import Source
import SourceTitle

type Edit
  = SelectNote Filter
  | NoteSelected Note.Note

init : Edit
init = SelectNote ""

type alias Filter = String
type alias LinkedDiscussions = Maybe ( List Note.Note )
type alias EntryPointForDiscussion = Maybe ( List Note.Note )
type alias ConnectedNotes = Maybe ( List Note.Note )

type EditView
  = ViewSelectNote Filter
  | ViewNoteSelected Note.Note ( Maybe Source.Source ) LinkedDiscussions EntryPointForDiscussion ConnectedNotes

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
      in
      ViewNoteSelected
        note
        source
        Nothing
        Nothing
        Nothing

toSelectNote : Edit -> Edit
toSelectNote edit =
  case edit of
    SelectNote _ -> edit
    _ -> SelectNote ""

select : Note.Note -> Edit
select note = NoteSelected note