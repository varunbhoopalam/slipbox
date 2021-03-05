module Slipbox exposing 
  ( Slipbox
  , new
  , getNotes
  , getDiscussions
  , getSources
  , getItems
  , getLinkedNotes
  , getNotesThatCanLinkToNote
  , getNotesAssociatedToSource
  , AddAction(..)
  , addItem
  , dismissItem
  , updateItem
  , UpdateAction(..)
  , decode
  , encode
  , unsavedChanges
  , saveChanges
  , getAllNotesAndLinksInQuestionTree
  , addNote
  , addDiscussion
  , addSource
  , addLink
  )

import Note
import Link
import Item
import Source
import IdGenerator
import Json.Encode
import Json.Decode

--Types
type Slipbox = Slipbox Content

type alias Content =
  { notes: List Note.Note
  , links: List Link.Link
  , items: List Item.Item
  , sources: List Source.Source
  , idGenerator: IdGenerator.IdGenerator
  , unsavedChanges: Bool
  }

getContent : Slipbox -> Content
getContent slipbox =
  case slipbox of 
    Slipbox content -> content

-- Returns Slipbox

new :  Slipbox
new  = Slipbox <| Content [] [] [] [] IdGenerator.init False

isNote : Note.Note -> Bool
isNote note =
  Note.getVariant note == Note.Regular

isQuestion : Note.Note -> Bool
isQuestion note =
  Note.getVariant note == Note.Discussion

getNotes : (Maybe String) -> Slipbox -> (List Note.Note)
getNotes maybeSearch slipbox =
  let
    content = getContent slipbox
  in
  case maybeSearch of
    Just search -> List.filter isNote <| List.filter (Note.contains search) content.notes
    Nothing -> List.filter isNote content.notes

getDiscussions : (Maybe String) -> Slipbox -> (List Note.Note)
getDiscussions maybeSearch slipbox =
  let
    content = getContent slipbox
  in
  case maybeSearch of
    Just search -> List.filter isQuestion <| List.filter (Note.contains search) content.notes
    Nothing -> List.filter isQuestion content.notes


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
  List.filter ( Link.canLink content.links note )
    <| List.filter (\n -> not <|  Note.is note n ) content.notes

getNotesAssociatedToSource : Source.Source -> Slipbox -> (List Note.Note)
getNotesAssociatedToSource source slipbox =
  List.filter ( Note.isAssociated source ) <| .notes <| getContent slipbox

type AddAction
  = OpenNote Note.Note
  | OpenSource Source.Source
  | NewNote
  | NewSource
  | NewDiscussion

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

    NewDiscussion -> itemDoesNotExistLambda <| Item.newQuestion content.idGenerator

dismissItem : Item.Item -> Slipbox -> Slipbox
dismissItem item slipbox =
  let
      content = getContent slipbox
  in
  Slipbox { content | items = removeItemFromList item content.items }

removeItemFromList : Item.Item -> ( List (Item.Item ) ) -> ( List ( Item.Item ) )
removeItemFromList item items =
  List.filter ( isNotLambda Item.is item ) items

