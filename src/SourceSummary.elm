module SourceSummary exposing (Model, Msg, init, subscriptions, update, view)

import Browser
import Browser.Dom as BrowserDom
import Browser.Events as BrowserEvents
import Html exposing (Html, text)
import Element as ElmUI
import Element.Input as Input
import Task
import Http as Http
import Json.Decode as Decode
import Time as Time
import Date as Date

-- MODEL

type alias Model =
  { device : ElmUI.Device
  , state : PageState
  , timezone: Time.Zone
  }

type PageState = 
  Loading | -- If I want to show a loading bar I can add this to the model here for get request and add subscription to update the model from elm http library
  Failed String |
  View Source |
  InEdit Source Edits RequestStatus | -- If I want to show a loading bar I can add this to the model here for post/patch request and add subscription to update the model from elm http library
  ShouldDeletePrompt Source | -- If I want to show a loading bar I can add this to the model here for delete request and add subscription to update the model from elm http library
  DeleteSuccess Source

type alias Source = 
  { id: Int
  , title: String
  , author: String
  , created: Int
  , updated: Int
  , content: String
  , associatedNotes: List Note
  }

type alias Note = 
  { id: Int
  , content: String 
  }

type alias Edits =
  { title: String
  , author: String
  , content: String
  }

type RequestStatus =
  NoRequest |
  RequestMade (Maybe Http.Progress)

type Field =
  Title |
  Author |
  Content

type alias Width = Int
type alias Height = Int

-- INIT

init : (Int) -> (Model, Cmd Msg)
init sourceId = 
  (Model {class = ElmUI.Desktop, orientation = ElmUI.Landscape} Loading Time.utc
  , Cmd.batch [fooViewport, fooApiCall sourceId, getTimezone]
  )

fooViewport: Cmd Msg
fooViewport = Task.perform GotViewport BrowserDom.getViewport

fooApiCall: Int -> Cmd Msg
fooApiCall _ = 
  Http.get
    { url = "http://localhost:5000/"
    , expect = Http.expectJson FooApiCall (Decode.succeed 42)
    }

getTimezone: Cmd Msg
getTimezone = Task.perform GotTimezone Time.here

fooInitData: Model -> Model
fooInitData model =
  let
    note1 = Note 0 "Sapiens illustrates how history is neither natural, nor inevitable."
    note2 = Note 1 
          """Writing as invented to address human brains inadequacey for storing and 
          processing large amounts of mathematical data.
          """
    state = 
      Source 
        0 
        "Sapiens: A Brief History of Humankind"
        "Yuval Noah Harrari"
        1603200000
        1603209942
        """ Sapiens illustrates how history is neither natural, nor inevitable. 
        We walk through the time before culture to modern day and explore how cultures
        have changed over time and what the resulted from it.
        """
        []
        |> View
  in
    { model | state = state }

sendDeleteRequest: Model -> Cmd Msg
sendDeleteRequest _ = Cmd.none

sendSaveRequest: Source -> Edits -> Cmd Msg
sendSaveRequest _ _ = Cmd.none

cancelRequest: Cmd Msg
cancelRequest = Cmd.none

-- UPDATE

type Msg = 
  GotViewport BrowserDom.Viewport |
  FooApiCall (Result Http.Error Int) |
  GotTimezone Time.Zone |
  StartEdit |
  DiscardEdits |
  ToDeletePrompt |
  TryDelete |
  DoNotDelete |
  Save |
  CancelRequest |
  FieldUpdate Field String |
  GotWindowResize (Width, Height)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of 
        GotViewport viewport -> (handleWindowInfo (getHeightWidth viewport) model, Cmd.none)
        FooApiCall _ -> (fooInitData model, Cmd.none)
        GotTimezone timezone -> (handleGotTimezone timezone model, Cmd.none)
        StartEdit -> (handleStartEdit model, Cmd.none)
        DiscardEdits -> (handleDiscardEdits model, Cmd.none)
        ToDeletePrompt -> (handleDeleteClicked model, Cmd.none)
        TryDelete -> (handleTryDelete model, sendDeleteRequest model)
        DoNotDelete -> (handleDoNotDelete model, Cmd.none)
        Save -> handleSave model
        CancelRequest -> handleCancelRequest model
        FieldUpdate field value -> (handleFieldUpdate field value model, Cmd.none)
        GotWindowResize vals -> (handleWindowInfo vals model, Cmd.none)

