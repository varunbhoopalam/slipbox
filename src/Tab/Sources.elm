module Tab.Sources exposing (..)
import Time as Time
import Element as exposing (Element)
import Element.Input

-- MAIN
main =
  Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }

-- INIT
init: Model
init = {}

-- MODEL
type alias Model = 
  { slipbox: Slipbox.Slipbox
  , sort: Sort
  , search: Maybe String
  , timezone: Time.Zone
  }

-- SORT

type Sort = 
  Title Direction 
  | Author Direction 
  | Created Direction 
  | Updated Direction
type Direction = Ascending | Descending

chooseSorter: Sort -> (Source.Source -> Source.Source -> Order)
chooseSorter sort =
  case sort of
    Title direction ->
      case direction of
        Ascending -> Source.sortTitleAsc
        Descending -> Source.sortTitleDesc
    Author direction -> 
      case direction of
        Ascending -> Source.sortAuthorAsc
        Descending -> Source.sortAuthorDesc
    Created direction -> 
      case direction of
        Ascending -> Source.sortCreatedAsc
        Descending -> Source.sortCreatedDesc
    Updated direction ->
      case direction of
        Ascending -> Source.sortUpdatedAsc
        Descending -> Source.sortUpdatedDesc

getTitleLabel: Sort -> Element Msg
getTitleLabel sort =
  case sort of 
    Title direction ->
      case direction of 
        Ascending -> Element.text "Title ^"
        Descending -> Element.text "Title v"
    _ -> Element.text "Title"

getAuthorLabel: Sort -> Element Msg
getAuthorLabel sort =
  case sort of 
    Author direction ->
      case direction of 
        Ascending -> Element.text "Author ^"
        Descending -> Element.text "Author v"
    _ -> Element.text "Author"

getCreatedLabel: Sort -> Element Msg
getCreatedLabel sort =
  case sort of 
    Created direction ->
      case direction of 
        Ascending -> Element.text "Created ^"
        Descending -> Element.text "Created v"
    _ -> Element.text "Created"

getUpdatedLabel: Sort -> Element Msg
getUpdatedLabel sort =
  case sort of 
    Updated direction ->
      case direction of 
        Ascending -> Element.text "Updated ^"
        Descending -> Element.text "Updated v"
    _ -> Element.text "Updated"

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
  Element.layout [Element.width Element.fill] <| view_ model

view_: Model -> Element Msg
view_ model = Element.column 
  [ Element.width Element.fill, Element.height Element.fill]
  [ toolbar model.search
  , sourceTable model.sort model.timezone <| getAndSortSources model.search model.slipbox model.sort
  ]

getAndSortSources: Maybe String -> Slipbox.Slipbox -> Sort -> (List Source.Source)
getAndSortSources maybeSearch slipbox sort =
  List.sortWith (chooseSorter sort) <| Slipbox.getSources maybeSearch slipbox

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
  { onChange = (\s -> Msg)
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

-- SOURCES
type alias SourceRow =
  { id: Int
  , title: String
  , author: String
  , created: Int
  , updated: Int
  }

toSourceRow: Source.Source -> SourceRow
toSourceRow source =
  SourceRow 
    (Source.getId source)
    (Source.getTitle source)
    (Source.getAuthor source)
    (Source.getCreated source)
    (Source.getUpdated source)

sourcesTable: Sort -> Time.Zone -> (List Source.Source) -> Element Msg
sourcesTable sort timezone sources =
  Element.table []
    { data = List.map toSourceRow sources
    , columns = 
      [ { header = Element.Input.button [] 
          {onPress = Nothing, label = getTitleLabel sort }
        , width = Element.fill
        , view = \row -> Element.Input.button [] 
          {onPress = Nothing, label = Element.text row.author }
        }
      , { header = Element.Input.button [] 
          {onPress = Nothing, label = getAuthorLabel sort }
        , width = Element.fill
        , view = \row -> Element.Input.button [] 
          {onPress = Nothing, label = Element.text row.title }
        }
      , { header = Element.Input.button [] 
          {onPress = Nothing, label = getCreatedLabel sort }
        , width = Element.fill
        , view = \row -> Element.Input.button [] 
          {onPress = Nothing, label = Element.text <| timestamp timezone row.created }
        }
      , { header = Element.Input.button [] 
          {onPress = Nothing, label = getUpdatedLabel sort }
        , width = Element.fill
        , view = \row -> Element.Input.button [] 
          {onPress = Nothing, label = Element.text <| timestamp timezone row.updated }
        }
      ]
    }

-- COLORS
thistle = Element.rgb255 216 191 216