type UpdateAction
  = UpdateContent String
  | UpdateSource String
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
  | OpenTray
  | CloseTray

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
        Item.EditingNote itemId tray originalNote noteWithEdits ->
          update <| Item.EditingNote itemId tray originalNote
            <| Note.updateContent input noteWithEdits
        Item.EditingSource itemId tray originalSource sourceWithEdits ->
          update <| Item.EditingSource itemId tray originalSource
            <| Source.updateContent input sourceWithEdits
        Item.NewNote itemId tray newNoteContent ->
          update <| Item.NewNote itemId tray { newNoteContent | content = input }
        Item.NewSource itemId tray newSourceContent ->
          update <| Item.NewSource itemId tray { newSourceContent | content = input }
        Item.NewDiscussion itemId tray _ ->
          update <| Item.NewDiscussion itemId tray input
        _ -> slipbox

    UpdateSource input ->
      case item of
        Item.EditingNote itemId tray originalNote noteWithEdits ->
          update
            <| Item.EditingNote itemId tray originalNote
              <| Note.updateSource input noteWithEdits
        Item.NewNote itemId tray newNoteContent ->
          update <| Item.NewNote itemId tray { newNoteContent | source = input }
        _ -> slipbox

    UpdateTitle input ->
      case item of
        Item.EditingSource itemId tray originalSource sourceWithEdits ->
          update <| Item.EditingSource itemId tray originalSource
            <| Source.updateTitle input sourceWithEdits
        Item.NewSource itemId tray newSourceContent ->
          update <| Item.NewSource itemId tray { newSourceContent | title = input }
        _ -> slipbox

    UpdateAuthor input ->
      case item of
        Item.EditingSource itemId tray originalSource sourceWithEdits ->
          update <| Item.EditingSource itemId tray originalSource
            <| Source.updateAuthor input sourceWithEdits
        Item.NewSource itemId tray newSourceContent ->
          update <| Item.NewSource itemId tray { newSourceContent | author = input }
        _ -> slipbox

    UpdateSearch input ->
      case item of 
        Item.AddingLinkToNoteForm itemId tray _ note maybeNote ->
          update <| Item.AddingLinkToNoteForm itemId tray input note maybeNote
        _ -> slipbox

    AddLink noteToBeAdded ->
      case item of 
        Item.AddingLinkToNoteForm itemId tray search note _ ->
          update <| Item.AddingLinkToNoteForm itemId tray search note <| Just noteToBeAdded
        _ -> slipbox

    Edit ->
      case item of
        Item.Note itemId tray note ->
          update <| Item.EditingNote itemId tray note note
        Item.Source itemId tray source ->
          update <| Item.EditingSource itemId tray source source
        _ -> slipbox
            
    PromptConfirmDelete ->
      case item of
        Item.Note itemId tray note ->
          update <| Item.ConfirmDeleteNote itemId tray note
        Item.Source itemId tray source ->
          update <| Item.ConfirmDeleteSource itemId tray source
        _ -> slipbox

    AddLinkForm ->
      case item of 
        Item.Note itemId tray note ->
          update <| Item.AddingLinkToNoteForm itemId tray "" note Nothing
        _ -> slipbox
    
    PromptConfirmRemoveLink linkedNote link ->
      case item of 
        Item.Note itemId tray note ->
          update <| Item.ConfirmDeleteLink itemId tray note linkedNote link
        _ -> slipbox
    
    Cancel ->
      let
        conditionallyDismissOrTransformLambda =
          \transformation ->
            if Item.isEmpty item then
              dismissItem item slipbox
            else
              update transformation
      in
      case item of
        Item.NewNote itemId tray note ->
          conditionallyDismissOrTransformLambda <| Item.ConfirmDiscardNewNoteForm itemId tray note
        Item.ConfirmDiscardNewNoteForm itemId tray note ->
          update <| Item.NewNote itemId tray note
        Item.EditingNote itemId tray originalNote _ ->
          update <| Item.Note itemId tray originalNote
        Item.ConfirmDeleteNote itemId tray note ->
          update <| Item.Note itemId tray note
        Item.AddingLinkToNoteForm itemId tray _ note _ ->
          update <| Item.Note itemId tray note
        Item.NewSource itemId tray source ->
          conditionallyDismissOrTransformLambda <| Item.ConfirmDiscardNewSourceForm itemId tray source
        Item.ConfirmDiscardNewSourceForm itemId tray source ->
          update <| Item.NewSource itemId tray source
        Item.EditingSource itemId tray originalSource _ ->
          update <| Item.Source itemId tray originalSource
        Item.ConfirmDeleteSource itemId tray source ->
          update <| Item.Source itemId tray source
        Item.ConfirmDeleteLink itemId tray note _ _ ->
          update <| Item.Note itemId tray note
        Item.NewDiscussion itemId tray question ->
          conditionallyDismissOrTransformLambda <| Item.ConfirmDiscardNewDiscussion itemId tray question
        Item.ConfirmDiscardNewDiscussion itemId tray question ->
          update <| Item.ConfirmDiscardNewDiscussion itemId tray question
        _ -> slipbox

    Submit ->
      case item of
        Item.ConfirmDeleteNote _ _ noteToDelete ->
          let
            links = List.filter (\l -> not <| isAssociated noteToDelete l ) content.links
            notes = List.filter (isNotLambda Note.is noteToDelete) content.notes
          in
          Slipbox
            { content | notes = notes
            , links = links
            , items = List.map (deleteNoteItemStateChange noteToDelete) <| removeItemFromList item content.items
            , unsavedChanges = True
            }

        Item.ConfirmDeleteSource _ _ source ->
          Slipbox
            { content | sources = List.filter (isNotLambda Source.is source) content.sources
            , items = removeItemFromList item content.items
            , unsavedChanges = True
            }

        Item.NewNote itemId tray noteContent ->
          let
              source =
                if String.isEmpty noteContent.source then
                  "n/a"
                else
                  noteContent.source
              (note, idGenerator) = Note.create content.idGenerator
                <| { content = noteContent.content, source = source, variant = Note.Regular }
          in
          Slipbox
            { content | notes = (note :: content.notes)
            , items = List.map (\i -> if Item.is item i then Item.Note itemId tray note else i) content.items
            , idGenerator = idGenerator
            , unsavedChanges = True
            }

        Item.NewSource itemId tray sourceContent ->
          let
              ( source, generator ) = Source.createSource content.idGenerator sourceContent
          in
          Slipbox
            { content | sources = source :: content.sources
            , items = List.map (\i -> if Item.is item i then Item.Source itemId tray source else i) content.items
            , idGenerator = generator
            , unsavedChanges = True
            }

        Item.EditingNote itemId tray _ editingNote ->
          let
              conditionallyUpdateTargetNoteWithEdits = updateLambda Note.is ( updateNoteEdits editingNote ) editingNote
          in
          Slipbox
            { content | notes = List.map conditionallyUpdateTargetNoteWithEdits content.notes
            , items = List.map (\i -> if Item.is item i then Item.Note itemId tray editingNote else i) content.items
            , unsavedChanges = True
            }

        Item.EditingSource itemId tray _ sourceWithEdits ->
          let
              conditionallyUpdateTargetSourceWithEdits = updateLambda Source.is ( updateSourceEdits sourceWithEdits ) sourceWithEdits
          in
          Slipbox
            { content | sources = List.map conditionallyUpdateTargetSourceWithEdits content.sources
            , items = List.map (\i -> if Item.is item i then Item.Source itemId tray sourceWithEdits else i) content.items
            , unsavedChanges = True
            }

        Item.AddingLinkToNoteForm itemId tray _ note maybeNoteToBeLinked ->
          case maybeNoteToBeLinked of
            Just noteToBeLinked ->
              let
                  (link, idGenerator) = Link.create content.idGenerator note noteToBeLinked
                  links = link :: content.links
              in
              Slipbox
                { content | links = links
                , items = List.map (\i -> if Item.is item i then Item.Note itemId tray note else i) content.items
                , idGenerator = idGenerator
                , unsavedChanges = True
                }
            _ -> slipbox

        Item.ConfirmDeleteLink itemId tray note _ link ->
          let
            trueIfNotTargetLink = isNotLambda Link.is link
            links = List.filter trueIfNotTargetLink content.links
          in
          Slipbox
            { content | links = links
            , items = List.map (\i -> if Item.is item i then Item.Note itemId tray note else i) content.items
            , unsavedChanges = True
            }

        Item.ConfirmDiscardNewNoteForm _ _ _ ->
          Slipbox { content | items = removeItemFromList item content.items }

        Item.ConfirmDiscardNewSourceForm _ _ _ ->
          Slipbox { content | items = removeItemFromList item content.items }

        Item.NewDiscussion itemId tray question ->
          let
              (note, idGenerator) = Note.create content.idGenerator
                <| { content = question, source = "n/a", variant = Note.Discussion }
          in
          Slipbox
            { content | notes = (note :: content.notes)
            , items = List.map (\i -> if Item.is item i then Item.Note itemId tray note else i) content.items
            , idGenerator = idGenerator
            , unsavedChanges = True
            }

        Item.ConfirmDiscardNewDiscussion _ _ _ ->
          Slipbox { content | items = removeItemFromList item content.items }

        _ -> slipbox

    OpenTray ->
      Slipbox { content | items = List.map ( updateLambda Item.is Item.openTray item ) content.items }

    CloseTray ->
      Slipbox { content | items = List.map ( updateLambda Item.is Item.closeTray item ) content.items }