handleWindowInfo: (Width,Height) -> Model -> Model
handleWindowInfo (width,height) model = 
  { model | device = {height = height, width = width} |> ElmUI.classifyDevice }

getHeightWidth: BrowserDom.Viewport -> (Width, Height)
getHeightWidth viewport =
  (round viewport.viewport.width, round viewport.viewport.height)

handleGotTimezone: Time.Zone -> Model -> Model
handleGotTimezone timezone model =
  { model | timezone = timezone}

handleStartEdit: Model -> Model
handleStartEdit model =
  case model.state of
    Loading -> model
    Failed _ -> model
    View source -> { model | state = 
      InEdit
        source
        (Edits source.title source.author source.content) 
        NoRequest 
      }
    InEdit _ _ _ -> model
    ShouldDeletePrompt _ -> model
    DeleteSuccess _ -> model

handleDiscardEdits: Model -> Model
handleDiscardEdits model =
  case model.state of
    Loading -> model
    Failed _ -> model
    View _ -> model
    InEdit source _ _ -> {model | state = View source}
    ShouldDeletePrompt _ -> model
    DeleteSuccess _ -> model

handleDeleteClicked: Model -> Model
handleDeleteClicked model =
  case model.state of
    Loading -> model
    Failed _ -> model
    View source -> {model | state = ShouldDeletePrompt source}
    InEdit _ _ _ -> model
    ShouldDeletePrompt _ -> model
    DeleteSuccess _ -> model

handleTryDelete: Model -> Model
handleTryDelete model = model

handleDoNotDelete: Model -> Model
handleDoNotDelete model = 
  case model.state of
    Loading -> model
    Failed _ -> model
    View source -> model
    InEdit _ _ _ -> model
    ShouldDeletePrompt source -> {model | state = View source}
    DeleteSuccess _ -> model

handleSave: Model -> (Model, Cmd Msg)
handleSave model =
  case model.state of
    Loading -> (model, Cmd.none)
    Failed _ -> (model, Cmd.none)
    View source -> (model, Cmd.none)
    ShouldDeletePrompt _ -> (model, Cmd.none)
    DeleteSuccess _ -> (model, Cmd.none)
    InEdit source edits _ -> 
      if editMade source edits then
        ({model | state = InEdit source edits (RequestMade Nothing)}, sendSaveRequest source edits)
      else
        ({model | state = View source}, Cmd.none)

editMade: Source -> Edits -> Bool
editMade source edits = 
  let
    titleChanged = source.title /= edits.title
    authorChanged = source.author /= edits.author
    contentChanged = source.content /= edits.content
  in
    titleChanged || authorChanged || contentChanged

handleCancelRequest: Model -> (Model, Cmd Msg)
handleCancelRequest model =
  case model.state of
    Loading -> (model, Cmd.none)
    Failed _ -> (model, Cmd.none)
    View source -> (model, Cmd.none)
    ShouldDeletePrompt _ -> (model, Cmd.none)
    DeleteSuccess _ -> (model, Cmd.none)
    InEdit source edits requestStatus -> 
      case requestStatus of
        NoRequest -> (model, Cmd.none)
        RequestMade _ -> ({model | state = InEdit source edits NoRequest}, cancelRequest)

handleFieldUpdate: Field -> String -> Model -> Model
handleFieldUpdate field value model =
  case model.state of
    Loading -> model
    Failed _ -> model
    View source -> model
    ShouldDeletePrompt _ -> model
    DeleteSuccess _ -> model
    InEdit source edits requestStatus -> 
      case requestStatus of
        RequestMade _ -> model
        NoRequest -> 
          case field of
             Title -> {model | state = InEdit source (Edits value edits.author edits.content) requestStatus}
             Author -> {model | state = InEdit source (Edits edits.title value edits.content) requestStatus}
             Content -> {model | state = InEdit source (Edits edits.title edits.author value) requestStatus}

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model = Sub.batch
  [ BrowserEvents.onResize (\w h -> GotWindowResize (w,h))
  ]
