module Slipbox exposing (Slipbox, Note, LinkRecord, initialize, 
  selectNote, dismissNote, stopHoverNote, searchSlipbox, SearchResult,
  getGraphElements, GraphNote, GraphLink, getSelectedNotes, DescriptionNote
  , DescriptionLink, NoteId, hoverNote)

import Force exposing (entity, computeSimulation, manyBody, simulation, links, center)
import Set

--Types
type Slipbox = Slipbox (List PositionNote) (List Link)

type alias LinkRecord =
  { source: Int
  , target: Int
  , id: Int
  }
type alias Note = 
  { id : Int
  , content : String
  , source : String
  , noteType: String
  }

type alias SearchResult = 
  { id : NoteId
  , x : Float
  , y : Float
  , color : String
  , content : String
  }

type alias GraphNote =
  { id: NoteId
  , x : Float
  , y : Float
  , color : String 
  , shouldAnimate : Bool
  }

type alias GraphLink = 
  { sourceId: NoteId
  , sourceX: Float
  , sourceY: Float
  , targetId: NoteId
  , targetX: Float
  , targetY: Float
  , id: LinkId
  }

type alias Link = 
  { source: NoteId
  , target: NoteId
  , id: LinkId
  }

type alias DescriptionNote =
  { id : NoteId
  , x : Float
  , y : Float 
  , content : String
  , source : String 
  , links : (List DescriptionLink)
  }

type alias DescriptionLink =
  { target : NoteId
  , targetX : Float
  , targetY : Float
  }

-- Methods

initialize: (List Note) -> (List LinkRecord) -> Slipbox
initialize notes links =
  Slipbox (initializeNotes notes links) (initializeLinks links)

initializeLinks: (List LinkRecord) -> (List Link)
initializeLinks l =
  List.map (\lr -> Link lr.source lr.target lr.id) l

initSimulation: (List PositionNote) -> (List LinkRecord) -> (List PositionNote)
initSimulation notes linkRecords =
  let
    state = 
      simulation 
        [ manyBody (List.map (\n -> n.id) notes)
        , links (List.map (\l -> (l.source, l.target)) linkRecords)
        , center 0 0
        ]
  in
    computeSimulation state notes

initializeNotes: (List Note) -> (List LinkRecord) -> (List PositionNote)
initializeNotes notes links =
  initSimulation (List.indexedMap initializePosition notes) links

initializePosition: Int -> Note -> PositionNote
initializePosition index note =
  let
    positions = entity index 1
  in
    PositionNote note.id note.content note.source (noteType note.noteType) positions.x positions.y positions.vx positions.vy NotSelected NotHover

noteType: String -> NoteType
noteType s =
  if s == "index" then
    Index
  else
    Regular

noteColor: NoteType -> String
noteColor notetype =
  case notetype of
    Regular -> "rgba(137, 196, 244, 1)"
    Index -> "rgba(250, 190, 88, 1)"

shouldAnimateNoteCircle: Hover -> Bool
shouldAnimateNoteCircle hover =
  case hover of
     Hover -> True
     NotHover -> False

selectNote: NoteId -> Slipbox -> Slipbox
selectNote noteId slipbox =
  case slipbox of 
    Slipbox notes links -> Slipbox (List.map (\note -> selectNoteById noteId note) notes) links

selectNoteById: NoteId -> PositionNote -> PositionNote
selectNoteById noteId note =
  if  note.id == noteId then
    {note | selected = Selected}
  else
    note

dismissNote: NoteId -> Slipbox -> Slipbox
dismissNote noteId slipbox =
  case slipbox of 
    Slipbox notes links -> Slipbox (List.map (\note -> unselectNoteById noteId note) notes) links

unselectNoteById: NoteId -> PositionNote -> PositionNote
unselectNoteById noteId note =
  if  note.id == noteId then
    {note | selected = NotSelected}
  else
    note

hoverNote: NoteId -> Slipbox -> Slipbox
hoverNote noteId slipbox =
  case slipbox of 
    Slipbox notes links -> Slipbox (List.map (\note -> hoverNoteById noteId note) notes) links

