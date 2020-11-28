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
  , filter: Filter
  }

-- INIT
init: () -> (Model, Cmd Msg)
init _ = (Model, Cmd.none)

con = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum"
src = "https://www.lipsum.com/"

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
view: Model -> Html Msg
view model =
  case model of
     Regular -> viewNoteTab model
     FilterOpen -> viewFilterOpen model

viewNoteTab: Model -> Html Msg
viewNoteTab model = 
  Element.layout [Element.width Element.fill]
    <| Element.column [Element.width Element.fill, Element.height Element.fill]
      [ toolbar (getSearch model)
      , notesView (getNotes model)
      ]

toolbar: String -> Element Msg
toolbar searchString = Element.el 
  [Element.width Element.fill, Element.height <| Element.px 50]
  <| Element.row [Element.width Element.fill, Element.paddingXY 8 0, Element.spacing 8] 
    [ search searchString
    , filter
    , add
    ]

search: String -> Element Msg
search searchString = Element.Input.text
  [Element.width Element.fill] 
  { onChange = (\s -> Msg)
  , text = searchString
  , placeholder = Nothing
  , label = Element.Input.labelLeft [] <| Element.text "search"
  }

filter: Element Msg
filter = Element.Input.button
  [ Element.Background.color gray
  , Element.mouseOver
      [ Element.Background.color thistle ]
  , Element.width Element.fill
  ]
  { onPress = Nothing
  , label = Element.text "Filter"
  }

add: Element Msg
add = Element.Input.button
  [ Element.Background.color indianred
  , Element.mouseOver
      [ Element.Background.color thistle ]
  , Element.width Element.fill
  ]
  { onPress = Nothing
  , label = Element.text "Add +"
  }

notesView: (List Note.Note) -> Element Msg
notesView notes = 
  Element.el [Element.width Element.fill, Element.height <| Element.px 500] noteDetailView notes

noteDetailView: Element Msg
noteDetailView = Element.column
  [Element.width Element.fill, Element.height Element.fill, Element.scrollbarY] 
  [ noteDetail 1 con src Regular
  , noteDetail 2 con src Regular
  , noteDetail 3 con src Regular
  ]

noteDetail: Note.Note -> Element Msg
noteDetail note = 
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