extends Node
## 시나리오 시험: 버섯 원목이 열린 뒤 처음 맞는 아침 텃밭에서 토끼 안내(mushroom_logs)가 한 번만 나오는지.
## 원목이 잠겨 있으면 안 나오고, 텃밭 첫 안내(garden)와 겹치지 않고 그 뒤에 이어서 나온다.
## 쓰는 법: tools/check/run.sh logs_tip  (시험용 사본에 오토로드로 붙여 돌린다. 끝 코드 = 실패 수)

const GARDEN_SCENE: String = "res://scenes/garden/garden.tscn"
const LOGS_TIP: StringName = &"mushroom_logs"

var fails: int = 0


func _ready() -> void:
	for i: int in 3:
		await get_tree().process_frame
	await _run()
	print("== 시험 끝: 실패 %d" % fails)
	get_tree().quit(fails)


func check(cond: bool, msg: String) -> void:
	print(("OK  " if cond else "!! 실패 ") + msg)
	if not cond:
		fails += 1


func _open_dialogs() -> Array[Node]:
	return get_tree().get_nodes_in_group(TutorialDialog.GROUP)


func _open_tip_id() -> StringName:
	var dialogs: Array[Node] = _open_dialogs()
	return (dialogs[0] as TutorialDialog)._tip.id if dialogs.size() == 1 else &""


## 열린 안내를 끝까지 넘겨 닫는다.
func _close_dialog() -> void:
	var dialogs: Array[Node] = _open_dialogs()
	if dialogs.is_empty():
		return
	var dialog: TutorialDialog = dialogs[0]
	for i: int in 20:
		if not is_instance_valid(dialog) or not dialog.is_in_group(TutorialDialog.GROUP):
			break
		dialog.advance()
		dialog.advance()
	await get_tree().create_timer(0.4).timeout


func _open_garden() -> Node:
	var garden: Node = (load(GARDEN_SCENE) as PackedScene).instantiate()
	add_child(garden)
	for i: int in 3:
		await get_tree().process_frame
	return garden


func _run() -> void:
	# 1) 새 게임 1일째: 원목이 잠겨 있으면 텃밭 안내만 나온다.
	GameState.new_game()
	check(not GameState.is_place_unlocked(&"mushroom_logs"), "준비: 새 게임은 원목이 잠겨 있음")
	var garden: Node = await _open_garden()
	check(_open_tip_id() == &"garden", "1일째: 텃밭 안내가 뜸")
	await _close_dialog()
	check(_open_dialogs().is_empty(), "1일째: 텃밭 안내를 닫으면 다른 안내 없음")
	check(not GameState.has_seen_tutorial(LOGS_TIP), "1일째: 원목 안내는 아직 안 본 것으로 남음")
	garden.queue_free()
	await get_tree().process_frame

	# 2) 고슴도치에게 버섯을 받아 원목이 열린 다음 아침: 원목 안내가 뜬다.
	GameState.add_ingredient(&"mushroom", 1)
	check(GameState.is_place_unlocked(&"mushroom_logs"), "준비: 버섯을 얻으면 원목이 열림")
	garden = await _open_garden()
	check(_open_tip_id() == LOGS_TIP, "원목이 열린 아침: 원목 안내가 뜸 (열린 것 %d개)" % _open_dialogs().size())
	await _close_dialog()
	check(_open_dialogs().is_empty(), "원목 안내를 닫으면 끝")
	garden.queue_free()
	await get_tree().process_frame

	# 3) 다음 날: 다시 안 나온다.
	garden = await _open_garden()
	check(_open_dialogs().is_empty(), "다음 아침: 원목 안내가 다시 안 뜸")
	garden.queue_free()
	await get_tree().process_frame

	# 4) 텃밭 안내를 안 본 채 원목이 이미 열려 있어도, 두 안내가 겹치지 않고 차례로 나온다.
	GameState.seen_tutorial_ids.clear()
	garden = await _open_garden()
	check(_open_tip_id() == &"garden", "둘 다 안 봄: 텃밭 안내가 먼저 하나만 뜸 (열린 것 %d개)" % _open_dialogs().size())
	await _close_dialog()
	await get_tree().process_frame
	check(_open_tip_id() == LOGS_TIP, "둘 다 안 봄: 텃밭 안내 뒤에 원목 안내가 이어서 뜸")
	await _close_dialog()
	garden.queue_free()
	await get_tree().process_frame

	# 5) 세이브에 원목 안내를 본 것이 남는지
	var saved: Dictionary = GameState._to_save_data()
	check(String(LOGS_TIP) in saved.get("seen_tutorial_ids", []), "세이브: 원목 안내 본 것이 저장됨")
