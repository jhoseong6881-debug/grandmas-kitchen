extends Node
## 시나리오 시험: 밥 짓기 불 조절(가마솥 3단 불). 센불 → 끓어오르면(뚜껑 두 번 들썩) 중불 → 약불로 뜸 → 완성.
## 단계에 안 맞는 불이면 진행만 멈추고(실패 없음), 맞추면 다시 진행한다.
## 쓰는 법: tools/check/run.sh rice_fire  (시험용 사본에 오토로드로 붙여 돌린다. 끝 코드 = 실패 수)

var fails: int = 0
var mg: RiceMinigame


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


## 손잡이를 knob 에 두고, 단계가 stage 가 될 때까지(또는 limit 초) 기다린다.
func _hold_until_stage(knob: float, stage: RiceMinigame.CookStage, limit: float) -> bool:
	var t: float = 0.0
	while t < limit:
		mg._knob = knob
		if mg._cook_stage == stage and not mg._is_lid_hopping:
			return true
		await get_tree().process_frame
		t += get_process_delta_time()
	return false


func _run() -> void:
	var recipe: Recipe = GameData.get_recipe(&"carrot_kimbop")
	var step: CookStep = null
	for s: CookStep in recipe.cook_steps:
		if s.type == Recipe.MinigameType.COOK_RICE:
			step = s
			break
	mg = (load("res://scenes/kitchen/minigames/rice_minigame.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(mg)
	mg.start(recipe, step)
	for i: int in 600:
		if mg._is_playing:
			break
		await get_tree().process_frame
	mg._start_cooking()
	check(mg._cook_stage == RiceMinigame.CookStage.BOIL, "불 조절은 센불부터")
	check(mg._side_label.text.ends_with("센불"), "옆 글에 '센불' (%s)" % mg._side_label.text)

	mg._knob = 0.15
	await _wait(1.0)
	check(is_zero_approx(mg._stage_progress), "센불 단계에서 약불이면 진행 안 됨")
	check(mg._progress_label.text == RiceMinigame.COOK_STAGE_TEXTS[0][RiceMinigame.Heat.LOW], "'처음엔 센불로!' 안내")

	var boiled: bool = await _hold_until_stage(0.9, RiceMinigame.CookStage.SIMMER, 8.0)
	check(boiled, "센불로 두면 끓어올라 중불 단계로 넘어감")
	check(mg._side_label.text.ends_with("중불"), "옆 글에 '중불'")

	mg._knob = 0.9
	await _wait(1.2)
	check(mg._stage_progress < 0.05, "중불 단계에서 센불 그대로면 진행 멈춤 (%.2f)" % mg._stage_progress)
	check(mg._heat_state == RiceMinigame.Heat.HIGH, "센불 그대로면 '넘치려 해요' 상태")
	check(mg._is_playing, "넘치려 해도 실패 없이 계속")

	var simmered: bool = await _hold_until_stage(0.5, RiceMinigame.CookStage.REST, 8.0)
	check(simmered, "가운데(중불)로 두면 약불 뜸 단계로 넘어감")

	mg._knob = 0.5
	await _wait(1.0)
	check(mg._stage_progress < 0.05, "뜸 단계에서 중불이면 진행 멈춤")

	var t: float = 0.0
	while mg._is_playing and t < 8.0:
		mg._knob = 0.18
		await get_tree().process_frame
		t += get_process_delta_time()
	check(not mg._is_playing, "약불로 두면 밥이 다 됨")
	check(mg._cook_progress >= 0.99, "밥 짓기 막대가 다 참 (%.2f)" % mg._cook_progress)
	mg.queue_free()
