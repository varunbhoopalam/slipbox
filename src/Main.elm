module Main exposing (..)

import Browser as Browser
import Browser.Navigation as Nav
import SourceSummary as SourceSummary
import Html as Html
import Element as ElmUI

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
  Setup |
  Parsing |
  FailureToParse |
  Session Content

-- CONTENT
type alias Content = 
  { tab: Tab
  , slipbox: Slipbox
  , timezone: Timezone
  , device: Device
  }

-- TAB
type Tab = 
  Explore Search Viewport
  Notes Search |
  Sources Search Sort |
  History |
  Setup

-- INIT

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ _ _ =
  ( Setup, Cmd.none)

-- UPDATE
type Msg
  = LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url
  | ExploreTabUpdateInput String
  | CreateNote
  | CompressNote Note.Note
  | OpenNote Note.Note
  | ExpandNote Note.Note
  | CreateSource
  | NoteTabUpdateInput String


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  case message of

    LinkClicked _ -> (model, Cmd.none)

    UrlChanged _ -> (model, Cmd.none)

    ExploreTabUpdateInput input -> 
      case model.tab of
        Explore _ viewport -> ({ model | tab = Explore input viewport }, Cmd.none)
        _ -> (model, Cmd.none)

    ExploreTabUpdateInput input -> 
      case model.tab of
        Notes _ -> ({ model | tab = Notes input }, Cmd.none)
        _ -> (model, Cmd.none)

    CreateNote -> ({ model | slipbox = Slipbox.createNote model.slipbox }, Cmd.none)

    CompressNote note -> ({ model | slipbox = Slipbox.compressNote note model.slipbox }, Cmd.none)

    OpenNote note -> ({ model | slipbox = Slipbox.openNote note model.slipbox }, Cmd.none)

    ExpandNote note -> ({ model | slipbox = Slipbox.expandNote note model.slipbox }, Cmd.none)

    CreateSource -> ({ model | slipbox = Slipbox.createSource model.slipbox }, Cmd.none)

-- SUBSCRIPTIONS
subscriptions: Model -> Sub Msg
subscriptions model =
  case model.page of 
    NotFound -> Sub.none
    Source source -> Sub.map SourceMsg (SourceSummary.subscriptions source)

-- Steps
sourceStep: Model -> (SourceSummary.Model, Cmd SourceSummary.Msg) -> (Model, Cmd Msg)
sourceStep model (summaryModel, sourceMsg) =
  ({model | page = Source summaryModel}, Cmd.map SourceMsg sourceMsg)

-- VIEW
-- Source source -> {title = "TODO", body = [Html.map SourceMsg <| SourceSummary.view source]}

view: Model -> Browser.Document Msg
view model =
  case model of
    Setup -> {title = "TODO", body = []}
    Parsing -> {title = "TODO", body = []}
    FailureToParse -> {title = "TODO", body = []}
    Session content -> {title = "MySlipbox", body = [ sessionView content ]}

sessionView: Content -> Html Msg
sessionView content =
  Element.layout 
    [] 
    <| Element.column 
      [] 
      [ tabView content
      , itemsView content
      ]

-- TAB
tabView: Content -> Element Msg
tabView content = 
  case content.tab of
    Explore search viewport -> exploreTabView search viewport content.slipbox
    Notes search -> noteTabView search content.slipbox
    Sources search ->
    History ->
    Setup ->

-- ITEMS
itemsView: Content -> Element Msg
itemsView content =
  let
      items = List.map (toItemView slipbox) <| Slipbox.getItems content.slipbox
  in
    Element.column 
      []
-- How do I add an item between all items in a list?
-- Is list the correct data structure here?

