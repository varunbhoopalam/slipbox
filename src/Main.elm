module Main exposing (..)

import Browser
import Browser.Navigation
import Html
import Element

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
  Explore String Viewport
  Notes String |
  Sources String Sort |
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
  | SourceTabUpdateInput String
  | OpenSource Source.Source
  | ToggleSortAuthor
  | ToggleSortTitle
  | ToggleSortCreated
  | ToggleSortUpdated
  | EditItem Int
  | DeleteItem Int
  | DismissItem Int
  | AddLink Int
  | RemoveLink Note.Note Note.Note
  | NoteChosenToLink Int Note.Note
  | UpdateNoteContent Int String
  | UpdateNoteSource Int String
  | UpdateNoteVariant Int Variant
  | SubmitItem Int
  | ConfirmDismissItem Int
  | DoNotDismissItem Int
  | CancelItemAction Int
  | ConfirmDeleteItem Int
  | UpdateSourceTitle Int String
  | UpdateSourceAuthor Int String

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
    
    SourceTabUpdateInput input -> 
      case model.tab of 
        Sources _ sort -> ({ model | tab = Sources input sort }, Cmd.none)
        _ -> (model, Cmd.none)

    CreateNote -> ({ model | slipbox = Slipbox.createNote model.slipbox }, Cmd.none)

    CompressNote note -> ({ model | slipbox = Slipbox.compressNote note model.slipbox }, Cmd.none)

    OpenNote note -> ({ model | slipbox = Slipbox.openNote note model.slipbox }, Cmd.none)

    ExpandNote note -> ({ model | slipbox = Slipbox.expandNote note model.slipbox }, Cmd.none)

    CreateSource -> ({ model | slipbox = Slipbox.createSource model.slipbox }, Cmd.none)

    OpenSource source -> ({ model | slipbox = Slipbox.openSource source model.slipbox }, Cmd.none)

    ToggleSortAuthor ->      
      case model.tab of 
        Sources input sort -> 
          case sort of
             Sort.Author direction -> ({ model | tab = Sources input <| Sort.toggle direction }, Cmd.none)
             _ -> ({ model | tab = Sources input Sort.author }, Cmd.none)
        _ -> (model, Cmd.none)

    ToggleSortTitle ->      
      case model.tab of 
        Sources input sort -> 
          case sort of
             Sort.Title direction -> ({ model | tab = Sources input <| Sort.toggle direction }, Cmd.none)
             _ -> ({ model | tab = Sources input Sort.title }, Cmd.none)
        _ -> (model, Cmd.none)

    ToggleSortCreated ->      
      case model.tab of 
        Sources input sort -> 
          case sort of
             Sort.Created direction -> ({ model | tab = Sources input <| Sort.toggle direction }, Cmd.none)
             _ -> ({ model | tab = Sources input Sort.created }, Cmd.none)
        _ -> (model, Cmd.none)

    ToggleSortUpdated ->
      case model.tab of 
        Sources input sort -> 
          case sort of
             Sort.Updated direction -> ({ model | tab = Sources input <| Sort.toggle direction }, Cmd.none)
             _ -> ({ model | tab = Sources input Sort.updated }, Cmd.none)
        _ -> (model, Cmd.none)
    
    EditItem itemId -> ({ model | slipbox = Slipbox.editItem itemId model.slipbox }, Cmd.none)

    DeleteItem itemId -> ({ model | slipbox = Slipbox.deleteItem itemId model.slipbox }, Cmd.none)

    DismissItem itemId -> ({ model | slipbox = Slipbox.dismissItem itemId model.slipbox }, Cmd.none)

    AddLink itemId -> ({ model | slipbox = Slipbox.addLink itemId model.slipbox }, Cmd.none)

    RemoveLink openNote linkedNote -> ({ model | slipbox = Slipbox.removeLink openNote linkedNote model.slipbox }, Cmd.none)

    NoteChosenToLink itemId noteChosen -> ({ model | slipbox = Slipbox.noteChosenToLink itemId noteChosen model.slipbox }, Cmd.none)

    UpdateNoteContent itemId input -> ({ model | slipbox = Slipbox.updateNoteContent itemId input model.slipbox }, Cmd.none)

    UpdateNoteSource itemId input -> ({ model | slipbox = Slipbox.updateNoteSource itemId input model.slipbox }, Cmd.none)

    UpdateNoteVariant itemId variant -> ({ model | slipbox = Slipbox.updateNoteVariant itemId variant model.slipbox }, Cmd.none)

    SubmitItem itemId -> ({ model | slipbox = Slipbox.submitItem itemId model.slipbox }, Cmd.none)

    ConfirmDismissItem itemId -> ({ model | slipbox = Slipbox.confirmDismissItem itemId model.slipbox }, Cmd.none)
  | 
    DoNotDismissItem itemId -> ({ model | slipbox = Slipbox.doNotDismissItem itemId model.slipbox }, Cmd.none)

    CancelItemAction itemId -> ({ model | slipbox = Slipbox.cancelItemAction itemId model.slipbox }, Cmd.none)

    ConfirmDeleteItem itemId -> ({ model | slipbox = Slipbox.confirmDeleteItem itemId model.slipbox }, Cmd.none)

    UpdateSourceTitle itemId input -> ({ model | slipbox = Slipbox.updateSourceTitle itemId input model.slipbox }, Cmd.none)
    
    UpdateSourceAuthor itemId input -> ({ model | slipbox = Slipbox.updateSourceAuthor itemId input model.slipbox }, Cmd.none)


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
    Explore input viewport -> exploreTabView input viewport content.slipbox
    Notes input -> noteTabView input content.slipbox
    Sources input sort -> sourceTabView input sort content.timezone content.slipbox
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
      items
