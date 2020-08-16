module Action exposing (Action, CreateNoteRecord, EditNoteRecord, DeleteNoteRecord
  , CreateLinkRecord, DeleteLinkRecord, Summary
  , createNote, editNote, deleteNote, createLink, deleteLink, summary
  , undo, shouldUndo, redo, shouldRedo, shouldRemove
  , subsequentActionId, sortDesc, save)


-- Types

type Action =
  CreateNote ActionId State CreateNoteRecord |
  EditNote ActionId State EditNoteRecord |
  DeleteNote ActionId State DeleteNoteRecord |
  CreateLink ActionId State CreateLinkRecord |
  DeleteLink ActionId State DeleteLinkRecord

type alias ActionId = Int

type State =
  Saved |
  Temporary Undone

type alias Undone = Bool

type alias CreateNoteRecord = 
  { id : Int
  , content : String
  , source : String
  , variant: String
  }

type alias CreateLinkRecord =
  { id: Int
  , source: Int
  , target: Int
  }

type alias EditNoteRecord =
  { id : Int
  , formerContent: String
  , currentContent: String
  , formerSource: String
  , currentSource: String
  , variant: String
  }

type alias DeleteNoteRecord =
  { id : Int
  , content : String
  , source : String
  , variant: String
  }

type alias DeleteLinkRecord =
  { id: Int
  , source: Int
  , target: Int
  }

type alias Summary =
  { id : ActionId
  , saved: Bool
  , undone : Bool
  , summary : String
  }

-- Exposed Methods
createNote: ActionId -> CreateNoteRecord -> Action
createNote actionId note =
  CreateNote actionId defaultState note

editNote: ActionId -> EditNoteRecord -> Action
editNote actionId note =
  EditNote actionId defaultState note

deleteNote: ActionId -> DeleteNoteRecord -> Action
deleteNote actionId note =
  DeleteNote actionId defaultState note

createLink: ActionId -> CreateLinkRecord -> Action
createLink actionId link =
  CreateLink actionId defaultState link

deleteLink: ActionId -> DeleteLinkRecord -> Action
deleteLink actionId link =
  DeleteLink actionId defaultState link

summary: Action -> Summary
summary action =
  case action of
    CreateNote actionId state record -> Summary actionId (isSaved state) (isUndone state) (createNoteSummary record)
    EditNote actionId state record -> Summary actionId (isSaved state) (isUndone state) (editNoteSummary record) 
    DeleteNote actionId state record -> Summary actionId (isSaved state) (isUndone state) (deleteNoteSummary record) 
    CreateLink actionId state record -> Summary actionId (isSaved state) (isUndone state) (createLinkSummary record) 
    DeleteLink actionId state record -> Summary actionId (isSaved state) (isUndone state) (deleteLinkSummary record)

undo: Action -> Action
undo action =
  case action of
    CreateNote actionId state record -> CreateNote actionId (undoState state) record
    EditNote actionId state record -> EditNote actionId (undoState state) record 
    DeleteNote actionId state record -> DeleteNote actionId (undoState state) record 
    CreateLink actionId state record -> CreateLink actionId (undoState state) record 
    DeleteLink actionId state record -> DeleteLink actionId (undoState state) record

shouldUndo: ActionId -> Action -> Bool
shouldUndo givenId action = 
  if ( givenId <= getActionId action ) then
    case getState action of
      Saved -> False
      Temporary undone -> not undone
  else
    False

redo: Action -> Action
redo action =
  case action of
    CreateNote actionId state record -> CreateNote actionId (redoState state) record
    EditNote actionId state record -> EditNote actionId (redoState state) record 
    DeleteNote actionId state record -> DeleteNote actionId (redoState state) record 
    CreateLink actionId state record -> CreateLink actionId (redoState state) record 
    DeleteLink actionId state record -> DeleteLink actionId (redoState state) record

shouldRedo: ActionId -> Action -> Bool
shouldRedo givenId action = 
  if ( givenId >= getActionId action ) then
    case getState action of
      Saved -> False
      Temporary undone -> undone
  else
    False

shouldRemove: Action -> Bool
shouldRemove action = 
  case getState action of
      Saved -> False
      Temporary undone -> undone

subsequentActionId: Action -> ActionId
subsequentActionId action =
  getActionId action + 1

sortDesc: (Action -> Action -> Order)
sortDesc actionA actionB =
  let
      idA = getActionId actionA
      idB = getActionId actionB
  in
    case compare idA idB of
       LT -> GT
       EQ -> EQ
       GT -> LT

save: (Action -> Action)
save action =
  case action of
    CreateNote actionId state record -> CreateNote actionId Saved record
    EditNote actionId state record -> EditNote actionId Saved record 
    DeleteNote actionId state record -> DeleteNote actionId Saved record 
    CreateLink actionId state record -> CreateLink actionId Saved record 
    DeleteLink actionId state record -> DeleteLink actionId Saved record

-- Helpers
defaultState: State
defaultState = Temporary False

getActionId: Action -> Int
getActionId action =
  case action of
    CreateNote actionId _ _ -> actionId 
    EditNote actionId _ _ -> actionId 
    DeleteNote actionId _ _ -> actionId 
    CreateLink actionId _ _ -> actionId 
    DeleteLink actionId _ _ -> actionId

getState: Action -> State
getState action =
  case action of
    CreateNote _ state _ -> state 
    EditNote _ state _ -> state 
    DeleteNote _ state _ -> state 
    CreateLink _ state _ -> state 
    DeleteLink _ state _ -> state

createNoteSummary: CreateNoteRecord -> String
createNoteSummary note =
  "Create Note:" ++  String.fromInt note.id ++
  " with Content: " ++ contentSummary note.content

editNoteSummary: EditNoteRecord -> String
editNoteSummary note =
  "Edit Note:" ++  String.fromInt note.id ++
  " with Content: " ++ contentSummary note.currentContent ++
  " from Content: " ++ contentSummary note.formerContent

deleteNoteSummary: DeleteNoteRecord -> String
deleteNoteSummary note =
  "Delete Note:" ++  String.fromInt note.id ++
  " with Content: " ++ contentSummary note.content

contentSummary: String -> String
contentSummary content = String.slice 0 summaryLengthMin content ++ "..."


createLinkSummary: CreateLinkRecord -> String
createLinkSummary link =
  "Create Link:" ++  String.fromInt link.id ++ 
  " from Source:" ++  String.fromInt link.source ++ 
  " to Target:" ++  String.fromInt link.target

deleteLinkSummary: DeleteLinkRecord -> String
deleteLinkSummary link =
  "Delete Link:" ++  String.fromInt link.id ++ 
  " from Source:" ++  String.fromInt link.source ++ 
  " to Target:" ++  String.fromInt link.target

isSaved: State -> Bool
isSaved state =
  case state of
    Saved -> True
    Temporary _ -> False

isUndone: State -> Bool
isUndone state =
  case state of
    Saved -> False
    Temporary undone -> undone

undoState: State -> State
undoState state =
  case state of
    Saved -> state
    Temporary _ -> Temporary True

redoState: State -> State
redoState state =
  case state of
    Saved -> state
    Temporary _ -> Temporary False

summaryLengthMin: Int
summaryLengthMin = 20