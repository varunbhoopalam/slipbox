module Main exposing (..)

import Browser
import Browser.Events
import Browser.Navigation
import Element.Background
import Element.Border
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
  | SetupTab

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
  | ZoomView Viewport.WheelEvent
  | GotViewport Browser.Dom.Viewport
  | GotWindowResize ( Int, Int )
  | InitializeNewSlipbox
  | FileRequested
  | FileSelected File.File
  | FileLoaded String
  | FileDownload
  | Tick Time.Posix

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

    -- TODO
    ZoomView wheelEvent -> ( model, Cmd.none )
      --case getSlipbox model of
      --  Just slipbox -> updateExploreTabViewportLambda <| Viewport.changeZoom wheelEvent <| Slipbox.getNotes Nothing slipbox
      --  Nothing -> ( model, Cmd.none )
    
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
              (ExploreTab "" <| Viewport.initialize model.deviceViewport)
              Slipbox.new
          }
          , Cmd.none)
        _ -> ( model, Cmd.none )

    FileRequested ->
      case model.state of
        Setup -> ( model, File.Select.file ["text/plain"] FileSelected )
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
              ({ model | state = Session <| Content ( ExploreTab "" <| Viewport.initialize model.deviceViewport ) slipbox }
              , Cmd.none
              )
            Err _ -> ( { model | state = FailureToParse }, Cmd.none )
        _ -> ( model, Cmd.none )

    FileDownload ->
      case getSlipbox model of
        Just slipbox -> ( model, File.Download.string "slipbox.slipbox" "text/plain" <| Slipbox.encode slipbox )
        Nothing -> ( model, Cmd.none )

    Tick _ ->
      case getSlipbox model of
        Just slipbox ->
          if Slipbox.simulationIsCompleted slipbox then
            ( updateSlipbox ( Slipbox.tick slipbox ) model, Cmd.none )
          else
            ( model, Cmd.none )
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
        ExploreTab _ _ -> Browser.Events.onAnimationFrame Tick
        _ -> Sub.none
    _ -> Sub.none

-- VIEW

view: Model -> Browser.Document Msg
view model =
  case model.state of
    Setup -> {title = "TODO", body = [ setupView ]}
    Parsing -> {title = "TODO", body = []}
    FailureToParse -> {title = "TODO", body = []}
    Session content -> {title = "MySlipbox", body = [ sessionView model.deviceViewport content ]}

-- SETUP VIEW

setupView : Html.Html Msg
setupView =
  Element.layout []
    <| Element.column []
      [ startNewSlipboxButton
      , requestCsvButton
      ]

startNewSlipboxButton : Element.Element Msg
startNewSlipboxButton =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just InitializeNewSlipbox
    , label = Element.text "Start New"
    }

requestCsvButton : Element.Element Msg
requestCsvButton =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just FileRequested
    , label = Element.text "Load Slipbox"
    }

-- SESSION VIEW

sessionView : ( Int, Int ) -> Content -> Html.Html Msg
sessionView deviceViewport content =
  Element.layout 
    [] 
    <| Element.column 
      [] 
      [ tabView deviceViewport content
      , itemsView content
      ]

-- TAB
tabView: ( Int, Int ) -> Content -> Element Msg
tabView deviceViewport content = 
  case content.tab of
    ExploreTab input viewport -> exploreTabView deviceViewport input viewport content.slipbox
    NotesTab input -> noteTabView input content.slipbox
    SourcesTab input -> sourceTabView input content.slipbox
    -- TODO
    SetupTab -> Element.text "TODO"


-- ITEMS
itemsView: Content -> Element Msg
itemsView content =
  let
      items = List.map ( toItemView content ) <| Slipbox.getItems content.slipbox
  in
    Element.column 
      []
      items
-- TODO: add div between each item that on hover shows buttons to create an item
-- TODO: figure out if it's necessary to have this same div but always visible either at beginning or end of item list

