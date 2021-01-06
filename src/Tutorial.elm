module Tutorial exposing
  ( Tutorial
  , Step(..)
  , end
  , update
  , UpdateAction
  , getStep
  , skip
  , submit
  , canSubmit
  )

import Slipbox
type Tutorial
  = One_Intro
  | Two_CreateFirstNote FirstNoteContent
  | Three_PromptAddSourceToNote FirstNoteContent
  | Four_SourceInput FirstNoteContent Source
  | Five_ExplainNotes FirstNote
  | Six_AddRelatedNotePrompt FirstNote
  | Seven_NoteInput FirstNote SecondNoteContent Title
  | Eight_SourceInput FirstNote SecondNoteContent Source
  | Nine_AddLinkPrompt FirstNote SecondNoteContent ( Maybe Source )
  | Ten_ExplainLinks FirstNote SecondNote
  | Eleven_QuestionPrompt FirstNote SecondNote
  | Twelve_QuestionInput FirstNote SecondNote Question
  | Thirteen_ExplainQuestions FirstNote SecondNote Question
  | Fourteen_PracticeSaving FirstNote SecondNote Question
  | Fifteen_PracticeUploading FirstNote SecondNote Question
  | Sixteen_WorkflowSuggestionsAndFinish FirstNote SecondNote Question

type FirstNote
  = WithSource String Source
  | WithoutSource String

getContent : FirstNote -> String
getContent firstNote =
  case firstNote of
    WithSource string _ -> string
    WithoutSource string -> string

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
  | AddRelatedNotePrompt FirstNoteContent
  | NoteInput FirstNoteContent SecondNoteContent Title
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

    Two_CreateFirstNote string -> PromptAddSourceToNote string


    Three_PromptAddSourceToNote string -> CreateFirstNote string


    Four_SourceInput string source -> SourceInput string source.title source.author source.content


    Five_ExplainNotes _ -> ExplainNotes


    Six_AddRelatedNotePrompt firstNote -> AddRelatedNotePrompt <| getContent firstNote


    Seven_NoteInput firstNote content source -> NoteInput ( getContent firstNote ) content source


    Eight_SourceInput _ string source -> SourceInput string source.title source.author source.content


    Nine_AddLinkPrompt firstNote string _ -> AddLinkPrompt ( getContent firstNote ) string


    Ten_ExplainLinks _ _ -> ExplainLinks


    Eleven_QuestionPrompt firstNote _ -> QuestionPrompt ( getContent firstNote )


    Twelve_QuestionInput firstNote _ string -> QuestionInput ( getContent firstNote ) string


    Thirteen_ExplainQuestions _ _ _ -> ExplainQuestions


    Fourteen_PracticeSaving firstNote secondNote string -> PracticeSaving <| toJsonString firstNote secondNote string


    Fifteen_PracticeUploading _ _ _ -> PracticeUploading


    Sixteen_WorkflowSuggestionsAndFinish firstNote secondNote string -> WorkflowSuggestionsAndFinish



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
        Eight_SourceInput firstNote secondNote source -> Eight_SourceInput firstNote secondNote { source | content = input}
        Seven_NoteInput firstNote _ title -> Seven_NoteInput firstNote input title
        Twelve_QuestionInput firstNote secondNote _ -> Twelve_QuestionInput firstNote secondNote input
        _ -> tutorial

    Title string ->


    Author string ->

-- TODO
skip : Tutorial -> Tutorial
skip tutorial =

-- TODO
canSubmit : Tutorial -> Bool
canSubmit tutorial =

-- TODO
submit : Tutorial -> Tutorial
submit tutorial =

-- TODO
toJsonString : FirstNote -> SecondNote -> String -> String
toJsonString firstNote secondNote question =
  ""