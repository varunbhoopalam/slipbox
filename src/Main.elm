port module Main exposing (..)

import Browser
import Browser.Navigation
import Color
import Create
import Discovery
import Element.Background
import Element.Border
import Element.Events
import Element.Font
import Element.Input
import FontAwesome.Attributes
import FontAwesome.Solid
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
import Url
import Note
import Source
import Item
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

type Model
  = Setup
  | FailureToParse
  | Session Content

updateTab : Tab -> Model -> Model
updateTab tab model =
  case model of
    Session content -> Session { content | tab = tab }
    _ -> model

setSlipbox : Slipbox.Slipbox -> Model -> Model
setSlipbox slipbox model =
  case model of
    Session content -> Session { content | slipbox = slipbox }
    _ -> model

getSlipbox : Model -> ( Maybe Slipbox.Slipbox )
getSlipbox model =
  case model of
    Session content -> Just content.slipbox
    _ -> Nothing

getCreate : Model -> Maybe Create.Create
getCreate model =
  case model of
    Session content ->
      case content.tab of
        CreateModeTab create -> Just create
        _ -> Nothing
    _ -> Nothing

setCreate : Create.Create -> Model -> Model
setCreate create model =
  case model of
    Session content ->
      case content.tab of
        CreateModeTab _ ->
          Session { content | tab = CreateModeTab create }
        _ -> model
    _ -> model

getDiscovery : Model -> Maybe Discovery.Discovery
getDiscovery model =
  case model of
    Session content ->
      case content.tab of
        DiscoveryModeTab create -> Just create
        _ -> Nothing
    _ -> Nothing

setDiscovery : Discovery.Discovery -> Model -> Model
setDiscovery create model =
  case model of
    Session content ->
      case content.tab of
        DiscoveryModeTab _ ->
          Session { content | tab = DiscoveryModeTab create }
        _ -> model
    _ -> model

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
  = NotesTab String
  | SourcesTab String
  | WorkspaceTab
  | DiscussionsTab String
  | CreateModeTab Create.Create
  | DiscoveryModeTab Discovery.Discovery

type Tab_
  = Workspace
  | Notes
  | Sources
  | Discussions
  | CreateMode
  | Discovery

-- INIT

init : () -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init _ _ _ =
  ( Setup
  , Cmd.none
  )

-- UPDATE
type Msg
  = LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url
  | NoteTabUpdateInput String
  | SourceTabUpdateInput String
  | AddItem ( Maybe Item.Item ) Slipbox.AddAction
  | UpdateItem Item.Item Slipbox.UpdateAction
  | DismissItem Item.Item
  | InitializeNewSlipbox
  | FileRequested
  | FileLoaded String
  | FileSaved Int
  | FileDownload
  | ChangeTab Tab_
  | ToggleSideNav
  | CreateTabToggleCoaching
  | CreateTabNextStep
  | CreateTabToFindLinksForDiscussion Note.Note
  | CreateTabToChooseDiscussion
  | CreateTabCreateLinkForSelectedNote
  | CreateTabRemoveLink
  | CreateTabSelectNote Note.Note
  | CreateTabContinueWithSelectedSource Source.Source
  | CreateTabNoSource
  | CreateTabNewSource
  | CreateTabSubmitNewSource
  | CreateTabUpdateInput Create.Input
  | CreateTabCreateAnotherNote
  | CreateTabSubmitNewDiscussion
  | DiscoveryModeUpdateInput String
  | DiscoveryModeSelectDiscussion Note.Note
  | DiscoveryModeBack
  | DiscoveryModeSelectNote Note.Note

