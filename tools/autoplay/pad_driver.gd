extends Node
## 게임패드(A·B·십자키) 입력만 보내서 봄 한 철을 끝까지 가 본다. 막히는 화면을 기록한다.
## 막히면 기록한 뒤 버튼을 직접 눌러 다음으로 넘어간다 (뒤쪽 화면도 계속 점검하려고).
## 시험용 사본에서 오토로드로 붙여 돌린다 (tools/autoplay/run.sh). 진짜 프로젝트에 붙이지 말 것.
## 미니게임은 왼쪽 스틱을 빙글빙글 돌리고, 가끔 오른쪽으로 밀고, A 를 눌렀다 뗀다 (손으로 다루는 미니게임이라 박자는 없다).

const PROGRESS: Array[String] = ["장사 시작", "요리 고르기", "요리하기", "마무리하고 대접하기", "다음 손님", "도시락 싸기",
	"도시락 건네기", "평상으로 가기", "계속하기", "다음", "잠자리에 들기", "닫기", "부엌으로 가기", "← 텃밭으로", "요리 시작"]
## 미니게임 하나를 게임패드로 해 보는 최대 틱 수 (0.1초마다 한 틱). 넘으면 도구가 대신 끝내고 기록한다.
const MINIGAME_TICK_LIMIT: int = 600
## 스틱 방향을 한 틱에 바꾸는 각도(라디안). 작을수록 손이 넓게 돌아다닌다 (크면 제자리에서 작은 원만 그린다), 오른쪽으로 미는 구간 (틱 주기와 길이), A 를 누르고 있는 틱 수와 뗀 틱 수
const STICK_TURN: float = 0.15
const PUSH_RIGHT_PERIOD: int = 40
const PUSH_RIGHT_TICKS: int = 12
const A_HOLD_TICKS: int = 3
const A_REST_TICKS: int = 3

var log_path: String = ""
var lines: Array[String] = []
var issues: Dictionary = {}
var _finished: bool = false
var _start_ms: int = 0
var _last_key: String = ""
var _same_ticks: int = 0
var _a_on_same: int = 0
var _last_focus: Control
var _seek_left: int = 0
var _seek_target: String = ""
var _market_trades: int = 0
var _market_day: int = -1
var _busy: bool = false
var _no_focus_ticks: int = 0
var _mg_presses: Dictionary = {}
var _mg_first_sig: Dictionary = {}
var _mg_changed: Dictionary = {}
var _tool_limit: int = 0
## 미니게임 종류별: 게임패드만으로 끝난 횟수, 도구가 대신 끝낸 횟수
var _mg_done_by_pad: Dictionary = {}
var _mg_done_by_tool: Dictionary = {}
var _mg_ticks: Dictionary = {}
var _stick_angle: float = 0.0
var _a_held: bool = false
var _stick_active: bool = false

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	log_path = args[0] if args.size() > 0 else "user://pad_log.txt"
	seed(int(args[1]) if args.size() > 1 else 5)
	Engine.time_scale = 8.0
	_start_ms = Time.get_ticks_msec()
	var accept_events: Array = InputMap.action_get_events(&"ui_accept").map(func(e: InputEvent) -> String: return e.as_text())
	lines.append("ui_accept 에 연결된 입력: %s" % ", ".join(accept_events))
	lines.append("ui_cancel 에 연결된 입력: %s" % ", ".join(InputMap.action_get_events(&"ui_cancel").map(func(e: InputEvent) -> String: return e.as_text())))
	lines.append("ui_down 에 연결된 입력: %s" % ", ".join(InputMap.action_get_events(&"ui_down").map(func(e: InputEvent) -> String: return e.as_text())))
	await get_tree().process_frame
	await get_tree().process_frame
	GameState.start_new_game()
	GameState.is_game_started = true
	GameState.player_name = "철수"
	get_tree().change_scene_to_file("res://scenes/garden/garden.tscn")
	var timer: Timer = Timer.new()
	timer.wait_time = 0.1
	timer.ignore_time_scale = true
	timer.timeout.connect(_tick)
	add_child(timer)
	timer.start()

func _press(button: JoyButton) -> void:
	var down: InputEventJoypadButton = InputEventJoypadButton.new()
	down.button_index = button
	down.pressed = true
	down.device = 0
	Input.parse_input_event(down)
	await get_tree().process_frame
	var up: InputEventJoypadButton = down.duplicate()
	up.pressed = false
	Input.parse_input_event(up)

