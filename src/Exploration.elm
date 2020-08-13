module Exploration exposing (..)

import Browser
import Html exposing (Html, div, input, text, button, textarea, option, select)
import Html.Attributes exposing (placeholder, value, selected)
import Html.Events exposing (onInput, onClick, onMouseLeave, onMouseEnter)
import Svg exposing (Svg, svg, circle, line, rect, animate)
import Svg.Attributes exposing (width, height, viewBox, cx, cy, r, x1, y1, x2, y2, style, transform, attributeName, dur, values, repeatCount)
import Svg.Events exposing (on, onMouseUp, onMouseOut)
import Json.Decode exposing (Decoder, int, map, field, map2)


-- Modules
import Viewport as V
import Slipbox as S
import LinkForm
import Note

-- MAIN

main =
  Browser.sandbox { init = init, update = update, view = view }

-- MODEL
type Model = Model S.Slipbox Search V.Viewport CreateNoteForm

init : Model
init =
  Model (S.initialize initNoteData initLinkData initHistoryData) (Shown "") V.initialize initCreateNoteForm

initNoteData : List Note.NoteRecord
initNoteData = 
  [ Note.NoteRecord 1 "What is the Elm langauge?" "Source 1" "index"
  , Note.NoteRecord 2 "Why does some food taste better than others?" "Source 2" "index"
  , Note.NoteRecord 3 "Note 0" "Source 1" "note"]

initLinkData: List S.LinkRecord
initLinkData =
  [ S.LinkRecord 1 3 1
  ]

initHistoryData: ((List S.CreateNoteRecord), (List S.CreateLinkRecord))
initHistoryData =
  (
    [ S.CreateNoteRecord 1 (Note.NoteRecord 1 "What is the Elm langauge?" "Source 1" "index")
    , S.CreateNoteRecord 2 (Note.NoteRecord 2 "Why does some food taste better than others?" "Source 2" "index")
    , S.CreateNoteRecord 3 (Note.NoteRecord 3 "Note 0" "Source 1" "note")
    ]
    , [ S.CreateLinkRecord 4 (S.LinkRecord 1 3 1) ]
  )

-- SEARCH
type Search = 
  Shown Query |
  Hidden Query

type alias Query = String

toggle: Search -> Search
toggle search =
  case search of
    Shown query -> Hidden query
    Hidden query -> Shown query

updateSearch: String -> Search -> Search
updateSearch query search =
  case search of
    Shown _ -> Shown query
    Hidden _ -> Hidden query

shouldShowSearch: Search -> Bool
shouldShowSearch search =
  case search of
    Shown _ -> True
    Hidden _ -> False

getSearchString: Search -> String
getSearchString search =
  case search of 
    Shown str -> str
    Hidden str -> str

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

wipeAndHideForm: CreateNoteForm -> CreateNoteForm
wipeAndHideForm form =
  case form of
    ShowForm _ _ _ -> HideForm "" "" Regular
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
  ToggleSearch |
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
  SubmitCreateLink |
  LinkFormSourceSelected String |
  LinkFormTargetSelected String

update : Msg -> Model -> Model
update msg model =
  case msg of 
    ToggleSearch -> handleToggleSearch model
    UpdateSearch query -> handleUpdateSearch query model
    PanningStart mouseEvent -> handlePanningStart mouseEvent model
    IfPanningShift mouseEvent -> handleIfPanningShift mouseEvent model
    PanningStop -> handlePanningStop model
    ZoomIn -> handleZoomIn model
    ZoomOut -> handleZoomOut model
    NoteSelect note coords -> handleNoteSelect note coords model
    MapNoteSelect note -> handleMapNoteSelect note model
    NoteDismiss note -> handleNoteDismiss note model
    NoteHighlight note -> handleNoteHighlight note model
    NoteRemoveHighlights -> handleNoteRemoveHighlights model
    ToggleCreateNoteForm -> handleToggleCreateNoteForm model
    ContentInputCreateNoteForm s -> handleContentInputCreateNoteForm s model
    SourceInputCreateNoteForm s -> handleSourceInputCreateNoteForm s model
    ChangeNoteTypeCreateNoteForm s -> handleChangeNoteTypeCreateNoteForm s model 
    SubmitCreateNoteForm -> handleSubmitCreateNoteForm model
    SubmitCreateLink -> handleSubmitCreateLink model
    LinkFormSourceSelected s -> handleLinkFormSourceSelected s model
    LinkFormTargetSelected s -> handleLinkFormTargetSelected s model 

