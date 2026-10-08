class_name PanFryMinigame
extends Minigame
## 부치기 미니게임 (반죽 펴기 → 노릇할 때 뒤집개로 뒤집기).
## 1) 팬 가운데 떨어진 반죽을, 마우스를 누른 채 빙글빙글 돌려(게임패드는 스틱, 키보드는 방향키를 돌려) 동그랗게 편다.
##    돌린 만큼 반죽이 넓어지고, 점선 동그라미까지 다 펴면 굽기 시작한다. 서툴러도 조금 오래 걸릴 뿐 실패는 없다.
## 2) 전이 지글지글 익으며 색이 하양 → 노랑 → 금색 → 갈색으로 변한다. 금색(노릇노릇)일 때 뒤집개를 위로 휙 올리면
##    (마우스를 누른 채 위로 빠르게 끌기, 위 방향키·스틱 위, 또는 Ⓐ·스페이스) 뒤집는다. 뒷면까지 익으면 한 번 더 휙 올려 접시로 옮긴다.
## 전 jeon_count 장을 다 부치면 완성 (장마다 반죽부터 편다).
## 너무 일찍 뒤집으면 빗나감이지만 그대로 계속 익는다. 늦게 뒤집으면 조금 진하게 익었을 뿐 넘어가고, 빗나감으로 센다.
## 면마다 굽기 시작한 직후 flip_grace 초 동안의 위 방향 입력은 무시한다 (스틱을 돌리다 위로 지나간 것을 뒤집기로 치지 않게).
## 타서 실패하는 일은 없다. 연타 방지, 완벽 표시는 공통 틀(Minigame)이 맡는다.

enum JeonState { SPREADING, COOKING, MOVING }

const SIDE_FORMAT: String = "전 %d / %d · %s"
const SPREAD_TEXT: String = "누른 채로 빙글빙글 돌려 반죽을 펴요 (스틱·방향키를 돌려도 돼요)"
const SPREAD_DONE_TEXT: String = "동그랗게 폈어요! 금색으로 노릇해지면 뒤집개를 위로 휙!"
const READY_TEXT: String = "금색으로 노릇해지면 뒤집개를 위로 휙! (위 방향키 / Ⓐ)"
const FLICK_HINT_TEXT: String = "뒤집개를 누른 채 위로 휙 올려요"
const SPREAD_SIDE_TEXT: String = "반죽 펴기"
const FRONT_SIDE_TEXT: String = "앞면"
const BACK_SIDE_TEXT: String = "뒷면"
## 반죽을 다 폈을 때 나는 소리 (data/sounds/ 의 id)
const SPREAD_DONE_SOUND: StringName = &"pop"
const FLIP_TEXT: String = "착! 노릇노릇하게 뒤집었어요"
const LIFT_TEXT: String = "노릇노릇! 접시에 담았어요"
const EARLY_TEXT: String = "아직 덜 익었어요. 조금 더 기다려요"
const LATE_TEXT: String = "앗, 조금 진하게 익었어요"
const DONE_TEXT: String = "노릇노릇 다 부쳤어요!"
## 한 장을 다 부치려면 앞면, 뒷면 두 번 눌러야 한다.
const SIDES_PER_JEON: int = 2