toItemView: Content -> Item.Item -> Element Msg
toItemView content item =
  case item of
     Item.Note _ note -> itemNoteView item note content.slipbox
     Item.NewNote itemId note -> newNoteView itemId item note content.slipbox
     Item.ConfirmDiscardNewNoteForm _ note -> confirmDiscardNewNoteFormView item note
     Item.EditingNote itemId _ noteWithEdits -> editingNoteView itemId item noteWithEdits content.slipbox
     Item.ConfirmDeleteNote _ note -> confirmDeleteNoteView item note content.slipbox
     Item.AddingLinkToNoteForm _ search note maybeNote -> addingLinkToNoteView item search note maybeNote content.slipbox
     Item.Source _ source -> itemSourceView item source content.slipbox
     Item.NewSource itemId source -> newSourceView itemId source
     Item.ConfirmDiscardNewSourceForm itemId source -> confirmDiscardNewSourceFormView itemId source
     Item.EditingSource itemId originalSource sourceWithEdits -> editingSourceView itemId source content.slipbox
     Item.ConfirmDeleteSource -> confirmDeleteSourceView itemId source content.slipbox
     Item.ConfirmDeleteLink itemId note linkedNote link ->

-- NOTE ITEM

itemNoteView: Item.Item -> Note.Note -> Slipbox.Slipbox -> Element Msg
itemNoteView item note slipbox =
  let
    linkedNotes = Slipbox.getLinkedNotes note slipbox
    canAddLinkToNote = not <| List.isEmpty <| Slipbox.getNotesThatCanLinkToNote note slipbox
    noLinkedNotes = List.isEmpty linkedNotes
    linkedNotesNode =
      if canAddLinkToNote then
        if noLinkedNotes then
          addLinkButton item
        else
          Element.column []
            [ Element.row
              []
              [ Element.text "Linked Notes"
              , addLinkButton item ]
            , Element.column
              []
              <| List.map (toLinkedNoteView item) linkedNotes
            ]
      else
        if noLinkedNotes then
          Element.text "No notes available to link to."
        else
          Element.column []
            [ Element.text "Linked Notes"
            , Element.column
              []
              <| List.map (toLinkedNoteView item) linkedNotes
            ]
  in
  Element.column
    []
    [ Element.row 
      []
      [ editButton item
      , deleteButton item
      , dismissButton item
      ]
    , noteContentView <| Note.getContent note
    , noteSourceView <| Note.getSource note
    , noteVariantView <| Note.getVariant note
    , linkedNotesNode
    ]

addLinkButton: Item.Item -> Element Msg
addLinkButton item =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| UpdateItem item Slipbox.AddLinkForm
    , label = Element.text "Add Link"
    }

toLinkedNoteView: Item.Item -> ( Note.Note, Link.Link ) -> Element Msg
toLinkedNoteView item ( linkedNote, link ) =
  Element.column
    []
    [ noteContentView <| Note.getContent linkedNote
    , noteSourceView <| Note.getSource linkedNote
    , noteVariantView <| Note.getVariant linkedNote
    , removeLinkButton item linkedNote link
    ]

removeLinkButton: Item.Item -> Note.Note -> Link.Link -> Element Msg
removeLinkButton item linkedNote link =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| UpdateItem item <| Slipbox.PromptConfirmRemoveLink linkedNote link
    , label = Element.text "Remove Link"
    }

-- NEW NOTE ITEM

newNoteView: Int -> Item.Item -> Item.NewNoteContent -> Slipbox.Slipbox -> Element Msg
newNoteView itemId item note slipbox =
  Element.column
    []
    [ contentInput item note.content
    , sourceInput itemId item note.source <| List.map Source.getTitle <| Slipbox.getSources Nothing slipbox
    , chooseVariantButtons item note.variant
    , cancelButton item
    , chooseSubmitButton item note.canSubmit
    ]

-- DISCARD NOTE ITEM

confirmDiscardNewNoteFormView: Item.Item -> Item.NewNoteContent -> Element Msg
confirmDiscardNewNoteFormView item note =
  Element.column
    []
    [ Element.row 
      []
      [ confirmDismissButton item
      , doNotDismissButton item
      ] 
    , noteContentView note.content
    , noteSourceView note.source
    , noteVariantView note.variant
    ]

-- EDITING NOTE ITEM VIEW

toLinkedNoteViewNoButtons: Note.Note -> Element Msg
toLinkedNoteViewNoButtons linkedNote =
  Element.column
    []
    [ noteContentView <| Note.getContent linkedNote
    , noteSourceView <| Note.getSource linkedNote
    , noteVariantView <| Note.getVariant linkedNote
    ]

