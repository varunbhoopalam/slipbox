port module Main exposing (..)

import Browser
import Browser.Events
import Browser.Navigation
import Color
import Create
import Element.Background
import Element.Border
import Element.Events
import Element.Font
import Element.Input
import File.Download
import FontAwesome.Attributes
import FontAwesome.Solid
import FontAwesome.Svg
import Html
import Html.Events
import Html.Attributes
import Link
import Slipbox
import Svg
import Svg.Events
import Svg.Attributes
import Element exposing (Element)
import Json.Decode
import Time
import Tutorial
import Viewport
import Browser.Dom
import Url
import Task
import Note
import Source
import Item
import File
import File.Select
import FontAwesome.Icon
import FontAwesome.Styles


-- MAIN
main =
  Browser.application
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    , onUrlRequest = LinkClicked
    , onUrlChange = UrlChanged
    }

-- MODEL

type alias Model =
  { state: State 
  , deviceViewport: ( Int, Int )
  }

updateTab : Tab -> Model -> Model
updateTab tab model =
  case model.state of
    Session content ->
      let
        state = Session { content | tab = tab }
      in
      { model | state = state }
    _ -> model

setSlipbox : Slipbox.Slipbox -> Model -> Model
setSlipbox slipbox model =
  case model.state of
    Session content ->
      let
        state = Session { content | slipbox = slipbox }
      in
      { model | state = state }
    _ -> model

getSlipbox : Model -> ( Maybe Slipbox.Slipbox )
getSlipbox model =
  case model.state of
    Session content -> Just content.slipbox
    _ -> Nothing

getCreate : Model -> Maybe Create.Create
getCreate model =
  case model.state of
    Session content ->
      case content.tab of
        CreateModeTab create -> Just create
        _ -> Nothing
    _ -> Nothing

setCreate : Create.Create -> Model -> Model
setCreate create model =
  case model.state of
    Session content ->
      case content.tab of
        CreateModeTab _ ->
          let
            state = Session { content | tab = CreateModeTab create }
          in
          { model | state = state }
        _ -> model
    _ -> model


type State 
  = Setup 
  | FailureToParse
  | Session Content
  | Tutorial Tutorial.Tutorial

-- CONTENT
type alias Content = 
  { tab: Tab
  , slipbox: Slipbox.Slipbox
  , sideNavState: SideNavState
  }

type SideNavState = Expanded | Contracted

toggle : SideNavState -> SideNavState
toggle state =
  case state of
    Expanded -> Contracted
    Contracted -> Expanded

-- TAB
type Tab
  = BrainTab String Viewport.Viewport
  | NotesTab String
  | SourcesTab String
  | WorkspaceTab
  | QuestionsTab String
  | CreateModeTab Create.Create

type Tab_
  = Brain
  | Workspace
  | Notes
  | Sources
  | Questions
  | CreateMode

-- INIT

init : () -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init _ _ _ =
  ( Model Setup ( 0, 0 )
  , Cmd.batch [ getViewport ]
  )

getViewport: Cmd Msg
getViewport = Task.perform GotViewport Browser.Dom.getViewport

-- UPDATE
type Msg
  = LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url
  | ExploreTabUpdateInput String
  | NoteTabUpdateInput String
  | SourceTabUpdateInput String
  | AddItem ( Maybe Item.Item ) Slipbox.AddAction
  | UpdateItem Item.Item Slipbox.UpdateAction
  | DismissItem Item.Item
  | CompressNote Note.Note
  | ExpandNote Note.Note
  | StartMoveView Viewport.MouseEvent
  | MoveView Viewport.MouseEvent
  | StopMoveView
  | GotViewport Browser.Dom.Viewport
  | GotWindowResize ( Int, Int )
  | InitializeNewSlipbox
  | FileRequested
  | FileRequestedTutorial
  | FileSelectedTutorial File.File
  | FileLoaded String
  | FileSaved Int
  | FileDownload
  | Tick Time.Posix
  | ChangeTab Tab_
  | ToggleSideNav
  | StartTutorial
  | ContinueTutorialAndDownloadFile String
  | ContinueTutorial
  | SkipTutorial
  | UpdateInputTutorial Tutorial.UpdateAction
  | EndTutorial
  | CreateTabToggleCoaching
  | CreateTabNextStep
  | CreateTabToFindLinksForQuestion Note.Note
  | CreateTabToChooseQuestion
  | CreateTabCreateLinkForSelectedNote
  | CreateTabCreateBridgeForSelectedNote
  | CreateTabToggleLinkModal
  | CreateTabRemoveLink
  | CreateTabSelectNote Note.Note
  | CreateTabContinueWithSelectedSource Source.Source
  | CreateTabNoSource
  | CreateTabNewSource
  | CreateTabSubmitNewSource
  | CreateTabUpdateInput Create.Input
  | CreateTabCreateAnotherNote

