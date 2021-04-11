module Create exposing
  ( Create
  , init
  , toggleCoachingModal
  , next
  , toAddLinkState
  , toChooseDiscussionState
  , createLink
  , removeLink
  , selectNote
  , selectSource
  , noSource
  , newSource
  , submitNewSource
  , submitNewDiscussion
  , updateInput
  , Input(..)
  , view
  , CreateView(..)
  , hover
  , stopHover
  )

import Graph
import Note
import Slipbox
import Source

type Create
  = NoteInput CoachingModal CreateModeInternal
  | ChooseDiscussion CoachingModal CreateModeInternal Filter
  | FindLinksForDiscussion CoachingModal Graph.Graph CreateModeInternal Discussion SelectedNote HoveredNote
  | DesignateDiscussionEntryPoint CoachingModal CreateModeInternal String
  | ChooseSourceCategory CoachingModal CreateModeInternal String
  | CreateNewSource CoachingModal CreateModeInternal Title Author Content
  | PromptCreateAnother CreateModeInternal

type alias Filter = String

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
    NoteInput coachingModal createModeInternal -> ChooseDiscussion coachingModal createModeInternal ""
    ChooseDiscussion coachingModal createModeInternal _ -> DesignateDiscussionEntryPoint coachingModal createModeInternal ""
    DesignateDiscussionEntryPoint coachingModal createModeInternal _ -> ChooseSourceCategory coachingModal createModeInternal ""
    _ -> create

toAddLinkState : Note.Note -> Slipbox.Slipbox -> Create -> Create
toAddLinkState question slipbox create =
  case create of
    ChooseDiscussion coachingModal createModeInternal _ ->
      FindLinksForDiscussion
        coachingModal
        ( Graph.simulatePositions
          <| Slipbox.getDiscussionTreeWithCollapsedDiscussions question slipbox )
        createModeInternal
        question
        question
        Nothing
    _ -> create

toChooseDiscussionState : Create -> Create
toChooseDiscussionState create =
  case create of
    FindLinksForDiscussion coachingModal _ createModeInternal _ _ _ ->
      ChooseDiscussion coachingModal createModeInternal ""
    _ -> create

createLink : Create -> Create
createLink create =
  case create of
    FindLinksForDiscussion coachingModal graph createModeInternal question selectedNote hoveredNote ->
      FindLinksForDiscussion
        coachingModal
        graph
        ( addLink ( makeLink selectedNote ) createModeInternal )
        question
        selectedNote
        hoveredNote
    _ -> create

removeLink : Create -> Create
removeLink create =
  case create of
    FindLinksForDiscussion coachingModal graph createModeInternal question selectedNote hoveredNote ->
      let
        updatedLinks =
          List.filter
            ( \l -> not <| linkIsForNote selectedNote l )
            <| getCreatedLinks createModeInternal
        updatedInternal = setCreatedLinks updatedLinks createModeInternal
      in
      FindLinksForDiscussion coachingModal graph updatedInternal question selectedNote hoveredNote
    _ -> create

selectNote : Note.Note -> Create -> Create
selectNote note create =
  case create of
    FindLinksForDiscussion coachingModal graph createModeInternal question _ hoveredNote ->
      FindLinksForDiscussion coachingModal graph createModeInternal question note hoveredNote
    _ -> create

hover : Note.Note -> Create -> Create
hover note create =
  case create of
    FindLinksForDiscussion coachingModal graph createModeInternal question selectedNote _ ->
      FindLinksForDiscussion coachingModal graph createModeInternal question selectedNote <| Just note
    _ -> create

stopHover : Create -> Create
stopHover create =
  case create of
    FindLinksForDiscussion coachingModal graph createModeInternal question selectedNote _ ->
      FindLinksForDiscussion coachingModal graph createModeInternal question selectedNote Nothing
    _ -> create

