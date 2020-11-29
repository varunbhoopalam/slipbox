module Tab.Notes exposing (..)

import Browser
import Element exposing (Element)
import Element.Input
import Element.Background
import Element.Border
import Html exposing (Html)
import Debug

-- MAIN
main =
  Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }

-- MODEL
type Model = 
  Regular Content |
  FilterOpen Content

type alias Content = 
  { slipbox: Slipbox.Slipbox
  , search: Maybe String
  }

-- INIT
init: () -> (Model, Cmd Msg)
init _ = (Model, Cmd.none)

-- UPDATE
type Msg =
  Msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Msg -> (model, Cmd.none)

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- VIEW
noteTabView: String -> Slipbox -> Html Msg
noteTabView search slipbox = 
  Element.layout [Element.width Element.fill]
    <| Element.column [Element.width Element.fill, Element.height Element.fill]
      [ toolbar search
      , notesView <| Slipbox.getNotes (toMaybeSearch search) slipbox
      ]

notesView: (List Note.Note) -> Element Msg
notesView notes = 
  Element.column 
    [Element.width Element.fill, Element.height <| Element.px 500, Element.scrollbarY] 
    <| List.map toNoteDetail notes

toNoteDetail: Note.Note -> Element Msg
toNoteDetail note = 
  Element.el 
    [ Element.paddingXY 8 0, Element.spacing 8
    , Element.Border.solid, Element.Border.color gray
    , Element.Border.width 4 
    ] 
    Element.Input.button [] 
      {onPress = Nothing, label = Element.column [] 
        [ Element.paragraph [] [ Element.text <| Note.getContent note]
        , Element.text <| "Source: " ++ (Note.getSource note)
        ]
      }
    
  
viewFilterOpen: Html Msg
viewFilterOpen = Html.text "todo"

-- COLORS
gray = Element.rgb255 238 238 238
thistle = Element.rgb255 216 191 216
indianred = Element.rgb255 205 92 92