update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  let
    updateSlipboxWrapper = \s -> case getSlipbox model of
       Just slipbox ->
         ( setSlipbox (s slipbox) model, Cmd.none )
       _ -> ( model, Cmd.none)

    createModeLambda createUpdate =
      case getCreate model of
        Just create ->
          ( setCreate
            ( createUpdate create )
            model
          , Cmd.none
          )
        Nothing -> ( model, Cmd.none )
    discoveryModeLambda discoveryUpdate =
      case getDiscovery model of
        Just discovery ->
          ( setDiscovery
            ( discoveryUpdate discovery )
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

    NoteTabUpdateInput input ->
      case model of
        Session content ->
          case content.tab of
            NotesTab _ ->
              ( updateTab ( NotesTab input ) model, Cmd.none )
            _ -> ( model, Cmd.none)
        _ -> ( model, Cmd.none)
    
    SourceTabUpdateInput input ->
      case model of
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

    UpdateItem item updateAction -> updateSlipboxWrapper <| Slipbox.updateItem item updateAction

    DismissItem item -> updateSlipboxWrapper <| Slipbox.dismissItem item

    InitializeNewSlipbox ->
      case model of
        Setup ->
          ( Session newContent, Cmd.none)
        _ -> ( model, Cmd.none )

    FileRequested ->
      case model of
        Setup -> ( model, open () )
        _ -> ( model, Cmd.none )

    FileLoaded fileContentAsString ->
      case model of
        Setup ->
          let
            maybeSlipbox = Json.Decode.decodeString Slipbox.decode fileContentAsString
          in
          case maybeSlipbox of
            Ok slipbox ->
              ( Session <| Content ( CreateModeTab Create.init ) slipbox Expanded
              , Cmd.none
              )
            Err _ -> ( FailureToParse, Cmd.none )
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

    ChangeTab tab ->
      case model of
        Session content ->
          case tab of
            Notes ->
              case content.tab of
                NotesTab _ -> ( model, Cmd.none )
                _ ->
                  ( Session { content | tab = NotesTab "" }
                  , Cmd.none
                  )
            Sources ->
              case content.tab of
                SourcesTab _ -> ( model, Cmd.none )
                _ ->
                  ( Session { content | tab = SourcesTab "" }
                  , Cmd.none
                  )

            Workspace ->
              ( updateTab WorkspaceTab model, Cmd.none )

            Discussions ->
              case content.tab of
                DiscussionsTab _ -> ( model, Cmd.none )
                _ ->
                  ( Session { content | tab = DiscussionsTab "" }
                  , Cmd.none
                  )

            CreateMode ->
              case content.tab of
                CreateModeTab _ -> ( model, Cmd.none )
                _ ->
                  ( Session { content | tab = CreateModeTab Create.init }
                  , Cmd.none
                  )

            Discovery ->
              case content.tab of
                DiscoveryModeTab _ -> ( model, Cmd.none )
                _ ->
                  ( Session { content | tab = DiscoveryModeTab Discovery.init }
                  , Cmd.none
                  )

        _ -> ( model, Cmd.none )

    ToggleSideNav ->
      case model of
        Session content ->
          ( Session { content | sideNavState = toggle content.sideNavState }
          , Cmd.none
          )

        _ -> ( model, Cmd.none )

    CreateTabToggleCoaching -> createModeLambda Create.toggleCoachingModal
    CreateTabNextStep -> createModeLambda Create.next
    CreateTabToFindLinksForDiscussion discussion ->
      case getSlipbox model of
        Just slipbox -> createModeLambda <| Create.toAddLinkState discussion slipbox
        Nothing -> ( model, Cmd.none )
    CreateTabToChooseDiscussion -> createModeLambda Create.toChooseDiscussionState
    CreateTabCreateLinkForSelectedNote -> createModeLambda Create.createLink
    CreateTabRemoveLink -> createModeLambda Create.removeLink
    CreateTabSelectNote newSelectedNote -> createModeLambda <| Create.selectNote newSelectedNote
    CreateTabUpdateInput input -> createModeLambda <| Create.updateInput input
    CreateTabContinueWithSelectedSource source -> createModeAndSlipboxLambda <| Create.selectSource source
    CreateTabNoSource -> createModeAndSlipboxLambda Create.noSource
    CreateTabNewSource -> createModeLambda Create.newSource
    CreateTabSubmitNewSource -> createModeAndSlipboxLambda Create.submitNewSource
    CreateTabCreateAnotherNote -> createModeLambda (\c -> Create.init)
    CreateTabSubmitNewDiscussion -> createModeLambda Create.submitNewDiscussion

    DiscoveryModeUpdateInput input -> discoveryModeLambda <| Discovery.updateInput input
    DiscoveryModeSelectDiscussion discussion ->
      case getSlipbox model of
        Just slipbox -> discoveryModeLambda <| Discovery.viewDiscussion discussion slipbox
        Nothing -> ( model, Cmd.none )
    DiscoveryModeBack -> discoveryModeLambda Discovery.back
    DiscoveryModeSelectNote note -> discoveryModeLambda <| Discovery.selectNote note


newContent : Content
newContent =
  Content
    ( CreateModeTab Create.init )
    Slipbox.new
    Expanded

-- PORTS

port open : () -> Cmd msg
port save : String -> Cmd msg
port fileContent : (String -> msg) -> Sub msg
port fileSaved : (Int -> msg) -> Sub msg

-- SUBSCRIPTIONS
subscriptions: Model -> Sub Msg
subscriptions _ =
  Sub.batch
    [ fileContent FileLoaded
    , fileSaved FileSaved
    ]

-- VIEW
versionString = "0.1"
webpageTitle = "Slipbox " ++ versionString
smallerElement = Element.fillPortion 1000
biggerElement = Element.fillPortion 1618

view: Model -> Browser.Document Msg
view model =
  case model of
    Setup -> { title = webpageTitle , body = [ setupView ] }
    FailureToParse -> { title = webpageTitle, body = [ Element.layout [] <| Element.text "Failure to read file, please reload the page." ] }
    Session content -> { title = webpageTitle, body = [ sessionView content ] }

setupView : Html.Html Msg
setupView =
  Html.div
    [ Html.Attributes.style "height" "100%"
    , Html.Attributes.style "width" "100%"
    ]
    [ FontAwesome.Styles.css
    , Element.layout
      [ Element.inFront setupOverlay ]
      <| Element.el
        [ Element.alpha 0.3, Element.height Element.fill, Element.width Element.fill ]
        <| sessionNode newContent
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
            { onPress = Just InitializeNewSlipbox
            , label = Element.el [ Element.centerX, Element.Font.underline ] <| Element.text "Start New"
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

sessionView : Content -> Html.Html Msg
sessionView content =
  layoutWithFontAwesomeStyles <| sessionNode content

sessionNode : Content -> Element Msg
sessionNode content =
  Element.row
    [ Element.width Element.fill
    , Element.height Element.fill
    ]
    [ leftNav content.sideNavState content.tab content.slipbox
    , Element.el
      [ Element.width biggerElement
      , Element.height Element.fill]
      <| tabView content
    ]

contactUrl = "https://github.com/varunbhoopalam/slipbox"

-- TAB
tabView: Content -> Element Msg
tabView content =
  case content.tab of
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

    DiscussionsTab input ->
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
              <| Slipbox.getDiscussions ( searchConverter input ) content.slipbox
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
                [ Element.text
                  """
                  Transform your learning into clear, concise notes with one idea. Write as if you'll forget all about this note.
                  When you come across it again, you should be able to read and understand. Take your time, this isn't always an easy endeavor.
                  """
                ]
            continueNode =
              if canContinue then
                button ( Just CreateTabNextStep ) ( Element.text "Next" )
              else
                Element.none
          in
          column
            [ Element.el
              [ Element.centerX
              , Element.Font.heavy
              ] <|
              Element.text "Write a Permanent Note"
            , coaching coachingOpen coachingText
            , multiline ( \n -> CreateTabUpdateInput <| Create.Note n ) noteInput "Note Content (required)"
            , continueNode
            ]

        Create.ChooseDiscussionView  coachingOpen canContinue note discussionsRead ->
          let
            coachingText =
              Element.paragraph
                [ Element.Font.center
                , Element.width <| Element.maximum 800 Element.fill
                , Element.centerX
                ]
                [ Element.text
                  """
                  Add to existing discussions by linking relevant notes/ideas to that discussion. Click a discussion to get started!
                  Linking knowledge can anything from finding supporting arguments, expanding on a thought, and especially finding counter arguments.
                  Because of confirmation bias, it is hard for us to gather information that opposes what we already know.
                  """
                ]
            continueLabel =
              if canContinue then
                  ( Element.text "Continue without linking" )
              else
                  ( Element.text "Next" )
            discussions = Slipbox.getDiscussions Nothing content.slipbox
            discussionTabularData =
              let
                toDiscussionRecord =
                  \q ->
                    { read = List.any ( Note.is q) discussionsRead
                    , discussion = Note.getContent q
                    , note = q
                    }
              in
              List.map toDiscussionRecord discussions

            tableNode =
              if List.isEmpty discussions then
                Element.paragraph
                  [ Element.Font.center
                  , Element.width <| Element.maximum 800 Element.fill
                  , Element.centerX
                  ]
                  [ Element.text "There are no discussions in your slipbox! "
                  , Element.text "We smartly add to our external mind by framing our minds to the perspective of continuing conversation on discussions that interest us. "
                  , Element.text "Add a discussion in the next step to start linking notes together! "
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
                    , Element.el (Element.width ( Element.fillPortion 4 ) :: headerAttrs) <| Element.text "Discussion"
                    ]
                  , Element.el [ Element.width Element.fill ] <| Element.table
                    [ Element.width Element.fill
                    , Element.spacingXY 8 8
                    , Element.centerX
                    , Element.height <| Element.maximum 600 Element.fill
                    , Element.scrollbarY
                    ]
                    { data = discussionTabularData
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
                                    { onPress = Just <| CreateTabToFindLinksForDiscussion row.note
                                    , label =
                                      Element.paragraph
                                        []
                                        [ Element.text row.discussion
                                        ]
                                    }
                        }
                      ]
                    }
                  ]
          in
          column
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
            , button
              ( Just CreateTabNextStep )
              continueLabel
            , tableNode
            ]

        Create.DiscussionChosenView createTabGraph note discussion selectedNote selectedNoteIsLinked notesAssociatedToCreatedLinks ->
          let
            linkNode =
              if selectedNoteIsLinked then
                Element.column
                  [ Element.width Element.fill
                  ]
                  [ Element.text "Linked"
                  , Element.Input.button
                    [ Element.padding 8
                    , Element.Border.width 1
                    ]
                    { onPress = Just CreateTabRemoveLink
                    , label = Element.text "Remove"
                    }
                  ]
              else
                Element.Input.button
                  [ Element.padding 8
                  , Element.Border.width 1
                  ]
                  { onPress = Just CreateTabCreateLinkForSelectedNote
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
                  , List.map ( \n -> viewGraphNote CreateTabSelectNote n ) <|
                    List.map ( toCreateTabGraphNote notesAssociatedToCreatedLinks selectedNote ) createTabGraph.positions
                  ]
          in
          Element.row
            [ Element.inFront <|
              Element.el
                [ Element.padding 16
                , Element.alignRight
                , Element.alignTop
                ] <|
                Element.Input.button
                  [ Element.Border.width 1
                  , Element.padding 8
                  ]
                  { onPress = Just CreateTabToChooseDiscussion
                  , label = Element.text "Done"
                  }
            , Element.width Element.fill
            , Element.height Element.fill
            ]
            [ Element.column
              [ Element.width smallerElement
              , Element.height Element.fill
              ]
              [ Element.textColumn
                [ Element.width Element.fill
                , Element.height <| Element.fillPortion 1
                , Element.padding 8
                , Element.Border.width 1
                , Element.centerY
                , Element.centerX
                , Element.spacingXY 10 10
                ]
                [ Element.paragraph [ Element.Font.bold ] [ Element.text "Discussion" ]
                , Element.paragraph [] [ Element.text <| Note.getContent discussion ]
                ]
              , Element.textColumn
                [ Element.width Element.fill
                , Element.height <| Element.fillPortion 1
                , Element.centerY
                , Element.centerX
                , Element.Border.width 1
                , Element.padding 8
                , Element.spacingXY 10 10
                ]
                [ Element.paragraph [ Element.Font.bold ] [ Element.text "Created Note" ]
                , Element.paragraph [] [ Element.text note ]
                ]
              , Element.column
                [ Element.width Element.fill
                , Element.height <| Element.fillPortion 3
                , Element.Border.width 1
                , Element.padding 8
                , Element.spacingXY 10 10
                ]
                [ Element.textColumn
                  [ Element.spacingXY 10 10
                  ]
                  [ Element.paragraph [ Element.Font.bold ] [ Element.text "Selected Note" ]
                  , Element.paragraph [] [ Element.text <| Note.getContent selectedNote ]
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
                [ selectedNoteLegend
                , linkedCircleLegend
                , discussionLegend
                , circleLegend
                ]
              ]
            ]

        Create.DesignateDiscussionEntryPointView note input ->
          let
            continueNode =
              if String.isEmpty input then
                Element.el
                  [ Element.height <| Element.px 38
                  ] Element.none
              else
                Element.el [ Element.moveRight 16 ] <|
                  button ( Just CreateTabSubmitNewDiscussion ) ( Element.text "Create and Link Discussion" )
          in
          column
            [ Element.el
              [ Element.centerX
              , Element.Font.heavy
              ] <|
              Element.text "Is this note the start of its own discussion/a new discussion?"
            , Element.paragraph
              [ Element.Font.center
              , Element.width <| Element.maximum 800 Element.fill
              , Element.centerX
              ]
              [ Element.text note
              ]
            , multiline ( \n -> CreateTabUpdateInput <| Create.Note n ) input "Discussion"
            , continueNode
            , button ( Just CreateTabNextStep ) ( Element.text "This isn't the start of a new discussion" )
            ]

        Create.ChooseSourceCategoryView note input  ->
          let
            existingSources = Slipbox.getSources Nothing content.slipbox
            maybeSourceSelected = List.head <| List.filter ( \source -> Source.getTitle source == input ) existingSources
            useExistingSourceNode =
              case maybeSourceSelected of
                Just source ->
                  Element.el [ Element.moveRight 16 ] <|
                  button
                    ( Just <| CreateTabContinueWithSelectedSource source )
                    ( Element.text "Use Selected Source" )
                Nothing ->
                  Element.none
          in
          column
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
            , Element.el
              [ Element.centerX
              , Element.onRight useExistingSourceNode
              ] <|
              createTabSourceInput input <| List.map Source.getTitle existingSources
            , button ( Just CreateTabNoSource ) ( Element.text "No Source" )
            , button ( Just CreateTabNewSource ) ( Element.text "New Source" )
            ]

        Create.CreateNewSourceView note title author sourceContent ->
          let
            existingTitles = List.map Source.getTitle <| Slipbox.getSources Nothing content.slipbox
            ( titleLabel, submitNode ) =
              if Source.titleIsValid existingTitles title then
                ( "Title (required)"
                , button ( Just CreateTabSubmitNewSource ) ( Element.text "Submit New Source" )
                )
              else
                if String.isEmpty title then
                  ( "Title (required)"
                  , Element.none
                  )
                else
                  ( "Title is not valid. Titles must be unique and may not be 'n/a' or empty"
                  , Element.none
                  )
            msgLambda updateMethod = \s -> CreateTabUpdateInput <| updateMethod s
          in
          column
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
            , multiline ( msgLambda Create.SourceTitle ) title titleLabel
            , multiline ( msgLambda Create.SourceAuthor ) author "Author (not required)"
            , multiline ( msgLambda Create.SourceContent ) sourceContent "Content (not required)"
            , submitNode
            ]

        Create.PromptCreateAnotherView note ->
          column
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
            , button ( Just CreateTabCreateAnotherNote ) ( Element.text "Create Another Note?" )
            ]

    DiscoveryModeTab discovery ->
      case Discovery.view discovery of
        Discovery.ViewDiscussionView discussion selectedNote discussionGraph ->
          let
            viewGraph = Element.html <|
              Svg.svg
                [ Svg.Attributes.width "100%"
                , Svg.Attributes.height "100%"
                , Svg.Attributes.viewBox <| computeViewbox discussionGraph.positions
                , Svg.Attributes.style "position: absolute"
                ] <|
                List.concat
                  [ List.filterMap (toCreateTabGraphLink discussionGraph.positions) discussionGraph.links
                  , List.map ( \n -> viewGraphNote DiscoveryModeSelectNote n ) <|
                    List.map ( toCreateTabGraphNote [] selectedNote ) discussionGraph.positions
                  ]
            viewDiscussionNode =
              if Note.getVariant selectedNote == Note.Discussion && ( not <| Note.is discussion selectedNote ) then
                button
                  ( Just <| DiscoveryModeSelectDiscussion selectedNote )
                  ( Element.el [ Element.centerX ] <| Element.text "Go to Discussion" )
              else
                Element.none
          in
          Element.row
            [ Element.inFront <|
              Element.el
                [ Element.padding 16
                , Element.alignRight
                , Element.alignTop
                ] <|
                Element.Input.button
                  [ Element.Border.width 1
                  , Element.padding 8
                  ]
                  { onPress = Just DiscoveryModeBack
                  , label = Element.text "Done"
                  }
            , Element.width Element.fill
            , Element.height Element.fill
            ]
            [ Element.column
              [ Element.width smallerElement
              , Element.height Element.fill
              ]
              [ Element.textColumn
                [ Element.width Element.fill
                , Element.Border.width 1
                , Element.padding 8
                , Element.spacingXY 10 10
                ]
                [ Element.paragraph [ Element.Font.bold ] [ Element.text "Discussion" ]
                , Element.paragraph [] [ Element.text <| Note.getContent discussion ]
                ]
              , Element.textColumn
                [ Element.width Element.fill
                , Element.Border.width 1
                , Element.padding 8
                , Element.spacingXY 10 10
                ]
                [ Element.paragraph [ Element.Font.bold ] [ Element.text "Selected Note" ]
                , Element.paragraph [] [ Element.text <| Note.getContent selectedNote ]
                , viewDiscussionNode
                ]
              , selectedNoteLegend
              , discussionLegend
              , circleLegend
              ]
            , Element.el
              [ Element.width biggerElement
              , Element.height Element.fill
              , Element.htmlAttribute <| Html.Attributes.style "position" "relative"
              ]
              viewGraph
            ]

        Discovery.ChooseDiscussionView filterInput ->
          let
            discussionFilter =
              if String.isEmpty filterInput then
                Nothing
              else
                Just filterInput
            discussions = Slipbox.getDiscussions discussionFilter content.slipbox
            discussionTabularData =
              let
                toDiscussionRecord =
                  \q ->
                    { discussion = Note.getContent q
                    , note = q
                    }
              in
              List.map toDiscussionRecord discussions
            tableNode =
              if List.isEmpty discussions then
                Element.paragraph
                  [ Element.Font.center
                  , Element.width <| Element.maximum 800 Element.fill
                  , Element.centerX
                  ]
                  [ Element.text "There are no discussions in your slipbox! "
                  , Element.text "We smartly add to our external mind by framing our minds to the perspective of continuing conversation on discussions that interest us. "
                  , Element.text "Add a discussion to use discovery mode! "
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
                  [ multiline DiscoveryModeUpdateInput filterInput "Filter Discussion"
                  , Element.row [ Element.width Element.fill ]
                    [ Element.el (Element.width Element.fill :: headerAttrs) <| Element.text "Discussion"
                    ]
                  , Element.el [ Element.width Element.fill ] <| Element.table
                    [ Element.width Element.fill
                    , Element.spacingXY 8 8
                    , Element.centerX
                    , Element.height <| Element.maximum 600 Element.fill
                    , Element.scrollbarY
                    ]
                    { data = discussionTabularData
                    , columns =
                      [ { header = Element.none
                        , width = Element.fillPortion 4
                        , view =
                              \row ->
                                  Element.Input.button
                                    []
                                    { onPress = Just <| DiscoveryModeSelectDiscussion row.note
                                    , label =
                                      Element.paragraph
                                        []
                                        [ Element.text row.discussion
                                        ]
                                    }
                        }
                      ]
                    }
                  ]
          in
          column
            [ Element.el
              [ Element.centerX
              , Element.Font.heavy
              ] <|
              Element.text "Select Discussion"
            , tableNode
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

type GraphNote
  = Selected Note.Note X Y
  | Linked Note.Note X Y
  | Discussion Note.Note X Y
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
    isDiscussion = Note.getVariant note == Note.Discussion
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
    if isDiscussion then
      Discussion note x y
    else
      case hasCreatedLink of
        True -> Linked note x y
        False -> Regular note x y


viewGraphNote : ( Note.Note -> Msg ) ->  GraphNote -> Svg.Svg Msg
viewGraphNote msg graphNote =
  let gLambda note content = Svg.g [ Svg.Attributes.cursor "Pointer", Svg.Events.onClick <| msg note ] content
  in
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
      gLambda note
        [ svgRect xCenter yCenter
        , svgRectTransform xCenter yCenter transformation
        ]


    Linked note x y ->
      let
        modify str increment =
          case String.toFloat str of
            Just s -> String.fromFloat <| s + increment
            Nothing -> str
      in
      gLambda note
        [ svgCircle x y "5"
        , svgLine ( modify x -5 ) ( modify x 5 ) y y
        , svgLine x x ( modify y -5 ) ( modify y 5 )
        ]

    Discussion note x y ->
      let
        center str =
          case String.toFloat str of
            Just s -> String.fromFloat <| s - 10
            Nothing -> str
        xCenter = center x
        yCenter = center y
      in
      gLambda note
        [ svgRect xCenter yCenter ]

    Regular note x y -> gLambda note [ svgCircle x y "5" ]

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
    line note1 note2 = Svg.line
      [ Svg.Attributes.x1 <| String.fromFloat <| note1.x
      , Svg.Attributes.y1 <| String.fromFloat <| note1.y
      , Svg.Attributes.x2 <| String.fromFloat <| note2.x
      , Svg.Attributes.y2 <| String.fromFloat <| note2.y
      , Svg.Attributes.stroke "rgb(0,0,0)"
      , Svg.Attributes.strokeWidth "2" ] []
  in
  Maybe.map2 line (maybeGetNoteByIdentifier Link.isSource) (maybeGetNoteByIdentifier Link.isTarget)

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
          , leftNavExpandedButtonLambda Element.alignBottom handPaperIcon "Create Discussion" ( AddItem Nothing Slipbox.NewDiscussion ) False
          ]
        , Element.column
          [ Element.height biggerElement
          , Element.width Element.fill
          , Element.spacingXY 0 8
          ]
          [ leftNavExpandedButtonLambda Element.alignLeft brainIcon "Discovery Mode" ( ChangeTab Discovery ) <| sameTab selectedTab Discovery
          , leftNavExpandedButtonLambda Element.alignLeft toolsIcon "Workspace" ( ChangeTab Workspace ) <| sameTab selectedTab Workspace
          , leftNavExpandedButtonLambda Element.alignLeft fileAltIcon "Notes" ( ChangeTab Notes ) <| sameTab selectedTab Notes
          , leftNavExpandedButtonLambda Element.alignLeft scrollIcon "Sources" ( ChangeTab Sources ) <| sameTab selectedTab Sources
          , leftNavExpandedButtonLambda Element.alignLeft questionIcon "Discussions" ( ChangeTab Discussions ) <| sameTab selectedTab Discussions
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
          , leftNavContractedButtonLambda Element.alignBottom ( AddItem Nothing Slipbox.NewDiscussion ) handPaperIcon False
          ]
        , Element.column
          [ Element.height biggerElement
          , Element.spacingXY 0 8
          ]
          [ leftNavContractedButtonLambda Element.alignLeft ( ChangeTab Discovery ) brainIcon <| sameTab selectedTab Discovery
          , leftNavContractedButtonLambda Element.alignLeft ( ChangeTab Workspace ) toolsIcon <| sameTab selectedTab Workspace
          , leftNavContractedButtonLambda Element.alignLeft ( ChangeTab Notes ) fileAltIcon <| sameTab selectedTab Notes
          , leftNavContractedButtonLambda Element.alignLeft ( ChangeTab Sources ) scrollIcon <| sameTab selectedTab Sources
          , leftNavContractedButtonLambda Element.alignLeft ( ChangeTab Discussions ) questionIcon <| sameTab selectedTab Discussions
          ]
        ]

