port module Main exposing (..)

import Browser
import Browser.Navigation
import Color
import Create
import Discovery
import Edit
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Export
import File.Download
import FontAwesome.Attributes
import FontAwesome.Solid
import Graph
import Html
import Html.Events
import Html.Attributes
import Link
import Slipbox
import SourceTitle
import Svg
import Svg.Events
import Svg.Attributes
import Element exposing (Element)
import Json.Decode
import Url
import Note
import Source
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

setSlipbox : Slipbox.Slipbox -> Model -> Model
setSlipbox slipbox model =
  case model of
    Session content -> Session { content | slipbox = slipbox }
    _ -> model

setTab : Tab -> Model -> Model
setTab tab model =
  case model of
    Session content -> Session { content | tab = tab }
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

getEdit : Model -> Maybe Edit.Edit
getEdit model =
  case model of
    Session content ->
      case content.tab of
        EditModeTab create -> Just create
        _ -> Nothing
    _ -> Nothing

setEdit : Edit.Edit -> Model -> Model
setEdit create model =
  case model of
    Session content ->
      case content.tab of
        EditModeTab _ ->
          Session { content | tab = EditModeTab create }
        _ -> model
    _ -> model

getExport : Model -> Maybe Export.Export
getExport model =
  case model of
    Session content ->
      case content.tab of
        ExportModeTab export -> Just export
        _ -> Nothing
    _ -> Nothing

setExport : Export.Export -> Model -> Model
setExport export model =
  case model of
    Session content ->
      case content.tab of
        ExportModeTab _ ->
          Session { content | tab = ExportModeTab export }
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
  = EditModeTab Edit.Edit
  | CreateModeTab Create.Create
  | DiscoveryModeTab Discovery.Discovery
  | ExportModeTab Export.Export

type Tab_
  = EditMode
  | CreateMode
  | DiscoveryMode
  | ExportMode

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
  | CreateTabHoverNote Note.Note
  | CreateTabStopHover
  | DiscoveryModeUpdateInput String
  | DiscoveryModeSelectDiscussion Note.Note
  | DiscoveryModeBack
  | DiscoveryModeSelectNote Note.Note
  | DiscoveryModeSubmit
  | DiscoveryModeStartNewDiscussion Note.Note
  | DiscoveryModeHoverNote Note.Note
  | DiscoveryModeStopHover
  | EditModeUpdateInput String
  | EditModeSelectNote Note.Note
  | EditModeConfirmBreakLink Note.Note Link.Link
  | EditModeSelectNoteOnGraph Note.Note
  | EditModeCancel
  | EditModeConfirm
  | EditModeHoverNote Note.Note
  | EditModeStopHover
  | EditModeSelectNoteScreen
  | EditModeAddLink
  | EditModeCancelAddLink
  | EditModeToChooseDiscussion
  | EditModeChooseDiscussion Note.Note
  | EditModeToggleStrayNoteFilter Bool
  | EditModeToConfirmDelete Note.Note
  | ExportModeContinue
  | ExportModeUpdateInput String
  | ExportModeToggleDiscussion Note.Note
  | ExportModeRemove Note.Note
  | ExportModeFinish

