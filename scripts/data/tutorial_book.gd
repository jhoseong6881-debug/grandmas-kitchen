class_name TutorialBook
extends Resource
## 처음 하는 사람을 위한 안내 모음. data/story/tutorial.tres 에 있다. StartingSetup.tutorial 에 연결한다.
## 안내를 더하려면 Tips 에 TutorialTip 을 더하고, 그 화면 코드에서 TutorialDialog.show_once(id) 를 부른다.

## 안내해 주는 손님 (얼굴 그림과 이름을 쓴다)
@export var guide: AnimalGuest
@export var tips: Array[TutorialTip] = []


func get_tip(tip_id: StringName) -> TutorialTip:
	for tip: TutorialTip in tips:
		if tip != null and tip.id == tip_id:
			return tip
	return null


func get_all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for tip: TutorialTip in tips:
		if tip != null:
			ids.append(tip.id)
	return ids
