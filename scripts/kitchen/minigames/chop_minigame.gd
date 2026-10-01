class_name ChopMinigame
extends Minigame
## 썰기 미니게임. 칼이 재료 위를 좌우로 오가고, 칼이 썰 자리(하얀 띠)에 왔을 때 누르면 한 번 썬다.
## 누르기 입력, 연타 방지, 완벽 표시는 공통 틀(Minigame)이 맡는다.

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
## 판정을 후하게 해 주는 여유 폭(픽셀). 하얀 띠 양옆으로 이만큼 벗어나도 맞은 것으로 친다. 화면에는 안 보인다.
@export var judge_margin: float = 10.0
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


func _ready() -> void:
	super()
	_ingredient_left = _ingredient.position.x
	_ingredient_full_width = _ingredient.size.x
	_knife.pivot_offset = Vector2(_knife.size.x / 2.0, 0.0)


func _on_start(recipe: Recipe) -> void:
	_chop_count = 0
	for slice: Node in _slices.get_children():
		slice.queue_free()
	_ingredient.color = ingredient_color
	_ingredient.size.x = _ingredient_full_width
	_knife_x = _ingredient_left
	_knife_direction = 1.0
	_update_knife()
	_update_target()
	_target_zone.show()
	var ingredient_name: String = FALLBACK_INGREDIENT_NAME
	if not recipe.ingredients.is_empty():
		ingredient_name = recipe.ingredients[0].display_name
	_title_label.text = TITLE_FORMAT % ingredient_name
	_progress_label.text = READY_FORMAT % chops_needed


func _process(delta: float) -> void:
	super(delta)
	if not _is_playing:
		return
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


func _on_press() -> void:
	if is_knife_on_target():
		_chop()
	else:
		_miss()


func is_knife_on_target() -> bool:
	return absf(_knife_x - _target_center) <= target_width / 2.0 + judge_margin


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
		_target_zone.hide()
		_complete(DONE_TEXT)
	else:
		_update_target()


func _miss() -> void:
	_register_miss()
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
