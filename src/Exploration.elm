module Exploration exposing (..)

import Browser
import Html exposing (Html, div, text, button, option)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onClick, onMouseLeave, onMouseEnter)
import Svg exposing (Svg, svg, circle, line, rect, animate)
import Svg.Attributes exposing (width, height, viewBox, cx, cy, r, x1, y1, x2, y2, style, transform, attributeName, dur, values, repeatCount)
import Svg.Events exposing (on, onMouseUp, onMouseOut)
import Json.Decode exposing (Decoder, int, map, field, map2, list, string, map4, map3, map6, map5)
import Http

-- Modules
import Viewport as V
import Slipbox as S
import LinkForm
import Note
import Action
import Element exposing (Element, el)
import Element.Input as Input
import Element.Events as Events
import Element.Background as Background
import Input as I

-- MAIN

main =
  Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }

-- MODEL
type Model = Model S.Slipbox I.Input V.Viewport CreateNoteForm

init : () -> (Model, Cmd Msg)
init _ =
  ( Model (S.initialize initNoteData initLinkData initHistoryData) I.init V.initialize initCreateNoteForm
  , Http.get
      { url = "http://localhost:5000/"
      , expect = Http.expectJson GetSlipbox slipboxDecoder
      }
  )

initNoteData : List Note.NoteRecord
initNoteData = []
initLinkData: List S.LinkRecord
initLinkData = []
initHistoryData: S.ActionResponse
initHistoryData = S.ActionResponse [] [] [] [] []

getSearchText: Model -> String
getSearchText model =
  case model of
    Model _ search _ _ -> I.get search

getNotes: Model -> (List Note.Extract)
getNotes model =
  case model of
    Model slipbox search _ _ -> S.searchSlipbox (I.get search) slipbox

getSelectedNotes: Model -> (List S.DescriptionNote)
getSelectedNotes model =
  case model of
    Model slipbox _ _ _ -> S.getSelectedNotes slipbox

getActions: Model -> (List Action.Summary)
getActions model =
  case model of
    Model slipbox _ _ _ -> S.getHistory slipbox

getViewport: Model -> String
getViewport model =
  case model of
    Model _ _ viewport _ -> V.getViewbox viewport

getNotesAndLinks: Model -> ((List S.GraphNote),(List S.GraphLink))
getNotesAndLinks model =
  case model of
    Model slipbox _ _ _ -> S.getGraphElements slipbox

getPanningAttributes: Model -> V.PanningAttributes
getPanningAttributes model =
  case model of
    Model _ _ viewport _ -> V.getPanningAttributes viewport

getNoteFormData: Model -> CreateForm
getNoteFormData model =
  case model of 
    Model _ _ _ form -> getCreateFormData form

getLinkFormData: Model -> LinkForm.LinkFormData
getLinkFormData model =
  case model of
    Model slipbox _ _ _ -> S.getLinkFormData slipbox

-- CreateNoteForm

type CreateNoteForm =
  ShowForm Content Source NoteType |
  HideForm Content Source NoteType

type NoteType = Index | Regular
type alias Content = String
type alias Source = String

type alias CreateForm =
  { shown: Bool
  , content: String
  , source: String
  , isIndex: Bool
  , canSubmit: Bool
  }

initCreateNoteForm: CreateNoteForm 
initCreateNoteForm =
  ShowForm "" "" Regular

updateContent: String -> CreateNoteForm -> CreateNoteForm
updateContent content form =
  case form of
    ShowForm _ source noteType -> ShowForm content source noteType
    HideForm _ _ _ -> form

updateSource: String -> CreateNoteForm -> CreateNoteForm
updateSource source form =
  case form of
    ShowForm content _ noteType -> ShowForm content source noteType
    HideForm _ _ _ -> form

updateNoteType: String -> CreateNoteForm -> CreateNoteForm
updateNoteType noteType form =
  case form of
    ShowForm content source _ -> ShowForm content source (toNoteType noteType)
    HideForm _ _ _ -> form

toNoteType: String -> NoteType
toNoteType noteType =
  if noteType == "index" then
    Index
  else
    Regular

