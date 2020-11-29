module Tab.Explore exposing (..)

import Element exposing (Element)
import Element.Background
import Svg exposing (Svg)
import Html exposing (Html)
import Svg.Attributes
import Svg.Events
import Input

-- MAIN
main =
  Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }

-- INIT
init: Model
init = {}

-- MODEL
type alias Model = 
  { slipbox: Slipbox
  , search: Input.Input
  , viewport: Viewport
  }

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
  Element.layout [Element.width Element.fill] <| exploreTabView model

exploreTabView: Model -> Element Msg
exploreTabView model = Element.column 
  [ Element.width Element.fill, Element.height Element.fill]
  [ toolbar
  , graph <| Slipbox.getNotesAndLinks model.search model.slipbox
  ]

-- TOOLBAR

toolbar: Maybe String -> Element Msg
toolbar searchString = Element.el 
  [Element.width Element.fill, Element.height <| Element.px 50]
  <| Element.row [Element.width Element.fill, Element.paddingXY 8 0, Element.spacing 8] 
    [ search searchString
    , add
    ]

search: Maybe String -> Element Msg
search searchString = Element.Input.text
  [Element.width Element.fill] 
  { onChange = (\s -> UpdateInput s)
  , text = searchString
  , placeholder = Nothing
  , label = Element.Input.labelLeft [] <| Element.text "search"
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

-- GRAPH
graph: ((List Note.Note, List Link.Link)) -> Viewport -> Element Msg
graph notesAndLinks viewport =
  Element.el [Element.height Element.fill, Element.width Element.fill] 
    <| Element.html <| graph_ notesAndLinks viewport

graph_: ((List Note.Note, List Link.Link)) -> Viewport -> Html Msg
graph_ (notes, links) viewport = 
  let
    graphNotes = List.map toGraphNote notes
    graphLinks = List.map toGraphLink links  
  in
    Svg.svg 
      [ Svg.Attributes.width <| Viewport.getWidth viewport
      , Svg.Attributes.height <| Viewport.getHeight viewport
      , Svg.Attributes.viewBox <| Viewport.getViewbox viewport
      ]

toGraphNote: Note.Note -> Svg Msg
toGraphNote note =
  let
    variant = Note.getVariant note
  in
    case Note.getGraphState note of
      Note.Expanded width height -> 
        Svg.g [Svg.Attributes.transform <| Note.getTransform note]
        [ Svg.rect
            [ Svg.Attributes.width width
            , Svg.Attributes.height height
            ]
        , Svg.foreignObject []
          <| Element.layout [Element.width Element.fill, Element.height Element.fill] 
            <| Element.column [Element.width Element.fill, Element.height Element.fill]
              [ Element.Input.button [Element.alignRight]
                { onPress = Nothing
                , label = Element.text "X"
                }
              , Element.Input.button []
                { onPress = Nothing
                , label = Element.paragraph 
                  [ Element.scrollbarY ] 
                  [ Element.text <| Note.getContent note ] 
                }
              ]
        ]
      Note.Compressed radius ->
        Svg.circle 
          [ Svg.Attributes.cx <| Note.getX note
          , Svg.Attributes.cy <| Note.getY note
          , Svg.Attributes.r <| String.fromInt radius
          , Svg.Attributes.fill <| noteColor variant
          , Svg.Attributes.cursor "Pointer"
          , Svg.Events.onClick Nothing
          ]
          []

toGraphLink: Link.Link -> Svg Msg
toGraphLink link =
  Svg.line 
    [ Svg.Attributes.x1 <| Link.getSourceX link
    , Svg.Attributes.y1 <| Link.getSourceY link
    , Svg.Attribtes.x2 <| Link.getTargetX link
    , Svg.Attributes.y2 <| Link.getTargetY link
    , Svg.Attributes.stroke "rgb(0,0,0)"
    , Svg.Attributes.strokeWidth "2"
    ] 
    []

-- VIEW UTILITIES

noteColor: Note.Variant -> String
noteColor variant =
  case variant of
    Note.Index -> "rgba(250, 190, 88, 1)"
    Note.Regular -> "rgba(137, 196, 244, 1)"