extends Node
## 시나리오 시험: 손님 수첩 "하나씩 알아 가기"
## (좋아하는 요리는 대접해야 한 칸씩, 싫어하는 요리는 대접했거나 이웃이 되면, 알아낸 것 숫자와 ★, 세이브 유지·옛 세이브 호환,
##  새로 적히면 기록 수가 늘고 수첩 버튼에 새 기록 표시 ●).
## 쓰는 법: tools/check/run.sh notebook_known_dishes  (시험용 사본에 오토로드로 붙여 돌린다. 끝 코드 = 실패 수)

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


func _run() -> void:
	GameState.new_game()
	for r: Recipe in GameData.get_all_recipes():
		GameState.unlock_recipe(r.id)
	var bear: AnimalGuest = GameData.get_guest(&"bear")
	var hen: AnimalGuest = GameData.get_guest(&"hen")
	var liked: Recipe = bear.favorite_recipes[0]
	var disliked: Recipe = bear.disliked_recipes[0]
	GameState.met_guest_ids.append(bear.id)

	var book: GuestNotebook = (load("res://scenes/ui/guest_notebook.tscn") as PackedScene).instantiate()
	add_child(book)
	await get_tree().process_frame
	book.open()
	book._show_guest(bear)
	check(book._likes_label.text.count("???") == bear.favorite_recipes.size(), "처음: 좋아하는 요리 모두 ??? (%s)" % book._likes_label.text)
	check("???" in book._dislikes_label.text and "이웃" in book._dislikes_label.text, "처음: 싫어하는 요리 ??? + 이웃 힌트 (%s)" % book._dislikes_label.text)
	var before: Vector2i = book._get_knowledge(bear)
	check(before.x == 1, "처음: 알아낸 것 1칸 (성격·밥값) — %s" % before)

	GameState.mark_notebook_viewed()
	var entries_before: int = GameState.count_notebook_entries()
	GameState.record_guest_dish(bear.id, liked.id)
	check(GameState.count_notebook_entries() == entries_before + 1, "좋아하는 요리를 알아내면 수첩 기록 수가 늘어남 (알림 조건)")
	check(GameState.has_unviewed_notebook_entries(), "새로 적히면 수첩 버튼에 ● 표시")
	GameState.mark_notebook_viewed()
	var not_favorite: Recipe = null
	for r: Recipe in GameData.get_all_recipes():
		if r not in bear.favorite_recipes and r not in bear.disliked_recipes:
			not_favorite = r
	GameState.record_guest_dish(bear.id, not_favorite.id)
	check(GameState.count_notebook_entries() == entries_before + 1 and not GameState.has_unviewed_notebook_entries(),
			"좋아하지도 싫어하지도 않는 요리는 수첩에 새로 적히지 않음 (알림 없음)")
	GameState.guest_known_dish_ids[bear.id].erase(not_favorite.id)
	book._show_guest(bear)
	check(liked.display_name in book._likes_label.text.replace("\n", " "), "대접한 좋아하는 요리가 적힘")
	check(book._likes_label.text.count("???") == bear.favorite_recipes.size() - 1, "나머지는 ??? 그대로")
	check(book._get_knowledge(bear).x == 2, "알아낸 것 하나 늘어남")
	GameState.record_guest_dish(bear.id, liked.id)
	check(GameState.guest_known_dish_ids[bear.id].size() == 1, "같은 요리를 두 번 대접해도 한 번만 적힘")

	var settings: RegularSettings = GameData.get_regular_settings()
	var entries_before_tier: int = GameState.count_notebook_entries()
	GameState.add_affection(bear.id, settings.tier_thresholds[settings.dislike_reveal_tier])
	check(GameState.count_notebook_entries() == entries_before_tier + bear.disliked_recipes.size(), "이웃이 되면 싫어하는 요리가 새 기록으로 늘어남 (알림 조건)")
	book._show_guest(bear)
	check(disliked.display_name in book._dislikes_label.text.replace("\n", " ") and "???" not in book._dislikes_label.text,
			"이웃이 되면 싫어하는 요리를 털어놓음 (%s)" % book._dislikes_label.text)
	check(GameState.knows_guest_dislike(hen.id, hen.disliked_recipes[0].id) == false, "다른 손님(암탉) 싫어하는 요리는 아직 모름")
	GameState.record_guest_dish(hen.id, hen.disliked_recipes[0].id)
	check(GameState.knows_guest_dislike(hen.id, hen.disliked_recipes[0].id), "싫어하는 요리를 대접해 봐도 적힘")

	# 다 알아내면 ★
	for r: Recipe in bear.favorite_recipes:
		GameState.record_guest_dish(bear.id, r.id)
	GameState.learn_taste(bear.id)
	for r: Recipe in GameData.get_all_recipes():
		if r.secret_teller_id == bear.id:
			GameState.learned_secret_ids.append(r.id)
	var full: Vector2i = book._get_knowledge(bear)
	check(full.x == full.y, "다 알아냄 %s" % full)
	book.open()
	var bear_button: Button = null
	for b: Node in book._guest_list.get_children():
		if (b as Button).text.begins_with(bear.display_name):
			bear_button = b
	check(bear_button != null and bear_button.text.ends_with(GuestNotebook.COMPLETE_MARK), "목록에 ★ (%s)" % (bear_button.text if bear_button else "없음"))
	book.close()

	# 저장·불러오기
	var data: Dictionary = JSON.parse_string(JSON.stringify(GameState._to_save_data()))
	check(GameState._is_usable_save(data), "세이브: 새 세이브 모양 검사 통과")
	GameState._from_save_data(data)
	check(GameState.knows_guest_dish(bear.id, liked.id) and GameState.guest_known_dish_ids[bear.id].size() == bear.favorite_recipes.size(),
			"세이브: 불러온 뒤에도 적힌 요리 유지")
	check(not GameState.knows_guest_dish(hen.id, hen.favorite_recipes[0].id), "세이브: 안 적힌 요리는 그대로 모름")

	# 옛 세이브 (기록 칸 없음): 만난 손님의 좋아하는/싫어하는 요리를 모두 아는 것으로
	data.erase("guest_known_dish_ids")
	data["met_guest_ids"] = ["bear", "hen"]
	check(GameState._is_usable_save(data), "옛 세이브(항목 없음): 상한 세이브로 보지 않음")
	GameState._from_save_data(data)
	var all_known: bool = true
	for guest: AnimalGuest in [bear, hen]:
		for r: Recipe in guest.favorite_recipes + guest.disliked_recipes:
			all_known = all_known and GameState.knows_guest_dish(guest.id, r.id)
	check(all_known, "옛 세이브: 만난 손님의 좋아하는/싫어하는 요리가 모두 적힘")
	var unviewed: Array[String] = GameState._notebook_keys().filter(func(key: String) -> bool:
			return (key.begins_with("like:") or key.begins_with("dislike:")) and key not in GameState.notebook_viewed_keys)
	check(unviewed.is_empty(), "옛 세이브: 원래 보이던 요리 칸으로 ● 를 켜지 않음 (%s)" % [unviewed])
	var rabbit: AnimalGuest = GameData.get_guest(&"rabbit")
	check(not GameState.knows_guest_dish(rabbit.id, rabbit.favorite_recipes[0].id), "옛 세이브: 안 만난 손님은 비어 있음")
	GameState.new_game()
