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
  | Seven_SourceInput FirstNote NoteContent Source
  | Eight_AddLinkPrompt FirstNote NoteContent ( Maybe Source )
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
  | WithoutSourceAndLinked NoteContent
  | WithSourceNotLinked String Source
  | WithoutSourceNotLinked NoteContent
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
type alias NoteContent = { content: String, source: String}

getStep : Tutorial -> Step
getStep tutorial =
  case tutorial of
    One_Intro -> Intro

    Two_CreateFirstNote string -> CreateFirstNote string


    Three_PromptAddSourceToNote string -> PromptAddSourceToNote string


    Four_SourceInput string source -> SourceInput string source.title source.author source.content


    Five_ExplainNotes _ -> ExplainNotes


    Six_NoteInput firstNote content source -> NoteInput ( getContent firstNote ) ( getSourceTitle firstNote ) content source


    Seven_SourceInput _ string source -> SourceInput string.content source.title source.author source.content


    Eight_AddLinkPrompt firstNote secondNote _ -> AddLinkPrompt ( getContent firstNote ) secondNote.content


    Nine_ExplainLinks _ _ -> ExplainLinks


    Ten_QuestionPrompt firstNote _ -> QuestionPrompt ( getContent firstNote )


    Eleven_QuestionInput firstNote _ string -> QuestionInput ( getContent firstNote ) string


    Twelve_ExplainQuestions _ _ _ -> ExplainQuestions


    Thirteen_PracticeSaving _ _ _ -> PracticeSaving <| Slipbox.encode <| end tutorial


    Fourteen_PracticeUploading _ _ _ -> PracticeUploading


    Fifteen_WorkflowSuggestionsAndFinish _ _ _ -> WorkflowSuggestionsAndFinish

