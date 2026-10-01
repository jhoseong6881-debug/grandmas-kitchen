class_name ChopMinigame
extends Control
## 썰기 미니게임. 칼이 재료 위를 좌우로 오가고, 칼이 썰 자리(하얀 띠)에 왔을 때
## 클릭, 스페이스/Enter, 게임패드 A 버튼(ui_accept)을 누르면 한 번 썬다.
## 빗나가도 벌칙은 없다. 시간 제한과 실패 없이, chops_needed 번 썰면 끝나고 finished 시그널을 보낸다.

signal finished

const TITLE_FORMAT: String = "%s 썰기"
const READY_FORMAT: String = "0 / %d"
const HIT_FORMAT: String = "탁! %d / %d"
const MISS_FORMAT: String = "틱… 다시 한 번! %d / %d"
const DONE_TEXT: String = "다 썰었어요!"
const FALLBACK_INGREDIENT_NAME: String = "재료"

@export var chops_needed: int = 8
## 칼이 움직이는 속도(초당 픽셀)
@export var knife_speed: float = 450.0
## 썰 자리(하얀 띠)의 넓이(픽셀). 넓을수록 쉽다.
@export var target_width: float = 50.0
## 한 번 누른 뒤 다음 입력을 받기까지 쉬는 시간(초). 마구 눌러 통과하는 것을 막는다.
@export var press_cooldown: float = 0.15
## 다 썬 뒤 "다 썰었어요!"를 보여 주는 시간(초)
@export var finish_delay: float = 0.8
## 썰 때마다 도마가 살짝 커졌다 돌아오는 정도와 시간(초)
@export var bounce_scale: float = 1.03
@export var bounce_duration: float = 0.08
## 빗나갔을 때 칼이 흔들리는 각도(라디안)와 시간(초)
@export var miss_wobble_angle: float = 0.15
@export var miss_wobble_duration: float = 0.2
@export var slice_size: Vector2 = Vector2(24, 120)
## 그림이 아직 없는 재료와 조각에 쓰는 임시 색
@export var ingredient_color: Color = Color(0.85, 0.55, 0.3)

var _chop_count: int = 0
var _is_chopping: bool = false
var _cooldown_left: float = 0.0
var _ingredient_left: float = 0.0
var _ingredient_full_width: float = 0.0
## 칼 중심의 x 위치(도마 기준)와 움직이는 방향(1 = 오른쪽, -1 = 왼쪽)
var _knife_x: float = 0.0
var _knife_direction: float = 1.0
var _target_center: float = 0.0

@onready var _board: Control = %Board
@onready var _ingredient: ColorRect = %Ingredient
@onready var _target_zone: ColorRect = %TargetZone
@onready var _knife: ColorRect = %Knife
@onready var _slices: HFlowContainer = %Slices
@onready var _title_label: Label = %TitleLabel
@onready var _progress_label: Label = %ProgressLabel


func _ready() -> void:
	_ingredient_left = _ingredient.position.x
	_ingredient_full_width = _ingredient.size.x
	_knife.pivot_offset = Vector2(_knife.size.x / 2.0, 0.0)
	hide()


func start(recipe: Recipe) -> void:
	_chop_count = 0
	_is_chopping = true
	_cooldown_left = 0.0
	for slice: Node in _slices.get_children():
		slice.queue_free()
	_ingredient.color = ingredient_color
	_ingredient.size.x = _ingredient_full_width
	_knife_x = _ingredient_left
	_knife_direction = 1.0
	_update_knife()
	_update_target()
	var ingredient_name: String = FALLBACK_INGREDIENT_NAME
	if not recipe.ingredients.is_empty():
		ingredient_name = recipe.ingredients[0].display_name
	_title_label.text = TITLE_FORMAT % ingredient_name
	_progress_label.text = READY_FORMAT % chops_needed
	show()
	# 포커스를 가져와야 키보드와 게임패드 입력이 뒤에 있는 버튼으로 새지 않는다.
	grab_focus()


func _process(delta: float) -> void:
	if not _is_chopping:
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	# 칼은 재료의 처음 길이 안에서 왔다 갔다 한다.
	_knife_x += knife_speed * _knife_direction * delta
	var track_right: float = _ingredient_left + _ingredient_full_width
	if _knife_x >= track_right:
		_knife_x = track_right
		_knife_direction = -1.0
	elif _knife_x <= _ingredient_left:
		_knife_x = _ingredient_left
		_knife_direction = 1.0
	_update_knife()


func _gui_input(event: InputEvent) -> void:
	if not _is_chopping:
		return
	var is_click: bool = event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if not (is_click or event.is_action_pressed("ui_accept")):
		return
	accept_event()
	if _cooldown_left > 0.0:
		return
	_cooldown_left = press_cooldown
	if is_knife_on_target():
		_chop()
	else:
		_miss()


func is_knife_on_target() -> bool:
	return absf(_knife_x - _target_center) <= target_width / 2.0


func _chop() -> void:
	_chop_count += 1
	_ingredient.size.x = _ingredient_full_width * (1.0 - float(_chop_count) / chops_needed)
	var slice: ColorRect = ColorRect.new()
	slice.color = ingredient_color
	slice.custom_minimum_size = slice_size
	_slices.add_child(slice)
	_bounce_board()
	_progress_label.text = HIT_FORMAT % [_chop_count, chops_needed]
	if _chop_count >= chops_needed:
		_finish()
	else:
		_update_target()


func _miss() -> void:
	_progress_label.text = MISS_FORMAT % [_chop_count, chops_needed]
	_knife.rotation = miss_wobble_angle
	var tween: Tween = create_tween()
	tween.tween_property(_knife, "rotation", 0.0, miss_wobble_duration)


## 썰 자리는 지금 남은 재료의 오른쪽 끝, 한 조각 두께만큼 안쪽에 둔다.
func _update_target() -> void:
	var slice_width: float = _ingredient_full_width / chops_needed
	_target_center = _ingredient_left + _ingredient.size.x - slice_width / 2.0
	_target_zone.position.x = _target_center - target_width / 2.0
	_target_zone.size.x = target_width


func _update_knife() -> void:
	_knife.position.x = _knife_x - _knife.size.x / 2.0


func _bounce_board() -> void:
	_board.scale = Vector2.ONE * bounce_scale
	var tween: Tween = create_tween()
	tween.tween_property(_board, "scale", Vector2.ONE, bounce_duration)


func _finish() -> void:
	_is_chopping = false
	_target_zone.hide()
	_progress_label.text = DONE_TEXT
	await get_tree().create_timer(finish_delay).timeout
	_target_zone.show()
	hide()
	finished.emit()
