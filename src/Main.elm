module Main exposing (..)

import Browser
import Browser.Events
import Browser.Navigation
import Color
import Element.Background
import Element.Border
import Element.Events
import Element.Font
import Element.Input
import File.Download
import Html
import Html.Events
import Html.Attributes
import Link
import Slipbox
import Svg
import Svg.Events
import Svg.Attributes
import Element exposing ( Element )
import Json.Decode
import Time
import Viewport
import Browser.Dom
import Url
import Task
import Note
import Source
import Item
import File
import File.Select

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

updateSlipbox : Slipbox.Slipbox -> Model -> Model
updateSlipbox slipbox model =
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

type State 
  = Setup 
  | Parsing 
  | FailureToParse 
  | Session Content

-- CONTENT
type alias Content = 
  { tab: Tab
  , slipbox: Slipbox.Slipbox
  }

-- TAB
type Tab
  = ExploreTab String Viewport.Viewport
  | NotesTab String
  | SourcesTab String

type Tab_
  = Explore
  | Notes
  | Sources

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
  | FileSelected File.File
  | FileLoaded String
  | FileDownload
  | Tick Time.Posix
  | ChangeTab Tab_

update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  let
    updateSlipboxWrapper = \s -> case getSlipbox model of
       Just slipbox ->
         ( updateSlipbox (s slipbox) model, Cmd.none )
       _ -> ( model, Cmd.none)
    updateExploreTabViewportLambda = \toViewport ->
      case model.state of
        Session content ->
          case content.tab of
            ExploreTab input viewport ->
              ({ model | state = Session
                { content | tab =
                  ExploreTab input (toViewport viewport)
                }
              }, Cmd.none )
            _ -> ( model, Cmd.none )
        _ -> ( model , Cmd.none)
  in
  case message of
    
    LinkClicked _ -> (model, Cmd.none)

    UrlChanged _ -> (model, Cmd.none)

    ExploreTabUpdateInput input ->
      case model.state of
        Session content ->
          case content.tab of
            ExploreTab _ viewport ->
              ( updateTab ( ExploreTab input viewport ) model, Cmd.none )
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

    AddItem maybeItem addAction -> updateSlipboxWrapper <| Slipbox.addItem maybeItem addAction

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
          ({ model | state =
            Session <| Content
              (ExploreTab "" <| Viewport.initialize (Tuple.first model.deviceViewport, svgGraphHeight) )
              Slipbox.new
          }
          , Cmd.none)
        _ -> ( model, Cmd.none )

    FileRequested ->
      case model.state of
        Setup -> ( model, File.Select.file ["application/json"] FileSelected )
        _ -> ( model, Cmd.none )

    FileSelected file ->
      case model.state of
        Setup ->
          ({ model | state = Parsing}
          , Task.perform FileLoaded (File.toString file)
          )
        _ -> ( model, Cmd.none )

    FileLoaded fileContentAsString ->
      case model.state of
        Parsing ->
          let
            maybeSlipbox = Json.Decode.decodeString Slipbox.decode fileContentAsString
          in
          case maybeSlipbox of
            Ok slipbox ->
              ({ model | state = Session <| Content ( ExploreTab "" <| Viewport.initialize (Tuple.first model.deviceViewport, svgGraphHeight) ) slipbox }
              , Cmd.none
              )
            Err _ -> ( { model | state = FailureToParse }, Cmd.none )
        _ -> ( model, Cmd.none )

    FileDownload ->
      case getSlipbox model of
        Just slipbox -> ( model, File.Download.string "slipbox.json" "application/json" <| Slipbox.encode slipbox )
        Nothing -> ( model, Cmd.none )

    Tick _ ->
      case getSlipbox model of
        Just slipbox ->
          if not <| Slipbox.simulationIsCompleted slipbox then
            ( updateSlipbox ( Slipbox.tick slipbox ) model, Cmd.none )
          else
            ( model, Cmd.none )
        _ -> ( model, Cmd.none )

    ChangeTab tab ->
      case model.state of
        Session content ->
          case tab of
            Explore ->
              case content.tab of
                ExploreTab _ _ -> ( model, Cmd.none )
                _ ->
                  ( { model | state =
                    Session { content | tab = ExploreTab "" <| Viewport.initialize (Tuple.first model.deviceViewport, svgGraphHeight) }
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
        _ -> ( model, Cmd.none )
    

handleWindowInfo: ( Int, Int ) -> Model -> Model
handleWindowInfo windowInfo model = 
  case model.state of
    Session content ->
      case content.tab of
        ExploreTab input viewport ->
          { model | deviceViewport = windowInfo
          , state = Session { content | tab =
            ExploreTab input <| Viewport.updateSvgContainerDimensions windowInfo viewport
            }
          }
        _ -> { model | deviceViewport = windowInfo }
    _ -> { model | deviceViewport = windowInfo }

-- SUBSCRIPTIONS
subscriptions: Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Browser.Events.onResize (\w h -> GotWindowResize (w,h))
    , maybeSubscribeOnAnimationFrame model
    ]

maybeSubscribeOnAnimationFrame : Model -> Sub Msg
maybeSubscribeOnAnimationFrame model =
  case model.state of
    Session content ->
      case content.tab of
        ExploreTab _ _ ->
          if Slipbox.simulationIsCompleted content.slipbox then
            Sub.none
          else
            Browser.Events.onAnimationFrame Tick
        _ -> Sub.none
    _ -> Sub.none

-- VIEW
version = 0.1

view: Model -> Browser.Document Msg
view model =
  case model.state of
    Setup -> { title = String.fromFloat <| version, body = [ setupView ] }
    Parsing -> { title = "Loading", body = [ Element.layout [] <| Element.text "Loading" ] }
    FailureToParse -> { title = "Failure", body = [ Element.layout [] <| Element.text "Failure" ] }
    Session content -> { title = "MySlipbox", body = [ sessionView model.deviceViewport content ] }

-- SETUP VIEW

setupView : Html.Html Msg
setupView =
  Element.layout []
    <| Element.column
      [ Element.height Element.fill
      , Element.width Element.fill
      , Element.Font.color <| Color.white
      , Element.Font.size 24
      ]
      [ headerSetupPage
      , Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.Font.size 36
        , Element.Font.heavy
        ]
        [ startNewSlipboxButton
        , requestCsvButton
        ]
      ]