toItemView: Content -> Item.Item -> Element Msg
toItemView content item =
  case item of
     Item.Note listId note -> itemNoteView listId note content.slipbox
     Item.NewNote listId note -> newNoteView listId note content.slipbox
     Item.ConfirmDismissNewNote listId note -> confirmDismissNewNote listId note content.slipbox
     Item.EditingNote listId originalNote noteWithEdits -> editingNoteView listId originalNote noteWithEdits content.slipbox
     Item.ConfirmDeleteNote listId note -> confirmDeleteNoteView listId note content.slipbox
     -- Invariant for AddingLinkToNote and LinkChosen: If Note is deleted from content.slipbox need to make sure these states are still valid
     -- If they are not valid either remove note from item list or move it back to Note state depending on what happened
     Item.AddingLinkToNote listId search note -> addingLinkToNoteView listId search note content.slipbox
     Item.LinkChosen listId search note noteToLink -> linkChosenView listId search note noteToLink content.slipbox
     Item.Source listId source -> itemSourceView listId source content.timezone content.slipbox
     Item.NewSource listId source -> newSourceView listId source
     Item.ConfirmDismissNewSource listId source -> confirmDismissNewSourceView listId source
     Item.EditingSource listId originalSource sourceWithEdits -> editingSourceView listId source content.slipbox
     Item.ConfirmDeleteSource -> confirmDeleteSourceView listId source content.timezone content.slipbox

itemNoteView: Int -> Note.Note -> Slipbox -> Element Msg
itemNoteView listId note slipbox =
  Element.column
    []
    [ Element.row 
      []
      [ idHeader Note.getId note
      , editButton listId
      , deleteButton listId
      , dismissButton listId
      ]
    , variantView <| Note.getVariant note
    , contentView <| Note.getContent note
    , sourceView <| Note.getSource note
    , Element.row
      []
      [ linkedNotesHeader 
      , addLinkButton listId note slipbox
      ]
    , Element.column
      []
      <| List.map (toLinkedNoteView (Note.getId note)) <| Slipbox.getLinkedNotes note slipbox
    ]

addLinkButton: Int -> Note.Note -> Slipbox.Slipbox -> Element Msg
addLinkButton listId note slipbox =
  if Slipbox.noteCanLinkToOtherNotes note slipbox then
    addLinkButton_ listId
  else 
    cannotAddLink 

cannotAddLink: Element Msg
cannotAddLink = Element.text "No notes to make a valid link to."

toLinkedNoteView: Int -> Note.Note -> Element Msg
toLinkedNoteView noteId note =
  Element.column
    []
    [ idHeader <| Note.getId note
    , variantView <| Note.getVariant note
    , contentView <| Note.getContent note
    , sourceView <| Note.getSouce note
    , removeLinkButton noteId <| Note.getId note
    ]

newNoteView: Int -> Item.NewNoteContent -> Slipbox.Slipbox -> Element Msg
newNoteView listId note slipbox=
  Element.column
    []
    [ dismissButton listId
    , contentEdit listId note.content
    , sourceChoiceEdit listId note.source <| Slipbox.getSources Nothing slipbox
    , chooseVariant listId note.variant
    , chooseSaveButton listId note.canSave
    ]

confirmDismissNewNoteView: Int -> Item.NewNoteContent -> Element Msg
confirmDismissNewNoteView listId note =
  Element.column
    []
    [ Element.row 
      []
      [ confirmDismissNewNoteButton listId
      , cancelDismissNewNoteButton listId
      ] 
    , contentView note.content
    , sourceView note.source
    , chooseVariant note.variant
    , saveButtonNotClickable
    ]

toLinkedNoteViewNoButtons: Int -> Note.Note -> Element Msg
toLinkedNoteViewNoButtons noteId note =
  Element.column
    []
    [ idHeader <| Note.getId note
    , variantView <| Note.getVariant note
    , contentView <| Note.getContent note
    , sourceView <| Note.getSource note
    ]

editingNoteView: Int -> Note.Note -> Note.Note -> Slipbox.Slipbox -> Element Msg
editingNoteView listId _ noteWithEdits slipbox =
  Element.column
    []
    [ Element.row 
      []
      [ idHeader <| Note.getId noteWithEdits
      , saveButton listId
      , cancelButton listId
      ]
    , contentEdit listId <| Note.getContent noteWithEdits
    , sourceChoiceEdit listId <| Note.getSource noteWithEdits <| Slipbox.getSources Nothing slipbox
    , chooseVariant listId <| Note.getVariant noteWithEdits
    , Element.row
      []
      [ linkedNotesHeader ]
    , Element.column
      []
      <| List.map (toLinkedNoteViewNoButtons (Note.getId noteWithEdits)) <| Slipbox.getLinkedNotes noteWithEdits slipbox
    ]