@export var jeon_count: int = 1
## 반죽 펴기: 처음 떨어진 반죽의 반지름(픽셀)과, 점선 동그라미(전 크기)까지 다 펴려면 돌려야 하는 바퀴 수
@export var spread_start_radius: float = 54.0
@export var spread_turns: float = 2.5
## 가운데에서 이만큼(픽셀) 떨어져 돌려야 돈 것으로 센다. 한 번에 이보다 크게 돈 각도(라디안)는 튄 값이라 세지 않는다.
@export var spread_min_distance: float = 30.0
@export var spread_max_step: float = 1.2
## 스틱·방향키를 이만큼 기울여야 돌린 것으로 센다 (0~1)
@export var stick_deadzone: float = 0.5
## 펴진 반죽 위 소용돌이 줄 간격(픽셀)과 색, 다 펴야 할 크기를 보여 주는 점선 색, 게임패드 국자 표시 색
@export var spiral_ring_gap: float = 27.0
@export var spiral_ring_color: Color = Color(0.86, 0.8, 0.64)
@export var guide_color: Color = Color(1, 1, 1, 0.45)
@export var ladle_color: Color = Color(0.55, 0.42, 0.3)
@export var ladle_radius: float = 15.0
## 뒤집개 휘두르기: 누른 채 이만큼(픽셀) 위로 이 시간(초) 안에 끌면 뒤집는다
@export var flick_distance: float = 110.0
@export var flick_max_time: float = 0.45
## 면마다 굽기 시작한 직후 위 방향 입력을 무시하는 시간(초)
@export var flip_grace: float = 0.5
## 한 면이 하양에서 완전히 갈색이 될 때까지 걸리는 시간(초). 면마다 cook_duration_variance 만큼 조금씩 달라진다.
@export var cook_duration: float = 2.4
@export var cook_duration_variance: float = 0.15
## 익은 정도(0~1) 중 금색(노릇노릇) 구간. 이때 누르면 성공. 넓을수록 쉽다.
@export_range(0.0, 1.0) var golden_start: float = 0.6
@export_range(0.0, 1.0) var golden_end: float = 0.8
## 금색 구간 양쪽으로 이만큼 더 봐준다. 화면에는 안 보인다.
@export var judge_margin: float = 0.03
## 익는 색: 처음(하양) → 노랑 → 금색(노릇) → 다 지나면 갈색
@export var raw_color: Color = Color(0.98, 0.95, 0.82)
@export var light_color: Color = Color(0.98, 0.86, 0.45)
@export var golden_color: Color = Color(0.93, 0.66, 0.2)
@export var over_color: Color = Color(0.55, 0.32, 0.14)
## 금색 구간일 때 전 둘레가 빛나는 정도
@export var glow_alpha: float = 0.9
## 뒤집을 때 전이 튀어 오르는 높이(픽셀)와 시간(초)
@export var flip_hop_height: float = 80.0
@export var flip_duration: float = 0.3
## 다 익은 전이 접시로 미끄러져 가는 시간(초)과 다음 전이 놓이기까지 쉬는 시간(초)
@export var lift_duration: float = 0.35
## 접시로 가면서 작아지는 크기 (접시 줄의 작은 전 크기에 맞춘다)
@export var lift_end_scale: float = 0.2
@export var next_jeon_delay: float = 0.3

## 이번 단계의 전 장수와 한 면 익는 시간 (요리 단계에서 정한 값, 없으면 위의 기본값)
var _jeon_count: int = 0
var _cook_duration: float = 2.4
var _state: JeonState = JeonState.COOKING
## 지금 익히는 면의 익은 정도. 0 = 날것, 1 = 완전히 갈색.
var _doneness: float = 0.0
var _side_duration: float = 2.4
## 다 부친 전 수, 지금 전에서 끝낸 면 수
var _jeons_done: int = 0
var _sides_done: int = 0
## 전의 처음 자리 (뒤집고 옮긴 뒤 되돌릴 때 쓴다)
var _jeon_home: Vector2
## 반죽을 편 만큼 돌린 각도 합(라디안). 마우스와 스틱이 마지막으로 가리킨 각도 (NAN = 아직 없음)
var _spread_angle_total: float = 0.0
var _mouse_last_angle: float = NAN
var _pad_last_angle: float = NAN
## 게임패드·방향키가 가리키는 방향 (국자 표시용, 안 기울였으면 0)
var _pad_dir: Vector2 = Vector2.ZERO
## 마우스를 누르고 있는지, 뒤집개를 휘두르기 시작한 자리와 때
var _is_mouse_down: bool = false
var _flick_start: Vector2 = Vector2.ZERO
var _flick_start_ms: int = 0
var _has_flicked: bool = false
## 이 면을 굽기 시작한 뒤 지난 시간 (flip_grace 와 비교)
var _side_time: float = 0.0

@onready var _jeon: Control = %Jeon
@onready var _glow: Control = %Glow
@onready var _doneness_bar: Control = %DonenessBar
@onready var _gold_zone: ColorRect = %GoldZone
@onready var _over_zone: ColorRect = %OverZone
@onready var _marker: Control = %Marker
@onready var _done_row: HBoxContainer = %DoneRow
@onready var _done_template: Control = %DoneTemplate
@onready var _side_label: Label = %SideLabel
## 펴지는 반죽을 그리는 칸 (전과 같은 자리·크기)과, 뒤집개 (그림이 오기 전엔 임시 막대)
@onready var _batter: Control = %Batter
@onready var _spatula: Control = %Spatula


