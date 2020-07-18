module Main exposing (..)

import Browser

-- MAIN
main = Browser.sandbox { init = init, update = update, view = view }

-- MODEL
type Model

init: Model      

-- UPDATE
update : 

-- VIEW
view : Model -> Html Msg
view model