module Item exposing 
  (Item(..), openNote
  , openSource, newNote
  , newSource, is
  , UpdateAction(..)
  , ItemId
  )

import Note
import Source
import IdGenerator
import IdGenerator exposing (IdGenerator)

type Item 
  = Note ItemId Note.Note
  | Source ItemId Source.Source
  | NewNote ItemId NewNoteContent
  | NewSource ItemId NewSourceContent
  | EditingNote ItemId Note.Note Note.Note
  | EditingSource ItemId Source.Source Source.Source
  | AddingLinkToNoteForm ItemId String Note.Note (Maybe Note.Note)
  | ConfirmDiscardNewNoteForm ItemId Note.Note
  | ConfirmDiscardNewSourceForm ItemId Source.Source
  | ConfirmDeleteNote ItemId Note.Note
  | ConfirmDeleteSource ItemId Source.Source
  | ConfirmRemoveLink ItemId Note.Note Note.Note Link.Link
type alias ItemId = Int

type alias NewNoteContent =
  { content : String
  , source : String
  , variant : Note.Variant
  , canSubmit : Bool
  }

type alias NewSourceContent =
  { title : String
  , author : String
  , content : String
  , canSubmit : Bool
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

newNote : IdGenerator.IdGenerator -> NewNoteContent -> ( Item, IdGenerator.IdGenerator)
newNote generator note =
  let
      ( id, idGenerator ) = IdGenerator.generateId generator
  in
  ( NewNote id note, idGenerator )

newSource : IdGenerator.IdGenerator -> NewSourceContent -> ( Item, IdGenerator.IdGenerator)
newSource generator source =
  let
      ( id, idGenerator ) = IdGenerator.generateId generator
  in
  ( NewSource id source, idGenerator )

is : Item.Item -> Item.Item -> Bool
is item1 item2 =
  let
      id1 = getId item1
      id2 = getId item2
  in
  equals id1 id2
  

type UpdateAction 
  = Content String 
  | Source String 
  | Variant Note.Variant 
  | Title String 
  | Author String 
  | AddLink Note.Note 
  | Edit 
  | PromptConfirmDelete 
  | AddLinkForm 
  | PromptConfirmRemoveLink Note.Note 
  | Cancel
