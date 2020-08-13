module LinkForm exposing (LinkForm, linkFormData, selectionsChange,
  removeSelections, addSource, addTarget, initLinkForm, maybeProspectiveLink,
  LinkFormData, FormNote, Choice, LinkNoteChoice, linkProspectExists)

import Set
import List

-- Types
type LinkForm =
  Hidden |
  NoSelections |
  SourceSelected Int |
  TargetSelected Int |
  ReadyToSubmit (Int, Int)

type alias FormNote =
  { id: Int
  , summary: String
  , isIndex: Bool
  , linkedNotes: (List Int)
  }

type alias LinkFormData =
  { shown: Bool
  , sourceChoices: (List LinkNoteChoice)
  , sourceChosen: Choice
  , targetChoices: (List LinkNoteChoice)
  , targetChosen: Choice
  , canSubmit: Bool
  }

type alias Choice = 
  { choiceMade: Bool
  , choiceValue: Int
  }

type alias LinkNoteChoice =
  { value: Int
  , display: String
  }

-- Invariants
linkProspectExists: (List FormNote) -> Bool
linkProspectExists notes =
  List.foldl boolConversion 0 (List.map (canCreateLink notes) notes) >= 2

canCreateLink: (List FormNote) -> FormNote -> Bool
canCreateLink notes note =
  Set.size (getLinkProspects note notes) > 0

getLinkProspectNotes: FormNote -> (List FormNote) -> (List FormNote)
getLinkProspectNotes note notes =
  List.filter (\n -> List.member n.id (Set.toList (getLinkProspects note notes))) notes

getLinkProspects: FormNote -> (List FormNote) -> (Set.Set Int)
getLinkProspects note notes =
  Set.diff (linkProspects note notes) (Set.fromList note.linkedNotes)

selectionIsValid: Int -> (List FormNote) -> Bool 
selectionIsValid noteId notes = 
  let
    maybeNote = List.head (List.filter (\n -> n.id == noteId) notes)
  in 
    case maybeNote of 
      Just note -> linkProspectExists notes && canCreateLink notes note
      Nothing -> False

pairIsValid: Int -> Int -> (List FormNote) -> Bool
pairIsValid sourceId targetId notes =
  let
    maybeSource = List.head (List.filter (\note -> note.id == sourceId) notes)
  in
    case maybeSource of
      Just source -> Set.member targetId (getLinkProspects source notes)
      Nothing -> False

-- Exposed Methods
initLinkForm: LinkForm
initLinkForm = Hidden

linkFormData: (List FormNote) -> LinkForm -> LinkFormData
linkFormData notes form =
  case form of
     Hidden -> hiddenLinkFormData
     NoSelections -> buildLinkFormData notes
     SourceSelected noteId -> sourceSelectedLinkFormDataHandler noteId notes
     TargetSelected noteId -> targetSelectedLinkFormDataHandler noteId notes
     ReadyToSubmit selections -> readyToSubmitLinkFormDataHandler selections notes

selectionsChange: LinkForm -> (List FormNote) -> LinkForm
selectionsChange form notes =
  case form of
     Hidden -> noneSelectedHandler notes
     NoSelections -> noneSelectedHandler notes
     SourceSelected noteId -> sourceSelectedHandler noteId notes
     TargetSelected noteId -> targetSelectedHandler noteId notes
     ReadyToSubmit selections -> readyToSubmitHandler selections notes
  
removeSelections: (List FormNote) -> LinkForm
removeSelections notes =
  noneSelectedHandler notes

addSource: String -> LinkForm -> LinkForm
addSource source form =
  case String.toInt source of
    Just intSource -> addSourceHandler intSource form
    Nothing -> form

addTarget: String -> LinkForm -> LinkForm
addTarget target form =
  case String.toInt target of
    Just intTarget -> addTargetHandler intTarget form
    Nothing -> form

maybeProspectiveLink: LinkForm -> (Maybe (Int, Int))
maybeProspectiveLink form =
  case form of
     Hidden -> Nothing
     NoSelections -> Nothing
     SourceSelected _ -> Nothing
     TargetSelected _ -> Nothing
     ReadyToSubmit (source, target) -> Just (source, target)



-- Helper Methods
noneSelectedHandler: (List FormNote) -> LinkForm
noneSelectedHandler notes =
  if linkProspectExists notes then
    NoSelections
  else
    Hidden

sourceSelectedHandler: Int -> (List FormNote) -> LinkForm
sourceSelectedHandler noteId notes =
  if selectionIsValid noteId notes then
    SourceSelected noteId
  else 
    noneSelectedHandler notes

