module Tutorial exposing
  ( Tutorial
  , Step(..)
  , end
  , update
  , UpdateAction
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
  | Six_AddRelatedNotePrompt FirstNote
  | Seven_NoteInput FirstNote SecondNoteContent Title
  | Eight_SourceInput FirstNote SecondNoteContent Source
  | Nine_AddLinkPrompt FirstNote SecondNoteContent ( Maybe Source )
  | Ten_ExplainLinks FirstNote SecondNote
  | Eleven_QuestionPrompt FirstNote SecondNote
  | Twelve_QuestionInput FirstNote SecondNote Question
  | Thirteen_ExplainQuestions FirstNote SecondNote ( Maybe Question )
  | Fourteen_PracticeSaving FirstNote SecondNote ( Maybe Question )
  | Fifteen_PracticeUploading FirstNote SecondNote ( Maybe Question )
  | Sixteen_WorkflowSuggestionsAndFinish FirstNote SecondNote ( Maybe Question )

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

    Title input ->
      case tutorial of
        Four_SourceInput firstNote source -> Four_SourceInput firstNote { source | title = input }
        Eight_SourceInput firstNote secondNote source -> Eight_SourceInput firstNote secondNote { source | title = input}
        Seven_NoteInput firstNote secondNote _ -> Seven_NoteInput firstNote secondNote input
        _ -> tutorial


    Author input ->
      case tutorial of
        Four_SourceInput firstNote source -> Four_SourceInput firstNote { source | author = input }
        Eight_SourceInput firstNote secondNote source -> Eight_SourceInput firstNote secondNote { source | author = input}
        _ -> tutorial

-- TODO
skip : Tutorial -> Tutorial
skip tutorial = tutorial

-- TODO
canContinue : Tutorial -> Bool
canContinue tutorial = True

-- TODO
continue : Tutorial -> Tutorial
continue tutorial =
  case tutorial of
    One_Intro -> Two_CreateFirstNote ""

    Two_CreateFirstNote string -> Three_PromptAddSourceToNote string


    Three_PromptAddSourceToNote string -> Four_SourceInput string emptySource


    Four_SourceInput string source -> Five_ExplainNotes <| WithSource string source


    Five_ExplainNotes firstNote -> Six_AddRelatedNotePrompt firstNote


    Six_AddRelatedNotePrompt firstNote -> Seven_NoteInput firstNote "" ""


    Seven_NoteInput firstNote content title -> Eight_SourceInput firstNote content <| Source title "" ""


    Eight_SourceInput firstNote secondNoteContent source -> Nine_AddLinkPrompt firstNote secondNoteContent ( Just source )


    Nine_AddLinkPrompt firstNote secondNoteContent maybeSource ->
      case maybeSource of
        Just source ->
          Ten_ExplainLinks firstNote <| WithSourceAndLinked secondNoteContent source
        Nothing ->
          Ten_ExplainLinks firstNote <| WithoutSourceAndLinked secondNoteContent


    Ten_ExplainLinks firstNote secondNote -> Eleven_QuestionPrompt firstNote secondNote


    Eleven_QuestionPrompt firstNote secondNote -> Twelve_QuestionInput firstNote secondNote ""


    Twelve_QuestionInput firstNote secondNote question -> Thirteen_ExplainQuestions firstNote secondNote ( Just question )


    Thirteen_ExplainQuestions firstNote secondNote maybeQuestion -> Fourteen_PracticeSaving firstNote secondNote maybeQuestion


    Fourteen_PracticeSaving firstNote secondNote maybeQuestion -> Fifteen_PracticeUploading firstNote secondNote maybeQuestion


    Fifteen_PracticeUploading firstNote secondNote maybeQuestion -> Sixteen_WorkflowSuggestionsAndFinish firstNote secondNote maybeQuestion


    Sixteen_WorkflowSuggestionsAndFinish _ _ _ -> tutorial

-- TODO
toJsonString : FirstNote -> SecondNote -> ( Maybe String ) -> String
toJsonString firstNote secondNote question =
  ""

emptySource : Source
emptySource =
  Source "" "" ""