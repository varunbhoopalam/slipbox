module Slipbox exposing 
  ( Slipbox
  , new
  , getNotesAndLinks
  , getNotes
  , getSources
  , getItems
  , getLinkedNotes
  , getNotesThatCanLinkToNote
  , getNotesAssociatedToSource
  , compressNote
  , expandNote
  , AddAction(..)
  , addItem
  , dismissItem
  , updateItem
  , UpdateAction(..)
  , tick
  , simulationIsCompleted
  , decode
  , encode
  )

import Note
import Link
import Item
import Source
import IdGenerator
import Json.Encode
import Json.Decode
import Force

--Types
type Slipbox = Slipbox Content

type alias Content =
  { notes: List Note.Note
  , links: List Link.Link
  , items: List Item.Item
  , sources: List Source.Source
  , state: State Int
  , idGenerator: IdGenerator.IdGenerator
  }

getContent : Slipbox -> Content
getContent slipbox =
  case slipbox of 
    Slipbox content -> content

-- Returns Slipbox

new :  Slipbox
new  =
  let
    ( state, _ ) = simulation [] []
  in
  Slipbox <| Content [] [] [] [] state IdGenerator.init

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

getLinkedNotes : Note.Note -> Slipbox -> ( List ( Note.Note, Link.Link ) )
getLinkedNotes note slipbox =
  let
      content = getContent slipbox
      relevantLinks = List.filter ( isAssociated note ) content.links
  in
  List.filterMap ( convertLinktoLinkNoteTuple note content.notes ) relevantLinks

convertLinktoLinkNoteTuple : Note.Note -> ( List Note.Note ) -> Link.Link -> ( Maybe ( Note.Note, Link.Link ) )
convertLinktoLinkNoteTuple targetNote notes link =
  if Link.isTarget link targetNote then
    case List.head <| List.filter ( Link.isSource link ) notes of
      Just note -> Just ( note, link )
      Nothing -> Nothing
  else if Link.isSource link targetNote then
    case List.head <| List.filter ( Link.isTarget link ) notes of
      Just note -> Just ( note, link )
      Nothing -> Nothing
  else
    Nothing

getNotesThatCanLinkToNote : Note.Note -> Slipbox -> (List Note.Note)
getNotesThatCanLinkToNote note slipbox =
  let
      content = getContent slipbox
  in
  List.filter ( Link.canLink content.links note ) content.notes

getNotesAssociatedToSource : Source.Source -> Slipbox -> (List Note.Note)
getNotesAssociatedToSource source slipbox =
  List.filter ( Note.isAssociated source ) <| .notes <| getContent slipbox

compressNote : Note.Note -> Slipbox -> Slipbox
compressNote note slipbox =
  let
    content = getContent slipbox
    conditionallyCompressNote = \n -> if Note.is note n then Note.compress n else n
    (state, notes) = simulation
      (List.map conditionallyCompressNote content.notes)
      content.links
  in
  Slipbox { content | notes = notes, state = state}

expandNote : Note.Note -> Slipbox -> Slipbox
expandNote note slipbox =
  let
      content = getContent slipbox
      conditionallyExpandNote = \n -> if Note.is note n then Note.expand n else n
      (state, notes) = simulation
        (List.map conditionallyExpandNote content.notes)
        content.links
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
  Slipbox { content | items = List.filter (\i -> not <| Item.is item i) content.items}

type UpdateAction
  = UpdateContent String
  | UpdateSource String
  | UpdateVariant Note.Variant
  | UpdateTitle String
  | UpdateAuthor String
  | UpdateSearch String
  | AddLink Note.Note
  | Edit
  | PromptConfirmDelete
  | AddLinkForm
  | PromptConfirmRemoveLink Note.Note Link.Link
  | Cancel
  | Submit