editingNoteView: Int -> Item.Item -> Note.Note -> Slipbox.Slipbox -> Element Msg
editingNoteView itemId item noteWithEdits slipbox =
  let
    linkedNotes = Slipbox.getLinkedNotes noteWithEdits slipbox
    noLinkedNotes = List.isEmpty linkedNotes
    linkedNotesNode =
      if noLinkedNotes then
        Element.text "No Linked Notes"
      else
        Element.column []
          [ Element.text "Linked Notes"
          , Element.column
            []
            <| List.map toLinkedNoteViewNoButtons <| List.map Tuple.first linkedNotes
          ]
  in
  Element.column
    []
    [ Element.row 
      []
      [ submitButton item
      , cancelButton item
      ]
    , contentInput item <| Note.getContent noteWithEdits
    , sourceInput itemId item (Note.getSource noteWithEdits) <| List.map Source.getTitle <| Slipbox.getSources Nothing slipbox
    , chooseVariantButtons item <| Note.getVariant noteWithEdits
    , linkedNotesNode
    ]

-- CONFIRM DELETE NOTE ITEM VIEW

confirmDeleteNoteView: Item.Item -> Note.Note -> Slipbox.Slipbox -> Element Msg
confirmDeleteNoteView item note slipbox =
  let
    linkedNotes = Slipbox.getLinkedNotes note slipbox
    noLinkedNotes = List.isEmpty linkedNotes
    linkedNotesNode =
      if noLinkedNotes then
        Element.text "No Linked Notes"
      else
        Element.column []
          [ Element.text "Linked Notes"
          , Element.column
            []
            <| List.map toLinkedNoteViewNoButtons <| List.map Tuple.first linkedNotes
          ]
  in
  Element.column
    []
    [ Element.row 
      []
      [ confirmDeleteButton item
      , cancelButton item
      ]
    , noteContentView <| Note.getContent note
    , noteSourceView <| Note.getSource note
    , noteVariantView <| Note.getVariant note
    , linkedNotesNode
    ]

-- ADDING LINK TO NOTE ITEM VIEW

addingLinkToNoteView: Item.Item -> String -> Note.Note -> (Maybe Note.Note) -> Slipbox.Slipbox -> Element Msg
addingLinkToNoteView item search note maybeNote slipbox =
  let
      noteRepresentation = \n ->
        Element.column []
          [ noteContentView <| Note.getContent n
          , noteSourceView <| Note.getSource n
          , noteVariantView <| Note.getVariant n
          ]
      choice =
        case maybeNote of 
          Just chosenNoteToLink ->
            [ submitButton item
            , noteRepresentation chosenNoteToLink
            ]
          Nothing -> 
            [ Element.text "Select note to add link to from below" ]

  in
  Element.column
    []
    [ Element.row
      []
      [ Element.text "Adding Link"
      , cancelButton item
      ]
    , Element.row
      []
      <| noteRepresentation note :: choice
    , Element.column
      []
      [ searchInput search <| ( \inp -> UpdateItem item <| Slipbox.UpdateSearch inp )
      , Element.column [ Element.scrollbarY ]
        <| List.map (toNoteDetailAddingLinkForm item) <| Slipbox.getNotesThatCanLinkToNote note slipbox
      ]
    ]

toNoteDetailAddingLinkForm: Item.Item -> Note.Note -> Element Msg
toNoteDetailAddingLinkForm item note =
  Element.el 
    [ Element.paddingXY 8 0
    , Element.spacing 8
    , Element.Border.solid
    , Element.Border.color gray
    , Element.Border.width 4 
    ] 
    <| Element.Input.button []
      { onPress = Just <| UpdateItem item <| Slipbox.AddLink note
      , label = Element.column [] 
        [ Element.paragraph [] [ Element.text <| Note.getContent note]
        , Element.text <| "Source: " ++ (Note.getSource note)
        ]
      }

-- SOURCE ITEM VIEW

itemSourceView: Item.Item -> Source.Source -> Slipbox.Slipbox -> Element Msg
itemSourceView item source slipbox =
  Element.column
    []
    [ dismissButton item
    , sourceTitleView <| Source.getTitle source
    , sourceAuthorView <| Source.getAuthor source
    , editButton item
    , deleteButton item
    , noteContentView <| Source.getContent source
    , Element.column [ Element.scrollbarY ]
      <| List.map toLinkedNoteViewNoButtons <| Slipbox.getNotesAssociatedToSource source slipbox
    ]