toggleCreateNoteForm: CreateNoteForm -> CreateNoteForm
toggleCreateNoteForm form =
  case form of
     ShowForm content source noteType -> HideForm content source noteType
     HideForm content source noteType -> ShowForm content source noteType

getCreateFormData: CreateNoteForm -> CreateForm
getCreateFormData form =
  case form of
    ShowForm content source noteType -> CreateForm True content source (isIndex noteType) (canSubmit content source)
    HideForm content source noteType -> CreateForm False content source (isIndex noteType) False

canSubmit: Content -> Source -> Bool
canSubmit content source =
  content /= "" && source /= ""

isIndex: NoteType -> Bool
isIndex noteType = 
  case noteType of
    Index -> True
    Regular -> False

wipeForm: CreateNoteForm -> CreateNoteForm
wipeForm form =
  case form of
    ShowForm _ _ _ -> ShowForm "" "" Regular
    HideForm _ _ _ -> form

noteTypeToString: NoteType -> String
noteTypeToString noteType =
  case noteType of 
    Index -> "index"
    Regular -> "regular"

makeNoteRecord: CreateNoteForm -> S.MakeNoteRecord
makeNoteRecord form =
  case form of
    ShowForm content source noteType -> S.MakeNoteRecord content source (noteTypeToString noteType)
    HideForm content source noteType -> S.MakeNoteRecord content source (noteTypeToString noteType)

-- UPDATE
type Msg = 
  UpdateSearch String |
  PanningStart V.MouseEvent |
  IfPanningShift V.MouseEvent |
  PanningStop |
  ZoomIn |
  ZoomOut |
  NoteSelect Note.NoteId (Float, Float) |
  MapNoteSelect Note.NoteId |
  NoteDismiss Note.NoteId |
  NoteHighlight Note.NoteId |
  NoteRemoveHighlights |
  ToggleCreateNoteForm |
  ContentInputCreateNoteForm String |
  SourceInputCreateNoteForm String |
  ChangeNoteTypeCreateNoteForm String |
  SubmitCreateNoteForm |
  SubmitLink |
  LinkFormSourceSelected String |
  LinkFormTargetSelected String |
  EditNote Note.NoteId |
  DiscardEdits Note.NoteId |
  SubmitEdits Note.NoteId |
  ContentUpdate Note.NoteId String |
  SourceUpdate Note.NoteId String |
  DeleteNote Note.NoteId |
  DeleteLink Int |
  Undo Int |
  Redo Int |
  GetSlipbox (Result Http.Error SlipboxResponse)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of 
    UpdateSearch query -> (handleUpdateSearch query model, Cmd.none)
    PanningStart mouseEvent -> (handlePanningStart mouseEvent model, Cmd.none)
    IfPanningShift mouseEvent -> (handleIfPanningShift mouseEvent model, Cmd.none)
    PanningStop -> (handlePanningStop model, Cmd.none)
    ZoomIn -> (handleZoomIn model, Cmd.none)
    ZoomOut -> (handleZoomOut model, Cmd.none)
    NoteSelect note coords -> (handleNoteSelect note coords model, Cmd.none)
    MapNoteSelect note -> (handleMapNoteSelect note model, Cmd.none)
    NoteDismiss note -> (handleNoteDismiss note model, Cmd.none)
    NoteHighlight note -> (handleNoteHighlight note model, Cmd.none)
    NoteRemoveHighlights -> (handleNoteRemoveHighlights model, Cmd.none)
    ToggleCreateNoteForm -> (handleToggleCreateNoteForm model, Cmd.none)
    ContentInputCreateNoteForm s -> (handleContentInputCreateNoteForm s model, Cmd.none)
    SourceInputCreateNoteForm s -> (handleSourceInputCreateNoteForm s model, Cmd.none)
    ChangeNoteTypeCreateNoteForm s -> (handleChangeNoteTypeCreateNoteForm s model, Cmd.none)
    SubmitCreateNoteForm -> (handleSubmitCreateNoteForm model, Cmd.none)
    SubmitLink -> (handleSubmitLink model, Cmd.none)
    LinkFormSourceSelected s -> (handleLinkFormSourceSelected s model, Cmd.none)
    LinkFormTargetSelected s -> (handleLinkFormTargetSelected s model, Cmd.none)
    EditNote note -> (handleEditNote note model, Cmd.none)
    DiscardEdits note -> (handleDiscardEdits note model, Cmd.none)
    SubmitEdits note -> (handleSubmitEdits note model, Cmd.none)
    ContentUpdate note s -> (handleContentUpdate s note model, Cmd.none)
    SourceUpdate note s -> (handleSourceUpdate s note model, Cmd.none)
    DeleteNote note -> (handleDeleteNote note model, Cmd.none)
    DeleteLink link -> (handleDeleteLink link model, Cmd.none)
    Undo id -> (handleUndo id model, Cmd.none)
    Redo id -> (handleRedo id model, Cmd.none)
    GetSlipbox response -> (handleGetSlipbox response model, Cmd.none)