func _ready() -> void:
	super()
	_done_template.hide()
	_jeon_home = _jeon.position
	_jeon.pivot_offset = _jeon.size / 2.0
	_batter.draw.connect(_draw_batter)
	_spatula.hide()


func _get_minigame_type() -> Recipe.MinigameType:
	return Recipe.MinigameType.PAN_FRY


func _on_start(recipe: Recipe) -> void:
	_jeon_count = _step_count(jeon_count)
	_cook_duration = cook_duration / _speed
	_jeons_done = 0
	for child: Node in _done_row.get_children():
		child.queue_free()
	_layout_doneness_bar()
	_clear_zones(_gold_zone)
	_title_label.text = _step_title(Recipe.MinigameType.PAN_FRY, _default_subject(recipe))
	_progress_label.text = READY_TEXT
	_place_new_jeon()


func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing:
		return
	if _state == JeonState.SPREADING:
		_spread_with_pad()
		return
	if _state != JeonState.COOKING:
		return
	_side_time += delta
	_doneness = minf(_doneness + delta / _side_duration, 1.0)
	_update_jeon_look()


## 마우스는 펴기·뒤집개 휘두르기를 직접 다룬다. 위 방향(키·스틱)은 뒤집기, 다른 방향은 포커스가 옮겨 가지 않게 먹는다.
## Ⓐ·스페이스는 공통 틀이 연타 방지를 거쳐 _on_press 로 보낸다.
func _gui_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if event.pressed:
			_on_mouse_down(event.position)
		else:
			_on_mouse_up()
		return
	if event is InputEventMouseMotion:
		_on_mouse_move(event.position)
		return
	if event.is_action_pressed("ui_up") and _state == JeonState.COOKING:
		accept_event()
		_try_flip(false)
		return
	for action: StringName in [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]:
		if event.is_action(action):
			accept_event()
			return
	super(event)


## Ⓐ·스페이스 (공통 틀이 이미 연타 방지를 거쳤다)
func _on_press() -> void:
	if _state == JeonState.COOKING:
		_judge_flip()


func _on_mouse_down(at: Vector2) -> void:
	_is_mouse_down = true
	_mouse_last_angle = NAN
	if _state == JeonState.SPREADING:
		_spread_toward(at, true)
	elif _state == JeonState.COOKING:
		_flick_start = at
		_flick_start_ms = Time.get_ticks_msec()
		_has_flicked = false
		_move_spatula(at)
		_spatula.show()


func _on_mouse_move(at: Vector2) -> void:
	if not _is_mouse_down:
		return
	if _state == JeonState.SPREADING:
		_spread_toward(at, true)
	elif _state == JeonState.COOKING and _spatula.visible:
		_move_spatula(at)
		var is_quick: bool = Time.get_ticks_msec() - _flick_start_ms <= int(flick_max_time * 1000.0)
		if not _has_flicked and is_quick and _flick_start.y - at.y >= flick_distance:
			_has_flicked = true
			_try_flip(true)


func _on_mouse_up() -> void:
	_is_mouse_down = false
	_mouse_last_angle = NAN
	if _spatula.visible:
		_spatula.hide()
		if not _has_flicked and _state == JeonState.COOKING:
			_progress_label.text = FLICK_HINT_TEXT


func _move_spatula(at: Vector2) -> void:
	_spatula.position = at - _spatula.size / 2.0


## 뒤집개로 뒤집기. 연타 방지를 공통 틀과 같이 쓴다.
## is_deliberate 가 false(위 방향키·스틱)면 굽기 시작 직후 flip_grace 동안은 무시한다.
func _try_flip(is_deliberate: bool) -> void:
	if _state != JeonState.COOKING or _cooldown_left > 0.0:
		return
	if not is_deliberate and _side_time < flip_grace:
		return
	_cooldown_left = press_cooldown
	_judge_flip()


func _judge_flip() -> void:
	if _doneness < golden_start - judge_margin:
		_register_miss()
		_progress_label.text = EARLY_TEXT
		return
	if _doneness > golden_end + judge_margin:
		_register_miss()
		# 늦었어도 전은 뒤집으니까 뒤집는 소리는 낸다.
		_play_hit_sound()
		_progress_label.text = LATE_TEXT
	else:
		# 막 금색이 됐을 때 = 0, 짙은 금색 끝 = 1
		_register_hit((_doneness - golden_start) / (golden_end - golden_start))
	_sides_done += 1
	if _sides_done >= SIDES_PER_JEON:
		_lift_jeon()
	else:
		_flip_jeon()