topHeaderHeight = 30

headerSetupPage : Element.Element Msg
headerSetupPage =
  let
    versionText = Element.el [ Element.centerX, Element.centerY ]
      <| Element.text <| "Slipbox.io Version " ++ ( String.fromFloat version )
  in
  Element.el
    [ Element.height <| Element.px topHeaderHeight
    , Element.width Element.fill
    , Element.Background.color Color.ebonyRegular
    , Element.Font.color <| Color.white
    , Element.Font.size 24
    , Element.inFront versionText
    , Element.paddingXY 8 0
    ]
    aboutButton

aboutButton : Element Msg
aboutButton =
  Element.newTabLink
    [ Element.alignRight
    , Element.Font.color Color.white
    , Element.Font.underline
    , Element.centerY
    ]
    { url = contactUrl
    , label = Element.text "About"
    }

downloadButton : Element Msg
downloadButton =
  Element.Input.button
    [ Element.paddingXY 4 0
    , Element.alignRight
    , Element.Border.rounded 10
    , Element.Border.color Color.white
    , Element.Border.width 2
    ]
    { onPress = Just FileDownload, label = Element.text "Save" }


header : Element.Element Msg
header =
  let
    versionText = Element.el [ Element.centerX, Element.centerY ]
      <| Element.text <| "Slipbox.io Version " ++ ( String.fromFloat version )
  in
  Element.row
    [ Element.height <| Element.px topHeaderHeight
    , Element.width Element.fill
    , Element.Background.color Color.ebonyRegular
    , Element.Font.color <| Color.white
    , Element.Font.size 24
    , Element.inFront versionText
    , Element.paddingXY 4 0
    , Element.spacingXY 8 0
    ]
    [ aboutButton
    , downloadButton
    ]

