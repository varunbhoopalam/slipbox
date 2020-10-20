module SourceSummary exposing (..)

import Browser
import Browser.Dom as Dom
import Html exposing (Html, text)
import Element as ElmUI
import Task
import Http as Http
import Json.Decode as Decode

-- MAIN
main =
  Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }

-- MODEL

type alias Model =
  { device : ElmUI.Device
  , state : PageState
  }

type PageState = 
  Loading |
  Failed String |
  Success Source |
  InEdit Source Edits |
  AssociationChangeAfterSourceEdit Source Edits Associations |
  AssociationInEdit Source AssociationEdits

type alias Source = 
  { id: Int
  , title: String
  , author: String
  , created: Int
  , updated: Int
  , content: String
  , associatedNotes: List Note
  }

type Note = 
  Unassociated NoteContent |
  Associated NoteContent Association

type alias NoteContent =
  { id: Int
  , content: String 
  }

type alias Association =
  { startAssociation: Int
  , endAssociation: Int
  }

type alias Edits = String

type alias Associations = String
type alias AssociationEdits = String

-- INIT

init : () -> (Model, Cmd Msg)
init _ = 
  (Model {class = ElmUI.Desktop, orientation = ElmUI.Landscape} Loading
  , Cmd.batch [fooViewport, fooApiCall]
  )

fooViewport: Cmd Msg
fooViewport = Task.perform GotViewport Dom.getViewport

fooApiCall: Cmd Msg
fooApiCall = 
  Http.get
    { url = "http://localhost:5000/"
    , expect = Http.expectJson FooApiCall (Decode.succeed 42)
    }

fooInitData: Model -> Model
fooInitData model =
  let
    note1 = 
      Associated 
        (NoteContent 0 "Sapiens illustrates how history is neither natural, nor inevitable.")
        (Association 0 10)
    note2 = 
      Unassociated
        (NoteContent 1 
          """Writing as invented to address human brains inadequacey for storing and 
          processing large amounts of mathematical data.
          """)
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
        |> Success
  in
    { model | state = state }


-- UPDATE

type Msg = 
  GotViewport Dom.Viewport |
  FooApiCall (Result Http.Error Int)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of 
        GotViewport viewport -> (handleGotViewport viewport model, Cmd.none)
        FooApiCall _ -> (fooInitData model, Cmd.none)

handleGotViewport: Dom.Viewport -> Model -> Model
handleGotViewport viewport model = 
  let
    height = viewport.viewport.height
    width = viewport.viewport.width
    window = {height = round height, width = round width}
  in
  { model | device = ElmUI.classifyDevice window }


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model = Sub.none

-- VIEW

view : Model -> Html Msg
view model = 
  view_ model |> ElmUI.layout []
  
view_: Model -> ElmUI.Element Msg
view_ model =
  case model.state of 
    Loading -> ElmUI.text "loading"
    Failed _ -> ElmUI.text "todo"
    Success source -> 
      case model.device.class of 
        ElmUI.Phone -> successPhoneLayout source
        ElmUI.Tablet -> ElmUI.text "todo"
        ElmUI.Desktop -> ElmUI.text "todo" 
        ElmUI.BigDesktop -> ElmUI.text "todo"
    InEdit _ _ -> ElmUI.text "todo"
    AssociationChangeAfterSourceEdit _ _ _ -> ElmUI.text "todo"
    AssociationInEdit _ _ -> ElmUI.text "todo"

successPhoneLayout: Source -> ElmUI.Element Msg
successPhoneLayout source = 
  ElmUI.column 
    []
    [ title source.title
    , author source.author
    , created source.created
    , updated source.updated
    , edit
    , delete
    , content source.content
    , associatedNotesPhone source.associatedNotes
    ]

title: String -> ElmUI.Element Msg
title str = ElmUI.text "todo"
author: String -> ElmUI.Element Msg
author str = ElmUI.text "todo"

created: Int -> ElmUI.Element Msg
created date = ElmUI.text "todo"

updated: Int -> ElmUI.Element Msg
updated date = ElmUI.text "todo"

edit: ElmUI.Element Msg
edit = ElmUI.text "todo"

delete: ElmUI.Element Msg
delete = ElmUI.text "todo"

content: String -> ElmUI.Element Msg
content str = ElmUI.text "todo"

associatedNotesPhone: (List Note) -> ElmUI.Element Msg
associatedNotesPhone notes = ElmUI.text "todo"