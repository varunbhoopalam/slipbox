module Create exposing
  ( Create
  , init
  , toggleCoachingModal
  , next
  , toAddLinkState
  , toChooseQuestionState
  , createLink
  , createBridge
  , toggleLinkModal
  , removeLink
  , selectNote
  , selectSource
  , noSource
  , newSource
  , submitNewSource
  , updateInput
  , Input(..)
  , view
  , CreateView(..)
  )

import Force
import Note
import Link
import Slipbox
import Source

type Create
  = NoteInput CoachingModal CreateModeInternal
  | ChooseQuestion CoachingModal CreateModeInternal
  | FindLinksForQuestion CoachingModal Graph LinkModal CreateModeInternal Question SelectedNote
  | ChooseSourceCategory CoachingModal CreateModeInternal String
  | CreateNewSource CoachingModal CreateModeInternal Title Author Content
  | PromptCreateAnother CreateModeInternal

init : Create
init =
  NoteInput CoachingModalClosed createModeInternalInit

toggleCoachingModal : Create -> Create
toggleCoachingModal create =
  case getCoachingModal create of
    Just coachingModal ->
      setCoachingModal ( toggle coachingModal ) create
    Nothing ->
      create

next : Create -> Create
next create =
  case create of
    NoteInput coachingModal createModeInternal -> ChooseQuestion coachingModal createModeInternal
    ChooseQuestion coachingModal createModeInternal -> ChooseSourceCategory coachingModal createModeInternal ""
    _ -> create

toAddLinkState : Note.Note -> Slipbox.Slipbox -> Create -> Create
toAddLinkState question slipbox create =
  case create of
    ChooseQuestion coachingModal createModeInternal ->
      let
        (notePositions, links) = simulatePositions
          <| Slipbox.getAllNotesAndLinksInQuestionTree question slipbox
        updatedInternal = read question createModeInternal
      in
      FindLinksForQuestion
        coachingModal
        (Graph notePositions links)
        Closed
        updatedInternal
        question
        question
    _ -> create

toChooseQuestionState : Create -> Create
toChooseQuestionState create =
  case create of
    FindLinksForQuestion coachingModal _ _ createModeInternal _ _ ->
      ChooseQuestion coachingModal createModeInternal
    _ -> create

createLink : Create -> Create
createLink create =
  case create of
    FindLinksForQuestion coachingModal graph linkModal createModeInternal question selectedNote ->
      if linkModalIsClosed linkModal then
        create
      else
        FindLinksForQuestion
          coachingModal
          graph
          closeLinkModal
          ( addLink ( makeLink selectedNote ) createModeInternal )
          question
          selectedNote
    _ -> create

createBridge : Create -> Create
createBridge create =
  case create of
    FindLinksForQuestion coachingModal graph linkModal createModeInternal question selectedNote ->
      case getBridgeNote linkModal of
        Just bridgeNote ->
          FindLinksForQuestion
            coachingModal
            graph
            closeLinkModal
            ( addLink ( makeBridge selectedNote bridgeNote ) createModeInternal )
            question
            selectedNote
        Nothing -> create
    _ -> create

toggleLinkModal : Create -> Create
toggleLinkModal create =
  case create of
    FindLinksForQuestion coachingModal graph linkModal createModeInternal question selectedNote ->
      let createdLinks = getCreatedLinks createModeInternal
      in
      if linkModalIsClosed linkModal then
        case getBridgeNoteIfExists selectedNote createdLinks of
          Just bridge ->
            FindLinksForQuestion coachingModal graph ( openLinkModal bridge ) createModeInternal question selectedNote
          Nothing ->
            FindLinksForQuestion coachingModal graph ( openLinkModal "" ) createModeInternal question selectedNote
      else
        FindLinksForQuestion coachingModal graph closeLinkModal createModeInternal question selectedNote
    _ -> create

removeLink : Create -> Create
removeLink create =
  case create of
    FindLinksForQuestion coachingModal graph linkModal createModeInternal question selectedNote ->
      let
        updatedLinks =
          List.filter
            ( \l -> not <| linkIsForNote selectedNote l )
            <| getCreatedLinks createModeInternal
        updatedInternal = setCreatedLinks updatedLinks createModeInternal
      in
      FindLinksForQuestion coachingModal graph linkModal updatedInternal question selectedNote
    _ -> create

