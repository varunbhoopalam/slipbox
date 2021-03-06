module Slipbox exposing 
  ( Slipbox
  , new
  , getNotes
  , getDiscussions
  , getSources
  , getLinkedNotes
  , decode
  , encode
  , unsavedChanges
  , saveChanges
  , getDiscussionTreeWithCollapsedDiscussions
  , getAllDiscussionsAndLinksBetweenDiscussions
  , addNote
  , addDiscussion
  , addSource
  , addLink
  , breakLink
  , getStrayNotes
  , deleteNote
  )

import Note
import Link
import Set
import Source
import IdGenerator
import Json.Encode
import Json.Decode

--Types
type Slipbox = Slipbox Content

type alias Content =
  { notes: List Note.Note
  , links: List Link.Link
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
new  = Slipbox <| Content [] [] [] IdGenerator.init False

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

getLinkedNotes : Note.Note -> Slipbox -> ( List ( Note.Note, Link.Link ) )
getLinkedNotes note slipbox =
  let
      content = getContent slipbox
      relevantLinks = List.filter ( isAssociated note ) content.links
  in
  List.filterMap ( toLinkNoteTuple note content.notes ) relevantLinks

toLinkNoteTuple : Note.Note -> ( List Note.Note ) -> Link.Link -> ( Maybe ( Note.Note, Link.Link ) )
toLinkNoteTuple targetNote notes link =
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

decode : Json.Decode.Decoder Slipbox
decode =
  let
    slipbox notes links sources idGenerator =
      Slipbox <| Content notes links sources idGenerator False
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
      if isADifferentDiscussion rootNote discussion then
        []
      else
        List.map
          ( \( linkedNote, link ) ->
            case noteIsEntryPointForDifferentDiscussion linkedNote discussion slipbox of
              Just differentDiscussionList ->
                ( linkedNote, link ) :: differentDiscussionList
              Nothing ->
                ( (linkedNote,link) ::
                  recurs
                    linkedNote
                    ( List.filter (\l -> not <| Link.is link l ) links )
                )
          )
          ( getLinkedNotes_ rootNote content.notes links )
          |> flatten2D
    allTuples = recurs discussion content.links
  in
  ( discussion :: List.map Tuple.first allTuples
  , List.map Tuple.second allTuples
  )

{-| A stray note is a note that is not directly or indirectly linked to a discussion.
This function returns all stray notes in the slipbox.
-}
getStrayNotes : ( Maybe String ) -> Slipbox -> List Note.Note
getStrayNotes filter slipbox =
  let
    idsAssociatedToDiscussion discussion existingIds =
      Set.union existingIds
        <| Set.fromList
          <| List.map Note.getId
            <| Tuple.first
              <| getDiscussionTreeWithCollapsedDiscussions discussion slipbox
    idsAssociatedToAllDiscussions = List.foldl idsAssociatedToDiscussion Set.empty ( getDiscussions Nothing slipbox )
    noteNotAssociatedToAnyDiscussion note = not <| Set.member ( Note.getId note ) idsAssociatedToAllDiscussions
  in
  List.filter
    noteNotAssociatedToAnyDiscussion
    <| getNotes filter slipbox

{-| Returns all discussions in a slipbox and which discussions are linked
Discussions are linked if there is a chain of notes that go from one discussion's entry point to another discussion's entry point
Example:
Discussion A and Discussion C are not linked if the entry point of Discussion B is in the chain of notes that connect
the Discussion A and C entry points. In this case the following links would exist
Link: A - B
Link: B - C
-}
getAllDiscussionsAndLinksBetweenDiscussions : Slipbox -> ( List Note.Note, List Link.Link )
getAllDiscussionsAndLinksBetweenDiscussions slipbox =
  let
    discussions = getDiscussions Nothing slipbox
    discussionsWithLinkedDiscussions =
      List.map
      ( \d ->
        ( d
        , List.filter
          ( \n -> Note.getVariant n == Note.Discussion )
          <| Tuple.first <| getDiscussionTreeWithCollapsedDiscussions d slipbox
        )
      )
      discussions
    uniqueDiscussionLinks =
      List.foldl
        ( \(discussion, linkedDiscussions) existingDiscussionLinks ->
          List.concat
            [ List.filterMap
              ( \linkedNode ->
                if isUniqueLink existingDiscussionLinks (discussion, linkedNode) && ( not <| Note.is discussion linkedNode ) then
                  Just (discussion, linkedNode)
                else
                  Nothing
              )
              linkedDiscussions
            , existingDiscussionLinks
            ]
        )
        []
        discussionsWithLinkedDiscussions
    uniqueLinks =
      List.map
        ( \(alpha, beta) -> Tuple.first <| Link.create ( .idGenerator <| getContent slipbox ) alpha beta )
        uniqueDiscussionLinks
  in
  ( discussions, uniqueLinks )

isUniqueLink : ( List ( Note.Note, Note.Note ) ) -> ( Note.Note, Note.Note ) -> Bool
isUniqueLink existingDiscussionLinks (alphaProspect, betaProspect) =
  not <| List.any
    (\(alpha, beta) ->
      ( ( Note.is alpha alphaProspect ) && ( Note.is beta betaProspect ) )
      ||
      ( ( Note.is beta alphaProspect ) && ( Note.is alpha betaProspect ) )
    )
    existingDiscussionLinks

isADifferentDiscussion : Note.Note -> Note.Note -> Bool
isADifferentDiscussion note discussion =
  Note.getVariant note == Note.Discussion && ( not <| Note.is note discussion )

noteIsEntryPointForDifferentDiscussion : Note.Note -> Note.Note -> Slipbox -> Maybe ( List ( Note.Note, Link.Link ) )
noteIsEntryPointForDifferentDiscussion note discussion slipbox =
  let
    noteLinkTuples = getLinkedNotes note slipbox
    differentLinkedDiscussions =
        List.filter
          ( \( linkedNote, _ ) -> isADifferentDiscussion linkedNote discussion )
          noteLinkTuples
    isEntryPointForGivenDiscussion =
      List.any
        ( \( linkedNote, _ ) ->
          Note.is linkedNote discussion
        )
        noteLinkTuples
  in
  if List.isEmpty differentLinkedDiscussions || isEntryPointForGivenDiscussion then
    Nothing
  else
    Just differentLinkedDiscussions

getLinkedNotes_ : Note.Note -> ( List Note.Note ) -> ( List Link.Link ) -> ( List ( Note.Note, Link.Link ) )
getLinkedNotes_ note notes links =
  let
      relevantLinks = List.filter ( isAssociated note ) links
  in
  List.filterMap ( toLinkNoteTuple note notes ) relevantLinks

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

breakLink : Link.Link -> Slipbox -> Slipbox
breakLink link slipbox =
  let content = getContent slipbox
  in
    Slipbox
      { content | links = List.filter (\l -> not <| Link.is l link ) content.links
      , unsavedChanges = True
      }

deleteNote : Note.Note -> Slipbox -> Slipbox
deleteNote note slipbox =
  let
    relevantLinks = List.map Tuple.second <| getLinkedNotes note slipbox
    content = getContent <| List.foldl breakLink slipbox relevantLinks
  in
  Slipbox
    { content | notes = List.filter (\n -> not <| Note.is n note) content.notes
    , unsavedChanges = True
    }

flatten2D : List (List a) -> List a
flatten2D list =
  List.foldr (++) [] list

isAssociated : Note.Note -> Link.Link -> Bool
isAssociated note link =
  Link.isSource link note || Link.isTarget link note