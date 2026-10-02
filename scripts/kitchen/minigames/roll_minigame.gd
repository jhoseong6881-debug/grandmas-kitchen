class_name RollMinigame
extends Minigame
## 말기 미니게임 (붓고 → 돌돌 말기). 계란말이를 한 겹씩 쌓는다. 한 겹은 두 동작이다.
##   1. 붓기: 꾹 누르고 있으면 계란물이 팬에 퍼진다. 금색 칸에서 손을 떼면 성공.
##      일찍 떼면 빗나감이지만 다시 눌러 이어서 부으면 된다. 끝까지 차면 저절로 멈춘다(빗나감).
##   2. 말기: 말린 계란이 퍼진 계란물 위를 굴러간다. 끝의 금색 칸에 닿을 때 누르면 '착' 접힌다.
##      일찍 누르면 빗나감이고 계속 굴러간다. 끝을 지나치면 빗나감이지만 그대로 접힌다.
## layers_needed 겹을 다 말면 완성. 겹이 쌓일수록 말린 계란이 두툼해진다.
## 누르기/손 떼기 입력, 연타 방지, 완벽 표시는 공통 틀(Minigame)이 맡는다.

enum Phase { POUR_READY, POURING, ROLLING, MOVING }

const LAYER_FORMAT: String = "%d / %d겹 · %s"
const POUR_STEP_TEXT: String = "붓기"
const ROLL_STEP_TEXT: String = "말기"
const POUR_READY_TEXT: String = "꾹 눌러서 계란물을 부어요"
const POUR_SHORT_TEXT: String = "조금 모자라요. 다시 눌러서 더 부어요"
const POUR_GOOD_TEXT: String = "좋아요! 이제 금색 칸에서 눌러 말아요"
const POUR_OVER_TEXT: String = "앗, 조금 많이 부었어요. 금색 칸에서 눌러 말아요"
const ROLL_EARLY_TEXT: String = "아직이에요. 끝까지 굴러가면 눌러요"
const ROLL_GOOD_TEXT: String = "착! 한 겹 말았어요"
const ROLL_LATE_TEXT: String = "앗, 조금 늦었어요. 그래도 말았어요"
const DONE_TEXT: String = "돌돌 예쁘게 말았어요!"

## 말아야 하는 겹 수
@export var layers_needed: int = 3
## 꾹 누르고 있을 때 계란물이 퍼지는 속도 (1초에 팬 빈자리의 몇 배만큼. 0.6이면 약 1.7초에 가득)
@export var pour_speed: float = 0.6
## 붓기 금색 칸 (팬 빈자리에 대한 비율). 이 사이에서 손을 떼면 성공. 넓을수록 쉽다.
@export_range(0.0, 1.0) var pour_target_start: float = 0.78
@export_range(0.0, 1.0) var pour_target_end: float = 0.92
## 이보다 적게 붓고 손을 떼면 실수로 살짝 누른 것으로 보고 빗나감으로 치지 않는다.
@export var accidental_tap_level: float = 0.05
## 말린 계란이 퍼진 계란물 끝까지 굴러가는 시간(초)
@export var roll_duration: float = 1.2
## 말기 금색 칸: 굴러가는 시간 중 마지막 이 비율만큼. 클수록 쉽다.
@export var roll_catch_window: float = 0.22
## 금색 칸 양쪽으로 이만큼 더 봐준다. 화면에는 안 보인다.
@export var judge_margin: float = 0.02
## 끝에 닿은 뒤에도 이 시간(초)까지는 제때 누른 것으로 친다. 화면에는 안 보인다.
@export var roll_grace: float = 0.08
## 말린 계란의 처음 두께와 한 겹마다 두꺼워지는 정도(픽셀)
@export var roll_start_width: float = 36.0
@export var roll_growth: float = 36.0
## 다 만 계란이 처음 자리로 밀려 돌아가는 시간(초)
@export var push_back_duration: float = 0.35
## 한 겹 말았을 때 계란이 살짝 커졌다 돌아오는 정도와 시간(초)
@export var bounce_scale: float = 1.08
@export var bounce_duration: float = 0.1

## 이번 단계의 겹 수, 붓는 빠르기, 굴러가는 시간 (요리 단계에서 정한 값, 없으면 위의 기본값)
var _layers_needed: int = 0
var _pour_speed: float = 0.6
var _roll_duration: float = 1.2
var _phase: Phase = Phase.POUR_READY
var _layers_done: int = 0
## 지금 겹에서 부은 양 (0 = 없음, 1 = 팬 빈자리 끝까지)
var _pour_level: float = 0.0
## 말기에서 굴러간 정도 (0 = 출발, 1 = 계란물 끝)
var _roll_t: float = 0.0
var _roll_width: float = 36.0

@onready var _pan_inner: Control = %PanInner
@onready var _sheet: ColorRect = %Sheet
@onready var _roll: Control = %Roll
@onready var _pour_zone: ColorRect = %PourZone
@onready var _roll_zone: ColorRect = %RollZone
@onready var _side_label: Label = %SideLabel


func _on_start(recipe: Recipe) -> void:
	_layers_needed = _step_count(layers_needed)
	_pour_speed = pour_speed * _speed
	_roll_duration = roll_duration / _speed
	_layers_done = 0
	_roll_width = roll_start_width
	_title_label.text = _step_title(Recipe.MinigameType.ROLL, _default_subject(recipe))
	_roll.position.x = 0.0
	_start_pour()