updateItem : Item.Item -> UpdateAction -> Slipbox -> Slipbox
updateItem item updateAction slipbox =
  let
      content = getContent slipbox
      update = \updatedItem -> Slipbox 
        { content | items = List.map (conditionalUpdate updatedItem (Item.is item)) content.items}
  in
  case updateAction of
    UpdateContent input ->
      case item of
        Item.EditingNote itemId originalNote noteWithEdits ->
          update <| Item.EditingNote itemId originalNote 
            <| Note.updateContent input noteWithEdits
        Item.EditingSource itemId originalSource sourceWithEdits ->
          update <| Item.EditingSource itemId originalSource
            <| Source.updateContent input sourceWithEdits
        Item.NewNote itemId newNoteContent ->
          update <| Item.NewNote itemId { newNoteContent | content = input }
        Item.NewSource itemId newSourceContent ->
          update <| Item.NewSource itemId { newSourceContent | content = input }
        _ -> slipbox

    UpdateSource input ->
      case item of
        Item.EditingNote itemId originalNote noteWithEdits ->
          update
            <| Item.EditingNote itemId originalNote
              <| Note.updateSource input noteWithEdits
        Item.NewNote itemId newNoteContent ->
          update <| Item.NewNote itemId { newNoteContent | source = input }
        _ -> slipbox

    UpdateVariant input ->
      case item of
        Item.EditingNote itemId originalNote noteWithEdits ->
          update <|Item.EditingNote itemId originalNote 
            <| Note.updateVariant input noteWithEdits
        Item.NewNote itemId newNoteContent ->
          update <| Item.NewNote itemId { newNoteContent | variant = input }
        _ -> slipbox

    UpdateTitle input ->
      case item of
        Item.EditingSource itemId originalSource sourceWithEdits ->
          update <| Item.EditingSource itemId originalSource 
            <| Source.updateTitle input sourceWithEdits
        Item.NewSource itemId newSourceContent ->
          update <| Item.NewSource itemId { newSourceContent | title = input }
        _ -> slipbox

    UpdateAuthor input ->
      case item of
        Item.EditingSource itemId originalSource sourceWithEdits ->
          update <| Item.EditingSource itemId originalSource 
            <| Source.updateAuthor input sourceWithEdits
        Item.NewSource itemId newSourceContent ->
          update <| Item.NewSource itemId { newSourceContent | author = input }
        _ -> slipbox

    UpdateSearch input ->
      case item of 
        Item.AddingLinkToNoteForm itemId _ note maybeNote ->
          update <| Item.AddingLinkToNoteForm itemId input note maybeNote
        _ -> slipbox

    AddLink noteToBeAdded ->
      case item of 
        Item.AddingLinkToNoteForm itemId search note _ ->
          update <| Item.AddingLinkToNoteForm itemId search note <| Just noteToBeAdded
        _ -> slipbox

    Edit ->
      case item of
        Item.Note itemId note ->
          update <| Item.EditingNote itemId note note
        Item.Source itemId source ->
          update <| Item.EditingSource itemId source source
        _ -> slipbox
            
    PromptConfirmDelete ->
      case item of
        Item.Note itemId note ->
          update <| Item.ConfirmDeleteNote itemId note
        Item.Source itemId source ->
          update <| Item.ConfirmDeleteSource itemId source
        _ -> slipbox

    AddLinkForm ->
      case item of 
        Item.Note itemId note ->
          update <| Item.AddingLinkToNoteForm itemId "" note Nothing
        _ -> slipbox
    
    PromptConfirmRemoveLink linkedNote link ->
      case item of 
        Item.Note itemId note ->
          update <| Item.ConfirmDeleteLink itemId note linkedNote link
        _ -> slipbox
    
    Cancel ->
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
          update <| Item.NewSource itemId source
        Item.EditingSource itemId originalSource sourceWithEdits ->
          update <| Item.Source itemId originalSource
        Item.ConfirmDeleteSource itemId source ->
          update <| Item.Source itemId source
        Item.ConfirmDeleteLink itemId note linkedNote link ->
          update <| Item.Note itemId note
        _ -> slipbox

    Submit ->
      case item of
        Item.ConfirmDeleteNote _ noteToDelete ->
          let
            links = List.filter (\l -> not <| isAssociated noteToDelete l ) content.links
            (state, notes) = simulation (List.filter (Note.is noteToDelete) content.notes) links
          in
          Slipbox
            { content | notes = notes
            , links = links
            , items = List.map (deleteNoteItemStateChange noteToDelete) <| List.filter (Item.is item) content.items
            , state = state
            }

        Item.ConfirmDeleteSource _ source ->
          Slipbox
            { content | sources = List.filter (Source.is source) content.sources
            , items = List.filter (Item.is item) content.items
            }

        Item.NewNote itemId noteContent ->
          let
              (note, idGenerator) = Note.create content.idGenerator
                <| { content = noteContent.content, source = noteContent.source, variant = noteContent.variant }
              (state, notes) = simulation (note :: content.notes) content.links
          in
          Slipbox
            { content | notes = notes
            , items = List.map (\i -> if Item.is item i then Item.Note itemId note else i) content.items
            , state = state
            , idGenerator = idGenerator
            }

        Item.NewSource itemId sourceContent ->
          let
              ( source, generator ) = Source.createSource content.idGenerator sourceContent
          in
          Slipbox
            { content | sources = source :: content.sources
            , items = List.map (\i -> if Item.is item i then Item.Source itemId source else i) content.items
            , idGenerator = generator
            }

        Item.EditingNote itemId originalNote editingNote ->
          let
              noteUpdateLambda = \n -> if Note.is n editingNote then updateNoteEdits n editingNote else n
          in
          Slipbox
            { content | notes = List.map noteUpdateLambda content.notes
            , items = List.map (\i -> if Item.is item i then Item.Note itemId editingNote else i) content.items
            }

        -- TODO: Implement Migrate note sources to new source title if this is wanted behavior
        Item.EditingSource itemId _ sourceWithEdits ->
          let
              sourceUpdateLambda = \s -> if Source.is s sourceWithEdits then updateSourceEdits s sourceWithEdits else s
          in
          Slipbox
            { content | sources = List.map sourceUpdateLambda content.sources
            , items = List.map (\i -> if Item.is item i then Item.Source itemId sourceWithEdits else i) content.items
            }

        Item.AddingLinkToNoteForm itemId _ note maybeNoteToBeLinked ->
          case maybeNoteToBeLinked of
            Just noteToBeLinked ->
              let
                  (link, idGenerator) = Link.create content.idGenerator note noteToBeLinked
                  links = link :: content.links
                  (state, notes) = simulation content.notes links
              in
              Slipbox
                { content | notes = notes
                , links = links
                , items = List.map (\i -> if Item.is item i then Item.Note itemId note else i) content.items
                , state = state
                , idGenerator = idGenerator
                }
            _ -> slipbox

        Item.ConfirmDeleteLink itemId note linkedNote link ->
          let
             links = List.filter (Link.is link) content.links
             (state, notes) = simulation content.notes links
          in
          Slipbox
            { content | notes = notes
            , links = links
            , items = List.map (\i -> if Item.is item i then Item.Note itemId note else i) content.items
            , state = state
            }
        _ -> slipbox

