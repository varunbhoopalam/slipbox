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



-- COLORS
thistle = Element.rgb255 216 191 216
