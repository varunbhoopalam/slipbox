module Slipbox exposing 
  ( Slipbox, initialize
  , getNotesAndLinks
  , getNotes, getSources
  , getItems, getLinkedNotes
  , getNotesThatCanLinkToNote
  , getNotesAssociatedToSource
  , compressNote, expandNote
  , openNote, openSource
  , newNoteForm, newSourceForm
  , dismissItem, deleteNote
  , deleteSource, createNote
  , createSource
  , submitNoteEdits
  , submitSourceEdits
  , addLink, removeLink
  , updateItem, undo
  , redo, tick, save
  , getHistory
  , simulationIsCompleted
  )

import Simulation
import Note
import Link
import Action
import Item
import Source

--Types
type Slipbox = Slipbox Content

type alias Content =
  { notes: List Note.Note
  , links: List Link.Link
  , actions: List Action.Action
  , items: List Item.Item
  , sources: List Source.Source
  , state: Simulation.State Int
  }

getContent : Slipbox -> Content
getContent slipbox =
  case slipbox of 
    Slipbox content -> content

-- Returns Slipbox

-- TODO
initialize : (List Note.NoteRecord) -> (List LinkRecord) -> ActionResponse -> Slipbox
-- initialize notes links response =
--   let
--     l =  initializeLinks links
--     (state, newNotes) = initializeNotes notes l
--   in
--     Slipbox (Content newNotes l (actionsInit response) LinkForm.initLinkForm state)

getNotesAndLinks : (Maybe String) -> Slipbox -> ((List Note.Note), (List Link.Link))
getNotesAndLinks maybeSearch slipbox =
  let
      content = getContent slipbox
  in
  case maybeSearch of
    Just search -> 
      let
        filteredNotes = List.filter (Note.contains search) content.notes
      in
      ( filteredNotes, List.filter ( Link.isRelevant <| List.map Note.getId filteredNotes ) content.links )
    Nothing -> ( content.notes, content.links )

getNotes : (Maybe String) -> Slipbox -> (List Note.Note)
getNotes maybeSearch slipbox =
  case maybeSearch of
    Just search -> List.filter (Note.contains search) <| notes <| getContent slipbox
    Nothing -> notes <| getContent slipbox

getSources : (Maybe String) -> Slipbox -> (List Source.Source)
getSources maybeSearch slipbox =
  case maybeSearch of
    Just search -> List.filter (Source.contains search) <| sources <| getContent slipbox
    Nothing -> sources <| getContent slipbox

getItems : Slipbox -> (List Item.Item)
getItems slipbox =
  items <| getContent slipbox

getLinkedNotes : Note.Note -> Slipbox -> (List Note.Note)
getLinkedNotes note slipbox =
  let
      content = getContent slipbox
  in
  List.filter ( Note.isLinked content.links note ) content.notes

getNotesThatCanLinkToNote : Note.Note -> Slipbox -> (List Note.Note)
getNotesThatCanLinkToNote note slipbox =
  let
      content = getContent slipbox
  in
  List.filter ( Note.canLink content.links note ) content.notes

getNotesAssociatedToSource : Source.Source -> Slipbox -> (List Note.Note)
getNotesAssociatedToSource source slipbox =
  List.filter ( Note.isAssociated source ) <| notes <| getContent slipbox

compressNote : Note.Note -> Slipbox -> Slipbox
compressNote note slipbox =
  let
      content = getContent slipbox
      conditionallyCompressNote = \n -> if Note.is note n then Note.compress n else n
  in
  Slipbox { content | notes = List.map conditionallyCompressNote content.notes}

expandNote : Note.Note -> Slipbox -> Slipbox
expandNote note slipbox =
  let
      content = getContent slipbox
      conditionallyExpandNote = \n -> if Note.is note n then Note.expand n else n
  in
  Slipbox { content | notes = List.map conditionallyExpandNote content.notes}

openNote : (Maybe Item.Item) -> Note.Note -> Slipbox -> Slipbox
openNote maybeItem note slipbox =
  let
      content = getContent slipbox
      newItem = Item.Note Item.generateId note
      
  in
  case maybeItem of
     Just itemToMatch -> Slipbox { content | items = List.foldr (buildItemList itemToMatch newItem) [] content.items}
     Nothing -> Slipbox { content | items = newItem :: content.items }