func _set_a(is_down: bool) -> void:
	if is_down == _a_held:
		return
	_a_held = is_down
	var e: InputEventJoypadButton = InputEventJoypadButton.new()
	e.button_index = JOY_BUTTON_A
	e.pressed = is_down
	e.device = 0
	Input.parse_input_event(e)


func _set_stick(dir: Vector2) -> void:
	for axis: int in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var e: InputEventJoypadMotion = InputEventJoypadMotion.new()
		e.axis = axis
		e.axis_value = dir.x if axis == JOY_AXIS_LEFT_X else dir.y
		e.device = 0
		Input.parse_input_event(e)
	_stick_active = dir != Vector2.ZERO


## 미니게임 밖으로 나오면 스틱과 A 를 놓는다.
func _release_pad() -> void:
	if _stick_active:
		_set_stick(Vector2.ZERO)
	_set_a(false)


func _mg_kind(mg: Node) -> String:
	return String(mg.get_script().resource_path.get_file().get_basename())


func _issue(kind: String, detail: String) -> void:
	var key: String = kind + "|" + _scene_name() + "|" + detail
	if issues.has(key):
		issues[key] += 1
		return
	issues[key] = 1
	lines.append("!! %d일째 %s [%s] %s" % [GameState.current_day, _scene_name(), kind, detail])
	print("!! ", kind, " ", _scene_name(), " ", detail)

func _scene_name() -> String:
	var s: Node = get_tree().current_scene
	return s.scene_file_path.get_file().get_basename() if s else "-"

func _visible_buttons() -> Array[BaseButton]:
	var out: Array[BaseButton] = []
	var s: Node = get_tree().current_scene
	if s == null: return out
	for n: Node in get_tree().root.find_children("*", "BaseButton", true, false):
		var b: BaseButton = n
		if b.is_visible_in_tree() and not b.disabled and b.focus_mode != Control.FOCUS_NONE:
			out.append(b)
	return out

func _texts(buttons: Array[BaseButton]) -> String:
	var t: PackedStringArray = []
	for b: BaseButton in buttons:
		t.append((b as Button).text.replace("\n", " ") if b is Button else b.name)
	return ", ".join(t)

func _tick() -> void:
	if _finished or _busy: return
	_busy = true
	await _step()
	_busy = false

