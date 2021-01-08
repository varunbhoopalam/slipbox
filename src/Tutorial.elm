module Tutorial exposing
  ( Tutorial
  , Step(..)
  , end
  , update
  , UpdateAction(..)
  , getStep
  , skip
  , continue
  , canContinue
  , init
  )

import Slipbox

init : Tutorial
init =
  One_Intro

type Tutorial
  = One_Intro
  | Two_CreateFirstNote FirstNoteContent
  | Three_PromptAddSourceToNote FirstNoteContent
  | Four_SourceInput FirstNoteContent Source
  | Five_ExplainNotes FirstNote
  | Six_NoteInput FirstNote SecondNoteContent Title
  | Seven_SourceInput FirstNote SecondNoteContent Source
  | Eight_AddLinkPrompt FirstNote SecondNoteContent ( Maybe Source )
  | Nine_ExplainLinks FirstNote SecondNote
  | Ten_QuestionPrompt FirstNote SecondNote
  | Eleven_QuestionInput FirstNote SecondNote Question
  | Twelve_ExplainQuestions FirstNote SecondNote ( Maybe Question )
  | Thirteen_PracticeSaving FirstNote SecondNote ( Maybe Question )
  | Fourteen_PracticeUploading FirstNote SecondNote ( Maybe Question )
  | Fifteen_WorkflowSuggestionsAndFinish FirstNote SecondNote ( Maybe Question )

type FirstNote
  = WithSource String Source
  | WithoutSource String

getContent : FirstNote -> String
getContent firstNote =
  case firstNote of
    WithSource string _ -> string
    WithoutSource string -> string

getSourceTitle : FirstNote -> ( Maybe String )
getSourceTitle firstNote =
  case firstNote of
    WithSource _ source -> Just source.title
    WithoutSource _ -> Nothing

type SecondNote
  = WithSourceAndLinked String Source
  | WithoutSourceAndLinked String
  | WithSourceNotLinked String Source
  | WithoutSourceNotLinked String
  | NoSecondNote

type alias Source =
  { title : String
  , author : String
  , content : String
  }

type Step
  = Intro
  | CreateFirstNote FirstNoteContent
  | PromptAddSourceToNote FirstNoteContent
  | SourceInput FirstNoteContent Title Author SourceContent
  | ExplainNotes
  | NoteInput FirstNoteContent ( Maybe Title ) SecondNoteContent Title
  | AddLinkPrompt FirstNoteContent SecondNoteContent
  | ExplainLinks
  | QuestionPrompt FirstNoteContent
  | QuestionInput FirstNoteContent Question
  | ExplainQuestions
  | PracticeSaving JsonFile
  | PracticeUploading
  | WorkflowSuggestionsAndFinish

type alias FirstNoteContent = String
type alias Title = String
type alias Author = String
type alias SourceContent = String
type alias SecondNoteContent = String
type alias Question = String
type alias JsonFile = String

getStep : Tutorial -> Step
getStep tutorial =
  case tutorial of
    One_Intro -> Intro

    Two_CreateFirstNote string -> CreateFirstNote string


    Three_PromptAddSourceToNote string -> PromptAddSourceToNote string


    Four_SourceInput string source -> SourceInput string source.title source.author source.content


    Five_ExplainNotes _ -> ExplainNotes


    Six_NoteInput firstNote content source -> NoteInput ( getContent firstNote ) ( getSourceTitle firstNote ) content source


    Seven_SourceInput _ string source -> SourceInput string source.title source.author source.content


    Eight_AddLinkPrompt firstNote string _ -> AddLinkPrompt ( getContent firstNote ) string


    Nine_ExplainLinks _ _ -> ExplainLinks


    Ten_QuestionPrompt firstNote _ -> QuestionPrompt ( getContent firstNote )


    Eleven_QuestionInput firstNote _ string -> QuestionInput ( getContent firstNote ) string


    Twelve_ExplainQuestions _ _ _ -> ExplainQuestions


    Thirteen_PracticeSaving firstNote secondNote string -> PracticeSaving <| toJsonString firstNote secondNote string


    Fourteen_PracticeUploading _ _ _ -> PracticeUploading


    Fifteen_WorkflowSuggestionsAndFinish firstNote secondNote string -> WorkflowSuggestionsAndFinish



-- TODO
end : Tutorial -> Slipbox.Slipbox
end tutorial =
  Slipbox.new

type UpdateAction
  = Content String
  | Title String
  | Author String