openSource : (Maybe Item.Item) -> Source.Source -> Slipbox -> Slipbox
openSource maybeItem source slipbox =
  let
      content = getContent slipbox
      newItem = Item.Source Item.generateId note
      
  in
  case maybeItem of
     Just itemToMatch -> Slipbox { content | items = List.foldr (buildItemList itemToMatch newItem) [] content.items}
     Nothing -> Slipbox { content | items = newItem :: content.items }

newNoteForm : (Maybe Item.Item) -> Slipbox -> Slipbox
newNoteForm maybeItem slipbox =
  let
      content = getContent slipbox      
  in
  case maybeItem of
     Just itemToMatch -> Slipbox { content | items = List.foldr (buildItemList itemToMatch Item.newNoteForm) [] content.items}
     Nothing -> Slipbox { content | items = Item.newNoteForm :: content.items }

newSourceForm : (Maybe Item.Item) -> Slipbox -> Slipbox
newSourceForm maybeItem slipbox =
  let
      content = getContent slipbox      
  in
  case maybeItem of
     Just itemToMatch -> Slipbox { content | items = List.foldr (buildItemList itemToMatch Item.newSourceForm) [] content.items}
     Nothing -> Slipbox { content | items = Item.newSourceForm :: content.items }

dismissItem : Item.Item -> Slipbox -> Slipbox
dismissItem item slipbox =
  let
      content = getContent slipbox
  in
  Slipbox { content | items = List.filter (Item.is item) content.items}