updateLambda : ( a -> a -> Bool ) -> ( a -> a ) -> a -> ( a -> a )
updateLambda is update target =
  \maybeTarget ->
    if is target maybeTarget then
      update maybeTarget
    else
      maybeTarget

isNotLambda : ( a -> a -> Bool) -> a -> ( a -> Bool )
isNotLambda is target =
  \maybeTarget ->
    if is target maybeTarget then
      False
    else
      True

decode : Json.Decode.Decoder Slipbox
decode =
  let
    slipbox notes links sources idGenerator =
      Slipbox <| Content notes links [] sources idGenerator False
  in
  Json.Decode.map4
    slipbox
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

unsavedChanges : Slipbox -> Bool
unsavedChanges slipbox =
  case slipbox of
    Slipbox content -> content.unsavedChanges

saveChanges : Slipbox -> Slipbox
saveChanges slipbox =
  case slipbox of
    Slipbox content -> Slipbox { content | unsavedChanges = False }

{-| Returns all notes in discussion tree with a few conditions around other discussion entry points
(Discussion Entry point is a note linked to a discussion)
1. If a note is ca different discussion entry point, the discussion is swapped with the entry point.
Ignore any other links from that entry point or on the discussion.
2. If a note is not a different discussion entry point, normal tree behavior.
-}
getDiscussionTreeWithCollapsedDiscussions : Note.Note -> Slipbox -> ( List Note.Note, List Link.Link )
getDiscussionTreeWithCollapsedDiscussions discussion slipbox =
  let
    content = getContent slipbox
    recurs rootNote links =
      List.map
        ( \( linkedNote, link ) ->
          case noteIsEntryPointForDifferentDiscussion linkedNote discussion slipbox of
            Just differentDiscussion ->
              [
                ( differentDiscussion
                , Tuple.first <| Link.create content.idGenerator rootNote differentDiscussion
                )
              ]
            Nothing ->
              ( (linkedNote,link) ::
                recurs
                  linkedNote
                  content.notes
                  ( List.filter (\l -> not <| Link.is link l ) links )
              )
        )
        ( getLinkedNotes_ rootNote content.notes links )
        |> flatten2D
    allTuples = recurs discussion content.links
  in
  ( List.map Tuple.first allTuples
  , List.map Tuple.second allTuples
  )


