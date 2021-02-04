module CreateMode exposing (..)

import Browser
import Element.Border
import FontAwesome.Attributes
import FontAwesome.Icon
import FontAwesome.Solid
import FontAwesome.Svg
import Html.Attributes
import Html.Events
import Link
import Slipbox
import Note
import Force
import Source
import Html
import Element exposing (Element)
import Element.Input
import Element.Font
import Svg
import Svg.Attributes
import Svg.Events

-- MAIN

-- TODO: Use replaceURL to turn this into a SPA?

main =
  Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }

-- MODEL

type Model
  = NoteInput CoachingModal Slipbox.Slipbox CreateModeInternal
  | ChooseQuestion CoachingModal Slipbox.Slipbox CreateModeInternal
  | FindLinksForQuestion CoachingModal Graph LinkModal Slipbox.Slipbox CreateModeInternal Question SelectedNote
  | ChooseSourceCategory CoachingModal Slipbox.Slipbox CreateModeInternal String
  | CreateNewSource CoachingModal Slipbox.Slipbox CreateModeInternal Title Author Content
  | PromptCreateAnother Slipbox.Slipbox CreateModeInternal

type alias Question = Note.Note
type alias SelectedNote = Note.Note

getCoachingModal : Model -> ( Maybe CoachingModal )
getCoachingModal model =
  case model of
    NoteInput coachingModal _ _ -> Just coachingModal
    ChooseQuestion coachingModal _ _ -> Just coachingModal
    FindLinksForQuestion coachingModal _ _ _ _ _ _ -> Just coachingModal
    ChooseSourceCategory coachingModal _ _ _ -> Just coachingModal
    CreateNewSource coachingModal _ _ _ _ _ -> Just coachingModal
    PromptCreateAnother _ _ -> Nothing

setCoachingModal : CoachingModal -> Model -> Model
setCoachingModal coachingModal model =
   case model of
     NoteInput _ slipbox internal -> NoteInput coachingModal slipbox internal
     ChooseQuestion _ slipbox internal -> ChooseQuestion coachingModal slipbox internal
     FindLinksForQuestion _ graph bridgeModal slipbox internal question selectedNote ->
      FindLinksForQuestion coachingModal graph bridgeModal slipbox internal question selectedNote
     ChooseSourceCategory _ slipbox internal input -> ChooseSourceCategory coachingModal slipbox internal input
     CreateNewSource _ slipbox internal title author content -> CreateNewSource coachingModal slipbox internal title author content
     PromptCreateAnother _ _ -> model

getInternal : Model -> CreateModeInternal
getInternal model =
  case model of
    NoteInput _ _ createModeInternal -> createModeInternal
    ChooseQuestion _ _ createModeInternal -> createModeInternal
    FindLinksForQuestion _ _ _ _ createModeInternal _ _ -> createModeInternal
    ChooseSourceCategory _ _ createModeInternal _ -> createModeInternal
    CreateNewSource _ _ createModeInternal _ _ _ -> createModeInternal
    PromptCreateAnother _ createModeInternal -> createModeInternal

setInternal : CreateModeInternal -> Model -> Model
setInternal createModeInternal model =
  case model of
    NoteInput coachingModal slipbox _ -> NoteInput coachingModal slipbox createModeInternal
    ChooseQuestion coachingModal slipbox _ -> ChooseQuestion coachingModal slipbox createModeInternal
    FindLinksForQuestion coachingModal graph bridgeModal slipbox _ question selectedNote ->
      FindLinksForQuestion coachingModal graph bridgeModal slipbox createModeInternal question selectedNote
    ChooseSourceCategory coachingModal slipbox _ input -> ChooseSourceCategory coachingModal slipbox createModeInternal input
    CreateNewSource coachingModal slipbox _ title author content -> CreateNewSource coachingModal slipbox createModeInternal title author content
    PromptCreateAnother slipbox _ -> PromptCreateAnother slipbox createModeInternal

nextStep : Model -> Model
nextStep model =
  case model of
    NoteInput coachingModal slipbox createModeInternal -> ChooseQuestion coachingModal slipbox createModeInternal
    ChooseQuestion coachingModal slipbox createModeInternal -> ChooseSourceCategory coachingModal slipbox createModeInternal ""
    _ -> model

-- CREATEMODEINTERNAL
type CreateModeInternal
  = CreateModeInternal Note QuestionsRead LinksCreated Source

type Source
  = None
  | New Title Author Content
  | Existing Source.Source

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

