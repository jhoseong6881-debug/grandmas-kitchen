class_name PlateMinigame
extends Minigame
## 담기 미니게임. 버튼을 꾹 누르고 있으면 국자가 기울어 음식이 흘러내리며 그릇에 차오르고,
## 금색 띠("딱 좋을 만큼")에서 손을 떼면 한 그릇이 완성된다. 그릇 여러 개를 차례로 채운다.
## 모자라거나 많거나 넘치면 그릇을 비우고 다시 담는다. 벌칙은 없다.
## 누르기/손 떼기 입력, 연타 방지, 완벽 표시는 공통 틀(Minigame)이 맡는다.

const READY_FORMAT: String = "0 / %d"
const HIT_FORMAT: String = "쏙! %d / %d"
const UNDER_FORMAT: String = "조금 모자라요… 다시 담아요 %d / %d"
const OVER_FORMAT: String = "조금 많아요… 다시 담아요 %d / %d"
const OVERFLOW_FORMAT: String = "넘쳤어요! 다시 담아요 %d / %d"
const DONE_TEXT: String = "예쁘게 완성했어요!"

## 채울 그릇 수
@export var bowl_count: int = 3
## 꾹 누르고 있을 때 차오르는 속도 (1초에 그릇의 몇 배만큼. 0.5면 2초에 가득)
@export var fill_speed: float = 0.5
## 금색 띠의 높이 (그릇 높이에 대한 비율). 클수록 쉽다.
@export var target_band_height: float = 0.12
## 판정을 후하게 해 주는 여유 (그릇 높이에 대한 비율). 금색 띠 위아래로 이만큼 벗어나도 맞은 것으로 친다. 화면에는 안 보인다.
@export var judge_margin: float = 0.02
## 그릇마다 금색 띠 가운데가 놓이는 높이의 범위 (그릇 높이에 대한 비율)
@export var target_level_min: float = 0.5
@export var target_level_max: float = 0.85
## 이보다 적게 채우고 손을 떼면 실수로 살짝 누른 것으로 보고 빗나감으로 치지 않는다.
@export var accidental_tap_level: float = 0.05
## 빗나갔을 때 그릇이 비워지는 시간(초)
@export var empty_duration: float = 0.35
## 한 그릇 완성했을 때 그릇이 살짝 커졌다 돌아오는 정도와 시간(초)
@export var bounce_scale: float = 1.05
@export var bounce_duration: float = 0.1
@export var bowl_done_color: Color = Color(1, 0.84, 0.25)
@export var bowl_pending_color: Color = Color(1, 1, 1, 0.3)
## 그릇에 담기는 음식 색 (그림이 생기기 전 임시 색). 흘러내리는 줄기와 튀는 알갱이도 이 색이다.
@export var food_color: Color = Color(0.97, 0.93, 0.82)
## 국자가 기울어지는 각도(라디안, 음수 = 손잡이가 올라감)와 시간(초)
@export var ladle_pour_angle: float = -0.6
@export var ladle_tilt_duration: float = 0.12
@export var stream_width: float = 26.0
## 튀는 알갱이가 음식 위에서도 보이도록 음식 색보다 이만큼 어둡게 한다 (0 ~ 1)
@export var splash_darken: float = 0.25

## 이번 단계의 그릇 수와 차오르는 빠르기 (요리 단계에서 정한 값, 없으면 위의 기본값)
var _bowl_count: int = 0
var _fill_speed: float = 0.5
var _bowls_done: int = 0
## 지금 그릇에 찬 양 (0 = 빈 그릇, 1 = 가득)
var _fill_level: float = 0.0
var _target_level: float = 0.0
var _is_holding: bool = false
var _is_emptying: bool = false

@onready var _bowl: Control = %Bowl
@onready var _bowl_inner: Control = %BowlInner
@onready var _fill: Control = %Fill
@onready var _ladle: Control = %Ladle
@onready var _ladle_lip: Control = %LadleLip
@onready var _stream: ColorRect = %Stream
@onready var _splash: CPUParticles2D = %Splash
@onready var _target_band: ColorRect = %TargetBand
@onready var _bowl_dots: HBoxContainer = %BowlDots
@onready var _bowl_dot_template: Control = %BowlDotTemplate


func _ready() -> void:
	super()
	_bowl.pivot_offset = _bowl.size / 2.0
	_bowl_dot_template.hide()
	# 국자는 따르는 입구(LadleLip)를 중심으로 기울어진다.
	_ladle.pivot_offset = _ladle_lip.position
	_fill.self_modulate = food_color
	_stream.color = food_color
	_splash.color = food_color.darkened(splash_darken)