newSourceView: Int -> Item.NewSourceContent -> Element Msg
newSourceView itemId source =
  ElmUI.column 
    []
    [ titleInput itemId source.title
    , authorInput itemId source.author
    , contentInput itemId source.content 
    , cancelButton itemId
    , chooseSubmitButton itemId source.canSubmit
    ]

confirmDiscardNewSourceFormView : Int -> Item.NewSourceContent -> Element Msg
confirmDiscardNewSourceFormView itemId source =
  ElmUI.column 
    []
    [ Element.row 
      []
      [ confirmDismissButton itemId
      , doNotDismissButton itemId
      ] 
    , titleView source.title
    , authorView source.author
    , contentView source.content 
    , saveButtonNotClickable
    ]

editingSourceView: Int -> Source.Source -> Slipbox -> Element Msg
editingSourceView itemId source slipbox =
  ElmUI.column 
    []
    [ Element.row 
      []
      [ saveButton itemId
      , cancelButton itemId
      ]
    , titleInput itemId <| Source.getTitle source
    , authorInput itemId <| Source.getAuthor source
    , contentInput itemId <| Source.getContent source 
    , Element.column
      [Element.scrollbarsY] 
      <| List.map (toLinkedNoteViewNoButtons itemId) 
        <| Slipbox.getNotesAssociatedToSource source slipbox
    ]

confirmDeleteSourceView: Int -> Source.Source -> Slipbox -> Element Msg
confirmDeleteSourceView itemId source slipbox =
  ElmUI.column 
    []
    [ Element.row 
      []
      [ confirmDeleteButton itemId
      , cancelButton itemId
      ]
    , titleView <| Source.getTitle source
    , authorView <| Source.getAuthor source
    , contentView <| Source.getContent source 
    , Element.column
      [Element.scrollbarsY] 
      <| List.map (toLinkedNoteViewNoButtons itemId) 
        <| Slipbox.getNotesAssociatedToSource source slipbox
    ]

-- EXPLORE TAB
exploreTabView: ( Int, Int ) -> String -> Viewport.Viewport -> Slipbox.Slipbox -> Element Msg
exploreTabView deviceViewport input viewport slipbox = Element.column 
  [ Element.width Element.fill, Element.height Element.fill]
  [ exploreTabToolbar input
  , graph deviceViewport viewport <| Slipbox.getNotesAndLinks input slipbox
  ]

exploreTabToolbar: String -> Element Msg
exploreTabToolbar input = 
  Element.el 
    [Element.width Element.fill, Element.height <| Element.px 50]
    <| Element.row [Element.width Element.fill, Element.paddingXY 8 0, Element.spacing 8] 
      [ searchInput input (\s -> ExploreTabUpdateInput s)
      , createNoteButton
      ]

graph : ( Int, Int ) -> Viewport -> ((List Note.Note, List Link.Link)) -> Element Msg
graph deviceViewport viewport elements =
  Element.el [Element.height Element.fill, Element.width Element.fill] 
    <| Element.html 
      <| Html.div (graphWrapperAttributes viewport) <| graph_ deviceViewport viewport elements

graphWrapperAttributes : Viewport.Viewport -> ( List Html.Attributes Msg )
graphWrapperAttributes viewport =
  case Viewport.getState viewport of
    Viewport.Moving ->
      [ Html.Events.onMouseEnter StopMoveView ]
    Viewort.Stationary ->
      []

graph_ : ( Int, Int ) -> Viewport -> ((List Note.Note, List Link.Link)) -> Svg Msg
graph_ deviceViewport viewport (notes, links) =
  Svg.svg (graphAttributes viewport) <| List.map toGraphNote notes 
    :: List.filterMap (toGraphLink notes) links 
    :: panningFrame viewport notes

