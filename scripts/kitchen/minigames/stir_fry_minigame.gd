class_name StirFryMinigame
extends Minigame
## 볶기 미니게임 (위에서 내려다본 팬 토스). 동그란 팬이 커서를 따라 불판 위를 움직인다. 게임패드는 스틱으로 옮긴다.
## 클릭(Ⓐ·스페이스)하면 팬 안의 조각들이 화면 쪽으로 떠오른다 (높이 뜰수록 커진다). 떨어질 자리에는 그림자가 생기고,
## 떨어질 자리는 띄울 때마다 팬에서 조금씩 벗어난다. 조각이 내려올 때 팬 안에 들어간 조각만 남고,
## 팬 테두리 밖 조각은 불판에 툭 떨어져 그대로 있다. 그림자 가운데가 팬 안이면 받은 것으로 한 번 센다.
## 팬에 fail_piece_count 개 이하만 남으면 "다 흘렸네!" 하고 조각을 모두 팬에 다시 담아 이 단계만 처음부터 한다 (재료·보상 손해 없음).
## 할머니 비법 자리·부탁 자리 = 받는 자리: 0 = 그림자 가운데가 팬 한가운데, 1 = 팬 가장자리. 팬 위에 고리로 그린다.

enum TossState { RESTING, AIRBORNE, SPILLED }

const READY_TEXT: String = "클릭해서 재료를 띄워요"
const CATCH_FORMAT: String = "착! %d / %d"
const MISS_FORMAT: String = "툭… 팬 밖으로 떨어졌어요 %d / %d"
const SPILL_TEXT: String = "어이쿠, 다 흘렸네! 다시 볶아요"
const DONE_TEXT: String = "잘 익었어요!"

@export var tosses_needed: int = 6
## 팬 반지름(픽셀). 씬의 Pan 크기의 반.
@export var pan_radius: float = 180.0
## 조각 가운데가 팬 가장자리에서 이만큼(픽셀) 안쪽이어야 팬에 남는다
@export var piece_margin: float = 12.0
## 팬이 처음 자리에서 좌우·위아래로 갈 수 있는 거리(픽셀)
@export var pan_move_range: Vector2 = Vector2(300.0, 110.0)
## 게임패드·방향키로 팬을 옮기는 빠르기(초당 픽셀)
@export var pad_pan_speed: float = 600.0
## 한 번 날아갔다 떨어지는 시간(초)과, 가장 높이 떴을 때 조각이 커지는 정도 (1 = 두 배)
@export var toss_duration: float = 0.9
@export var toss_grow: float = 0.9
## 떨어질 자리가 띄운 자리(팬 가운데)에서 벗어나는 거리(픽셀) 범위. 띄울 때마다 방향과 거리가 정해진다.
@export var toss_drift_min: float = 80.0
@export var toss_drift_max: float = 220.0
## 처음 조각 수와, 팬에 이만큼 이하가 남으면 다시 볶기
@export var food_piece_count: int = 8
@export var fail_piece_count: int = 3
## 팬에 담긴 조각들이 팬 가운데에서 흩어지는 반지름(픽셀). 날아갔다 떨어질 때도 이만큼 흩어진다.
@export var food_spread: float = 35.0
## 조각이 날아가며 도는 바퀴 수
@export var food_spin_turns: float = 1.0
## 그림이 아직 없는 재료 조각의 임시 색과, 불판에 떨어진 조각이 어두워지는 정도
@export var food_color: Color = Color(0.93, 0.55, 0.25)
@export var fallen_tint: Color = Color(0.75, 0.75, 0.75)
## 떨어질 자리 그림자 크기(픽셀)와 가장 진할 때 진하기
@export var shadow_size: float = 90.0
@export var shadow_max_alpha: float = 0.45
## 팬 밖으로 떨어진 조각이 팬 테두리에서 적어도 이만큼(픽셀) 바깥에 놓인다 (팬 밑에 가려지지 않게), 튕겨 나가는 시간(초)
@export var fallen_clearance: float = 30.0
@export var fall_bounce_duration: float = 0.2
## 불판에 떨어진 조각이 납작해졌다 돌아오는 정도와 시간(초)
@export var fall_squash: float = 0.7
@export var fall_squash_duration: float = 0.15
## 다 흘렸을 때 다시 담기 전에 기다리는 시간과 조각이 팬으로 돌아오는 시간(초)
@export var spill_wait: float = 0.9
@export var spill_return_duration: float = 0.35
## 받는 자리 고리 진하기 (비법·부탁 자리 색에 곱한다)
@export var zone_ring_alpha: float = 0.45
## 띄울 때와 받을 때 팬이 튀는 크기와 시간(초)
@export var pan_jolt_scale: float = 0.96
@export var pan_jolt_duration: float = 0.15
## 불꽃 고리가 일렁이는 빠르기와 정도
@export var flame_flicker_speed: float = 9.0
@export var flame_flicker_amount: float = 0.04