hoverNoteById: NoteId -> PositionNote -> PositionNote
hoverNoteById noteId note =
  if  note.id == noteId then
    {note | hover = Hover}
  else
    {note | hover = NotHover}

stopHoverNote: Slipbox -> Slipbox
stopHoverNote slipbox =
  case slipbox of 
    Slipbox notes links -> Slipbox (List.map (\note -> {note | hover = NotHover}) notes) links

searchSlipbox: String -> Slipbox -> (List SearchResult)
searchSlipbox searchString slipbox =
  case slipbox of
     Slipbox notes links -> 
      notes
        |> List.filter (\note -> String.contains searchString note.content)
        |> List.map toSearchResult

toSearchResult: PositionNote -> SearchResult
toSearchResult pn =
  SearchResult pn.id pn.x pn.y (noteColor pn.noteType) pn.content

getGraphElements: Slipbox -> ((List GraphNote), (List GraphLink))
getGraphElements slipbox =
  case slipbox of
    Slipbox notes links -> 
      ( List.map toGraphNote notes
      , List.filterMap (\link -> (toGraphLink link notes)) links)

toGraphNote: PositionNote -> GraphNote
toGraphNote pn =
  GraphNote pn.id pn.x pn.y (noteColor pn.noteType) (shouldAnimateNoteCircle pn.hover)

toGraphLink: Link -> (List PositionNote) -> (Maybe GraphLink)
toGraphLink link notes =
  let
      source = findNote link.source notes
      target = findNote link.target notes
  in
    Maybe.map3 graphLinkBuilder source target (Just link.id)
    
graphLinkBuilder: PositionNote -> PositionNote -> LinkId -> GraphLink
graphLinkBuilder source target id =
  GraphLink source.id source.x source.y target.id target.x target.y id

getSelectedNotes: Slipbox -> (List DescriptionNote)
getSelectedNotes slipbox =
  case slipbox of 
    Slipbox notes links -> 
      notes
       |> List.filter (\note -> note.selected == Selected )
       |> List.map (\note -> (toDescriptionNote notes note links))

toDescriptionNote: (List PositionNote) -> PositionNote -> (List Link) -> DescriptionNote
toDescriptionNote notes note links =
  DescriptionNote note.id note.x note.y note.content note.source (getDescriptionLinks notes note.id links)

getDescriptionLinks: (List PositionNote) -> NoteId -> (List Link) -> (List DescriptionLink)
getDescriptionLinks notes noteId links =
  List.map toDescriptionLink (uniqueLinkParts (getLinkParts notes noteId links))

toDescriptionLink: (Int, Float, Float) -> DescriptionLink
toDescriptionLink (noteId, x, y) =
  DescriptionLink noteId x y

getLinkParts: (List PositionNote) -> NoteId -> (List Link) -> (List (Int, Float, Float))
getLinkParts notes noteId links =
  List.filterMap (\link -> maybeGetDescriptionLinkParts notes noteId link) links

uniqueLinkParts: (List (Int, Float, Float)) -> (List (Int, Float, Float))
uniqueLinkParts linkParts = Set.toList (Set.fromList linkParts)

maybeGetDescriptionLinkParts: (List PositionNote) -> NoteId -> Link -> (Maybe (Int, Float, Float))
maybeGetDescriptionLinkParts notes noteId link =
  if link.source == noteId then 
    Maybe.map toLinkParts (findNote link.target notes)
  else if link.target == noteId then 
    Maybe.map toLinkParts (findNote link.source notes)
  else 
    Nothing

toLinkParts: PositionNote -> (Int, Float, Float)
toLinkParts note = (note.id, note.x, note.y)

findNote: NoteId -> (List PositionNote) -> (Maybe PositionNote)
findNote noteId notes =
  List.head (List.filter (\note -> note.id == noteId) notes)

type alias PositionNote =
  { id : NoteId
  , content : Content
  , source : Source
  , noteType: NoteType
  , x : Float
  , y : Float
  , vx : Float
  , vy : Float
  , selected : Selected
  , hover : Hover
  }

type Selected = 
  Selected |
  NotSelected

type Hover =
  Hover |
  NotHover

type alias NoteId = Int
type alias Content = String
type NoteType = Regular | Index
type alias Source = String

type alias LinkId = Int