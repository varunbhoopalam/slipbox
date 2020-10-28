module Page.Sources exposing (Model, Msg, init, subscriptions, update, view)
import Time as Time
import Element as ElmUI


-- MODEL
type Model = Model PageData
type alias PageData = 
  { device: DeviceWrapper
  , state: State
  , timezone: Time.Zone
  }

-- DEVICEWRAPPER
-- exposing (DeviceWrapper(..), init, updateDevice, toggleSort)
type DeviceWrapper =
  Desktop |
  Mobile SortToggled

type alias SortToggled = Bool

init: ElmUI.Device -> DeviceWrapper

updateDevice: ElmUI.Device -> DeviceWrapper -> DeviceWrapper

toggleSort: DeviceWrapper -> DeviceWrapper

-- STATE
type State =
  Loading |
  Failed |
  View Data

type alias Data =
  { sources: Sources
  , sort: Sort
  , search: Maybe String
  }

-- SOURCES
-- exposing (Sources, init, get, Sort, Field(..), Direction(..))

type Sources = Sources (List Source)
type alias Source = {title: String, author: String, created: Int, updated: Int, id: Int}

type alias Sort = {field: Field, direction: Direction}
type Field = Title | Author | Created | Updated
type Direction = Ascending | Descending

init: (List Source) -> Sources
init sources = Sources sources

-- TODO
get: (Maybe String) -> Sort -> Sources -> (List Source)
get maybeSearchString sort sources = []

-- TODO
-- INIT

-- TODO
-- SUBSCRIPTIONS

-- TODO
-- UPDATE

-- TODO
-- VIEW