extends Node
## 시나리오 시험: 아침 마을 길 (손님 집 마실).
## 열리는 날, 못 만난 손님 집은 "?"로 막힘, 하루 한 집, 좋아하는 선물이면 단골도가 더 오름,
## 선물 없이 가기, 방문 횟수 세이브, 옛 세이브(방문 기록 없음) 불러오기.
## 마을 지도: 집이 데이터의 지도 자리에 놓임, 단골 하트, 오늘 들른 집 도장, 십자키로 방향에 맞는 집으로 이동.
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
	for child: Node in village._home_map.get_children():
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
	var on_spot: bool = true
	for i: int in buttons.size():
		if buttons[i].get_rect().get_center().distance_to(guests[i].home_map_position * village.map_scale) > 1.0:
			on_spot = false
	check(on_spot, "집 버튼이 손님 데이터의 지도 자리에 놓임")
	check(buttons[rabbit_index].get_child_count() == 1 and buttons[rabbit_index].get_child(0) is Label \
			and (buttons[rabbit_index].get_child(0) as Label).text.begins_with(village.HEART_EMPTY), "만난 토끼 집에 빈 하트(낯선 손님)")
	check(buttons.filter(func(b: Button) -> bool: return b.get_child_count() > 0).size() == 1, "못 만난 집에는 하트 없음")
	check(village._map._home_points.size() == guests.size() and village._map._home_known[rabbit_index], "지도에 집마다 점선 길 (토끼 길은 진하게)")

	# 3) 토끼 집: 인사 → 이야기 → 대답 → 선물(당근, 좋아하는 선물)
	GameState.add_ingredient(&"carrot", 10)
	GameState.add_ingredient(&"egg", 10)
	var carrots: int = GameState.get_ingredient_count(&"carrot")
	var affection: int = GameState.get_affection(&"rabbit")
	buttons[rabbit_index].pressed.emit()
	check(village._next_button.visible and not village._home_map.visible, "집에 들어가면 인사 뒤 다음 버튼")
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
	var stamps: Array = _home_buttons(village)[rabbit_index].get_children().filter(
			func(c: Node) -> bool: return c is Label and (c as Label).text == settings.visited_stamp_text)
	check(stamps.size() == 1, "오늘 들른 토끼 집에 도장")
	check(village._back_button.has_focus(), "모두 막혔으면 돌아가기 버튼에 초점")
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

	# 5-1) 다 만났을 때 게임패드 십자키: 방향에 맞는 집으로, 아래쪽에 집이 없으면 돌아가기 버튼
	GameState.advance_day()
	for guest: AnimalGuest in guests:
		GameState.record_served_guest(guest.id)
	village = await _open(VILLAGE_SCENE)
	buttons = _home_buttons(village)
	var by_id: Dictionary = {}
	for i: int in guests.size():
		by_id[guests[i].id] = buttons[i]
	check(buttons.all(func(b: Button) -> bool: return not b.disabled and b.focus_mode == Control.FOCUS_ALL), "다 만났으면 집 5채 모두 열림")
	var rabbit_button: Button = by_id[&"rabbit"]
	var neighbor: Callable = func(b: Control, side: Side) -> Node: return b.get_node(b.get_focus_neighbor(side))
	check(neighbor.call(rabbit_button, SIDE_RIGHT) == by_id[&"hen"], "토끼 집에서 → : 암탉 집")
	check(neighbor.call(rabbit_button, SIDE_BOTTOM) == by_id[&"bear"], "토끼 집에서 ↓ : 곰 집")
	check(neighbor.call(by_id[&"bear"], SIDE_BOTTOM) == village._back_button, "곰 집에서 ↓ : 돌아가기 버튼")
	check(neighbor.call(by_id[&"squirrel"], SIDE_LEFT) == by_id[&"hen"], "다람쥐 집에서 ← : 암탉 집")
	check(neighbor.call(by_id[&"hedgehog"], SIDE_TOP) == by_id[&"squirrel"], "고슴도치 집에서 ↑ : 다람쥐 집")
	var up_from_back: Node = neighbor.call(village._back_button, SIDE_TOP)
	check(up_from_back in buttons, "돌아가기 버튼에서 ↑ : 집으로 (%s)" % (up_from_back as Button).text)
	var all_focus_ok: bool = true
	for b: Button in buttons:
		for side: int in 4:
			var target: Node = neighbor.call(b, side as Side)
			if target != b and target != village._back_button and target not in buttons:
				all_focus_ok = false
	check(all_focus_ok, "십자키가 집과 돌아가기 버튼 밖으로 빠지지 않음")
	var on_screen: bool = true
	for b: Button in buttons:
		var r: Rect2 = b.get_global_rect()
		if r.position.y < 96.0 or r.end.y + 40.0 > village._back_button.get_global_rect().position.y + 1.0 and absf(r.get_center().x - 960.0) < 300.0:
			on_screen = false
	check(on_screen, "집이 날짜 글 아래, 돌아가기 버튼과 안 겹침")
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
