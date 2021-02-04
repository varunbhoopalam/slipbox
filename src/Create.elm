module Create exposing
  ( Create
  )

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
  = CreateModeInternal Note QuestionsRead LinksCreated Source

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