selectNote : Note.Note -> Create -> Create
selectNote note create =
  case create of
    FindLinksForQuestion coachingModal graph linkModal createModeInternal question _ ->
      FindLinksForQuestion coachingModal graph linkModal createModeInternal question note
    _ -> create

selectSource : Source.Source -> Slipbox.Slipbox -> Create -> ( Slipbox.Slipbox, Create )
selectSource source slipbox create =
  case create of
    ChooseSourceCategory _ internal _ ->
      ( updateSlipbox create slipbox
      , PromptCreateAnother <| setExistingSource source internal
      )
    _ -> ( slipbox, create )

noSource : Slipbox.Slipbox -> Create -> ( Slipbox.Slipbox, Create )
noSource slipbox create =
  case create of
    ChooseSourceCategory _ internal _ ->
      ( updateSlipbox create slipbox
      , PromptCreateAnother internal
      )
    _ -> ( slipbox, create )

newSource : Create -> Create
newSource create =
  case create of
    ChooseSourceCategory coachingModal internal _ ->
      CreateNewSource coachingModal internal "" "" ""
    _ -> create

submitNewSource : Slipbox.Slipbox -> Create -> ( Slipbox.Slipbox, Create )
submitNewSource slipbox create =
  case create of
    CreateNewSource _ internal title author content ->
      ( updateSlipbox create slipbox
      , PromptCreateAnother <| setNewSource title author content internal
      )
    _ -> ( slipbox, create )


type Input
  = Note String
  | SourceTitle String
  | SourceAuthor String
  | SourceContent String

updateInput : Input -> Create -> Create
updateInput input create =
  case input of
    Note noteInput ->
      case create of
        NoteInput coachingModal createModeInternal ->
          NoteInput coachingModal <| setNote noteInput createModeInternal

        FindLinksForQuestion coachingModal graph linkModal createModeInternal question selectedNote ->
          FindLinksForQuestion coachingModal graph (setBridgeNote noteInput linkModal) createModeInternal question selectedNote

        _ -> create

    SourceTitle title ->
      case create of
        ChooseSourceCategory coachingModal internal _ ->
          ChooseSourceCategory coachingModal internal title

        CreateNewSource coachingModal internal _ author content ->
          CreateNewSource coachingModal internal title author content

        _ -> create

    SourceAuthor author ->
      case create of
        CreateNewSource coachingModal internal title _ content ->
          CreateNewSource coachingModal internal title author content
        _ -> create

    SourceContent content ->
      case create of
        CreateNewSource coachingModal internal title author _ ->
          CreateNewSource coachingModal internal title author content
        _ -> create

type alias CoachingOpen = Bool
type alias CanContinue = Bool
type CreateView
  = NoteCreation CoachingOpen CanContinue CreatedNote
  | QuestionScreen CoachingOpen CanContinue CreatedNote QuestionsRead

view : Create -> CreateView
view create =
  case create of
    NoteInput coachingModal createModeInternal ->
      let
        note = getNote createModeInternal
        canContinue = not <| String.isEmpty note
      in
      NoteCreation (isOpen coachingModal) canContinue note


    ChooseQuestion coachingModal createModeInternal ->



    FindLinksForQuestion coachingModal graph linkModal createModeInternal question selectedNote ->


    ChooseSourceCategory coachingModal createModeInternal string ->


    CreateNewSource coachingModal createModeInternal title author content ->


    PromptCreateAnother createModeInternal ->


-- COACHINGMODAL
type CoachingModal = CoachingModalOpen | CoachingModalClosed

toggle : CoachingModal -> CoachingModal
toggle modal =
  case modal of
    CoachingModalOpen -> CoachingModalClosed
    CoachingModalClosed -> CoachingModalOpen

isOpen : CoachingModal -> Bool
isOpen modal =
  case modal of
    CoachingModalOpen -> True
    CoachingModalClosed -> False

-- CREATEMODEINTERNAL
type CreateModeInternal
  = CreateModeInternal CreatedNote QuestionsRead LinksCreated Source

getNote : CreateModeInternal -> CreatedNote
getNote internal =
  case internal of
    CreateModeInternal note _ _ _ -> note

