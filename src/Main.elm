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
     Item.NewSource _ source -> newSourceView item source
     Item.ConfirmDiscardNewSourceForm _ source -> confirmDiscardNewSourceFormView item source
     Item.EditingSource _ _ sourceWithEdits -> editingSourceView item sourceWithEdits content.slipbox
     Item.ConfirmDeleteSource _ source -> confirmDeleteSourceView item source content.slipbox
     Item.ConfirmDeleteLink _ note linkedNote _ ->
       let
             noteRepresentation = \n ->
               Element.column []
                 [ noteContentView <| Note.getContent n
                 , noteSourceView <| Note.getSource n
                 , noteVariantView <| Note.getVariant n
                 ]
         in
         Element.column
           []
           [ Element.row
             []
             [ Element.text "Confirm Delete Link between these notes"
             , submitButton item
             , cancelButton item
             ]
           , Element.row
             []
             [ noteRepresentation note
             , noteRepresentation linkedNote
             ]
           ]

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
    , Element.spacingXY 8 0
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

-- NEW SOURCE ITEM VIEW

newSourceView: Item.Item -> Item.NewSourceContent -> Element Msg
newSourceView item source =
  Element.column
    []
    [ titleInput item source.title
    , authorInput item source.author
    , contentInput item source.content
    , cancelButton item
    , chooseSubmitButton item source.canSubmit
    ]

-- CONFIRM DISCARD NEW SOURCE FORM ITEM VIEW

confirmDiscardNewSourceFormView : Item.Item -> Item.NewSourceContent -> Element Msg
confirmDiscardNewSourceFormView item source =
  Element.column
    []
    [ Element.row 
      []
      [ confirmDismissButton item
      , doNotDismissButton item
      ] 
    , sourceTitleView source.title
    , sourceAuthorView source.author
    , noteContentView source.content
    ]

-- EDITING SOURCE VIEW

editingSourceView: Item.Item -> Source.Source -> Slipbox.Slipbox -> Element Msg
editingSourceView item source slipbox =
  Element.column
    []
    [ Element.row 
      []
      [ submitButton item
      , cancelButton item
      ]
    , titleInput item <| Source.getTitle source
    , authorInput item <| Source.getAuthor source
    , contentInput item <| Source.getContent source
    , Element.column [ Element.scrollbarY ]
      <| List.map toLinkedNoteViewNoButtons <| Slipbox.getNotesAssociatedToSource source slipbox
    ]

-- CONFIRM DELETE SOURCE VIEW

confirmDeleteSourceView: Item.Item -> Source.Source -> Slipbox.Slipbox -> Element Msg
confirmDeleteSourceView item source slipbox =
  Element.column
    []
    [ Element.row 
      []
      [ confirmDeleteButton item
      , cancelButton item
      ]
    , sourceTitleView <| Source.getTitle source
    , sourceAuthorView <| Source.getAuthor source
    , noteContentView <| Source.getContent source
    , Element.column [Element.scrollbarY]
      <| List.map toLinkedNoteViewNoButtons <| Slipbox.getNotesAssociatedToSource source slipbox
    ]

-- EXPLORE TAB

exploreTabView: ( Int, Int ) -> String -> Viewport.Viewport -> Slipbox.Slipbox -> Element Msg
exploreTabView deviceViewport input viewport slipbox =
  let
    search =
      if String.isEmpty input then
        Nothing
      else
        Just input
  in
  Element.column
    [ Element.width Element.fill, Element.height Element.fill]
    [ exploreTabToolbar input
    , graph deviceViewport viewport <| Slipbox.getNotesAndLinks search slipbox
    ]

exploreTabToolbar: String -> Element Msg
exploreTabToolbar input = 
  Element.el 
    [Element.width Element.fill, Element.height <| Element.px 50]
    <| Element.row [Element.width Element.fill, Element.paddingXY 8 0, Element.spacingXY 8 8 ]
      [ searchInput input (\s -> ExploreTabUpdateInput s)
      , createNoteButton Nothing
      ]

graph : ( Int, Int ) -> Viewport.Viewport -> ((List Note.Note, List Link.Link)) -> Element Msg
graph deviceViewport viewport elements =
  Element.el [Element.height Element.fill, Element.width Element.fill] 
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

graphAttributes : ( Int, Int ) -> Viewport.Viewport -> (List ( Svg.Attribute Msg ) )
graphAttributes ( width, height ) viewport =
  let
      mouseEventDecoder =
        Json.Decode.map2 Viewport.MouseEvent
        ( Json.Decode.field "offsetX" Json.Decode.int )
        ( Json.Decode.field "offsetY" Json.Decode.int )
  in
  case Viewport.getState viewport of
    Viewport.Moving _ ->
      [ Svg.Attributes.width <| String.fromInt width
        , Svg.Attributes.height <| String.fromInt height
        , Svg.Attributes.viewBox <| Viewport.getViewbox viewport
        , Svg.Events.on "mousemove" <| Json.Decode.map MoveView mouseEventDecoder
        , Svg.Events.onMouseUp StopMoveView
      ]
    Viewport.Stationary -> 
      [ Svg.Attributes.width <| String.fromInt width
        , Svg.Attributes.height <| String.fromInt height
        , Svg.Attributes.viewBox <| Viewport.getViewbox viewport
        , Svg.Events.on "mousedown" <| Json.Decode.map StartMoveView mouseEventDecoder
        -- TODO
        --, Svg.Events.on "wheel" <| Json.Decode.map ZoomView wheelEventDecoder
      ]