## 이번 단계의 토스 수, 한 번 날아가는 시간, 재료 색 (요리 단계에서 정한 값, 없으면 위의 기본값)
var _tosses_needed: int = 0
var _toss_duration: float = 0.9
var _food_color: Color
var _state: TossState = TossState.RESTING
var _toss_time: float = 0.0
var _tosses_done: int = 0
var _flame_time: float = 0.0
## 조각들과, 팬 안에 있는지, 팬 가운데에서 떨어진 자리, 날아갈 때 출발·도착 자리 (미니게임 기준)
var _pieces: Array[Control] = []
var _is_in_pan: Array[bool] = []
var _pan_offsets: Array[Vector2] = []
var _starts: Array[Vector2] = []
var _lands: Array[Vector2] = []
## 이번에 떨어질 자리 (그림자 가운데)
var _landing_point: Vector2
## 팬 가운데의 처음 자리와 지금 자리 (미니게임 기준)
var _home_point: Vector2
var _pan_point: Vector2
## 이번에 쓰는 팬의 받는 반지름 (조리도구가 있으면 넓어진다)
var _catch_radius: float = 180.0
var _shadow: Panel
var _fallen_layer: Control

@onready var _pan: Control = %Pan
@onready var _food_layer: Control = %FoodLayer
@onready var _food_template: Control = %FoodTemplate
@onready var _flame: Control = %Flame
@onready var _sizzle: Node2D = $Sizzle


func _ready() -> void:
	super()
	_food_template.hide()
	_home_point = _pan.position + _pan.size / 2.0
	_pan.pivot_offset = _pan.size / 2.0
	_flame.pivot_offset = _flame.size / 2.0
	# 조각은 미니게임 기준 자리에 둔다
	_food_layer.position = Vector2.ZERO
	# 불판에 떨어진 조각은 팬 아래에 깔린다 (팬이 그 위를 지나가면 가려진다).
	_fallen_layer = Control.new()
	_fallen_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fallen_layer)
	move_child(_fallen_layer, _pan.get_index())
	_shadow = _make_circle(shadow_size / 2.0, Color(0, 0, 0, 1))
	_shadow.size = Vector2.ONE * shadow_size
	add_child(_shadow)
	move_child(_shadow, _food_layer.get_index())
	_shadow.hide()


func _get_minigame_type() -> Recipe.MinigameType:
	return Recipe.MinigameType.STIR_FRY


func _on_start(recipe: Recipe) -> void:
	_tosses_needed = _step_count(tosses_needed)
	_toss_duration = toss_duration / _speed
	_catch_radius = pan_radius * _window_scale
	_food_color = _step_color(food_color)
	_state = TossState.RESTING
	_toss_time = 0.0
	_tosses_done = 0
	_shadow.hide()
	for piece: Node in _food_layer.get_children() + _fallen_layer.get_children():
		piece.queue_free()
	_pieces.clear()
	_is_in_pan.clear()
	_pan_offsets.clear()
	for i: int in food_piece_count:
		var piece: Control = _food_template.duplicate()
		piece.self_modulate = _food_color
		piece.pivot_offset = piece.size / 2.0
		piece.rotation = randf() * TAU
		piece.show()
		_food_layer.add_child(piece)
		_pieces.append(piece)
		_is_in_pan.append(true)
		_pan_offsets.append(_random_spread())
	_starts.resize(food_piece_count)
	_lands.resize(food_piece_count)
	_clear_zones(_pan)
	_move_pan_to(_home_point)
	_title_label.text = _step_title(Recipe.MinigameType.STIR_FRY, _default_subject(recipe))
	_progress_label.text = READY_TEXT


