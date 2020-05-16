module Main exposing (..)

-- Press buttons to increment and decrement a counter.
--
-- Read how it works:
--   https://guide.elm-lang.org/architecture/buttons.html
--


import Browser
import Html exposing (Html, text, pre)
import Http

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
  | Success String


init : () -> (Model, Cmd Msg)
init _ =
  (
    Loading
    , Http.get
    {
      expect = Http.expectString GotText,
      url = "http://localhost:5000"
    }
  )




-- UPDATE
type Msg
  = GotText (Result Http.Error String)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotText result ->
      case result of
        Ok fullText ->
          (Success fullText, Cmd.none)

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

    Success fullText ->
      pre [] [ text fullText ]