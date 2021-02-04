module Create exposing
  ( Create
  )

import Note
import Link
import Source

type Create
  = NoteInput CoachingModal CreateModeInternal
  | ChooseQuestion CoachingModal CreateModeInternal
  | FindLinksForQuestion CoachingModal Graph LinkModal CreateModeInternal Question SelectedNote
  | ChooseSourceCategory CoachingModal CreateModeInternal String
  | CreateNewSource CoachingModal CreateModeInternal Title Author Content
  | PromptCreateAnother CreateModeInternal

-- COACHINGMODAL
type CoachingModal = CoachingModalOpen | CoachingModalClosed

-- COACHINGMODEINTERNAL
type CreateModeInternal
  = CreateModeInternal CreatedNote QuestionsRead LinksCreated Source

-- GRAPH
type alias Graph =
  { positions :  List NotePosition
  , links : List Link.Link
  }

type alias NotePosition =
  { id : Int
  , note : Note.Note
  , x : Float
  , y : Float
  , vx : Float
  , vy : Float
  }

-- LINKMODAL
type LinkModal
  = Closed
  | Open String

-- CREATEMODESOURCE
type Source
  = None
  | New Title Author Content
  | Existing Source.Source

-- QUESTIONSREAD
type alias QuestionsRead = ( List Note.Note )

-- LINKSCREATED
type alias LinksCreated = ( List Link )

-- CREATEMODELINK
type Link
  = Link Note.Note
  | Bridge Note.Note CreatedNote

-- MISC
type alias Question = Note.Note
type alias SelectedNote = Note.Note
type alias Title = String
type alias Author = String
type alias Content = String
type alias CreatedNote = String


