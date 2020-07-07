module Main exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Html.Attributes exposing (class, rel, href)
import Array

-- MAIN
main = Browser.sandbox { init = init, update = update, view = view }

-- MODEL
type Model
  = Overflow (Array.Array String) (Array.Array String)
  | NoOverflow (Array.Array String)

init: Model
init =
  let
    questions = [
      "Question 0", "Question 1", "Question 2", 
      "Question 3", "Question 4", "Question 5", 
      "Question 6", "Question 7", "Question 8"]
    questionLength = List.length questions
    inScope = 5
  in
    if questionLength > inScope then
      Overflow (Array.fromList (List.take inScope questions)) (Array.fromList (List.reverse (List.drop inScope questions)))
    else
      NoOverflow (Array.fromList questions)
      

-- UPDATE
type Msg = Clockwise | CounterClockwise

update : Msg -> Model -> Model
update msg model =
  case msg of
    Clockwise ->
      clockwise model

    CounterClockwise ->
      counterClockwise model

removeFirstElement : (Array.Array String) -> (Array.Array String)
removeFirstElement arr =
  Array.slice 1 (Array.length arr) arr

addElementToTop : String -> (Array.Array String) -> (Array.Array String)
addElementToTop str arr =
  Array.append (Array.fromList [str]) arr

removeLastElement : (Array.Array String) -> (Array.Array String)
removeLastElement arr =
  Array.slice 0 -1 arr

getLastElement : (Array.Array String) -> (Maybe String)
getLastElement arr =
  Array.get (Array.length arr - 1) arr

getFirstElement : (Array.Array String) -> (Maybe String)
getFirstElement arr =
  Array.get 0 arr



clockwise : Model -> Model
clockwise model = 
  case model of 
    Overflow current outside->
      let 
        elementMovingOutside = getFirstElement current
        elementMovingCurrent = getLastElement outside
      in
        case elementMovingCurrent of
          Just elCur ->
            case elementMovingOutside of
              Just elOut ->
                Overflow (Array.push elCur (removeFirstElement current)) (addElementToTop elOut (removeLastElement outside))
              Nothing ->
                Overflow current outside
          Nothing ->
            Overflow current outside

    NoOverflow current->
      let
        firstElement = getFirstElement current
      in
        case firstElement of
          Just element ->
            NoOverflow (Array.push element (removeFirstElement current))
          Nothing ->
            NoOverflow Array.empty
        

counterClockwise : Model -> Model
counterClockwise model = 
  case model of 
    Overflow current outside->
      let 
        elementMovingOutside = getLastElement current
        elementMovingCurrent = getFirstElement outside
      in
        case elementMovingCurrent of
          Just elCur ->
            case elementMovingOutside of
              Just elOut ->
                Overflow (addElementToTop elCur (removeLastElement current)) (Array.push elOut (removeFirstElement outside))
              Nothing ->
                Overflow current outside
          Nothing ->
            Overflow current outside

    NoOverflow current->
      let
        lastElement = getLastElement current
      in
        case lastElement of
          Just element ->
            NoOverflow (addElementToTop element (removeLastElement current))
          Nothing ->
            NoOverflow Array.empty

-- VIEW

viewHelper : (Array.Array String) -> Html Msg
viewHelper arr =
  div [class "parent"]  
          [
            button [ onClick CounterClockwise ] [ text "^" ]
            , div [class "parent"] (List.map questionToHtml (Array.toList arr))
            , button [ onClick Clockwise ] [ text "v" ]
            , Html.node "link" [ rel "stylesheet", href "style.css" ] []]

view : Model -> Html Msg
view model = 
  case model of 
    Overflow current _->
      viewHelper current
    NoOverflow current ->
      viewHelper current
questionToHtml : String -> Html Msg
questionToHtml str = 
  div [class "questionContainer"] [text str]