handleUpdateSearch: String -> Model -> Model
handleUpdateSearch query model =
  case model of 
    Model slipbox search viewport form ->
      Model slipbox (I.update query search) viewport form
  
handlePanningStart: V.MouseEvent -> Model -> Model
handlePanningStart mouseEvent model =
  case model of
    Model slipbox search viewport form->
      Model slipbox search (V.startPanning mouseEvent viewport) form

handleIfPanningShift: V.MouseEvent -> Model -> Model
handleIfPanningShift mouseEvent model =
  case model of 
    Model slipbox search viewport form ->
      Model slipbox search (V.shiftIfPanning mouseEvent viewport) form

handlePanningStop: Model -> Model
handlePanningStop model =
  case model of
    Model slipbox search viewport form ->
      Model slipbox search (V.stopPanning viewport) form

handleZoomIn: Model -> Model
handleZoomIn model =
  case model of 
    Model slipbox search viewport form->
      Model slipbox search (V.zoomIn viewport) form

handleZoomOut: Model -> Model
handleZoomOut model =
  case model of
    Model slipbox search viewport form->
      Model slipbox search (V.zoomOut viewport) form

handleNoteSelect: Note.NoteId -> (Float, Float) -> Model -> Model
handleNoteSelect noteId coords model =
  case model of
    Model slipbox search viewport form ->
      Model (S.selectNote noteId slipbox) search (V.centerOn coords viewport) form

handleMapNoteSelect: Note.NoteId -> Model -> Model
handleMapNoteSelect noteId model =
  case model of
    Model slipbox search viewport form ->
      Model (S.selectNote noteId slipbox) search viewport form


handleNoteDismiss: Note.NoteId -> Model -> Model
handleNoteDismiss noteId model =
  case model of
    Model slipbox query viewport form ->
      Model (S.dismissNote noteId slipbox) query viewport form

handleNoteHighlight: Note.NoteId -> Model -> Model
handleNoteHighlight noteId model =
  case model of
    Model slipbox query viewport form ->
      Model (S.hoverNote noteId slipbox) query viewport form

handleNoteRemoveHighlights: Model -> Model
handleNoteRemoveHighlights model =
  case model of
    Model slipbox query viewport form ->
      Model (S.stopHoverNote slipbox) query viewport form

handleToggleCreateNoteForm: Model -> Model
handleToggleCreateNoteForm model =
  case model of 
    Model slipbox query viewport form ->
      Model slipbox query viewport (toggleCreateNoteForm form)

handleContentInputCreateNoteForm: String -> Model -> Model
handleContentInputCreateNoteForm content model =
  case model of
    Model slipbox query viewport form ->
      Model slipbox query viewport (updateContent content form)

handleSourceInputCreateNoteForm: String -> Model -> Model
handleSourceInputCreateNoteForm source model =
  case model of
    Model slipbox query viewport form ->
      Model slipbox query viewport (updateSource source form)

handleChangeNoteTypeCreateNoteForm: String -> Model -> Model
handleChangeNoteTypeCreateNoteForm noteType model =
  case model of
    Model slipbox query viewport form ->
      Model slipbox query viewport (updateNoteType noteType form)

handleSubmitCreateNoteForm: Model -> Model
handleSubmitCreateNoteForm model =
  case model of 
    Model slipbox query viewport form ->
      Model (S.createNote (makeNoteRecord form) slipbox) query viewport (wipeForm form)

