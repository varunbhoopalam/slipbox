module Item exposing 
  ( Item(..)
  , openNote
  , openSource
  , newNote
  , newSource
  , is
  , getNote
  , getSource
  , NewNoteContent
  , NewSourceContent
  , noteCanSubmit
  , sourceCanSubmit
  )

import Note
import Source
import IdGenerator
import IdGenerator exposing (IdGenerator)
import Link

type Item 
  = Note ItemId Note.Note
  | Source ItemId Source.Source
  | NewNote ItemId NewNoteContent
  | NewSource ItemId NewSourceContent
  | EditingNote ItemId Note.Note Note.Note
  | EditingSource ItemId Source.Source Source.Source
  | AddingLinkToNoteForm ItemId String Note.Note (Maybe Note.Note)
  | ConfirmDiscardNewNoteForm ItemId NewNoteContent
  | ConfirmDiscardNewSourceForm ItemId NewSourceContent
  | ConfirmDeleteNote ItemId Note.Note
  | ConfirmDeleteSource ItemId Source.Source
  | ConfirmDeleteLink ItemId Note.Note Note.Note Link.Link

type alias ItemId = Int

type alias NewNoteContent =
  { content : String
  , source : String
  , variant : Note.Variant
  }

type alias NewSourceContent =
  { title : String
  , author : String
  , content : String
  }

openNote : IdGenerator.IdGenerator -> Note.Note -> ( Item, IdGenerator.IdGenerator)
openNote generator note =
  let
      ( id, idGenerator ) = IdGenerator.generateId generator
  in
  ( Note id note, idGenerator )
  
openSource : IdGenerator.IdGenerator -> Source.Source -> ( Item, IdGenerator.IdGenerator)
openSource generator source =
  let
      ( id, idGenerator ) = IdGenerator.generateId generator
  in
  ( Source id source, idGenerator )

newNote : IdGenerator.IdGenerator -> ( Item, IdGenerator.IdGenerator)
newNote generator =
  let
      ( id, idGenerator ) = IdGenerator.generateId generator
      emptyContent = NewNoteContent "" "" Note.Regular
  in
  ( NewNote id emptyContent, idGenerator )

noteCanSubmit : NewNoteContent -> Bool
noteCanSubmit newNoteContent =
  ( not <| String.isEmpty newNoteContent.source ) && ( not <| String.isEmpty newNoteContent.content )

newSource : IdGenerator.IdGenerator -> ( Item, IdGenerator.IdGenerator)
newSource generator =
  let
      ( id, idGenerator ) = IdGenerator.generateId generator
      emptyContent = NewSourceContent "" "" ""
  in
  ( NewSource id emptyContent, idGenerator )

sourceCanSubmit : NewSourceContent -> Bool
sourceCanSubmit newSourceContent =
  ( not <| String.isEmpty newSourceContent.title ) &&
  ( not <| String.isEmpty newSourceContent.author ) &&
  ( not <| String.isEmpty newSourceContent.content )

is : Item -> Item -> Bool
is item1 item2 =
  let
      id1 = getId item1
      id2 = getId item2
  in
  id1 == id2

getId : Item -> Int
getId item =
  case item of
    Note id _ -> id
    Source id _  -> id
    NewNote id _  -> id
    NewSource id _  -> id
    EditingNote id _ _ -> id
    EditingSource id _ _ -> id
    AddingLinkToNoteForm id _ _ _ -> id
    ConfirmDiscardNewNoteForm id _ -> id
    ConfirmDiscardNewSourceForm id _ -> id
    ConfirmDeleteNote id _ -> id
    ConfirmDeleteSource id _ -> id
    ConfirmDeleteLink id _ _ _ -> id

getNote : Item -> ( Maybe Note.Note )
getNote item =
  case item of
    Note _ note -> Just note
    EditingNote _ note _ -> Just note
    AddingLinkToNoteForm _ _ note _ -> Just note
    ConfirmDeleteNote _ note -> Just note
    ConfirmDeleteLink _ note _ _ -> Just note
    _ -> Nothing

getSource : Item -> ( Maybe Source.Source )
getSource item =
  case item of
    Source _ source -> Just source
    EditingSource _ source _ -> Just source
    ConfirmDeleteSource _ source -> Just source
    _ -> Nothing