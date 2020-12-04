module Item exposing 
  (Item(..), openNote
  , openSource, newNote
  , newSource, is
  , UpdateAction(..)
  , ItemId
  )

import Note
import Source

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

openNote : Note.Note -> Item
openNote note =
  Note generateId note
  
openSource : Source.Source -> Item
openSource source =
  Source generateId source

newNote : NewNoteContent -> Item
newNote note =
  NewNote generateId note

newSource : NewSourceContent -> Item
newSource source =
  NewSource generateId source

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