startNewSlipboxButton : Element.Element Msg
startNewSlipboxButton =
  Element.Input.button
    [ Element.Background.color Color.heliotropeGrayRegular
    , Element.mouseOver
      [ Element.Background.color Color.heliotropeGrayHighlighted
      , Element.Font.color Color.heliotropeGrayRegular
      ]
    , Element.width Element.fill
    , Element.height Element.fill
    ]
    { onPress = Just InitializeNewSlipbox
    , label = Element.el [ Element.centerX, Element.Border.width 1, Element.padding 8 ] <| Element.text "Start New"
    }

requestCsvButton : Element.Element Msg
requestCsvButton =
  Element.Input.button
    [ Element.Background.color Color.oldLavenderRegular
    , Element.mouseOver
      [ Element.Background.color Color.oldLavenderHighlighted
      , Element.Font.color Color.oldLavenderRegular
      ]
    , Element.width Element.fill
    , Element.height Element.fill
    ]
    { onPress = Just FileRequested
    , label = Element.el [ Element.centerX, Element.Border.width 1, Element.padding 8 ] <| Element.text "Load Slipbox"
    }

-- SESSION VIEW

sessionView : ( Int, Int ) -> Content -> Html.Html Msg
sessionView deviceViewport content =
  Element.layout 
    [ Element.inFront header]
    <| Element.column 
      [ Element.width Element.fill
      , Element.moveDown <| toFloat topHeaderHeight ]
      [ tabHeader content.tab
      , tabView deviceViewport content
      , itemsView content
      , Element.el [ Element.height <| Element.px <| barHeight * 2 ] Element.none
      , contact
      ]

contact : Element Msg
contact =
  Element.el
    [ Element.Background.color Color.ebonyRegular
    , Element.width Element.fill
    , Element.height <| Element.px 36
    , Element.padding 8
    ]
    <| Element.newTabLink
      [ Element.centerX
      , Element.Font.color Color.white
      , Element.Font.underline
      ]
      { url = contactUrl
      , label = Element.text "Contact/Contribute"
      }

contactUrl = "https://github.com/varunbhoopalam/slipbox"

-- TAB
tabView: ( Int, Int ) -> Content -> Element Msg
tabView deviceViewport content =
  Element.el
    [ Element.width Element.fill
    , Element.height Element.fill
    , Element.Border.widthEach { bottom = 3, top = 0, right = 0, left = 0 }
    , Element.Border.color Color.heliotropeGrayRegular
    ]
    <| case content.tab of
        ExploreTab input viewport ->
          Element.column
            [ Element.width Element.fill
            ]
            [ exploreTabToolbar input
            , graph deviceViewport viewport <| Slipbox.getNotesAndLinks ( searchConverter input ) content.slipbox
            ]

        NotesTab input ->
          Element.column
            [ Element.width Element.fill
            ]
            [ noteTabToolbar input
            , tabTextContentContainer
              <| List.map ( toOpenNoteButton Nothing )
                <| Slipbox.getNotes ( searchConverter input ) content.slipbox
            ]

        SourcesTab input ->
          Element.column
            [ Element.width Element.fill
            ]
            [ sourceTabToolbar input
            , tabTextContentContainer
              <| List.map toOpenSourceButton
                <| Slipbox.getSources ( searchConverter input ) content.slipbox
            ]

tabTextContentContainer : ( List ( Element Msg ) ) -> Element Msg
tabTextContentContainer contents =
  Element.wrappedRow
    [ Element.scrollbarY
    , Element.height <| Element.px 500
    , Element.padding 8
    , Element.spacingXY 8 8
    ]
    contents

searchConverter : String -> ( Maybe String )
searchConverter input =
  if String.isEmpty input then
    Nothing
  else
    Just input

barHeight = 65