## 익힘 막대의 금색 칸 안에 비법 자리나 부탁 자리를 그린다.
func _show_zone(start: float, end: float, color: Color, zone_name: String) -> void:
	var width: float = _gold_zone.size.x
	_make_zone(_gold_zone, Rect2(start * width, 0.0, (end - start) * width, _gold_zone.size.y), color, zone_name)


func is_golden() -> bool:
	return _state == JeonState.COOKING \
			and _doneness >= golden_start - judge_margin and _doneness <= golden_end + judge_margin


## 새 반죽을 팬 가운데 떨어뜨리고 펴기부터 시작한다.
func _place_new_jeon() -> void:
	_sides_done = 0
	_jeon.position = _jeon_home
	_jeon.scale = Vector2.ONE
	_jeon.hide()
	_glow.modulate.a = 0.0
	_doneness = 0.0
	_marker.position.x = -_marker.size.x / 2.0
	_state = JeonState.SPREADING
	_spread_angle_total = 0.0
	_mouse_last_angle = NAN
	_pad_last_angle = NAN
	_pad_dir = Vector2.ZERO
	_batter.show()
	_batter.queue_redraw()
	_progress_label.text = SPREAD_TEXT
	_side_label.text = SIDE_FORMAT % [_jeons_done + 1, _jeon_count, SPREAD_SIDE_TEXT]


## 반죽이 펴진 반지름: 처음 떨어진 크기에서, 돌린 바퀴 수만큼 전 크기까지 넓어진다.
func _spread_radius() -> float:
	var full: float = _batter.size.x / 2.0
	var progress: float = clampf(_spread_angle_total / (spread_turns * TAU), 0.0, 1.0)
	return lerpf(spread_start_radius, full, progress)


## 반죽 가운데를 중심으로 at 이 돈 각도만큼 편다. is_mouse 로 마우스·패드의 마지막 각도를 따로 기억한다.
func _spread_toward(at: Vector2, is_mouse: bool) -> void:
	var offset: Vector2 = at - (_batter.position + _batter.size / 2.0)
	var last: float = _mouse_last_angle if is_mouse else _pad_last_angle
	var angle: float = NAN
	if offset.length() >= spread_min_distance:
		angle = offset.angle()
		if not is_nan(last):
			var step: float = absf(angle_difference(last, angle))
			if step <= spread_max_step:
				_spread_angle_total += step
	if is_mouse:
		_mouse_last_angle = angle
	else:
		_pad_last_angle = angle
	_batter.queue_redraw()
	if _spread_angle_total >= spread_turns * TAU:
		_finish_spread()


## 스틱·방향키를 기울인 방향을 반죽 둘레의 한 점으로 보고 돌린 만큼 편다.
func _spread_with_pad() -> void:
	var dir: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if dir.length() < stick_deadzone:
		if _pad_dir != Vector2.ZERO:
			_pad_dir = Vector2.ZERO
			_pad_last_angle = NAN
			_batter.queue_redraw()
		return
	_pad_dir = dir.normalized()
	_spread_toward(_batter.position + _batter.size / 2.0 + _pad_dir * _batter.size.x * 0.35, false)


func _finish_spread() -> void:
	_state = JeonState.MOVING
	_spread_angle_total = spread_turns * TAU
	_pad_dir = Vector2.ZERO
	Sound.play(SPREAD_DONE_SOUND)
	_batter.hide()
	_jeon.show()
	_progress_label.text = SPREAD_DONE_TEXT
	_start_side()


## 다 펴야 할 크기(점선), 펴진 반죽과 소용돌이 줄, 게임패드로 돌릴 때 국자 자리를 그린다.
func _draw_batter() -> void:
	var center: Vector2 = _batter.size / 2.0
	var full: float = _batter.size.x / 2.0
	var dashes: int = 36
	for i: int in dashes:
		if i % 2 == 0:
			var from: float = TAU * i / dashes
			_batter.draw_arc(center, full, from, from + TAU / dashes, 4, guide_color, 4.0)
	var radius: float = _spread_radius()
	_batter.draw_circle(center, radius, raw_color)
	var ring: float = radius - spiral_ring_gap
	while ring > spiral_ring_gap / 2.0:
		_batter.draw_arc(center, ring, 0.0, TAU, 48, spiral_ring_color, 3.0)
		ring -= spiral_ring_gap
	if _pad_dir != Vector2.ZERO:
		_batter.draw_circle(center + _pad_dir * full * 0.8, ladle_radius, ladle_color)