handleSubmitLink: Model -> Model
handleSubmitLink model =
  case model of 
    Model slipbox query viewport form ->
      Model (S.createLink slipbox) query viewport form

handleLinkFormSourceSelected: String -> Model -> Model
handleLinkFormSourceSelected source model =
  case model of 
    Model slipbox query viewport form ->
      Model (S.sourceSelected source slipbox) query viewport form

handleLinkFormTargetSelected: String -> Model -> Model
handleLinkFormTargetSelected target model =
  case model of 
    Model slipbox query viewport form ->
      Model (S.targetSelected target slipbox) query viewport form

handleEditNote: Note.NoteId -> Model -> Model
handleEditNote noteId model =
  case model of
    Model slipbox query viewport form ->
      Model (S.startEditState noteId slipbox) query viewport form

handleDiscardEdits: Note.NoteId -> Model -> Model
handleDiscardEdits noteId model =
  case model of
    Model slipbox query viewport form ->
      Model (S.discardEdits noteId slipbox) query viewport form

handleSubmitEdits: Note.NoteId -> Model -> Model
handleSubmitEdits noteId model =
  case model of
    Model slipbox query viewport form ->
      Model (S.submitEdits noteId slipbox) query viewport form

handleContentUpdate: String -> Note.NoteId -> Model -> Model
handleContentUpdate content noteId model =
  case model of
    Model slipbox query viewport form ->
      Model (S.contentUpdate content noteId slipbox) query viewport form

handleSourceUpdate: String -> Note.NoteId -> Model -> Model
handleSourceUpdate source noteId model =
  case model of
    Model slipbox query viewport form ->
      Model (S.sourceUpdate source noteId slipbox) query viewport form

handleDeleteNote: Note.NoteId -> Model -> Model
handleDeleteNote noteId model =
  case model of
    Model slipbox query viewport form ->
      Model (S.deleteNote noteId slipbox) query viewport form

handleDeleteLink: Int -> Model -> Model
handleDeleteLink linkId model =
  case model of
    Model slipbox query viewport form ->
      Model (S.deleteLink linkId slipbox) query viewport form

handleUndo: Int -> Model -> Model
handleUndo actionId model =
  case model of
    Model slipbox query viewport form ->
      Model (S.undo actionId slipbox) query viewport form

handleRedo: Int -> Model -> Model
handleRedo actionId model =
  case model of
    Model slipbox query viewport form ->
      Model (S.redo actionId slipbox) query viewport form

handleGetSlipbox: (Result Http.Error SlipboxResponse) -> Model -> Model
handleGetSlipbox result model =
  case result of
    Ok response ->
      case model of
        Model _ _ _ _ -> Model (S.initialize response.notes response.links response.actions) I.init V.initialize initCreateNoteForm
    Err _ -> model


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
-- VIEW

view : Model -> Html Msg
view model =
  Element.layout [] <|
    Element.row [Element.width Element.fill, Element.height Element.fill, Element.spacing 8] 
    [ leftColumn model
    , svgContainer model
    , rightColumn model
    ]

leftColumn: Model -> Element Msg
leftColumn model =
  Element.column [Element.alignLeft, Element.height Element.fill, Element.width (Element.fillPortion 1)]
    [ search_ model
    , history model
    ]

search_: Model -> Element Msg
search_ model = 
  Element.column 
    [ Element.height Element.fill
    , Element.width Element.fill
    , Element.padding 8
    , Element.spacing 8
    ] 
    (searchBox (getSearchText model) :: List.map toSearchNote (getNotes model))

searchBox: String -> Element Msg
searchBox query =
  Input.text []
    { onChange = \new -> UpdateSearch new
    , label = Input.labelAbove [] (Element.text "Search by (content|source)")
    , placeholder = Nothing        
    , text = query
    }

toSearchNote: Note.Extract -> Element Msg
toSearchNote extract =
  Element.paragraph 
    [Events.onClick (NoteSelect extract.id (extract.x, extract.y))
    , Element.pointer
    , Element.width Element.fill
    , Background.color (Element.rgb255 240 240 240)
    ] 
    [ Element.text extract.content
    ]