update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  let
    updateSlipboxWrapper = \s -> case getSlipbox model of
       Just slipbox ->
         ( setSlipbox (s slipbox) model, Cmd.none )
       _ -> ( model, Cmd.none)
    updateExploreTabViewportLambda = \toViewport ->
      case model.state of
        Session content ->
          case content.tab of
            BrainTab input viewport ->
              ({ model | state = Session
                { content | tab =
                  BrainTab input (toViewport viewport)
                }
              }, Cmd.none )
            _ -> ( model, Cmd.none )
        _ -> ( model , Cmd.none)

    createModeLambda createUpdate =
      case getCreate model of
        Just create ->
          ( setCreate
            ( createUpdate create )
            model
          , Cmd.none
          )
        Nothing -> ( model, Cmd.none )
    createModeAndSlipboxLambda createUpdate =
      case getSlipbox model of
        Just slipbox ->
          case getCreate model of
            Just create ->
              let
                ( updatedSlipbox, updatedCreate ) = createUpdate slipbox create
              in
              ( setCreate updatedCreate model |> setSlipbox updatedSlipbox
              , Cmd.none
              )
            Nothing -> ( model, Cmd.none )
        Nothing -> ( model, Cmd.none )
  in
  case message of
    
    LinkClicked _ -> (model, Cmd.none)

    UrlChanged _ -> (model, Cmd.none)

    ExploreTabUpdateInput input ->
      case model.state of
        Session content ->
          case content.tab of
            BrainTab _ viewport ->
              ( updateTab ( BrainTab input viewport ) model, Cmd.none )
            _ -> ( model, Cmd.none)
        _ -> ( model, Cmd.none)

    NoteTabUpdateInput input ->
      case model.state of
        Session content ->
          case content.tab of
            NotesTab _ ->
              ( updateTab ( NotesTab input ) model, Cmd.none )
            _ -> ( model, Cmd.none)
        _ -> ( model, Cmd.none)
    
    SourceTabUpdateInput input ->
      case model.state of
        Session content ->
          case content.tab of
            SourcesTab _ ->
              ( updateTab ( SourcesTab input ) model, Cmd.none )
            _ -> ( model, Cmd.none)
        _ -> ( model, Cmd.none)

    AddItem maybeItem addAction ->
      let
         modelWithUpdatedTab = updateTab WorkspaceTab model
         addItemToSlipboxLambda = Slipbox.addItem maybeItem addAction
      in
      case getSlipbox model of
        Just slipbox ->
          ( setSlipbox ( addItemToSlipboxLambda slipbox ) modelWithUpdatedTab
          , Cmd.none
          )
        _ -> ( model, Cmd.none)

    CompressNote note -> updateSlipboxWrapper <| Slipbox.compressNote note

    ExpandNote note -> updateSlipboxWrapper <| Slipbox.expandNote note

    UpdateItem item updateAction -> updateSlipboxWrapper <| Slipbox.updateItem item updateAction

    DismissItem item -> updateSlipboxWrapper <| Slipbox.dismissItem item

    StartMoveView mouseEvent -> updateExploreTabViewportLambda <| Viewport.startMove mouseEvent
    
    MoveView mouseEvent ->
      case getSlipbox model of
        Just slipbox -> updateExploreTabViewportLambda <| Viewport.move mouseEvent ( Slipbox.getNotes Nothing slipbox )
        Nothing -> ( model, Cmd.none )
    
    StopMoveView -> updateExploreTabViewportLambda Viewport.stopMove
    
    GotViewport viewport ->
      let
        windowInfo = ( round viewport.viewport.width, round viewport.viewport.height )
      in
      ( handleWindowInfo windowInfo model, Cmd.none )

    GotWindowResize windowInfo -> (handleWindowInfo windowInfo model, Cmd.none)

    InitializeNewSlipbox ->
      case model.state of
        Setup ->
          ({ model | state = Session <| newContent model.deviceViewport }, Cmd.none)
        _ -> ( model, Cmd.none )

    FileRequested ->
      case model.state of
        Setup -> ( model, open () )
        _ -> ( model, Cmd.none )

    FileRequestedTutorial ->
      case model.state of
        Tutorial _ -> ( model, File.Select.file ["application/json"] FileSelectedTutorial )
        _ -> ( model, Cmd.none )

    FileSelectedTutorial _ -> update ContinueTutorial model

    FileLoaded fileContentAsString ->
      case model.state of
        Setup ->
          let
            maybeSlipbox = Json.Decode.decodeString Slipbox.decode fileContentAsString
          in
          case maybeSlipbox of
            Ok slipbox ->
              ({ model | state = Session <| Content ( BrainTab "" Viewport.initialize ) slipbox Expanded }
              , Cmd.none
              )
            Err _ -> ( { model | state = FailureToParse }, Cmd.none )
        _ -> ( model, Cmd.none )

    FileSaved _ ->
      case getSlipbox model of
        Just slipbox ->
          ( setSlipbox ( Slipbox.saveChanges slipbox ) model
          , Cmd.none
          )
        Nothing -> ( model, Cmd.none )

    FileDownload ->
      case getSlipbox model of
        Just slipbox ->
          ( model
          , save <| Slipbox.encode slipbox
          )
        Nothing -> ( model, Cmd.none )

    Tick _ ->
      case getSlipbox model of
        Just slipbox ->
          if not <| Slipbox.simulationIsCompleted slipbox then
            ( setSlipbox ( Slipbox.tick slipbox ) model, Cmd.none )
          else
            ( model, Cmd.none )
        _ -> ( model, Cmd.none )

    ChangeTab tab ->
      case model.state of
        Session content ->
          case tab of
            Brain ->
              case content.tab of
                BrainTab _ _ -> ( model, Cmd.none )
                _ ->
                  ( { model | state =
                    Session { content | tab = BrainTab "" Viewport.initialize }
                    }
                  , Cmd.none
                  )
            Notes ->
              case content.tab of
                NotesTab _ -> ( model, Cmd.none )
                _ ->
                  ( { model | state =
                    Session { content | tab = NotesTab "" }
                    }
                  , Cmd.none
                  )
            Sources ->
              case content.tab of
                SourcesTab _ -> ( model, Cmd.none )
                _ ->
                  ( { model | state =
                    Session { content | tab = SourcesTab "" }
                    }
                  , Cmd.none
                  )

            Workspace ->
              ( updateTab WorkspaceTab model, Cmd.none )

            Questions ->
              case content.tab of
                QuestionsTab _ -> ( model, Cmd.none )
                _ ->
                  ( { model | state =
                    Session { content | tab = QuestionsTab "" }
                    }
                  , Cmd.none
                  )

            CreateMode ->
              case content.tab of
                CreateModeTab _ -> ( model, Cmd.none )
                _ ->
                  ( { model | state =
                    Session { content | tab = CreateModeTab Create.init }
                    }
                  , Cmd.none
                  )

        _ -> ( model, Cmd.none )

    ToggleSideNav ->
      case model.state of
        Session content ->
          ( { model | state = ( Session { content | sideNavState = toggle content.sideNavState } ) }
          , Cmd.none
          )

        _ -> ( model, Cmd.none )

    StartTutorial ->
      case model.state of
        Setup ->
          ( { model | state = Tutorial Tutorial.init }
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    ContinueTutorialAndDownloadFile jsonFile ->
      case model.state of
        Tutorial tutorial ->
          ( { model | state = Tutorial <| Tutorial.continue tutorial }
          , File.Download.string "slipbox.json" "application/json" jsonFile
          )
        _ -> ( model, Cmd.none )


    ContinueTutorial ->
      case model.state of
        Tutorial tutorial ->
          ( { model | state = Tutorial <| Tutorial.continue tutorial }
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    SkipTutorial ->
      case model.state of
        Tutorial tutorial ->
          ( { model | state = Tutorial <| Tutorial.skip tutorial }
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    UpdateInputTutorial action ->
      case model.state of
        Tutorial tutorial ->
          ( { model | state = Tutorial <| Tutorial.update action tutorial }
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    EndTutorial ->
      case model.state of
        Tutorial tutorial ->
          ( { model | state = Session <| Content
            ( BrainTab "" Viewport.initialize )
            ( Tutorial.end tutorial )
            Expanded
            }
          , Cmd.none
          )
        _ -> ( model, Cmd.none )

    CreateTabToggleCoaching -> createModeLambda Create.toggleCoachingModal
    CreateTabNextStep -> createModeLambda Create.next
    CreateTabToFindLinksForQuestion question ->
      case getSlipbox model of
        Just slipbox -> createModeLambda <| Create.toAddLinkState question slipbox
        Nothing -> ( model, Cmd.none )
    CreateTabToChooseQuestion -> createModeLambda Create.toChooseQuestionState
    CreateTabCreateLinkForSelectedNote -> createModeLambda Create.createLink
    CreateTabCreateBridgeForSelectedNote -> createModeLambda Create.createBridge
    CreateTabToggleLinkModal -> createModeLambda Create.toggleLinkModal
    CreateTabRemoveLink -> createModeLambda Create.removeLink
    CreateTabSelectNote newSelectedNote -> createModeLambda <| Create.selectNote newSelectedNote
    CreateTabUpdateInput input -> createModeLambda <| Create.updateInput input
    CreateTabContinueWithSelectedSource source -> createModeAndSlipboxLambda <| Create.selectSource source
    CreateTabNoSource -> createModeAndSlipboxLambda Create.noSource
    CreateTabNewSource -> createModeLambda Create.newSource
    CreateTabSubmitNewSource -> createModeAndSlipboxLambda Create.submitNewSource
    CreateTabCreateAnotherNote -> createModeLambda (\c -> Create.init)


newContent : ( Int, Int ) -> Content
newContent deviceViewport =
  Content
    (BrainTab "" Viewport.initialize )
    Slipbox.new
    Expanded

handleWindowInfo: ( Int, Int ) -> Model -> Model
handleWindowInfo windowInfo model = 
  case model.state of
    Session content ->
      case content.tab of
        BrainTab input viewport ->
          { model | deviceViewport = windowInfo
          , state = Session { content | tab =
            BrainTab input <| Viewport.updateSvgContainerDimensions windowInfo viewport
            }
          }
        _ -> { model | deviceViewport = windowInfo }
    _ -> { model | deviceViewport = windowInfo }

-- PORTS

port open : () -> Cmd msg
port save : String -> Cmd msg
port fileContent : (String -> msg) -> Sub msg
port fileSaved : (Int -> msg) -> Sub msg

-- SUBSCRIPTIONS
subscriptions: Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Browser.Events.onResize (\w h -> GotWindowResize (w,h))
    , maybeSubscribeOnAnimationFrame model
    , fileContent FileLoaded
    , fileSaved FileSaved
    ]

maybeSubscribeOnAnimationFrame : Model -> Sub Msg
maybeSubscribeOnAnimationFrame model =
  case model.state of
    Session content ->
      case content.tab of
        BrainTab _ _ ->
          if Slipbox.simulationIsCompleted content.slipbox then
            Sub.none
          else
            Browser.Events.onAnimationFrame Tick
        _ -> Sub.none
    _ -> Sub.none

-- VIEW
version = 0.1
versionString = "0.1"
webpageTitle = "Slipbox " ++ versionString
smallerElement = Element.fillPortion 1000
biggerElement = Element.fillPortion 1618

view: Model -> Browser.Document Msg
view model =
  case model.state of
    Setup -> { title = webpageTitle , body = [ setupView model.deviceViewport ] }
    FailureToParse -> { title = webpageTitle, body = [ Element.layout [] <| Element.text "Failure" ] }
    Session content -> { title = webpageTitle, body = [ sessionView model.deviceViewport content ] }
    Tutorial tutorial -> { title = webpageTitle, body = [ tutorialView tutorial ] }

type Highlight
  = ShouldHighlight String Msg
  | ShouldNotHighlight

leftNavTutorialButtonLambda : Element.Attribute Msg -> Element Msg -> String -> Highlight -> Element Msg
leftNavTutorialButtonLambda alignment icon text highlight =
  let
    buttonAttributes =
      [ Element.width Element.fill
      , Element.height Element.fill
      , Element.Border.rounded 10
      , Element.padding 1
      ]
    fadedAttributes =
      [ Element.alpha 0.5
      ]
    highlightedAttributes =
      \labelText ->
        Element.onRight
          <| Element.el
            [ Element.centerY ]
            <| Element.text labelText

  in
  case highlight of
    ShouldHighlight labelText msg ->
      Element.el
        ( highlightedAttributes labelText ::
        [ Element.width Element.fill
        , alignment
        ]
        )
        <| Element.Input.button
          ( Element.Border.glow Color.yellow 2 :: buttonAttributes )
          { onPress = Just msg
          , label =
            Element.row
              [ Element.spacingXY 16 0]
              [ icon
              , Element.text text
              ]
          }

    ShouldNotHighlight ->
      Element.el
        [ Element.width Element.fill
        , alignment
        ]
        <| Element.Input.button
          ( List.concat [ buttonAttributes, fadedAttributes ] )
          { onPress = Nothing
          , label =
            Element.row
              [ Element.spacingXY 16 0]
              [ icon
              , Element.text text
              ]
          }

paddingBottom = {bottom = 16, top = 0, right = 0, left = 0}

type HighlightTutorialNav
  = HighlightCreateNote
  | HighlightCreateSource
  | HighlightCreateQuestion
  | HighlightSaveButton String
  | NoHighlights

leftNavTutorial : HighlightTutorialNav -> Element.Element Msg
leftNavTutorial highlights =
  let
    iconWidth = Element.width <| Element.px 35
    iconHeight = Element.width <| Element.px 40
    emptyIcon = Element.el [ iconWidth, iconHeight ] Element.none
    createNoteHighlight =
      case highlights of
        HighlightCreateNote -> ( ShouldHighlight " <- Click create note to get started!" ContinueTutorial )
        HighlightCreateSource -> ShouldNotHighlight
        HighlightCreateQuestion -> ShouldNotHighlight
        HighlightSaveButton _ -> ShouldNotHighlight
        NoHighlights -> ShouldNotHighlight
    createSourceHighlight =
      case highlights of
        HighlightCreateNote -> ShouldNotHighlight
        HighlightCreateSource -> ( ShouldHighlight " <- Click create source to add a source!" ContinueTutorial )
        HighlightCreateQuestion -> ShouldNotHighlight
        HighlightSaveButton _ -> ShouldNotHighlight
        NoHighlights -> ShouldNotHighlight
    createQuestionHighlight =
      case highlights of
        HighlightCreateNote -> ShouldNotHighlight
        HighlightCreateSource -> ShouldNotHighlight
        HighlightCreateQuestion -> ( ShouldHighlight " <- Click create question to converse with your brain!" ContinueTutorial )
        HighlightSaveButton _ -> ShouldNotHighlight
        NoHighlights -> ShouldNotHighlight
    saveButtonHighlight =
      case highlights of
        HighlightCreateNote -> ShouldNotHighlight
        HighlightCreateSource -> ShouldNotHighlight
        HighlightCreateQuestion -> ShouldNotHighlight
        HighlightSaveButton jsonFile -> ( ShouldHighlight " <- Click here to save!" <| ContinueTutorialAndDownloadFile jsonFile )
        NoHighlights -> ShouldNotHighlight

  in
  Element.column
    [ Element.height Element.fill
    , Element.padding 8
    , Element.spacingXY 0 8
    ]
    [ Element.column
      [ Element.height smallerElement
      , Element.width Element.fill
      , Element.spacingXY 0 8
      ]
      [ Element.row
        [ Element.width Element.fill
        , Element.spacingXY 16 0
        ]
        [ emptyIcon
        , Element.el [ Element.centerY, Element.alignLeft ]
          <| Element.text webpageTitle
        ]
      , Element.row
        [ Element.width Element.fill
        , Element.spacingXY 16 0
        ]
        [ emptyIcon
        , Element.el [ Element.centerY, Element.alignLeft ] aboutButton
        ]
      , leftNavTutorialButtonLambda Element.alignBottom saveIcon "Save" saveButtonHighlight
      , leftNavTutorialButtonLambda Element.alignBottom plusIcon "Create Note" createNoteHighlight
      , leftNavTutorialButtonLambda Element.alignBottom newspaperIcon "Create Source" createSourceHighlight
      , leftNavTutorialButtonLambda Element.alignBottom handPaperIcon "Create Question" createQuestionHighlight
      ]
    , Element.column
      [ Element.height biggerElement
      , Element.width Element.fill
      , Element.spacingXY 0 8
      ]
      [ leftNavTutorialButtonLambda Element.alignLeft brainIcon "Brain" ShouldNotHighlight
      , leftNavTutorialButtonLambda Element.alignLeft toolsIcon "Workspace" ShouldNotHighlight
      , leftNavTutorialButtonLambda Element.alignLeft fileAltIcon "Notes" ShouldNotHighlight
      , leftNavTutorialButtonLambda Element.alignLeft scrollIcon "Sources" ShouldNotHighlight
      , leftNavTutorialButtonLambda Element.alignLeft questionIcon "Questions" ShouldNotHighlight
      ]
    ]

setupOverlayTutorial : Element Msg
setupOverlayTutorial =
  let
    xButton =
      Element.el
        [ Element.width Element.fill
        , Element.alpha 0.5
        ]
        <| Element.Input.button
          [ Element.alignRight, Element.moveLeft 2]
          { onPress = Nothing, label = Element.text "x" }
    buttonBuilder =
      \func ->
        Element.Input.button
          [ Element.centerX, Element.centerY ]
          func

  in
  Element.el
    [ Element.height Element.fill
    , Element.width Element.fill
    , Element.padding barHeight
    ]
    <| Element.el
      [ Element.width <| Element.px 350
      , Element.height <| Element.px 150
      , Element.centerX
      , Element.centerY
      , Element.Border.width 1
      , Element.Background.color Color.white
      , Element.inFront xButton
      , Element.paddingXY 0 16
      ]
      <| Element.row
        [ Element.height Element.fill
        , Element.width Element.fill
        ]
        [ Element.el
          [ Element.height Element.fill
          , Element.width Element.fill
          , Element.Border.widthEach {right=1,top=0,bottom=0,left=0}
          ]
          <| buttonBuilder
            { onPress = Nothing
            , label = Element.el [ Element.centerX, Element.Font.underline, Element.alpha 0.5 ] <| Element.text "Start New"
            }
        , Element.el
          [ Element.height Element.fill
          , Element.width Element.fill
          , Element.Border.glow Color.yellow 1
          ]
          <| buttonBuilder
            { onPress = Just FileRequestedTutorial
            , label = Element.el [ Element.centerX, Element.Font.underline ] <| Element.text "Load Slipbox"
            }
        ]

finishTutorialButton : Element Msg
finishTutorialButton =
  Element.Input.button
    [ Element.alignRight ]
    { onPress = Just EndTutorial
    , label = Element.el [] <| Element.text "Finish Tutorial"
    }

tutorialView : Tutorial.Tutorial -> Html.Html Msg
tutorialView tutorial =
  layoutWithFontAwesomeStyles <| case Tutorial.getStep tutorial of
    Tutorial.Intro ->
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial HighlightCreateNote
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ finishTutorialButton
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "Welcome to Slipbox!"
          , Element.el [ Element.centerX, Element.Font.bold ]
            <| Element.text "We're going to build your second brain one note at a time."
          ]
        ]


    Tutorial.CreateFirstNote firstNoteContent ->
      let
        continueNode =
          if Tutorial.canContinue tutorial then
            Element.Input.button
              [ Element.Border.width 1
              , Element.padding 3
              , Element.centerX
              ]
              { onPress = Just ContinueTutorial
              , label = Element.el [] <| Element.text "Continue ->"
              }
          else
            Element.el [ Element.height <| Element.px 28 ] Element.none
      in
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial NoHighlights
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ finishTutorialButton
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "What is one thing you've learned recently?"
          , Element.Input.multiline
            []
            { onChange = (\s -> UpdateInputTutorial <| Tutorial.Content s )
            , text = firstNoteContent
            , placeholder = Just <| Element.Input.placeholder [] <| Element.text "Add your knowledge here!"
            , label = Element.Input.labelAbove [] <| Element.text "Content (required)"
            , spellcheck = True
            }
          , continueNode
          ]
        ]


    Tutorial.PromptAddSourceToNote firstNoteContent ->
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial HighlightCreateSource
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ finishTutorialButton
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "Awesome Note!"
          , Element.el [ Element.centerX, Element.paddingEach paddingBottom ]
            <| Element.text "Do you remember where you learned it?"
          , Element.el [ Element.centerX ] <| Element.text firstNoteContent
          , Element.Input.button
            [ Element.Border.width 1
            , Element.padding 3
            , Element.centerX
            ]
            { onPress = Just SkipTutorial
            , label = Element.el [] <| Element.text "I don't have a source ->"
            }
          ]
        ]

    Tutorial.SourceInput firstNoteContent title author sourceContent ->
      let
        continueNode =
          if Tutorial.canContinue tutorial then
            Element.Input.button
              [ Element.Border.width 1
              , Element.padding 3
              , Element.centerX
              ]
              { onPress = Just ContinueTutorial
              , label = Element.el [] <| Element.text "Continue ->"
              }
          else
            Element.el [ Element.height <| Element.px 28 ] Element.none
      in
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial NoHighlights
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ finishTutorialButton
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "Add more information about this note's source!"
          , Element.el [ Element.centerX ] <| Element.text firstNoteContent
          , Element.Input.multiline
            []
            { onChange = (\s -> UpdateInputTutorial <| Tutorial.Title s )
            , text = title
            , placeholder = Just <| Element.Input.placeholder [] <| Element.text "Put the source's name here!"
            , label = Element.Input.labelAbove [] <| Element.text "Title (required)"
            , spellcheck = True
            }
          , Element.Input.multiline
            []
            { onChange = (\s -> UpdateInputTutorial <| Tutorial.Author s )
            , text = author
            , placeholder = Just <| Element.Input.placeholder [] <| Element.text "Put the source's creator here!"
            , label = Element.Input.labelAbove [] <| Element.text "Author (optional)"
            , spellcheck = True
            }
          , Element.Input.multiline
            []
            { onChange = (\s -> UpdateInputTutorial <| Tutorial.Content s )
            , text = sourceContent
            , placeholder = Just <| Element.Input.placeholder [] <| Element.text "Put any other information about the source here!"
            , label = Element.Input.labelAbove [] <| Element.text "Content (optional)"
            , spellcheck = True
            }
          , continueNode
          , Element.Input.button
            [ Element.Border.width 1
            , Element.padding 3
            , Element.centerX
            ]
            { onPress = Just SkipTutorial
            , label = Element.el [] <| Element.text "I'll do it later ->"
            }
          ]
        ]

    Tutorial.ExplainNotes ->
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial NoHighlights
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ finishTutorialButton
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "Bravo! Your first entry into your second mind! Your new brain is expanding in size!"
          , Element.textColumn
            [ Element.centerX
            , Element.spacingXY 0 16
            ]
            [ Element.paragraph []
              [ Element.text "Every intellectual endeavor starts with writing. "
              , Element.text "Writing helps us remember. Writing helps us organize the thoughts in our head. "
              ]
            , Element.paragraph []
              [ Element.text "The notes you write are the building blocks of your external brain. "
              , Element.text "It is important for you to transfer ideas from the medium of your head to your new brain in concise note form. "
              , Element.text "This transfer from mind to written words is one of the hardest things tasks you do. "
              , Element.text "This is why we have a system to do this gradually over time and set future selves up for success! "
              ]
            , Element.paragraph []
              [ Element.text "Imagine everything you know in your head! "
              , Element.text "Now imagine yourself writing a book or project outline and starting from scratch, staring at a blank sheet of paper. "
              , Element.text "It could take weeks, months, or even years from the time you start! "
              , Element.text "But, you've been learning for a long time leading up to this moment! "
              ]
            , Element.paragraph []
              [ Element.text "Now imagine when you sit down to start writing that book or project outline, you have a rough draft sitting in front of you rather than a blank sheet of paper. "
              , Element.text "This is a much nicer situation. Refining is much easier than starting from scratch. "
              , Element.text "The Slipbox app and practice are the tools to do this and it starts with what you just did, writing one note. "
              ]
            ]
          , Element.Input.button
            [ Element.Border.width 1
            , Element.padding 3
            , Element.centerX
            ]
            { onPress = Just ContinueTutorial
            , label = Element.el [] <| Element.text "Continue ->"
            }
          ]
        ]

    Tutorial.NoteInput firstNoteContent maybeFirstNoteTitle secondNoteContent secondNoteSourceTitle ->
      let
        sourceInputid = "Source: 1"
        dataitemId = "Sources: 1"
        suggestions =
          case maybeFirstNoteTitle of
            Just firstNoteTitle -> [ firstNoteTitle, "n/a" ]
            Nothing -> [ "n/a" ]
        continueNode =
          if Tutorial.canContinue tutorial then
            Element.Input.button
              [ Element.Border.width 1
              , Element.padding 3
              , Element.centerX
              ]
              { onPress = Just ContinueTutorial
              , label = Element.el [] <| Element.text "Continue ->"
              }
          else
            Element.el [ Element.height <| Element.px 28 ] Element.none
      in
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial NoHighlights
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ finishTutorialButton
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "Want to add a related note to your first?"
          , Element.el [ Element.centerX, Element.paddingEach paddingBottom ]
            <| Element.text firstNoteContent
          , Element.Input.multiline
            []
            { onChange = (\s -> UpdateInputTutorial <| Tutorial.Content s )
            , text = secondNoteContent
            , placeholder = Just <| Element.Input.placeholder [] <| Element.text "Add your knowledge here!"
            , label = Element.Input.labelAbove [] <| Element.text "Content (required)"
            , spellcheck = True
            }
          , Element.el [] <| Element.html
            <| Html.div
              []
              [ Html.label
                [ Html.Attributes.for sourceInputid ]
                [ Html.text "Source Title (optional) " ]
              , Html.input
                [ Html.Attributes.list dataitemId
                , Html.Attributes.name sourceInputid
                , Html.Attributes.id sourceInputid
                , Html.Attributes.value secondNoteSourceTitle
                , Html.Events.onInput ( \s -> UpdateInputTutorial <| Tutorial.Title s )
                ]
                []
              , Html.datalist
                [ Html.Attributes.id dataitemId ]
                <| List.map toHtmlOption suggestions
              ]
          , continueNode
          , Element.Input.button
            [ Element.Border.width 1
            , Element.padding 3
            , Element.centerX
            ]
            { onPress = Just SkipTutorial
            , label = Element.el [] <| Element.text "I'll do it later"
            }
          ]
        ]

    Tutorial.AddLinkPrompt firstNoteContent secondNoteContent ->
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial NoHighlights
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ finishTutorialButton
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "Are these notes related?"
          , Element.el [ Element.centerX ] <| Element.text firstNoteContent
          , Element.el [ Element.centerX ] <| Element.text secondNoteContent
          , Element.Input.button
            [ Element.Border.width 1
            , Element.padding 3
            , Element.centerX
            ]
            { onPress = Just ContinueTutorial
            , label = Element.el [] <| Element.text "Link the notes together"
            }
          , Element.Input.button
            [ Element.Border.width 1
            , Element.padding 3
            , Element.centerX
            ]
            { onPress = Just SkipTutorial
            , label = Element.el [] <| Element.text "These notes aren't related"
            }
          ]
        ]

    Tutorial.ExplainLinks ->
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial NoHighlights
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ finishTutorialButton
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "Linking notes together is the foundation of Slipbox"
          , Element.textColumn
            [ Element.centerX
            , Element.spacingXY 0 16
            ]
            [ Element.paragraph
              []
              [ Element.text "Organizing your thoughts gives you a higher chance of success with projects in the future. "
              , Element.text "Using systems of organization are limited by an individuals willpower. "
              , Element.text "This system of organization moves past this limitation. "
              ]
            , Element.paragraph
              []
              [ Element.text "The slipbox system is more successful if you only do what you feel like doing in the moment. "
              , Element.text "This does not require willpower! "
              , Element.text "There are no restrictions or limitations on what you have to research or do with your time. "
              ]
            , Element.paragraph
              []
              [ Element.text "Slipbox is an application and a practice. "
              , Element.text "This practice asks you to keep track of what you learn in a day. "
              , Element.text "Then, take this knowledge and put it inside your second brain. "
              , Element.text "While you're doing this, make connections between new knowledge and old knowledge. "
              ]
            , Element.paragraph []
              [ Element.text "Trust that your natural curiosity will guide you towards the intellectual endeavors. "
              , Element.text "You can count on your second brain to have a rough draft of your project waiting for you without any extra effort expended on your part. "
              , Element.text "The only thing you are responsible for is following your interest and taking a few minutes each day to record where your interest took you! "
              ]
            ]
          , Element.Input.button
            [ Element.Border.width 1
            , Element.padding 3
            , Element.centerX
            ]
            { onPress = Just ContinueTutorial
            , label = Element.el [] <| Element.text "Continue ->"
            }
          ]
        ]

    Tutorial.QuestionPrompt firstNoteContent ->
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial HighlightCreateQuestion
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ finishTutorialButton
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "Next we'll go over ways of conversing with your external brain"
          , Element.el [ Element.centerX, Element.paddingEach paddingBottom ]
            <| Element.text "Have a question you want to answer? If you want it can be related to your first note."
          , Element.el [ Element.centerX ] <| Element.text firstNoteContent
          , Element.Input.button
            [ Element.Border.width 1
            , Element.padding 3
            , Element.centerX
            ]
            { onPress = Just SkipTutorial
            , label = Element.el [] <| Element.text "I'll add a question later"
            }
          ]
        ]

    Tutorial.QuestionInput firstNoteContent question ->
      let
        continueNode =
          if Tutorial.canContinue tutorial then
            Element.Input.button
              [ Element.Border.width 1
              , Element.padding 3
              , Element.centerX
              ]
              { onPress = Just ContinueTutorial
              , label = Element.el [] <| Element.text "Continue ->"
              }
          else
            Element.el [ Element.height <| Element.px 28 ] Element.none
      in
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial NoHighlights
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ finishTutorialButton
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "What do you want to ask your brain?"
          , Element.el [ Element.centerX ] <| Element.text firstNoteContent
          , Element.Input.multiline
            []
            { onChange = (\s -> UpdateInputTutorial <| Tutorial.Content s )
            , text = question
            , placeholder = Just <| Element.Input.placeholder [] <| Element.text "Ask a question here!"
            , label = Element.Input.labelAbove [] <| Element.text "Question (required)"
            , spellcheck = True
            }
          , continueNode
          , Element.Input.button
            [ Element.Border.width 1
            , Element.padding 3
            , Element.centerX
            ]
            { onPress = Just SkipTutorial
            , label = Element.el [] <| Element.text "Actually, I'll converse with my brain another time ->"
            }
          ]
        ]

    Tutorial.ExplainQuestions ->
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial NoHighlights
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ finishTutorialButton
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "Questions are how you converse with your mind!"
          , Element.textColumn
            [ Element.centerX
            , Element.spacingXY 0 16
            ]
            [ Element.paragraph
              []
              [ Element.text "Adding a question to your slipbox can be a way of understanding how much you know on a topic. "
              , Element.text "Questions can be linked to a few notes in your slipbox. "
              , Element.text "These notes are linked to other notes. And those notes are linked to other notes! And so on. "
              ]
            , Element.paragraph
              []
              [ Element.text "See where we're going with this? "
              , Element.text "Asking your mind questions often results in action. "
              , Element.text "You can use the insight from this exercise to seek out information where your knowledge is lacking on a subject. "
              , Element.text "Or you could use the complex theory laid out in front of you as the start of a paper or company! It's up to you. "
              ]
            , Element.paragraph
              []
              [ Element.text "This is pretty cool right? Our own minds are incapable of producing everything we know on a topic and all related information at a moments notice. "
              ]
            ]
          , Element.Input.button
            [ Element.Border.width 1
            , Element.padding 3
            , Element.centerX
            ]
            { onPress = Just ContinueTutorial
            , label = Element.el [] <| Element.text "Continue ->"
            }
          ]
        ]

    Tutorial.PracticeSaving jsonFile ->
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial <| HighlightSaveButton jsonFile
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ finishTutorialButton
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "On Saving"
          , Element.textColumn
            [ Element.centerX
            , Element.spacingXY 0 16
            ]
            [ Element.paragraph
              []
              [ Element.text "When you're done adding notes, save your work! Slipbox application will save a file to your computer containing the contents of your mind. "
              , Element.text "Back this file up somewhere easily accessible. It's great to have another place to store this information should something happen to the original file. "
              , Element.text "This application can't remember the contents of your slipbox if you reload or navigate away from the page. "
              ]
            , Element.paragraph
              []
              [ Element.text "If you would be interested in us saving your brain for you and logging in to see it and add to it, please contact us! "
              , Element.text "You can find information to contact the project founder by clicking about in the left navigation. "
              ]
            ]
          ]
        ]


    Tutorial.PracticeUploading ->
      Element.el
        [ Element.inFront
          <| Element.column
            [ Element.centerX
            , Element.padding 8
            , Element.spacingXY 0 16
            ]
            [ Element.el [ Element.Font.heavy, Element.centerX ] <| Element.text "Practice Loading Slipbox File"
            , Element.textColumn
              [ Element.centerX
              , Element.paddingXY 0 16
              , Element.spacingXY 0 16
              ]
              [ Element.paragraph
                []
                [ Element.text "Practice loading your brain by uploading the slipbox file you downloaded! "
                , Element.text "This is how you'll start every session after you complete the tutorial."
                ]
              , Element.paragraph
                []
                [ Element.text "Click the Load Slipbox button below. This will bring up a file explorer."
                ]
              , Element.paragraph
                []
                [ Element.text "Look for a file called "
                , Element.el [ Element.Font.underline ] <| Element.text "slipbox.json"
                , Element.text ". Then select this file. "
                , Element.text "If you have saved files like this before, it may be called "
                , Element.el [ Element.Font.underline ] <| Element.text "slipbox (1).json"
                , Element.text " or something similar. "
                , Element.text "Try looking in your Downloads folder if you can't find the file at first!"
                ]
              ]
            ]
        , Element.inFront setupOverlayTutorial
        , Element.height Element.fill
        , Element.width Element.fill
        ]
        <| Element.el
          [ Element.alpha 0.3
          , Element.height Element.fill
          , Element.width Element.fill
          ]
          <| sessionNode ( 0,0 ) (newContent (0,0))

    Tutorial.WorkflowSuggestionsAndFinish ->
      Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ leftNavTutorial NoHighlights
        , Element.column
          [ Element.width biggerElement
          , Element.height Element.fill
          , Element.padding 16
          , Element.spacingXY 0 16
          ]
          [ Element.el [ Element.height <| Element.px 20 ] Element.none
          , Element.el [ Element.centerX, Element.Font.heavy ]
            <| Element.text "That's it for the tutorial! Congratulations!"
          , Element.textColumn
            [ Element.centerX
            , Element.spacingXY 0 16
            ]
            [ Element.paragraph
              []
              [ Element.text "The mission of this project is to help people achieve their goals. "
              , Element.text "If this project helps you discover more about your goals or brings you closer to them tell us about it! "
              , Element.text "We would love to hear your story. "
              ]
            , Element.el [ Element.Font.semiBold, Element.centerX ] <| Element.text "Workflow Suggestions"
            , Element.paragraph
              []
              [ Element.text "Take notes any way convenient to you throughout the day. "
              , Element.text "Pick a time at the end of the day and spend 15 minutes or less transferring notes from your temporary notes to your slipbox.  "
              , Element.text "After saving the slipbox.json file to your local computer, back it up! Google drive is a common way to do this but there are many options! "
              ]
            ]
          , Element.Input.button
            [ Element.Border.width 1
            , Element.padding 3
            , Element.centerX
            ]
            { onPress = Just EndTutorial
            , label = Element.el [] <| Element.text "Finish tutorial and take me to my second brain! "
            }
          ]
        ]


