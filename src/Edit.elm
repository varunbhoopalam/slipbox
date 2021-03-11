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

type Edit
  = SelectNote Filter
  | NoteSelected Note.Note

init : Edit
init = SelectNote ""

type alias Filter = String
type alias LinkedDiscussions = List Note.Note
type alias DiscussionEntryPoints = List Note.Note
type alias ConnectedNotes = List Note.Note

type EditView
  = ViewSelectNote Filter
  | ViewNoteSelected Note.Note ( Maybe Source.Source ) LinkedDiscussions DiscussionEntryPoints ConnectedNotes

view : Slipbox.Slipbox -> Edit -> EditView
view slipbox edit =
  case edit of
    SelectNote filter -> ViewSelectNote filter
    NoteSelected note ->
      let
        source =
          case Note.getSource note of
            Nothing -> Nothing
            Just sourceTitle ->
              List.head <| Slipbox.getSources ( Just sourceTitle ) slipbox
      in
      ViewNoteSelected
        note
        source

toSelectNote : Edit -> Edit
toSelectNote edit =
  case edit of
    SelectNote _ -> edit
    _ -> SelectNote ""

select : Note.Note -> Edit
select note = NoteSelected note