graphAttributes : ( Int, Int ) -> Viewport -> (List Svg.Attribute Msg)
graphAttributes ( width, height ) viewport =
  let
      mouseEventDecoder = map2 Viewport.MouseEvent (field "offsetX" int) (field "offsetY" int)
  in
  case Viewport.getState viewport of
    Viewport.Moving -> 
      [ Svg.Attributes.width <| width
        , Svg.Attributes.height <| height
        , Svg.Attributes.viewBox <| Viewport.getViewbox viewport
        , Svg.Events.on "mousemove" <| Json.Decode.map MoveView mouseEventDecoder
        , Svg.Events.onMouseUp StopMoveView
      ]
    Viewport.Stationary -> 
      [ Svg.Attributes.width <| Viewport.getSvgContainerWidth viewport
        , Svg.Attributes.height <| Viewport.getSvgContainerHeight viewport
        , Svg.Attributes.viewBox <| Viewport.getViewbox viewport
        , Svg.Events.on "mousedown" <| Json.Decode.map StartMoveView mouseEventDecoder
        , Svg.Events.on "wheel" <| Json.Decode.map ZoomView wheelEventDecoder
      ]

toGraphNote: Note.Note -> Svg Msg
toGraphNote note =
  let
    variant = Note.getVariant note
  in
    case Note.getGraphState note of
      Note.Expanded width height -> 
        Svg.g [Svg.Attributes.transform <| Note.getTransform note]
        [ Svg.rect
            [ Svg.Attributes.width width
            , Svg.Attributes.height height
            ]
        , Svg.foreignObject []
          <| Element.layout [Element.width Element.fill, Element.height Element.fill] 
            <| Element.column [Element.width Element.fill, Element.height Element.fill]
              [ Element.Input.button [Element.alignRight]
                { onPress = Just <| CompressNote note
                , label = Element.text "X"
                }
              , Element.Input.button []
                { onPress = Just <| OpenNote note
                , label = Element.paragraph 
                  [ Element.scrollbarY ] 
                  [ Element.text <| Note.getContent note ] 
                }
              ]
        ]
      Note.Compressed radius ->
        Svg.circle 
          [ Svg.Attributes.cx <| Note.getX note
          , Svg.Attributes.cy <| Note.getY note
          , Svg.Attributes.r <| String.fromInt radius
          , Svg.Attributes.fill <| noteColor variant
          , Svg.Attributes.cursor "Pointer"
          , Svg.Events.onClick <| Just <| ExpandNote note
          ]
          []

toGraphLink: (List Note.Note) -> Link.Link -> (Maybe Svg Msg)
toGraphLink link notes =
  Maybe.map2 svgLine (getSource link notes) (getTarget link notes)

svgLine : Note.Note -> Note.Note -> Svg Msg 
svgLine note1 note2 =
  Svg.line 
    [ Svg.Attributes.x1 <| String.fromFloat <| Note.getX note1
    , Svg.Attributes.y1 <| String.fromFloat <| Note.getY note1
    , Svg.Attribtes.x2 <| String.fromFloat <| Note.getX note2
    , Svg.Attributes.y2 <| String.fromFloat <| Note.getY note2
    , Svg.Attributes.stroke "rgb(0,0,0)"
    , Svg.Attributes.strokeWidth "2"
    ] 
    []

panningFrame: Viewport.Viewport -> ( List Note.Note ) -> Svg Msg
panningFrame viewport =
  let
      attr = Viewport.getPanningAttributes notes viewport
  in
  Svg.g
    [ Svg.Attributes.transform attr.bottomRight] 
    [ Svg.rect
      [ Svg.Attributes.width <| attr.outerWidth viewport
      , Svg.Attributes.height <| attr.outerHeight viewport
      , style "border: 2px solid gray;"
      ] 
      []
    , Svg.rect 
      [ Svg.Attributes.width <| attr.innerWidth viewport
      , Svg.Attributes.height <| attr.innerHeight viewport
      , Svg.Attributes.style <| attr.innerStyle viewport
      , Svg.Attributes.transform <| attr.innerTransform viewport
      ] 
      []
    ]

-- NOTE TAB
noteTabView: String -> Slipbox -> Element Msg
noteTabView search slipbox = 
  Element.column [Element.width Element.fill, Element.height Element.fill]
    [ noteTabToolbar search
    , notesView <| Slipbox.getNotes (toMaybeSearch search) slipbox
    ]

noteTabToolbar: String -> Element Msg
noteTabToolbar input = 
  Element.el 
    [Element.width Element.fill, Element.height <| Element.px 50]
    <| Element.row [Element.width Element.fill, Element.paddingXY 8 0, Element.spacing 8] 
      [ searchInput input (\s -> NoteTabUpdateInput s)
      , createNoteButton
      ]