handleToggleSearch: Model -> Model
handleToggleSearch model =
  case model of 
    Model slipbox search viewport form ->
      Model slipbox (toggle search) viewport form

handleUpdateSearch: String -> Model -> Model
handleUpdateSearch query model =
  case model of 
    Model slipbox search viewport form ->
      Model slipbox (updateSearch query search) viewport form
  
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
      Model (S.createNote (makeNoteRecord form) slipbox) query viewport (wipeAndHideForm form)

handleSubmitCreateLink: Model -> Model
handleSubmitCreateLink model =
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

-- VIEW
view : Model -> Html Msg
view model =
  case model of 
    Model slipbox search viewport form->
      div [style "padding: 16px; border: 4px solid black"] 
        [ searchBox slipbox search
        , noteNetwork slipbox viewport
        , panningVisual viewport
        , button [ onClick ZoomOut ] [ text "-" ]
        , button [ onClick ZoomIn ] [ text "+" ]
        , selectedNotes slipbox
        , linkForm slipbox
        , historyView slipbox
        , handleCreateNoteForm form
        ]

searchBox : S.Slipbox -> Search -> Html Msg
searchBox slipbox search =
  if shouldShowSearch search then
    searchBoxShown slipbox (getSearchString search)
  else
    questionButton

questionButton: Html Msg
questionButton = 
  button [ onClick ToggleSearch ] [ text "S" ]

searchBoxShown: S.Slipbox -> String -> Html Msg
searchBoxShown slipbox searchString =
  div [] 
    [ input [placeholder "Find Note", value searchString, onInput UpdateSearch] []
    , searchResults slipbox searchString
    , questionButton
    ]

searchResults: S.Slipbox -> String -> Html Msg
searchResults slipbox searchString =
  div 
    [ style "border: 4px solid black; padding: 16px;"] 
    (List.map toResultPane (S.searchSlipbox searchString slipbox))

toResultPane: S.SearchResult -> Html Msg
toResultPane sr =
  let 
    backgroundColor = "background-color:" ++ (noteColor sr.variant) ++ ";"
    styleString = "border: 1px solid black;margin-bottom: 16px;cursor:pointer;" ++ backgroundColor
  in
    div 
      [style styleString
      , onClick (NoteSelect sr.id (sr.x, sr.y))
      ] 
      [text sr.content]

noteNetwork: S.Slipbox -> V.Viewport -> Svg Msg
noteNetwork slipbox viewport =
  svg
    [ width V.svgWidthString
    , height V.svgLengthString
    , viewBox (V.getViewbox viewport)
    , style "border: 4px solid black;"
    ]
    (graphElements (S.getGraphElements slipbox))

graphElements: ((List S.GraphNote),(List S.GraphLink)) -> (List (Svg Msg))
graphElements (notes, links) =
  List.map toSvgCircle notes ++ List.map toSvgLine links

toSvgCircle: S.GraphNote -> Svg Msg
toSvgCircle note =
  circle 
    [ cx (String.fromFloat note.x)
    , cy (String.fromFloat note.y) 
    , r "5"
    , style ("Cursor:Pointer;" ++ "fill:" ++ (noteColor note.variant) ++ ";")
    , onClick (MapNoteSelect note.id) 
    ]
    (handleCircleAnimation note.shouldAnimate)

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

panningVisual: V.Viewport -> Svg Msg
panningVisual viewport =
  panningSvg (V.getPanningAttributes viewport)
      
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

offsetXDecoder: Decoder Int
offsetXDecoder = field "offsetX" int

offsetYDecoder: Decoder Int
offsetYDecoder =field "offsetY" int

mouseEventDecoder: Decoder V.MouseEvent
mouseEventDecoder = map2 V.MouseEvent offsetXDecoder offsetYDecoder

mouseMoveDecoder: Decoder Msg
mouseMoveDecoder = map IfPanningShift mouseEventDecoder

mouseDownDecoder: Decoder Msg
mouseDownDecoder = map PanningStart mouseEventDecoder

selectedNotes: S.Slipbox -> Html Msg
selectedNotes slipbox =
  div 
    [style "border: 4px solid black; padding: 16px;"] 
    (List.map toDescription (S.getSelectedNotes slipbox))