setNote : Note -> CreateModeInternal -> CreateModeInternal
setNote note internal =
  case internal of
    CreateModeInternal _ questionsRead linksCreated source -> CreateModeInternal note questionsRead linksCreated source

createModeInternalInit : CreateModeInternal
createModeInternalInit =
  CreateModeInternal "" [] [] None

getNote : CreateModeInternal -> String
getNote internal =
  case internal of
    CreateModeInternal note _ _ _ -> note

getCreatedLinks : CreateModeInternal -> LinksCreated
getCreatedLinks internal =
  case internal of
    CreateModeInternal _ _ links _ -> links

setCreatedLinks : LinksCreated -> CreateModeInternal -> CreateModeInternal
setCreatedLinks linksCreated internal =
  case internal of
    CreateModeInternal note questionsRead _ source ->
      CreateModeInternal note questionsRead linksCreated source

getQuestionsRead : CreateModeInternal -> QuestionsRead
getQuestionsRead internal =
  case internal of
    CreateModeInternal _ questions _ _ -> questions

markQuestionAsRead : Note.Note -> CreateModeInternal -> CreateModeInternal
markQuestionAsRead question internal =
  case internal of
    CreateModeInternal note questionsRead linksCreated source ->
      CreateModeInternal note (question :: questionsRead) linksCreated source

createLink : Note.Note -> CreateModeInternal -> CreateModeInternal
createLink note internal =
  let
    links = getCreatedLinks internal
    linkIdentifier = ( linkIsForNote note )
    linkToNoteAlreadyExists = List.any linkIdentifier links
    newLink = makeLink note
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

createBridge : Note.Note -> String -> CreateModeInternal -> CreateModeInternal
createBridge note bridgeNote internal =
  let
    links = getCreatedLinks internal
    linkIdentifier = ( linkIsForNote note )
    linkToNoteAlreadyExists = List.any linkIdentifier links
    newLink = makeBridge note bridgeNote
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

type alias Note = String
-- TODO: This data structure allows for duplicate questions, is that okay?
-- We can prevent this with logic but perhaps a set would be a better structure
type alias QuestionsRead = ( List Note.Note )

type alias LinksCreated = ( List Link )

removeLinkAssociatedWithNote : Note.Note -> LinksCreated -> LinksCreated
removeLinkAssociatedWithNote note linksCreated =
  List.filter
    (\l -> not <| linkIsForNote note l )
    linksCreated

type Link
  = Link Note.Note
  | Bridge Note.Note Note

getBridgeNoteFromLink : Link -> Maybe String
getBridgeNoteFromLink link =
  case link of
    Link _ -> Nothing
    Bridge _ bridgeNote -> Just bridgeNote

makeLink : Note.Note -> Link
makeLink note =
  Link note

makeBridge : Note.Note -> String -> Link
makeBridge note bridgeNote =
  Bridge note bridgeNote

linkIsForNote : Note.Note -> Link -> Bool
linkIsForNote note link =
  Note.is note ( getNoteOnLink link )

getNoteOnLink : Link -> Note.Note
getNoteOnLink link =
  case link of
    Link noteOnLink -> noteOnLink
    Bridge noteOnLink _ -> noteOnLink


getLinkForSelectedNote : Note.Note -> LinksCreated -> Maybe Link
getLinkForSelectedNote note linksCreated =
  List.head <|
    List.filter
      ( linkIsForNote note )
      linksCreated

getLinkForSelectedNoteIfBridge : Note.Note -> LinksCreated -> Maybe String
getLinkForSelectedNoteIfBridge note linksCreated =
  Maybe.andThen
    getBridgeNoteFromLink <|
    List.head <|
      List.filter
        ( linkIsForNote note )
        linksCreated

-- COACHINGMODAL
type CoachingModal = CoachingModalOpen | CoachingModalClosed

toggle : CoachingModal -> CoachingModal
toggle modal =
  case modal of
    CoachingModalOpen -> CoachingModalClosed
    CoachingModalClosed -> CoachingModalOpen



type alias Title = String
type alias Author = String
type alias Content = String

type LinkModal
  = Closed
  | Open String

openLinkModal : String -> LinkModal
openLinkModal bridgeNote =
  Open bridgeNote

closeLinkModal : LinkModal
closeLinkModal = Closed

linkModalIsClosed : LinkModal -> Bool
linkModalIsClosed bridgeModal =
  case bridgeModal of
    Closed -> True
    Open _ -> False