setupView : ( Int, Int ) -> Html.Html Msg
setupView deviceViewport =
  Html.div
    [ Html.Attributes.style "height" "100%"
    , Html.Attributes.style "width" "100%"
    ]
    [ FontAwesome.Styles.css
    , Element.layout
      [ Element.inFront setupOverlay ]
      <| Element.el
        [ Element.alpha 0.3, Element.height Element.fill, Element.width Element.fill ]
        <| sessionNode deviceViewport (newContent deviceViewport)
    ]

setupOverlay : Element Msg
setupOverlay =
  let
    xButton =
      Element.el [ Element.width Element.fill]
        <| Element.Input.button
          [ Element.alignRight, Element.moveLeft 2]
          { onPress = Just InitializeNewSlipbox, label = Element.text "x" }
    buttonBuilder =
      \func ->
        Element.Input.button
          [ Element.centerX, Element.centerY ]
          func

  in
  Element.el
    [ Element.height Element.fill
    , Element.width Element.fill
    , Element.padding barHeight
    ]
    <| Element.el
      [ Element.width <| Element.px 450
      , Element.height <| Element.px 150
      , Element.centerX
      , Element.centerY
      , Element.Border.width 1
      , Element.Background.color Color.white
      , Element.inFront xButton
      , Element.paddingXY 0 16
      ]
      <| Element.row
        [ Element.height Element.fill
        , Element.width Element.fill
        ]
        [ Element.el
          [ Element.height Element.fill
          , Element.width Element.fill
          , Element.Border.widthEach {right=1,top=0,bottom=0,left=0}
          ]
          <| buttonBuilder
            { onPress = Just StartTutorial
            , label = Element.el [ Element.centerX, Element.Font.underline ] <| Element.text "Start New (Tutorial)"
            }
        , Element.el [ Element.height Element.fill, Element.width Element.fill]
          <| buttonBuilder
            { onPress = Just FileRequested
            , label = Element.el [ Element.centerX, Element.Font.underline ] <| Element.text "Load Slipbox"
            }
        ]

