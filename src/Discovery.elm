module Discovery exposing
  ( Discovery
  , DiscoveryView(..)
  )

import Graph
import Note

type Discovery
  = ViewDiscussion Discussion SelectedNote Graph.Graph
  | ChooseDiscussion FilterInput

type alias Discussion = Note.Note
type alias SelectedNote = Note.Note
type alias FilterInput = String

type DiscoveryView
  = ViewDiscussionView Discussion SelectedNote Graph.Graph
  | ChooseDiscussionView FilterInput