toGraphNote: Note.Note -> Svg.Svg Msg
toGraphNote note =
  case Note.getGraphState note of
    Note.Expanded width height ->
      Svg.g [ Svg.Attributes.transform <| Note.getTransform note ]
        [ Svg.rect
            [ Svg.Attributes.width <| String.fromInt width
            , Svg.Attributes.height <| String.fromInt height
            ]
            []
        , Svg.foreignObject []
          <| [ Element.layout [Element.width Element.fill, Element.height Element.fill]
            <| Element.column [Element.width Element.fill, Element.height Element.fill]
              [ Element.Input.button [Element.alignRight]
                { onPress = Just <| CompressNote note
                , label = Element.text "X"
                }
              , Element.Input.button []
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

-- NOTE TAB

noteTabView: String -> Slipbox.Slipbox -> Element Msg
noteTabView input slipbox =
  let
    search =
      if String.isEmpty input then
        Nothing
      else
        Just input
  in
  Element.column [Element.width Element.fill, Element.height Element.fill]
    [ noteTabToolbar input
    , notesView <| Slipbox.getNotes search slipbox
    ]

noteTabToolbar: String -> Element Msg
noteTabToolbar input = 
  Element.el 
    [Element.width Element.fill, Element.height <| Element.px 50]
    <| Element.row [Element.width Element.fill, Element.paddingXY 8 0, Element.spacingXY 8 8 ]
      [ searchInput input (\s -> NoteTabUpdateInput s)
      , createNoteButton Nothing
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
    [ Element.paddingXY 8 0, Element.spacingXY 8 8
    , Element.Border.solid, Element.Border.color gray
    , Element.Border.width 4 
    ] 
    <| Element.Input.button []
      { onPress = Just <| AddItem Nothing <| Slipbox.OpenNote note
      , label = Element.column [] 
        [ Element.paragraph [] [ Element.text <| Note.getContent note]
        , Element.text <| "Source: " ++ (Note.getSource note)
        ]
      }

-- SOURCE TAB

sourceTabView: String -> Slipbox.Slipbox -> Element Msg
sourceTabView input slipbox =
  let
    search =
      if String.isEmpty input then
        Nothing
      else
        Just input
  in
  Element.column 
    [ Element.width Element.fill
    , Element.height Element.fill
    ]
    [ sourceTabToolbar input
    , Element.column 
      [ Element.scrollbarY ]
      <| List.map toSource <| Slipbox.getSources search slipbox
    ]

sourceTabToolbar: String -> Element Msg
sourceTabToolbar input = Element.el 
  [ Element.width Element.fill
  , Element.height <| Element.px 50
  ]
  <| Element.row 
    [ Element.width Element.fill
    , Element.paddingXY 8 0
    , Element.spacingXY 8 8
    ] 
    [ searchInput input SourceTabUpdateInput
    , createSourceButton Nothing
    ]

toSource : Source.Source -> Element Msg
toSource source =
  Element.el
    [ Element.paddingXY 8 0, Element.spacingXY 8 8
    , Element.Border.solid, Element.Border.color gray
    , Element.Border.width 4
    ]
    <| Element.Input.button []
      { onPress = Just <| AddItem Nothing <| Slipbox.OpenSource source
      , label = Element.column []
        [ Element.paragraph []
          [ Element.text <| Source.getTitle source
          , Element.text <| Source.getAuthor source
          , Element.text <| Source.getContent source
          ]
        ]
      }

-- VIEW UTILITIES
gray = Element.rgb255 238 238 238
thistle = Element.rgb255 216 191 216
indianred = Element.rgb255 205 92 92
noteColor : Note.Variant -> String
noteColor variant =
  case variant of
    Note.Index -> "rgba(250, 190, 88, 1)"
    Note.Regular -> "rgba(137, 196, 244, 1)"

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
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| AddItem maybeItem Slipbox.NewNote
    , label = Element.text "Create Note"
    }

createSourceButton : ( Maybe Item.Item ) -> Element Msg
createSourceButton maybeItem = Element.Input.button
  [ Element.Background.color indianred
  , Element.mouseOver
      [ Element.Background.color thistle ]
  , Element.width Element.fill
  ]
  { onPress = Just <| AddItem maybeItem Slipbox.NewSource
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
        Note.Index ->
          { topLeft = 6, bottomLeft = 6, topRight = 0, bottomRight = 0 }
        Note.Regular ->
          { topLeft = 0, bottomLeft = 0, topRight = 6, bottomRight = 6 }
    text =
      case variant of
        Note.Index -> "Index"
        Note.Regular -> "Regular"
    color =
      case variant of
        Note.Index ->
          if Note.Index == variant then
            Element.rgb255 114 159 207
          else
            Element.rgb255 0xFF 0xFF 0xFF
        Note.Regular ->
          if Note.Regular == variant then
            Element.rgb255 114 159 207
          else
            Element.rgb255 0xFF 0xFF 0xFF
  in
    Element.el
      [ Element.paddingEach { left = 20, right = 20, top = 10, bottom = 10 }
      , Element.Border.roundEach { topLeft = 6, bottomLeft = 6, topRight = 0, bottomRight = 0 }
      , Element.Border.widthEach { left = 2, right = 2, top = 2, bottom = 2 }
      , Element.Border.color <| Element.rgb255 0xC0 0xC0 0xC0
      , Element.Background.color <| color
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

-- Using function currying or partial applying, I could have create functions that are styled buttons like red button and blue button.
-- Then use those to create the buttons that are used for application logic.