aboutButton : Element Msg
aboutButton =
  Element.newTabLink
    [ Element.centerY
    ]
    { url = contactUrl
    , label = Element.el [ Element.Font.underline ] <| Element.text "About"
    }

-- SESSION VIEW

layoutWithFontAwesomeStyles : Element Msg -> Html.Html Msg
layoutWithFontAwesomeStyles node =
  Html.div
    [ Html.Attributes.style "height" "100%"
    , Html.Attributes.style "width" "100%"
    ]
    [ FontAwesome.Styles.css
    , Element.layout
      [ Element.height Element.fill
      , Element.width Element.fill
      ]
      node
    ]

sessionView : ( Int, Int ) -> Content -> Html.Html Msg
sessionView deviceViewport content =
  layoutWithFontAwesomeStyles <| sessionNode deviceViewport content

sessionNode : ( Int, Int ) -> Content -> Element Msg
sessionNode deviceViewport content =
  Element.row
    [ Element.width Element.fill
    , Element.height Element.fill
    ]
    [ leftNav content.sideNavState content.tab content.slipbox
    , Element.el
      [ Element.width biggerElement
      , Element.height Element.fill]
      <| tabView deviceViewport content
    ]

contactUrl = "https://github.com/varunbhoopalam/slipbox"

-- TAB
tabView: ( Int, Int ) -> Content -> Element Msg
tabView deviceViewport content =
  case content.tab of
    BrainTab input viewport ->
      Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ exploreTabToolbar input
        , graph deviceViewport viewport <| Slipbox.getGraphItems ( searchConverter input ) content.slipbox
        ]

    NotesTab input ->
      Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ noteTabToolbar input
        , tabTextContentContainer
          <| List.map ( \n -> Element.el
            [ Element.width <| Element.minimum 300 Element.fill
            , Element.alignTop
            , Element.alignLeft
            ]
            n )
            <| List.map ( toOpenNoteButton Nothing )
              <| Slipbox.getNotes ( searchConverter input ) content.slipbox
        ]

    SourcesTab input ->
      Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ sourceTabToolbar input
        , tabTextContentContainer
          <| List.map toOpenSourceButton
            <| Slipbox.getSources ( searchConverter input ) content.slipbox
        ]

    WorkspaceTab ->
      Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.padding 8
        , Element.spacingXY 8 8
        ]
        [ Element.el
          [ Element.Font.heavy
          , Element.Border.width 1
          , Element.padding 4
          , Element.Font.color Color.oldLavenderRegular
          , Element.centerX
          ]
          <| Element.text "Workspace"
        , Element.el [ Element.centerX ] <| buttonTray Nothing
        , Element.column
          [ Element.height Element.fill
          , Element.padding 8
          , Element.spacingXY 8 8
          , Element.width Element.fill
          , Element.scrollbarY
          ]
          <| List.map ( toItemView content )
            <| Slipbox.getItems content.slipbox
        ]

    QuestionsTab input ->
      Element.column
      [ Element.width Element.fill
      , Element.height Element.fill
      ]
        [ noteTabToolbar input
        , tabTextContentContainer
          <| List.map ( \n -> Element.el
            [ Element.width <| Element.minimum 300 Element.fill
            , Element.alignTop
            , Element.alignLeft
            ]
            n )
            <| List.map ( toOpenNoteButton Nothing )
              <| Slipbox.getQuestions ( searchConverter input ) content.slipbox
        ]

    CreateModeTab create ->
      case Create.view create of
        Create.NoteInputView coachingOpen canContinue noteInput ->
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
              if canContinue then
                Element.Input.button
                  [ Element.Border.width 1
                  , Element.padding 8
                  ]
                  { onPress = Just CreateTabNextStep
                  , label = Element.text "Next"
                  }
              else
                Element.none
          in
          Element.column
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
            , coaching coachingOpen coachingText
            , Element.Input.multiline
              []
              { onChange = \n -> CreateTabUpdateInput <| Create.Note n
              , text = noteInput
              , placeholder = Nothing
              , label = Element.Input.labelAbove [] <| Element.text "Note Content (required)"
              , spellcheck = True
              }
            , continueNode
            ]

        Create.ChooseQuestionView  coachingOpen canContinue note questionsRead ->
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
              if canContinue then
                Element.Input.button
                  [ Element.centerX
                  , Element.padding 8
                  , Element.Border.width 1
                  ]
                  { onPress = Just CreateTabNextStep
                  , label = Element.text "Continue without linking"
                  }
              else
                Element.Input.button
                  [ Element.centerX
                  , Element.padding 8
                  , Element.Border.width 1
                  ]
                  { onPress = Just CreateTabNextStep
                  , label = Element.text "Next"
                  }
            questions = Slipbox.getQuestions Nothing content.slipbox
            questionTabularData =
              let
                toQuestionRecord =
                  \q ->
                    { read = List.any ( Note.is q) questionsRead
                    , question = Note.getContent q
                    , note = q
                    }
              in
              List.map toQuestionRecord questions

            tableNode =
              if List.isEmpty questions then
                Element.paragraph
                  [ Element.Font.center
                  , Element.width <| Element.maximum 800 Element.fill
                  , Element.centerX
                  ]
                  [ Element.text "There are no questions in your slipbox! "
                  , Element.text "We smartly add to our external mind by framing our minds to the perspective of furthering arguments on questions we care about. "
                  , Element.text "Add some questions to start adding links! "
                  ]
              else
                let
                    headerAttrs =
                        [ Element.Font.bold
                        , Element.Border.widthEach { bottom = 2, top = 0, left = 0, right = 0 }
                        ]
                in
                Element.column
                  [ Element.width <| Element.maximum 600 Element.fill
                  , Element.height Element.fill
                  , Element.spacingXY 10 10
                  , Element.padding 5
                  , Element.Border.width 2
                  , Element.Border.rounded 6
                  , Element.centerX
                  ]
                  [ Element.row [ Element.width Element.fill ]
                    [ Element.el (Element.width ( Element.fillPortion 1 ) :: headerAttrs) <| Element.text "Read"
                    , Element.el (Element.width ( Element.fillPortion 4 ) :: headerAttrs) <| Element.text "Question"
                    ]
                  , Element.el [ Element.width Element.fill ] <| Element.table
                    [ Element.width Element.fill
                    , Element.spacingXY 8 8
                    , Element.centerX
                    , Element.height <| Element.maximum 600 Element.fill
                    , Element.scrollbarY
                    ]
                    { data = questionTabularData
                    , columns =
                      [ { header = Element.none
                        , width = Element.fillPortion 1
                        , view =
                              \row ->
                                  case row.read of
                                    True -> Element.text "read"
                                    False -> Element.text "unread"
                        }
                      , { header = Element.none
                        , width = Element.fillPortion 4
                        , view =
                              \row ->
                                  Element.Input.button
                                    []
                                    { onPress = Just <| CreateTabToFindLinksForQuestion row.note
                                    , label =
                                      Element.paragraph
                                        []
                                        [ Element.text row.question
                                        ]
                                    }
                        }
                      ]
                    }
                  ]
          in
          Element.column
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
            , coaching coachingOpen coachingText
            , Element.paragraph
              [ Element.Font.center
              , Element.width <| Element.maximum 800 Element.fill
              , Element.centerX
              ]
              [ Element.text note
              ]
            , continueNode
            , tableNode
            ]

        Create.QuestionChosenView createTabGraph linkModal note question selectedNote selectedNoteIsLinked notesAssociatedToCreatedLinks ->
          let
            linkNode =
              if selectedNoteIsLinked then
                Element.column
                  []
                  [ Element.text "Linked"
                  , Element.Input.button
                    []
                    { onPress = Just CreateTabToggleLinkModal
                    , label = Element.text "Edit"
                    }
                  , Element.Input.button
                    []
                    { onPress = Just CreateTabRemoveLink
                    , label = Element.text "Remove"
                    }
                  ]
              else
                Element.Input.button
                  []
                  { onPress = Just CreateTabToggleLinkModal
                  , label = Element.text "Create Link"
                  }
            viewGraph = Element.html <|
              Svg.svg
                [ Svg.Attributes.width "100%"
                , Svg.Attributes.height "100%"
                , Svg.Attributes.viewBox <| computeViewbox createTabGraph.positions
                ] <|
                List.concat
                  [ List.filterMap (toCreateTabGraphLink createTabGraph.positions) createTabGraph.links
                  , List.map viewGraphNote <|
                    List.map ( toCreateTabGraphNote notesAssociatedToCreatedLinks selectedNote ) createTabGraph.positions
                  ]
          in
          Element.row
            [ Element.inFront <| doneOrLinkModal selectedNote note linkModal
            , Element.width Element.fill
            , Element.height Element.fill
            ]
            [ Element.column
              [ Element.width smallerElement
              , Element.height Element.fill
              ]
              [ Element.paragraph
                [ Element.width Element.fill
                , Element.padding 8
                ]
                [ Element.text <| Note.getContent question
                ]
              , Element.paragraph
                [ Element.Font.center
                , Element.width <| Element.maximum 800 Element.fill
                , Element.centerX
                ]
                [ Element.text note
                ]
              , Element.column
                []
                [ Element.el [ Element.alignRight ] starIcon
                , Element.paragraph
                  []
                  [ Element.text <| Note.getContent selectedNote
                  ]
                , linkNode
                ]
              ]
            , Element.column
              [ Element.width biggerElement
              , Element.height Element.fill
              ]
              [ viewGraph
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

        Create.ChooseSourceCategoryView note input  ->
          let
            existingSources = Slipbox.getSources Nothing content.slipbox
            maybeSourceSelected = List.head <| List.filter ( \source -> Source.getTitle source == input ) existingSources
            useExistingSourceNode =
              case maybeSourceSelected of
                Just source ->
                  Element.Input.button
                    []
                    { onPress = Just <| CreateTabContinueWithSelectedSource source
                    , label = Element.text "Use Selected Source"
                    }
                Nothing ->
                  Element.none
          in
          Element.column
            [ Element.padding 16
            , Element.centerX
            , Element.width Element.fill
            , Element.spacingXY 32 32
            ]
            [ Element.el
              [ Element.centerX
              , Element.Font.heavy
              ] <|
              Element.text "Attribute a Source"
            , Element.paragraph
              [ Element.Font.center
              , Element.width <| Element.maximum 800 Element.fill
              , Element.centerX
              ]
              [ Element.text note
              ]
            , Element.row
              []
              [ createTabSourceInput input <| List.map Source.getTitle existingSources
              , useExistingSourceNode
              ]
            , Element.Input.button
              []
              { onPress = Just CreateTabNoSource
              , label = Element.text "No Source"
              }
            , Element.Input.button
              []
              { onPress = Just CreateTabNewSource
              , label = Element.text "New Source"
              }
            ]

        Create.CreateNewSourceView note title author sourceContent ->
          let
            existingTitles = List.map Source.getTitle <| Slipbox.getSources Nothing content.slipbox
            ( titleLabel, submitNode ) =
              if Source.titleIsValid existingTitles title then
                ( Element.text "Title (required)"
                , Element.Input.button
                  []
                  { onPress = Just CreateTabSubmitNewSource
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
          Element.column
            [ Element.padding 16
            , Element.centerX
            , Element.width Element.fill
            , Element.spacingXY 32 32
            ]
            [ Element.el
              [ Element.centerX
              , Element.Font.heavy
              ] <|
              Element.text "Create a Source"
            , Element.paragraph
              [ Element.Font.center
              , Element.width <| Element.maximum 800 Element.fill
              , Element.centerX
              ]
              [ Element.text note
              ]
            , Element.Input.multiline
              []
              { onChange = \s -> CreateTabUpdateInput <| Create.SourceTitle s
              , text = title
              , placeholder = Nothing
              , label = Element.Input.labelAbove [] titleLabel
              , spellcheck = True
              }
            , Element.Input.multiline
              []
              { onChange = \s -> CreateTabUpdateInput <| Create.SourceAuthor s
              , text = author
              , placeholder = Nothing
              , label = Element.Input.labelAbove [] <|
                Element.text "Author (not required)"
              , spellcheck = True
              }
            , Element.Input.multiline
              []
              { onChange = \s -> CreateTabUpdateInput <| Create.SourceContent s
              , text = sourceContent
              , placeholder = Nothing
              , label = Element.Input.labelAbove [] <|
                Element.text "Content (not required)"
              , spellcheck = True
              }
            , submitNode
            ]

        Create.PromptCreateAnotherView note ->
          Element.column
            [ Element.padding 16
            , Element.centerX
            , Element.width Element.fill
            , Element.spacingXY 32 32
            ]
            [ Element.el
              [ Element.centerX
              , Element.Font.heavy
              ] <|
              Element.text "Success! You've smartly added to your external mind. "
            , Element.paragraph
              [ Element.Font.center
              , Element.width <| Element.maximum 800 Element.fill
              , Element.centerX
              ]
              [ Element.text note
              ]
            , Element.Input.button
              []
              { onPress = Just CreateTabCreateAnotherNote
              , label = Element.text "Create Another Note?"
              }
            ]

-- CREATETAB HELPERS

coaching : Bool -> Element Msg -> Element Msg
coaching coachingOpen text =
  let
    toggleCoachingButton =
      Element.Input.button
        [ Element.centerX
        , Element.Border.width 1
        , Element.Border.rounded 4
        , Element.padding 2
        ]
        { onPress = Just CreateTabToggleCoaching
        , label = Element.text "Coaching"
        }
  in
  case coachingOpen of
    False -> toggleCoachingButton
    True ->
      Element.column
        [ Element.spacingXY 8 8
        , Element.centerX
        ]
        [ toggleCoachingButton
        , text
        ]

doneOrLinkModal : Note.Note -> String -> Create.LinkModal -> Element Msg
doneOrLinkModal selectedNote createdNote bridgeModal =
  case bridgeModal of
    Create.Closed ->
      Element.el
        [ Element.padding 8
        , Element.alignRight
        , Element.alignTop
        ] <|
        Element.Input.button
          []
          { onPress = Just CreateTabToChooseQuestion
          , label = Element.text "Done"
          }
    Create.Open input ->
      let
        submitNode =
          if String.isEmpty input then
            Element.none
          else
            Element.Input.button
              []
              { onPress = Just CreateTabCreateBridgeForSelectedNote
              , label = Element.text "Create Bridged Link with Note"
              }
      in
      Element.column
        [ Element.height Element.fill
        , Element.width Element.fill
        , Element.Background.color Color.white
        , Element.padding 32
        , Element.spacingXY 16 16
        ]
        [ Element.row
          [ Element.width Element.fill ]
          [ Element.paragraph
            [ Element.width Element.fill
            , Element.height Element.fill
            ]
            [ Element.text createdNote
            ]
          , Element.paragraph
            [ Element.width Element.fill
            , Element.height Element.fill
            ]
            [ Element.text <| Note.getContent selectedNote
            ]
          ]
        , Element.Input.button
          [ Element.centerX
          , Element.Border.width 1
          , Element.padding 8
          ]
          { onPress = Just CreateTabCreateLinkForSelectedNote
          , label = Element.text "Create Link"}
        , Element.column
          [ Element.width Element.fill
          ]
          [ Element.Input.multiline
            []
            { onChange = \s -> CreateTabUpdateInput <| Create.Note s
            , text = input
            , placeholder = Nothing
            , label = Element.Input.labelAbove [] <| Element.text "Note Content (required)"
            , spellcheck = True
            }
          , submitNode
          ]
        , Element.Input.button
          [ Element.centerX
          , Element.Border.width 1
          , Element.padding 8
          ]
          { onPress = Just CreateTabToggleLinkModal
          , label = Element.text "Cancel"
          }
        ]

type GraphNote
  = Selected Note.Note X Y
  | Linked Note.Note X Y
  | Question Note.Note X Y
  | Regular Note.Note X Y

type alias X = String
type alias Y = String

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

toCreateTabGraphNote : ( List Note.Note ) -> Note.Note -> NotePosition -> GraphNote
toCreateTabGraphNote notesAssociatedToCreatedLinks selectedNote notePosition =
  let
    note = notePosition.note
    isSelectedNote = Note.is note selectedNote
    isQuestion = Note.getVariant note == Note.Question
    hasCreatedLink =
      List.any
        ( Note.is note )
        notesAssociatedToCreatedLinks
    x = String.fromFloat notePosition.x
    y = String.fromFloat notePosition.y
  in
  if isSelectedNote then
    Selected note x y
  else
    if isQuestion then
      Question note x y
    else
      case hasCreatedLink of
        True -> Linked note x y
        False -> Regular note x y

viewGraphNote : GraphNote -> Svg.Svg Msg
viewGraphNote graphNote =
  case graphNote of
    Selected note x y ->
      let
        center str =
          case String.toFloat str of
            Just s -> String.fromFloat <| s - 10
            Nothing -> str
        xCenter = center x
        yCenter = center y
        transformation = "rotate(45 " ++ x ++ " " ++ y ++ ")"
      in
      Svg.g
        [ Svg.Attributes.cursor "Pointer"
        , Svg.Events.onClick <| CreateTabSelectNote note
        ]
        [ Svg.rect
          [ Svg.Attributes.fill "rgb(0,0,0)"
          , Svg.Attributes.width "20"
          , Svg.Attributes.height "20"
          , Svg.Attributes.x xCenter
          , Svg.Attributes.y yCenter
          ]
          []
        , Svg.rect
          [ Svg.Attributes.fill "rgba(0,0,0)"
          , Svg.Attributes.width "20"
          , Svg.Attributes.height "20"
          , Svg.Attributes.x xCenter
          , Svg.Attributes.y yCenter
          , Svg.Attributes.transform transformation
          ]
          []
        ]


    Linked note x y ->
      let
        modify str increment =
          case String.toFloat str of
            Just s -> String.fromFloat <| s + increment
            Nothing -> str
      in
      Svg.g
        [ Svg.Attributes.cursor "Pointer"
        , Svg.Events.onClick <| CreateTabSelectNote note
        ]
        [ Svg.circle
          [ Svg.Attributes.r "5"
          --, Svg.Attributes.fill "none"
          , Svg.Attributes.stroke "black"
          , Svg.Attributes.fill "rgba(137, 196, 244, 1)"
          , Svg.Attributes.cx x
          , Svg.Attributes.cy y
          ]
          []
        , Svg.line
          [ Svg.Attributes.x1 <| modify x -5
          , Svg.Attributes.x2 <| modify x 5
          , Svg.Attributes.y1 y
          , Svg.Attributes.y2 y
          , Svg.Attributes.stroke "black"
          ]
          []
        , Svg.line
          [ Svg.Attributes.x1 x
          , Svg.Attributes.x2 x
          , Svg.Attributes.y1 <| modify y -5
          , Svg.Attributes.y2 <| modify y 5
          , Svg.Attributes.stroke "black"
          ]
          []
        ]

    Question note x y ->
      let
        center str =
          case String.toFloat str of
            Just s -> String.fromFloat <| s - 10
            Nothing -> str
        xCenter = center x
        yCenter = center y
      in
      Svg.rect
        [ Svg.Attributes.fill "rgb(0,0,0)"
        , Svg.Attributes.width "20"
        , Svg.Attributes.height "20"
        , Svg.Attributes.x xCenter
        , Svg.Attributes.y yCenter
        , Svg.Attributes.cursor "Pointer"
        , Svg.Events.onClick <| CreateTabSelectNote note
        ]
        []

    Regular note x y ->
      Svg.circle
        [ Svg.Attributes.cx x
        , Svg.Attributes.cy y
        , Svg.Attributes.r "5"
        , Svg.Attributes.fill "rgba(137, 196, 244, 1)"
        , Svg.Attributes.cursor "Pointer"
        , Svg.Events.onClick <| CreateTabSelectNote note
        ]
        []

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
    padding = 50
    formatViewbox record =
      String.fromFloat record.minX
      ++ " " ++  String.fromFloat record.minY
      ++ " " ++  String.fromFloat record.width
      ++ " " ++  String.fromFloat record.height
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

toCreateTabGraphLink: (List NotePosition) -> Link.Link -> ( Maybe ( Svg.Svg Msg ) )
toCreateTabGraphLink notePositions link =
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
  Maybe.map2 createTabSvgLine (maybeGetNoteByIdentifier Link.isSource) (maybeGetNoteByIdentifier Link.isTarget)

createTabSvgLine : NotePosition -> NotePosition -> Svg.Svg Msg
createTabSvgLine note1 note2 =
  Svg.line
    [ Svg.Attributes.x1 <| String.fromFloat <| note1.x
    , Svg.Attributes.y1 <| String.fromFloat <| note1.y
    , Svg.Attributes.x2 <| String.fromFloat <| note2.x
    , Svg.Attributes.y2 <| String.fromFloat <| note2.y
    , Svg.Attributes.stroke "rgb(0,0,0)"
    , Svg.Attributes.strokeWidth "2"
    ]
    []

createTabSourceInput: String -> (List String) -> Element Msg
createTabSourceInput input suggestions =
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
          , Html.Events.onInput <| \s -> CreateTabUpdateInput <| Create.SourceTitle s
          ]
          []
        , Html.datalist
          [ Html.Attributes.id dataitemId ]
          <| List.map toHtmlOption suggestions
        ]

toHtmlOption: String -> Html.Html Msg
toHtmlOption value =
  Html.option [ Html.Attributes.value value ] []

-- END CREATETAB HELPERS

tabTextContentContainer : ( List ( Element Msg ) ) -> Element Msg
tabTextContentContainer contents =
  Element.wrappedRow
    [ Element.height Element.fill
    , Element.padding 8
    , Element.spacingXY 8 8
    , Element.width Element.fill
    , Element.scrollbarY
    ]
    contents

searchConverter : String -> ( Maybe String )
searchConverter input =
  if String.isEmpty input then
    Nothing
  else
    Just input

barHeight = 65

leftNavExpandedButtonLambda : Element.Attribute Msg -> Element Msg -> String -> Msg -> Bool -> Element Msg
leftNavExpandedButtonLambda alignment icon text msg shouldHaveBackground =
  let
    buttonAttributes =
      [ Element.width Element.fill
      , Element.height Element.fill
      , Element.Border.rounded 10
      , Element.padding 1
      ]
    buttonAttributesMaybeWithBackground =
      if shouldHaveBackground then
        Element.Background.color Color.heliotropeGrayRegular :: buttonAttributes
      else
        buttonAttributes
  in
  Element.el
    [ Element.width Element.fill
    , alignment
    ]
    <| Element.Input.button
      buttonAttributesMaybeWithBackground
      { onPress = Just msg
      , label =
        Element.row
          [ Element.spacingXY 16 0]
          [ icon
          , Element.text text
          ]
      }

leftNavContractedButtonLambda : Element.Attribute Msg -> Msg -> Element Msg -> Bool -> Element Msg
leftNavContractedButtonLambda alignment msg icon shouldHaveBackground =
    let
      buttonAttributes =
        if shouldHaveBackground then
          [ Element.Background.color Color.heliotropeGrayRegular ]
        else
          []
    in
    Element.el [ alignment ]
      <| Element.Input.button buttonAttributes
        { onPress = Just msg
        , label = icon
        }

leftNav : SideNavState -> Tab -> Slipbox.Slipbox -> Element.Element Msg
leftNav sideNavState selectedTab slipbox =
  let
    iconWidth = Element.width <| Element.px 35
    iconHeight = Element.width <| Element.px 40
    emptyIcon = Element.el [ iconWidth, iconHeight ] Element.none
    unsavedChangesNode =
      if Slipbox.unsavedChanges slipbox then
        Element.el
          [Element.Font.size 12
          , Element.moveRight 6.0
          , Element.moveDown 14.0
          ]
          <| Element.text "unsaved changes"
      else
        Element.none
  in
  case sideNavState of
    Expanded ->
      Element.column
        [ Element.height Element.fill
        , Element.width <| Element.px 250
        , Element.padding 8
        , Element.spacingXY 0 8
        ]
        [ Element.column
          [ Element.height smallerElement
          , Element.width Element.fill
          , Element.spacingXY 0 8
          ]
          [ Element.row
            [ Element.width Element.fill
            , Element.spacingXY 16 0
            ]
            [ barsButton
            , Element.el [ Element.centerY, Element.alignLeft ]
              <| Element.text <| "Slipbox " ++ versionString
            ]
          , Element.row
            [ Element.width Element.fill
            , Element.spacingXY 16 0
            ]
            [ emptyIcon
            , Element.el [ Element.centerY, Element.alignLeft ] aboutButton
            ]
          , Element.el
            [ Element.width Element.fill
            , Element.alignBottom
            ]
            <| Element.Input.button
              [ Element.width Element.fill
              , Element.height Element.fill
              , Element.Border.rounded 10
              , Element.padding 1
              ]
              { onPress = Just FileDownload
              , label =
                Element.row
                  [ Element.spacingXY 16 0, Element.onRight unsavedChangesNode ]
                  [ saveIcon
                  , Element.text "Save"
                  ]
              }
          , leftNavExpandedButtonLambda Element.alignBottom plusIcon "Create Mode" ( ChangeTab CreateMode ) <| sameTab selectedTab CreateMode
          , leftNavExpandedButtonLambda Element.alignBottom newspaperIcon "Create Source" ( AddItem Nothing Slipbox.NewSource ) False
          , leftNavExpandedButtonLambda Element.alignBottom handPaperIcon "Create Question" ( AddItem Nothing Slipbox.NewQuestion ) False
          ]
        , Element.column
          [ Element.height biggerElement
          , Element.width Element.fill
          , Element.spacingXY 0 8
          ]
          [ leftNavExpandedButtonLambda Element.alignLeft brainIcon "Brain" ( ChangeTab Brain ) <| sameTab selectedTab Brain
          , leftNavExpandedButtonLambda Element.alignLeft toolsIcon "Workspace" ( ChangeTab Workspace ) <| sameTab selectedTab Workspace
          , leftNavExpandedButtonLambda Element.alignLeft fileAltIcon "Notes" ( ChangeTab Notes ) <| sameTab selectedTab Notes
          , leftNavExpandedButtonLambda Element.alignLeft scrollIcon "Sources" ( ChangeTab Sources ) <| sameTab selectedTab Sources
          , leftNavExpandedButtonLambda Element.alignLeft questionIcon "Questions" ( ChangeTab Questions ) <| sameTab selectedTab Questions
          ]
        ]
    Contracted ->
      Element.column
        [ Element.height Element.fill
        , Element.width <| Element.px 64
        , Element.padding 8
        , Element.spacingXY 0 8
        ]
        [ Element.column
          [ Element.height smallerElement
          , Element.spacingXY 0 8
          ]
          [ barsButton
          , leftNavContractedButtonLambda Element.alignBottom FileDownload saveIcon False
          , leftNavContractedButtonLambda Element.alignBottom ( AddItem Nothing Slipbox.NewNote ) plusIcon False
          , leftNavContractedButtonLambda Element.alignBottom ( AddItem Nothing Slipbox.NewSource ) newspaperIcon False
          , leftNavContractedButtonLambda Element.alignBottom ( AddItem Nothing Slipbox.NewQuestion ) handPaperIcon False
          ]
        , Element.column
          [ Element.height biggerElement
          , Element.spacingXY 0 8
          ]
          [ leftNavContractedButtonLambda Element.alignLeft ( ChangeTab Brain ) brainIcon <| sameTab selectedTab Brain
          , leftNavContractedButtonLambda Element.alignLeft ( ChangeTab Workspace ) toolsIcon <| sameTab selectedTab Workspace
          , leftNavContractedButtonLambda Element.alignLeft ( ChangeTab Notes ) fileAltIcon <| sameTab selectedTab Notes
          , leftNavContractedButtonLambda Element.alignLeft ( ChangeTab Sources ) scrollIcon <| sameTab selectedTab Sources
          , leftNavContractedButtonLambda Element.alignLeft ( ChangeTab Questions ) questionIcon <| sameTab selectedTab Questions
          ]
        ]

sameTab : Tab -> Tab_ -> Bool
sameTab tab tab_ =
  case tab of
    BrainTab _ _ ->
      case tab_ of
        Brain -> True
        _ -> False

    NotesTab _ ->
      case tab_ of
        Notes -> True
        _ -> False

    SourcesTab _ ->
      case tab_ of
        Sources -> True
        _ -> False

    WorkspaceTab ->
      case tab_ of
        Workspace -> True
        _ -> False

    QuestionsTab _ ->
      case tab_ of
        Questions -> True
        _ -> False

    CreateModeTab _ ->
      case tab_ of
        CreateMode -> True
        _ -> False

iconBuilder : FontAwesome.Icon.Icon -> Element Msg
iconBuilder icon =
  Element.el []
    <| Element.html
      <| FontAwesome.Icon.viewStyled
        [ FontAwesome.Attributes.fa2x
        , FontAwesome.Attributes.fw
        ]
        icon

plusIcon : Element Msg
plusIcon = iconBuilder FontAwesome.Solid.plus

newspaperIcon : Element Msg
newspaperIcon = iconBuilder FontAwesome.Solid.newspaper

handPaperIcon : Element Msg
handPaperIcon = iconBuilder FontAwesome.Solid.handPaper

saveIcon : Element Msg
saveIcon = iconBuilder FontAwesome.Solid.save

brainIcon : Element Msg
brainIcon = iconBuilder FontAwesome.Solid.brain

toolsIcon : Element Msg
toolsIcon = iconBuilder FontAwesome.Solid.tools

fileAltIcon : Element Msg
fileAltIcon = iconBuilder FontAwesome.Solid.fileAlt

scrollIcon : Element Msg
scrollIcon = iconBuilder FontAwesome.Solid.scroll

questionIcon : Element Msg
questionIcon = iconBuilder FontAwesome.Solid.question

starIcon = iconBuilder FontAwesome.Solid.star
starSvg = FontAwesome.Svg.viewIcon FontAwesome.Solid.star

linkIcon = iconBuilder FontAwesome.Solid.link
linkSvg = FontAwesome.Svg.viewIcon FontAwesome.Solid.link

questionCircleIcon = iconBuilder FontAwesome.Solid.questionCircle
questionCircleSvg = FontAwesome.Svg.viewIcon FontAwesome.Solid.questionCircle

barsButton : Element Msg
barsButton =
  Element.Input.button
    []
    { onPress = Just ToggleSideNav
    , label = Element.el []
      <| Element.html
        <| FontAwesome.Icon.viewStyled
          [ FontAwesome.Attributes.fa2x
          ]
          FontAwesome.Solid.bars
    }

-- ITEMS

itemHeaderBuilder : ( List ( Element Msg ) ) -> Element Msg
itemHeaderBuilder contents =
  Element.row
    [ Element.width Element.fill
    , Element.spacingXY 8 0
    ]
    contents

normalItemHeader : String -> Item.Item -> Element Msg
normalItemHeader text item =
  itemHeaderBuilder
    [ headerText text
    , Element.el [ Element.alignRight ] <| editButton item
    , Element.el [ Element.alignRight ] <| deleteButton item
    , Element.el [ Element.alignRight ] <| dismissButton item
    ]

conditionalSubmitItemHeader : String -> Bool -> Item.Item -> Element Msg
conditionalSubmitItemHeader text canSubmit item =
  itemHeaderBuilder
    [ headerText text
    , Element.el [ Element.alignRight ] <| cancelButton item
    , Element.el [ Element.alignRight ] <| chooseSubmitButton item canSubmit
    ]

deleteItemHeader : String -> Item.Item -> Element Msg
deleteItemHeader text item =
  itemHeaderBuilder
    [ headerText text
    , Element.el [ Element.alignRight ] <| cancelButton item
    , Element.el [ Element.alignRight ] <| confirmButton item
    ]

submitItemHeader : String -> Item.Item -> Element Msg
submitItemHeader text item =
  itemHeaderBuilder
    [ headerText text
    , Element.el [ Element.alignRight ] <| cancelButton item
    , Element.el [ Element.alignRight ] <| submitButton item
    ]

toItemView: Content -> Item.Item -> Element Msg
toItemView content item =
  let
    itemContainerLambda =
      \contents ->
        Element.column
          [ Element.spacingXY 8 8
          , Element.width Element.fill
          , Element.centerX
          ]
          [ Element.el
            [ Element.width <| Element.maximum 600 Element.fill
            , Element.centerX
            ]
            <| Element.column
              containerAttributes
              contents
          , onHoverButtonTray item
          ]
  in
  case item of
    Item.Note _ _ note ->
      let
        text =
          case Note.getVariant note of
            Note.Regular -> "Note"
            Note.Question -> "Question"
      in
      itemContainerLambda
        [ normalItemHeader text item
        , toNoteRepresentationFromNote note
        , linkedNotesNode item note content.slipbox
        ]


    Item.NewNote itemId _ note -> itemContainerLambda
      [ conditionalSubmitItemHeader "New Note" ( Item.noteCanSubmit note ) item
      , toEditingNoteRepresentation
        itemId item ( List.map Source.getTitle <| Slipbox.getSources Nothing content.slipbox ) note.content note.source Note.Regular
      ]


    Item.ConfirmDiscardNewNoteForm _ _ note -> itemContainerLambda
      [ deleteItemHeader "Discard New Note" item
      , toNoteRepresentation note.content note.source Note.Regular
      ]


    Item.EditingNote itemId _ _ noteWithEdits ->
      let
        text =
          case Note.getVariant noteWithEdits of
            Note.Regular -> "Editing Note"
            Note.Question -> "Editing Question"
      in
      itemContainerLambda
        [ submitItemHeader text item
        , toEditingNoteRepresentationFromItemNoteSlipbox itemId item noteWithEdits content.slipbox
        ]


    Item.ConfirmDeleteNote _ _ note ->
      let
        text =
          case Note.getVariant note of
            Note.Regular -> "Delete Note"
            Note.Question -> "Delete Question"
      in
      itemContainerLambda
        [ deleteItemHeader text item
        , toNoteRepresentationFromNote note
        ]


    Item.AddingLinkToNoteForm _ _ search note maybeNote ->
      let
        maybeChoice =
          case maybeNote of
            Just chosenNoteToLink -> toNoteRepresentationFromNote chosenNoteToLink
            Nothing -> Element.paragraph [] [ Element.text "Select note to add link to from below" ]
      in
      itemContainerLambda
        [ conditionalSubmitItemHeader "Add Link" ( maybeNote /= Nothing ) item
        , Element.row
          [ Element.width Element.fill ]
          [ Element.el
            [ Element.Border.widthEach { right = 3, top = 0, left = 0, bottom = 0 }
            , Element.width Element.fill
            ]
            <| toNoteRepresentationFromNote note
          , maybeChoice
          ]
        , Element.column
          [ Element.height Element.fill
          , Element.width Element.fill
          , Element.spacingXY 8 8
          ]
          [ Element.el [ Element.alignLeft, Element.Font.heavy ]
            <| Element.text "Select Note to Link"
          , searchInput search
            <| ( \inp -> UpdateItem item <| Slipbox.UpdateSearch inp )
          , Element.column
            containerWithScrollAttributes
              <| List.map (toNoteDetailAddingLinkForm item)
                <| List.filter ( Note.contains search )
                  <| Slipbox.getNotesThatCanLinkToNote note content.slipbox
          ]
        ]


    Item.Source _ _ source -> itemContainerLambda
      [ normalItemHeader "Source" item
      , toSourceRepresentationFromSource source
      , associatedNotesNode item source content.slipbox
      ]


    Item.NewSource _ _ source ->
      let
        existingTitles = getTitlesFromSlipbox content.slipbox
      in
      itemContainerLambda
        [ conditionalSubmitItemHeader "New Source" ( Item.sourceCanSubmit source existingTitles ) item
        , toEditingSourceRepresentation item source.title source.author source.content existingTitles
        ]


    Item.ConfirmDiscardNewSourceForm _ _ source -> itemContainerLambda
      [ deleteItemHeader "Confirm Discard New Source" item
      , toSourceRepresentation source.title source.author source.content
      ]


    Item.EditingSource _ _ source sourceWithEdits ->
      let
        titlesThatArentTheOriginalSourcesTitle = ( \title -> title /= Source.getTitle source )
        existingTitlesExcludingThisSourcesTitle =
          List.filter titlesThatArentTheOriginalSourcesTitle
            <| getTitlesFromSlipbox content.slipbox
      in
        itemContainerLambda
          [ conditionalSubmitItemHeader
            "Editing Source"
            ( Source.titleIsValid existingTitlesExcludingThisSourcesTitle ( Source.getTitle sourceWithEdits ) )
            item
          , toEditingSourceRepresentationFromItemSource item sourceWithEdits existingTitlesExcludingThisSourcesTitle
          ]


    Item.ConfirmDeleteSource _ _ source -> itemContainerLambda
      [ deleteItemHeader "Confirm Delete Source" item
      , toSourceRepresentationFromSource source
      ]


    Item.ConfirmDeleteLink _ _ note linkedNote _ -> itemContainerLambda
      [ deleteItemHeader "Confirm Delete Link" item
      , Element.row
        [ Element.spaceEvenly ]
        [ toNoteRepresentationFromNote note
        , toNoteRepresentationFromNote linkedNote
        ]
      ]

    Item.NewQuestion _ _ question -> itemContainerLambda
      [ conditionalSubmitItemHeader "New Question" ( not <| String.isEmpty question ) item
      , contentContainer
        [ Element.el [ Element.width Element.fill ] <| questionInput item question
        ]
      ]

    Item.ConfirmDiscardNewQuestion _ _ question -> itemContainerLambda
      [ deleteItemHeader "Confirm Discard New Question" item
      , toQuestionRepresentation question
      ]

getTitlesFromSlipbox : Slipbox.Slipbox -> ( List String )
getTitlesFromSlipbox slipbox =
  List.map (Source.getTitle) <| Slipbox.getSources Nothing slipbox

onHoverButtonTray : Item.Item -> Element Msg
onHoverButtonTray item =
  let
    tray =
      if Item.isTrayOpen item then
        buttonTray <| Just item
      else
        Element.el
          [ Element.height <| Element.minimum 10 Element.fill
          , Element.width Element.fill
          ]
          Element.none
  in
  Element.el
    [ Element.Events.onMouseEnter <| UpdateItem item Slipbox.OpenTray
    , Element.Events.onMouseLeave <| UpdateItem item Slipbox.CloseTray
    , Element.width Element.fill
    ]
    tray

buttonTray : ( Maybe Item.Item ) -> Element Msg
buttonTray maybeItem =
  Element.row
    [ Element.width Element.fill
    , Element.padding 8
    , Element.spacingXY 8 8
    , Element.height Element.fill
    ]
    [ createNoteButton maybeItem
    , createSourceButton maybeItem
    , createQuestionButton maybeItem
    ]

headerText : String -> Element Msg
headerText text =
  Element.el [ Element.alignLeft, Element.Font.heavy ] <| Element.text text

linkedNotesNode : Item.Item -> Note.Note -> Slipbox.Slipbox -> Element Msg
linkedNotesNode item note slipbox =
  let
    linkedNotes = Slipbox.getLinkedNotes note slipbox
    canAddLinkToNote = not <| List.isEmpty <| Slipbox.getNotesThatCanLinkToNote note slipbox
    noLinkedNotes = List.isEmpty linkedNotes
    linkedNotesDomRep = Element.column
      containerWithScrollAttributes
      <| List.map (toLinkedNoteView item) linkedNotes
  in
  if canAddLinkToNote then
    if noLinkedNotes then
      addLinkButton item
    else
      Element.column
        []
        [ Element.row
          [ Element.width Element.fill]
          [ headerText "Linked Notes"
          , Element.el [ Element.alignRight ] <| addLinkButton item ]
        , linkedNotesDomRep
        ]
  else
    if noLinkedNotes then
      Element.none
    else
      Element.column []
        [ Element.el [ Element.alignLeft ] <| Element.text "Linked Notes"
        , linkedNotesDomRep
        ]

associatedNotesNode : Item.Item -> Source.Source -> Slipbox.Slipbox -> Element Msg
associatedNotesNode item source slipbox =
  let
    associatedNotes = Slipbox.getNotesAssociatedToSource source slipbox
    noAssociatedNotes = List.isEmpty associatedNotes
  in
  if noAssociatedNotes then
    Element.none
  else
    Element.column
      [ Element.width Element.fill, Element.spacingXY 8 8 ]
      [ headerText "Associated Notes"
      , Element.column containerWithScrollAttributes
          ( List.map (\n -> toAssociatedNoteButton ( Just item ) n ) associatedNotes )
      ]

addLinkButton: Item.Item -> Element Msg
addLinkButton item =
  smallOldLavenderButton
    { onPress = Just <| UpdateItem item Slipbox.AddLinkForm
    , label = Element.text "Add Link"
    }

containerAttributes : ( List ( Element.Attribute Msg) )
containerAttributes =
  [ Element.Border.width 3
  , Element.Border.color Color.heliotropeGrayRegular
  , Element.padding 8
  , Element.spacingXY 8 8
  , Element.width Element.fill
  , Element.centerX
  ]

containerWithScrollAttributes : ( List ( Element.Attribute Msg) )
containerWithScrollAttributes =
  [ Element.Border.width 3
  , Element.Border.color Color.heliotropeGrayRegular
  , Element.padding 8
  , Element.spacingXY 8 8
  , Element.width Element.fill
  , Element.centerX
  , Element.height <| Element.minimum 250 Element.fill
  , Element.scrollbarY
  ]

toLinkedNoteView: Item.Item -> ( Note.Note, Link.Link ) -> Element Msg
toLinkedNoteView item ( linkedNote, link ) =
  Element.row
    containerAttributes
    [ toOpenNoteButton ( Just item ) linkedNote
    , removeLinkButton item linkedNote link
    ]

removeLinkButton: Item.Item -> Note.Note -> Link.Link -> Element Msg
removeLinkButton item linkedNote link =
  smallRedButton
    { onPress = Just <| UpdateItem item <| Slipbox.PromptConfirmRemoveLink linkedNote link
    , label = Element.text "Remove Link"
    }

contentContainer : ( List ( Element Msg ) ) -> Element Msg
contentContainer contents =
  Element.column
    [ Element.padding 8
    , Element.spacingXY 8 8
    , Element.width Element.fill
    ]
    contents

toNoteRepresentationFromNote : Note.Note -> Element Msg
toNoteRepresentationFromNote note =
  toNoteRepresentation
    ( Note.getContent note )
    ( Note.getSource note )
    ( Note.getVariant note )

toNoteRepresentation : String -> String -> Note.Variant -> Element Msg
toNoteRepresentation content source variant =
  case variant of
    Note.Regular ->
      contentContainer
        [ Element.el [ Element.width Element.fill] <| noteContentView content
        , Element.el [ Element.width Element.fill] <| noteSourceView source
        ]
    Note.Question ->
      contentContainer
        [ Element.el [ Element.width Element.fill] <| questionView content
        ]

toAssociatedNoteRepresentation : String -> Note.Variant -> Element Msg
toAssociatedNoteRepresentation content variant =
  case variant of
    Note.Regular ->
      contentContainer
        [ Element.el [ Element.width Element.fill] <| labeledViewBuilder "Note" content ]
    Note.Question ->
      contentContainer
        [ Element.el [ Element.width Element.fill] <| questionView content ]

toAssociatedNoteRepresentationFromNote : Note.Note -> Element Msg
toAssociatedNoteRepresentationFromNote note =
  toAssociatedNoteRepresentation ( Note.getContent note ) ( Note.getVariant note )

toEditingNoteRepresentationFromItemNoteSlipbox : Int -> Item.Item -> Note.Note -> Slipbox.Slipbox -> Element Msg
toEditingNoteRepresentationFromItemNoteSlipbox itemId item note slipbox =
  toEditingNoteRepresentation
    itemId
    item
    ( List.map Source.getTitle <| Slipbox.getSources Nothing slipbox )
    ( Note.getContent note )
    ( Note.getSource note )
    ( Note.getVariant note )

toEditingNoteRepresentation : Int -> Item.Item -> ( List String ) -> String -> String -> Note.Variant -> Element Msg
toEditingNoteRepresentation itemId item titles content source variant =
  case variant of
    Note.Regular ->
      contentContainer
        [ Element.el [ Element.width Element.fill ] <| contentInput item content
        , Element.el [ Element.width Element.fill ] <| sourceInput itemId item source titles
        ]
    Note.Question ->
      contentContainer
        [ Element.el [ Element.width Element.fill ] <| contentInput item content
        ]

toNoteDetailAddingLinkForm: Item.Item -> Note.Note -> Element Msg
toNoteDetailAddingLinkForm item note =
  Element.Input.button
    [ Element.paddingXY 8 0
    , Element.spacingXY 8 0
    , Element.Border.solid
    , Element.Border.color Color.gray
    , Element.Border.width 4
    , Element.width Element.fill
    ]
    { onPress = Just <| UpdateItem item <| Slipbox.AddLink note
    , label = toNoteRepresentationFromNote note
    }

toSourceRepresentationFromSource : Source.Source -> Element Msg
toSourceRepresentationFromSource source =
  toSourceRepresentation
    ( Source.getTitle source )
    ( Source.getAuthor source )
    ( Source.getContent source )

toSourceRepresentation : String -> String -> String -> Element Msg
toSourceRepresentation title author content =
  contentContainer
    [ Element.el [ Element.width Element.fill] <| sourceTitleView title
    , Element.el [ Element.width Element.fill] <| sourceAuthorView author
    , Element.el [ Element.width Element.fill] <| sourceContentView content
    ]

toQuestionRepresentation : String -> Element Msg
toQuestionRepresentation question =
  contentContainer
    [ Element.el [ Element.width Element.fill] <| questionView question
    ]

toEditingSourceRepresentationFromItemSource : Item.Item -> Source.Source -> ( List String ) -> Element Msg
toEditingSourceRepresentationFromItemSource item source existingTitles =
  toEditingSourceRepresentation
    item
    ( Source.getTitle source )
    ( Source.getAuthor source )
    ( Source.getContent source )
    existingTitles

toEditingSourceRepresentation : Item.Item -> String -> String -> String -> ( List String ) -> Element Msg
toEditingSourceRepresentation item title author content existingTitles =
  contentContainer
    [ titleInput item title existingTitles
    , authorInput item author
    , contentInput item content
    ]

exploreTabToolbar: String -> Element Msg
exploreTabToolbar input = 
  Element.el 
    [ Element.width Element.fill
    , Element.height <| Element.px barHeight
    , Element.padding 8
    ]
    <| Element.row [ Element.width Element.fill, Element.spacingXY 8 8 ]
      [ searchInput input (\s -> ExploreTabUpdateInput s)
      ]

graph : ( Int, Int ) -> Viewport.Viewport -> ((List Note.Note, List Link.Link)) -> Element Msg
graph deviceViewport viewport elements =
  Element.el
    [ Element.width Element.fill
    , Element.height Element.fill
    ]
    <| Element.html
      <| Html.div (graphWrapperAttributes viewport) <| [ graph_ deviceViewport viewport elements ]

graphWrapperAttributes : Viewport.Viewport -> ( List ( Html.Attribute Msg ) )
graphWrapperAttributes viewport =
  case Viewport.getState viewport of
    Viewport.Moving _ -> [ Html.Events.onMouseEnter StopMoveView ]
    Viewport.Stationary -> []

graph_ : ( Int, Int ) -> Viewport.Viewport -> ((List Note.Note, List Link.Link)) -> Svg.Svg Msg
graph_ deviceViewport viewport (notes, links) =
  Svg.svg ( graphAttributes deviceViewport viewport )
    <| List.concat
      [ List.filterMap (toGraphLink notes) links
      , List.map toGraphNote notes
      , maybePanningFrame viewport notes
      ]

graphAttributes : ( Int, Int ) -> Viewport.Viewport -> (List ( Svg.Attribute Msg ) )
graphAttributes ( width, _ ) viewport =
  let
      mouseEventDecoder =
        Json.Decode.map2 Viewport.MouseEvent
        ( Json.Decode.field "offsetX" Json.Decode.int )
        ( Json.Decode.field "offsetY" Json.Decode.int )
  in
  case Viewport.getState viewport of
    Viewport.Moving _ ->
      [ Svg.Attributes.viewBox <| Viewport.getViewbox viewport
        , Svg.Events.on "mousemove" <| Json.Decode.map MoveView mouseEventDecoder
        , Svg.Events.onMouseUp StopMoveView
        , Svg.Attributes.width "100%"
        , Svg.Attributes.height "100%"
      ]
    Viewport.Stationary -> 
      [ Svg.Attributes.viewBox <| Viewport.getViewbox viewport
        , Svg.Events.on "mousedown" <| Json.Decode.map StartMoveView mouseEventDecoder
        , Svg.Attributes.width "100%"
        , Svg.Attributes.height "100%"
      ]

toGraphNote: Note.Note -> Svg.Svg Msg
toGraphNote note =
  case Note.getGraphState note of
    Note.Expanded width height ->
      Svg.g [ Svg.Attributes.transform <| Note.getTransform note ]
        [ Svg.rect
            [ Svg.Attributes.width <| String.fromInt width
            , Svg.Attributes.height <| String.fromInt height
            , Svg.Attributes.fill "none"
            ]
            []
        , Svg.foreignObject
          [ Svg.Attributes.width <| String.fromInt width
          , Svg.Attributes.height <| String.fromInt height
          ]
          <| [ Element.layoutWith
            { options = [ Element.noStaticStyleSheet ] }
            [ Element.width <| Element.px width, Element.height <| Element.px height ]
            <| Element.column
              [ Element.width Element.fill
              , Element.height Element.fill
              , Element.Border.width 3
              ]
              [ Element.Input.button [Element.alignRight]
                { onPress = Just <| CompressNote note
                , label = Element.text "X"
                }
              , Element.Input.button
                [ Element.width Element.fill
                , Element.height Element.fill
                , Element.Font.size 8
                ]
                { onPress = Just <| AddItem Nothing <| Slipbox.OpenNote note
                , label = Element.paragraph
                  [ Element.scrollbarY ]
                  [ Element.text <| Note.getContent note ]
                }
              ]
              ]
        ]
    Note.Compressed radius ->
      Svg.circle
        [ Svg.Attributes.cx <| String.fromFloat <| Note.getX note
        , Svg.Attributes.cy <| String.fromFloat <| Note.getY note
        , Svg.Attributes.r <| String.fromInt radius
        , Svg.Attributes.fill <| noteColor <| Note.getVariant note
        , Svg.Attributes.cursor "Pointer"
        , Svg.Events.onClick <| ExpandNote note
        ]
        []

toGraphLink: (List Note.Note) -> Link.Link -> ( Maybe ( Svg.Svg Msg ) )
toGraphLink notes link =
  let
    maybeGetNoteByIdentifier = \identifier -> List.head <| List.filter (identifier link) notes
  in
  Maybe.map2 svgLine (maybeGetNoteByIdentifier Link.isSource) (maybeGetNoteByIdentifier Link.isTarget)

svgLine : Note.Note -> Note.Note -> Svg.Svg Msg
svgLine note1 note2 =
  Svg.line 
    [ Svg.Attributes.x1 <| String.fromFloat <| Note.getX note1
    , Svg.Attributes.y1 <| String.fromFloat <| Note.getY note1
    , Svg.Attributes.x2 <| String.fromFloat <| Note.getX note2
    , Svg.Attributes.y2 <| String.fromFloat <| Note.getY note2
    , Svg.Attributes.stroke "rgb(0,0,0)"
    , Svg.Attributes.strokeWidth "2"
    ] 
    []

maybePanningFrame: Viewport.Viewport -> ( List Note.Note ) -> ( List ( Svg.Svg Msg ) )
maybePanningFrame viewport notes =
  let
      maybeAttr = Viewport.getPanningAttributes viewport notes
  in
  case maybeAttr of
    Just attr ->
      [ Svg.g
        [ Svg.Attributes.transform attr.bottomRight]
        [ Svg.rect
          [ Svg.Attributes.width attr.outerWidth
          , Svg.Attributes.height attr.outerHeight
          , Svg.Attributes.style "border: 2px solid gray;"
          , Svg.Attributes.fillOpacity "0.1"
          ]
          []
        , Svg.rect
          [ Svg.Attributes.width attr.innerWidth
          , Svg.Attributes.height attr.innerHeight
          , Svg.Attributes.style attr.innerStyle
          , Svg.Attributes.transform attr.innerTransform
          ]
          []
        ]
      ]
    Nothing -> []

noteTabToolbar: String -> Element Msg
noteTabToolbar input = 
  Element.el 
    [ Element.width Element.fill
    , Element.height <| Element.px barHeight
    , Element.padding 8
    ]
    <| Element.row [ Element.width Element.fill, Element.spacingXY 8 8 ]
      [ searchInput input (\s -> NoteTabUpdateInput s)
      ]

toOpenNoteButton : ( Maybe Item.Item ) -> Note.Note -> Element Msg
toOpenNoteButton maybeItemOpenedFrom note =
  Element.el 
    [ Element.paddingXY 8 0
    , Element.spacingXY 8 8
    , Element.Border.solid
    , Element.Border.color Color.gray
    , Element.Border.width 4
    , Element.width Element.fill
    ] 
    <| Element.Input.button
      [ Element.width Element.fill, Element.height Element.fill]
      { onPress = Just <| AddItem maybeItemOpenedFrom <| Slipbox.OpenNote note
      , label = toNoteRepresentationFromNote note
      }

toAssociatedNoteButton : ( Maybe Item.Item ) -> Note.Note -> Element Msg
toAssociatedNoteButton maybeItemOpenedFrom note =
  Element.el
    [ Element.paddingXY 8 0, Element.spacingXY 8 8
    , Element.Border.solid, Element.Border.color Color.gray
    , Element.Border.width 4
    ]
    <| Element.Input.button []
      { onPress = Just <| AddItem maybeItemOpenedFrom <| Slipbox.OpenNote note
      , label = toAssociatedNoteRepresentationFromNote note
      }

sourceTabToolbar: String -> Element Msg
sourceTabToolbar input =
  Element.row
    [ Element.width Element.fill
    , Element.padding 8
    , Element.spacingXY 8 8
    , Element.height <| Element.px barHeight
    ] 
    [ searchInput input SourceTabUpdateInput
    ]

toOpenSourceButton : Source.Source -> Element Msg
toOpenSourceButton source =
  Element.el
    [ Element.paddingXY 8 0, Element.spacingXY 8 8
    , Element.Border.solid
    , Element.Border.color Color.heliotropeGrayRegular
    , Element.Border.width 4
    ]
    <| Element.Input.button []
      { onPress = Just <| AddItem Nothing <| Slipbox.OpenSource source
      , label = toSourceRepresentationFromSource source
      }

-- COLORS
noteColor : Note.Variant -> String
noteColor variant =
  case variant of
    Note.Question -> "rgba(250, 190, 88, 1)"
    Note.Regular -> "rgba(137, 196, 244, 1)"

-- UTILITIES

searchInput : String -> (String -> Msg) -> Element Msg
searchInput input onChange = Element.Input.text
  [Element.width Element.fill] 
  { onChange = onChange
  , text = input
  , placeholder = Nothing
  , label = Element.Input.labelLeft [] <| Element.text "search"
  }

createNoteButton : ( Maybe Item.Item ) -> Element Msg
createNoteButton maybeItem =
  smallOldLavenderButton
    { onPress = Just <| AddItem maybeItem Slipbox.NewNote
    , label = Element.el
      [ Element.centerX
      , Element.centerY
      , Element.Font.heavy
      , Element.Font.color Color.white
      ]
      <| Element.text "Create Note"
    }

createSourceButton : ( Maybe Item.Item ) -> Element Msg
createSourceButton maybeItem =
  smallOldLavenderButton
    { onPress = Just <| AddItem maybeItem Slipbox.NewSource
    , label = Element.el
      [ Element.centerX
      , Element.centerY
      , Element.Font.heavy
      , Element.Font.color Color.white
      ] <| Element.text "Create Source"
    }

createQuestionButton : ( Maybe Item.Item ) -> Element Msg
createQuestionButton maybeItem =
  smallOldLavenderButton
    { onPress = Just <| AddItem maybeItem Slipbox.NewQuestion
    , label = Element.el
      [ Element.centerX
      , Element.centerY
      , Element.Font.heavy
      , Element.Font.color Color.white
      ] <| Element.text "Create Question"
    }

editButton: Item.Item -> Element Msg
editButton item =
  smallOldLavenderButton
    { onPress = Just <| UpdateItem item Slipbox.Edit
    , label = Element.text "Edit"
    }

deleteButton: Item.Item -> Element Msg
deleteButton item =
  smallRedButton
    { onPress = Just <| UpdateItem item Slipbox.PromptConfirmDelete
    , label = Element.text "Delete"
    }

dismissButton: Item.Item -> Element Msg
dismissButton item =
  Element.Input.button
    [ Element.width Element.fill
    , Element.height Element.fill
    , Element.Font.heavy
    ]
    { onPress = Just <| DismissItem item
    , label = Element.text "X"
    }

contentInput: Item.Item -> String -> Element Msg
contentInput item input =
  Element.Input.multiline
    []
    { onChange = (\s -> UpdateItem item <| Slipbox.UpdateContent s )
    , text = input
    , placeholder = Nothing
    , label = Element.Input.labelAbove [] <| Element.text "Content"
    , spellcheck = True
    }

questionInput: Item.Item -> String -> Element Msg
questionInput item input =
  Element.Input.multiline
    []
    { onChange = (\s -> UpdateItem item <| Slipbox.UpdateContent s )
    , text = input
    , placeholder = Nothing
    , label = Element.Input.labelAbove [] <| Element.text "Question"
    , spellcheck = True
    }

sourceInput: Int -> Item.Item -> String -> (List String) -> Element Msg
sourceInput itemId item input suggestions =
  let
    sourceInputid = "Source: " ++ (String.fromInt itemId)
    dataitemId = "Sources: " ++ (String.fromInt itemId)
    suggestionsWithNA = "n/a" :: suggestions
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
          , Html.Events.onInput (\s -> UpdateItem item <| Slipbox.UpdateSource s)
          ]
          []
        , Html.datalist 
          [ Html.Attributes.id dataitemId ]
          <| List.map toHtmlOption suggestionsWithNA
        ]

