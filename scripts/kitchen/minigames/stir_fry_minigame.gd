class_name StirFryMinigame
extends Minigame
## 볶기 미니게임 (웍 토스). 누르면 팬이 튀며 재료가 포물선을 그리고 날아오른다.
## 재료가 팬 위 금색 구역으로 내려왔을 때 누르면 받아서 다시 토스한다. tosses_needed 번 이어 가면 완성.
## 너무 일찍 누르거나 놓쳐서 팬에 떨어지면 빗나감이지만 벌칙은 없다. 다시 누르면 또 띄운다.
## 누르기 입력, 연타 방지, 완벽 표시는 공통 틀(Minigame)이 맡는다.

enum TossState { RESTING, AIRBORNE }

const READY_TEXT: String = "눌러서 재료를 띄워요"
const CATCH_FORMAT: String = "착! %d / %d"
const EARLY_FORMAT: String = "아직 높아요! %d / %d"
const DROP_FORMAT: String = "툭… 다시 띄워요 %d / %d"
const DONE_TEXT: String = "잘 익었어요!"

@export var tosses_needed: int = 6
## 재료가 튀어 오르는 최고 높이(픽셀)와 한 번 날아갔다 내려오는 시간(초)
@export var toss_height: float = 360.0
@export var toss_duration: float = 0.9
## 받을 수 있는 구간: 날아가는 시간 중 마지막 이 비율만큼 (금색 구역). 클수록 쉽다.
@export var catch_window: float = 0.14
## 팬에 내려앉은 뒤에도 이 시간(초)까지는 받은 것으로 친다. 화면에는 안 보인다.
@export var landing_grace: float = 0.06
## 날아오르는 재료 조각 수, 조각들이 좌우로 퍼지는 폭(픽셀), 조각마다 높이가 달라지는 정도
@export var food_piece_count: int = 5
@export var food_spread: float = 160.0
@export var food_height_variance: float = 0.15
## 조각이 날아가며 도는 바퀴 수
@export var food_spin_turns: float = 1.0
## 그림이 아직 없는 재료 조각의 임시 색
@export var food_color: Color = Color(0.93, 0.55, 0.25)
## 누를 때 팬이 튀는 각도(라디안)와 시간(초)
@export var pan_jolt_angle: float = -0.08
@export var pan_jolt_duration: float = 0.15
## 불꽃이 일렁이는 빠르기와 정도
@export var flame_flicker_speed: float = 9.0
@export var flame_flicker_amount: float = 0.12

## 이번 단계의 토스 수, 한 번 날아가는 시간, 재료 색 (요리 단계에서 정한 값, 없으면 위의 기본값)
var _tosses_needed: int = 0
var _toss_duration: float = 0.9
var _food_color: Color
var _state: TossState = TossState.RESTING
var _toss_time: float = 0.0
var _tosses_done: int = 0
var _flame_time: float = 0.0
var _food_pieces: Array[Control] = []
## 조각마다 팬 가운데에서 떨어진 좌우 거리와 높이 배율
var _piece_offsets: Array[float] = []
var _piece_height_factors: Array[float] = []

@onready var _pan: Control = %Pan
@onready var _food_layer: Control = %FoodLayer
@onready var _food_template: Control = %FoodTemplate
@onready var _catch_band: ColorRect = %CatchBand
@onready var _flame: Control = %Flame


func _ready() -> void:
	super()
	_food_template.hide()
	_pan.pivot_offset = _pan.size / 2.0
	_flame.pivot_offset = Vector2(_flame.size.x / 2.0, _flame.size.y)