notesView: (List Note.Note) -> Element Msg
notesView notes = 
  Element.column 
    [ Element.width Element.fill
    , Element.height <| Element.px 500
    , Element.scrollbarY
    ] 
    <| List.map toNoteDetail notes

toNoteDetail: Note.Note -> Element Msg
toNoteDetail note = 
  Element.el 
    [ Element.paddingXY 8 0, Element.spacing 8
    , Element.Border.solid, Element.Border.color gray
    , Element.Border.width 4 
    ] 
    Element.Input.button [] 
      { onPress = Just <| OpenNote note
      , label = Element.column [] 
        [ Element.paragraph [] [ Element.text <| Note.getContent note]
        , Element.text <| "Source: " ++ (Note.getSource note)
        ]
      }

-- SOURCE TAB
sourceTabView: String -> Slipbox.Slipbox -> Element Msg
sourceTabView input sort slipbox = 
  Element.column 
    [ Element.width Element.fill
    , Element.height Element.fill
    ]
    [ sourceTabToolbar model.search
    , Element.column 
      [ Element.scrollbarY ]
      List.map toSource <| Slipbox.getSources input slipbox
    ]

sourceTabToolbar: String -> Element Msg
sourceTabToolbar input = Element.el 
  [ Element.width Element.fill
  , Element.height <| Element.px 50
  ]
  <| Element.row 
    [ Element.width Element.fill
    , Element.paddingXY 8 0
    , Element.spacing 8
    ] 
    [ searchInput input (\s -> SourceTabUpdateInput)
    , createSourceButton
    ]

-- TODO
toSource : Source.Source -> Element Msg
toSource source = Element.text "todo"

-- VIEW UTILITIES
gray = Element.rgb255 238 238 238
thistle = Element.rgb255 216 191 216
indianred = Element.rgb255 205 92 92
noteColor: Note.Variant -> String
noteColor variant =
  case variant of
    Note.Index -> "rgba(250, 190, 88, 1)"
    Note.Regular -> "rgba(137, 196, 244, 1)"

searchInput: String -> (String -> Msg) -> Element Msg
searchInput input onChange = Element.Input.text
  [Element.width Element.fill] 
  { onChange = onChange
  , text = input
  , placeholder = Nothing
  , label = Element.Input.labelLeft [] <| Element.text "search"
  }

createNoteButton: Element Msg
createNoteButton = 
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just NewNoteForm
    , label = Element.text "Create Note"
    }

createSourceButton: Element Msg
createSourceButton = Element.Input.button
  [ Element.Background.color indianred
  , Element.mouseOver
      [ Element.Background.color thistle ]
  , Element.width Element.fill
  ]
  { onPress = Just CreateSource
  , label = Element.text "Create Source"
  }

editButton: Item.Item -> Element Msg
editButton item =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| UpdateItem item Slipbox.Edit
    , label = Element.text "Edit"
    }

deleteButton: Item.Item -> Element Msg
deleteButton item =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| UpdateItem item Slipbox.PromptConfirmDelete
    , label = Element.text "Delete"
    }

dismissButton: Item.Item -> Element Msg
dismissButton item =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| DismissItem item
    , label = Element.text "X"
    }

contentInput: Item.Item -> String -> Element Msg
contentInput item input =
  Element.Input.multiline
    []
    { onChange = (\s -> UpdateItem item <| Slipbox.UpdateContent input )
    , text = input
    , placeholder = Nothing
    , label = Element.Input.labelAbove [] <| Element.text "Content"
    , spellcheck = True
    }

sourceInput: Int -> Item.Item -> String -> (List String) -> Element Msg
sourceInput itemId item input suggestions =
  let
    sourceInputid = "Source: " ++ (String.fromInt itemId)
    dataitemId = "Sources: " ++ (String.fromInt itemId)
  in
    Element.html
      <| Html.div
        []
        [ Html.label 
          [ Html.Attributes.for sourceInputid ]
          [ Html.text "Label:" ]
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
          <| List.map toHtmlOption suggestions
        ]

toHtmlOption: String -> Html.Html Msg
toHtmlOption value =
  Html.option [ Html.Attributes.value value ] []