func _on_start(recipe: Recipe) -> void:
	_bowl_count = _step_count(bowl_count)
	_fill_speed = fill_speed * _speed
	_bowls_done = 0
	for dot: Node in _bowl_dots.get_children():
		dot.queue_free()
	for i: int in _bowl_count:
		var dot: Control = _bowl_dot_template.duplicate()
		dot.modulate = bowl_pending_color
		dot.show()
		_bowl_dots.add_child(dot)
	_is_holding = false
	_is_emptying = false
	_ladle.rotation = 0.0
	_stream.hide()
	_splash.emitting = false
	_start_new_bowl()
	_title_label.text = _step_title(Recipe.MinigameType.PLATE, recipe.display_name)
	_progress_label.text = READY_FORMAT % _bowl_count


func _process(delta: float) -> void:
	super(delta)
	if not _is_playing or not _is_holding:
		return
	_set_fill_level(_fill_level + _fill_speed * delta)
	_update_stream()
	if _fill_level >= 1.0:
		_is_holding = false
		_set_pouring(false)
		_miss(OVERFLOW_FORMAT)


func _on_press() -> void:
	if not _is_emptying:
		_is_holding = true
		_set_pouring(true)


func _on_release() -> void:
	if not _is_holding:
		return
	_is_holding = false
	_set_pouring(false)
	if _fill_level < accidental_tap_level:
		_set_fill_level(0.0)
		return
	if is_fill_on_target():
		_finish_bowl()
	elif _fill_level < _target_level:
		_miss(UNDER_FORMAT)
	else:
		_miss(OVER_FORMAT)


func is_fill_on_target() -> bool:
	return absf(_fill_level - _target_level) <= target_band_height / 2.0 + judge_margin


func _finish_bowl() -> void:
	_bowl_dots.get_child(_bowls_done).modulate = bowl_done_color
	_bowls_done += 1
	_progress_label.text = HIT_FORMAT % [_bowls_done, _bowl_count]
	_bowl.scale = Vector2.ONE * bounce_scale
	var tween: Tween = create_tween()
	tween.tween_property(_bowl, "scale", Vector2.ONE, bounce_duration)
	if _bowls_done >= _bowl_count:
		_complete(DONE_TEXT)
	else:
		tween.tween_callback(_start_new_bowl)


func _miss(text_format: String) -> void:
	_register_miss()
	_progress_label.text = text_format % [_bowls_done, _bowl_count]
	_is_emptying = true
	var tween: Tween = create_tween()
	tween.tween_method(_set_fill_level, _fill_level, 0.0, empty_duration)
	tween.tween_callback(func() -> void: _is_emptying = false)


## 따르기 시작/멈춤: 국자를 기울이거나 세우고, 흘러내리는 줄기와 튀는 알갱이를 켜고 끈다.
func _set_pouring(is_pouring: bool) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_ladle, "rotation", ladle_pour_angle if is_pouring else 0.0, ladle_tilt_duration)
	_stream.visible = is_pouring
	_splash.emitting = is_pouring
	if is_pouring:
		_update_stream()


## 줄기는 국자 입구에서 음식 윗면까지 이어지고, 알갱이는 윗면에서 튄다.
func _update_stream() -> void:
	var lip: Vector2 = _ladle_lip.get_global_rect().get_center() - global_position
	var inner_rect: Rect2 = _bowl_inner.get_global_rect()
	var surface_y: float = inner_rect.end.y - _fill.size.y - global_position.y
	_stream.position = Vector2(lip.x - stream_width / 2.0, lip.y)
	_stream.size = Vector2(stream_width, maxf(surface_y - lip.y, 0.0))
	_splash.position = Vector2(lip.x, surface_y)


func _start_new_bowl() -> void:
	_set_fill_level(0.0)
	_target_level = randf_range(target_level_min, target_level_max)
	var inner_height: float = _bowl_inner.size.y
	_target_band.size.y = inner_height * target_band_height
	_target_band.position.y = inner_height * (1.0 - _target_level - target_band_height / 2.0)


func _set_fill_level(level: float) -> void:
	_fill_level = clampf(level, 0.0, 1.0)
	var inner_height: float = _bowl_inner.size.y
	_fill.size.y = inner_height * _fill_level
	_fill.position.y = inner_height - _fill.size.y