func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing:
		return
	if _phase == Phase.POURING:
		_pour_level = minf(_pour_level + _pour_speed * delta, 1.0)
		_update_sheet()
		if _pour_level >= 1.0:
			_register_miss()
			_finish_pour(POUR_OVER_TEXT)
	elif _phase == Phase.ROLLING:
		_roll_t += delta / _roll_duration
		_update_roll()
		if _roll_t > 1.0 + roll_grace / _roll_duration:
			_register_miss()
			_finish_layer(ROLL_LATE_TEXT)


func _on_press() -> void:
	if _phase == Phase.POUR_READY:
		_phase = Phase.POURING
	elif _phase == Phase.ROLLING:
		if is_in_roll_window():
			_finish_layer(ROLL_GOOD_TEXT)
		else:
			_register_miss()
			_progress_label.text = ROLL_EARLY_TEXT


func _on_release() -> void:
	if _phase != Phase.POURING:
		return
	if _pour_level < accidental_tap_level:
		_phase = Phase.POUR_READY
		return
	if _pour_level < pour_target_start - judge_margin:
		_register_miss()
		_phase = Phase.POUR_READY
		_progress_label.text = POUR_SHORT_TEXT
	elif _pour_level <= pour_target_end + judge_margin:
		_finish_pour(POUR_GOOD_TEXT)
	else:
		_register_miss()
		_finish_pour(POUR_OVER_TEXT)


func is_in_roll_window() -> bool:
	return _phase == Phase.ROLLING and _roll_t >= 1.0 - roll_catch_window - judge_margin \
			and _roll_t <= 1.0 + roll_grace / _roll_duration


# --- 붓기 ---

## 새 겹을 붓기 시작한다. 말린 계란은 팬 왼쪽 끝에 있다.
func _start_pour() -> void:
	_phase = Phase.POUR_READY
	_pour_level = 0.0
	_roll.size.x = _roll_width
	_roll.pivot_offset = _roll.size / 2.0
	_update_sheet()
	var free_width: float = _pour_free_width()
	_pour_zone.position.x = _roll_width + pour_target_start * free_width
	_pour_zone.size.x = (pour_target_end - pour_target_start) * free_width
	_pour_zone.show()
	_roll_zone.hide()
	_sheet.show()
	_progress_label.text = POUR_READY_TEXT
	_update_side_label(POUR_STEP_TEXT)


## 다 부었으면 말기를 시작한다. 금색 칸은 계란물 끝에서 굴러가는 시간의 마지막 roll_catch_window 만큼이다.
func _finish_pour(message: String) -> void:
	_phase = Phase.ROLLING
	_progress_label.text = message
	_roll_t = 0.0
	_pour_zone.hide()
	var zone_start: float = _roll_right_at(1.0 - roll_catch_window)
	_roll_zone.position.x = zone_start
	_roll_zone.size.x = _sheet_end() - zone_start
	_roll_zone.show()
	_update_side_label(ROLL_STEP_TEXT)


# --- 말기 ---

## 한 겹을 다 말았다. 계란이 두꺼워지고, 처음 자리로 밀려 돌아간다. 다 말았으면 완성.
func _finish_layer(message: String) -> void:
	_phase = Phase.MOVING
	_progress_label.text = message
	_layers_done += 1
	_roll_zone.hide()
	_sheet.hide()
	# 두꺼워진 계란의 오른쪽 끝이 계란물이 있던 끝에 오게 한다.
	var end_x: float = _sheet_end()
	_roll_width += roll_growth
	_roll.size.x = _roll_width
	_roll.position.x = end_x - _roll_width
	_roll.pivot_offset = _roll.size / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(_roll, "scale", Vector2.ONE * bounce_scale, bounce_duration)
	tween.tween_property(_roll, "scale", Vector2.ONE, bounce_duration)
	if _layers_done >= _layers_needed:
		_update_side_label(ROLL_STEP_TEXT)
		_complete(DONE_TEXT)
		return
	tween.tween_property(_roll, "position:x", 0.0, push_back_duration) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(_start_pour)


# --- 화면 ---

## 팬에서 말린 계란 오른쪽의 빈자리 폭
func _pour_free_width() -> float:
	return _pan_inner.size.x - _roll_width


## 부은 계란물의 오른쪽 끝 (팬 안쪽 기준 x)
func _sheet_end() -> float:
	return _roll_width + _pour_level * _pour_free_width()


## 말기에서 굴러간 정도 t 일 때 말린 계란의 오른쪽 끝 x
func _roll_right_at(t: float) -> float:
	return _roll_width + clampf(t, 0.0, 1.0) * (_sheet_end() - _roll_width)


func _update_sheet() -> void:
	_sheet.position.x = _roll_width
	_sheet.size.x = _sheet_end() - _roll_width


## 말린 계란이 굴러간 만큼 오른쪽으로 가고, 지나간 자리의 계란물은 말려 들어가 사라진다.
func _update_roll() -> void:
	var right: float = _roll_right_at(_roll_t)
	_roll.position.x = right - _roll_width
	_sheet.position.x = right
	_sheet.size.x = maxf(_sheet_end() - right, 0.0)


func _update_side_label(step_text: String) -> void:
	_side_label.text = LAYER_FORMAT % [mini(_layers_done + 1, _layers_needed), _layers_needed, step_text]