tick : Slipbox -> Slipbox
tick slipbox =
  let
    content = getContent slipbox
    ( state, notes ) = tick_ content.notes content.state
  in
  Slipbox { content | notes = notes, state = state }

simulationIsCompleted : Slipbox -> Bool
simulationIsCompleted slipbox =
  let
    content = getContent slipbox
    thereAreNoNotes = ( List.length <| content.notes ) == 0
  in
  if thereAreNoNotes then
    True
  else
    extract content.state |> Force.isCompleted

decode : Json.Decode.Decoder Slipbox
decode =
  Json.Decode.map4
    slipbox_
    ( Json.Decode.field "notes" (Json.Decode.list Note.decode) )
    ( Json.Decode.field "links" (Json.Decode.list Link.decode) )
    ( Json.Decode.field "sources" (Json.Decode.list Source.decode) )
    ( Json.Decode.field "idGenerator" IdGenerator.decode )

encode : Slipbox -> String
encode slipbox =
  let
    info = getContent slipbox
  in
  Json.Encode.encode 0
    <| Json.Encode.object
      [ ( "notes", Json.Encode.list Note.encode info.notes )
      , ( "links", Json.Encode.list Link.encode info.links )
      , ( "sources", Json.Encode.list Source.encode info.sources )
      , ( "idGenerator", IdGenerator.encode info.idGenerator )
      ]

-- Helper Functions
slipbox_: ( List Note.Note ) -> ( List Link.Link ) -> ( List Source.Source ) -> IdGenerator.IdGenerator -> Slipbox
slipbox_ notesBeforeSimulation links sources idGenerator =
  let
    ( state, notes ) = simulation notesBeforeSimulation links
  in
  Slipbox <| Content notes links [] sources state idGenerator

buildItemList : Item.Item -> Item.Item -> (Item.Item -> (List Item.Item) -> (List Item.Item))
buildItemList itemToMatch itemToAdd =
  \item list -> if Item.is item itemToMatch then item :: (itemToAdd :: list) else item :: list

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

-- SIMULATION

type alias SimulationRecord =
  { id: Int
  , x: Float
  , y: Float
  , vx: Float
  , vy: Float
  }

type State comparable = State (Force.State comparable)

-- EXPOSED

initNote : Int -> SimulationRecord
initNote id =
  let
    entity = Force.entity id 1
  in
    SimulationRecord id entity.x entity.y entity.vx entity.vy

simulation : ( List Note.Note ) -> ( List Link.Link ) -> ( State Int, (List Note.Note) )
simulation notes links =
  let
    entities = List.map toEntity notes
    state = stateBuilder entities links
  in
  Force.tick state entities |> toStateRecordTuple

tick_ : ( List Note.Note ) -> State Int -> ( State Int, (List Note.Note) )
tick_ notes state =
  let
    entities = List.map toEntity notes
  in
   Force.tick (extract state) entities |> toStateRecordTuple


-- HELPERS

stateBuilder : ( List (Force.Entity Int { note : Note.Note })) -> ( List Link.Link ) -> Force.State Int
stateBuilder entities links =
  Force.simulation
        [ Force.manyBodyStrength -15 (List.map (\n -> n.id) entities)
        , Force.links <| List.map (\link -> ( Link.getSourceId link, Link.getTargetId link)) links
        , Force.center 0 0
        ]

toEntity : Note.Note -> (Force.Entity Int { note : Note.Note })
toEntity note =
  { id = Note.getId note, x = Note.getX note, y = Note.getY note, vx = Note.getVx note, vy = Note.getVy note, note = note }

updateNote: (Force.Entity Int { note : Note.Note }) -> Note.Note
updateNote entity =
  Note.updateX entity.x <| Note.updateY entity.y <| Note.updateVx entity.vx <| Note.updateVy entity.vy entity.note

extract : State Int -> Force.State Int
extract state =
  case state of
     State simState -> simState

toStateRecordTuple : ( Force.State Int, List ( Force.Entity Int { note : Note.Note } ) ) -> ( State Int, (List Note.Note) )
toStateRecordTuple ( simState, records ) =
  ( State simState
  , List.map updateNote records
  )