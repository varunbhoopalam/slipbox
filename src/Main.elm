module Main exposing (..)

import Browser as Browser
import Browser.Navigation as Nav
import SourceSummary as SourceSummary
import Html as Html
import Element as ElmUI

-- MAIN
main =
  Browser.application
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    , onUrlRequest = LinkClicked
    , onUrlChange = UrlChanged
    }

-- MODEL

type alias Model =
  Setup |
  Parsing |
  FailureToParse |
  Session Content

-- CONTENT
type alias Content = 
  { tab: Tab
  , slipbox: Slipbox
  , timezone: Timezone
  , device: Device
  }

-- TAB
type Tab = 
  Notes Filter Search Viewport NotesInView |
  Sources Search Sort |
  History |
  Setup

-- INIT

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ _ _ =
  ( Setup, Cmd.none)

-- UPDATE
type Msg
  = SourceMsg SourceSummary.Msg
  | LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url

update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  case message of
    SourceMsg msg ->
      case model.page of
        Source source -> SourceSummary.update msg source |> sourceStep model
        _ -> ( model, Cmd.none) 
    -- TODO
    LinkClicked _ -> (model, Cmd.none)
    UrlChanged _ -> (model, Cmd.none)

-- SUBSCRIPTIONS
subscriptions: Model -> Sub Msg
subscriptions model =
  case model.page of 
    NotFound -> Sub.none
    Source source -> Sub.map SourceMsg (SourceSummary.subscriptions source)

-- Steps
sourceStep: Model -> (SourceSummary.Model, Cmd SourceSummary.Msg) -> (Model, Cmd Msg)
sourceStep model (summaryModel, sourceMsg) =
  ({model | page = Source summaryModel}, Cmd.map SourceMsg sourceMsg)

-- VIEW
-- Source source -> {title = "TODO", body = [Html.map SourceMsg <| SourceSummary.view source]}

view: Model -> Browser.Document Msg
view model =
  case model of
    Setup -> {title = "TODO", body = []}
    Parsing -> {title = "TODO", body = []}
    FailureToParse -> {title = "TODO", body = []}
    Session content -> {title = "MySlipbox", body = [ sessionView content ]}

sessionView: Content -> Html Msg
sessionView content =
  Element.layout 
    [] 
    <| Element.column 
      []
      [ tabView content
      , itemsView content
      ]

-- TAB
tabView: Content -> Element Msg
tabView content = []

-- ITEMS
itemsView: Content -> Element Msg
itemsView content =
  let
      items = List.map (toItemView slipbox) <| Slipbox.getItems content.slipbox
  in
    Element.column 
      []
-- How do I add an item between all items in a list?
-- Is list the correct data structure here?

toItemView: Slipbox.Slipbox -> Item.Item -> Element Msg
toItemView slipbox item =
  case item of
     Item.Note listId note -> itemNoteView listId note slipbox
     Item.NewNote listId note -> newNoteView listId note slipbox
     Item.ConfirmDismissNewNote listId note -> confirmDismissNewNote listId note slipbox
     Item.EditingNote listId originalNote noteWithEdits -> editingNoteView listId originalNote noteWithEdits slipbox
     Item.ConfirmDeleteNote listId note -> confirmDeleteNoteView listId note slipbox
     -- Invariant for AddingLinkToNote and LinkChosen: If Note is deleted from slipbox need to make sure these states are still valid
     -- If they are not valid either remove note from item list or move it back to Note state depending on what happened
     Item.AddingLinkToNote listId search note -> addingLinkToNoteView listId search note slipbox
     Item.LinkChosen listId search note noteToLink -> linkChosenView listId search note noteToLink slipbox
     Item.Source lsitId source ->
     Item.NewSource ->
     Item.EditingSource -> 
     Item.ConfirmDeleteSource ->

itemNoteView: Int -> Note.Note -> Slipbox -> Element Msg
itemNoteView listId note slipbox =
  Element.column
    []
    [ Element.row 
      []
      [ idHeader Note.getId note
      , editButton listId
      , deleteButton listId
      , dismissButton listId
      ]
    , variantView <| Note.getVariant note
    , contentView <| Note.getContent note
    , sourceView <| Note.getSource note
    , Element.row
      []
      [ linkedNotesHeader 
      , addLinkButton listId note slipbox
      ]
    , Element.column
      []
      <| List.map (toLinkedNoteView (Note.getId note)) <| Slipbox.getLinkedNotes note slipbox
    ]

addLinkButton: Int -> Note.Note -> Slipbox.Slipbox -> Element Msg
addLinkButton listId note slipbox =
  if Slipbox.noteCanLinkToOtherNotes note slipbox then
    addLinkButton_ listId
  else 
    cannotAddLink 