selectSource : Source.Source -> Slipbox.Slipbox -> Create -> ( Slipbox.Slipbox, Create )
selectSource source slipbox create =
  case create of
    ChooseSourceCategory _ internal _ ->
      let updatedCreate = PromptCreateAnother <| setExistingSource source internal
      in
      ( updateSlipbox updatedCreate slipbox
      , updatedCreate
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
      let updatedCreate = PromptCreateAnother <| setNewSource title author content internal
      in
      ( updateSlipbox updatedCreate slipbox
      , updatedCreate
      )
    _ -> ( slipbox, create )

submitNewDiscussion : Create -> Create
submitNewDiscussion create =
  case create of
    DesignateDiscussionEntryPoint coachingModal internal discussion ->
      ChooseSourceCategory coachingModal ( setDiscussion discussion internal ) ""
    _ -> create

type Input
  = Note String
  | SourceTitle String
  | SourceAuthor String
  | SourceContent String
  | Filter String

updateInput : Input -> Create -> Create
updateInput input create =
  case input of
    Note noteInput ->
      case create of
        NoteInput coachingModal createModeInternal ->
          NoteInput coachingModal <| setNote noteInput createModeInternal

        DesignateDiscussionEntryPoint coachingModal createModeInternal _ ->
          DesignateDiscussionEntryPoint coachingModal createModeInternal noteInput

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

    Filter filter ->
      case create of
        ChooseDiscussion modal internal _ ->
          ChooseDiscussion modal internal filter
        _ -> create


type alias CoachingOpen = Bool
type alias CanContinue = Bool
type alias SelectedNoteIsLinked = Bool
type alias NotesAssociatedToCreatedLinks = List Note.Note
type alias HoveredNote = Maybe Note.Note
type alias Discussions = List Note.Note
type CreateView
  = NoteInputView CoachingOpen CanContinue CreatedNote
  | ChooseDiscussionView CoachingOpen CanContinue CreatedNote Filter Discussions
  | DiscussionChosenView Graph.Graph CreatedNote Discussion SelectedNote SelectedNoteIsLinked NotesAssociatedToCreatedLinks HoveredNote
  | DesignateDiscussionEntryPointView CreatedNote String
  | ChooseSourceCategoryView CreatedNote String
  | CreateNewSourceView CreatedNote Title Author Content
  | PromptCreateAnotherView CreatedNote

view : Slipbox.Slipbox -> Create -> CreateView
view slipbox create =
  case create of
    NoteInput coachingModal createModeInternal ->
      let
        note = getNote createModeInternal
        canContinue = not <| String.isEmpty note
      in
      NoteInputView (isOpen coachingModal) canContinue note

    ChooseDiscussion coachingModal createModeInternal filter ->
      let
        note = getNote createModeInternal
        canContinue = List.isEmpty <| getCreatedLinks createModeInternal
        dFilter = if String.isEmpty filter then Nothing else Just filter
        discussions = Slipbox.getDiscussions dFilter slipbox
      in
      ChooseDiscussionView (isOpen coachingModal) canContinue note filter discussions

    FindLinksForDiscussion _ graph createModeInternal question selectedNote hoveredNote->
      let
        note = getNote createModeInternal
        createdLinks = getCreatedLinks createModeInternal
        selectedNoteIsLinked =
          List.any
            ( linkIsForNote selectedNote )
            createdLinks
        notesAssociatedToCreatedLinks = List.map getNoteOnLink createdLinks
      in
      DiscussionChosenView
        graph
        note
        question
        selectedNote
        selectedNoteIsLinked
        notesAssociatedToCreatedLinks
        hoveredNote

    DesignateDiscussionEntryPoint _ createModeInternal string ->
      DesignateDiscussionEntryPointView ( getNote createModeInternal ) string

    ChooseSourceCategory _ createModeInternal string ->
      ChooseSourceCategoryView ( getNote createModeInternal ) string

    CreateNewSource _ createModeInternal title author content ->
      CreateNewSourceView ( getNote createModeInternal ) title author content

    PromptCreateAnother createModeInternal ->
      PromptCreateAnotherView <| getNote createModeInternal


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
  = CreateModeInternal CreatedNote LinksCreated Source LinkedDiscussion

getNote : CreateModeInternal -> CreatedNote
getNote internal =
  case internal of
    CreateModeInternal note _ _ _ -> note

getSource : CreateModeInternal -> Source
getSource internal =
  case internal of
    CreateModeInternal _ _ source _ -> source

getDiscussion : CreateModeInternal -> LinkedDiscussion
getDiscussion internal =
  case internal of
    CreateModeInternal _ _ _ linkedDiscussion -> linkedDiscussion

setExistingSource : Source.Source -> CreateModeInternal -> CreateModeInternal
setExistingSource source internal =
  case internal of
    CreateModeInternal note linksCreated _ discussion ->
      CreateModeInternal note linksCreated ( Existing source ) discussion

setNewSource : Title -> Author -> Content -> CreateModeInternal -> CreateModeInternal
setNewSource title author content internal =
  case internal of
    CreateModeInternal note linksCreated _ discussion ->
      CreateModeInternal note linksCreated ( New title author content ) discussion

setDiscussion : String -> CreateModeInternal -> CreateModeInternal
setDiscussion discussion internal =
  case internal of
    CreateModeInternal note linksCreated source _ ->
      CreateModeInternal note linksCreated source <| Just discussion

createModeInternalInit : CreateModeInternal
createModeInternalInit =
  CreateModeInternal "" [] None Nothing

getCreatedLinks : CreateModeInternal -> LinksCreated
getCreatedLinks internal =
  case internal of
    CreateModeInternal _ links _ _ -> links

setCreatedLinks : LinksCreated -> CreateModeInternal -> CreateModeInternal
setCreatedLinks linksCreated internal =
  case internal of
    CreateModeInternal note _ source discussion ->
      CreateModeInternal note linksCreated source discussion

setNote : CreatedNote -> CreateModeInternal -> CreateModeInternal
setNote note internal =
  case internal of
    CreateModeInternal _ linksCreated source discussion ->
      CreateModeInternal note linksCreated source discussion

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

-- CREATEMODESOURCE
type Source
  = None
  | New Title Author Content
  | Existing Source.Source

-- LINKSCREATED
type alias LinksCreated = ( List Link )

-- DISCUSSION
type alias LinkedDiscussion = Maybe String

-- CREATEMODELINK
type Link = Link Note.Note

getNoteOnLink : Link -> Note.Note
getNoteOnLink link =
  case link of
    Link note -> note

makeLink : Note.Note -> Link
makeLink note =
  Link note

-- MISC
type alias Discussion = Note.Note
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
    ChooseDiscussion coachingModal _ _ -> Just coachingModal
    FindLinksForDiscussion coachingModal _ _ _ _ _ -> Just coachingModal
    DesignateDiscussionEntryPoint coachingModal _ _ -> Just coachingModal
    ChooseSourceCategory coachingModal _ _ -> Just coachingModal
    CreateNewSource coachingModal _ _ _ _ -> Just coachingModal
    PromptCreateAnother _ -> Nothing

setCoachingModal : CoachingModal -> Create -> Create
setCoachingModal coachingModal model =
   case model of
     NoteInput _ internal -> NoteInput coachingModal internal
     ChooseDiscussion _ internal filter -> ChooseDiscussion coachingModal internal filter

     FindLinksForDiscussion _ graph internal question selectedNote hoveredNote ->
       FindLinksForDiscussion coachingModal graph internal question selectedNote hoveredNote

     DesignateDiscussionEntryPoint _ createModeInternal string ->
       DesignateDiscussionEntryPoint coachingModal createModeInternal string

     ChooseSourceCategory _ internal input -> ChooseSourceCategory coachingModal internal input
     CreateNewSource _ internal title author content -> CreateNewSource coachingModal internal title author content
     PromptCreateAnother _ -> model

getInternal : Create -> CreateModeInternal
getInternal create =
  case create of
    NoteInput _ createModeInternal -> createModeInternal
    ChooseDiscussion _ createModeInternal _ -> createModeInternal
    FindLinksForDiscussion _ _ createModeInternal _ _ _ -> createModeInternal
    DesignateDiscussionEntryPoint _ createModeInternal _ -> createModeInternal
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
    updatedSlipbox =
      case getDiscussion internal of
        Just discussion ->
          let
            ( slipboxWithDiscussion, discussionNote ) = Slipbox.addDiscussion discussion slipboxWithNote
          in
          Slipbox.addLink note discussionNote slipboxWithDiscussion
        Nothing ->
          slipboxWithNote

  in
  List.foldr ( updateSlipboxWithLink note ) updatedSlipbox ( getCreatedLinks internal )

updateSlipboxWithLink : Note.Note -> Link -> Slipbox.Slipbox -> Slipbox.Slipbox
updateSlipboxWithLink note link slipbox =
  case link of
    Link noteToLink ->
      Slipbox.addLink note noteToLink slipbox