func _step() -> void:
	if Time.get_ticks_msec() - _start_ms > 2400000:
		lines.append("!! 시간 초과 — 멈춘 곳 %s %d일째" % [_scene_name(), GameState.current_day])
		_finish(); return
	var scene: Node = get_tree().current_scene
	if scene == null: return
	var path: String = scene.scene_file_path
	if path == "res://scenes/ui/title.tscn" or (GameState.current_season != Season.Id.SPRING and path == "res://scenes/garden/garden.tscn"):
		lines.append("끝까지 감: %s (%d일째)" % [_scene_name(), GameState.current_day])
		_finish(); return
	# 진행이 멈췄는지 (장면·날짜·포커스가 오래 그대로)
	var focus: Control = get_viewport().gui_get_focus_owner()
	var key: String = "%s|%d|%s|%s" % [path, GameState.current_day, str(focus.get_instance_id()) if focus else "-", (focus as Button).text if focus is Button else ""]
	if key == _last_key:
		_same_ticks += 1
	else:
		_same_ticks = 0
		_last_key = key
	if _same_ticks > 300 and not _is_minigame_playing():
		_issue("멈춤", "같은 상태로 오래 머무름 (포커스: %s / 보이는 버튼: %s)" % [_describe(focus), _texts(_visible_buttons())])
		_same_ticks = 0
		_force_progress()
		return
	# 미니게임: 스틱을 돌리고 가끔 오른쪽으로 밀며 A 를 눌렀다 뗀다
	for mg: Node in get_tree().root.find_children("*", "Minigame", true, false):
		if (mg as Control).is_visible_in_tree() and mg._is_playing:
			if get_viewport().gui_get_focus_owner() != mg:
				_issue("미니게임 포커스", "%s 가 선택돼 있지 않아 A 가 먹지 않을 수 있음 (포커스: %s)" % [mg.name, _describe(get_viewport().gui_get_focus_owner())])
			var id: int = mg.get_instance_id()
			# 맞힘 수만 보면 쌀 씻기처럼 맞힘을 늦게 세는 미니게임이 "반응 없음"으로 잘못 잡혀서, 단계·진행 값도 함께 본다.
			var sig: String = "%d|%s|%s|%s|%s" % [mg._hit_count, str(mg.get("_cook_progress")), str(mg.get("_phase")),
					str(mg.get("_washes_done")), str(mg.get("_rub"))]
			if not _mg_presses.has(id):
				_mg_presses[id] = 0; _mg_first_sig[id] = sig; _mg_changed[id] = false
			if sig != _mg_first_sig[id]:
				_mg_changed[id] = true
			_mg_presses[id] += 1
			var t: int = _mg_presses[id]
			if t == 150 and not _mg_changed[id]:
				_issue("미니게임 반응 없음", "%s 에서 스틱·A 를 15초 해도 맞힘이 하나도 안 셈" % _mg_kind(mg))
			if t > MINIGAME_TICK_LIMIT:
				_tool_limit += 1
				_mg_done_by_tool[_mg_kind(mg)] = _mg_done_by_tool.get(_mg_kind(mg), 0) + 1
				_mg_presses.erase(id)
				_release_pad()
				mg._complete("완성")
				return
			_stick_angle += STICK_TURN + randf_range(-0.1, 0.1)
			var push_right: bool = t % PUSH_RIGHT_PERIOD >= PUSH_RIGHT_PERIOD - PUSH_RIGHT_TICKS
			_set_stick(Vector2.RIGHT if push_right else Vector2.from_angle(_stick_angle))
			_set_a(t % (A_HOLD_TICKS + A_REST_TICKS) < A_HOLD_TICKS)
			return
	# 방금 끝난 미니게임: 게임패드만으로 끝난 것으로 센다
	for id: int in _mg_presses.keys():
		var node: Object = instance_from_id(id)
		if node == null or not node._is_playing:
			if node != null:
				var kind: String = _mg_kind(node)
				_mg_done_by_pad[kind] = _mg_done_by_pad.get(kind, 0) + 1
				_mg_ticks[kind] = maxi(_mg_ticks.get(kind, 0), _mg_presses[id])
			_mg_presses.erase(id)
	_release_pad()
	var buttons: Array[BaseButton] = _visible_buttons()
	if focus == null or not focus.is_visible_in_tree():
		if buttons.is_empty():
			await _press(JOY_BUTTON_A)   # 이야기 장면·결과판처럼 A 로 넘기는 화면
			return
		# 손님이 걸어 들어오는 중처럼 잠깐 선택이 없는 건 괜찮다. 3초 넘게 그대로일 때만 문제로 본다.
		_no_focus_ticks += 1
		if _no_focus_ticks < 30:
			return
		_no_focus_ticks = 0
		_issue("선택 없음", "버튼이 보이는데 3초 넘게 아무것도 선택돼 있지 않음 → 게임패드로 못 누름 (보이는 버튼: %s)" % _texts(buttons))
		await _press(JOY_BUTTON_DPAD_DOWN)
		await get_tree().process_frame
		if get_viewport().gui_get_focus_owner() == null:
			_force_progress()
		return
	_no_focus_ticks = 0
	if focus is HSlider:
		await _press(JOY_BUTTON_B); return
	# 찾아가는 중이면 계속 아래로
	if _seek_left > 0:
		if focus is Button and (focus as Button).text == _seek_target:
			_seek_left = 0
			await _press(JOY_BUTTON_A); return
		_seek_left -= 1
		if _seek_left == 0:
			_issue("갈 수 없음", "'%s' 버튼까지 십자키로 못 감 (포커스가 돈 곳: %s)" % [_seek_target, _describe(focus)])
			_force_progress(); return
		await _press(JOY_BUTTON_DPAD_DOWN if _seek_left % 6 != 0 else JOY_BUTTON_DPAD_RIGHT)
		return
	var text: String = (focus as Button).text if focus is Button else ""
	# 번진 노트: 고른 보기가 틀려 그대로면 십자키로 다음 보기로 옮겨 다시 고른다
	var puzzle: Node = _find_visible("NotePuzzleBoard")
	if puzzle != null and text != "요리 시작" and text != "추억 떠올리기":
		if focus == _last_focus:
			_a_on_same += 1
		else:
			_a_on_same = 0
			_last_focus = focus
		if _a_on_same >= 1:
			_a_on_same = 0
			_last_focus = null
			await _press(JOY_BUTTON_DPAD_DOWN)
			return
		await _press(JOY_BUTTON_A)
		return
	# 메뉴판: 장사 시작으로 간다 (요리를 껐다 켜지 않게)
	var board: Node = _find_visible("MenuBoard")
	if board != null:
		if text == "장사 시작" and not board._message_label.text.is_empty() and _a_on_same >= 1 and board._selected_ids.is_empty():
			# 아무것도 안 골랐으면 만들 수 있는 요리 하나를 켠다
			for r: Recipe in GameData.get_all_recipes():
				if GameState.is_recipe_unlocked(r.id) and GameState.has_ingredients(r.get_ingredient_counts()):
					_seek("○ " + r.display_name); return
		if text == "장사 시작" and not board._message_label.text.is_empty() and _a_on_same >= 1:
			# 재료 부족으로 막힘 → 모자란 요리를 찾아 끈다
			for id: StringName in board._selected_ids:
				if not GameState.has_ingredients(GameData.get_recipe(id).get_ingredient_counts()):
					_seek("● " + GameData.get_recipe(id).display_name); return
		if text != "장사 시작":
			_seek("장사 시작"); return
	if _scene_name() == "market":
		if _market_day != GameState.current_day:
			_market_day = GameState.current_day; _market_trades = 0
		if text != "← 텃밭으로" and _market_trades < 2:
			_market_trades += 1
			await _press(JOY_BUTTON_A); return
		if text != "← 텃밭으로":
			_seek("← 텃밭으로"); return
	# 같은 버튼을 계속 눌러도 그대로면 진행 버튼을 찾아간다
	if focus == _last_focus:
		_a_on_same += 1
	else:
		_a_on_same = 0
		_last_focus = focus
	if _a_on_same >= 6 and text not in PROGRESS:
		for target: String in PROGRESS:
			for b: BaseButton in buttons:
				if b is Button and (b as Button).text == target:
					_a_on_same = 0
					_seek(target); return
	await _press(JOY_BUTTON_A)

