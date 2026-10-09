extends Node
## 시나리오 시험: 밥 짓기 물 맞추기는 눈금의 밝은 칸(알맞은 물) 안에서 떼야 넘어간다.
## 너무 많으면 물을 따라 내고 다시 받고(손해 없음), 모자라면 "조금 더 부어요", 알맞으면 불 조절로 넘어간다.
## 쓰는 법: tools/check/run.sh rice_water  (시험용 사본에 오토로드로 붙여 돌린다. 끝 코드 = 실패 수)

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


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _run() -> void:
	var recipe: Recipe = GameData.get_recipe(&"carrot_kimbop")
	var step: CookStep = null
	for s: CookStep in recipe.cook_steps:
		if s.type == Recipe.MinigameType.COOK_RICE:
			step = s
			break
	check(step != null, "당근 김밥에 밥 짓기 단계가 있음")
	if step == null:
		return
	var mg: RiceMinigame = (load("res://scenes/kitchen/minigames/rice_minigame.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(mg)
	mg.start(recipe, step)
	for i: int in 600:
		if mg._is_playing:
			break
		await get_tree().process_frame
	check(mg._is_playing, "준비~ 시작! 뒤에 밥 짓기가 시작됨")
	# 쌀 씻기는 건너뛰고 바로 물 맞추기
	mg._start_watering()
	check(mg._phase == RiceMinigame.Phase.WATERING, "물 맞추기 단계")
	check(mg.water_min_level <= 0.3 and mg.water_max_level >= 0.7, "할머니 비법 자리(0.3~0.7)가 알맞은 물 칸 안")
	check(mg.water_min_level <= 0.15 and mg.water_max_level >= 0.45, "포슬포슬 부탁 자리(0.15~0.45)가 알맞은 물 칸 안")

	# 너무 많이 붓고 뗌
	mg._water_level = 0.95
	mg._has_poured = true
	mg._is_pouring_water = false
	await _wait(mg.water_settle_time + 0.2)
	check(mg._progress_label.text == RiceMinigame.WATER_POUR_OFF_TEXT, "넘치게 붓고 떼면 '따라 내고 다시 받아요'")
	await _wait(mg.water_pour_off_time + 0.3)
	check(mg._phase == RiceMinigame.Phase.WATERING, "넘쳐도 다음 단계로 안 넘어가고 물 맞추기 그대로")
	check(is_zero_approx(mg._water_level), "넘친 물은 다 따라 냄 (물 높이 %.2f)" % mg._water_level)

	# 모자라게 붓고 뗌
	mg._water_level = 0.08
	mg._has_poured = true
	await _wait(mg.water_settle_time + 0.2)
	check(mg._phase == RiceMinigame.Phase.WATERING and mg._progress_label.text == RiceMinigame.WATER_MORE_TEXT,
			"모자라면 '조금 더 부어요' 하고 기다림")

	# 알맞게
	mg._water_level = 0.5
	mg._has_poured = true
	await _wait(mg.water_settle_time + 0.2)
	check(mg._phase != RiceMinigame.Phase.WATERING, "알맞은 물(손등 0.5)에서 떼면 불 조절로 넘어감")
	mg.queue_free()
