module Action exposing (Action, CreateNoteRecord, EditNoteRecord, DeleteNoteRecord
  , CreateLinkRecord, DeleteLinkRecord, Summary, Record_ (..)
  , createNote, editNote, deleteNote, createLink, deleteLink, summary
  , undo, shouldUndo, redo, shouldRedo, shouldRemove
  , subsequentActionId, sortDesc, save, record_
  , SaveRequestNote, SaveRequestNoteEdit, SaveRequestLink, extract
  , SaveRequestRecord (..), actionIsSaved)

import Link
import Note

-- Types

type Action =
  CreateNote ActionId CreateNoteRecord |
  EditNote ActionId EditNoteRecord |
  DeleteNote ActionId Note.Note |
  CreateLink ActionId CreateLinkRecord |
  DeleteLink ActionId Link.Link

type alias ActionId = Int

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

type Record_ =
  CreateNote_ CreateNoteRecord |
  EditNote_ EditNoteRecord |
  DeleteNote_ DeleteNoteRecord |
  CreateLink_ CreateLinkRecord |
  DeleteLink_ DeleteLinkRecord 

type alias SaveRequestNote = 
  { action_id: Int
  , id_: Int
  , content: String
  , source: String
  , variant: String
  }

type alias SaveRequestNoteEdit = 
  { action_id: Int
  , id_: Int
  , new_content: String
  , old_content: String
  , new_source: String
  , old_source: String
  , variant: String
  }

type alias SaveRequestLink =
  { action_id: Int
  , id_: Int
  , source: Int
  , target: Int
  }

type SaveRequestRecord =
  CreateNoteSave SaveRequestNote |
  EditNoteSave SaveRequestNoteEdit |
  DeleteNoteSave SaveRequestNote |
  CreateLinkSave SaveRequestLink |
  DeleteLinkSave SaveRequestLink |
  AlreadySaved

-- Exposed Methods
createNote: ActionId -> CreateNoteRecord -> Action
createNote actionId note =
  CreateNote actionId defaultState note

editNote: ActionId -> EditNoteRecord -> Action
editNote actionId note =
  EditNote actionId defaultState note

deleteNote: ( List Action ) -> Note.Note -> Action
deleteNote actions note =
  DeleteNote (nextActionId actions) note

createLink: ActionId -> CreateLinkRecord -> Action
createLink actionId link =
  CreateLink actionId defaultState link

deleteLink: ( List Action ) -> Link.Link -> Action
deleteLink actions link =
  DeleteLink (nextActionId actions) link

summary: Action -> Summary
summary action =
  case action of
    CreateNote actionId state record -> Summary actionId (isSaved state) (isUndone state) (createNoteSummary record)
    EditNote actionId state record -> Summary actionId (isSaved state) (isUndone state) (editNoteSummary record) 
    DeleteNote actionId state record -> Summary actionId (isSaved state) (isUndone state) (deleteNoteSummary record) 
    CreateLink actionId state record -> Summary actionId (isSaved state) (isUndone state) (createLinkSummary record) 
    DeleteLink actionId state record -> Summary actionId (isSaved state) (isUndone state) (deleteLinkSummary record)

record_: Action -> Record_
record_ action =
  case action of
    CreateNote _ _ record -> (CreateNote_ record)
    EditNote _ _ record -> (EditNote_ record)
    DeleteNote _ _ record -> (DeleteNote_ record)
    CreateLink _ _ record -> (CreateLink_ record)
    DeleteLink _ _ record -> (DeleteLink_ record)

extract: Action -> SaveRequestRecord
extract action =
  if getState action |> isSaved then
    AlreadySaved
  else
    case action of
      CreateNote actionId _ record -> 
        SaveRequestNote actionId record.id record.content record.source record.variant
        |> CreateNoteSave 
      EditNote actionId _ record -> 
        SaveRequestNoteEdit actionId record.id record.currentContent record.formerContent record.currentSource record.formerSource record.variant
        |> EditNoteSave
      DeleteNote actionId _ record ->
        SaveRequestNote actionId record.id record.content record.source record.variant
        |> DeleteNoteSave 
      CreateLink actionId _ record -> 
        SaveRequestLink actionId record.id record.source record.target
        |> CreateLinkSave
      DeleteLink actionId _ record -> 
        SaveRequestLink actionId record.id record.source record.target
        |> DeleteLinkSave

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
  if  givenId >= getActionId action  then
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
  if  givenId >= getActionId action  then
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
    CreateNote actionId _ record -> CreateNote actionId Saved record
    EditNote actionId _ record -> EditNote actionId Saved record 
    DeleteNote actionId _ record -> DeleteNote actionId Saved record 
    CreateLink actionId _ record -> CreateLink actionId Saved record 
    DeleteLink actionId _ record -> DeleteLink actionId Saved record

actionIsSaved: Action -> Bool
actionIsSaved action =
  getState action |> isSaved

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