chooseVariantButtons: Item.Item -> Note.Variant -> Element Msg
chooseVariantButtons item variant =
  Element.Input.radioRow
    [ Element.Border.rounded 6
    , Element.Border.shadow { offset = ( 0, 0 ), size = 3, blur = 10, color = Element.rgb255 0xE0 0xE0 0xE0 }
    ]
    { onChange = (\v -> UpdateItem item <| Slipbox.UpdateVariant v)
    , selected = Just variant
    , label = Element.Input.labelLeft [] <| Element.text "Choose Note Variant"
    , options =
      [ Element.Input.option Note.Index <| variantButton Note.Index
      , Element.Input.option Note.Regular <| variantButton Note.Regular
      ]
    }

variantButton: Note.Variant -> Element Msg
variantButton variant =
  let
    borders =
      case variant of
        Note.Index ->
          { left = 2, right = 2, top = 2, bottom = 2 }
        Note.Regular ->
          { left = 0, right = 2, top = 2, bottom = 2 }
    corners =
      case variant of
        Index ->
          { topLeft = 6, bottomLeft = 6, topRight = 0, bottomRight = 0 }
        Regular ->
    text =
      case variant of
        Index -> "Index"
        Regular -> "Regular"
    color =
      case variant of
        Index -> 
          if Note.Index == variant then
            Element.rgb255 114 159 207
          else
            Element.rgb255 0xFF 0xFF 0xFF
        Regular -> 
          if Note.Regular == variant then
            Element.rgb255 114 159 207
          else
            Element.rgb255 0xFF 0xFF 0xFF
  in
    Element.el
      [ paddingEach { left = 20, right = 20, top = 10, bottom = 10 }
      , Border.roundEach { topLeft = 6, bottomLeft = 6, topRight = 0, bottomRight = 0 }
      , Border.widthEach { left = 2, right = 2, top = 2, bottom = 2 }
      , Border.color <| Element.rgb255 0xC0 0xC0 0xC0
      , Background.color <| color
      ]
      <| Element.el [ Element.centerX, Element.centerY ] <| Element.text text

chooseSubmitButton : Item.Item -> Bool -> Element Msg
chooseSubmitButton item canSubmit =
  if canSubmit then
    submitButton item
  else
    Element.text "Cannot Submit Yet!"

submitButton : Item.Item -> Element Msg
submitButton item =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| UpdateItem item Slipbox.Submit
    , label = Element.text "Submit"
    }

confirmDismissButton : Item.Item -> Element Msg
confirmDismissButton item =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| DismissItem item
    , label = Element.text "Confirm Dismiss"
    }

doNotDismissButton : Item.Item -> Element Msg
doNotDismissButton item =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| UpdateItem item Slipbox.Cancel
    , label = Element.text "Do Not Dismiss"
    }

cancelButton : Item.Item -> Element Msg
cancelButton item =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| UpdateItem item Slipbox.Cancel
    , label = Element.text "Cancel"
    }

confirmDeleteButton : Item.Item -> Element Msg
confirmDeleteButton item =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| UpdateItem item Slipbox.Submit
    , label = Element.text "Confirm Delete Note"
    }

titleInput: Int -> String -> Element Msg
titleInput itemId input =
  Element.Input.multiline
    []
    { onChange : (\s -> UpdateSourceTitle itemId s)
    , text : input
    , placeholder : Nothing
    , label : Element.labelAbove [] <| Element.text "Title"
    , spellcheck : True
    }

authorInput: Int -> String -> Element Msg
authorInput itemId input =
  Element.Input.multiline
    []
    { onChange : (\s -> UpdateSourceAuthor itemId s)
    , text : input
    , placeholder : Nothing
    , label : Element.labelAbove [] <| Element.text "Author"
    , spellcheck : True
    }

-- MISC VIEW FUNCTIONS

noteContentView : String -> Element Msg
noteContentView noteContent =
  Element.paragraph [] [ Element.text noteContent ]

noteSourceView : String -> Element Msg
noteSourceView noteSource =
  Element.paragraph [] [ Element.text noteSource ]

noteVariantView : Note.Variant -> Element Msg
noteVariantView variant =
  let
    text = case variant of
      Note.Regular -> "regular"
      Note.Index -> "index"
  in
  Element.paragraph [] [ Element.text text ]

sourceTitleView : String -> Element Msg
sourceTitleView sourceTitle =
  Element.paragraph [] [ Element.text sourceTitle ]

sourceAuthorView : String -> Element Msg
sourceAuthorView sourceAuthor =
  Element.paragraph [] [ Element.text sourceAuthor ]