confirmDeleteNoteView: Int -> Note.Note -> Slipbox.Slipbox -> Element Msg
confirmDeleteNoteView listId note slipbox =
  Element.column
    []
    [ Element.row 
      []
      [ idHeader <| Note.getId note
      , confirmDeleteButton listId
      , cancelButton listId
      ]
    , contentView <|Note.getContent note
    , sourceView <|Note.getSource note
    , variantView <|Note.getVariant note
    , Element.row
      []
      [ linkedNotesHeader ]
    , Element.column
      []
      <| List.map (toLinkedNoteViewNoButtons (Note.getId)) <| Slipbox.getLinkedNotes note slipbox
    ]

addingLinkToNoteView: Int -> String -> Note.Note -> Slipbox.Slipbox -> Element Msg
addingLinkToNoteView listId search note slipbox =
  Element.column
    []
    [ Element.row
      []
      [ Element.text "Adding Link"
      , cancelButton listId
      ]
    , Element.row
      []
      [ noteRepresentation note
      , Element.text "Select note to add link to from below"
      ]
    , Element.column
      []
      [ searchBar search listId
      , Element.el [Element.scrollbarsY] <| List.map (toNoteDetail listId) <| Slipbox.getNotesThatCanLinkToNote note slipbox
      ]
    ]

toNoteDetail: Int -> Note.Note -> Element Msg
toNoteDetail listId note =
  Element.el 
    [ Element.paddingXY 8 0, Element.spacing 8
    , Element.Border.solid, Element.Border.color gray
    , Element.Border.width 4 
    ] 
    Element.Input.button [] 
      {onPress = Nothing, label = Element.column [] 
        [ Element.paragraph [] [ Element.text <| Note.getContent note]
        , Element.text <| "Source: " ++ (Note.getSource note)
        ]
      }

linkChosenView: Int -> String -> Note.Note -> Note.Note -> Slipbox.Slipbox -> Element Msg
linkChosenView listId search note noteToLink slipbox =
  Element.column
    []
    [ Element.row
      []
      [ Element.text "Adding Link"
      , cancelButton listId
      , createLinkButton listId
      ]
    , Element.row
      []
      [ noteRepresentation note
      , noteRepresentation noteToLink
      ]
    , Element.column
      []
      [ searchBar search listId
      , Element.column 
        [Element.scrollbarsY] 
        <| List.map (toNoteDetail listId) 
          <| Slipbox.getNotesThatCanLinkToNote note slipbox
      ]
    ]

itemSourceView: Int -> Source.Source -> Time.Zone -> Slipbox -> Element Msg
itemSourceView listId source timezone slipbox =
  ElmUI.column 
    []
    [ dismissButton listId
    , titleView <| Source.getTitle source
    , authorView <| Source.getAuthor source
    , createdTimeView timezone <| Source.getCreated source
    , updatedTime timezone <| Source.getUpdated source
    , editButton listId
    , deleteButton listId
    , contentView <| Source.getContent source 
    , Element.column
      [Element.scrollbarsY] 
      <| List.map (toLinkedNoteViewNoButtons listId) 
        <| Slipbox.getNotesAssociatedToSource source slipbox
    ]

-- Invariant: An edit to a source should not break a link between a source and a note
newSourceView: Int -> Item.NewSourceContent -> Element Msg
newSourceView listId source =
  ElmUI.column 
    []
    [ dismissButton listId
    , editTitleView listId source.title
    , editAuthorView listId source.author
    , editContentView listId source.content 
    , chooseSaveButton listId source.isValidToSave
    ]

confirmDismissNewSourceView : Int -> Item.NewSourceContent -> Element Msg
confirmDismissNewSourceView listId source =
  ElmUI.column 
    []
    [ Element.row 
      []
      [ confirmDismissNewNoteButton listId
      , cancelDismissNewNoteButton listId
      ] 
    , titleView source.title
    , authorView source.author
    , contentView source.content 
    , saveButtonNotClickable
    ]

editingSourceView: Int -> Source.Source -> Slipbox -> Element Msg
editingSourceView listId source slipbox =
  ElmUI.column 
    []
    [ Element.row 
      []
      [ saveButton listId
      , cancelButton listId
      ]
    , editTitleView listId <| Source.getTitle source
    , editAuthorView listId <| Source.getAuthor source
    , editContentView listId <| Source.getContent source 
    , Element.column
      [Element.scrollbarsY] 
      <| List.map (toLinkedNoteViewNoButtons listId) 
        <| Slipbox.getNotesAssociatedToSource source slipbox
    ]

