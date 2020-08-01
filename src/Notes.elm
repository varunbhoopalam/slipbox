module Notes exposing (Foobar)

type Foobar = Foobar

type alias Notes = List Note
type alias Note = 
  {id : NoteId
  , content : Content
  , source : Source
  , noteType: NoteType}
type alias Description = String
type alias NoteId = Int
type NoteType = Regular | Index

type alias Content = String
type alias Source = String


add: Notes -> Note -> Notes
add notes note =
  note :: notes
remove: Notes -> Note -> Notes
remove notes note =
  List.filter (\x -> x.id == note.id) notes

get: Notes -> Note -> Maybe Note
get notes note =
  List.head (List.filter (\x -> x.id == note.id) notes)

createNote: Content -> Source -> NoteType -> Note
createNote = c s n
  Note generateId c s n

isMember: Notes -> Note -> Bool
isMember notes note =
  List.member note.id (List.map (\x -> x.id) notes)

equals: Note -> Note -> Bool
equals n1 n2 =
  n1 == n2

getIndexQuestions: Notes -> Notes
getIndexQuestions n =
  List.filter isIndexQuestion n

isIndexQuestion: Note -> Bool
isIndexQuestion n =
  case n.noteType of
     Regular -> False
     Index -> True

-- description: Notes -> Note -> Description