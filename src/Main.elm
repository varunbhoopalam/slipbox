module Main exposing (..)

import Browser as Browser
import Browser.Navigation as Nav
import Url as Url
import Url.Parser as Parser exposing ((</>))
import SourceSummary as SourceSummary
import Html as Html

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
  { key : Nav.Key
  , page : Page
  }

type Page = 
  Source SourceSummary.Model |
  NotFound 

-- INIT

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
  router url { key = key, page = NotFound}  

-- UPDATE
type Msg
  = SourceMsg SourceSummary.Msg
  | LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url

update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  case message of
    SourceMsg msg ->
      case model.page of
        Source source -> SourceSummary.update msg source |> sourceStep model
        _ -> ( model, Cmd.none) 
    -- TODO
    LinkClicked _ -> (model, Cmd.none)
    UrlChanged _ -> (model, Cmd.none)

-- VIEW

view: Model -> Browser.Document Msg
view model =
  case model.page of
    -- TODO: Make source a opaque type and create a getter for title
    Source source -> {title = "TODO", body = [Html.map SourceMsg <| SourceSummary.view source]}
    -- TODO: Need a not found page
    NotFound -> {title = "TODO", body = []}

-- SUBSCRIPTIONS
subscriptions: Model -> Sub Msg
subscriptions model =
  case model.page of 
    NotFound -> Sub.none
    Source source -> Sub.map SourceMsg (SourceSummary.subscriptions source)


-- ROUTER
router: Url.Url -> Model -> (Model, Cmd Msg) 
router url model =
  let
    parser = Parser.oneOf
      [ Parser.map 
        (\summaryId -> SourceSummary.init summaryId |> sourceStep model)
        (Parser.s "summary" </> Parser.int)
      ]
  in
    case Parser.parse parser url of
      Just answer ->
        answer
      Nothing ->
        ({model | page = NotFound}, Cmd.none)

-- Steps
sourceStep: Model -> (SourceSummary.Model, Cmd SourceSummary.Msg) -> (Model, Cmd Msg)
sourceStep model (summaryModel, sourceMsg) =
  ({model | page = Source summaryModel}, Cmd.map SourceMsg sourceMsg)