history: Model -> Element Msg
history model = 
  Element.column 
    [ Element.height Element.fill
    , Element.width Element.fill
    , Element.padding 8
    , Element.spacing 8
    ] 
    (Element.text "Action History" :: List.map toActionPane (getActions model))

toActionPane: Action.Summary -> Element Msg
toActionPane action =
  Element.row [Element.width Element.fill]
    [ Element.text action.summary
    , actionInput action
    ] 

actionInput: Action.Summary -> Element Msg
actionInput action =
  if action.saved then
    el [Element.alignRight] (Element.text "saved")
  else
    if action.undone then
      Input.button [Element.alignRight] { onPress = Just (Redo action.id), label = Element.text "redo" }
    else 
      Input.button [Element.alignRight] { onPress = Just (Undo action.id), label = Element.text "undo" }

svgContainer: Model -> Element Msg
svgContainer model =
  el [Element.centerX, Element.height Element.fill, Element.width (Element.fillPortion 2)] 
    (Element.html 
      (div [] 
        [ noteNetwork model
        , panningVisual model
        , button [ onClick ZoomOut ] [ text "-" ]
        , button [ onClick ZoomIn ] [ text "+" ]
        ]
      )
    )

noteNetwork: Model -> Svg Msg
noteNetwork model =
  svg
    [ width V.svgWidthString
    , height V.svgLengthString
    , viewBox (getViewport model)
    , style "border: 4px solid black;"
    ]
    ((graphElements (getNotesAndLinks model)))

graphElements: ((List S.GraphNote),(List S.GraphLink)) -> (List (Svg Msg))
graphElements (notes, links) =
  List.map toSvgCircle notes ++ List.map toSvgLine links

toSvgCircle: S.GraphNote -> Svg Msg
toSvgCircle note =
  circle 
    [ cx (String.fromFloat note.x)
    , cy (String.fromFloat note.y) 
    , r "5"
    , style ("Cursor:Pointer;" ++ "fill:" ++ noteColor note.variant ++ ";")
    , onClick (MapNoteSelect note.id) 
    ]
    (handleCircleAnimation note.shouldAnimate)

noteColor: String -> String
noteColor variant =
  if variant == "index" then
    "rgba(250, 190, 88, 1)"
  else
    "rgba(137, 196, 244, 1)"

handleCircleAnimation: Bool -> (List (Svg Msg))
handleCircleAnimation shouldAnimate =
  if shouldAnimate then
    [circleAnimation]
  else
    []

circleAnimation: Svg Msg
circleAnimation = animate [attributeName "r", values "5;9;5", dur "3s", repeatCount "indefinite"] []

toSvgLine: S.GraphLink -> Svg Msg
toSvgLine link =
  line 
    [x1 (String.fromFloat link.sourceX)
    , y1 (String.fromFloat link.sourceY)
    , x2 (String.fromFloat link.targetX)
    , y2 (String.fromFloat link.targetY)
    , style "stroke:rgb(0,0,0);stroke-width:2"
    ] 
    []

panningVisual: Model -> Svg Msg
panningVisual model =
  panningSvg (getPanningAttributes model)
      
panningSvg: V.PanningAttributes -> Svg Msg
panningSvg attr =
  svg 
    [ width attr.svgWidth
    , height attr.svgHeight
    , style "border: 4px solid black;"
    ] 
    [
      rect 
        [ width attr.rectWidth
        , height attr.rectHeight
        , style attr.rectStyle
        , transform attr.rectTransform
        , on "mousemove" mouseMoveDecoder
        , on "mousedown" mouseDownDecoder
        , onMouseUp PanningStop
        , onMouseOut PanningStop
        ] 
        []
    ]

rightColumn: Model -> Element Msg
rightColumn model =
  Element.column [Element.alignRight, Element.height Element.fill, Element.width (Element.fillPortion 1)]
    [ createNoteForm (getNoteFormData model)
    , createLink (getLinkFormData model)
    , selections (getSelectedNotes model)
    ]