chooseSubmitButton : Item.Item -> Bool -> Element Msg
chooseSubmitButton item canSubmit =
  if canSubmit then
    submitButton item
  else
    Element.none

submitButton : Item.Item -> Element Msg
submitButton item =
  smallOldLavenderButton
    { onPress = Just <| UpdateItem item Slipbox.Submit
    , label = Element.text "Submit"
    }

confirmButton : Item.Item -> Element Msg
confirmButton item =
  smallRedButton
    { onPress = Just <| UpdateItem item Slipbox.Submit
    , label = Element.text "Confirm"
    }

cancelButton : Item.Item -> Element Msg
cancelButton item =
  smallRedButton
    { onPress = Just <| UpdateItem item Slipbox.Cancel
    , label = Element.text "Cancel"
    }

titleInput : Item.Item -> String -> ( List String ) -> Element Msg
titleInput item input existingTitles =
  let
    titleLabel =
      if Source.titleIsValid existingTitles input then
        Element.text "Title"
      else
        Element.text "Title is not valid. Titles must be unique and Please use a different title than 'n/a'"
  in
  Element.Input.multiline
    []
    { onChange = (\s -> UpdateItem item <| Slipbox.UpdateTitle s )
    , text = input
    , placeholder = Nothing
    , label = Element.Input.labelAbove [] titleLabel
    , spellcheck = True
    }