-- TODO: add div between each item that on hover shows buttons to create an item
-- TODO: figure out if it's necessary to have this same div but always visible either at
  -- beginning or end of item list

toItemView: Content -> Item.Item -> Element Msg
toItemView content item =
  case item of
     Item.Note itemId note -> itemNoteView itemId note content.slipbox
     Item.NewNote itemId note -> newNoteView itemId note content.slipbox
     Item.ConfirmDiscardNewNoteForm itemId note -> confirmDiscardNewNoteFormView itemId note content.slipbox
     Item.EditingNote itemId originalNote noteWithEdits -> editingNoteView itemId originalNote noteWithEdits content.slipbox
     Item.ConfirmDeleteNote itemId note -> confirmDeleteNoteView itemId note content.slipbox
     Item.AddingLinkToNoteForm itemId search note maybeNote -> addingLinkToNoteView itemId search note maybeNote content.slipbox
     Item.Source itemId source -> itemSourceView itemId source content.timezone content.slipbox
     Item.NewSource itemId source -> newSourceView itemId source
     Item.ConfirmDiscardNewSourceForm itemId source -> confirmDiscardNewSourceFormView itemId source
     Item.EditingSource itemId originalSource sourceWithEdits -> editingSourceView itemId source content.slipbox
     Item.ConfirmDeleteSource -> confirmDeleteSourceView itemId source content.timezone content.slipbox
     Item.ConfirmDeleteLink itemId note linkedNote link ->

itemNoteView: Int -> Note.Note -> Slipbox -> Element Msg
itemNoteView itemId note slipbox =
  Element.column
    []
    [ Element.row 
      []
      [ idHeader Note.getId note
      , editButton itemId
      , deleteButton itemId
      , dismissButton itemId
      ]
    , contentView <| Note.getContent note
    , sourceView <| Note.getSource note
    , variantView <| Note.getVariant note
    , Element.row
      []
      [ linkedNotesHeader 
      , handleAddLinkButton itemId note slipbox
      ]
    , Element.column
      []
      <| List.map (toLinkedNoteView note <| Slipbox.getLinkedNotes note slipbox
    ]

handleAddLinkButton: Int -> Note.Note -> Slipbox.Slipbox -> Element Msg
handleAddLinkButton itemId note slipbox =
  if Slipbox.noteCanLinkToOtherNotes note slipbox then
    addLinkButton itemId
  else 
    cannotAddLink 

addLinkButton: Int -> Element Msg
addLinkButton itemId =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| AddLink itemId
    , label = Element.text "Add Link"
    }

cannotAddLink: Element Msg
cannotAddLink = Element.text "No notes to make a valid link to."