tabHeader : Tab -> Element.Element Msg
tabHeader tab =
  let
    tab_ =
      case tab of
        ExploreTab _ _ -> Explore
        NotesTab _ -> Notes
        SourcesTab _ -> Sources
  in
  Element.row
    [ Element.height <| Element.px barHeight
    , Element.width Element.fill
    , Element.Font.size 36
    , Element.Font.heavy
    ]
    [ tabHeaderBuilder
      { onPress = Just <| ChangeTab Explore
      , label = Element.el [ Element.centerX ] <| Element.text "Explore"
      }
      ( tab_ == Explore )
    , tabHeaderBuilder
      { onPress = Just <| ChangeTab Notes
      , label = Element.el [ Element.centerX ] <| Element.text "Notes"
      }
      ( tab_ == Notes )
    , tabHeaderBuilder
      { onPress = Just <| ChangeTab Sources
      , label = Element.el [ Element.centerX ] <| Element.text "Sources"
      }
      ( tab_ == Sources )
    ]

tabHeaderBuilder : { onPress: Maybe Msg, label: Element Msg } -> Bool -> Element Msg
tabHeaderBuilder content onTab =
  let
    attributes =
      if onTab then
        [ Element.Background.color Color.heliotropeGrayRegular
        , Element.Font.color Color.white
        , Element.width Element.fill
        , Element.height Element.fill
        ]
      else
        [ Element.Background.color Color.heliotropeGrayHighlighted
        , Element.Font.color Color.white
        , Element.width Element.fill
        , Element.height Element.fill
        ]
  in
  Element.Input.button attributes content

-- ITEMS
itemsView: Content -> Element Msg
itemsView content =
  let
      items = List.map ( toItemView content ) <| Slipbox.getItems content.slipbox
  in
    Element.column 
      [ Element.centerX
      , Element.padding 8
      , Element.spacingXY 8 8
      , Element.width Element.fill
      , Element.height Element.fill
      ]
      <|
      List.concat
        [ [ Element.el
          [ Element.Font.heavy
          , Element.Border.width 1
          , Element.padding 4
          , Element.Font.color Color.oldLavenderRegular
          , Element.centerX
          ] <| Element.text "Workspace" ]
        , [ buttonTray Nothing ]
        , items
        ]

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

newItemHeader : String -> Bool -> Item.Item -> Element Msg
newItemHeader text canSubmit item =
  itemHeaderBuilder
    [ headerText text
    , Element.el [ Element.alignRight ] <| cancelButton item
    , Element.el [ Element.alignRight ] <| chooseSubmitButton item canSubmit
    ]

deleteItemHeader : String -> Item.Item -> Element Msg
deleteItemHeader text item =
  itemHeaderBuilder
    [ headerText text
    , Element.el [ Element.alignRight ] <| confirmButton item
    , Element.el [ Element.alignRight ] <| cancelButton item
    ]

editItemHeader : String -> Item.Item -> Element Msg
editItemHeader text item =
  itemHeaderBuilder
    [ headerText text
    , Element.el [ Element.alignRight ] <| submitButton item
    , Element.el [ Element.alignRight ] <| cancelButton item
    ]