func _on_start(recipe: Recipe) -> void:
	_tosses_needed = _step_count(tosses_needed)
	_toss_duration = toss_duration / _speed
	_food_color = _step_color(food_color)
	_state = TossState.RESTING
	_toss_time = 0.0
	_tosses_done = 0
	for piece: Node in _food_layer.get_children():
		piece.queue_free()
	_food_pieces.clear()
	_piece_offsets.clear()
	_piece_height_factors.clear()
	for i: int in food_piece_count:
		var piece: Control = _food_template.duplicate()
		piece.self_modulate = _food_color
		piece.pivot_offset = piece.size / 2.0
		piece.show()
		_food_layer.add_child(piece)
		_food_pieces.append(piece)
		var spread_ratio: float = 0.0 if food_piece_count == 1 else float(i) / (food_piece_count - 1) - 0.5
		_piece_offsets.append(spread_ratio * food_spread)
		_piece_height_factors.append(1.0 + randf_range(-food_height_variance, food_height_variance))
	_update_food(0.0)
	# 금색 구역의 높이 = 받을 수 있는 구간이 시작될 때 재료의 높이
	var catch_height: float = _height_at(1.0 - catch_window)
	_catch_band.position.y = _food_layer.position.y - catch_height
	_catch_band.size.y = catch_height
	_clear_secret_zone(_catch_band)
	_title_label.text = _step_title(Recipe.MinigameType.STIR_FRY, _default_subject(recipe))
	_progress_label.text = READY_TEXT


func _process(delta: float) -> void:
	super(delta)
	if not visible:
		return
	_flame_time += delta
	_flame.scale.y = 1.0 + sin(_flame_time * flame_flicker_speed) * flame_flicker_amount
	if not _is_playing or _state != TossState.AIRBORNE:
		return
	_toss_time += delta
	var t: float = _toss_time / _toss_duration
	if t > 1.0 + landing_grace / _toss_duration:
		_drop()
	else:
		_update_food(t)


func _on_press() -> void:
	_jolt_pan()
	if _state == TossState.RESTING:
		_launch()
	elif is_in_catch_window():
		_catch()
	else:
		_register_miss()
		_progress_label.text = EARLY_FORMAT % [_tosses_done, _tosses_needed]


## 금색 구역 안에 비법 자리를 그린다. 위쪽이 금색 구역에 막 들어온 때, 아래쪽이 팬에 닿을 때.
func _show_secret_zone(start: float, end: float) -> void:
	var catch_height: float = _catch_band.size.y
	var top: float = catch_height - _height_at(1.0 - catch_window + start * catch_window)
	var bottom: float = catch_height - _height_at(1.0 - catch_window + end * catch_window)
	_make_secret_zone(_catch_band, Rect2(0.0, top, _catch_band.size.x, bottom - top))


func is_in_catch_window() -> bool:
	if _state != TossState.AIRBORNE:
		return false
	var t: float = _toss_time / _toss_duration
	return t >= 1.0 - catch_window and t <= 1.0 + landing_grace / _toss_duration


func _launch() -> void:
	_state = TossState.AIRBORNE
	_toss_time = 0.0


func _catch() -> void:
	# 금색 구역에 들어온 때 = 0, 팬에 닿을 때 = 1
	_register_hit((_toss_time / _toss_duration - (1.0 - catch_window)) / catch_window)
	_tosses_done += 1
	_progress_label.text = CATCH_FORMAT % [_tosses_done, _tosses_needed]
	if _tosses_done >= _tosses_needed:
		_state = TossState.RESTING
		_update_food(0.0)
		_complete(DONE_TEXT)
	else:
		_launch()


## 받지 못하고 팬에 떨어졌다. 다시 누르면 띄운다.
func _drop() -> void:
	_register_miss()
	_state = TossState.RESTING
	_update_food(0.0)
	_progress_label.text = DROP_FORMAT % [_tosses_done, _tosses_needed]


## t: 0 = 팬에서 출발, 0.5 = 가장 높은 곳, 1 = 팬에 도착
func _height_at(t: float) -> float:
	return maxf(4.0 * toss_height * t * (1.0 - t), 0.0)


func _update_food(t: float) -> void:
	var clamped_t: float = clampf(t, 0.0, 1.0)
	for i: int in _food_pieces.size():
		var piece: Control = _food_pieces[i]
		var height: float = _height_at(clamped_t) * _piece_height_factors[i]
		piece.position = Vector2(_piece_offsets[i] - piece.size.x / 2.0, -piece.size.y - height)
		piece.rotation = clamped_t * TAU * food_spin_turns * (1.0 if i % 2 == 0 else -1.0)


func _jolt_pan() -> void:
	_pan.rotation = pan_jolt_angle
	var tween: Tween = create_tween()
	tween.tween_property(_pan, "rotation", 0.0, pan_jolt_duration)