func _start_side() -> void:
	_state = JeonState.COOKING
	_side_time = 0.0
	_doneness = 0.0
	_side_duration = _cook_duration * (1.0 + randf_range(-cook_duration_variance, cook_duration_variance))
	_update_jeon_look()
	_side_label.text = SIDE_FORMAT % [_jeons_done + 1, _jeon_count,
			FRONT_SIDE_TEXT if _sides_done == 0 else BACK_SIDE_TEXT]


## 전이 살짝 튀어 오르며 납작해졌다가(뒤집히는 중) 다시 펴진다. 펴지면 뒷면을 익힌다.
func _flip_jeon() -> void:
	_state = JeonState.MOVING
	if _doneness <= golden_end + judge_margin:
		_progress_label.text = FLIP_TEXT
	var half: float = flip_duration / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(_jeon, "scale:y", 0.0, half)
	tween.parallel().tween_property(_jeon, "position:y", _jeon_home.y - flip_hop_height, half) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(_show_raw_side)
	tween.tween_property(_jeon, "scale:y", 1.0, half)
	tween.parallel().tween_property(_jeon, "position:y", _jeon_home.y, half) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.finished.connect(_start_side)


func _show_raw_side() -> void:
	_doneness = 0.0
	_update_jeon_look()


## 다 익은 전을 왼쪽 접시로 옮긴다. 다 부쳤으면 완성.
func _lift_jeon() -> void:
	_state = JeonState.MOVING
	if _doneness <= golden_end + judge_margin:
		_progress_label.text = LIFT_TEXT
	_glow.modulate.a = 0.0
	var finished_color: Color = _jeon.self_modulate
	# 접시 가운데로 미끄러져 간다.
	var target: Vector2 = _done_row.global_position + _done_row.size / 2.0 - _jeon.get_parent().global_position
	var tween: Tween = create_tween()
	tween.tween_property(_jeon, "position", target - _jeon.size / 2.0, lift_duration) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(_jeon, "scale", Vector2.ONE * lift_end_scale, lift_duration)
	tween.tween_callback(_on_jeon_lifted.bind(finished_color))


func _on_jeon_lifted(finished_color: Color) -> void:
	_jeon.hide()
	var done_jeon: Control = _done_template.duplicate()
	done_jeon.self_modulate = finished_color
	done_jeon.show()
	_done_row.add_child(done_jeon)
	_jeons_done += 1
	if _jeons_done >= _jeon_count:
		_complete(DONE_TEXT)
		return
	# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
	await get_tree().create_timer(next_jeon_delay, false).timeout
	if _is_playing:
		_place_new_jeon()


## 익은 정도에 따라 전 색을 바꾸고, 금색 구간이면 둘레를 빛나게, 막대 표시를 옮긴다.
func _update_jeon_look() -> void:
	_jeon.self_modulate = _doneness_color(_doneness)
	_glow.modulate.a = glow_alpha if is_golden() else 0.0
	_marker.position.x = _doneness * _doneness_bar.size.x - _marker.size.x / 2.0


func _doneness_color(doneness: float) -> Color:
	if doneness < golden_start:
		var t: float = doneness / golden_start
		return raw_color.lerp(light_color, t * 2.0) if t < 0.5 else light_color.lerp(golden_color, t * 2.0 - 1.0)
	if doneness <= golden_end:
		return golden_color
	return golden_color.lerp(over_color, (doneness - golden_end) / (1.0 - golden_end))


## 익힘 막대에서 금색 구간과 갈색 구간의 자리를 golden_start, golden_end 에 맞춘다.
func _layout_doneness_bar() -> void:
	var width: float = _doneness_bar.size.x
	_gold_zone.position.x = golden_start * width
	_gold_zone.size.x = (golden_end - golden_start) * width
	_over_zone.position.x = golden_end * width
	_over_zone.size.x = (1.0 - golden_end) * width