getLinkedNotes_ : Note.Note -> ( List Note.Note ) -> ( List Link.Link ) -> ( List ( Note.Note, Link.Link ) )
getLinkedNotes_ note notes links =
  let
      relevantLinks = List.filter ( isAssociated note ) links
  in
  List.filterMap ( convertLinktoLinkNoteTuple note notes ) relevantLinks

-- Given algorithm(rootNote, rootDiscusion, notes, links)
-- For each linked note to the root
-- If (noteIsEntryPointForNewDiscussion)
-- Return [(discussionForTheEntryPoint, newLinkBetweenRootNoteAndDiscussion)]
-- Else
-- Return (linkedNote, link) ++ algorithm(linkedNote, rootDiscussion, notes, links (without found link))

{-| This will get all linked notes to a question and all linked notes to those linked notes
except for if the note is a question. Confusing I know but perhaps this is a confusing feature.
-}
getAllNotesAndLinksInQuestionTree : Note.Note -> Slipbox -> ( List Note.Note, List Link.Link )
getAllNotesAndLinksInQuestionTree question slipbox =
  let
    content = getContent slipbox
    noteLinkTuples = getAllNotesInQuestionTreeRecursion question content.notes content.links
  in
  ( question :: List.map Tuple.first noteLinkTuples, List.map Tuple.second noteLinkTuples )

addNote : String -> String -> Slipbox -> ( Slipbox, Note.Note )
addNote noteContent sourceTitle slipbox =
  let
    content = getContent slipbox
    source =
      if String.isEmpty sourceTitle then
        "n/a"
      else
        sourceTitle
    (note, idGenerator) = Note.create content.idGenerator <|
      { content = noteContent, source = source, variant = Note.Regular }
  in
  ( Slipbox
    { content | notes = (note :: content.notes)
    , idGenerator = idGenerator
    , unsavedChanges = True
    }
  , note
  )

addDiscussion : String -> Slipbox -> ( Slipbox, Note.Note )
addDiscussion discussion slipbox =
  let
    content = getContent slipbox
    source = "n/a"
    (note, idGenerator) = Note.create content.idGenerator <|
      { content = discussion, source = source, variant = Note.Discussion }
  in
  ( Slipbox
    { content | notes = (note :: content.notes)
    , idGenerator = idGenerator
    , unsavedChanges = True
    }
  , note
  )

addSource : String -> String -> String -> Slipbox -> Slipbox
addSource title author sourceContent slipbox =
  let
    content = getContent slipbox
    ( source, generator ) = Source.createSource content.idGenerator
      <| {title=title,author=author,content=sourceContent}
  in
  Slipbox
    { content | sources = source :: content.sources
    , idGenerator = generator
    , unsavedChanges = True
    }

addLink : Note.Note -> Note.Note -> Slipbox -> Slipbox
addLink note1 note2 slipbox =
  let
      content = getContent slipbox
      (link, idGenerator) = Link.create content.idGenerator note1 note2
      links = link :: content.links
  in
  Slipbox
    { content | links = links
    , idGenerator = idGenerator
    , unsavedChanges = True
    }