func _process(delta: float) -> void:
	super(delta)
	if not visible:
		return
	_flame_time += delta
	_flame.scale = Vector2.ONE * (1.0 + sin(_flame_time * flame_flicker_speed) * flame_flicker_amount)
	if not _is_playing:
		return
	var pad: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if pad != Vector2.ZERO:
		_move_pan_to(_pan_point + pad * pad_pan_speed * delta)
	if _state == TossState.AIRBORNE:
		_toss_time += delta
		var t: float = _toss_time / _toss_duration
		if t >= 1.0:
			_land()
		else:
			_update_flying(t, delta)


## 마우스는 팬을 옮기고, 클릭·Ⓐ(스페이스)는 띄운다. 방향은 포커스가 다른 버튼으로 새지 않게 먹는다.
func _gui_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if event is InputEventMouseMotion:
		accept_event()
		_move_pan_to(event.position)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_move_pan_to(event.position)
		if event.pressed:
			_toss()
		return
	if event.is_action_pressed(&"ui_accept"):
		accept_event()
		_toss()
		return
	for action: StringName in [&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"ui_accept"]:
		if event.is_action(action):
			accept_event()
			return


## 팬 위에 받는 자리 고리를 그린다 (start ~ end: 팬 가운데 0 ~ 가장자리 1). 가운데부터면 꽉 찬 동그라미.
func _show_zone(start: float, end: float, color: Color, zone_name: String) -> void:
	var outer: float = end * pan_radius
	var ring: Panel = _make_circle(outer, Color(color, color.a * zone_ring_alpha), (end - start) * pan_radius)
	ring.name = zone_name
	ring.size = Vector2.ONE * outer * 2.0
	ring.position = _pan.size / 2.0 - ring.size / 2.0
	_pan.add_child(ring)


## 반지름 radius 동그라미. ring_width 를 주면 그 두께의 고리만 그린다 (두께가 반지름 이상이면 꽉 찬 동그라미).
func _make_circle(radius: float, color: Color, ring_width: float = -1.0) -> Panel:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_corner_radius_all(int(radius))
	if ring_width >= 0.0 and ring_width < radius:
		style.draw_center = false
		style.set_border_width_all(int(ring_width))
		style.border_color = color
	else:
		style.bg_color = color
	var circle: Panel = Panel.new()
	circle.add_theme_stylebox_override("panel", style)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return circle


## 팬 안에서 조각이 놓일 아무 자리 (팬 가운데 기준)
func _random_spread() -> Vector2:
	return Vector2.from_angle(randf() * TAU) * food_spread * sqrt(randf())


## 팬 가운데를 at 으로 옮긴다 (움직일 수 있는 거리 안에서). 팬 안의 조각과 김도 함께 옮긴다.
func _move_pan_to(at: Vector2) -> void:
	_pan_point = at.clamp(_home_point - pan_move_range, _home_point + pan_move_range)
	_pan.position = _pan_point - _pan.size / 2.0
	_sizzle.position = _pan_point
	if _state != TossState.AIRBORNE:
		_place_resting_pieces()


func _place_resting_pieces() -> void:
	for i: int in _pieces.size():
		if _is_in_pan[i]:
			_pieces[i].position = _pan_point + _pan_offsets[i] - _pieces[i].size / 2.0
			_pieces[i].scale = Vector2.ONE


func _toss() -> void:
	if _state != TossState.RESTING:
		return
	_jolt_pan()
	_state = TossState.AIRBORNE
	_toss_time = 0.0
	# 떨어질 자리는 팬이 갈 수 있는 곳 안으로 둔다 (언제나 팬 한가운데로 받을 수 있게).
	_landing_point = (_pan_point + Vector2.from_angle(randf() * TAU) * randf_range(toss_drift_min, toss_drift_max)) \
			.clamp(_home_point - pan_move_range, _home_point + pan_move_range)
	for i: int in _pieces.size():
		_starts[i] = _pan_point + _pan_offsets[i]
		_lands[i] = _landing_point + _random_spread()
	_shadow.position = _landing_point - _shadow.size / 2.0
	_shadow.modulate.a = 0.0
	_shadow.show()


