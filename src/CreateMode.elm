module CreateMode exposing (..)

import Browser
import Element.Border
import FontAwesome.Attributes
import FontAwesome.Icon
import FontAwesome.Solid
import FontAwesome.Svg
import Link
import Slipbox
import Note
import Force
import Source
import Html
import Element exposing (Element)
import Element.Input
import Element.Font

-- MAIN

main =
  Browser.element { init = init, update = update, view = view, subscriptions = subscriptions }

-- MODEL

type Model
  = NoteInput CoachingModal Slipbox.Slipbox CreateModeInternal
  | ChooseQuestion CoachingModal Slipbox.Slipbox CreateModeInternal
  | FindLinksForQuestion CoachingModal Graph BridgeModal Slipbox.Slipbox CreateModeInternal Question SelectedNote
  | ChooseSourceCategory CoachingModal Slipbox.Slipbox CreateModeInternal
  | ChooseExistingSource CoachingModal Slipbox.Slipbox CreateModeInternal
  | CreateNewSource CoachingModal Slipbox.Slipbox CreateModeInternal
  | PromptCreateAnotherOrFinish Slipbox.Slipbox CreateModeInternal

type alias Question = Note.Note
type alias SelectedNote = Note.Note

getCoachingModal : Model -> ( Maybe CoachingModal )
getCoachingModal model =
  case model of
    NoteInput coachingModal _ _ -> Just coachingModal
    ChooseQuestion coachingModal _ _ -> Just coachingModal
    FindLinksForQuestion coachingModal _ _ _ _ _ _ -> Just coachingModal
    ChooseSourceCategory coachingModal _ _ -> Just coachingModal
    ChooseExistingSource coachingModal _ _ -> Just coachingModal
    CreateNewSource coachingModal _ _ -> Just coachingModal
    PromptCreateAnotherOrFinish _ _ -> Nothing

setCoachingModal : CoachingModal -> Model -> Model
setCoachingModal coachingModal model =
   case model of
     NoteInput _ slipbox internal -> NoteInput coachingModal slipbox internal
     ChooseQuestion _ slipbox internal -> ChooseQuestion coachingModal slipbox internal
     FindLinksForQuestion _ graph bridgeModal slipbox internal question selectedNote ->
      FindLinksForQuestion coachingModal graph bridgeModal slipbox internal question selectedNote
     ChooseSourceCategory _ slipbox internal -> ChooseSourceCategory coachingModal slipbox internal
     ChooseExistingSource _ slipbox internal -> ChooseExistingSource coachingModal slipbox internal
     CreateNewSource _ slipbox internal -> CreateNewSource coachingModal slipbox internal
     PromptCreateAnotherOrFinish _ _ -> model

getInternal : Model -> CreateModeInternal
getInternal model =
  case model of
    NoteInput _ _ createModeInternal -> createModeInternal
    ChooseQuestion _ _ createModeInternal -> createModeInternal
    FindLinksForQuestion _ _ _ _ createModeInternal _ _ -> createModeInternal
    ChooseSourceCategory _ _ createModeInternal -> createModeInternal
    ChooseExistingSource _ _ createModeInternal -> createModeInternal
    CreateNewSource _ _ createModeInternal -> createModeInternal
    PromptCreateAnotherOrFinish _ createModeInternal -> createModeInternal

setInternal : CreateModeInternal -> Model -> Model
setInternal createModeInternal model =
  case model of
    NoteInput coachingModal slipbox _ -> NoteInput coachingModal slipbox createModeInternal
    ChooseQuestion coachingModal slipbox _ -> ChooseQuestion coachingModal slipbox createModeInternal
    FindLinksForQuestion coachingModal graph bridgeModal slipbox _ question selectedNote ->
      FindLinksForQuestion coachingModal graph bridgeModal slipbox createModeInternal question selectedNote
    ChooseSourceCategory coachingModal slipbox _ -> ChooseSourceCategory coachingModal slipbox createModeInternal
    ChooseExistingSource coachingModal slipbox _ -> ChooseExistingSource coachingModal slipbox createModeInternal
    CreateNewSource coachingModal slipbox _ -> CreateNewSource coachingModal slipbox createModeInternal
    PromptCreateAnotherOrFinish slipbox _ -> PromptCreateAnotherOrFinish slipbox createModeInternal

nextStep : Model -> Model
nextStep model =
  case model of
    NoteInput coachingModal slipbox createModeInternal -> ChooseQuestion coachingModal slipbox createModeInternal
    ChooseQuestion coachingModal slipbox createModeInternal -> ChooseSourceCategory coachingModal slipbox createModeInternal
    _ -> model
    --FindLinksForQuestion coachingModal graph bridgeModal slipbox createModeInternal ->
    --ChooseSourceCategory coachingModal slipbox createModeInternal ->
    --ChooseExistingSource coachingModal slipbox createModeInternal ->
    --CreateNewSource coachingModal slipbox createModeInternal ->
    --PromptCreateAnotherOrFinish slipbox createModeInternal ->


-- CREATEMODEINTERNAL
type CreateModeInternal
  = CreateModeInternal Note QuestionsRead LinksCreated Source

type Source
  = None
  | New Title Author Content
  | Existing Source.Source

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

type alias Note = String
-- TODO: This data structure allows for duplicate questions, is that okay?
-- We can prevent this with logic but perhaps a set would be a better structure
type alias QuestionsRead = ( List Note.Note )