update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  let
    getAndSetLambda getter setter updater =
      case getter model of
        Just create ->
          ( setter
            ( updater create )
            model
          , Cmd.none
          )
        Nothing -> ( model, Cmd.none )
    createModeLambda updater = getAndSetLambda getCreate setCreate updater
    discoveryModeLambda updater = getAndSetLambda getDiscovery setDiscovery updater
    editModeLambda updater = getAndSetLambda getEdit setEdit updater
    exportModeLambda updater = getAndSetLambda getExport setExport updater

    getAndSetWithSlipboxLambda getter setter updater =
      case getSlipbox model of
        Just slipbox ->
          case getter model of
            Just create ->
              let
                ( updatedSlipbox, updatedModule ) = updater slipbox create
              in
              ( setSlipbox updatedSlipbox ( setter updatedModule model )
              , changesMade ()
              )
            Nothing -> ( model, Cmd.none )
        Nothing -> ( model, Cmd.none )
    createModeAndSlipboxLambda updater = getAndSetWithSlipboxLambda getCreate setCreate updater
    discoveryModeAndSlipboxLambda updater = getAndSetWithSlipboxLambda getDiscovery setDiscovery updater
    editModeAndSlipboxLambda updater = getAndSetWithSlipboxLambda getEdit setEdit updater
  in
  case message of
    
    LinkClicked _ -> (model, Cmd.none)

    UrlChanged _ -> (model, Cmd.none)

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
            EditMode ->
              case content.tab of
                EditModeTab _ -> ( model, Cmd.none )
                _ ->
                  ( Session { content | tab = EditModeTab Edit.init }
                  , Cmd.none
                  )

            CreateMode ->
              case content.tab of
                CreateModeTab _ -> ( model, Cmd.none )
                _ ->
                  ( Session { content | tab = CreateModeTab Create.init }
                  , Cmd.none
                  )

            DiscoveryMode ->
              case content.tab of
                DiscoveryModeTab _ -> ( model, Cmd.none )
                _ ->
                  ( Session { content | tab = DiscoveryModeTab Discovery.init }
                  , Cmd.none
                  )

            ExportMode ->
              case content.tab of
                ExportModeTab _ -> ( model, Cmd.none )
                _ ->
                  case getSlipbox model of
                    Just slipbox ->
                      ( Session { content | tab = ExportModeTab <| Export.init slipbox }
                      , Cmd.none
                      )
                    _ -> ( model, Cmd.none )

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
    CreateTabCreateAnotherNote -> createModeLambda (\_ -> Create.init)
    CreateTabSubmitNewDiscussion -> createModeLambda Create.submitNewDiscussion
    CreateTabHoverNote note -> createModeLambda <| Create.hover note
    CreateTabStopHover -> createModeLambda Create.stopHover

    DiscoveryModeUpdateInput input -> discoveryModeLambda <| Discovery.updateInput input
    DiscoveryModeSelectDiscussion discussion ->
      case getSlipbox model of
        Just slipbox -> discoveryModeLambda <| Discovery.viewDiscussion discussion slipbox
        Nothing -> ( model, Cmd.none )
    DiscoveryModeBack -> discoveryModeLambda Discovery.back
    DiscoveryModeSelectNote note -> discoveryModeLambda <| Discovery.selectNote note
    DiscoveryModeSubmit -> discoveryModeAndSlipboxLambda Discovery.submit
    DiscoveryModeStartNewDiscussion note ->
      ( setTab ( DiscoveryModeTab <| Discovery.startNewDiscussion note ) model, Cmd.none )
    DiscoveryModeHoverNote note -> discoveryModeLambda <| Discovery.hover note
    DiscoveryModeStopHover -> discoveryModeLambda Discovery.stopHover

    EditModeUpdateInput input -> editModeLambda <| Edit.updateInput input
    EditModeSelectNote note -> ( setTab ( EditModeTab <| Edit.select note ) model, Cmd.none )
    EditModeConfirmBreakLink note link ->
      case getSlipbox model of
        Just slipbox ->
          ( setTab ( EditModeTab <| Edit.toConfirmBreakLink note link slipbox ) model, Cmd.none )
        Nothing -> ( model, Cmd.none )
    EditModeSelectNoteOnGraph note -> editModeLambda <| Edit.selectNoteOnGraph note
    EditModeCancel -> editModeLambda Edit.cancel
    EditModeConfirm -> editModeAndSlipboxLambda Edit.confirm
    EditModeHoverNote note -> editModeLambda <| Edit.hover note
    EditModeStopHover -> editModeLambda Edit.stopHover
    EditModeSelectNoteScreen -> editModeLambda Edit.toSelectNote
    EditModeAddLink -> editModeLambda Edit.addLink
    EditModeCancelAddLink -> editModeLambda Edit.cancelAddLink
    EditModeToChooseDiscussion -> editModeLambda Edit.toChooseDiscussion
    EditModeChooseDiscussion discussion ->
      case getSlipbox model of
        Just slipbox -> editModeLambda <| Edit.chooseDiscussion discussion slipbox
        Nothing -> ( model, Cmd.none )
    EditModeToggleStrayNoteFilter _ -> editModeLambda Edit.toggleStrayNoteFilter
    EditModeToConfirmDelete note ->
      case getSlipbox model of
        Just slipbox ->
          ( setTab ( EditModeTab <| Edit.toConfirmDelete note slipbox ) model, Cmd.none )
        Nothing -> ( model, Cmd.none )
    ExportModeContinue ->
      case getSlipbox model of
        Just slipbox -> exportModeLambda <| Export.continue slipbox
        Nothing -> ( model, Cmd.none )
    ExportModeUpdateInput input -> exportModeLambda <| Export.updateInput input
    ExportModeToggleDiscussion discussion -> exportModeLambda <| Export.toggleDiscussion discussion
    ExportModeRemove note -> exportModeLambda <| Export.remove note
    ExportModeFinish ->
      case getSlipbox model of
        Just slipbox ->
          case getExport model of
            Just export ->
              let
                cmd =
                  case Export.encode slipbox export of
                    Just ( title, file ) -> File.Download.string title "text/plain" file
                    Nothing -> Cmd.none
              in
              ( setExport ( Export.continue slipbox export ) model
              , cmd
              )
            Nothing -> ( model, Cmd.none )
        Nothing -> ( model, Cmd.none )

newContent : Content
newContent =
  Content
    ( CreateModeTab Create.init )
    Slipbox.new
    Expanded

-- PORTS

