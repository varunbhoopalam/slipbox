module Main exposing (..)

import Browser
import Html exposing (Html, text, li, ul)
import Http
import Json.Decode exposing (Decoder, map5, field, string, list)

-- MAIN

main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

-- MODEL
type Model 
  = Failure
  | Loading
  | Success (List Notification)

init : () -> (Model, Cmd Msg)
init _ =
  (
    Loading
    , Http.get
    {
      expect = Http.expectJson GotText notificationsDecoder,
      url = "http://localhost:5000"
    }
  )

-- UPDATE
type Msg
  = GotText (Result Http.Error (List Notification))

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotText result ->
      case result of
        Ok notifications ->
          (Success notifications, Cmd.none)

        Err _ ->
          (Failure, Cmd.none)

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- VIEW
view : Model -> Html Msg
view model =
  case model of
    Failure ->
      text "I was unable to json."

    Loading ->
      text "Loading..."

    Success notifications ->
      ul [] (List.map notificationToLi notifications)

notificationToLi : Notification -> (Html msg)
notificationToLi notification = 
  li [] [text notification.name]

-- HTTP
type alias Notification = {
  name: String,
  content: String,
  sources: List(String),
  links: List(String),
  backLinks: List(String)
  }

notificationDecoder : Decoder Notification
notificationDecoder = 
  map5 Notification
    (field "name" string)
    (field "content" string)
    (field "sources" (list string))
    (field "links" (list string))
    (field "backLinks" (list string))

notificationsDecoder : Decoder (List Notification)
notificationsDecoder = 
  field "entries" (list notificationDecoder)