toDescription: S.DescriptionNote -> Html Msg
toDescription note =
  div [] [
    button [onClick (NoteDismiss note.id)] [text "-"]
    , div 
      [ style "border: 1px solid black;margin-bottom: 16px;cursor:pointer;"
      , onClick (NoteSelect note.id (note.x, note.y))
      , onMouseEnter (NoteHighlight note.id)
      , onMouseLeave NoteRemoveHighlights
      ] 
      [ Html.text note.content
      , Html.text note.source
      , div [] (List.map toLinkDiv note.links)
      ]
  ]

toLinkDiv: S.DescriptionLink -> Html Msg
toLinkDiv link =
  div 
    [ onClick (NoteSelect link.id (link.x, link.y))] 
    [ Html.text (String.fromInt link.idInt)]

historyView: S.Slipbox -> Html Msg
historyView slipbox =
  div [style "padding: 16px; border: 4px solid black"] (List.map toHistoryPane (S.getHistory slipbox))

toHistoryPane: S.HistoryAction -> Html Msg
toHistoryPane action =
  div 
    [style (historyTextColor action.undone)] 
    [text action.summary]

historyTextColor: Bool -> String
historyTextColor undone =
  if undone then
    "color:gray;"
  else
    "color:black;"

handleCreateNoteForm: CreateNoteForm -> Html Msg
handleCreateNoteForm form =
  let
    formData = getCreateFormData form
  in
    if formData.shown then
      createNoteForm formData
    else
      createFormButton

createNoteForm: CreateForm -> Html Msg
createNoteForm form =
  div [] 
  [ div [style "padding: 16px; border: 4px solid black"]
    [ textarea [onInput ContentInputCreateNoteForm] [text form.content]
    , input [onInput SourceInputCreateNoteForm] [text form.source]
    , select [onInput ChangeNoteTypeCreateNoteForm] (formOptions form.isIndex)
    , submitFormButton form.canSubmit
    ]
  , createFormButton
  ]

formOptions: Bool -> (List (Html Msg))
formOptions indexOptionChosen =
  if indexOptionChosen then
    [ option [selected True, value "index"] [text "Index"]
    , option [value "Regular"] [text "Regular"]
    ]
  else
    [ option [value "index"] [text "Index"]
    , option [selected True, value "Regular"] [text "Regular"]
    ]

createFormButton: Html Msg
createFormButton = button [onClick ToggleCreateNoteForm] [text "+"] 

submitFormButton: Bool -> Html Msg
submitFormButton canSubmitNote = 
  if canSubmitNote then
    button [onClick SubmitCreateNoteForm, style "cursor:pointer;"] [text "Create Note"]
  else
    button [] [text "Create Note"]

linkForm: S.Slipbox -> Html Msg
linkForm slipbox =
  createLinkForm (S.getLinkFormData slipbox)

createLinkForm: LinkForm.LinkFormData -> Html Msg
createLinkForm formData =
  if formData.shown then
    createLinkFormHandler formData
  else
    div [] []

createLinkFormHandler: LinkForm.LinkFormData -> Html Msg
createLinkFormHandler formData =
  div []
    [ select [Html.Attributes.name "Source", onInput LinkFormSourceSelected, value (valueHandler formData.sourceChosen)] (optionHandler formData.sourceChosen formData.sourceChoices) 
    , select [Html.Attributes.name "Target", onInput LinkFormTargetSelected, value (valueHandler formData.targetChosen)] (optionHandler formData.targetChosen formData.targetChoices)
    , createLinkButton formData.canSubmit
    ]
  
valueHandler: LinkForm.Choice -> String
valueHandler choice =
  if choice.choiceMade then
    String.fromInt choice.choiceValue
  else
    "noOption"

optionHandler: LinkForm.Choice -> (List LinkForm.LinkNoteChoice) -> (List (Html Msg))
optionHandler choice options =
  if choice.choiceMade then
    List.map toOption options
  else
    notChosenDefault :: List.map toOption options

notChosenDefault: Html Msg
notChosenDefault = option [Html.Attributes.disabled True, selected True, value "noOption"] [text "--select an option--"]

toOption: LinkForm.LinkNoteChoice -> Html Msg
toOption linkNoteChoice =
  option [value (String.fromInt linkNoteChoice.value)] [text linkNoteChoice.display]

createLinkButton: Bool -> Html Msg
createLinkButton canSubmitLink =
  if canSubmitLink then
    button [style "cursor:pointer;", onClick SubmitCreateLink] [text "Create Link"]
  else 
    button [style "background:gray;"] [text "Create Link"]

noteColor: String -> String
noteColor variant =
  if variant == "index" then
    "rgba(250, 190, 88, 1)"
  else
    "rgba(137, 196, 244, 1)"