deleteNote : Item.Item -> Slipbox -> Slipbox
deleteNote item slipbox =
  case item of
    Item.ConfirmDeleteNote itemId note ->
      let
          content = getContent slipbox
          links = List.filter (Link.isAssociated note) content.links
          (state, notes) = Simulation.step link (List.filter (Note.is note) content.notes) content.state
          deletedLinkActions = 
            List.foldr (Action.deleteLink content.actions 
            <| List.filter (not <| Link.isAssociated note) content.links
          deletedNoteAction = Action.deleteNote note 
            <| List.concat deletedLinkActions content.actions
      in
      Slipbox 
        { content | notes = notes
        , links = links
        , actions = List.concat deletedNoteAction deletedLinkActions content.actions
        , items = List.map (deleteNoteItemStateChange note) <| List.filter (Item.is item) content.items
        , state = state
        }
     _ -> slipbox

deleteSource : Item.Item -> Slipbox -> Slipbox
deleteSource item slipbox =
  case item of
    Item.ConfirmDeleteSource itemId source ->
      let
          content = getContent slipbox
      in
      Slipbox 
        { content | sources = List.filter (Source.is source) content.sources
        , actions = (Action.deleteSource source content.actions) :: content.actions
        , items = List.filter (Item.is item) content.items
        }
     _ -> slipbox

createNote : Item.Item -> Slipbox -> Slipbox
createNote item slipbox =
  case item of
    Item.NewNote itemId noteContent ->
      let
          content = getContent slipbox
          note = Note.create noteContent -- Is it easy to generate an id for a note. Do I need the context of all other existing notes to do so?
          (state, notes) = Simulation.step content.links (note :: content.notes) content.state
      in
      Slipbox
        { content | notes = notes
        , actions = (Action.createNote note content.actions) :: content.actions
        , items = List.map (\i -> if Item.is item i then Item.note note else i) content.items
        , state = state
        }
    _ -> Slipbox

createSource : Item.Item -> Slipbox -> Slipbox
createSource item slipbox =
  case item of
    Item.NewSource itemId sourceContent ->
      let
          content = getContent slipbox
          source = Source.createSource sourceContent
      in
      Slipbox
        { content | sources = source :: content.sources
        , actions = (Action.createSource source content.actions) :: content.actions
        , items = List.map (\i -> if Item.is item i then Item.source source else i) content.items
        }
    _ -> slipbox

submitNoteEdits : Item.Item -> Slipbox -> Slipbox
submitNoteEdits item slipbox =
  case item of
    Item.EditingNote itemId originalNote editingNote ->
      let
          content = getContent slipbox
          noteUpdateLambda = \n -> if Note.is n editingNote then Note.update n editingNote else n 
      in
      Slipbox 
        { content | notes = List.map noteUpdateLambda content.notes
        , actions = (Action.editNote originalNote editingNote content.actions) :: content.actions
        , items = List.map (\i -> if Item.is item i then Item.note editingNote else i) content.items
        }
    _ -> slipbox
      
-- TODO: Implement Migrate note sources to new source title if this is wanted behavior
submitSourceEdits : Item.Item -> Slipbox -> Slipbox
submitSourceEdits item slipbox =
  case item of
    Item.EditingSource itemId originalSource sourceWithEdits ->
      let
          content = getContent slipbox
          sourceUpdateLambda = \s -> if Source.is s sourceWithEdits then Source.update s sourceWithEdits else s 
      in
      Slipbox 
        { content | sources = List.map sourceUpdateLambda content.sources
        , actions = (Action.editSource originalSource editingsourceWithEdits content.actions) :: content.actions
        , items = List.map (\i -> if Item.is item i then Item.source sourceWithEdits else i) content.items
        }
    _ -> slipbox

createLink : Item.Item -> Slipbox -> Slipbox
createLink item slipbox =
  case item of
    AddingLinkToNoteForm itemId search note maybeNoteToBeLinked ->
      case maybeNoteToBeLinked of
        Just noteToBeLinked ->
          let
              content = getContent slipbox
              link = Link.create note noteToBeLinked
              links = link :: content.links
              (state, notes) = Simulation.step links content.notes content.state
          in
          Slipbox
            { content | notes = notes
            , links = links
            , actions = Action.createLink link |> List.concat content.actions
            , items = List.map (\i -> if Item.is item i then Item.note note else i) content.items
            , state = state
            }
        _ -> slipbox
    _ -> slipbox

deleteLink : Item.Item -> Slipbox -> Slipbox
deleteLink item slipbox =
  case item of
    Item.ConfirmDeleteLink itemId note linkedNote link ->
      let
          content = getContent slipbox
          links = List.filter (Link.is link) content.links
          (state, notes) = Simulation.step links content.notes content.state
      in
      Slipbox 
        { content | notes = notes
        , links = links
        , actions = (Action.deleteLink link content.actions) :: content.actions
        , items = List.map (\i -> if Item.is item i then Item.note note else i) content.items
        }
    _ -> slipbox

updateItem : Item.Item -> Item.UpdateAction -> Slipbox -> Slipbox
updateItem item updateAction slipbox =
  let
      content = getContent slipbox
  in
  case updateAction of
    Item.Content input ->
      case item of
        Item.EditingNote itemId originalNote noteWithEdits ->
          let
              updatedItem = Item.EditingNote itemId originalNote 
                <| Note.updateContent input noteWithEdits
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }

        Item.EditingSource itemId originalSource sourceWithEdits ->
          let
              updatedItem = Item.EditingSource itemId originalSource 
                <| Source.updateContent input sourceWithEdits
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items}
        
        _ -> slipbox
            
    Item.Source input ->
      case item of
        Item.EditingNote itemId originalNote noteWithEdits ->
          let
              updatedItem = Item.EditingNote itemId originalNote 
                <| Note.updateSource input noteWithEdits
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }

        _ -> slipbox


    Item.Variant input ->
      case item of
        Item.EditingNote itemId originalNote noteWithEdits ->
          let
              updatedItem = Item.EditingNote itemId originalNote 
                <| Note.updateVariant input noteWithEdits
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }

        _ -> slipbox


    Item.Title input ->
      case item of
        Item.EditingSource itemId originalSource sourceWithEdits ->
          let
              updatedItem = Item.EditingSource itemId originalSource 
                <| Source.updateTitle input sourceWithEdits
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
        
        _ -> slipbox


    Item.Author input ->
      case item of
        Item.EditingSource itemId originalSource sourceWithEdits ->
          let
              updatedItem = Item.EditingSource itemId originalSource 
                <| Source.updateAuthor input sourceWithEdits
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
              
      _ -> slipbox

    Item.Search input ->
      case item of 
        Item.AddingLinkToNoteForm itemId _ note maybeNote ->
          let
              updatedItem = Item.AddingLinkToNoteForm itemId input note maybeNote
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
            Slipbox { content | items = List.map lambda content.items }

        _ -> slipbox

    Item.AddLink noteToBeAdded ->
      case item of 
        Item.AddingLinkToNoteForm itemId search note _ ->
          let
              updatedItem = Item.AddingLinkToNoteForm itemId search note <| Just noteToBeAdded
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
            Slipbox { content | items = List.map lambda content.items }

        _ -> slipbox

    Item.Edit ->
      case item of
        Item.Note itemId note ->
          let
              updatedItem = Item.EditingNote itemId note note 
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }

        Item.Source itemId source ->
          let
              updatedItem = Item.EditingSource itemId source source
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items}
        
        _ -> slipbox
            
    Item.PromptConfirmDelete ->
        Item.Note itemId note ->
          let
              updatedItem = Item.ConfirmDeleteNote itemId note 
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
          
        Item.Source itemId source ->
          let
              updatedItem = Item.ConfirmDeleteSource itemId source
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items}
        
        _ -> slipbox
    Item.AddLinkForm ->
      case item of 
        Item.Note itemId note ->
          let
              updatedItem = Item.AddingLinkToNoteForm itemId note Nothing
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
        _ -> slipbox
    Item.PromptConfirmRemoveLink linkedNote link ->
      case item of 
        Item.Note itemId note ->
          let
              updatedItem = Item.ConfirmDeleteLink itemId note linkedNote link
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
        _ -> slipbox
    Item.Cancel ->
      case item of
        Item.NewNote itemId note -> 
          let
              updatedItem = Item.ConfirmDiscardNewNoteForm itemId note
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
        Item.ConfirmDiscardNewNoteForm itemId note ->
          let
              updatedItem = Item.NewNote itemId note
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
        Item.EditingNote itemId originalNote noteWithEdits ->
          let
              updatedItem = Item.Note itemId originalNote
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
        Item.ConfirmDeleteNote itemId note ->
          let
              updatedItem = Item.Note itemId note
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
        Item.AddingLinkToNoteForm itemId search note maybeNote ->
          let
              updatedItem = Item.Note itemId note
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
        Item.NewSource itemId source ->
          let
              updatedItem = Item.ConfirmDiscardNewSourceForm itemId source
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
        Item.ConfirmDiscardNewSourceForm itemId source ->
          let
              updatedItem = Item.NewSource itemId source
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
        Item.EditingSource itemId originalSource sourceWithEdits ->
          let
              updatedItem = Item.Source itemId originalSource
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
        Item.ConfirmDeleteSource itemId source ->
          let
              updatedItem = Item.Source itemId source
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
        Item.ConfirmDeleteLink itemId note linkedNote link ->
          let
              updatedItem = Item.Note itemId note
              lambda = conditionalUpdate updatedItem <| Item.is item
          in
          Slipbox { content | items = List.map lambda content.items }
          --\lambda -> Slipbox { content | items = List.map lambda content.items}