createNoteForm: CreateForm -> Element Msg
createNoteForm form = 
  Element.column 
    [Element.height (Element.fillPortion 2), Element.padding 8, Element.spacing 8, Element.width (Element.fill |> Element.maximum 300)] 
    [ contentInput ContentInputCreateNoteForm form.content
    , sourceInput SourceInputCreateNoteForm form.source
    , Input.radioRow [] { onChange = ChangeNoteTypeCreateNoteForm
      , selected = Just (boolToVal form.isIndex)
      , label = Input.labelAbove [] (Element.text "Variant")
      , options =
        [ Input.option "index" (Element.text "Index")
        , Input.option "regular" (Element.text "Regular")]}
    , submitNote form.canSubmit
    ]

contentInput: (String -> Msg) -> String -> Element Msg
contentInput message text =
  Input.multiline [Element.width (Element.fill |> Element.maximum 300)] { onChange = (\inp -> (message inp))
    , text = text
    , placeholder = Just (Input.placeholder [] (Element.text "Write the note content here!"))
    , label = Input.labelLeft [] (Element.text "Content")
    , spellcheck = False}

sourceInput: (String -> Msg) -> String -> Element Msg
sourceInput message text =
  Input.text [Element.width (Element.fill |> Element.maximum 300)] { onChange = (\inp -> (message inp))
    , text = text
    , placeholder = Just (Input.placeholder [] (Element.text "Write the note source here!"))
    , label = Input.labelLeft [] (Element.text "Source")}

boolToVal: Bool -> String
boolToVal ind =
  if ind then
    "index"
  else
    "regular"

submitNote: Bool -> Element Msg
submitNote canSubmitNote = 
  if canSubmitNote then
    Input.button [] {onPress = Just SubmitCreateNoteForm, label = (Element.text "Create Note")}
  else
    Input.button [] {onPress = Nothing, label = (Element.text "Create Note")}

createLink: LinkForm.LinkFormData -> Element Msg
createLink form = 
  Element.column 
    [Element.height (Element.fillPortion 1)] 
    [ Input.radioRow [] { onChange = LinkFormSourceSelected
      , selected = form.sourceChosen
      , label = Input.labelAbove [] (Element.text "Source")
      , options = (List.map toOption form.sourceChoices) }
    , Input.radioRow [] { onChange = LinkFormTargetSelected
      , selected = form.targetChosen
      , label = Input.labelAbove [] (Element.text "Target")
      , options = (List.map toOption form.targetChoices) }
    , submitLink form.canSubmit
    ]

toOption: LinkForm.LinkNoteChoice -> (Input.Option String Msg)
toOption linkNoteChoice =
  Input.option linkNoteChoice.value (Element.text linkNoteChoice.display)

submitLink: Bool -> Element Msg
submitLink canSubmitLink = 
  if canSubmitLink then
    Input.button [] {onPress = Just SubmitLink, label = Element.text "Create Link"}
  else
    Input.button [] {onPress = Nothing, label = Element.text "Create Link"}

selections: (List S.DescriptionNote) -> Element Msg
selections notes = 
  Element.column [Element.height (Element.fillPortion 5)] 
    (List.map toSelection notes)

toSelection: S.DescriptionNote -> Element Msg
toSelection note =
  Element.column 
    [ Events.onMouseEnter (NoteHighlight note.id)
    , Events.onMouseLeave NoteRemoveHighlights
    , Element.spacing 8
    , Element.padding 8
    ] 
    (selectionContent note)

selectionContent: S.DescriptionNote -> (List (Element Msg))
selectionContent note =
  if note.inEdit then
    inEditContent note
  else 
    notInEditContent note

blue = Element.rgb255 238 238 238

inEditContent: S.DescriptionNote -> (List (Element Msg))
inEditContent note =
  [ Element.wrappedRow [Element.spacing 8, Element.padding 8] 
    [ Input.button [Background.color blue] {onPress = Just (SubmitEdits note.id), label = Element.text "Save" }
    , Input.button [Background.color blue] {onPress = Just (DiscardEdits note.id), label = Element.text "Discard" }
    ]
  , contentInput (ContentUpdate note.id) note.content
  , sourceInput (SourceUpdate note.id) note.source
  , Element.wrappedRow [] (List.map toLink note.links)
  ]