port open : () -> Cmd msg
port save : String -> Cmd msg
port changesMade : () -> Cmd msg
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
    EditModeTab edit ->
      case Edit.view content.slipbox edit of
        Edit.ViewSelectNote filter strayNoteFilter notes ->
          column
            [ headingCenter "Select Note"
            , Element.Input.checkbox []
              { onChange = EditModeToggleStrayNoteFilter
              , icon = Element.Input.defaultCheckbox
              , checked = strayNoteFilter
              , label = Element.Input.labelLeft [ ] <| Element.text "Notes Unattached to Discussions Only (Stray Notes)"
              }
            , tableWithFilter filter notes EditModeUpdateInput EditModeSelectNote "Note"
            ]

        Edit.ViewNoteSelected note maybeSource directlyLinkedDiscussions connectedNotes ->
          let
            textLambda title text =
              Element.column
                [ Element.padding 8, Element.width Element.fill, Element.Border.width 1, Element.spacingXY 8 8 ]
                [ heading title, textWrap text ]
            source = case maybeSource of
              Just s -> textLambda "Source" <| Source.getTitle s
              Nothing ->
                Element.el [ Element.padding 8, Element.width Element.fill, Element.Border.width 1, Element.spacingXY 8 8 ]
                  <| heading "No Source"
            toDiscussionButton ( n, l ) =
              listButtonWithBreakLink
               ( Just <| EditModeConfirmBreakLink note l ) ( Just <| EditModeSelectNote n ) ( textWrap <| Note.getContent n )
            toLinkedNoteButton ( n, l ) =
              listButtonWithBreakLink
                ( Just <| EditModeConfirmBreakLink note l ) ( Just <| EditModeSelectNote n ) ( textWrap <| Note.getContent n )
            discussionHeader = Element.el [ Element.padding 8 ] <| heading "Directly Linked Discussions"
            discussions = case directlyLinkedDiscussions of
              Just linkedDiscussions -> Element.column
                [ Element.width Element.fill
                , Element.height Element.fill
                , Element.scrollbarY
                ] <|
                discussionHeader :: List.map toDiscussionButton linkedDiscussions
              Nothing -> Element.none
            linkedNotes = case connectedNotes of
              Just tuples ->
                Element.column
                  [ Element.width Element.fill
                  , Element.height Element.fill
                  ]
                  [ Element.el [ Element.padding 8 ] <| heading "Linked Notes"
                  , Element.column
                    [ Element.scrollbarY, Element.width Element.fill, Element.height Element.fill] <|
                    List.map toLinkedNoteButton tuples
                  ]
              Nothing ->
                Element.el
                  [ Element.width Element.fill
                  , Element.height Element.fill
                  , Element.padding 8
                  ] <| heading "No Linked Notes"
          in
          Element.row
            [ Element.width Element.fill
            , Element.height Element.fill
            , Element.spacingXY 8 8
            ]
            [ Element.column
              [ Element.width Element.fill
              , Element.height Element.fill
              ]
              [ Element.el [ Element.padding 8 ] <| heading "Note"
              , textLambda "Content" <| Note.getContent note
              , source
              , discussions
              , button ( Just EditModeToChooseDiscussion ) ( Element.text "Add Links" )
              , button ( Just <| DiscoveryModeStartNewDiscussion note ) ( Element.text "Start New Discussion From Note")
              , button ( Just <| EditModeToConfirmDelete note ) ( Element.text "Delete" )
              , button ( Just EditModeSelectNoteScreen ) ( Element.text "Select Note Screen")
              ]
            , linkedNotes
            ]

        Edit.ViewDiscussionSelected note connectedNotes ->
          let
            textLambda title text =
              Element.column
                [ Element.padding 8, Element.width Element.fill, Element.Border.width 1, Element.spacingXY 8 8 ]
                [ heading title, textWrap text ]
            toLinkedNoteButton ( n, l ) =
              listButtonWithBreakLink
                ( Just <| EditModeConfirmBreakLink note l ) ( Just <| EditModeSelectNote n ) ( textWrap <| Note.getContent n )
            linkedNotes = case connectedNotes of
              Just tuples ->
                Element.column
                  [ Element.width Element.fill
                  , Element.height Element.fill
                  ]
                  [ Element.el [ Element.padding 8 ] <| heading "Linked Notes"
                  , Element.column
                    [ Element.scrollbarY, Element.width Element.fill, Element.height Element.fill] <|
                    List.map toLinkedNoteButton tuples
                  ]
              Nothing ->
                Element.el
                  [ Element.width Element.fill
                  , Element.height Element.fill
                  , Element.padding 8
                  ] <| heading "No Linked Notes"
          in
          Element.row
            [ Element.width Element.fill
            , Element.height Element.fill
            , Element.spacingXY 8 8
            ]
            [ Element.column
              [ Element.width Element.fill
              , Element.height Element.fill
              ]
              [ Element.el [ Element.padding 8 ] <| heading "Discussion"
              , textLambda "Content" <| Note.getContent note
              , button ( Just <| EditModeToConfirmDelete note ) ( Element.text "Delete" )
              , button ( Just EditModeSelectNoteScreen ) ( Element.text "Select Note Screen")
              ]
            , linkedNotes
            ]

        Edit.ViewConfirmBreakLink linkToBreak graph selectedNote hoverNote ->
          Element.row
            [ Element.width Element.fill
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
                [ heading "Selected Note"
                , Element.paragraph [] [ Element.text <| Note.getContent selectedNote ]
                ]
              , Element.column
                [ Element.width Element.fill
                , Element.Border.width 1
                , Element.padding 8
                , Element.spacingXY 10 10
                ]
                [ heading "Confirm Break Link"
                , Element.row
                  [ Element.spacingXY 10 10 ]
                  [ button ( Just EditModeConfirm ) ( Element.text "Confirm" )
                  , button ( Just EditModeCancel ) ( Element.text "Cancel" )
                  ]
                ]
              ]
            , svgGraph graph ( ConfirmBreakLink linkToBreak ) selectedNote hoverNote
            ]

        Edit.AddLinkChooseDiscussionView filter discussions changeMade ->
          let
            buttonNode =
              if changeMade then
                Element.row
                  [ Element.centerX
                  , Element.spacingXY 8 8
                  ]
                  [ button ( Just EditModeConfirm ) ( Element.text "Finish Adding Links" )
                  , button ( Just EditModeCancel ) ( Element.text "Cancel" )
                  ]
              else
                button ( Just EditModeCancel ) ( Element.text "Cancel")
          in
          column
            [ headingCenter "Select Discussion"
            , buttonNode
            , tableWithFilter filter discussions EditModeUpdateInput EditModeChooseDiscussion "Discussion"
            ]

        Edit.AddLinkDiscussionChosenView note discussion graph selectedNote hoverNote notesToLink notesNotSelectable selectedNoteIsLinked ->
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
                    { onPress = Just EditModeCancelAddLink
                    , label = Element.text "Cancel Create Link"
                    }
                  ]
              else
                Element.Input.button
                  [ Element.padding 8
                  , Element.Border.width 1
                  ]
                  { onPress = Just EditModeAddLink
                  , label = Element.text "Create Link"
                  }
          in
          Element.row
            [ Element.width Element.fill
            , Element.height Element.fill
            ]
            [ Element.column
              [ Element.width smallerElement
              , Element.height Element.fill
              ]
              [ Element.textColumn
                [ Element.width Element.fill
                , Element.padding 8
                , Element.Border.width 1
                , Element.spacingXY 10 10
                ]
                [ heading "Discussion"
                , Element.paragraph [] [ Element.text <| Note.getContent discussion ]
                ]
              , Element.textColumn
                [ Element.width Element.fill
                , Element.Border.width 1
                , Element.padding 8
                , Element.spacingXY 10 10
                ]
                [ heading "Created Note"
                , Element.paragraph [] [ Element.text <| Note.getContent note ]
                ]
              , Element.column
                [ Element.width Element.fill
                , Element.Border.width 1
                , Element.padding 8
                , Element.spacingXY 10 10
                ]
                [ Element.textColumn
                  [ Element.spacingXY 10 10
                  ]
                  [ heading "Selected Note"
                  , Element.paragraph [] [ Element.text <| Note.getContent selectedNote ]
                  ]
                , linkNode
                ]
              , button ( Just EditModeToChooseDiscussion ) ( Element.text "Done Linking" )
              ]
            , svgGraph graph ( EditModeAddLinkFlow notesToLink notesNotSelectable ) selectedNote hoverNote
            ]

        Edit.ViewConfirmDelete note graph selectedNote hoveredNote ->
          Element.row
            [ Element.width Element.fill
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
                [ heading "Selected Note"
                , Element.paragraph [] [ Element.text <| Note.getContent selectedNote ]
                ]
              , Element.column
                [ Element.width Element.fill
                , Element.Border.width 1
                , Element.padding 8
                , Element.spacingXY 10 10
                ]
                [ heading "Confirm Delete Note"
                , Element.paragraph [] [ Element.text <| Note.getContent note ]
                , Element.row
                  [ Element.spacingXY 10 10 ]
                  [ button ( Just EditModeConfirm ) ( Element.text "Confirm" )
                  , button ( Just EditModeCancel ) ( Element.text "Cancel" )
                  ]
                ]
              ]
            , svgGraph graph ( ConfirmDelete note ) selectedNote hoveredNote
            ]

    CreateModeTab create ->
      case Create.view content.slipbox create of
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
            [ headingCenter "Write a Permanent Note"
            , coaching coachingOpen coachingText
            , multiline ( \n -> CreateTabUpdateInput <| Create.Note n ) noteInput "Note Content (required)"
            , continueNode
            ]

        Create.ChooseDiscussionView  coachingOpen canContinue note filter filteredDiscussions ->
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
            tableNode =
              if List.isEmpty <| Slipbox.getDiscussions Nothing content.slipbox then
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
                tableWithFilter
                  filter filteredDiscussions ( \s -> CreateTabUpdateInput <| Create.Filter s ) CreateTabToFindLinksForDiscussion "Discussion"
          in
          column
            [ headingCenter "Further Existing Arguments"
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

        Create.DiscussionChosenView createTabGraph note discussion selectedNote selectedNoteIsLinked notesAssociatedToCreatedLinks hoverNote ->
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
          in
          Element.row
            [ Element.width Element.fill
            , Element.height Element.fill
            ]
            [ Element.column
              [ Element.width smallerElement
              , Element.height Element.fill
              ]
              [ Element.textColumn
                [ Element.width Element.fill
                , Element.padding 8
                , Element.Border.width 1
                , Element.spacingXY 10 10
                ]
                [ heading "Discussion"
                , Element.paragraph [] [ Element.text <| Note.getContent discussion ]
                ]
              , Element.textColumn
                [ Element.width Element.fill
                , Element.Border.width 1
                , Element.padding 8
                , Element.spacingXY 10 10
                ]
                [ heading "Created Note"
                , Element.paragraph [] [ Element.text note ]
                ]
              , Element.column
                [ Element.width Element.fill
                , Element.Border.width 1
                , Element.padding 8
                , Element.spacingXY 10 10
                ]
                [ Element.textColumn
                  [ Element.spacingXY 10 10
                  ]
                  [ heading "Selected Note"
                  , Element.paragraph [] [ Element.text <| Note.getContent selectedNote ]
                  ]
                , linkNode
                ]
              , button ( Just CreateTabToChooseDiscussion ) ( Element.text "Done Linking" )
              ]
            , svgGraph createTabGraph ( DiscussionChosenView notesAssociatedToCreatedLinks ) selectedNote hoverNote
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
            [ headingCenter "Is this note the start of its own discussion/a new discussion?"
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
            [ headingCenter "Attribute a Source"
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
              if SourceTitle.validateNewSourceTitle existingTitles title then
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
            [ headingCenter "Create a Source"
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
            [ headingCenter "Success! You've smartly added to your external mind. "
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
        Discovery.ViewDiscussionView discussion selectedNote discussionGraph hoverNote ->
          let
            viewDiscussionNode =
              if Note.getVariant selectedNote == Note.Discussion && ( not <| Note.is discussion selectedNote ) then
                button
                  ( Just <| DiscoveryModeSelectDiscussion selectedNote )
                  ( Element.el [ Element.centerX ] <| Element.text "Go to Discussion" )
              else if Note.getVariant selectedNote == Note.Regular then
                button
                  ( Just <| DiscoveryModeStartNewDiscussion selectedNote )
                  ( Element.el [ Element.centerX ] <| Element.text "Designate New Discussion Entry Point" )
              else
                Element.none
          in
          Element.row
            [ Element.width Element.fill
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
                [ heading "Selected Discussion"
                , Element.paragraph [] [ Element.text <| Note.getContent discussion ]
                ]
              , Element.textColumn
                [ Element.width Element.fill
                , Element.Border.width 1
                , Element.padding 8
                , Element.spacingXY 10 10
                ]
                [ heading "Selected Note"
                , Element.paragraph [] [ Element.text <| Note.getContent selectedNote ]
                , button
                  ( Just <| EditModeSelectNote selectedNote )
                  ( Element.el [ Element.centerX ] <| Element.text "Open Note")
                , viewDiscussionNode
                ]
              , button ( Just DiscoveryModeBack ) ( Element.text "Back" )
              ]
            , svgGraph discussionGraph ViewDiscussionView selectedNote hoverNote
            ]

        Discovery.ChooseDiscussionView filterInput ->
          let
            discussionFilter =
              if String.isEmpty filterInput then
                Nothing
              else
                Just filterInput
            discussions = Slipbox.getDiscussions discussionFilter content.slipbox
          in
          column
            [ headingCenter "Select Discussion"
            , tableWithFilter filterInput discussions DiscoveryModeUpdateInput DiscoveryModeSelectDiscussion "Discussion"
            ]

        Discovery.DesignateDiscussionEntryPointView selectedNote input ->
          let
            matchingDiscussionExists = List.any ( \discussion -> Note.getContent discussion == input )
              <| Slipbox.getDiscussions Nothing content.slipbox
            submitNode =
              if matchingDiscussionExists then
                Element.el [ Element.centerX ] <| Element.text "Discussion already exists!"
              else if String.isEmpty input then
                Element.el
                  [ Element.height <| Element.minimum 10 Element.fill
                  , Element.width Element.fill
                  ]
                  Element.none
              else
                button ( Just DiscoveryModeSubmit ) ( Element.text "Submit New Discussion" )
          in
          column
            [ headingCenter "New Discussion Discovery"
            , Element.paragraph
              [ Element.Font.center
              , Element.width <| Element.maximum 800 Element.fill
              , Element.centerX
              ]
              [ Element.text selectedNote
              ]
            , multiline DiscoveryModeUpdateInput input "Discussion"
            , submitNode
            , button ( Just DiscoveryModeBack ) ( Element.text "Cancel" )
            ]

    ExportModeTab export -> case Export.view export of
      Export.ErrorStateNoDiscussionsView ->
        column
          [ headingCenter "We cannot start export mode without discussions!"
          , Element.paragraph [ Element.width <| Element.maximum 800 Element.fill, Element.centerX ]
            [ Element.text "Export Mode is used to bring discussions out of the app and into your hands! "
            , Element.text "Start some discussions! Adding relevant facts to discussions is the sustainable way to use this application! "
            , Element.text "When you have a discussion you want to do something with, come back here! "
            , Element.text "As you build up your knowledge, your discussions will be come richer with knowledge and more useful to you. "
            , Element.text "We bet you will much to share soon! "
            ]
          -- TODO : What feature can help people more directly create discussions from what they already have?
          , button ( Just <| ChangeTab CreateMode ) ( Element.text "Create Notes and Discussions")
          ]

      Export.InputProjectTitleView title canContinue ->
        let buttonNode = if canContinue then button ( Just ExportModeContinue ) ( Element.text "Continue") else Element.none
        in
        column
          [ headingCenter "Give a title to the project you're exporting!"
          , multiline ExportModeUpdateInput title "Project Title (required)"
          , buttonNode
          ]

      Export.SelectDiscussionsView title filter selectedDiscussions unselectedFilteredDiscussions canContinue ->
        let
          continueNodeWithSelectedDiscussions =
            if canContinue then
              column
                [ headingCenter "Selected Discussions"
                , column
                  <| List.map
                  (\d ->
                    Element.row
                      [ Element.Border.width 1, Element.width Element.fill, Element.width <| Element.maximum 600 Element.fill, Element.centerX ]
                      [ Element.el [ Element.paddingEach leftPad ] <| Element.text <| Note.getContent d
                      , Element.el [ Element.alignRight ] <| button ( Just <| ExportModeToggleDiscussion d ) ( Element.text "Unselect Discussion" )
                      ]
                  )
                  selectedDiscussions
                , button ( Just ExportModeContinue ) ( Element.text "Continue")
                ]
            else
              Element.none
        in
        column
          [ headingCenter "Select Relevant Discussions to Project"
          , Element.el [ Element.centerX ] <| Element.text title
          , continueNodeWithSelectedDiscussions
          , tableWithFilter filter unselectedFilteredDiscussions ExportModeUpdateInput ExportModeToggleDiscussion "Discussion"
          ]

      Export.ConfigureContentView title notes ->
        column
          [ headingCenter "Configure Notes"
          , Element.el [ Element.centerX ] <| Element.text title
          , button ( Just ExportModeFinish ) ( Element.text "Continue")
          , column
            <| List.map
            (\d ->
              Element.row
                [ Element.Border.width 1, Element.width Element.fill, Element.width <| Element.maximum 600 Element.fill, Element.centerX ]
                [ Element.paragraph [ Element.width Element.fill, Element.padding 8 ] [ Element.text <| Note.getContent d ]
                , Element.el [ Element.alignRight ] <| button ( Just <| ExportModeRemove d ) ( Element.text "Remove Note" )
                ]
            )
            notes
          ]

      Export.PromptAnotherExportView ->
        column
          [ headingCenter "Success! Your new project has downloaded. "
          , button ( Just ExportModeContinue ) ( Element.text "Start Another Project" )
          ]


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
  | ToBeDeleted Note.Note X Y
  | CannotSelect X Y

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

toGraphNote : Note.Note -> NotePosition -> GraphNote
toGraphNote selectedNote notePosition =
  let
      note = notePosition.note
      isSelectedNote = Note.is note selectedNote
      isDiscussion = Note.getVariant note == Note.Discussion
      x = String.fromFloat notePosition.x
      y = String.fromFloat notePosition.y
    in
    if isSelectedNote then
      Selected note x y
    else
      if isDiscussion then
        Discussion note x y
      else
        Regular note x y

toGraphNoteWithCreatedLinkStateAndNoSelectState : ( List Note.Note ) -> ( List Note.Note ) -> Note.Note -> NotePosition -> GraphNote
toGraphNoteWithCreatedLinkStateAndNoSelectState notesAssociatedToCreatedLinks unselectableNotes selectedNote notePosition =
  let
    cannotSelect = List.any ( Note.is notePosition.note ) unselectableNotes
  in
  if cannotSelect then
    CannotSelect ( String.fromFloat notePosition.x ) ( String.fromFloat notePosition.y )
  else
    toGraphNoteWithCreatedLinkState notesAssociatedToCreatedLinks selectedNote notePosition

toGraphNoteWithCreatedLinkState : ( List Note.Note ) -> Note.Note -> NotePosition -> GraphNote
toGraphNoteWithCreatedLinkState notesAssociatedToCreatedLinks selectedNote notePosition =
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

toGraphNoteWithDeleteNoteState : Note.Note -> Note.Note -> NotePosition -> GraphNote
toGraphNoteWithDeleteNoteState selectedNote noteToBeDeleted notePosition =
  let
      note = notePosition.note
      isSelectedNote = Note.is note selectedNote
      isNoteToBeDeleted = Note.is note noteToBeDeleted
      isDiscussion = Note.getVariant note == Note.Discussion
      x = String.fromFloat notePosition.x
      y = String.fromFloat notePosition.y
    in
    if isSelectedNote then
      Selected note x y
    else if isNoteToBeDeleted then
      ToBeDeleted note x y
    else
      if isDiscussion then
        Discussion note x y
      else
        Regular note x y


viewGraphNote : ( Note.Note -> Msg ) -> ( Note.Note -> Msg ) -> Msg -> GraphNote -> Svg.Svg Msg
viewGraphNote onClick mouseOver mouseOut graphNote =
  let
    gLambda note content =
      Svg.g
        [ Svg.Attributes.cursor "Pointer"
        , Svg.Events.onClick <| onClick note
        , Svg.Events.onMouseOver <| mouseOver note
        , Svg.Events.onMouseOut mouseOut
        ] content
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

    CannotSelect x y -> svgCircleNoFill x y "5"

    ToBeDeleted note x y -> gLambda note [ svgCircleRedWithBorder x y "5" ]


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

toGraphLinkDeleteLink: (List NotePosition) -> Link.Link -> Link.Link -> ( Maybe ( Svg.Svg Msg ) )
toGraphLinkDeleteLink notePositions linkToDelete link =
  let
    maybeGetNoteByIdentifier =
      \identifier ->
        List.head <|
          List.filter
          ( \notePosition ->
            identifier link notePosition.note
          )
          notePositions
    line note1 note2 =
      if Link.is linkToDelete link then
        Svg.line
          [ Svg.Attributes.x1 <| String.fromFloat <| note1.x
          , Svg.Attributes.y1 <| String.fromFloat <| note1.y
          , Svg.Attributes.x2 <| String.fromFloat <| note2.x
          , Svg.Attributes.y2 <| String.fromFloat <| note2.y
          , Svg.Attributes.stroke "rgb(0,0,0)"
          , Svg.Attributes.strokeWidth "2"
          , Svg.Attributes.strokeDasharray "5,5"
          ] []
      else
        Svg.line
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
          ]
        , Element.column
          [ Element.height biggerElement
          , Element.width Element.fill
          , Element.spacingXY 0 8
          ]
          [ leftNavExpandedButtonLambda Element.alignLeft brainIcon "Discovery Mode" ( ChangeTab DiscoveryMode ) <| sameTab selectedTab DiscoveryMode
          , leftNavExpandedButtonLambda Element.alignLeft toolsIcon "Edit Mode" ( ChangeTab EditMode ) <| sameTab selectedTab EditMode
          , leftNavExpandedButtonLambda Element.alignLeft exportIcon "Export Mode" ( ChangeTab ExportMode ) <| sameTab selectedTab ExportMode
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
          , leftNavContractedButtonLambda Element.alignBottom ( ChangeTab CreateMode) plusIcon <| sameTab selectedTab CreateMode
          ]
        , Element.column
          [ Element.height biggerElement
          , Element.spacingXY 0 8
          ]
          [ leftNavContractedButtonLambda Element.alignLeft ( ChangeTab DiscoveryMode ) brainIcon <| sameTab selectedTab DiscoveryMode
          , leftNavContractedButtonLambda Element.alignLeft ( ChangeTab EditMode ) toolsIcon <| sameTab selectedTab EditMode
          , leftNavContractedButtonLambda Element.alignLeft ( ChangeTab ExportMode ) exportIcon <| sameTab selectedTab ExportMode
          ]
        ]

sameTab : Tab -> Tab_ -> Bool
sameTab tab tab_ =
  case tab of
    EditModeTab _ ->
      case tab_ of
        EditMode -> True
        _ -> False

    CreateModeTab _ ->
      case tab_ of
        CreateMode -> True
        _ -> False

    DiscoveryModeTab _ ->
      case tab_ of
        DiscoveryMode -> True
        _ -> False

    ExportModeTab _ ->
      case tab_ of
        ExportMode -> True
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

saveIcon : Element Msg
saveIcon = iconBuilder FontAwesome.Solid.save

brainIcon : Element Msg
brainIcon = iconBuilder FontAwesome.Solid.brain

toolsIcon : Element Msg
toolsIcon = iconBuilder FontAwesome.Solid.tools

exportIcon : Element Msg
exportIcon = iconBuilder FontAwesome.Solid.fileDownload

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
listButton : Maybe Msg -> Element Msg -> Element Msg
listButton onPress label =
  Element.Input.button [ Element.Border.width 2, Element.padding 8 ]
    { onPress = onPress
    , label = label
    }

leftPad = {right=0,top=0,bottom=0,left=8}
rightWidth = {right=1,top=0,bottom=0,left=0}

listButtonWithBreakLink : Maybe Msg -> Maybe Msg -> Element Msg -> Element Msg
listButtonWithBreakLink cancelPress onPress label =
  Element.row
    [ Element.Border.width 1, Element.width Element.fill ]
    [ Element.Input.button
        [ Element.Border.widthEach rightWidth
        , Element.padding 8
        , Element.width Element.fill
        ]
        { onPress = onPress
        , label = label
        }
    , Element.Input.button
      [ Element.height Element.fill
      , Element.width Element.shrink
      , Element.padding 8
      ]
      { onPress = cancelPress
      , label = Element.el [ Element.centerX, Element.centerY ] <| Element.text "Break Link"}
    ]

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

heading title = Element.paragraph [ Element.Font.bold ] [ Element.text title ]
headingCenter title = Element.el [ Element.centerX ] <| heading title

textWrap text = Element.paragraph [] [ Element.text text ]

tableWithFilter : String -> ( List Note.Note ) -> ( String -> Msg ) -> ( Note.Note -> Msg ) -> String -> Element Msg
tableWithFilter filter notes updateFilter onSelect tableTitle =
  Element.column
    [ Element.width <| Element.maximum 600 Element.fill
    , Element.height Element.fill
    , Element.spacingXY 10 10
    , Element.padding 5
    , Element.Border.width 2
    , Element.Border.rounded 6
    , Element.centerX
    ]
    [ multiline updateFilter filter "Filter"
    , Element.row [ Element.width Element.fill ]
      [ Element.el
        [ Element.width Element.fill
        , Element.Font.bold
        , Element.Border.widthEach { bottom = 2, top = 0, left = 0, right = 0 }
        ] <| Element.text tableTitle
      ]
    , Element.el [ Element.width Element.fill ] <| Element.table
      [ Element.width Element.fill
      , Element.padding 8
      , Element.spacingXY 8 8
      , Element.centerX
      , Element.height <| Element.maximum 300 Element.fill
      , Element.scrollbarY
      ]
      { data = List.map ( \q -> { discussion = Note.getContent q, note = q } ) notes
      , columns =
        [ { header = Element.none
          , width = Element.fillPortion 4
          , view = \row -> listButton ( Just <| onSelect row.note ) ( Element.paragraph [] [ Element.text row.discussion ] )
          }
        ]
      }
    ]

-- SVG HELPERS
type TabGraph
 = ConfirmBreakLink Link.Link
 | DiscussionChosenView ( List Note.Note )
 | ViewDiscussionView
 | EditModeAddLinkFlow ( List Note.Note ) ( List Note.Note )
 | ConfirmDelete Note.Note

svgGraph : Graph.Graph -> TabGraph -> Note.Note -> Maybe Note.Note -> Element Msg
svgGraph graph tab selectedNote maybeHoverNote =
  let

    linkLambda filterMap = List.filterMap filterMap graph.links

    notesLambda onSelect onMouseOver onMouseOut mapper =
      List.map ( \n -> viewGraphNote onSelect onMouseOver onMouseOut n ) <| List.map mapper graph.positions

    ( links, notes ) =
      case tab of
        ConfirmBreakLink link ->
          ( linkLambda <| toGraphLinkDeleteLink graph.positions link
          , notesLambda EditModeSelectNoteOnGraph EditModeHoverNote EditModeStopHover ( toGraphNote selectedNote )
          )

        DiscussionChosenView newlyLinkedNotes ->
          ( linkLambda <| toCreateTabGraphLink graph.positions
          , notesLambda CreateTabSelectNote CreateTabHoverNote CreateTabStopHover
            ( toGraphNoteWithCreatedLinkState newlyLinkedNotes selectedNote )
          )

        ViewDiscussionView ->
          ( linkLambda <| toCreateTabGraphLink graph.positions
          , notesLambda DiscoveryModeSelectNote DiscoveryModeHoverNote DiscoveryModeStopHover ( toGraphNote selectedNote )
          )

        EditModeAddLinkFlow newlyLinkedNotes unselectableNotes ->
          ( linkLambda <| toCreateTabGraphLink graph.positions
          , notesLambda EditModeSelectNoteOnGraph EditModeHoverNote EditModeStopHover
            ( toGraphNoteWithCreatedLinkStateAndNoSelectState newlyLinkedNotes unselectableNotes selectedNote )
          )

        ConfirmDelete note ->
          ( linkLambda <| toCreateTabGraphLink graph.positions
          , notesLambda EditModeSelectNoteOnGraph EditModeHoverNote EditModeStopHover
            ( toGraphNoteWithDeleteNoteState selectedNote note )
          )

    legend = Element.el [ Element.alignBottom ] <|
      Element.wrappedRow [ Element.Font.size 9 ]
      [ selectedNoteLegend
      , linkedCircleLegend
      , discussionLegend
      , circleLegend
      , linkBreakLegend
      , cannotSelectCircleLegend
      , toBeDeletedCircleLegend
      ]

    hover =
      case maybeHoverNote of
        Just hoverNote ->
          Element.el
            [ Element.alignTop
            , Element.alignLeft
            , Element.padding 8
            , Element.Font.size 12
            ] <| textWrap <| Note.getContent hoverNote
        Nothing -> Element.none
  in
  Element.el
    [ Element.width biggerElement
    , Element.height Element.fill
    , Element.htmlAttribute <| Html.Attributes.style "position" "relative"
    ] <|Element.el
    [ Element.width Element.fill
    , Element.height Element.fill
    , Element.behindContent legend
    , Element.behindContent hover
    ]
    <| Element.html <| Svg.svg
    [ Svg.Attributes.width "100%"
    , Svg.Attributes.height "100%"
    , Svg.Attributes.viewBox <| computeViewbox graph.positions
    , Svg.Attributes.style "position: absolute"
    ] <| List.concat [ links, notes ]

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

svgCircleRedWithBorder cx cy r =
  Svg.circle
    [ Svg.Attributes.r r
    , Svg.Attributes.fill "rgba(255, 0, 0, 1)"
    , Svg.Attributes.strokeDasharray "5"
    , Svg.Attributes.cx cx
    , Svg.Attributes.cy cy
    ]
    []

svgCircleNoFill cx cy r =
  Svg.circle
    [ Svg.Attributes.r r
    , Svg.Attributes.stroke "rgba(137, 196, 244, 1)"
    , Svg.Attributes.fill "none"
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

svgDashedLine x1 x2 y1 y2 =
  Svg.line
    [ Svg.Attributes.x1 x1
    , Svg.Attributes.x2 x2
    , Svg.Attributes.y1 y1
    , Svg.Attributes.y2 y2
    , Svg.Attributes.stroke "black"
    , Svg.Attributes.strokeDasharray "5,5"
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

cannotSelectCircleLegend =
  Element.row
    []
    [ Element.html <| svgLegend [ svgCircleNoFill "20" "20" "10" ]
    , Element.text "Cannot Select Note"
    ]

toBeDeletedCircleLegend =
  Element.row
    []
    [ Element.html <| svgLegend [ svgCircleRedWithBorder "20" "20" "10" ]
    , Element.text "Cannot Select Note"
    ]

linkBreakLegend =
  Element.row
    []
    [ Element.html <| svgLegend [ svgDashedLine "10" "30" "20" "20"]
    , Element.text "Link to Break"
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