-- TODO: Set up subscription for tracking progress of a request, may require model change

-- VIEW

view : Model -> Html Msg
view model = 
  view_ model |> ElmUI.layout []
  
view_: Model -> ElmUI.Element Msg
view_ model =
  case model.state of 
    Loading -> ElmUI.text "loading"
    Failed _ -> ElmUI.text "Problems contacting the backend"
    View source -> 
      case model.device.class of 
        ElmUI.Phone -> viewPhone source model.timezone
        ElmUI.Tablet -> viewDesktop source model.timezone
        ElmUI.Desktop -> viewDesktop source model.timezone
        ElmUI.BigDesktop -> viewDesktop source model.timezone
    InEdit source edits requestStatus ->
      case requestStatus of
        NoRequest ->
          case model.device.class of 
            ElmUI.Phone -> editPhone source edits model.timezone
            ElmUI.Tablet -> editDesktop source edits model.timezone
            ElmUI.Desktop -> editDesktop source edits model.timezone
            ElmUI.BigDesktop -> editDesktop source edits model.timezone
        RequestMade mProgress ->
          case model.device.class of 
            ElmUI.Phone -> editPhoneRequestMade source edits mProgress model.timezone
            ElmUI.Tablet -> editDesktopRequestMade source edits mProgress model.timezone
            ElmUI.Desktop -> editDesktopRequestMade source edits mProgress model.timezone
            ElmUI.BigDesktop -> editDesktopRequestMade source edits mProgress model.timezone
    ShouldDeletePrompt source -> shouldDeletePrompt source.title
    DeleteSuccess source -> deleteSuccess source.title

viewPhone: Source -> Time.Zone -> ElmUI.Element Msg
viewPhone source zone = 
  ElmUI.column 
    []
    [ title source.title
    , author source.author
    , createdTime source.created zone
    , updatedTime source.updated zone
    , edit
    , delete
    , content source.content 
    , notesPhone source.associatedNotes
    ]

editPhone: Source -> Edits -> Time.Zone -> ElmUI.Element Msg
editPhone source edits zone = 
  ElmUI.column 
    []
    [ editTitle source.title edits.title
    , editAuthor source.author edits.author
    , createdTime source.created zone
    , updatedTime source.updated zone
    , save
    , discard
    , editContent source.content edits.content
    , notesPhone source.associatedNotes
    ]

editPhoneRequestMade: Source -> Edits -> (Maybe Http.Progress) -> Time.Zone -> ElmUI.Element Msg
editPhoneRequestMade source edits maybeProgress zone =
  ElmUI.column
    []
    [ title edits.title
    , author edits.author
    , createdTime source.created zone
    , updatedTime source.updated zone
    , viewProgress maybeProgress
    , cancel
    , content edits.content
    , notesPhone source.associatedNotes
    ]

viewDesktop: Source -> Time.Zone -> ElmUI.Element Msg
viewDesktop source zone =
  ElmUI.column 
    []
    [ title source.title
    , author source.author
    , createdTime source.created zone
    , updatedTime source.updated zone
    , edit
    , delete
    , content source.content 
    , notesPhone source.associatedNotes
    ]

editDesktop: Source -> Edits -> Time.Zone -> ElmUI.Element Msg
editDesktop source edits zone = 
  ElmUI.column 
    []
    [ editTitle source.title edits.title
    , editAuthor source.author edits.author
    , createdTime source.created zone
    , updatedTime source.updated zone
    , save
    , discard
    , editContent source.content edits.content
    , notesPhone source.associatedNotes
    ]

editDesktopRequestMade: Source -> Edits -> (Maybe Http.Progress) -> Time.Zone -> ElmUI.Element Msg
editDesktopRequestMade source edits maybeProgress zone =
  ElmUI.column
    []
    [ title edits.title
    , author edits.author
    , createdTime source.created zone
    , updatedTime source.updated zone
    , viewProgress maybeProgress
    , cancel
    , content edits.content
    , notesPhone source.associatedNotes
    ]

title: String -> ElmUI.Element Msg
title str = "Title: " ++ str |> ElmUI.text

