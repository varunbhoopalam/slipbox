module Export exposing
  ( Export
  , init
  , View(..)
  , view
  , continue
  , updateInput
  , toggleDiscussion
  , remove
  , encode
  )

import Note
import Slipbox
import Source
import SourceTitle

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

toggle : Discussion -> Discussion
toggle discussion =
  case discussion of
    Selected note -> Unselected note
    Unselected note -> Selected note

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
  | SelectDiscussionsView Title Filter SelectedDiscussions UnselectedFilteredDiscussions CanContinue
  | ConfigureContentView Title Notes
  | PromptAnotherExportView

type alias SelectedDiscussions = List Note.Note
type alias UnselectedFilteredDiscussions = List Note.Note

type alias CanContinue = Bool

view : Export -> View
view export =
  case export of
    ErrorStateNoDiscussions -> ErrorStateNoDiscussionsView
    InputProjectTitle projectTitle -> InputProjectTitleView projectTitle <| not <| String.isEmpty projectTitle

    SelectDiscussions projectTitle filter discussions ->
      SelectDiscussionsView
        projectTitle
        filter
        ( List.map getNote <| List.filter isSelected discussions )
        ( List.map getNote
          <| List.filter (\d -> Note.contains filter ( getNote d ) )
            <| List.filter (\d -> not <| isSelected d ) discussions
        )
        ( atLeastOneDiscussionWasChosen discussions )

    ConfigureContent projectTitle notes -> ConfigureContentView projectTitle notes
    PromptAnotherExport -> PromptAnotherExportView

continue : Slipbox.Slipbox -> Export -> Export
continue slipbox export =
  case export of
    InputProjectTitle title ->
      if String.isEmpty title then
        export
      else
        SelectDiscussions
          title
          ""
          ( List.map toUnselectedDiscussion <| Slipbox.getDiscussions Nothing slipbox )

    SelectDiscussions title _ discussions ->
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

    ConfigureContent _ _ -> PromptAnotherExport
    PromptAnotherExport -> init slipbox
    _ -> export



updateInput : String -> Export -> Export
updateInput input export =
  case export of
    InputProjectTitle _ -> InputProjectTitle input
    SelectDiscussions title _ discussions -> SelectDiscussions title input discussions
    _ -> export

toggleDiscussion : Note.Note -> Export -> Export
toggleDiscussion note export =
  case export of
    SelectDiscussions title filter discussions ->
      let
        foo = List.map
          ( \d ->
            if Note.is note <| getNote d then
              toggle d
            else
              d
          )
          discussions
      in
      SelectDiscussions
        title
        filter
        foo

    _ -> export

remove : Note.Note -> Export -> Export
remove note export =
  case export of
    ConfigureContent title notes ->
      ConfigureContent
        title
        ( List.filter ( \n -> not <| Note.is note n ) notes )
    _ -> export

encode : Slipbox.Slipbox -> Export -> Maybe ( String, String )
encode slipbox export =
  case export of
    ConfigureContent title notes ->
      let
        relevantSources =
          List.filter
            ( \source ->
              List.any
                ( \note ->
                  case SourceTitle.getTitle <|Note.getSource note of
                    Just sourceTitle -> sourceTitle == Source.getTitle source
                    Nothing -> False
                )
                notes
            )
            <| Slipbox.getSources Nothing slipbox
        fileTitle = ( String.replace " " "_" title ) ++ ".txt"
      in
      Just ( fileTitle, String.concat <| List.intersperse "\n\n" <|
        List.concat
          [ [ title ]
          , [ "Notes" ]
          , List.map ( toEncodedNote relevantSources ) notes
          , [ "Sources" ]
          , List.map toEncodedSource relevantSources
          ]
        )
    _ -> Nothing

-- HELPER
atLeastOneDiscussionWasChosen : ( List Discussion ) -> Bool
atLeastOneDiscussionWasChosen discussions = not <| List.isEmpty <| List.filter isSelected discussions

toEncodedSource : Source.Source -> String
toEncodedSource source =
  String.concat <|
    List.intersperse
      "\n"
      [ "ID: " ++ ( String.fromInt <| Source.getId source )
      , "Title: " ++ Source.getTitle source
      , "Author: " ++ Source.getAuthor source
      , "Content: " ++ Source.getContent source
      ]

toEncodedNote : List Source.Source -> Note.Note -> String
toEncodedNote sources note =
  let
    maybeSource = List.head <|
      List.filter
        ( \source ->
          case SourceTitle.getTitle <| Note.getSource note of
            Just sourceTitle -> Source.getTitle source == sourceTitle
            Nothing -> False
        )
        sources
    sourceString =
      if Note.getVariant note == Note.Discussion then
        ""
      else
        case maybeSource of
          Just source -> "Source ID: " ++ ( String.fromInt <| Source.getId source )
          Nothing -> "No Source"
  in
  String.concat <|
    List.intersperse
      "\n"
      [ Note.getContent note
      , sourceString
      ]