type alias LinksCreated = ( List Link )

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

type BridgeModal
  = Closed
  | Open Note.Note Note String

openBridgeModal : Note.Note -> Note -> String -> BridgeModal
openBridgeModal selectedNote writtenNote bridgeNote =
  Open selectedNote writtenNote bridgeNote

bridgeModalIsClosed : BridgeModal -> Bool
bridgeModalIsClosed bridgeModal =
  case bridgeModal of
    Closed -> True
    Open _ _ _ -> False



-- TODO: Do I need to include links in here as well to represent them on the graph?
type alias Graph =
  { positions :  List NotePositions
  , links : List Link.Link
  }

type alias NotePositions =
  { id : Int
  , note : Note.Note
  , x : Float
  , y : Float
  , vx : Float
  , vy : Float
  }

-- INIT
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
  | OpenBridgeModalForSelectedNote

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
        FindLinksForQuestion _ _ _ _ createModeInternal _ selectedNote ->
          ( setInternal ( createLink selectedNote createModeInternal ) model
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    OpenBridgeModalForSelectedNote ->
      case model of
        FindLinksForQuestion coachingModal graph bridgeModal slipbox createModeInternal question selectedNote ->
          let
            maybeBridgeNote =
              getLinkForSelectedNoteIfBridge selectedNote <|
                getCreatedLinks createModeInternal
            updatedBridgeModal =
              if bridgeModalIsClosed bridgeModal then
                case maybeBridgeNote of
                  Just bridgeNote ->
                    openBridgeModal selectedNote ( getNote createModeInternal ) bridgeNote
                  Nothing ->
                    openBridgeModal selectedNote ( getNote createModeInternal ) ""
              else
                bridgeModal
          in
          ( FindLinksForQuestion coachingModal graph updatedBridgeModal slipbox createModeInternal question selectedNote
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

simulatePositions : ( List Note.Note, List Link.Link ) -> ( List NotePositions, List Link.Link )
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

    FindLinksForQuestion coachingModal graph bridgeModal slipbox createModeInternal question selectedNote ->
      Element.layout
        [ Element.inFront <| doneOrBridgeModal bridgeModal
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
              , radioOptionNode selectedNote <| getCreatedLinks createModeInternal
              ]
            ]
          , Element.column
            [ Element.width biggerElement
            , Element.height Element.fill
            ]
            [ graph
            , Element.row
              [ legend
              , coaching
              ]
            ]
          ]

    _ -> Html.div [] []
    --
    --ChooseSourceCategory coachingModal slipbox createModeInternal ->
    --
    --
    --ChooseExistingSource coachingModal slipbox createModeInternal ->
    --
    --
    --CreateNewSource coachingModal slipbox createModeInternal ->
    --
    --
    --PromptCreateAnotherOrFinish slipbox createModeInternal ->

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

doneOrBridgeModal : BridgeModal -> Element Msg
doneOrBridgeModal bridgeModal =
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

    Open selectedNote createdNote input ->
      let
        submitNode =
          if String.isEmpty input then
            Element.none
          else
            Element.Input.button
              []
              -- TODO
              { onPress = Nothing
              , label = Element.text "Create Bridge Note"
              }
      in
      Element.column
        [ Element.height Element.fill
        , Element.width Element.fill
        ]
        [ instructions
        , Element.row
          []
          [ Element.el [ Element.width Element.fill, Element.height Element.fill ]
            <| Element.text createdNote
          , Element.el [ Element.width Element.fill, Element.height Element.fill ]
            <| Element.text <| Note.getContent selectedNote
          ]
        , Element.Input.multiline
          []
          { onChange = UpdateNote
          , text = input
          , placeholder = Nothing
          , label = Element.Input.labelAbove [] <| Element.text "Note Content (required)"
          , spellcheck = True
          }
        , Element.row
          []
          [ discard
          , submitNode
          ]
        ]

type LinkRadioOption
  = CreateLink
  | OpenBridgeModal

radioOptionNode : SelectedNote -> LinksCreated -> Element Msg
radioOptionNode selectedNote linksCreated =
  let
    maybeLinkCreatedForSelectedNote = getLinkForSelectedNote selectedNote linksCreated
    (selected, bridgeNode) =
      case maybeLinkCreatedForSelectedNote of
        Just link ->
          case getBridgeNoteFromLink link of
            Just bridgeNote ->
              ( Just OpenBridgeModal
              , Element.text bridgeNote
              )
            Nothing -> ( Just CreateLink, Element.none )
        Nothing -> ( Nothing, Element.none )
  in
  Element.column
    []
    [ Element.Input.radio
      []
      { onChange =
        ( \option ->
          case option of
            CreateLink -> CreateLinkForSelectedNote
            OpenBridgeModal -> OpenBridgeModalForSelectedNote
        )
      , label = Element.Input.labelAbove [] <| Element.text "Link Options"
      , options =
        [ Element.Input.option CreateLink <| Element.text "Directly Link"
        , Element.Input.option OpenBridgeModal <| Element.text "Link with a Bridge note"
        ]
      , selected = selected
      }
    , bridgeNode
    ]

legend : Element Msg
legend =
  Element.wrappedRow
    []
    [ Element.row
      []
      [ starIcon
      , Element.text "Currently Selected Note"
      ]
    , Element.row
      []
      [ linkIcon
      , Element.text "Note Marked to link"
      ]
    ]

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