sameTab : Tab -> Tab_ -> Bool
sameTab tab tab_ =
  case tab of
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

    DiscussionsTab _ ->
      case tab_ of
        Discussions -> True
        _ -> False

    CreateModeTab _ ->
      case tab_ of
        CreateMode -> True
        _ -> False

    DiscoveryModeTab _ ->
      case tab_ of
        Discovery -> True
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
            Note.Discussion -> "Discussion"
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
            Note.Discussion -> "Editing Discussion"
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
            Note.Discussion -> "Delete Discussion"
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

    Item.NewDiscussion _ _ discussion -> itemContainerLambda
      [ conditionalSubmitItemHeader "New Discussion" ( not <| String.isEmpty discussion ) item
      , contentContainer
        [ Element.el [ Element.width Element.fill ] <| discussionInput item discussion
        ]
      ]

    Item.ConfirmDiscardNewDiscussion _ _ discussion -> itemContainerLambda
      [ deleteItemHeader "Confirm Discard New Discussion" item
      , toDiscussionRepresentation discussion
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
  let
    button_ addAction text=
      smallOldLavenderButton
          { onPress = Just <| AddItem maybeItem addAction
          , label = Element.el
            [ Element.centerX
            , Element.centerY
            , Element.Font.heavy
            , Element.Font.color Color.white
            ]
            <| Element.text text
          }
  in
  Element.row
    [ Element.width Element.fill
    , Element.padding 8
    , Element.spacingXY 8 8
    , Element.height Element.fill
    ]
    [ button_ Slipbox.NewNote "Create Note"
    , button_ Slipbox.NewSource "Create Source"
    , button_ Slipbox.NewDiscussion "Create Discussion"
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
    Note.Discussion ->
      contentContainer
        [ Element.el [ Element.width Element.fill] <| discussionView content
        ]

toAssociatedNoteRepresentation : String -> Note.Variant -> Element Msg
toAssociatedNoteRepresentation content variant =
  case variant of
    Note.Regular ->
      contentContainer
        [ Element.el [ Element.width Element.fill] <| labeledViewBuilder "Note" content ]
    Note.Discussion ->
      contentContainer
        [ Element.el [ Element.width Element.fill] <| discussionView content ]

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
    Note.Discussion ->
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

toDiscussionRepresentation : String -> Element Msg
toDiscussionRepresentation dicussion =
  contentContainer
    [ Element.el [ Element.width Element.fill] <| discussionView dicussion
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

-- UTILITIES

searchInput : String -> (String -> Msg) -> Element Msg
searchInput input onChange = Element.Input.text
  [Element.width Element.fill] 
  { onChange = onChange
  , text = input
  , placeholder = Nothing
  , label = Element.Input.labelLeft [] <| Element.text "search"
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
contentInput item input = multiline ( \s -> UpdateItem item <| Slipbox.UpdateContent s ) input "Content"

discussionInput: Item.Item -> String -> Element Msg
discussionInput item input = multiline (\s -> UpdateItem item <| Slipbox.UpdateContent s ) input "Discussion"

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
        "Title"
      else if String.isEmpty input then
        "Title"
      else
        "Title is not valid. Titles must be unique and Please use a different title than 'n/a'"
  in
  multiline (\s -> UpdateItem item <| Slipbox.UpdateTitle s ) input titleLabel

authorInput : Item.Item -> String -> Element Msg
authorInput item input = multiline ( \s -> UpdateItem item <| Slipbox.UpdateAuthor s ) input "Author"

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

discussionView : String -> Element Msg
discussionView sourceTitle = labeledViewBuilder "Discussion" sourceTitle

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

-- Element Helpers

button : Maybe Msg -> Element Msg -> Element Msg
button msg label =
  Element.Input.button
    [ Element.centerX
    , Element.padding 8
    , Element.Border.width 1
    ]
    { onPress =  msg
    , label = label
    }

column : List ( Element Msg ) -> Element Msg
column contents =
  Element.column
    [ Element.padding 16
    , Element.centerX
    , Element.width Element.fill
    , Element.spacingXY 32 32
    ]
    contents

multiline onChange text label =
  Element.Input.multiline
    []
    { onChange = onChange
    , text = text
    , placeholder = Nothing
    , label = Element.Input.labelAbove [] <| Element.text label
    , spellcheck = True
    }

-- SVG HELPERS

svgLegend : List ( Svg.Svg Msg ) -> Svg.Svg Msg
svgLegend contents =
  Svg.svg [ Svg.Attributes.height "40", Svg.Attributes.width "40", Svg.Attributes.viewBox "0 0 40 40" ]
    contents

svgCircle cx cy r =
  Svg.circle
    [ Svg.Attributes.r r
    , Svg.Attributes.fill "rgba(137, 196, 244, 1)"
    , Svg.Attributes.cx cx
    , Svg.Attributes.cy cy
    ]
    []

svgRectTransform x y transform =
  Svg.rect
    [ Svg.Attributes.fill "rgb(0,0,0)"
    , Svg.Attributes.width "20"
    , Svg.Attributes.height "20"
    , Svg.Attributes.x x
    , Svg.Attributes.y y
    , Svg.Attributes.transform transform
    ]
    []

svgRect x y = svgRectTransform x y ""

svgLine x1 x2 y1 y2 =
  Svg.line
    [ Svg.Attributes.x1 x1
    , Svg.Attributes.x2 x2
    , Svg.Attributes.y1 y1
    , Svg.Attributes.y2 y2
    , Svg.Attributes.stroke "black"
    ]
    []

discussionLegend =
  Element.row
    []
    [ Element.html <| svgLegend [ svgRect "10" "10" ]
    , Element.text "Discussion (if not selected)"
    ]

selectedNoteLegend =
  Element.row
    []
    [ Element.html <|
      svgLegend
        [ Svg.g []
          [ svgRect "10" "10"
          , svgRectTransform "10" "10" "rotate(45 20 20)"
          ]
        ]
    , Element.text "Currently Selected Note"
    ]

circleLegend =
  Element.row
    []
    [ Element.html <| svgLegend [ svgCircle "20" "20" "10" ]
    , Element.text "Regular Note"
    ]

linkedCircleLegend =
  Element.row
    []
    [ Element.html <| svgLegend
      [ Svg.g []
        [ svgCircle "20" "20" "10"
        , svgLine "10" "30" "20" "20"
        , svgLine "20" "20" "10" "30"
        ]
      ]
    , Element.text "Note Marked to link (if not selected)"
    ]