targetSelectedHandler: Int -> (List FormNote) -> LinkForm
targetSelectedHandler noteId notes =
  if selectionIsValid noteId notes then
    TargetSelected noteId
  else
    noneSelectedHandler notes

readyToSubmitHandler: (Int, Int) -> (List FormNote) -> LinkForm
readyToSubmitHandler (sourceId, targetId) notes =
  if pairIsValid sourceId targetId notes then
    ReadyToSubmit (sourceId, targetId)
  else if selectionIsValid sourceId notes then
    SourceSelected sourceId
  else if selectionIsValid targetId notes then
    TargetSelected targetId
  else 
    noneSelectedHandler notes

addSourceHandler: Int -> LinkForm -> LinkForm
addSourceHandler source form =
  case form of
    Hidden -> Hidden
    NoSelections -> SourceSelected source
    SourceSelected _ -> SourceSelected source
    TargetSelected target -> ReadyToSubmit (source, target)
    ReadyToSubmit ( _ , priorTargetId) -> ReadyToSubmit (source, priorTargetId)

addTargetHandler: Int -> LinkForm -> LinkForm
addTargetHandler target form =
  case form of
    Hidden -> Hidden
    NoSelections -> TargetSelected target
    SourceSelected source -> ReadyToSubmit (source, target)
    TargetSelected _ -> TargetSelected target
    ReadyToSubmit (priorSourceId, _ ) -> ReadyToSubmit (priorSourceId, target)

hiddenLinkFormData: LinkFormData
hiddenLinkFormData = LinkFormData False [] noChoice [] noChoice False

noChoice: Choice
noChoice = Choice False -1

allChoices: (List FormNote) -> (List LinkNoteChoice)
allChoices notes = List.map toLinkNoteChoice (List.filter (canCreateLink notes) notes)

buildLinkFormData: (List FormNote) -> LinkFormData
buildLinkFormData notes =
  let
    linkNoteChoices = allChoices notes
  in 
    LinkFormData True linkNoteChoices noChoice linkNoteChoices noChoice False

toLinkNoteChoice: FormNote -> LinkNoteChoice
toLinkNoteChoice note =
  LinkNoteChoice note.id note.summary

sourceSelectedLinkFormDataHandler: Int -> (List FormNote) -> LinkFormData
sourceSelectedLinkFormDataHandler noteId notes =
  let
      maybeNote = List.head (List.filter (\n -> n.id == noteId) notes)
  in
  case maybeNote of
    Just note ->
      LinkFormData 
        True 
        (allChoices notes) 
        (Choice True noteId) 
        (List.map toLinkNoteChoice (getLinkProspectNotes note notes))
        noChoice 
        False
    Nothing -> hiddenLinkFormData

targetSelectedLinkFormDataHandler: Int -> (List FormNote) -> LinkFormData
targetSelectedLinkFormDataHandler noteId notes =
  let
      maybeNote = List.head (List.filter (\n -> n.id == noteId) notes)
  in
  case maybeNote of
    Just note ->
      LinkFormData 
        True 
        (List.map toLinkNoteChoice (getLinkProspectNotes note notes))
        noChoice 
        (allChoices notes) 
        (Choice True noteId) 
        False
    Nothing -> hiddenLinkFormData

readyToSubmitLinkFormDataHandler: (Int, Int) -> (List FormNote) -> LinkFormData
readyToSubmitLinkFormDataHandler (sourceId, targetId) notes =
  let
    maybeSource = List.head (List.filter (\note -> note.id == sourceId) notes)
    maybeTarget = List.head (List.filter (\note -> note.id == targetId) notes)
  in
    case maybeSource of
      Just source -> 
        case maybeTarget of
          Just target -> linkFormDataBothChoices source target notes
          Nothing -> hiddenLinkFormData
      Nothing -> hiddenLinkFormData

linkFormDataBothChoices: FormNote -> FormNote -> (List FormNote) -> LinkFormData
linkFormDataBothChoices source target notes =
  LinkFormData 
    True 
    (allChoices notes) 
    (Choice True source.id) 
    (allChoices notes) 
    (Choice True target.id) 
    True

boolConversion: Bool -> Int -> Int
boolConversion bool sum =
  if bool then
    1 + sum
  else
    0 + sum

linkProspects: FormNote -> (List FormNote) -> (Set.Set Int)
linkProspects note notes =
  Set.fromList (List.map (\n -> n.id) (indexHandler note (excludeNote note.id notes)))

excludeNote: Int -> (List FormNote) -> (List FormNote)
excludeNote noteId notes = List.filter (\note -> note.id /= noteId) notes

indexHandler: FormNote -> (List FormNote) -> (List FormNote)
indexHandler note notes =
  if note.isIndex then
    List.filter (\n -> n.isIndex /= True) notes
  else 
    notes