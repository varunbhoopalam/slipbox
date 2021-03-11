module Item exposing 
  ( Item(..)
  , openNote
  , openSource
  , newNote
  , newSource
  , newQuestion
  , is
  , getNote
  , getSource
  , NewNoteContent
  , NewSourceContent
  , noteCanSubmit
  , sourceCanSubmit
  , openTray
  , closeTray
  , ButtonTray
  , isTrayOpen
  , isEmpty
  )

import Note
import Source
import IdGenerator
import IdGenerator exposing (IdGenerator)
import Link
import SourceTitle

type Item 
  = Note ItemId ButtonTray Note.Note
  | Source ItemId ButtonTray Source.Source
  | NewNote ItemId ButtonTray NewNoteContent
  | NewSource ItemId ButtonTray NewSourceContent
  | NewDiscussion ItemId ButtonTray String
  | EditingNote ItemId ButtonTray Note.Note Note.Note
  | EditingSource ItemId ButtonTray Source.Source Source.Source
  | AddingLinkToNoteForm ItemId ButtonTray String Note.Note (Maybe Note.Note)
  | ConfirmDiscardNewNoteForm ItemId ButtonTray NewNoteContent
  | ConfirmDiscardNewSourceForm ItemId ButtonTray NewSourceContent
  | ConfirmDiscardNewDiscussion ItemId ButtonTray String
  | ConfirmDeleteNote ItemId ButtonTray Note.Note
  | ConfirmDeleteSource ItemId ButtonTray Source.Source
  | ConfirmDeleteLink ItemId ButtonTray Note.Note Note.Note Link.Link

type alias ItemId = Int

type ButtonTray = Open | Closed

type alias NewNoteContent =
  { content : String
  , source : String
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
  ( Note id Closed note, idGenerator )
  
openSource : IdGenerator.IdGenerator -> Source.Source -> ( Item, IdGenerator.IdGenerator)
openSource generator source =
  let
      ( id, idGenerator ) = IdGenerator.generateId generator
  in
  ( Source id Closed source, idGenerator )

newNote : IdGenerator.IdGenerator -> ( Item, IdGenerator.IdGenerator)
newNote generator =
  let
      ( id, idGenerator ) = IdGenerator.generateId generator
      emptyContent = NewNoteContent "" ""
  in
  ( NewNote id Closed emptyContent, idGenerator )

noteCanSubmit : NewNoteContent -> Bool
noteCanSubmit newNoteContent =
  ( not <| String.isEmpty newNoteContent.content )

newSource : IdGenerator.IdGenerator -> ( Item, IdGenerator.IdGenerator)
newSource generator =
  let
      ( id, idGenerator ) = IdGenerator.generateId generator
      emptyContent = NewSourceContent "" "" ""
  in
  ( NewSource id Closed emptyContent, idGenerator )

newQuestion : IdGenerator.IdGenerator -> ( Item, IdGenerator.IdGenerator)
newQuestion generator =
  let
      ( id, idGenerator ) = IdGenerator.generateId generator
  in
  ( NewDiscussion id Closed "", idGenerator )

sourceCanSubmit : NewSourceContent -> ( List String ) -> Bool
sourceCanSubmit newSourceContent existingTitles =
  ( not <| String.isEmpty newSourceContent.title ) &&
  ( not <| String.isEmpty newSourceContent.author ) &&
  ( SourceTitle.validateNewSourceTitle existingTitles newSourceContent.title )

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
    Note id _ _ -> id
    Source id _ _  -> id
    NewNote id _ _  -> id
    NewSource id _ _  -> id
    NewDiscussion id _ _ -> id
    EditingNote id _ _ _ -> id
    EditingSource id _ _ _ -> id
    AddingLinkToNoteForm id _ _ _ _ -> id
    ConfirmDiscardNewNoteForm id _ _ -> id
    ConfirmDiscardNewSourceForm id _ _ -> id
    ConfirmDiscardNewDiscussion id _ _ -> id
    ConfirmDeleteNote id _ _ -> id
    ConfirmDeleteSource id _ _ -> id
    ConfirmDeleteLink id _ _ _ _ -> id

getNote : Item -> ( Maybe Note.Note )
getNote item =
  case item of
    Note _ _ note -> Just note
    EditingNote _ _ note _ -> Just note
    AddingLinkToNoteForm _ _ _ note _ -> Just note
    ConfirmDeleteNote _ _ note -> Just note
    ConfirmDeleteLink _ _ note _ _ -> Just note
    _ -> Nothing

getSource : Item -> ( Maybe Source.Source )
getSource item =
  case item of
    Source _ _ source -> Just source
    EditingSource _ _ source _ -> Just source
    ConfirmDeleteSource _ _ source -> Just source
    _ -> Nothing

getButtonTray : Item -> ButtonTray
getButtonTray item =
  case item of
    Note _ tray _ -> tray
    Source _ tray _  -> tray
    NewNote _ tray _  -> tray
    NewSource _ tray _  -> tray
    NewDiscussion _ tray _ -> tray
    EditingNote _ tray _ _ -> tray
    EditingSource _ tray _ _ -> tray
    AddingLinkToNoteForm _ tray _ _ _ -> tray
    ConfirmDiscardNewNoteForm _ tray _ -> tray
    ConfirmDiscardNewSourceForm _ tray _ -> tray
    ConfirmDiscardNewDiscussion _ tray _ -> tray
    ConfirmDeleteNote _ tray _ -> tray
    ConfirmDeleteSource _ tray _ -> tray
    ConfirmDeleteLink _ tray _ _ _ -> tray

openTray : Item -> Item
openTray item =
  setTray Open item

closeTray : Item -> Item
closeTray item =
  setTray Closed item

isTrayOpen : Item -> Bool
isTrayOpen item =
  getButtonTray item == Open

setTray : ButtonTray -> Item -> Item
setTray tray item =
  case item of
    Note id _ note -> Note id tray note
    Source id _ source -> Source id tray source
    NewNote id _ content -> NewNote id tray content
    NewSource id _ content -> NewSource id tray content
    NewDiscussion id _ question -> NewDiscussion id tray question
    EditingNote id _ note noteWithEdits -> EditingNote id tray note noteWithEdits
    EditingSource id _ source sourceWithEdits -> EditingSource id tray source sourceWithEdits
    AddingLinkToNoteForm id _ input note maybeNote -> AddingLinkToNoteForm id tray input note maybeNote
    ConfirmDiscardNewNoteForm id _ content -> ConfirmDiscardNewNoteForm id tray content
    ConfirmDiscardNewSourceForm id _ content -> ConfirmDiscardNewSourceForm id tray content
    ConfirmDiscardNewDiscussion id _ question -> ConfirmDiscardNewDiscussion id tray question
    ConfirmDeleteNote id _ note -> ConfirmDeleteNote id tray note
    ConfirmDeleteSource id _ source -> ConfirmDeleteSource id tray source
    ConfirmDeleteLink id _ note linkedNote link -> ConfirmDeleteLink id tray note linkedNote link

isEmpty : Item -> Bool
isEmpty item =
  case item of
    NewNote _ _ newNoteContent ->
      String.isEmpty newNoteContent.content && String.isEmpty newNoteContent.source

    NewSource _ _ newSourceContent ->
      String.isEmpty newSourceContent.title &&
      String.isEmpty newSourceContent.author &&
      String.isEmpty newSourceContent.content

    NewDiscussion _ _ string ->
      String.isEmpty string

    _ -> False

