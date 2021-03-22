module Export exposing
  ( Export
  , init
  , View(..)
  , view
  )

import Note
import Slipbox

type Export
  = ErrorStateNoDiscussions
  | InputProjectTitle ProjectTitle
  | SelectDiscussions ProjectTitle Filter Discussions
  | ConfigureContent ProjectTitle Notes
  | PromptAnotherExport

type Discussion
  = Selected Note.Note
  | Unselected Note.Note

getNote : Discussion -> Note.Note
getNote discussion =
  case discussion of
    Selected note -> note
    Unselected note -> note

isSelected : Discussion -> Bool
isSelected discussion =
  case discussion of
    Selected _ -> True
    Unselected _ -> False

type alias Discussions = List Discussion
type alias ChosenDiscussions = List Note.Note

type alias ProjectTitle = String
type alias Filter = String
type alias Notes = List Note.Note

init : Slipbox.Slipbox -> Export
init slipbox =
  let discussions = Slipbox.getDiscussions Nothing slipbox
  in
  if List.isEmpty discussions then
    ErrorStateNoDiscussions
  else
    InputProjectTitle ""

type View
  = ErrorStateNoDiscussionsView
  | InputProjectTitleView ProjectTitle CanContinue
  | SelectDiscussionsView ProjectTitle Filter ( List DiscussionView ) CanContinue
  | ConfigureContentView ProjectTitle Notes
  | PromptAnotherExportView

type alias DiscussionView =
  { selected : Bool
  , note : Note.Note
  }

toDiscussionView : Discussion -> DiscussionView
toDiscussionView discussion =
  let note = getNote discussion
  in
  { selected = isSelected discussion
  , note = note
  }

type alias CanContinue = Bool

view : Export -> View
view export =
  case export of
    ErrorStateNoDiscussions -> ErrorStateNoDiscussionsView
    InputProjectTitle projectTitle -> InputProjectTitleView projectTitle <| String.isEmpty projectTitle

    SelectDiscussions projectTitle filter discussions ->
      let atLeastOneDiscussionWasChosen = not <| List.isEmpty <| List.filter isSelected discussions
      in
      SelectDiscussionsView
        projectTitle
        filter
        ( List.map toDiscussionView discussions )
        atLeastOneDiscussionWasChosen

    ConfigureContent projectTitle notes -> ConfigureContentView projectTitle notes
    PromptAnotherExport -> PromptAnotherExportView