## t: 0 = 팬에서 출발, 0.5 = 가장 높이 (가장 크게), 1 = 떨어질 자리에 닿음
func _update_flying(t: float, delta: float) -> void:
	var height: float = 4.0 * t * (1.0 - t)
	var spin: float = TAU * food_spin_turns * delta / _toss_duration
	for i: int in _pieces.size():
		if not _is_in_pan[i]:
			continue
		var piece: Control = _pieces[i]
		piece.position = _starts[i].lerp(_lands[i], t) - piece.size / 2.0
		piece.scale = Vector2.ONE * (1.0 + toss_grow * height)
		piece.rotation += spin if i % 2 == 0 else -spin
	_shadow.modulate.a = shadow_max_alpha * t


## 조각들이 내려왔다. 팬 안에 들어간 조각만 남고 나머지는 불판에 떨어진다.
func _land() -> void:
	_shadow.hide()
	_jolt_pan()
	for i: int in _pieces.size():
		if not _is_in_pan[i]:
			continue
		var offset: Vector2 = _lands[i] - _pan_point
		if offset.length() <= _catch_radius - piece_margin:
			_pan_offsets[i] = offset
		else:
			_drop_piece(i)
	var landing_distance: float = (_landing_point - _pan_point).length()
	if landing_distance <= _catch_radius:
		# 그림자 가운데가 팬 한가운데 = 0, 가장자리 = 1
		_register_hit(landing_distance / _catch_radius)
		_tosses_done += 1
		_progress_label.text = CATCH_FORMAT % [_tosses_done, _tosses_needed]
	else:
		_progress_label.text = MISS_FORMAT % [_tosses_done, _tosses_needed]
	if _is_in_pan.count(true) <= fail_piece_count:
		_spill()
		return
	_state = TossState.RESTING
	_place_resting_pieces()
	if _tosses_done >= _tosses_needed:
		_complete(DONE_TEXT)


## 조각 하나가 팬 테두리에 톡 튕겨 팬 밖 불판에 떨어져 그대로 놓인다.
func _drop_piece(index: int) -> void:
	var piece: Control = _pieces[index]
	_is_in_pan[index] = false
	piece.reparent(_fallen_layer)
	var offset: Vector2 = _lands[index] - _pan_point
	var outside: float = maxf(offset.length(), pan_radius + fallen_clearance)
	var rest: Vector2 = _pan_point + offset.normalized() * outside
	piece.position = _lands[index] - piece.size / 2.0
	piece.self_modulate = _food_color * fallen_tint
	piece.scale = Vector2(1.0, fall_squash)
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(piece, "position", rest - piece.size / 2.0, fall_bounce_duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "scale", Vector2.ONE, fall_squash_duration)


## 너무 많이 흘렸다. 잠깐 뒤 조각을 모두 팬에 다시 담고 이 단계를 처음부터 한다 (손해 없음).
func _spill() -> void:
	_state = TossState.SPILLED
	_progress_label.text = SPILL_TEXT
	# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
	await get_tree().create_timer(spill_wait, false).timeout
	if _state != TossState.SPILLED:
		return
	var tween: Tween = create_tween().set_parallel()
	for i: int in _pieces.size():
		if _is_in_pan[i]:
			continue
		var piece: Control = _pieces[i]
		piece.reparent(_food_layer)
		piece.self_modulate = _food_color
		_is_in_pan[i] = true
		_pan_offsets[i] = _random_spread()
		tween.tween_property(piece, "position", _pan_point + _pan_offsets[i] - piece.size / 2.0, spill_return_duration)
	await tween.finished
	if _state != TossState.SPILLED:
		return
	_tosses_done = 0
	_reset_hits()
	_state = TossState.RESTING
	_place_resting_pieces()
	_progress_label.text = READY_TEXT


func _jolt_pan() -> void:
	_pan.scale = Vector2.ONE * pan_jolt_scale
	var tween: Tween = create_tween()
	tween.tween_property(_pan, "scale", Vector2.ONE, pan_jolt_duration)