toItemView: Content -> Item.Item -> Element Msg
toItemView content item =
  let
    itemContainerLambda =
      \contents ->
        Element.column
          [ Element.spacingXY 4 4
          , Element.centerX
          , Element.width <| Element.maximum 800 Element.fill
          , Element.height Element.shrink
          ]
          [ Element.column
            containerAttributes
            contents
          , onHoverButtonTray item
          ]
  in
  case item of
    Item.Note _ _ note -> itemContainerLambda
      [ normalItemHeader "Note" item
      , toNoteRepresentationFromNote note
      , linkedNotesNode item note content.slipbox
      ]


    Item.NewNote itemId _ note -> itemContainerLambda
      [ newItemHeader "New Note" ( Item.noteCanSubmit note ) item
      , toEditingNoteRepresentation
        itemId item ( List.map Source.getTitle <| Slipbox.getSources Nothing content.slipbox ) note.content note.source
      ]


    Item.ConfirmDiscardNewNoteForm _ _ note -> itemContainerLambda
      [ deleteItemHeader "Discard New Note" item
      , toNoteRepresentation note.content note.source Note.Regular
      ]


    Item.EditingNote itemId _ _ noteWithEdits -> itemContainerLambda
      [ editItemHeader "Editing Note" item
      , toEditingNoteRepresentationFromItemNoteSlipbox itemId item noteWithEdits content.slipbox
      , linkedNotesNodeNoButtons noteWithEdits content.slipbox
      ]


    Item.ConfirmDeleteNote _ _ note -> itemContainerLambda
      [ deleteItemHeader "Delete Note" item
      , toNoteRepresentationFromNote note
      , linkedNotesNodeNoButtons note content.slipbox
      ]


    Item.AddingLinkToNoteForm _ _ search note maybeNote ->
      let
        maybeChoice =
          case maybeNote of
            Just chosenNoteToLink -> toNoteRepresentationFromNote chosenNoteToLink
            Nothing -> Element.paragraph [] [ Element.text "Select note to add link to from below" ]
      in
      itemContainerLambda
        [ newItemHeader "Add Link" ( maybeNote /= Nothing ) item
        , Element.row
          [ Element.width Element.fill ]
          [ toNoteRepresentationFromNote note
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
            [ Element.width Element.fill
            , Element.height <| Element.minimum 100 Element.fill
            , Element.spacingXY 8 0
            , Element.scrollbarY
            ]
              <| List.map (toNoteDetailAddingLinkForm item)
                <| Slipbox.getNotesThatCanLinkToNote note content.slipbox
          ]
        ]


    Item.Source _ _ source -> itemContainerLambda
      [ normalItemHeader "Source" item
      , toSourceRepresentationFromSource source
      , associatedNotesNode item source content.slipbox
      ]


    Item.NewSource _ _ source -> itemContainerLambda
      [ newItemHeader "New Source" ( Item.sourceCanSubmit source ) item
      , toEditingSourceRepresentation item source.title source.author source.content
      ]


    Item.ConfirmDiscardNewSourceForm _ _ source -> itemContainerLambda
      [ deleteItemHeader "Confirm Discard New Source" item
      , toSourceRepresentation source.title source.author source.content
      ]


    Item.EditingSource _ _ _ sourceWithEdits -> itemContainerLambda
      [ editItemHeader "Editing Source" item
      , toEditingSourceRepresentationFromItemSource item sourceWithEdits
      , associatedNotesNode item sourceWithEdits content.slipbox
      ]


    Item.ConfirmDeleteSource _ _ source -> itemContainerLambda
      [ deleteItemHeader "Confirm Delete Source" item
      , toSourceRepresentationFromSource source
      , associatedNotesNode item source content.slipbox
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
      [ newItemHeader "New Question" ( not <| String.isEmpty question ) item
      , contentContainer
        [ Element.el [ Element.width Element.fill ] <| questionInput item question
        ]
      ]

    Item.ConfirmDiscardNewQuestion _ _ question -> itemContainerLambda
      [ deleteItemHeader "Confirm Discard New Question" item
      , toQuestionRepresentation question
      ]

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
          ( List.map (\n -> toOpenNoteButton ( Just item ) n ) associatedNotes )
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
  , Element.height <| Element.minimum 200 Element.fill
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

linkedNotesNodeNoButtons : Note.Note -> Slipbox.Slipbox -> Element Msg
linkedNotesNodeNoButtons noteWithEdits slipbox =
    let
      linkedNotes = Slipbox.getLinkedNotes noteWithEdits slipbox
      noLinkedNotes = List.isEmpty linkedNotes
    in
    if noLinkedNotes then
      Element.none
    else
      Element.column []
        [ Element.text "Linked Notes"
        , Element.column
          []
          <| List.map toNoteRepresentationFromNote <| List.map Tuple.first linkedNotes
        ]

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


toEditingNoteRepresentationFromItemNoteSlipbox : Int -> Item.Item -> Note.Note -> Slipbox.Slipbox -> Element Msg
toEditingNoteRepresentationFromItemNoteSlipbox itemId item note slipbox =
  toEditingNoteRepresentation
    itemId
    item
    ( List.map Source.getTitle <| Slipbox.getSources Nothing slipbox )
    ( Note.getContent note )
    ( Note.getSource note )

toEditingNoteRepresentation : Int -> Item.Item -> ( List String ) -> String -> String -> Element Msg
toEditingNoteRepresentation itemId item titles content source =
  contentContainer
    [ Element.el [ Element.width Element.fill ] <| contentInput item content
    , Element.el [ Element.width Element.fill ] <| sourceInput itemId item source titles
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

toEditingSourceRepresentationFromItemSource : Item.Item -> Source.Source -> Element Msg
toEditingSourceRepresentationFromItemSource item source =
  toEditingSourceRepresentation
    item
    ( Source.getTitle source )
    ( Source.getAuthor source )
    ( Source.getContent source )

toEditingSourceRepresentation : Item.Item -> String -> String -> String -> Element Msg
toEditingSourceRepresentation item title author content =
  contentContainer
    [ titleInput item title
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
    [ Element.height <| Element.px svgGraphHeight
    , Element.width Element.fill
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
      [ List.map toGraphNote notes
      , List.filterMap (toGraphLink notes) links
      , maybePanningFrame viewport notes
      ]

svgGraphHeight = 500

graphAttributes : ( Int, Int ) -> Viewport.Viewport -> (List ( Svg.Attribute Msg ) )
graphAttributes ( width, _ ) viewport =
  let
      mouseEventDecoder =
        Json.Decode.map2 Viewport.MouseEvent
        ( Json.Decode.field "offsetX" Json.Decode.int )
        ( Json.Decode.field "offsetY" Json.Decode.int )
      smallerWidthToAccountForPageWidening = ( width - 50 )
  in
  case Viewport.getState viewport of
    Viewport.Moving _ ->
      [ Svg.Attributes.width <| String.fromInt smallerWidthToAccountForPageWidening
        , Svg.Attributes.height <| String.fromInt svgGraphHeight
        , Svg.Attributes.viewBox <| Viewport.getViewbox viewport
        , Svg.Events.on "mousemove" <| Json.Decode.map MoveView mouseEventDecoder
        , Svg.Events.onMouseUp StopMoveView
      ]
    Viewport.Stationary -> 
      [ Svg.Attributes.width <| String.fromInt smallerWidthToAccountForPageWidening
        , Svg.Attributes.height <| String.fromInt svgGraphHeight
        , Svg.Attributes.viewBox <| Viewport.getViewbox viewport
        , Svg.Events.on "mousedown" <| Json.Decode.map StartMoveView mouseEventDecoder
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
              , Element.Input.button [ Element.width Element.fill, Element.height Element.fill]
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
    [ Element.paddingXY 8 0, Element.spacingXY 8 8
    , Element.Border.solid, Element.Border.color Color.gray
    , Element.Border.width 4 
    ] 
    <| Element.Input.button []
      { onPress = Just <| AddItem maybeItemOpenedFrom <| Slipbox.OpenNote note
      , label = toNoteRepresentationFromNote note
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
      ] <| Element.text "Ask Question"
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

toHtmlOption: String -> Html.Html Msg
toHtmlOption value =
  Html.option [ Html.Attributes.value value ] []

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

titleInput : Item.Item -> String -> Element Msg
titleInput item input =
  Element.Input.multiline
    []
    { onChange = (\s -> UpdateItem item <| Slipbox.UpdateTitle s )
    , text = input
    , placeholder = Nothing
    , label = Element.Input.labelAbove [] <| Element.text "Title"
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

labeledViewBuilder : String -> String -> Element Msg
labeledViewBuilder label content =
  Element.textColumn
    [ Element.spacingXY 0 8 ]
    [ Element.el [ Element.Font.underline ] <| Element.text label
    , Element.paragraph [] [ Element.text content ] ]

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
sourceContentView noteContent =
  Element.textColumn
    [ Element.spacingXY 0 8
    , Element.scrollbarY
    , Element.height <| Element.maximum 300 Element.fill
    ]
    [ Element.el [ Element.Font.underline ] <| Element.text "Content"
    , Element.paragraph [] [ Element.text noteContent ] ]

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