getSource : CreateModeInternal -> Source
getSource internal =
  case internal of
    CreateModeInternal _ _ _ source -> source

setExistingSource : Source.Source -> CreateModeInternal -> CreateModeInternal
setExistingSource source internal =
  case internal of
    CreateModeInternal note questionsRead linksCreated _ ->
      CreateModeInternal note questionsRead linksCreated <| Existing source

setNewSource : Title -> Author -> Content -> CreateModeInternal -> CreateModeInternal
setNewSource title author content internal =
  case internal of
    CreateModeInternal note questionsRead linksCreated _ ->
      CreateModeInternal note questionsRead linksCreated <| New title author content

createModeInternalInit : CreateModeInternal
createModeInternalInit =
  CreateModeInternal "" [] [] None

getCreatedLinks : CreateModeInternal -> LinksCreated
getCreatedLinks internal =
  case internal of
    CreateModeInternal _ _ links _ -> links

setCreatedLinks : LinksCreated -> CreateModeInternal -> CreateModeInternal
setCreatedLinks linksCreated internal =
  case internal of
    CreateModeInternal note questionsRead _ source ->
      CreateModeInternal note questionsRead linksCreated source

setNote : CreatedNote -> CreateModeInternal -> CreateModeInternal
setNote note internal =
  case internal of
    CreateModeInternal _ questionsRead linksCreated source -> CreateModeInternal note questionsRead linksCreated source

read : Question -> CreateModeInternal -> CreateModeInternal
read question internal =
  case internal of
    CreateModeInternal note questionsRead linksCreated source ->
      CreateModeInternal note (question :: questionsRead) linksCreated source

linkIsForNote : Note.Note -> Link -> Bool
linkIsForNote note link =
  Note.is note ( getNoteOnLink link )

addLink : Link -> CreateModeInternal -> CreateModeInternal
addLink newLink internal =
  let
    note = getNoteOnLink newLink
    links = getCreatedLinks internal

    linkIdentifier = ( linkIsForNote note )

    linkToNoteAlreadyExists = List.any linkIdentifier links
    updatedCreatedLinks =
      if linkToNoteAlreadyExists then
        List.map
          ( \link ->
            if linkIdentifier link then
              newLink
            else
              link
          )
          links
      else
        newLink :: links
  in
  setCreatedLinks updatedCreatedLinks internal

-- GRAPH
type alias Graph =
  { positions :  List NotePosition
  , links : List Link.Link
  }

type alias NotePosition =
  { id : Int
  , note : Note.Note
  , x : Float
  , y : Float
  , vx : Float
  , vy : Float
  }

-- LINKMODAL
type LinkModal
  = Closed
  | Open CreatedNote

setBridgeNote : CreatedNote -> LinkModal -> LinkModal
setBridgeNote input linkModal =
  case linkModal of
    Closed -> linkModal
    Open _ -> Open input

getBridgeNote : LinkModal -> Maybe CreatedNote
getBridgeNote linkModal =
  case linkModal of
    Closed -> Nothing
    Open bridge -> Just bridge

linkModalIsClosed : LinkModal -> Bool
linkModalIsClosed bridgeModal =
  case bridgeModal of
    Closed -> True
    Open _ -> False

closeLinkModal : LinkModal
closeLinkModal = Closed

openLinkModal : CreatedNote -> LinkModal
openLinkModal bridge = Open bridge

-- CREATEMODESOURCE
type Source
  = None
  | New Title Author Content
  | Existing Source.Source

-- QUESTIONSREAD
type alias QuestionsRead = ( List Note.Note )

-- LINKSCREATED
type alias LinksCreated = ( List Link )

getLinkForSelectedNote : Note.Note -> LinksCreated -> Maybe Link
getLinkForSelectedNote note linksCreated =
  List.head <|
    List.filter
      ( linkIsForNote note )
      linksCreated

-- CREATEMODELINK
type Link
  = Link Note.Note
  | Bridge Note.Note CreatedNote

getNoteOnLink : Link -> Note.Note
getNoteOnLink link =
  case link of
    Link note -> note
    Bridge note _ -> note

getBridgeOnLink : Link -> Maybe CreatedNote
getBridgeOnLink link =
  case link of
    Link _ -> Nothing
    Bridge _ bridge -> Just bridge