end : Tutorial -> Slipbox.Slipbox
end tutorial =
  let
    tutorialEnding = case tutorial of
      One_Intro -> Slipbox.None

      Two_CreateFirstNote _ -> Slipbox.None

      Three_PromptAddSourceToNote firstNoteContent ->
        Slipbox.OnlyFirstNote (NoteContent firstNoteContent "n/a")

      Four_SourceInput firstNoteContent _ ->
        Slipbox.OnlyFirstNote (NoteContent firstNoteContent "n/a")

      Five_ExplainNotes firstNote ->
        case firstNote of
          WithSource firstNoteContent source ->
            Slipbox.WithFirstSource {content=firstNoteContent,source=source.title} source

          WithoutSource firstNoteContent ->
            Slipbox.OnlyFirstNote (NoteContent firstNoteContent "n/a")

      Six_NoteInput firstNote _ _ ->
        case firstNote of
          WithSource firstNoteContent source ->
            Slipbox.WithFirstSource {content=firstNoteContent,source=source.title} source

          WithoutSource firstNoteContent ->
            Slipbox.OnlyFirstNote (NoteContent firstNoteContent "n/a")

      Seven_SourceInput firstNote secondNoteContent _ ->
        case firstNote of
          WithSource firstNoteContent source ->
            Slipbox.WithFirstSourceSecondNote {content=firstNoteContent,source=source.title} source secondNoteContent

          WithoutSource firstNoteContent ->
            Slipbox.WithSecondNote (NoteContent firstNoteContent "n/a") secondNoteContent


      Eight_AddLinkPrompt firstNote secondNoteContent maybeSource ->
        case firstNote of
          WithSource firstNoteContent source ->

            case maybeSource of

              Just secondSource ->
                Slipbox.WithFirstSourceSecondNoteSecondSource {content=firstNoteContent,source=source.title} source secondNoteContent secondSource

              Nothing ->
                Slipbox.WithFirstSourceSecondNote {content=firstNoteContent,source=source.title} source secondNoteContent

          WithoutSource firstNoteContent ->
            case maybeSource of
              Just secondSource ->
                Slipbox.WithSecondNoteSecondSource (NoteContent firstNoteContent "n/a") secondNoteContent secondSource

              Nothing ->
                Slipbox.WithSecondNote (NoteContent firstNoteContent "n/a") secondNoteContent


      Nine_ExplainLinks firstNote secondNote ->
        case firstNote of

          WithSource firstNoteContent source ->

            case secondNote of
              WithSourceAndLinked secondNoteContent secondSource ->
                Slipbox.WithFirstSourceSecondNoteSecondSourceLink
                  {content=firstNoteContent,source=source.title} source {content=secondNoteContent,source=secondSource.title} secondSource

              WithoutSourceAndLinked secondNoteContent ->
                Slipbox.WithFirstSourceSecondNoteLink
                  {content=firstNoteContent,source=source.title} source secondNoteContent

              WithSourceNotLinked secondNoteContent secondSource ->
                Slipbox.WithFirstSourceSecondNoteSecondSource
                  {content=firstNoteContent,source=source.title} source {content=secondNoteContent,source=secondSource.title} secondSource

              WithoutSourceNotLinked secondNoteContent ->
                Slipbox.WithFirstSourceSecondNote {content=firstNoteContent,source=source.title} source secondNoteContent

              NoSecondNote ->
                Slipbox.WithFirstSource {content=firstNoteContent,source=source.title} source

          WithoutSource firstNoteContent ->
            case secondNote of
              WithSourceAndLinked secondNoteContent secondSource ->
                Slipbox.WithSecondNoteSecondSourceLink
                    (NoteContent firstNoteContent "n/a") {content=secondNoteContent,source=secondSource.title} secondSource

              WithoutSourceAndLinked secondNoteContent ->
                Slipbox.WithSecondNoteLink
                    (NoteContent firstNoteContent "n/a") secondNoteContent

              WithSourceNotLinked secondNoteContent secondSource ->
                Slipbox.WithSecondNoteSecondSource
                  (NoteContent firstNoteContent "n/a") {content=secondNoteContent,source=secondSource.title} secondSource

              WithoutSourceNotLinked secondNoteContent ->
                Slipbox.WithSecondNote (NoteContent firstNoteContent "n/a") secondNoteContent

              NoSecondNote ->
                Slipbox.OnlyFirstNote (NoteContent firstNoteContent "n/a")

      Ten_QuestionPrompt firstNote secondNote ->
        case firstNote of

          WithSource firstNoteContent source ->

            case secondNote of
              WithSourceAndLinked secondNoteContent secondSource ->
                Slipbox.WithFirstSourceSecondNoteSecondSourceLink
                  {content=firstNoteContent,source=source.title} source {content=secondNoteContent,source=secondSource.title} secondSource

              WithoutSourceAndLinked secondNoteContent ->
                Slipbox.WithFirstSourceSecondNoteLink
                  {content=firstNoteContent,source=source.title} source secondNoteContent

              WithSourceNotLinked secondNoteContent secondSource ->
                Slipbox.WithFirstSourceSecondNoteSecondSource
                  {content=firstNoteContent,source=source.title} source {content=secondNoteContent,source=secondSource.title} secondSource

              WithoutSourceNotLinked secondNoteContent ->
                Slipbox.WithFirstSourceSecondNote {content=firstNoteContent,source=source.title} source secondNoteContent

              NoSecondNote ->
                Slipbox.WithFirstSource {content=firstNoteContent,source=source.title} source

          WithoutSource firstNoteContent ->
            case secondNote of
              WithSourceAndLinked secondNoteContent secondSource ->
                Slipbox.WithSecondNoteSecondSourceLink
                    (NoteContent firstNoteContent "n/a") {content=secondNoteContent,source=secondSource.title} secondSource

              WithoutSourceAndLinked secondNoteContent ->
                Slipbox.WithSecondNoteLink
                    (NoteContent firstNoteContent "n/a") secondNoteContent

              WithSourceNotLinked secondNoteContent secondSource ->
                Slipbox.WithSecondNoteSecondSource
                  (NoteContent firstNoteContent "n/a") {content=secondNoteContent,source=secondSource.title} secondSource

              WithoutSourceNotLinked secondNoteContent ->
                Slipbox.WithSecondNote (NoteContent firstNoteContent "n/a") secondNoteContent

              NoSecondNote ->
                Slipbox.OnlyFirstNote (NoteContent firstNoteContent "n/a")

      Eleven_QuestionInput firstNote secondNote question ->
        case firstNote of

          WithSource firstNoteContent source ->

            case secondNote of
              WithSourceAndLinked secondNoteContent secondSource ->
                Slipbox.WithFirstSourceSecondNoteSecondSourceLink
                  {content=firstNoteContent,source=source.title} source {content=secondNoteContent,source=secondSource.title} secondSource

              WithoutSourceAndLinked secondNoteContent ->
                Slipbox.WithFirstSourceSecondNoteLink
                  {content=firstNoteContent,source=source.title} source secondNoteContent

              WithSourceNotLinked secondNoteContent secondSource ->
                Slipbox.WithFirstSourceSecondNoteSecondSource
                  {content=firstNoteContent,source=source.title} source {content=secondNoteContent,source=secondSource.title} secondSource

              WithoutSourceNotLinked secondNoteContent ->
                Slipbox.WithFirstSourceSecondNote {content=firstNoteContent,source=source.title} source secondNoteContent

              NoSecondNote -> Slipbox.WithFirstSource {content=firstNoteContent,source=source.title} source

          WithoutSource firstNoteContent ->
            case secondNote of
              WithSourceAndLinked secondNoteContent secondSource ->
                Slipbox.WithSecondNoteSecondSourceLink
                    (NoteContent firstNoteContent "n/a") {content=secondNoteContent,source=secondSource.title} secondSource

              WithoutSourceAndLinked secondNoteContent ->
                Slipbox.WithSecondNoteLink
                    (NoteContent firstNoteContent "n/a") secondNoteContent

              WithSourceNotLinked secondNoteContent secondSource ->
                Slipbox.WithSecondNoteSecondSource
                  (NoteContent firstNoteContent "n/a") {content=secondNoteContent,source=secondSource.title} secondSource

              WithoutSourceNotLinked secondNoteContent ->
                Slipbox.WithSecondNote (NoteContent firstNoteContent "n/a") secondNoteContent

              NoSecondNote -> Slipbox.OnlyFirstNote (NoteContent firstNoteContent "n/a")

      Twelve_ExplainQuestions firstNote secondNote maybeString -> lastScenarioEndTutorial firstNote secondNote maybeString
      Thirteen_PracticeSaving firstNote secondNote maybeString -> lastScenarioEndTutorial firstNote secondNote maybeString
      Fourteen_PracticeUploading firstNote secondNote maybeString -> lastScenarioEndTutorial firstNote secondNote maybeString
      Fifteen_WorkflowSuggestionsAndFinish firstNote secondNote maybeString -> lastScenarioEndTutorial firstNote secondNote maybeString
  in
  Slipbox.endTutorial tutorialEnding

