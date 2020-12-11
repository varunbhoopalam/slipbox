module Slipbox exposing 
  ( Slipbox, initialize
  , getNotesAndLinks
  , getNotes, getSources
  , getItems, getLinkedNotes
  , getNotesThatCanLinkToNote
  , getNotesAssociatedToSource
  , compressNote, expandNote
  , AddAction(..)
  , addItem
  , dismissItem, deleteNote
  , deleteSource, createNote
  , createSource
  , submitNoteEdits
  , submitSourceEdits
  , createLink, deleteLink
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
import IdGenerator
import IdGenerator exposing (IdGenerator)

--Types
type Slipbox = Slipbox Content

type alias Content =
  { notes: List Note.Note
  , links: List Link.Link
  , actions: List Action.Action
  , items: List Item.Item
  , sources: List Source.Source
  , state: Simulation.State Int
  , idGenerator: IdGenerator.IdGenerator
  }

getContent : Slipbox -> Content
getContent slipbox =
  case slipbox of 
    Slipbox content -> content

-- Returns Slipbox

-- TODO
-- initialize : (List Note.NoteRecord) -> (List LinkRecord) -> ActionResponse -> Slipbox
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
        filteredNotes = List.filter ( Note.contains search ) content.notes
        relevantLinks = List.filter ( linkIsRelevant filteredNotes ) content.links
      in
      ( filteredNotes,  relevantLinks )
    Nothing -> ( content.notes, content.links )

getNotes : (Maybe String) -> Slipbox -> (List Note.Note)
getNotes maybeSearch slipbox =
  let
    content = getContent slipbox
  in
  case maybeSearch of
    Just search -> List.filter (Note.contains search) content.notes
    Nothing -> content.notes

getSources : (Maybe String) -> Slipbox -> (List Source.Source)
getSources maybeSearch slipbox =
  let
    content = getContent slipbox
  in
  case maybeSearch of
    Just search -> List.filter (Source.contains search) content.sources
    Nothing -> content.sources

getItems : Slipbox -> (List Item.Item)
getItems slipbox =
  .items <| getContent slipbox

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
  List.filter ( Note.isAssociated source ) <| .notes <| getContent slipbox

compressNote : Note.Note -> Slipbox -> Slipbox
compressNote note slipbox =
  let
    content = getContent slipbox
    conditionallyCompressNote = \n -> if Note.is note n then Note.compress n else n
    (state, notes) = Simulation.step
      content.links
      (List.map conditionallyCompressNote content.notes)
      content.state
  in
  Slipbox { content | notes = notes, state = state}

expandNote : Note.Note -> Slipbox -> Slipbox
expandNote note slipbox =
  let
      content = getContent slipbox
      conditionallyExpandNote = \n -> if Note.is note n then Note.expand n else n
      (state, notes) = Simulation.step 
        content.links 
        (List.map conditionallyExpandNote content.notes) 
        content.state
  in
  Slipbox { content | notes = notes, state = state}

type AddAction
  = OpenNote Note.Note
  | OpenSource Source.Source
  | NewNote
  | NewSource

addItem : ( Maybe Item.Item ) -> AddAction -> Slipbox -> Slipbox
addItem maybeItem addAction slipbox =
  let
    content = getContent slipbox

    itemExistsLambda = \existingItem ->
      let
        updatedContent = getContent <| dismissItem existingItem slipbox
      in
      case maybeItem of
        Just itemToMatch -> Slipbox { updatedContent | items = List.foldr (buildItemList itemToMatch existingItem) [] updatedContent.items }
        Nothing -> Slipbox { updatedContent | items = existingItem :: updatedContent.items }

    itemDoesNotExistLambda = \(newItem,idGenerator) ->
      case maybeItem of
       Just itemToMatch -> Slipbox { content | items = List.foldr (buildItemList itemToMatch newItem) [] content.items
        , idGenerator = idGenerator
        }
       Nothing -> Slipbox { content | items = newItem :: content.items, idGenerator = idGenerator }
  in
  case addAction of
    OpenNote note ->
      case tryFindItemFromComponent content.items <| hasNote note of
        Just existingItem -> itemExistsLambda existingItem
        Nothing -> itemDoesNotExistLambda <| Item.openNote content.idGenerator note

    OpenSource source ->
      case tryFindItemFromComponent content.items <| hasSource source of
        Just existingItem -> itemExistsLambda existingItem
        Nothing -> itemDoesNotExistLambda <| Item.openSource content.idGenerator source

    NewNote -> itemDoesNotExistLambda <| Item.newNote content.idGenerator

    NewSource -> itemDoesNotExistLambda <| Item.newSource content.idGenerator

dismissItem : Item.Item -> Slipbox -> Slipbox
dismissItem item slipbox =
  let
      content = getContent slipbox
  in
  Slipbox { content | items = List.filter (Item.is item) content.items}

deleteNote : Item.Item -> Slipbox -> Slipbox
deleteNote item slipbox =
  case item of
    Item.ConfirmDeleteNote _ noteToDelete ->
      let
          content = getContent slipbox
          linksToDelete = List.filter ( isAssociated noteToDelete ) content.links
          linksToKeep = List.filter (\l -> not <| isAssociated noteToDelete l ) content.links
          (state, notes) = Simulation.step linksToKeep (List.filter (Note.is noteToDelete) content.notes) content.state
          deletedLinkActionsWithActionList =
            List.foldr
              (\linkToDelete actionList -> (Action.deleteLink actionList linkToDelete) :: actionList)
              content.actions
              linksToDelete
          deletedNoteAction = Action.deleteNote deletedLinkActionsWithActionList noteToDelete

      in
      Slipbox 
        { content | notes = notes
        , links = linksToKeep
        , actions = deletedNoteAction :: deletedLinkActionsWithActionList
        , items = List.map (deleteNoteItemStateChange noteToDelete) <| List.filter (Item.is item) content.items
        , state = state
        }
    _ -> slipbox

deleteSource : Item.Item -> Slipbox -> Slipbox
deleteSource item slipbox =
  case item of
    Item.ConfirmDeleteSource _ source ->
      let
          content = getContent slipbox
      in
      Slipbox 
        { content | sources = List.filter (Source.is source) content.sources
        , actions = (Action.deleteSource content.actions source) :: content.actions
        , items = List.filter (Item.is item) content.items
        }
    _ -> slipbox

createNote : Item.Item -> Slipbox -> Slipbox
createNote item slipbox =
  case item of
    Item.NewNote itemId noteContent ->
      let
          content = getContent slipbox
          (note, idGenerator) = Note.create content.idGenerator {}
          (state, notes) = Simulation.step content.links (note :: content.notes) content.state
      in
      Slipbox
        { content | notes = notes
        , actions = (Action.createNote note content.actions) :: content.actions
        , items = List.map (\i -> if Item.is item i then Item.Note itemId note else i) content.items
        , state = state
        , idGenerator = idGenerator
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
        , items = List.map (\i -> if Item.is item i then Item.Source itemId source else i) content.items
        }
    _ -> slipbox

submitNoteEdits : Item.Item -> Slipbox -> Slipbox
submitNoteEdits item slipbox =
  case item of
    Item.EditingNote itemId originalNote editingNote ->
      let
          content = getContent slipbox
          noteUpdateLambda = \n -> if Note.is n editingNote then updateNoteEdits n editingNote else n 
      in
      Slipbox 
        { content | notes = List.map noteUpdateLambda content.notes
        , actions = (Action.editNote originalNote editingNote content.actions) :: content.actions
        , items = List.map (\i -> if Item.is item i then Item.Note itemId editingNote else i) content.items
        }
    _ -> slipbox
      
-- TODO: Implement Migrate note sources to new source title if this is wanted behavior
submitSourceEdits : Item.Item -> Slipbox -> Slipbox
submitSourceEdits item slipbox =
  case item of
    Item.EditingSource itemId originalSource sourceWithEdits ->
      let
          content = getContent slipbox
          sourceUpdateLambda = \s -> if Source.is s sourceWithEdits then updateSourceEdits s sourceWithEdits else s 
      in
      Slipbox 
        { content | sources = List.map sourceUpdateLambda content.sources
        , actions = (Action.editSource originalSource editingsourceWithEdits content.actions) :: content.actions
        , items = List.map (\i -> if Item.is item i then Item.Source itemId sourceWithEdits else i) content.items
        }
    _ -> slipbox

createLink : Item.Item -> Slipbox -> Slipbox
createLink item slipbox =
  case item of
    Item.AddingLinkToNoteForm itemId search note maybeNoteToBeLinked ->
      case maybeNoteToBeLinked of
        Just noteToBeLinked ->
          let
              content = getContent slipbox
              (idGenerator, link) = Link.create slipbox.idGenerator note noteToBeLinked
              links = link :: content.links
              (state, notes) = Simulation.step links content.notes content.state
          in
          Slipbox
            { content | notes = notes
            , links = links
            , actions = Action.createLink link |> List.concat content.actions
            , items = List.map (\i -> if Item.is item i then Item.Note itemId note else i) content.items
            , state = state
            , idGenerator = idGenerator
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
        , items = List.map (\i -> if Item.is item i then Item.Note itemId note else i) content.items
        }
    _ -> slipbox

updateItem : Item.Item -> Item.UpdateAction -> Slipbox -> Slipbox
updateItem item updateAction slipbox =
  let
      content = getContent slipbox
      update = \updatedItem -> Slipbox 
        { content | items = List.map (conditionalUpdate updatedItem (Item.is item)) content.items}
  in
  case updateAction of
    Item.Content input ->
      case item of
        Item.EditingNote itemId originalNote noteWithEdits ->
          update <| Item.EditingNote itemId originalNote 
            <| Note.updateContent input noteWithEdits
        Item.EditingSource itemId originalSource sourceWithEdits ->
          update <| Item.EditingSource itemId originalSource
            <| Source.updateContent input sourceWithEdits
        _ -> slipbox

    Item.Source input ->
      case item of
        Item.EditingNote itemId originalNote noteWithEdits ->
          update Item.EditingNote itemId originalNote 
            <| Note.updateSource input noteWithEdits
        _ -> slipbox

    Item.Variant input ->
      case item of
        Item.EditingNote itemId originalNote noteWithEdits ->
          update <|Item.EditingNote itemId originalNote 
            <| Note.updateVariant input noteWithEdits
        _ -> slipbox

    Item.Title input ->
      case item of
        Item.EditingSource itemId originalSource sourceWithEdits ->
          update <| Item.EditingSource itemId originalSource 
            <| Source.updateTitle input sourceWithEdits
        _ -> slipbox


    Item.Author input ->
      case item of
        Item.EditingSource itemId originalSource sourceWithEdits ->
          update <| Item.EditingSource itemId originalSource 
            <| Source.updateAuthor input sourceWithEdits
      _ -> slipbox

    Item.Search input ->
      case item of 
        Item.AddingLinkToNoteForm itemId _ note maybeNote ->
          update <| Item.AddingLinkToNoteForm itemId input note maybeNote
        _ -> slipbox

    Item.AddLink noteToBeAdded ->
      case item of 
        Item.AddingLinkToNoteForm itemId search note _ ->
          update <| Item.AddingLinkToNoteForm itemId search note <| Just noteToBeAdded
        _ -> slipbox

    Item.Edit ->
      case item of
        Item.Note itemId note ->
          update <| Item.EditingNote itemId note note
        Item.Source itemId source ->
          update <| Item.EditingSource itemId source source
        _ -> slipbox
            
    Item.PromptConfirmDelete ->
        Item.Note itemId note ->
          update <| Item.ConfirmDeleteNote itemId note
        Item.Source itemId source ->
          update <| Item.ConfirmDeleteSource itemId source
        _ -> slipbox

    Item.AddLinkForm ->
      case item of 
        Item.Note itemId note ->
          update <| Item.AddingLinkToNoteForm itemId note Nothing
        _ -> slipbox
    
    Item.PromptConfirmRemoveLink linkedNote link ->
      case item of 
        Item.Note itemId note ->
          update <| Item.ConfirmDeleteLink itemId note linkedNote link
        _ -> slipbox
    
    Item.Cancel ->
      case item of
        Item.NewNote itemId note ->
          update <| Item.ConfirmDiscardNewNoteForm itemId note 
        Item.ConfirmDiscardNewNoteForm itemId note ->
          update <| Item.NewNote itemId note
        Item.EditingNote itemId originalNote noteWithEdits ->
          update <| Item.Note itemId originalNote
        Item.ConfirmDeleteNote itemId note ->
          update <| Item.Note itemId note
        Item.AddingLinkToNoteForm itemId search note maybeNote ->
          update <| Item.Note itemId note
        Item.NewSource itemId source ->
          update <| Item.ConfirmDiscardNewSourceForm itemId source
        Item.ConfirmDiscardNewSourceForm itemId source ->
          updated <| Item.NewSource itemId source
        Item.EditingSource itemId originalSource sourceWithEdits ->
          updated <| Item.Source itemId originalSource
        Item.ConfirmDeleteSource itemId source ->
          updated <| Item.Source itemId source
        Item.ConfirmDeleteLink itemId note linkedNote link ->
          updated <| Item.Note itemId note
        _ -> slipbox

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

updateNoteEdits : Note.Note -> Note.Note -> Note.Note
updateNoteEdits originalNote noteWithEdits =  
  let
      updatedContent = Note.getContent noteWithEdits
      updatedSource = Note.getSource noteWithEdits
      updatedVariant = Note.getVariant noteWithEdits
  in
  Note.updateContent updatedContent
    <| Note.updateSource updatedSource
      <| Note.updateVariant updatedVariant originalNote

updateSourceEdits : Source.Source -> Source.Source -> Source.Source
updateSourceEdits originalSource sourceWithEdits =  
  let
      updatedTitle = Source.getTitle sourceWithEdits
      updatedAuthor = Source.getAuthor sourceWithEdits
      updatedContent = Source.getContent sourceWithEdits
  in
  Source.updateTitle updatedTitle
    <| Source.updateAuthor updatedAuthor
      <| Source.updateContent updatedContent originalSource

linkIsRelevant : ( List Note.Note ) -> Link.Link -> Bool
linkIsRelevant notes link =
  let
    sourceInNotes = getSource link notes /= Nothing
    targetInNotes = getTarget link notes /= Nothing
  in
  sourceInNotes && targetInNotes

tryFindItemFromComponent : ( List Item.Item ) -> ( Item.Item -> (Bool) ) -> ( Maybe Item.Item )
tryFindItemFromComponent items filterCondition =
  List.head <| List.filter filterCondition items

hasNote : Note.Note -> Item.Item -> Bool
hasNote note item =
  case Item.getNote item of
    Just noteOnItem -> Note.is note noteOnItem
    Nothing -> False

hasSource : Source.Source -> Item.Item -> Bool
hasSource source item =
  case Item.getSource item of
    Just sourceOnItem -> Source.is source sourceOnItem
    Nothing -> False

isAssociated : Note.Note -> Link.Link -> Bool
isAssociated note link =
  Link.isSource link note || Link.isTarget link note

getSource : Link.Link -> (List Note.Note) -> (Maybe Note.Note)
getSource link notes =
  List.head <| List.filter (Link.isSource link) notes

getTarget : Link.Link -> (List Note.Note) -> (Maybe Note.Note)
getTarget link notes =
  List.head <| List.filter (Link.isTarget link) notes