makeLink : Note.Note -> Link
makeLink note =
  Link note

makeBridge : Note.Note -> String -> Link
makeBridge note bridgeNote =
  Bridge note bridgeNote

-- MISC
type alias Question = Note.Note
type alias SelectedNote = Note.Note
type alias Title = String
type alias Author = String
type alias Content = String
type alias CreatedNote = String

-- HELPER

getCoachingModal : Create -> ( Maybe CoachingModal )
getCoachingModal model =
  case model of
    NoteInput coachingModal _ -> Just coachingModal
    ChooseQuestion coachingModal _ -> Just coachingModal
    FindLinksForQuestion coachingModal _ _ _ _ _ -> Just coachingModal
    ChooseSourceCategory coachingModal _ _ -> Just coachingModal
    CreateNewSource coachingModal _ _ _ _ -> Just coachingModal
    PromptCreateAnother _ -> Nothing

setCoachingModal : CoachingModal -> Create -> Create
setCoachingModal coachingModal model =
   case model of
     NoteInput _ internal -> NoteInput coachingModal internal
     ChooseQuestion _ internal -> ChooseQuestion coachingModal internal
     FindLinksForQuestion _ graph bridgeModal internal question selectedNote ->
      FindLinksForQuestion coachingModal graph bridgeModal internal question selectedNote
     ChooseSourceCategory _ internal input -> ChooseSourceCategory coachingModal internal input
     CreateNewSource _ internal title author content -> CreateNewSource coachingModal internal title author content
     PromptCreateAnother _ -> model

simulatePositions : ( List Note.Note, List Link.Link ) -> ( List NotePosition, List Link.Link )
simulatePositions (notes, links) =
  let
    toEntity note =
      { id = Note.getId note
      , x = Note.getX note
      , y = Note.getY note
      , vx = Note.getVx note
      , vy = Note.getVy note
      , note = note
      }
    entities = List.map toEntity notes
    state =
      Force.simulation
        [ Force.manyBodyStrength -15 (List.map (\n -> n.id) entities)
        , Force.links <| List.map (\link -> ( Link.getSourceId link, Link.getTargetId link)) links
        , Force.center 0 0
        ]
    notePositions = Force.computeSimulation state entities
  in
  ( notePositions, links )

getBridgeNoteIfExists : Note.Note -> LinksCreated -> Maybe CreatedNote
getBridgeNoteIfExists note linksCreated =
  case getLinkForSelectedNote note linksCreated of
    Just link -> getBridgeOnLink link
    Nothing -> Nothing

getInternal : Create -> CreateModeInternal
getInternal create =
  case create of
    NoteInput _ createModeInternal -> createModeInternal
    ChooseQuestion _ createModeInternal -> createModeInternal
    FindLinksForQuestion _ _ _ createModeInternal _ _ -> createModeInternal
    ChooseSourceCategory _ createModeInternal _ -> createModeInternal
    CreateNewSource _ createModeInternal _ _ _ -> createModeInternal
    PromptCreateAnother createModeInternal -> createModeInternal

updateSlipbox : Create -> Slipbox.Slipbox -> Slipbox.Slipbox
updateSlipbox create slipbox =
  let
    internal = getInternal create
    ( sourceTitle, slipboxWithSource ) =
      case getSource internal of
        None -> ( "n/a", slipbox )
        Existing source -> ( Source.getTitle source, slipbox )
        New title author content ->
          ( title
          , Slipbox.addSource title author content slipbox
          )
    ( slipboxWithNote, note ) = Slipbox.addNote ( getNote internal ) sourceTitle slipboxWithSource
  in
  List.foldr ( updateSlipboxWithLink note ) slipboxWithNote ( getCreatedLinks internal )

updateSlipboxWithLink : Note.Note -> Link -> Slipbox.Slipbox -> Slipbox.Slipbox
updateSlipboxWithLink note link slipbox =
  case link of
    Link noteToLink ->
      Slipbox.addLink note noteToLink slipbox

    Bridge noteToLink bridge ->
      let
        ( slipboxWithBridgeNote, bridgeNote ) = Slipbox.addNote bridge "n/a" slipbox
      in
      Slipbox.addLink note bridgeNote slipboxWithBridgeNote
        |> Slipbox.addLink bridgeNote noteToLink