update : UpdateAction -> Tutorial -> Tutorial
update action tutorial =
  case action of
    Content input ->
      case tutorial of
        Two_CreateFirstNote _ -> Two_CreateFirstNote input
        Four_SourceInput firstNote source -> Four_SourceInput firstNote { source | content = input }
        Seven_SourceInput firstNote secondNote source -> Seven_SourceInput firstNote secondNote { source | content = input}
        Six_NoteInput firstNote _ title -> Six_NoteInput firstNote input title
        Eleven_QuestionInput firstNote secondNote _ -> Eleven_QuestionInput firstNote secondNote input
        _ -> tutorial

    Title input ->
      case tutorial of
        Four_SourceInput firstNote source -> Four_SourceInput firstNote { source | title = input }
        Seven_SourceInput firstNote secondNote source -> Seven_SourceInput firstNote secondNote { source | title = input}
        Six_NoteInput firstNote secondNote _ -> Six_NoteInput firstNote secondNote input
        _ -> tutorial


    Author input ->
      case tutorial of
        Four_SourceInput firstNote source -> Four_SourceInput firstNote { source | author = input }
        Seven_SourceInput firstNote secondNote source -> Seven_SourceInput firstNote secondNote { source | author = input}
        _ -> tutorial

skip : Tutorial -> Tutorial
skip tutorial =
  case tutorial of
    Three_PromptAddSourceToNote string -> Five_ExplainNotes <| WithoutSource string


    Four_SourceInput string _ -> Five_ExplainNotes <| WithoutSource string


    Six_NoteInput firstNote _ _ -> Nine_ExplainLinks firstNote NoSecondNote


    Seven_SourceInput firstNote secondNoteContent source -> Eight_AddLinkPrompt firstNote secondNoteContent ( Just source )


    Eight_AddLinkPrompt firstNote secondNoteContent maybeSource ->
      case maybeSource of
        Just source ->
          Nine_ExplainLinks firstNote <| WithSourceNotLinked secondNoteContent source
        Nothing ->
          Nine_ExplainLinks firstNote <| WithoutSourceNotLinked secondNoteContent


    Ten_QuestionPrompt firstNote secondNote -> Twelve_ExplainQuestions firstNote secondNote Nothing


    Eleven_QuestionInput firstNote secondNote _ -> Twelve_ExplainQuestions firstNote secondNote Nothing

    _ -> tutorial

canContinue : Tutorial -> Bool
canContinue tutorial =
  case tutorial of
    Two_CreateFirstNote firstNoteContent -> not <| String.isEmpty firstNoteContent

    Four_SourceInput _ source -> not <| String.isEmpty source.title

    Six_NoteInput firstNote secondNoteContent title -> not <| String.isEmpty secondNoteContent

    Seven_SourceInput firstNote secondNoteContent source -> not <| String.isEmpty source.title

    Eleven_QuestionInput firstNote secondNote question -> not <| String.isEmpty question

    _ -> True


continue : Tutorial -> Tutorial
continue tutorial =
  case tutorial of
    One_Intro -> Two_CreateFirstNote ""

    Two_CreateFirstNote string -> Three_PromptAddSourceToNote string


    Three_PromptAddSourceToNote string -> Four_SourceInput string emptySource


    Four_SourceInput string source -> Five_ExplainNotes <| WithSource string source


    Five_ExplainNotes firstNote -> Six_NoteInput firstNote "" ""


    Six_NoteInput firstNote content title ->
      if titleIsValid title then
        Seven_SourceInput firstNote content <| Source title "" ""
      else
        Eight_AddLinkPrompt firstNote content Nothing


    Seven_SourceInput firstNote secondNoteContent source -> Eight_AddLinkPrompt firstNote secondNoteContent ( Just source )


    Eight_AddLinkPrompt firstNote secondNoteContent maybeSource ->
      case maybeSource of
        Just source ->
          Nine_ExplainLinks firstNote <| WithSourceAndLinked secondNoteContent source
        Nothing ->
          Nine_ExplainLinks firstNote <| WithoutSourceAndLinked secondNoteContent


    Nine_ExplainLinks firstNote secondNote -> Ten_QuestionPrompt firstNote secondNote


    Ten_QuestionPrompt firstNote secondNote -> Eleven_QuestionInput firstNote secondNote ""


    Eleven_QuestionInput firstNote secondNote question -> Twelve_ExplainQuestions firstNote secondNote ( Just question )


    Twelve_ExplainQuestions firstNote secondNote maybeQuestion -> Thirteen_PracticeSaving firstNote secondNote maybeQuestion


    Thirteen_PracticeSaving firstNote secondNote maybeQuestion -> Fourteen_PracticeUploading firstNote secondNote maybeQuestion


    Fourteen_PracticeUploading firstNote secondNote maybeQuestion -> Fifteen_WorkflowSuggestionsAndFinish firstNote secondNote maybeQuestion


    Fifteen_WorkflowSuggestionsAndFinish _ _ _ -> tutorial

-- TODO
toJsonString : FirstNote -> SecondNote -> ( Maybe String ) -> String
toJsonString firstNote secondNote question =
  ""

emptySource : Source
emptySource =
  Source "" "" ""

titleIsValid : Title -> Bool
titleIsValid title =
  let
    notEmpty = not <| String.isEmpty title
    notNA = title /= "n/a"
  in
  notEmpty && notNA