confirmDeleteSourceView: Int -> Source.Source -> Time.Zone -> Slipbox -> Element Msg
confirmDeleteSourceView listId source timezone slipbox =
  ElmUI.column 
    []
    [ Element.row 
      []
      [ confirmDeleteButton listId
      , cancelButton listId
      ]
    , titleView <| Source.getTitle source
    , authorView <| Source.getAuthor source
    , createdTimeView timezone <| Source.getCreated source
    , updatedTime timezone <| Source.getUpdated source
    , contentView <| Source.getContent source 
    , Element.column
      [Element.scrollbarsY] 
      <| List.map (toLinkedNoteViewNoButtons listId) 
        <| Slipbox.getNotesAssociatedToSource source slipbox
    ]

-- EXPLORE TAB
exploreTabView: String -> Viewport.Viewport -> Slipbox.Slipbox -> Element Msg
exploreTabView input viewport slipbox = Element.column 
  [ Element.width Element.fill, Element.height Element.fill]
  [ toolbar input (\s -> ExploreTabUpdateInput s) Note
  , graph <| Slipbox.getNotesAndLinks input slipbox
  ]

-- TODO: Viewport actions
graph: Viewport -> ((List Note.Note, List Link.Link)) -> Element Msg
graph viewport (notes, links) =
  Element.el [Element.height Element.fill, Element.width Element.fill] 
    <| Element.html 
      <| Svg.svg 
        [ Svg.Attributes.width <| Viewport.getWidth viewport
        , Svg.Attributes.height <| Viewport.getHeight viewport
        , Svg.Attributes.viewBox <| Viewport.getViewbox viewport
        ]
        <| List.map toGraphNote notes :: List.map toGraphLink links

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

toGraphLink: Link.Link -> Svg Msg
toGraphLink link =
  Svg.line 
    [ Svg.Attributes.x1 <| Link.getSourceX link
    , Svg.Attributes.y1 <| Link.getSourceY link
    , Svg.Attribtes.x2 <| Link.getTargetX link
    , Svg.Attributes.y2 <| Link.getTargetY link
    , Svg.Attributes.stroke "rgb(0,0,0)"
    , Svg.Attributes.strokeWidth "2"
    ] 
    []

-- NOTE TAB
noteTabView: String -> Slipbox -> Html Msg
noteTabView search slipbox = 
  Element.layout [Element.width Element.fill]
    <| Element.column [Element.width Element.fill, Element.height Element.fill]
      [ toolbar search  (\s -> NoteTabUpdateInput s) Note
      , notesView <| Slipbox.getNotes (toMaybeSearch search) slipbox
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

-- VIEW UTILITIES
gray = Element.rgb255 238 238 238
thistle = Element.rgb255 216 191 216
indianred = Element.rgb255 205 92 92
noteColor: Note.Variant -> String
noteColor variant =
  case variant of
    Note.Index -> "rgba(250, 190, 88, 1)"
    Note.Regular -> "rgba(137, 196, 244, 1)"

-- TOOLBAR
toolbar: String -> (a -> Msg a) -> Create -> Element Msg
toolbar input onChange create = 
  Element.el 
    [Element.width Element.fill, Element.height <| Element.px 50]
    <| Element.row [Element.width Element.fill, Element.paddingXY 8 0, Element.spacing 8] 
      [ searchInput input onChange
      , createButton create
      ]

searchInput: String -> (a -> Msg a) -> Element Msg
searchInput input onChange = Element.Input.text
  [Element.width Element.fill] 
  { onChange = onChange
  , text = input
  , placeholder = Nothing
  , label = Element.Input.labelLeft [] <| Element.text "search"
  }

type Create = Note | Source

getCreateLabel: Create -> Element Msg
getCreateLabel create =
  case create of
    Note -> Element.text "Create Note"
    Source -> Element.text "Create Source"

getCreateOnPress: Create -> Maybe Msg
getCreateOnPress create =
  case create of 
    Note -> Just CreateNote
    Source -> Just CreateSource

createButton: Create -> Element Msg
createButton create = 
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = getCreateOnPress create
    , label = getCreateLabel create
    }