notInEditContent: S.DescriptionNote -> (List (Element Msg))
notInEditContent note =
  [ Element.wrappedRow [Element.spacing 8, Element.padding 8] 
    [ Input.button [Background.color blue] {onPress = (Just (NoteSelect note.id (note.x, note.y))) , label = (Element.text "Find")}
    , Input.button [Background.color blue] {onPress = (Just (NoteDismiss note.id)), label = (Element.text "Dismiss") }
    , Input.button [Background.color blue] {onPress = (Just (EditNote note.id)), label = (Element.text "Edit") }
    , Input.button [Background.color blue] {onPress = (Just (DeleteNote note.id)), label = (Element.text "Delete") }
    ]
  , (Element.text note.content)
  , (Element.text note.source)
  , Element.wrappedRow [] (List.map toLink note.links)
  ]

toLink: S.DescriptionLink -> Element Msg
toLink link =
  Element.row [] 
    [ el [ Events.onClick (NoteSelect link.id (link.x, link.y))] (Element.text (String.fromInt link.idInt))
    , Input.button [] {onPress = (Just (DeleteLink link.linkId)), label = (Element.text "Delete") }
    ]

-- DECODER

type alias SlipboxResponse = 
  { notes: (List Note.NoteRecord)
  , links: (List S.LinkRecord)
  , actions: S.ActionResponse
  }

slipboxDecoder : Decoder SlipboxResponse
slipboxDecoder =
  map3 SlipboxResponse
    notesDecoder
    linksDecoder
    actionsDecoder

notesDecoder: Decoder (List Note.NoteRecord)
notesDecoder =
  field "notes" (list noteRecordDecoder)

linksDecoder: Decoder (List S.LinkRecord)
linksDecoder =
  field "links" (list linkRecordDecoder)

actionsDecoder: Decoder S.ActionResponse
actionsDecoder =
  field "actions" actionResponseDecoder

actionResponseDecoder: Decoder S.ActionResponse
actionResponseDecoder =
  map5 S.ActionResponse
    (field "create_note" (list createNoteRecordDecoder))
    (field "edit_note" (list editNoteRecordWrapperDecoder))
    (field "delete_note" (list createNoteRecordDecoder))
    (field "create_link" (list createLinkRecordDecoder))
    (field "delete_link" (list createLinkRecordDecoder))

noteRecordDecoder: Decoder Note.NoteRecord
noteRecordDecoder =
  map4 Note.NoteRecord
    (field "id_" int)
    (field "content" string)
    (field "source" string)
    (field "variant" string)

linkRecordDecoder: Decoder S.LinkRecord
linkRecordDecoder = 
  map3 S.LinkRecord
    (field "id_" int)
    (field "source" int)
    (field "target" int)

createNoteRecordDecoder: Decoder S.CreateNoteRecord
createNoteRecordDecoder =
  map2 S.CreateNoteRecord
    (field "action_id" int)
    noteRecordDecoder

editNoteRecordDecoder: Decoder Action.EditNoteRecord
editNoteRecordDecoder =
  map6 Action.EditNoteRecord
    (field "id_" int)
    (field "old_content" string)
    (field "new_content" string)
    (field "old_source" string)
    (field "new_source" string)
    (field "variant" string)

editNoteRecordWrapperDecoder: Decoder S.EditNoteRecordWrapper
editNoteRecordWrapperDecoder =
  map2 S.EditNoteRecordWrapper
    (field "action_id" int)
    editNoteRecordDecoder

createLinkRecordDecoder: Decoder S.CreateLinkRecord
createLinkRecordDecoder =
  map2 S.CreateLinkRecord
    (field "action_id" int)
    linkRecordDecoder
offsetXDecoder: Decoder Int
offsetXDecoder = field "offsetX" int

offsetYDecoder: Decoder Int
offsetYDecoder = field "offsetY" int

mouseEventDecoder: Decoder V.MouseEvent
mouseEventDecoder = map2 V.MouseEvent offsetXDecoder offsetYDecoder

mouseMoveDecoder: Decoder Msg
mouseMoveDecoder = map IfPanningShift mouseEventDecoder

mouseDownDecoder: Decoder Msg
mouseDownDecoder = map PanningStart mouseEventDecoder