extends Node
## 시나리오 시험: 썰기는 하얀 칸에 칼을 대야만 썰린다 (칸 밖은 톡 치기만, 손해 없음). 칸 안에서 다 썰면 끝난다.
## 쓰는 법: tools/check/run.sh chop_target  (시험용 사본에 오토로드로 붙여 돌린다. 끝 코드 = 실패 수)

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
	var recipe: Recipe = GameData.get_recipe(&"carrot_kimbop")
	var step: CookStep = null
	for s: CookStep in recipe.cook_steps:
		if s.type == Recipe.MinigameType.CHOP:
			step = s
			break
	check(step != null, "당근 김밥에 썰기 단계가 있음")
	if step == null:
		return
	var mg: ChopMinigame = (load("res://scenes/kitchen/minigames/chop_minigame.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(mg)
	mg.start(recipe, step)
	for i: int in 600:
		if mg._is_playing:
			break
		await get_tree().process_frame
	check(mg._is_playing, "준비~ 시작! 뒤에 썰기가 시작됨")
	check(mg._target_width <= mg._even_width, "하얀 칸이 한 조각 폭보다 넓지 않음 (%.1f ≤ %.1f)" % [mg._target_width, mg._even_width])
	var width_before: float = mg._ingredient.size.x
	# 재료 위지만 하얀 칸 왼쪽 밖
	mg._knife_x = mg._target_center - mg._target_width / 2.0 - 15.0
	mg._chop_time_left = 0.0
	mg._chop()
	check(mg._chop_count == 0, "하얀 칸 밖에서 누르면 안 썰림")
	check(is_equal_approx(mg._ingredient.size.x, width_before), "칸 밖에서 눌러도 재료 길이 그대로")
	check(mg._progress_label.text == ChopMinigame.OFF_TARGET_TEXT, "칸 밖이면 '하얀 칸에 칼을 대고 썰어요' 안내")
	# 하얀 칸 가운데로 끝까지
	var needed: int = mg._chops_needed
	for i: int in needed:
		mg._knife_x = mg._target_center
		mg._chop_time_left = 0.0
		mg._chop()
	check(mg._chop_count == needed, "하얀 칸 안에서 %d번 썰면 %d조각 (실제 %d)" % [needed, needed, mg._chop_count])
	for i: int in 30:
		await get_tree().process_frame
	check(not mg._is_playing, "다 썰면 썰기가 끝남")
	mg.queue_free()
