extends Node
## 시나리오 시험: 아침 마을 길 (손님 집 마실).
## 열리는 날, 못 만난 손님 집은 "?"로 막힘, 하루 한 집, 좋아하는 선물이면 단골도가 더 오름,
## 선물 없이 가기, 방문 횟수 세이브, 옛 세이브(방문 기록 없음) 불러오기.
## 쓰는 법: tools/check/run.sh village_visit  (시험용 사본에 오토로드로 붙여 돌린다. 끝 코드 = 실패 수)

const GARDEN_SCENE: String = "res://scenes/garden/garden.tscn"
const VILLAGE_SCENE: String = "res://scenes/garden/village.tscn"

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


func _open(path: String) -> Node:
	var scene: Node = (load(path) as PackedScene).instantiate()
	add_child(scene)
	for i: int in 3:
		await get_tree().process_frame
	return scene


func _close(scene: Node) -> void:
	scene.queue_free()
	await get_tree().process_frame


func _home_buttons(village: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for child: Node in village._home_row.get_children():
		buttons.append(child as Button)
	return buttons


func _run() -> void:
	var settings: VillageSettings = GameData.get_village_settings()
	var guests: Array[AnimalGuest] = GameData.get_season_guests()
	check(settings.open_day == 2 and settings.gift_amount > 0, "설정 파일을 읽음 (열리는 날 %d, 선물 %d개)" % [settings.open_day, settings.gift_amount])
	for guest: AnimalGuest in guests:
		check(not guest.home_name.is_empty() and guest.home_talks.size() >= 1 and guest.favorite_gift != null,
				"%s: 집 이름·이야기·좋아하는 선물이 있음" % guest.display_name)

	# 1) 1일째: 텃밭에 마을 길 버튼이 없다. 2일째부터 있다.
	GameState.new_game()
	GameState.seen_tutorial_ids.assign(GameData.get_starting_setup().tutorial.get_all_ids())
	var garden: Node = await _open(GARDEN_SCENE)
	check(not garden._village_button.visible, "1일째: 마을 길 버튼 없음")
	await _close(garden)
	GameState.current_day = 2
	garden = await _open(GARDEN_SCENE)
	check(garden._village_button.visible, "2일째: 마을 길 버튼 있음")
	check(garden._status_text.contains(settings.unlocked_text), "2일째: 마을 길이 열렸다는 안내 한 줄")
	await _close(garden)

	# 2) 토끼만 만났으면 토끼 집만 열리고 나머지는 "?"
	var rabbit: AnimalGuest = GameData.get_guest(&"rabbit")
	GameState.record_served_guest(&"rabbit")
	var village: Node = await _open(VILLAGE_SCENE)
	var buttons: Array[Button] = _home_buttons(village)
	check(buttons.size() == guests.size(), "집 버튼이 손님 수만큼 (%d)" % buttons.size())
	var rabbit_index: int = guests.find(rabbit)
	var others_hidden: bool = true
	for i: int in buttons.size():
		if i != rabbit_index and (not buttons[i].disabled or buttons[i].text != settings.unknown_home_text):
			others_hidden = false
	check(not buttons[rabbit_index].disabled and buttons[rabbit_index].text == rabbit.home_name, "만난 토끼 집은 열림")
	check(others_hidden, "못 만난 손님 집은 \"?\"로 막힘")

	# 3) 토끼 집: 인사 → 이야기 → 대답 → 선물(당근, 좋아하는 선물)
	GameState.add_ingredient(&"carrot", 10)
	GameState.add_ingredient(&"egg", 10)
	var carrots: int = GameState.get_ingredient_count(&"carrot")
	var affection: int = GameState.get_affection(&"rabbit")
	buttons[rabbit_index].pressed.emit()
	check(village._next_button.visible and not village._home_row.visible, "집에 들어가면 인사 뒤 다음 버튼")
	village._on_next_pressed()
	check(village._current_talk == rabbit.home_talks[0] and village._reply_box.visible, "첫 방문: 첫 번째 집 이야기와 대답 버튼")
	village._on_talk_reply(0)
	village._on_next_pressed()
	var carrot_index: int = village._gift_choices.find(rabbit.favorite_gift)
	check(carrot_index >= 0, "선물 고르기에 당근이 있음")
	check(village._reply_box.get_child_count() == village._gift_choices.size() + 1, "선물 고르기 맨 아래에 선물 없이 가기")
	village._on_gift_chosen(carrot_index)
	check(GameState.get_ingredient_count(&"carrot") == carrots - settings.gift_amount, "당근 %d개가 줄어듦" % settings.gift_amount)
	check(GameState.get_affection(&"rabbit") == affection + settings.favorite_gift_points, "좋아하는 선물: 단골도 +%d" % settings.favorite_gift_points)
	check(village._back_button.visible, "선물 뒤 돌아가기 버튼")
	check(not GameState.can_visit_home_today(), "오늘은 더 들를 수 없음")
	await _close(village)

	# 4) 같은 날 다시 오면 모든 집이 막혀 있다.
	village = await _open(VILLAGE_SCENE)
	check(_home_buttons(village).all(func(button: Button) -> bool: return button.disabled), "같은 날 다시 오면 모든 집이 막힘")
	check(village._status_label.text == settings.visited_text, "같은 날: 벌써 다녀왔다는 글")
	await _close(village)

	# 5) 다음 날: 다시 들를 수 있고, 두 번째 이야기. 좋아하지 않는 선물은 +gift_points, 선물 없이도 갈 수 있다.
	GameState.advance_day()
	check(GameState.can_visit_home_today(), "다음 날: 다시 들를 수 있음")
	village = await _open(VILLAGE_SCENE)
	affection = GameState.get_affection(&"rabbit")
	_home_buttons(village)[rabbit_index].pressed.emit()
	village._on_next_pressed()
	check(village._current_talk == rabbit.home_talks[1 % rabbit.home_talks.size()], "두 번째 방문: 다음 집 이야기")
	village._on_talk_reply(1)
	village._on_next_pressed()
	village._on_gift_chosen(village._gift_choices.find(GameData.get_ingredient(&"egg")))
	check(GameState.get_affection(&"rabbit") == affection + settings.gift_points, "다른 선물: 단골도 +%d" % settings.gift_points)
	await _close(village)
	GameState.advance_day()
	village = await _open(VILLAGE_SCENE)
	affection = GameState.get_affection(&"rabbit")
	var eggs: int = GameState.get_ingredient_count(&"egg")
	_home_buttons(village)[rabbit_index].pressed.emit()
	village._on_next_pressed()
	village._on_talk_reply(0)
	village._on_next_pressed()
	village._on_gift_chosen(village._gift_choices.size())
	check(GameState.get_affection(&"rabbit") == affection and GameState.get_ingredient_count(&"egg") == eggs, "선물 없이 가기: 단골도·재료 그대로")
	check(village._back_button.visible, "선물 없이 가도 돌아가기 버튼")
	await _close(village)

	# 6) 세이브: 방문 횟수가 저장되고 불러와진다. 오늘 들른 집은 저장하지 않는다.
	var saved: Dictionary = GameState._to_save_data()
	check(int(saved.get("home_visit_counts", {}).get("rabbit", 0)) == 3, "세이브: 토끼 집 3번 들른 것이 저장됨")
	GameState._from_save_data(JSON.parse_string(JSON.stringify(saved)))
	check(GameState.home_visit_counts.get(&"rabbit", 0) == 3, "불러오기: 토끼 집 방문 3번")
	check(GameState.todays_visited_home_ids.is_empty(), "불러오기: 오늘 들른 집은 비어 있음")

	# 7) 옛 세이브(마을 길 전): 방문 기록이 없어도 쓸 수 있고 0번으로 읽는다.
	saved.erase("home_visit_counts")
	var old_save: Dictionary = JSON.parse_string(JSON.stringify(saved))
	check(GameState._is_usable_save(old_save), "옛 세이브: 쓸 수 있는 세이브로 봄")
	GameState._from_save_data(old_save)
	check(GameState.home_visit_counts.is_empty(), "옛 세이브: 방문 기록 없음 (0번)")