-- TODO
-- undo: Int -> Slipbox -> Slipbox
-- TODO
-- redo: Int -> Slipbox -> Slipbox
-- TODO
-- tick: Slipbox -> Slipbox
-- TODO
-- save: Slipbox -> Slipbox
-- TODO
-- getHistory: Slipbox -> (List Action.Summary)
-- TODO
-- simulationIsCompleted: Slipbox -> Bool

-- Helper Functions
buildItemList : Item.Item -> Item.Item -> (Item.Item -> (List Item.Item) -> (List Item.Item))
buildItemList itemToMatch itemToAdd =
  \item list -> if Item.is item itemToMatch then List.concat [item, itemToAdd] list else item :: list

deleteNoteItemStateChange : Note.Note -> Item.Item -> Item.Item
deleteNoteItemStateChange deletedNote item =
  case item of
    Item.AddingLinkToNoteForm itemId search note maybeNoteToBeLinked ->
      case maybeNoteToBeLinked of
        Just noteToBeLinked -> 
          if Note.is noteToBeLinked deletedNote then
            Item.AddingLinkToNoteForm itemId search note Nothing
          else 
            item
        _ -> item   
    _ -> item

conditionalUpdate : a -> (a -> Bool) -> (a -> a)
conditionalUpdate updatedItem itemIdentifier =
  (\i -> if itemIdentifier i then updatedItem else i)