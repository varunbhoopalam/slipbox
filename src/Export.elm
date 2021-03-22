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
  | InputProjectTitle Title
  | SelectDiscussions Title Filter Discussions
  | ConfigureContent Title Notes
  | PromptAnotherExport

type Discussion
  = Selected Note.Note
  | Unselected Note.Note

toUnselectedDiscussion : Note.Note -> Discussion
toUnselectedDiscussion note =
  Unselected note

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

type alias Title = String
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
  | InputProjectTitleView Title CanContinue
  | SelectDiscussionsView Title Filter ( List DiscussionView ) CanContinue
  | ConfigureContentView Title Notes
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
      let
        filterDiscussion = (\d -> Note.contains filter ( getNote d ) )
      in
      SelectDiscussionsView
        projectTitle
        filter
        ( List.map toDiscussionView <| List.filter filterDiscussion discussions )
        ( atLeastOneDiscussionWasChosen discussions )

    ConfigureContent projectTitle notes -> ConfigureContentView projectTitle notes
    PromptAnotherExport -> PromptAnotherExportView

finishInputTitle : Slipbox.Slipbox -> Export -> Export
finishInputTitle slipbox export =
  case export of
    InputProjectTitle title ->
      if String.isEmpty title then
        export
      else
        SelectDiscussions
          title
          ""
          ( List.map toUnselectedDiscussion <| Slipbox.getDiscussions Nothing slipbox )
    _ -> export

finishSelectingDiscussions : Slipbox.Slipbox -> Export -> Export
finishSelectingDiscussions slipbox export =
  case export of
    SelectDiscussions title filter discussions ->
      if ( not <| atLeastOneDiscussionWasChosen discussions ) then
        export
      else
        let
          selectedDiscussions = List.map getNote <| List.filter isSelected discussions
          notes =
            List.concatMap
              ( \n ->
                Tuple.first <| Slipbox.getDiscussionTreeWithCollapsedDiscussions n slipbox
              )
              selectedDiscussions
        in
        ConfigureContent
          title
          notes

    _ -> export

-- HELPER
atLeastOneDiscussionWasChosen : ( List Discussion ) -> Bool
atLeastOneDiscussionWasChosen discussions = not <| List.isEmpty <| List.filter isSelected discussions