editTitle: String -> String -> ElmUI.Element Msg
editTitle _ updated = 
  { onChange = FieldUpdate Title
  , text = updated
  , placeholder = Nothing
  , label = ElmUI.text "title" |> Input.labelBelow [] 
  }
  |> Input.text []

author: String -> ElmUI.Element Msg
author str = "Author: " ++ str |> ElmUI.text

editAuthor: String -> String -> ElmUI.Element Msg
editAuthor _ updated = 
  { onChange = FieldUpdate Author
  , text = updated
  , placeholder = Nothing
  , label = ElmUI.text "author" |> Input.labelBelow [] 
  }
  |> Input.text []

createdTime: Int -> Time.Zone -> ElmUI.Element Msg
createdTime millis zone = "Created: " ++ toDateRepresentation millis zone |> ElmUI.text

-- If http request to update works, then need to make new updated time in model
updatedTime: Int -> Time.Zone -> ElmUI.Element Msg
updatedTime millis zone = "Updated:" ++ toDateRepresentation millis zone |> ElmUI.text

toDateRepresentation: Int -> Time.Zone -> String
toDateRepresentation millis zone = 
  Time.millisToPosix millis |> Date.fromPosix zone |> Date.format "EEEE, d MMMM y"

edit: ElmUI.Element Msg
edit = Input.button [] {onPress = Just StartEdit, label = ElmUI.text "Edit"}

delete: ElmUI.Element Msg
delete = Input.button [] {onPress = Just ToDeletePrompt, label = ElmUI.text "Delete"}

save: ElmUI.Element Msg
save = Input.button [] {onPress = Just Save, label = ElmUI.text "Save"}

discard: ElmUI.Element Msg
discard = Input.button [] {onPress = Just DiscardEdits, label = ElmUI.text "Discard"}

content: String-> ElmUI.Element Msg
content str = ElmUI.paragraph [] [ElmUI.text str] 

editContent: String -> String -> ElmUI.Element Msg
editContent _ updated = 
  { onChange = FieldUpdate Content
  , text = updated
  , placeholder = Nothing
  , label = ElmUI.text "content" |> Input.labelBelow [] 
  , spellcheck = True
  }
  |> Input.multiline []

notesPhone: (List Note) -> ElmUI.Element Msg
notesPhone notes = 
  List.map visualizeNote notes |> ElmUI.column []
    
-- TODO route to other part of the app on click/navigate
visualizeNote: Note -> ElmUI.Element Msg
visualizeNote note =
  ElmUI.text note.content |> ElmUI.el [] 

shouldDeletePrompt: String -> ElmUI.Element Msg
shouldDeletePrompt sourceTitle =
  ElmUI.column [] 
    [ "Are you sure you want to delete this source?" |> ElmUI.text
    , ElmUI.text sourceTitle
    , Input.button [] {onPress = Just TryDelete, label = ElmUI.text "Delete"}
    , Input.button [] {onPress = Just DoNotDelete, label = ElmUI.text "Do Not Delete"}
    ]

deleteSuccess: String -> ElmUI.Element Msg
deleteSuccess sourceTitle =
  ElmUI.column []
    [ "Successfully deleted " ++ sourceTitle |> ElmUI.text
    -- TODO
    , ElmUI.text "Todo" -- Routes to main source dashboard
    ]

viewProgress: (Maybe Http.Progress) -> ElmUI.Element Msg
viewProgress maybeProgress =
  case maybeProgress of
    Just progress -> toProgressRepresentation progress
    Nothing -> ElmUI.text "Submitting your updates"

toProgressRepresentation: Http.Progress -> ElmUI.Element Msg
toProgressRepresentation progress =
  case progress of
    Http.Sending data -> Http.fractionSent data * 100 / 2 |> progressToStringRep
    Http.Receiving data -> Http.fractionReceived data * 100 |> progressToStringRep

progressToStringRep: Float -> ElmUI.Element Msg
progressToStringRep fraction =
  (fraction |> Basics.floor |> String.fromInt) ++ "% request processed" |> ElmUI.text

cancel: ElmUI.Element Msg
cancel = Input.button [] {onPress = Just CancelRequest, label = ElmUI.text "Cancel"}