getAllNotesInQuestionTreeRecursion : Note.Note -> ( List Note.Note ) -> ( List Link.Link) -> List ( Note.Note, Link.Link )
getAllNotesInQuestionTreeRecursion note notes links =
  let
    linkNoteTuples = getLinkedNotesWithoutQuestions note notes links
    linksAlreadyAccountedFor = List.map Tuple.second linkNoteTuples
    remainingLinks =
      List.filter
        ( \l ->
          if List.any ( Link.is l ) linksAlreadyAccountedFor then
            False
          else
            True
        )
        links
    recursedLinkNoteTuples =
      List.map
        ( \linkedNote ->
          getAllNotesInQuestionTreeRecursion
            linkedNote
            ( removeNoteFromList linkedNote notes )
            remainingLinks
        )
        ( List.map Tuple.first linkNoteTuples )
  in
   List.concat
    [ linkNoteTuples
    , flatten2D recursedLinkNoteTuples
    ]

flatten2D : List (List a) -> List a
flatten2D list =
  List.foldr (++) [] list

removeNoteFromList : Note.Note -> ( List Note.Note ) -> ( List Note.Note )
removeNoteFromList note notes =
  List.filter (\n -> not <| Note.is note n ) notes

getLinkedNotesWithoutQuestions : Note.Note -> ( List Note.Note ) -> ( List Link.Link ) -> ( List ( Note.Note, Link.Link ) )
getLinkedNotesWithoutQuestions note notes links =
  let
      relevantLinks = List.filter ( isAssociated note ) links
  in
  List.filterMap ( convertLinktoLinkNoteTupleNoQ note notes ) relevantLinks

convertLinktoLinkNoteTupleNoQ : Note.Note -> ( List Note.Note ) -> Link.Link -> ( Maybe ( Note.Note, Link.Link ) )
convertLinktoLinkNoteTupleNoQ targetNote notes link =
  if Link.isTarget link targetNote then
    case List.head <| List.filter ( Link.isSource link ) notes of

      Just note ->

        case Note.getVariant note of

          Note.Discussion -> Nothing

          Note.Regular -> Just ( note, link )

      Nothing -> Nothing

  else if Link.isSource link targetNote then

    case List.head <| List.filter ( Link.isTarget link ) notes of

      Just note ->

        case Note.getVariant note of

            Note.Discussion -> Nothing

            Note.Regular -> Just ( note, link )

      Nothing -> Nothing

  else

    Nothing


-- Helper Functions
buildItemList : Item.Item -> Item.Item -> (Item.Item -> (List Item.Item) -> (List Item.Item))
buildItemList itemToMatch itemToAdd =
  \item list -> if Item.is item itemToMatch then item :: (itemToAdd :: list) else item :: list

deleteNoteItemStateChange : Note.Note -> Item.Item -> Item.Item
deleteNoteItemStateChange deletedNote item =
  case item of
    Item.AddingLinkToNoteForm itemId tray search note maybeNoteToBeLinked ->
      case maybeNoteToBeLinked of
        Just noteToBeLinked -> 
          if Note.is noteToBeLinked deletedNote then
            Item.AddingLinkToNoteForm itemId tray search note Nothing
          else 
            item
        _ -> item   
    _ -> item

conditionalUpdate : a -> (a -> Bool) -> (a -> a)
conditionalUpdate updatedItem itemIdentifier =
  (\i -> if itemIdentifier i then updatedItem else i)

updateNoteEdits : Note.Note -> Note.Note -> Note.Note
updateNoteEdits noteWithEdits originalNote =
  let
      updatedContent = Note.getContent noteWithEdits
      updatedSource = Note.getSource noteWithEdits
      updatedVariant = Note.getVariant noteWithEdits
  in
  Note.updateContent updatedContent
    <| Note.updateSource updatedSource
      <| Note.updateVariant updatedVariant originalNote

updateSourceEdits : Source.Source -> Source.Source -> Source.Source
updateSourceEdits sourceWithEdits originalSource =
  let
      updatedTitle = Source.getTitle sourceWithEdits
      updatedAuthor = Source.getAuthor sourceWithEdits
      updatedContent = Source.getContent sourceWithEdits
  in
  Source.updateTitle updatedTitle
    <| Source.updateAuthor updatedAuthor
      <| Source.updateContent updatedContent originalSource

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