import Browser

-- MAIN

main =
  Browser.sandbox { init = init, update = update, view = view }

-- MODEL

type Model
  = NoteInput CoachingModal Slipbox.Slipbox CreateModeInternal
  | ChooseQuestion CoachingModal Slipbox.Slipbox CreateModeInternal
  | FindLinksForQuestion CoachingModal Graph BridgeModal Slipbox.Slipbox CreateModeInternal
  | ChooseSourceCategory CoachingModal Slipbox.Slipbox CreateModeInternal
  | ChooseExistingSource CoachingModal Slipbox.Slipbox CreateModeInternal
  | CreateNewSource CoachingModal Slipbox.Slipbox CreateModeInternal
  | PromptCreateAnotherOrFinish Slipbox.Slipbox CreateModeInternal

type CreateModeInternal
  = CreateModeInternal Note QuestionsRead LinksCreated Source

type alias Note = String
type alias QuestionsRead = ( List Note.Note )
type alias LinksCreated = ( List Link )
type Source
  = None
  | New Title Author Content
  | Existing Source.Source

type Link
  = Link Note.Note
  | Bridge Note.Note Note

-- Assumption, almost all bridge notes will not have a source. Maybe it's a bad assumption

type alias CoachingModal = Bool

type BridgeModal
  = Closed
  | Open Note.Note Note

type Graph =
  Graph Force.State ( List NotePositions )

type alias NotePositions = { Note, x, y, fx, fy }