authorInput : Item.Item -> String -> Element Msg
authorInput item input =
  Element.Input.multiline
    []
    { onChange = ( \s -> UpdateItem item <| Slipbox.UpdateAuthor s )
    , text = input
    , placeholder = Nothing
    , label = Element.Input.labelAbove [] <| Element.text "Author"
    , spellcheck = True
    }

-- MISC VIEW FUNCTIONS

toParagraph : String -> Element Msg
toParagraph content =
  Element.paragraph [] [ Element.text content ]

labeledViewBuilder : String -> String -> Element Msg
labeledViewBuilder label content =
  Element.textColumn
    [ Element.spacingXY 0 8, Element.width Element.fill ]
    [ Element.el [ Element.Font.underline ] <| Element.text label
    , Element.paragraph [ Element.width Element.fill ] [ Element.text content ] ]

noteContentView : String -> Element Msg
noteContentView noteContent = labeledViewBuilder "Content" noteContent

noteSourceView : String -> Element Msg
noteSourceView noteSource = labeledViewBuilder "Source" noteSource

questionView : String -> Element Msg
questionView sourceTitle = labeledViewBuilder "Question" sourceTitle

sourceTitleView : String -> Element Msg
sourceTitleView sourceTitle = labeledViewBuilder "Title" sourceTitle