-- TODO: Do I need to include links in here as well to represent them on the graph?
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

-- INIT
-- TODO: Refactor to take a slipbox
init : () -> ( Model, Cmd Msg)
init _ =
  ( NoteInput CoachingModalClosed Slipbox.new createModeInternalInit
  , Cmd.none
  )

-- UPDATE
type Msg
  = ToggleCoaching
  | UpdateNote String
  | NextStep
  | ToFindLinksForQuestion Note.Note
  | ToChooseQuestion
  | CreateLinkForSelectedNote
  | CreateBridgeForSelectedNote
  | CancelCreateLink
  | LinkCheckboxToggled Bool
  | SelectNote SelectedNote
  | ExistingSourceInputChanged String
  | ContinueWithSelectedSource Source.Source
  | NoSource
  | NewSource
  | SubmitNewSource
  | UpdateNewSourceTitle String
  | UpdateNewSourceAuthor String
  | UpdateNewSourceContent String
  | CreateAnotherNote

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    ToggleCoaching ->
      ( case getCoachingModal model of
        Just coachingModal ->
          setCoachingModal ( toggle coachingModal ) model
        Nothing ->
          model
      , Cmd.none
      )
    UpdateNote noteInput ->
      let
        updatedCreateModeInternal = setNote noteInput <| getInternal model
      in
      ( setInternal updatedCreateModeInternal model
      , Cmd.none
      )
    NextStep ->
      ( nextStep model
      , Cmd.none
      )
    ToFindLinksForQuestion question ->
      case model of
        ChooseQuestion coachingModal slipbox createModeInternal ->
          let
            (notePositions, links) = simulatePositions
              <| Slipbox.getAllNotesAndLinksInQuestionTree question slipbox
            updatedInternal = markQuestionAsRead question createModeInternal
          in
          ( FindLinksForQuestion
            coachingModal
            (Graph notePositions links)
            Closed
            slipbox
            updatedInternal
            question
            question
          , Cmd.none
          )
        _ -> ( model, Cmd.none )
    ToChooseQuestion ->
      case model of
        FindLinksForQuestion coachingModal _ _ slipbox createModeInternal _ _ ->
          ( ChooseQuestion coachingModal slipbox createModeInternal
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    CreateLinkForSelectedNote ->
      case model of
        FindLinksForQuestion coachingModal graph linkModal slipbox createModeInternal question selectedNote ->
          if linkModalIsClosed linkModal then
            ( model, Cmd.none )
          else
            ( FindLinksForQuestion
              coachingModal
              graph
              closeLinkModal
              slipbox
              ( createLink selectedNote createModeInternal )
              question
              selectedNote
            , Cmd.none
            )
        _ -> ( model, Cmd.none )

    CreateBridgeForSelectedNote ->
      case model of
        FindLinksForQuestion coachingModal graph linkModal slipbox createModeInternal question selectedNote ->
          case linkModal of
            Closed -> ( model, Cmd.none )
            Open bridgeNote ->
              ( FindLinksForQuestion
                coachingModal
                graph
                closeLinkModal
                slipbox
                ( createBridge selectedNote bridgeNote createModeInternal )
                question
                selectedNote
              , Cmd.none
              )
        _ -> ( model, Cmd.none )

    CancelCreateLink ->
      case model of
        FindLinksForQuestion coachingModal graph _ slipbox createModeInternal question selectedNote ->
          ( FindLinksForQuestion coachingModal graph closeLinkModal slipbox createModeInternal question selectedNote
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    LinkCheckboxToggled _ ->
      case model of
        FindLinksForQuestion coachingModal graph linkModal slipbox createModeInternal question selectedNote ->
          let
            createdLinks = getCreatedLinks createModeInternal
          in
          case getLinkForSelectedNote selectedNote createdLinks of
            Just _ ->
              let
                updatedCreatedLinks = removeLinkAssociatedWithNote selectedNote createdLinks
                updatedCreateModeInternal = setCreatedLinks updatedCreatedLinks createModeInternal
              in
              ( FindLinksForQuestion coachingModal graph linkModal slipbox updatedCreateModeInternal question selectedNote
              , Cmd.none
              )
            Nothing ->
              let
                updatedLinkModal =
                  if linkModalIsClosed linkModal then
                    openLinkModal ""
                  else
                    linkModal
              in
              ( FindLinksForQuestion coachingModal graph updatedLinkModal slipbox createModeInternal question selectedNote
              , Cmd.none
              )

        _ -> ( model, Cmd.none )

    SelectNote newSelectedNote ->
      case model of
        FindLinksForQuestion coachingModal graph linkModal slipbox createModeInternal question _ ->
          ( FindLinksForQuestion coachingModal graph linkModal slipbox createModeInternal question newSelectedNote
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    ExistingSourceInputChanged input ->
      case model of
        ChooseSourceCategory coachingModal slipbox internal _ ->
          ( ChooseSourceCategory coachingModal slipbox internal input
          , Cmd.none
          )
        _ -> ( model,Cmd.none )

    ContinueWithSelectedSource source ->
      case model of
        ChooseSourceCategory _ slipbox internal _ ->
          let
            updatedInternal = setExistingSource source internal
          in
          ( PromptCreateAnother (alterSlipbox updatedInternal slipbox) updatedInternal
          , Cmd.none
          )
        _ -> ( model,Cmd.none )

    NoSource ->
      case model of
        ChooseSourceCategory _ slipbox internal _ ->
          ( PromptCreateAnother (alterSlipbox internal slipbox) internal
          , Cmd.none
          )
        _ -> ( model,Cmd.none )

    NewSource ->
      case model of
        ChooseSourceCategory coachingModal slipbox internal _ ->
          ( CreateNewSource coachingModal slipbox internal "" "" ""
          , Cmd.none
          )
        _ -> ( model,Cmd.none )

    SubmitNewSource ->
      case model of
        CreateNewSource _ slipbox internal title author content ->
          let
            updatedInternal = setNewSource title author content internal
          in
          ( PromptCreateAnother (alterSlipbox updatedInternal slipbox) updatedInternal
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    UpdateNewSourceTitle title ->
      case model of
        CreateNewSource coachingModal slipbox internal _ author content ->
          ( CreateNewSource coachingModal slipbox internal title author content
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    UpdateNewSourceAuthor author ->
      case model of
        CreateNewSource coachingModal slipbox internal title _ content ->
          ( CreateNewSource coachingModal slipbox internal title author content
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    UpdateNewSourceContent content ->
      case model of
        CreateNewSource coachingModal slipbox internal title author _ ->
          ( CreateNewSource coachingModal slipbox internal title author content
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    CreateAnotherNote ->
      case model of
        PromptCreateAnother slipbox internal ->
          init ()
        _ -> ( model, Cmd.none )


simulatePositions : ( List Note.Note, List Link.Link ) -> ( List NotePosition, List Link.Link )
simulatePositions (notes, links) =
  let
    entities = List.map toEntity notes
    state = stateBuilder entities links
    notePositions = Force.computeSimulation state entities
  in
  ( notePositions, links )

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

-- SUBSCRIPTIONS
subscriptions: Model -> Sub Msg
subscriptions model = Sub.none


-- VIEW
smallerElement = Element.fillPortion 1000
biggerElement = Element.fillPortion 1618
      -- TODO Change to layoutWith when it is hooked up to main
      --Element.layoutWith
      --{ options = [ Element.noStaticStyleSheet ] }
view : Model -> Html.Html Msg
view model =
  case model of
    NoteInput coachingModal _ internal ->
      let
        coachingText =
          Element.paragraph
            [ Element.Font.center
            , Element.width <| Element.maximum 800 Element.fill
            , Element.centerX
            ]
            [ Element.text "Transform your learning into clear, concise notes with one idea. "
            , Element.text "Write as if you'll forget all about this note. "
            , Element.text "When you come across it again, you should be able to read and understand. "
            , Element.text "Take your time, this isn't always an easy endeavor. "
            ]
        continueNode =
          if not <| String.isEmpty <| getNote internal then
            Element.Input.button
              [ Element.alignRight
              ]
              { onPress = Just NextStep
              , label = Element.text "Next"
              }
          else
            Element.none
      in
      Element.layout
        [ Element.inFront cancel
        , Element.width Element.fill
        , Element.height Element.fill
        ]
        <| Element.column
          [ Element.padding 16
          , Element.centerX
          , Element.width Element.fill
          , Element.spacingXY 32 32
          ]
          [ Element.el
            [ Element.centerX
            , Element.Font.heavy
            ] <|
            Element.text "Write a Permanent Note"
          , coaching coachingModal coachingText
          , Element.Input.multiline
            []
            { onChange = UpdateNote
            , text = getNote internal
            , placeholder = Nothing
            , label = Element.Input.labelAbove [] <| Element.text "Note Content (required)"
            , spellcheck = True
            }
          , continueNode
          ]

    ChooseQuestion coachingModal slipbox createModeInternal ->
      let
        coachingText =
          Element.paragraph
            [ Element.Font.center
            , Element.width <| Element.maximum 800 Element.fill
            , Element.centerX
            ]
            [ Element.text "Further existing arguments by improving your understanding of questions you want to answer. "
            , Element.text "Choose a question and find notes to link your new knowledge to. "
            , Element.text "Linking knowledge can anything from finding supporting arguments, expanding on a thought, and especially finding counter arguments. "
            , Element.text "Because of existing biases, it is hard for us to gather information that opposes what we already know. "
            ]
        continueNode =
          if List.isEmpty <| getCreatedLinks createModeInternal then
            Element.Input.button
              [ Element.alignRight
              ]
              { onPress = Just NextStep
              , label = Element.text "Continue without linking"
              }
          else
            Element.Input.button
              [ Element.alignRight
              ]
              { onPress = Just NextStep
              , label = Element.text "Next"
              }
      in
      Element.layout
        [ Element.inFront cancel
        , Element.width Element.fill
        , Element.height Element.fill
        ]
        <| Element.column
          [ Element.padding 16
          , Element.centerX
          , Element.width Element.fill
          , Element.spacingXY 32 32
          ]
          [ Element.el
            [ Element.centerX
            , Element.Font.heavy
            ] <|
            Element.text "Further Existing Arguments"
          , coaching coachingModal coachingText
          , Element.paragraph
            [ Element.Font.center
            , Element.width <| Element.maximum 800 Element.fill
            , Element.centerX
            ]
            [ Element.text <| getNote createModeInternal
            ]
          , continueNode
          , Element.table
            []
            { data = questionTabularData createModeInternal slipbox
            , columns =
              [ { header = Element.text "Read"
                , width = Element.shrink
                , view =
                      \row ->
                          case row.read of
                            True -> Element.text "read"
                            False -> Element.text "unread"
                }
              , { header = Element.text "Question"
                , width = Element.fill
                , view =
                      \row ->
                          Element.Input.button
                            []
                            { onPress = Just <| ToFindLinksForQuestion row.note
                            , label = Element.text row.question
                            }
                }
              ]
            }
          ]

    FindLinksForQuestion _ graph linkModal _ createModeInternal question selectedNote ->
      Element.layout
        [ Element.inFront <| doneOrLinkModal selectedNote ( getNote createModeInternal ) linkModal
        , Element.width Element.fill
        , Element.height Element.fill
        ] <|
        Element.row
          [ Element.width Element.fill
          , Element.height Element.fill
          ]
          [ Element.column
            [ Element.width smallerElement
            , Element.height Element.fill
            ]
            [ Element.el [ Element.width Element.fill, Element.padding 8 ] <| Element.text <| Note.getContent question
            , Element.el [ Element.width Element.fill, Element.padding 8 ] <| Element.text <| getNote createModeInternal
            , Element.column
              []
              [ Element.el [ Element.alignRight ] starIcon
              , Element.el [] <| Element.text <| Note.getContent selectedNote
              , linkCheckbox selectedNote <| getCreatedLinks createModeInternal
              ]
            ]
          , Element.column
            [ Element.width biggerElement
            , Element.height Element.fill
            ]
            [ viewGraph graph createModeInternal selectedNote
            , Element.wrappedRow
              [ Element.width Element.fill
              , Element.height Element.shrink
              , Element.padding 8
              , Element.spacingXY 8 8
              ]
              [ Element.row
                []
                [ starIcon
                , Element.text "Currently Selected Note"
                ]
              , Element.row
                []
                [ linkIcon
                , Element.text "Note Marked to link (if not selected)"
                ]
              , Element.row
                []
                [ questionIcon
                , Element.text "Question (if not selected)"
                ]
              ]
            ]
          ]

    ChooseSourceCategory _ slipbox createModeInternal input ->
      let
        existingSources = Slipbox.getSources Nothing slipbox
        maybeSourceSelected = List.head <| List.filter ( \source -> Source.getTitle source == input ) existingSources
        useExistingSourceNode =
          case maybeSourceSelected of
            Just source ->
              Element.Input.button
                []
                { onPress = Just <| ContinueWithSelectedSource source
                , label = Element.text "Use Selected Source"
                }
            Nothing ->
              Element.none
      in
      Element.layout
        [ Element.inFront cancel
        , Element.width Element.fill
        , Element.height Element.fill
        ] <|
        Element.column
          []
          [ Element.text <| getNote createModeInternal
          , Element.row
            []
            [ sourceInput input <| List.map Source.getTitle existingSources
            , useExistingSourceNode
            ]
          , Element.Input.button
            []
            { onPress = Just NoSource
            , label = Element.text "No Source"
            }
          , Element.Input.button
            []
            { onPress = Just NewSource
            , label = Element.text "New Source"
            }
          ]
    CreateNewSource coachingModal slipbox createModeInternal title author content ->
      let
        existingTitles = List.map Source.getTitle <| Slipbox.getSources Nothing slipbox
        ( titleLabel, submitNode ) =
          if Source.titleIsValid existingTitles title then
            ( Element.text "Title (required)"
            , Element.Input.button
              []
              { onPress = Just SubmitNewSource
              , label = Element.text "Submit New Source"
              }
            )
          else
            if String.isEmpty title then
              ( Element.text "Title (required)"
              , Element.none
              )
            else
              ( Element.text "Title is not valid. Titles must be unique and may not be 'n/a' or empty"
              , Element.none
              )
      in
      Element.layout
        [ Element.inFront cancel
        , Element.width Element.fill
        , Element.height Element.fill
        ] <|
        Element.column
          []
          [ Element.text <| getNote createModeInternal
          , Element.Input.multiline
            []
            { onChange = UpdateNewSourceTitle
            , text = title
            , placeholder = Nothing
            , label = Element.Input.labelAbove [] titleLabel
            , spellcheck = True
            }
          , Element.Input.multiline
            []
            { onChange = UpdateNewSourceAuthor
            , text = author
            , placeholder = Nothing
            , label = Element.Input.labelAbove [] <|
              Element.text "Author (not required)"
            , spellcheck = True
            }
          , Element.Input.multiline
            []
            { onChange = UpdateNewSourceContent
            , text = content
            , placeholder = Nothing
            , label = Element.Input.labelAbove [] <|
              Element.text "Content (not required)"
            , spellcheck = True
            }
          , submitNode
          ]

    PromptCreateAnother _ createModeInternal ->
      Element.layout
        [ Element.inFront cancel
        , Element.width Element.fill
        , Element.height Element.fill
        ] <|
        Element.column
          []
          [ Element.text "New Note is Created!"
          , Element.text <| getNote createModeInternal
          , Element.Input.button
            []
            { onPress = Just CreateAnotherNote
            , label = Element.text "Create Another Note?"
            }
          ]


cancel : Element Msg
cancel =
  Element.el
    [ Element.padding 8
    , Element.alignRight
    , Element.alignTop
    ] <|
    Element.Input.button
      []
      { onPress = Nothing
      , label = Element.text "cancel"
      }

coaching : CoachingModal -> Element Msg -> Element Msg
coaching modal text =
  let
    toggleCoachingButton =
      Element.Input.button
        [ Element.centerX
        , Element.Border.width 1
        , Element.Border.rounded 4
        , Element.padding 2
        ]
        { onPress = Just ToggleCoaching
        , label = Element.text "Coaching"
        }
  in
  case modal of
    CoachingModalClosed -> toggleCoachingButton
    CoachingModalOpen ->
      Element.column
        [ Element.spacingXY 8 8
        , Element.centerX
        ]
        [ toggleCoachingButton
        , text
        ]

questionTabularData : CreateModeInternal -> Slipbox.Slipbox -> List {read:Bool,question:String,note:Note.Note}
questionTabularData internal slipbox =
  let
    slipboxQuestions = Slipbox.getQuestions Nothing slipbox
    readQuestions = getQuestionsRead internal
    toQuestionRecord =
      \q ->
        { read = List.any ( Note.is q) readQuestions
        , question = Note.getContent q
        , note = q
        }
  in
  List.map toQuestionRecord slipboxQuestions

doneOrLinkModal : SelectedNote -> Note -> LinkModal -> Element Msg
doneOrLinkModal selectedNote createdNote bridgeModal =
  case bridgeModal of
    Closed ->
      Element.el
        [ Element.padding 8
        , Element.alignRight
        , Element.alignTop
        ] <|
        Element.Input.button
          []
          { onPress = Just ToChooseQuestion
          , label = Element.text "Done"
          }
    Open input ->
      linkModalView selectedNote createdNote input


linkModalView : Note.Note -> Note -> String -> Element Msg
linkModalView selectedNote createdNote input =
  let
    submitNode =
      if String.isEmpty input then
        Element.none
      else
        Element.Input.button
          []
          { onPress = Just CreateBridgeForSelectedNote
          , label = Element.text "Create Bridged Link with Note"
          }
  in
  Element.column
    [ Element.height Element.fill
    , Element.width Element.fill
    ]
    [ Element.row
      []
      [ Element.el [ Element.width Element.fill, Element.height Element.fill ]
        <| Element.text createdNote
      , Element.el [ Element.width Element.fill, Element.height Element.fill ]
        <| Element.text <| Note.getContent selectedNote
      ]
    , Element.Input.button
      []
      { onPress = Just CreateLinkForSelectedNote
      , label = Element.text "Create Link"}
    , Element.column
      []
      [ Element.Input.multiline
        []
        { onChange = UpdateNote
        , text = input
        , placeholder = Nothing
        , label = Element.Input.labelAbove [] <| Element.text "Note Content (required)"
        , spellcheck = True
        }
      , submitNode
      ]
    , Element.Input.button
      []
      { onPress = Just CancelCreateLink
      , label = Element.text "Cancel"
      }
    ]


linkCheckbox : SelectedNote -> LinksCreated -> Element Msg
linkCheckbox selectedNote linksCreated =
  let
    maybeLinkCreatedForSelectedNote = getLinkForSelectedNote selectedNote linksCreated
    (checked, bridgeNode) =
      case maybeLinkCreatedForSelectedNote of
        Just link ->
          case getBridgeNoteFromLink link of
            Just bridgeNote ->
              ( True
              , Element.text <| "Link Bridged With:" ++ bridgeNote
              )
            Nothing -> ( True, Element.none )
        Nothing -> ( False, Element.none )
  in
  Element.column
    []
    [ Element.Input.checkbox
      []
      { onChange = LinkCheckboxToggled
      , icon = Element.Input.defaultCheckbox
      , label = Element.Input.labelAbove [] <| Element.text "Link Options"
      , checked = checked
      }
    , bridgeNode
    ]

type GraphNote
  = Selected Note.Note X Y
  | Linked Note.Note X Y
  | Question Note.Note X Y
  | Regular Note.Note X Y

type alias X = String
type alias Y = String

toGraphNote : CreateModeInternal -> SelectedNote -> NotePosition -> GraphNote
toGraphNote internal selectedNote notePosition =
  let
    note = notePosition.note
    isSelectedNote = Note.is note selectedNote
    isQuestion = Note.getVariant note == Note.Question
    maybeHasLink = getLinkForSelectedNote note <| getCreatedLinks internal
    x = String.fromFloat notePosition.x
    y = String.fromFloat notePosition.y
  in
  if isSelectedNote then
    Selected note x y
  else
    if isQuestion then
      Question note x y
    else
      case maybeHasLink of
        Just _ -> Linked note x y
        Nothing -> Regular note x y

viewGraphNote : GraphNote -> Svg.Svg Msg
viewGraphNote graphNote =
  case graphNote of
    Selected note x y ->
      Svg.g
        [ Svg.Attributes.cx x
        , Svg.Attributes.cy y
        --, Svg.Attributes.r "5"
        --, Svg.Attributes.fill "rgba(137, 196, 244, 1)"
        , Svg.Attributes.cursor "Pointer"
        , Svg.Events.onClick <| SelectNote note
        ]
        [ starSvg
        ]

    Linked note x y ->
      Svg.g
        [ Svg.Attributes.cx x
        , Svg.Attributes.cy y
        --, Svg.Attributes.r "5"
        --, Svg.Attributes.fill "rgba(137, 196, 244, 1)"
        , Svg.Attributes.cursor "Pointer"
        , Svg.Events.onClick <| SelectNote note
        ]
        [ linkSvg
        ]

    Question note x y ->
      Svg.g
        [ Svg.Attributes.cx x
        , Svg.Attributes.cy y
        --, Svg.Attributes.r "5"
        --, Svg.Attributes.fill "rgba(137, 196, 244, 1)"
        , Svg.Attributes.cursor "Pointer"
        , Svg.Events.onClick <| SelectNote note
        ]
        [ questionSvg
        ]

    Regular note x y ->
      Svg.circle
        [ Svg.Attributes.cx x
        , Svg.Attributes.cy y
        , Svg.Attributes.r "5"
        , Svg.Attributes.fill "rgba(137, 196, 244, 1)"
        , Svg.Attributes.cursor "Pointer"
        , Svg.Events.onClick <| SelectNote note
        ]
        []



viewGraph : Graph -> CreateModeInternal -> Note.Note -> Element Msg
viewGraph graph createModeInternal selectedNote =
  Element.html <|
    Svg.svg
      [ Svg.Attributes.width "100%"
      , Svg.Attributes.height "100%"
      , Svg.Attributes.viewBox <| computeViewbox graph.positions
      ] <|
      List.concat
        [ List.filterMap (toGraphLink graph.positions) graph.links
        , List.map viewGraphNote <| List.map ( toGraphNote createModeInternal selectedNote ) graph.positions
        ]

type alias PositionExtremes =
  { minX : Float
  , minY : Float
  , maxX : Float
  , maxY : Float
  }

computeViewbox : ( List NotePosition ) -> String
computeViewbox notePositions =
  let
    xList = List.map (.x) notePositions
    yList = List.map (.y) notePositions
    maybeExtremes =
      Maybe.map4
        PositionExtremes
        ( List.minimum xList )
        ( List.minimum yList )
        ( List.maximum xList )
        ( List.maximum yList )
    padding = 25
  in
  case maybeExtremes of
    Just extremes ->
      formatViewbox
        { minX = extremes.minX - padding
        , minY = extremes.minY - padding
        , width = ( extremes.maxX - extremes.minX ) + ( padding * 2 )
        , height = ( extremes.maxY - extremes.minY ) + ( padding * 2 )
        }

    Nothing ->
      formatViewbox {minX=100,minY=100,width=100,height=100}

formatViewbox : { minX: Float, minY: Float, width: Float, height: Float} -> String
formatViewbox record =
  String.fromFloat record.minX
  ++ " " ++  String.fromFloat record.minY
  ++ " " ++  String.fromFloat record.width
  ++ " " ++  String.fromFloat record.height


toGraphLink: (List NotePosition) -> Link.Link -> ( Maybe ( Svg.Svg Msg ) )
toGraphLink notePositions link =
  let
    maybeGetNoteByIdentifier =
      \identifier ->
        List.head <|
          List.filter
          ( \notePosition ->
            identifier link notePosition.note
          )
          notePositions
  in
  Maybe.map2 svgLine (maybeGetNoteByIdentifier Link.isSource) (maybeGetNoteByIdentifier Link.isTarget)

svgLine : NotePosition -> NotePosition -> Svg.Svg Msg
svgLine note1 note2 =
  Svg.line
    [ Svg.Attributes.x1 <| String.fromFloat <| note1.x
    , Svg.Attributes.y1 <| String.fromFloat <| note1.y
    , Svg.Attributes.x2 <| String.fromFloat <| note2.x
    , Svg.Attributes.y2 <| String.fromFloat <| note2.y
    , Svg.Attributes.stroke "rgb(0,0,0)"
    , Svg.Attributes.strokeWidth "2"
    ]
    []

sourceInput: String -> (List String) -> Element Msg
sourceInput input suggestions =
  let
    sourceInputid = "Source: 1"
    dataitemId = "Sources: 2"
  in
    Element.html
      <| Html.div
        []
        [ Html.label
          [ Html.Attributes.for sourceInputid ]
          [ Html.text "Source: " ]
        , Html.input
          [ Html.Attributes.list dataitemId
          , Html.Attributes.name sourceInputid
          , Html.Attributes.id sourceInputid
          , Html.Attributes.value input
          , Html.Events.onInput ExistingSourceInputChanged
          ]
          []
        , Html.datalist
          [ Html.Attributes.id dataitemId ]
          <| List.map toHtmlOption suggestions
        ]

toHtmlOption: String -> Html.Html Msg
toHtmlOption value =
  Html.option [ Html.Attributes.value value ] []

-- ICONS
iconBuilder : FontAwesome.Icon.Icon -> Element Msg
iconBuilder icon =
  Element.el []
    <| Element.html
      <| FontAwesome.Icon.viewStyled
        [ FontAwesome.Attributes.fa2x
        , FontAwesome.Attributes.fw
        ]
        icon

starIcon = iconBuilder FontAwesome.Solid.star
starSvg = FontAwesome.Svg.viewIcon FontAwesome.Solid.star

linkIcon = iconBuilder FontAwesome.Solid.link
linkSvg = FontAwesome.Svg.viewIcon FontAwesome.Solid.link

questionIcon = iconBuilder FontAwesome.Solid.questionCircle
questionSvg = FontAwesome.Svg.viewIcon FontAwesome.Solid.questionCircle