## 미니게임 중에는 포커스가 그대로인 게 정상이라 "오래 머무름" 감지를 끈다 (미니게임은 MINIGAME_TICK_LIMIT 로 따로 본다).
func _is_minigame_playing() -> bool:
	for mg: Node in get_tree().root.find_children("*", "Minigame", true, false):
		if (mg as Control).is_visible_in_tree() and mg._is_playing:
			return true
	return false


func _seek(target: String) -> void:
	_seek_target = target
	_seek_left = 24

func _find_visible(cls: String) -> Node:
	for n: Node in get_tree().root.find_children("*", cls, true, false):
		if (n as Control).is_visible_in_tree(): return n
	return null

func _describe(c: Control) -> String:
	if c == null: return "없음"
	return "%s(%s)" % [c.name, (c as Button).text.replace("\n", " ") if c is Button else c.get_class()]

## 막혔을 때: 진행 버튼을 직접 누르거나(기록됨) 미니게임을 끝낸다.
func _force_progress() -> void:
	for mg: Node in get_tree().root.find_children("*", "Minigame", true, false):
		if (mg as Control).is_visible_in_tree() and mg._is_playing:
			_tool_limit += 1
			_mg_done_by_tool[_mg_kind(mg)] = _mg_done_by_tool.get(_mg_kind(mg), 0) + 1
			_mg_presses.erase(mg.get_instance_id())
			_release_pad()
			mg._complete("완성"); return
	var buttons: Array[BaseButton] = _visible_buttons()
	for target: String in PROGRESS:
		for b: BaseButton in buttons:
			if b is Button and (b as Button).text == target:
				lines.append("   (직접 누름: %s)" % target)
				b.pressed.emit(); return
	lines.append("   (누를 진행 버튼이 없음: %s)" % _texts(buttons))

func _finish() -> void:
	_finished = true
	lines.append("")
	lines.append("게임패드만으로 끝난 미니게임 (종류: 횟수, 가장 오래 걸린 틱): %s" % ", ".join(_mg_done_by_pad.keys().map(func(k: String) -> String: return "%s %d번 %d틱" % [k, _mg_done_by_pad[k], _mg_ticks[k]])))
	lines.append("%d틱 안에 못 끝내 도구가 대신 끝낸 미니게임: %d번 %s" % [MINIGAME_TICK_LIMIT, _tool_limit, str(_mg_done_by_tool)])
	lines.append("문제 종류별 횟수:")
	for k: String in issues:
		lines.append("  %d번 · %s" % [issues[k], k])
	var f: FileAccess = FileAccess.open(log_path, FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	get_tree().quit()