lastScenarioEndTutorial : FirstNote -> SecondNote -> ( Maybe String ) -> Slipbox.TutorialEnding
lastScenarioEndTutorial firstNote secondNote maybeString =
  case firstNote of
    WithSource firstNoteContent source ->

      case secondNote of
        WithSourceAndLinked secondNoteContent secondSource ->
          case maybeString of
            Just question ->
              Slipbox.WithFirstSourceSecondNoteSecondSourceLinkQuestion
                {content=firstNoteContent,source=source.title} source {content=secondNoteContent,source=secondSource.title} secondSource question

            Nothing ->
              Slipbox.WithFirstSourceSecondNoteSecondSourceLink
                {content=firstNoteContent,source=source.title} source {content=secondNoteContent,source=secondSource.title} secondSource

        WithoutSourceAndLinked secondNoteContent ->
          case maybeString of
            Just question ->
              Slipbox.WithFirstSourceSecondNoteLinkQuestion
                {content=firstNoteContent,source=source.title} source secondNoteContent question

            Nothing ->
              Slipbox.WithFirstSourceSecondNoteLink
                {content=firstNoteContent,source=source.title} source secondNoteContent

        WithSourceNotLinked secondNoteContent secondSource ->
          case maybeString of
            Just question ->
              Slipbox.WithFirstSourceSecondNoteSecondSourceQuestion
                {content=firstNoteContent,source=source.title} source {content=secondNoteContent,source=secondSource.title} secondSource question

            Nothing ->
              Slipbox.WithFirstSourceSecondNoteSecondSource
                {content=firstNoteContent,source=source.title} source {content=secondNoteContent,source=secondSource.title} secondSource

        WithoutSourceNotLinked secondNoteContent ->
          case maybeString of
            Just question ->
              Slipbox.WithFirstSourceSecondNoteQuestion {content=firstNoteContent,source=source.title} source secondNoteContent question
            Nothing ->
              Slipbox.WithFirstSourceSecondNote {content=firstNoteContent,source=source.title} source secondNoteContent

        NoSecondNote ->
          case maybeString of
            Just question ->
              Slipbox.WithFirstSourceQuestion {content=firstNoteContent,source=source.title} source question
            Nothing ->
              Slipbox.WithFirstSource {content=firstNoteContent,source=source.title} source

    WithoutSource firstNoteContent ->
      case secondNote of
        WithSourceAndLinked secondNoteContent secondSource ->
          case maybeString of
            Just question ->
              Slipbox.WithSecondNoteSecondSourceLinkQuestion
                  (NoteContent firstNoteContent "n/a") {content=secondNoteContent,source=secondSource.title} secondSource question
            Nothing ->
              Slipbox.WithSecondNoteSecondSourceLink
                  (NoteContent firstNoteContent "n/a") {content=secondNoteContent,source=secondSource.title} secondSource

        WithoutSourceAndLinked secondNoteContent ->
          case maybeString of
            Just question ->
              Slipbox.WithSecondNoteLinkQuestion (NoteContent firstNoteContent "n/a") secondNoteContent question
            Nothing ->
              Slipbox.WithSecondNoteLink (NoteContent firstNoteContent "n/a") secondNoteContent

        WithSourceNotLinked secondNoteContent secondSource ->
          case maybeString of
            Just question ->
              Slipbox.WithSecondNoteSecondSourceQuestion
                (NoteContent firstNoteContent "n/a") {content=secondNoteContent,source=secondSource.title} secondSource question

            Nothing ->
              Slipbox.WithSecondNoteSecondSource
                (NoteContent firstNoteContent "n/a") {content=secondNoteContent,source=secondSource.title} secondSource

        WithoutSourceNotLinked secondNoteContent ->
          case maybeString of
            Just question -> Slipbox.WithSecondNoteQuestion (NoteContent firstNoteContent "n/a") secondNoteContent question
            Nothing -> Slipbox.WithSecondNote (NoteContent firstNoteContent "n/a") secondNoteContent

        NoSecondNote ->
          case maybeString of
            Just question -> Slipbox.WithQuestion (NoteContent firstNoteContent "n/a") question
            Nothing -> Slipbox.OnlyFirstNote (NoteContent firstNoteContent "n/a")

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
          Nine_ExplainLinks firstNote
            <| WithSourceNotLinked secondNoteContent.content source
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

    Six_NoteInput _ secondNoteContent _ -> not <| String.isEmpty secondNoteContent

    Seven_SourceInput _ _ source -> not <| String.isEmpty source.title

    Eleven_QuestionInput _ _ question -> not <| String.isEmpty question

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
        Seven_SourceInput firstNote { content=content,source=title } <| Source title "" ""
      else
        let
          blankToNaInvariant = \t ->
            if String.isEmpty t then
              "n/a"
            else
              t
        in
        Eight_AddLinkPrompt firstNote { content=content,source=blankToNaInvariant title } Nothing


    Seven_SourceInput firstNote secondNoteContent source -> Eight_AddLinkPrompt firstNote secondNoteContent ( Just source )


    Eight_AddLinkPrompt firstNote secondNoteContent maybeSource ->
      case maybeSource of
        Just source ->
          Nine_ExplainLinks firstNote <| WithSourceAndLinked secondNoteContent.content source
        Nothing ->
          Nine_ExplainLinks firstNote <| WithoutSourceAndLinked secondNoteContent


    Nine_ExplainLinks firstNote secondNote -> Ten_QuestionPrompt firstNote secondNote


    Ten_QuestionPrompt firstNote secondNote -> Eleven_QuestionInput firstNote secondNote ""


    Eleven_QuestionInput firstNote secondNote question -> Twelve_ExplainQuestions firstNote secondNote ( Just question )


    Twelve_ExplainQuestions firstNote secondNote maybeQuestion -> Thirteen_PracticeSaving firstNote secondNote maybeQuestion


    Thirteen_PracticeSaving firstNote secondNote maybeQuestion -> Fourteen_PracticeUploading firstNote secondNote maybeQuestion


    Fourteen_PracticeUploading firstNote secondNote maybeQuestion -> Fifteen_WorkflowSuggestionsAndFinish firstNote secondNote maybeQuestion


    Fifteen_WorkflowSuggestionsAndFinish _ _ _ -> tutorial

toJsonString : Slipbox.Slipbox -> String
toJsonString slipbox =
  Slipbox.encode slipbox

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
