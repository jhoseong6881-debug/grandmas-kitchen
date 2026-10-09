extends Node
## 시나리오 시험: 메뉴판이 번진 노트 요리를 권할 때 플레이어 선택을 존중하는지
## (재료가 있는데 직접 빼면 다시 안 넣음, 재료가 없어 뺀 것은 다시 권함, 뒤로 나가면 기록 안 함, 세이브 유지·옛 세이브 호환).
## 쓰는 법: tools/check/run.sh menu_note_suggest  (시험용 사본에 오토로드로 붙여 돌린다. 끝 코드 = 실패 수)

var fails: int = 0
var confirmed_ids: Array[StringName] = []


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


func _run() -> void:
	GameState.new_game()
	GameState.current_day = 5
	for r: Recipe in GameData.get_all_recipes():
		GameState.unlock_recipe(r.id)
		for ing: StringName in r.get_ingredient_counts():
			GameState.add_ingredient(ing, 99)
	var ids: Array[StringName] = GameState.unlocked_recipe_ids.duplicate()
	var p_new: StringName = ids[-1]
	var p_old: StringName = ids[-2]
	for id: StringName in ids:
		if id != p_new and id != p_old:
			GameState.solve_note_puzzle(id)
	check(NotePuzzleBoard.is_waiting_today(GameData.get_recipe(p_new)) and NotePuzzleBoard.is_waiting_today(GameData.get_recipe(p_old)), "준비: 퍼즐 요리 둘 (%s, %s)" % [p_new, p_old])
	var slots: int = GameState.get_menu_slots()
	check(slots < ids.size(), "준비: 메뉴 칸 %d < 레시피 %d" % [slots, ids.size()])
	GameState.menu_recipe_ids.assign(ids.slice(0, slots))
	check(p_new not in GameState.menu_recipe_ids and p_old not in GameState.menu_recipe_ids, "준비: 어제 메뉴가 퍼즐 없는 요리로 꽉 참")

	var board: MenuBoard = load("res://scenes/garden/menu_board.tscn").instantiate()
	add_child(board)
	await get_tree().process_frame
	board.confirmed.connect(func(confirmed: Array[StringName]) -> void: confirmed_ids = confirmed)

	# 5일째: 가장 최근 퍼즐 요리를 권한다. "뒤로"로 나가면 기록하지 않는다.
	board.open()
	check(p_new in board._selected_ids, "5일째: 새 퍼즐 요리를 미리 올림")
	check(board._selected_ids.size() == slots, "5일째: 칸 수 그대로 (%d)" % board._selected_ids.size())
	board._on_back_button_pressed()
	check(not GameState.is_note_puzzle_declined(p_new), "5일째: 뒤로 나가면 '뺌' 기록 안 함")
	board.open()
	check(p_new in board._selected_ids, "5일째: 다시 열어도 같은 제안")
	# 플레이어가 빼고 장사 시작
	board._toggle(p_new)
	board._on_start_button_pressed()
	check(p_new not in confirmed_ids and not confirmed_ids.is_empty(), "5일째: 뺀 메뉴로 장사 시작")
	check(GameState.is_note_puzzle_declined(p_new), "5일째: 재료가 있는데 빼고 확정하면 '뺌' 기록")

	# 6일째: 뺀 요리는 다시 안 넣고, 아직 안 권한 다른 퍼즐 요리를 권한다. 이번엔 그대로 둔다.
	GameState.current_day = 6
	GameState.menu_recipe_ids = confirmed_ids
	board.open()
	check(p_new not in board._selected_ids, "6일째: 뺀 요리를 다시 밀어 넣지 않음")
	check(p_old in board._selected_ids, "6일째: 다른 퍼즐 요리는 한 번 권함")
	board._on_start_button_pressed()
	check(not GameState.is_note_puzzle_declined(p_old), "6일째: 그대로 두면 '뺌' 기록 안 함")

	# 7일째: 그대로 둔 요리는 어제 메뉴라서 남는다. 이번엔 뺀다.
	GameState.current_day = 7
	GameState.menu_recipe_ids = confirmed_ids
	board.open()
	check(p_old in board._selected_ids, "7일째: 남겨 둔 퍼즐 요리는 계속 메뉴에")
	board._toggle(p_old)
	board._on_start_button_pressed()

	# 9일째: 둘 다 권했으니 아무것도 밀어 넣지 않는다. 줄 표시는 그대로 보인다.
	GameState.current_day = 9
	GameState.menu_recipe_ids = confirmed_ids
	var before: Array[StringName] = confirmed_ids.duplicate()
	board.open()
	check(p_new not in board._selected_ids and p_old not in board._selected_ids, "9일째: 뺀 퍼즐 요리 둘 다 다시 안 들어옴 (%s)" % [board._selected_ids])
	check(before.all(func(id: StringName) -> bool: return id in board._selected_ids), "9일째: 어제 고른 요리는 모두 그대로")
	check(board._note_tag_labels.has(p_new) and board._note_tag_labels[p_new].text == MenuBoard.NOTE_PUZZLE_TAG, "9일째: 뺀 요리 줄에 '번진 할머니 노트' 표시는 남음")
	# 플레이어가 다시 고를 수 있다
	board._toggle(before[-1])
	board._toggle(p_new)
	check(p_new in board._selected_ids, "9일째: 뺀 퍼즐 요리를 직접 다시 고를 수 있음")
	board._on_back_button_pressed()

	# 하루에 퍼즐 요리 둘이 빈 칸 채우기로 함께 올라가면 둘 다 "권함"으로 기록한다 (둘 다 빼면 둘 다 다시 안 넣음).
	GameState.declined_note_puzzle_ids.clear()
	GameState.current_day = 10
	GameState.menu_recipe_ids.assign(ids.slice(0, slots - 2))
	board.open()
	check(p_new in board._selected_ids and p_old in board._selected_ids, "10일째: 빈 칸 둘에 퍼즐 요리 둘이 함께 올라감")
	board._toggle(p_new)
	board._toggle(p_old)
	board._on_start_button_pressed()
	check(GameState.is_note_puzzle_declined(p_new) and GameState.is_note_puzzle_declined(p_old), "10일째: 둘 다 '뺌' 기록")
	GameState.current_day = 12
	GameState.menu_recipe_ids = confirmed_ids
	board.open()
	check(p_new not in board._selected_ids and p_old not in board._selected_ids, "12일째: 뺀 둘 다 다시 안 들어옴")
	board._on_back_button_pressed()

	# 재료가 없어서 어쩔 수 없이 뺀 요리는 선택이 아니다: 기록하지 않고, 재료가 생기면 다시 권한다.
	var saved_declined: Array[StringName] = GameState.declined_note_puzzle_ids.duplicate()
	GameState.declined_note_puzzle_ids.clear()
	GameState.current_day = 3
	GameState.menu_recipe_ids.assign(ids.slice(0, slots))
	var saved_inventory: Dictionary[StringName, int] = GameState.inventory.duplicate()
	for ing: StringName in GameData.get_recipe(p_old).get_ingredient_counts():
		GameState.inventory[ing] = 0
	board.open()
	# 장사를 시작하려면 재료가 모자란 요리를 빼야 한다 (봇과 같은 행동)
	board._selected_ids = board._selected_ids.filter(func(id: StringName) -> bool:
			return GameState.has_ingredients(GameData.get_recipe(id).get_ingredient_counts()))
	var had_p_old_short: bool = not GameState.has_ingredients(GameData.get_recipe(p_old).get_ingredient_counts())
	board._on_start_button_pressed()
	check(had_p_old_short and not GameState.is_note_puzzle_declined(p_old), "3일째: 재료가 없어 뺀 요리는 '뺌' 기록 안 함")
	GameState.inventory = saved_inventory
	GameState.current_day = 4
	GameState.menu_recipe_ids = confirmed_ids
	board.open()
	check(p_old in board._selected_ids or p_new in board._selected_ids, "4일째: 재료가 생기면 퍼즐 요리를 다시 권함 (%s)" % [board._selected_ids])
	board._on_back_button_pressed()
	GameState.declined_note_puzzle_ids = saved_declined

	# 저장·불러오기
	var data: Dictionary = JSON.parse_string(JSON.stringify(GameState._to_save_data()))
	check(GameState._is_usable_save(data), "세이브: 새 세이브 모양 검사 통과")
	GameState._from_save_data(data)
	check(GameState.is_note_puzzle_declined(p_new) and GameState.is_note_puzzle_declined(p_old), "세이브: 불러온 뒤에도 '뺌' 기록 유지")
	data.erase("declined_note_puzzle_ids")
	check(GameState._is_usable_save(data), "옛 세이브(항목 없음): 상한 세이브로 보지 않음")
	GameState._from_save_data(data)
	check(GameState.declined_note_puzzle_ids.is_empty() and GameState.current_day == int(data["current_day"]), "옛 세이브: 빈 기록으로 정상 불러옴 (%d일째)" % GameState.current_day)
