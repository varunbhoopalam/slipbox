module Main exposing (..)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
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


clockwise : Model -> Model
clockwise model = 
  case model of 
    Overflow current outside->
      let 
        elementMovingOutside = Array.get 0 current
        elementMovingCurrent = Array.get (Array.length outside - 1) outside
      in
        case elementMovingCurrent of
          Just elCur ->
            case elementMovingOutside of
              Just elOut ->
                Overflow (Array.push elCur (removeFirstElement current)) (addElementToTop elOut (Array.slice 0 -1 outside))
              Nothing ->
                Overflow current outside
          Nothing ->
            NoOverflow Array.empty

    NoOverflow current->
      let
        firstElement = Array.get 0 current
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
        elementMovingOutside = Array.get (Array.length current - 1) current
        elementMovingCurrent = Array.get 0 outside
      in
        case elementMovingCurrent of
          Just elCur ->
            case elementMovingOutside of
              Just elOut ->
                Overflow (addElementToTop elCur (Array.slice 0 -1 current)) (Array.push elOut (removeFirstElement outside))
              Nothing ->
                Overflow current outside
          Nothing ->
            NoOverflow Array.empty

    NoOverflow current->
      let
        firstElement = Array.get 0 current
      in
        case firstElement of
          Just element ->
            NoOverflow (Array.push element (removeFirstElement current))
          Nothing ->
            NoOverflow Array.empty

-- VIEW
view : Model -> Html Msg
view model = 
  case model of 
    Overflow current _->
      div []  
          [
            button [ onClick CounterClockwise ] [ text "^" ]
            , div [] (List.map questionToHtml (Array.toList current))
            , button [ onClick Clockwise ] [ text "v" ]]
    NoOverflow current ->
      div []  
          [
            button [ onClick CounterClockwise ] [ text "^" ]
            , div [] (List.map questionToHtml (Array.toList current))
            , button [ onClick Clockwise ] [ text "v" ]]
    
questionToHtml : String -> Html Msg
questionToHtml str = 
  div [] [text str]