cannotAddLink: Element Msg
cannotAddLink = Element.text "No notes to make a valid link to."

toLinkedNoteView: Int -> Note.Note -> Element Msg
toLinkedNoteView noteId note =
  Element.column
    []
    [ idHeader <| Note.getId note
    , variantView <| Note.getVariant note
    , contentView <| Note.getContent note
    , sourceView <| Note.getSouce note
    , removeLinkButton noteId <| Note.getId note
    ]

newNoteView: Int -> Item.NewNoteContent -> Element Msg
newNoteView listId note =
  Element.column
    []
    [ dismissButton listId
    , contentEdit listId <| Item.getContent note
    , sourceEdit listId <| Item.getSource note <| Slipbox.getExistingSourceTitles slipbox
    , chooseVariant listId <| Item.getVariant note
    , chooseSaveButton listId <| Item.noteIsValidToSave note -- Will give clickable save button if note is valid to save
    ]

confirmDismissNewNoteView: Int -> Item.NewNoteContent -> Element Msg
confirmDismissNewNoteView listId note =
  Element.column
    []
    [ Element.row 
      []
      [ confirmDismissNewNoteButton listId
      , cancelDismissNewNoteButton listId
      ] 
    , contentView <| Item.getContent note
    , sourceView <| Item.getSource note
    , chooseVariant <| Item.getVariant note
    , saveButtonNotClickable
    ]

toLinkedNoteViewNoButtons: Int -> Note.Note -> Element Msg
toLinkedNoteViewNoButtons noteId note =
  Element.column
    []
    [ idHeader <| Note.getId note
    , variantView <| Note.getVariant note
    , contentView <| Note.getContent note
    , sourceView <| Note.getSource note
    ]

editingNoteView: Int -> Note.Note -> Note.Note -> Slipbox.Slipbox -> Element Msg
editingNoteView listId _ noteWithEdits slipbox =
  Element.column
    []
    [ Element.row 
      []
      [ idHeader <| Note.getId noteWithEdits
      , saveButton listId
      , cancelButton listId
      ]
    , contentEdit listId <| Note.getContent noteWithEdits
    , sourceEdit listId <| Note.getSource noteWithEdits <| Slipbox.getExistingSourceTitles slipbox
    , chooseVariant listId <| Note.getVariant noteWithEdits
    , Element.row
      []
      [ linkedNotesHeader ]
    , Element.column
      []
      <| List.map (toLinkedNoteViewNoButtons (Note.getId noteWithEdits)) <| Slipbox.getLinkedNotes noteWithEdits slipbox
    ]

confirmDeleteNoteView: Int -> Note.Note -> Slipbox.Slipbox -> Element Msg
confirmDeleteNoteView listId note slipbox =
  Element.column
    []
    [ Element.row 
      []
      [ idHeader <| Note.getId note
      , confirmDeleteButton listId
      , cancelButton listId
      ]
    , contentView <|Note.getContent note
    , sourceView <|Note.getSource note
    , variantView <|Note.getVariant note
    , Element.row
      []
      [ linkedNotesHeader ]
    , Element.column
      []
      <| List.map (toLinkedNoteViewNoButtons (Note.getId)) <| Slipbox.getLinkedNotes note slipbox
    ]

addingLinkToNoteView: Int -> String -> Note.Note -> Slipbox.Slipbox -> Element Msg
addingLinkToNoteView listId search note slipbox =
  Element.column
    []
    [ Element.row
      []
      [ Element.text "Adding Link"
      , cancelButton listId
      ]
    , Element.row
      []
      [ noteRepresentation note
      , Element.text "Select note to add link to from below"
      ]
    , Element.column
      []
      [ searchBar search listId
      , Element.el [Element.scrollbarsY] <| List.map (toNoteDetail listId) <| Slipbox.getNotesThatCanLinkToNote note slipbox
      ]
    ]

toNoteDetail: Int -> Note.Note -> Element Msg
toNoteDetail listId note =
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

linkChosenView: Int -> String -> Note.Note -> Note.Note -> Slipbox.Slipbox -> Element Msg
linkChosenView listId search note noteToLink slipbox =
  Element.column
    []
    [ Element.row
      []
      [ Element.text "Adding Link"
      , cancelButton listId
      , createLinkButton listId
      ]
    , Element.row
      []
      [ noteRepresentation note
      , noteRepresentation noteToLink
      ]
    , Element.column
      []
      [ searchBar search listId
      , Element.el [Element.scrollbarsY] <| List.map (toNoteDetail listId) <| Slipbox.getNotesThatCanLinkToNote note slipbox
      ]
    ]