toLinkedNoteView: Note.Note -> Note.Note -> Element Msg
toLinkedNoteView openNote linkedNote =
  Element.column
    []
    [ idHeader <| Note.getId linkedNote
    , contentView <| Note.getContent linkedNote
    , sourceView <| Note.getSouce linkedNote
    , variantView <| Note.getVariant linkedNote
    , removeLinkButton openNote linkedNote
    ]

removeLinkButton: Note.Note -> Note.Note -> Element Msg
removeLinkButton openNote linkedNote  =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| RemoveLink openNote linkedNote
    , label = Element.text "Remove Link"
    }

newNoteView: Int -> Item.NewNoteContent -> Slipbox.Slipbox -> Element Msg
newNoteView itemId note slipbox =
  Element.column
    []
    [ contentInput itemId note.content
    , sourceInput itemId note.source <| Slipbox.getSources Nothing slipbox
    , chooseVariantButtons itemId note.variant
    , cancelButton itemId
    , chooseSubmitButton itemId note.canSubmit
    ]

confirmDiscardNewNoteFormView: Int -> Item.NewNoteContent -> Element Msg
confirmDiscardNewNoteFormView itemId note =
  Element.column
    []
    [ Element.row 
      []
      [ confirmDismissButton itemId
      , doNotDismissButton itemId
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
editingNoteView itemId _ noteWithEdits slipbox =
  Element.column
    []
    [ Element.row 
      []
      [ idHeader <| Note.getId noteWithEdits
      , submitButton itemId
      , cancelButton itemId
      ]
    , contentInput itemId <| Note.getContent noteWithEdits
    , sourceInput itemId (Note.getSource noteWithEdits) <| Slipbox.getSources Nothing slipbox
    , chooseVariantButtons itemId <| Note.getVariant noteWithEdits
    , Element.row
      []
      [ linkedNotesHeader ]
    , Element.column
      []
      <| List.map (toLinkedNoteViewNoButtons (Note.getId noteWithEdits)) <| Slipbox.getLinkedNotes noteWithEdits slipbox
    ]

confirmDeleteNoteView: Int -> Note.Note -> Slipbox.Slipbox -> Element Msg
confirmDeleteNoteView itemId note slipbox =
  Element.column
    []
    [ Element.row 
      []
      [ idHeader <| Note.getId note
      , confirmDeleteButton itemId
      , cancelButton itemId
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

addingLinkToNoteView: Int -> String -> Note.Note -> (Maybe Note.Note) -> Slipbox.Slipbox -> Element Msg
addingLinkToNoteView itemId search note maybeNote slipbox =
  let
      choice = 
        case maybeNote of 
          Just chosenNoteToLink ->
            [submitButton itemId, noteRepresentation chosenNoteToLink ]
          Nothing -> 
            [ Element.text "Select note to add link to from below" ]

  in
  Element.column
    []
    [ Element.row
      []
      [ Element.text "Adding Link"
      , cancelButton itemId
      ]
    , Element.row
      []
      [ noteRepresentation note ] :: choice
    , Element.column
      []
      [ searchBar search itemId
      , Element.el [Element.scrollbarsY] <| List.map (toNoteDetail itemId) <| Slipbox.getNotesThatCanLinkToNote note slipbox
      ]
    ]

toNoteDetail: Int -> Note.Note -> Element Msg
toNoteDetail itemId note =
  Element.el 
    [ Element.paddingXY 8 0, Element.spacing 8
    , Element.Border.solid, Element.Border.color gray
    , Element.Border.width 4 
    ] 
    Element.Input.button [] 
      { onPress = Just <| NoteChosenToLink itemId note
      , label = Element.column [] 
        [ Element.paragraph [] [ Element.text <| Note.getContent note]
        , Element.text <| "Source: " ++ (Note.getSource note)
        ]
      }

itemSourceView: Int -> Source.Source -> Time.Zone -> Slipbox -> Element Msg
itemSourceView itemId source timezone slipbox =
  ElmUI.column 
    []
    [ dismissButton itemId
    , titleView <| Source.getTitle source
    , authorView <| Source.getAuthor source
    , createdTimeView timezone <| Source.getCreated source
    , updatedTime timezone <| Source.getUpdated source
    , editButton itemId
    , deleteButton itemId
    , contentView <| Source.getContent source 
    , Element.column
      [Element.scrollbarsY] 
      <| List.map (toLinkedNoteViewNoButtons itemId) 
        <| Slipbox.getNotesAssociatedToSource source slipbox
    ]

-- Invariant: An edit to a source should not break a link between a source and a note
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

confirmDeleteSourceView: Int -> Source.Source -> Time.Zone -> Slipbox -> Element Msg
confirmDeleteSourceView itemId source timezone slipbox =
  ElmUI.column 
    []
    [ Element.row 
      []
      [ confirmDeleteButton itemId
      , cancelButton itemId
      ]
    , titleView <| Source.getTitle source
    , authorView <| Source.getAuthor source
    , createdTimeView timezone <| Source.getCreated source
    , updatedTime timezone <| Source.getUpdated source
    , contentView <| Source.getContent source 
    , Element.column
      [Element.scrollbarsY] 
      <| List.map (toLinkedNoteViewNoButtons itemId) 
        <| Slipbox.getNotesAssociatedToSource source slipbox
    ]

-- EXPLORE TAB
exploreTabView: String -> Viewport.Viewport -> Slipbox.Slipbox -> Element Msg
exploreTabView input viewport slipbox = Element.column 
  [ Element.width Element.fill, Element.height Element.fill]
  [ exploreTabToolbar input
  , graph <| Slipbox.getNotesAndLinks input slipbox
  ]

exploreTabToolbar: String -> Element Msg
exploreTabToolbar input = 
  Element.el 
    [Element.width Element.fill, Element.height <| Element.px 50]
    <| Element.row [Element.width Element.fill, Element.paddingXY 8 0, Element.spacing 8] 
      [ searchInput input (\s -> ExploreTabUpdateInput s)
      , createNoteButton
      ]

graph: Viewport -> ((List Note.Note, List Link.Link)) -> Element Msg
graph viewport (notes, links) =
  Element.el [Element.height Element.fill, Element.width Element.fill] 
    <| Element.html 
      <| Svg.svg 
        [ Svg.Attributes.width <| Viewport.getWidth viewport
        , Svg.Attributes.height <| Viewport.getHeight viewport
        , Svg.Attributes.viewBox <| Viewport.getViewbox viewport
        ]
        <| List.map toGraphNote notes 
          :: List.map toGraphLink links
          :: panningFrame viewport

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

panningFrame: Viewport.Viewport -> Svg Msg
panningFrame viewport =
  Svg.g
    [] 
    [ Svg.rect
      [ Svg.Attributes.width <| Viewport.getOuterPanningFrameWidth viewport
      , Svg.Attributes.height <| Viewport.getOuterPanningFrameHeight viewport
      , style "border: 2px solid black;"
      ] 
      []
    , Svg.rect 
      [ Svg.Attributes.width <| Viewport.getInnerPanningFrameWidth viewport
      , Svg.Attributes.height <| Viewport.getInnerPanningFrameHeight viewport
      , Svg.Attributes.style <| Viewport.getInnerPanningFrameStyle viewport
      , Svg.Attributes.transform <| Viewport.getInnerPanningFrameTransform viewport
      , Svg.Events.on "mousemove" mouseMoveDecoder
      , Svg.Events.on "mousedown" mouseDownDecoder
      , Svg.Events.onMouseUp PanningStop
      , Svg.Events.on "wheel" wheelDecoder
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
sourceTabView: String -> Sort -> Time.Zone -> Slipbox.Slipbox -> Element Msg
sourceTabView input sort timezone slipbox = 
  Element.column 
    [ Element.width Element.fill
    , Element.height Element.fill
    ]
    [ sourceTabToolbar model.search
    , sourceTable model.sort model.timezone 
      <| List.sortWith (chooseSorter sort) 
        <| Slipbox.getSources input slipbox
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

type alias SourceRow =
  { source: Source.Source
  , title: String
  , author: String
  , created: Int
  , updated: Int
  }

toSourceRow: Source.Source -> SourceRow
toSourceRow source =
  SourceRow 
    source
    (Source.getTitle source)
    (Source.getAuthor source)
    (Source.getCreated source)
    (Source.getUpdated source)

sourcesTable: Sort -> Time.Zone -> (List Source.Source) -> Element Msg
sourcesTable sort timezone sources =
  Element.table []
    { data = List.map toSourceRow sources
    , columns = 
      [ { header = Element.Input.button [] 
          { onPress = Just ToggleSortAuthor 
          , label = getTitleLabel sort 
          }
        , width = Element.fill
        , view = \row -> Element.Input.button [] 
          { onPress = Just <| OpenSource row.source
          , label = Element.text row.author 
          }
        }
      , { header = Element.Input.button [] 
          { onPress = Just ToggleSortTitle
          , label = getAuthorLabel sort 
          }
        , width = Element.fill
        , view = \row -> Element.Input.button [] 
          { onPress = Just <| OpenSource row.source
          , label = Element.text row.title 
          }
        }
      , { header = Element.Input.button [] 
          { onPress = Just ToggleSortCreated
          , label = getCreatedLabel sort 
          }
        , width = Element.fill
        , view = \row -> Element.Input.button [] 
          { onPress = Just <| OpenSource row.source
          , label = Element.text <| timestamp timezone row.created
          }
        }
      , { header = Element.Input.button [] 
          { onPress = Just ToggleSortUpdated
          , label = getUpdatedLabel sort 
          }
        , width = Element.fill
        , view = \row -> Element.Input.button [] 
          { onPress = Just <| OpenSource row.source
          , label = Element.text <| timestamp timezone row.updated 
          }
        }
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

searchInput: String -> (a -> Msg a) -> Element Msg
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
    { onPress = Just CreateNote
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

editButton: Int -> Element Msg
editButton itemId =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| EditItem itemId
    , label = Element.text "Edit"
    }

deleteButton: Int -> Element Msg
deleteButton itemId =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| DeleteItem itemId
    , label = Element.text "Delete"
    }

dismissButton: Int -> Element Msg
dismissButton itemId =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| DismissItem itemId
    , label = Element.text "X"
    }

contentInput: Int -> String -> Element Msg
contentInput itemId input =
  Element.Input.multiline
    []
    { onChange : (\s -> UpdateNoteContent itemId s)
    , text : input
    , placeholder : Nothing
    , label : Element.labelAbove [] <| Element.text "Content"
    , spellcheck : True
    }

sourceInput: Int -> String -> (List String) -> Element Msg
sourceInput itemId input suggestions =
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
          , Html.Events.onInput (\s -> UpdateNoteSource itemId s)
          ]
          []
        , Html.datalist 
          [ Html.Attributes.id dataitemId ]
          <| List.map toHtmlOption suggestions
        ]

toHtmlOption: String -> Html Msg
toHtmlOption value =
  Html.option [ Html.Attributes.value value ] []

chooseVariantButtons: Int -> Note.Variant -> Element Msg
chooseVariantButtons itemId variant =
  Element.Input.radioRow
    [ Element.Border.rounded 6
    , Element.Border.shadow { offset = ( 0, 0 ), size = 3, blur = 10, color = rgb255 0xE0 0xE0 0xE0 } 
    ]
    { onChange = (\v -> UpdateNoteVariant itemId v)
    , selected = Just variant
    , label = Input.labelLeft [] <| text "Choose Note Variant"
    , options =
      [ Input.option Note.Index <| variantButton Note.Index
      , Input.option Note.Regular <| variantButton Note.Regular
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

chooseSubmitButton : Int -> Bool -> Element Msg
chooseSubmitButton itemId canSubmit =
  if canSubmit then
    submitButon itemId
  else
    Element.text "Cannot Submit Yet!"

submitButton : Int -> Element Msg
submitButton itemId =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| SubmitItem itemId
    , label = Element.text "Submit"
    }

confirmDismissButton : Int -> Element Msg
confirmDismissButton itemId =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| ConfirmDismissItem itemId
    , label = Element.text "Confirm Dismiss"
    }

doNotDismissButton : Int -> Element Msg
doNotDismissButton itemId =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| DoNotDismissItem itemId
    , label = Element.text "Do Not Dismiss"
    }

cancelButton : Int -> Element Msg
cancelButton itemId =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| CancelItemAction itemId
    , label = Element.text "Cancel"
    }

confirmDeleteButton : Int -> Element Msg
confirmDeleteButton itemId =
  Element.Input.button
    [ Element.Background.color indianred
    , Element.mouseOver
        [ Element.Background.color thistle ]
    , Element.width Element.fill
    ]
    { onPress = Just <| ConfirmDeleteItem itemId
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