sourceAuthorView : String -> Element Msg
sourceAuthorView sourceAuthor = labeledViewBuilder "Author" sourceAuthor

sourceContentView : String -> Element Msg
sourceContentView sourceContent =
  Element.column
    [ Element.spacingXY 0 8
    , Element.scrollbarY
    , Element.height <| Element.maximum 300 Element.fill
    ]
    [ Element.el [ Element.Font.underline ] <| Element.text "Content"
    , Element.textColumn
      [ Element.spacingXY 0 16]
      ( List.map toParagraph <| String.lines sourceContent )
    ]

-- VIEW BUTTON BUILDER

smallRedButton : { onPress: Maybe Msg, label: Element Msg } -> Element Msg
smallRedButton buttonFunction =
  Element.Input.button
    [ Element.Background.color Color.indianred
    , Element.mouseOver
        [ Element.Background.color Color.thistle ]
    , Element.padding 8
    , Element.Font.heavy
    ]
    buttonFunction

smallOldLavenderButton : { onPress: Maybe Msg, label: Element Msg } -> Element Msg
smallOldLavenderButton buttonFunction =
  Element.Input.button
    [ Element.Background.color Color.oldLavenderRegular
    , Element.mouseOver
      [ Element.Background.color Color.oldLavenderHighlighted
      , Element.Font.color Color.oldLavenderRegular
      ]
    , Element.centerX
    , Element.height Element.fill
    , Element.padding 8
    , Element.Font.heavy
    ]
    buttonFunction