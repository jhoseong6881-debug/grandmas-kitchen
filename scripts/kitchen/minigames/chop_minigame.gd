class_name ChopMinigame
extends Minigame
## 썰기 미니게임 (손으로 쓱쓱 썰기). 칼이 마우스를 따라 재료 위를 움직인다.
## 마우스를 누른 채 아래로 쓱 끌면 칼이 내려가고, 끝까지 내려가면 칼 자리에서 한 조각이 잘려 나간다.
## 다시 위로 올리면(또는 손을 떼면) 칼이 들리고, 옆으로 옮겨 다음 칼질을 한다.
## 게임패드·방향키: 좌우로 칼을 옮기고, 아래로 당기면 썬다. 스페이스·Ⓐ 누르기는 쓰지 않는다.
## 하얀 칸은 "여기 썰면 고른 두께" 안내다. 아무 데서나 썰어도 되고 빗나감·실패는 없다 (완벽 도장도 없다).
## 할머니 비법 자리와 부탁 자리는 하얀 칸 안의 자리 (0 = 하얀 칸 왼쪽, 1 = 오른쪽). 칸 밖에서 썬 칼질은 그 자리로 치지 않는다.
## 요리 단계의 횟수 = 칼질 수. 다 썰면(두껍게 썰어 재료가 먼저 모자라도) 남은 끝 조각까지 조각 더미로 옮기고 완성. (빠르기는 쓰지 않는다)

const READY_FORMAT: String = "0 / %d"
const HIT_FORMAT: String = "탁! %d / %d"
const EMPTY_TEXT: String = "재료 위에서 썰어요"
const DONE_TEXT: String = "손질 끝!"

@export var chops_needed: int = 8
## 칼 길이(픽셀)와, 다 내려갔을 때 칼 위쪽 끝의 높이 (도마 기준 y). 칼날 끝이 재료 아래까지 닿게 둔다.
@export var knife_length: float = 180.0
@export var knife_low_top: float = 160.0
## 칼이 들렸을 때 올라가 있는 높이(픽셀). 들린 칼날 끝이 재료 위에 있도록 넉넉하게.
@export var knife_raise: float = 180.0
## 마우스를 누른 채 이만큼(픽셀) 아래로 끌면 칼이 끝까지 내려가 썰린다
@export var stroke_distance: float = 110.0
## 칼이 이만큼(0~1)보다 덜 내려가 있으면 들린 것으로 보고 옆으로 옮기거나 다음 칼질을 할 수 있다.
## 누른 채 위아래로 톱질하듯 썰 때 끝까지 올리지 않아도 되게 너그럽게 둔다.
@export var knife_rearm_depth: float = 0.25
## 손을 뗐을 때 칼이 다시 들리는 빠르기 (1초에 들리는 정도, 1 = 끝까지)
@export var knife_lift_speed: float = 6.0
## 게임패드·방향키로 칼을 옮기는 빠르기(초당 픽셀)와, 아래로 당겼을 때 칼이 내려가는 빠르기 (1초에 내려가는 정도)
@export var pad_knife_speed: float = 420.0
@export var pad_cut_speed: float = 5.0
## 스틱을 이만큼 아래로 당겨야 썰기 시작한다, 이보다 덜 당기면 칼이 들린다 (0~1)
@export var pad_cut_deadzone: float = 0.4
## 썰 자리(하얀 칸)의 넓이(픽셀). 넓을수록 비법 자리·부탁 자리를 맞추기 쉽다.
@export var target_width: float = 50.0
## 칼이 하얀 칸 위에 있을 때 하얀 칸 진하기 (평소 진하기는 씬의 TargetZone 색)
@export var target_hover_alpha: float = 0.8
## 이보다 얇게는 썰리지 않는다(픽셀). 남은 재료 끝에서도 이만큼은 떨어져야 썰린다.
@export var min_piece_width: float = 8.0
## 남은 재료가 고른 두께의 이 배수보다 적으면 남은 것을 끝 조각으로 치고 끝낸다 (두껍게 썰어 재료가 모자랄 때)
@export var last_piece_ratio: float = 1.5
## 썰 때마다 도마가 살짝 커졌다 돌아오는 정도와 시간(초)
@export var bounce_scale: float = 1.03
@export var bounce_duration: float = 0.08
## 재료가 없는 곳에서 칼이 도마에 닿았을 때 칼이 흔들리는 각도(라디안)와 시간(초). 빗나감으로 세지 않는다.
@export var empty_wobble_angle: float = 0.08
@export var empty_wobble_duration: float = 0.15
## 잘린 조각이 조각 더미로 날아가는 시간(초)과 기울어지는 각도(라디안)
@export var slice_fly_duration: float = 0.25
@export var slice_fly_tilt: float = 0.35
## 조각 더미에 쌓이는 조각 높이(픽셀). 폭은 실제로 썬 두께.
@export var slice_size: Vector2 = Vector2(24, 120)
## 그림이 아직 없는 재료와 조각에 쓰는 임시 색
@export var ingredient_color: Color = Color(0.85, 0.55, 0.3)

## 이번 단계의 칼질 수와 재료 색 (요리 단계에서 정한 값, 없으면 위의 기본값)
var _chops_needed: int = 0
## 이번에 쓰는 하얀 칸 넓이 (넓은 도마가 있으면 넓어진다)
var _target_width: float = 50.0
var _ingredient_color: Color
var _chop_count: int = 0
var _ingredient_left: float = 0.0
var _ingredient_full_width: float = 0.0
## 고른 두께 한 조각의 폭 (칼질 수 + 끝 조각 하나로 나눈 폭)
var _even_width: float = 0.0
## 칼 중심의 x 위치(도마 기준)와 내려간 정도 (0 = 들림, 1 = 도마까지)
var _knife_x: float = 0.0
var _knife_depth: float = 0.0
## 이번 칼질에서 이미 썰었는지. 칼이 다시 들려야(knife_rearm_depth 이하) 다음 칼질을 할 수 있다.
var _has_cut_this_stroke: bool = false
## 마우스를 누르고 있는지, 칼질을 시작한 마우스 높이 (미니게임 기준 y. 썰 때 도마가 커져도 흔들리지 않게)
var _is_mouse_down: bool = false
var _stroke_anchor_y: float = 0.0
var _target_center: float = 0.0
var _target_base_alpha: float = 0.45

@onready var _board: Control = %Board
@onready var _ingredient: ColorRect = %Ingredient
@onready var _target_zone: ColorRect = %TargetZone
@onready var _knife: ColorRect = %Knife
@onready var _slices: HFlowContainer = %Slices


func _ready() -> void:
	super()
	_ingredient_left = _ingredient.position.x
	_ingredient_full_width = _ingredient.size.x
	_target_base_alpha = _target_zone.color.a
	_knife.size.y = knife_length
	_knife.pivot_offset = Vector2(_knife.size.x / 2.0, 0.0)


func _get_minigame_type() -> Recipe.MinigameType:
	return Recipe.MinigameType.CHOP


func _uses_perfect_stamp() -> bool:
	return false


func _on_start(recipe: Recipe) -> void:
	_chops_needed = _step_count(chops_needed)
	_target_width = target_width * _window_scale
	_ingredient_color = _step_color(ingredient_color)
	_even_width = _ingredient_full_width / (_chops_needed + 1)
	_chop_count = 0
	for slice: Node in _slices.get_children():
		slice.queue_free()
	_ingredient.color = _ingredient_color
	_ingredient.size.x = _ingredient_full_width
	_knife_x = _ingredient_left + _ingredient_full_width + _even_width
	_knife_depth = 0.0
	_has_cut_this_stroke = false
	_is_mouse_down = false
	_knife.rotation = 0.0
	_update_target()
	_update_knife()
	_target_zone.show()
	_clear_zones(_target_zone)
	_title_label.text = _step_title(Recipe.MinigameType.CHOP, _default_subject(recipe))
	_progress_label.text = READY_FORMAT % _chops_needed


func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing:
		return
	var pad_x: float = Input.get_axis(&"ui_left", &"ui_right")
	var pad_down: float = Input.get_action_strength(&"ui_down")
	if not _is_mouse_down:
		if pad_down >= pad_cut_deadzone:
			_set_depth(_knife_depth + pad_cut_speed * delta)
		else:
			_set_depth(_knife_depth - knife_lift_speed * delta)
		if _is_knife_raised() and pad_x != 0.0:
			_move_knife_to(_knife_x + pad_x * pad_knife_speed * delta)
	_update_knife()


## 마우스와 방향(키·스틱)을 직접 다룬다. 누르기(스페이스·Ⓐ)는 쓰지 않고, 포커스가 다른 버튼으로 새지 않게 먹는다.
func _gui_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_is_mouse_down = event.pressed
		if event.pressed:
			_stroke_anchor_y = event.position.y
			if _is_knife_raised():
				_move_knife_to(_board_point(event.position).x)
		return
	if event is InputEventMouseMotion:
		accept_event()
		if _is_mouse_down:
			# 위로 올라간 만큼 기준 높이도 따라 올려서, 다시 아래로 끌면 바로 칼이 내려가게 한다.
			_stroke_anchor_y = minf(_stroke_anchor_y, event.position.y)
			_set_depth((event.position.y - _stroke_anchor_y) / stroke_distance)
		if _is_knife_raised():
			_move_knife_to(_board_point(event.position).x)
		return
	for action: StringName in [&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"ui_accept"]:
		if event.is_action(action):
			accept_event()
			return


## 하얀 칸 안에 비법 자리나 부탁 자리를 그린다. 하얀 칸이 옮겨 가면 함께 옮겨 간다.
func _show_zone(start: float, end: float, color: Color, zone_name: String) -> void:
	_make_zone(_target_zone, Rect2(start * _target_width, 0.0, (end - start) * _target_width, _target_zone.size.y),
			color, zone_name)


## 미니게임 좌표를 도마 좌표로 바꾼다 (썰 때 도마가 살짝 커지는 것도 함께 계산된다).
func _board_point(at: Vector2) -> Vector2:
	return _board.get_global_transform().affine_inverse() * (get_global_transform() * at)


## 칼은 재료 처음 길이에서 조금 오른쪽(빈 도마)까지 움직인다.
func _move_knife_to(x: float) -> void:
	_knife_x = clampf(x, _ingredient_left, _ingredient_left + _ingredient_full_width + _even_width)


## 칼 깊이를 바꾼다. 끝까지 내려가면 썰고, 다시 들리면 다음 칼질을 할 수 있다.
func _set_depth(depth: float) -> void:
	_knife_depth = clampf(depth, 0.0, 1.0)
	if _knife_depth >= 1.0 and not _has_cut_this_stroke:
		_has_cut_this_stroke = true
		_cut()
	elif _is_knife_raised():
		_has_cut_this_stroke = false


## 칼이 들려 있는지. 들려 있을 때만 옆으로 옮긴다 (내려가는 중에는 곧게 썬다).
func _is_knife_raised() -> bool:
	return _knife_depth <= knife_rearm_depth


func _ingredient_right() -> float:
	return _ingredient_left + _ingredient.size.x


func _cut() -> void:
	if _chop_count >= _chops_needed:
		return
	var right: float = _ingredient_right()
	if _knife_x <= _ingredient_left + min_piece_width or _knife_x >= right - min_piece_width:
		_tap_empty_board()
		return
	# 하얀 칸 왼쪽 끝 = 0, 오른쪽 끝 = 1
	var window_left: float = _target_center - _target_width / 2.0
	var is_in_window: bool = _knife_x >= window_left and _knife_x <= window_left + _target_width
	_register_hit((_knife_x - window_left) / _target_width, is_in_window)
	_chop_count += 1
	_ingredient.size.x = _knife_x - _ingredient_left
	_fly_slice(_knife_x, right - _knife_x)
	_bounce_board()
	_progress_label.text = HIT_FORMAT % [_chop_count, _chops_needed]
	# 두껍게 썰어서 남은 재료가 한 조각 반도 안 되면, 남은 것을 끝 조각으로 치고 끝낸다.
	if _chop_count >= _chops_needed or _ingredient.size.x < _even_width * last_piece_ratio:
		_finish()
	else:
		_update_target()


## 재료가 없는 곳(또는 너무 얇은 곳)에 칼이 닿았다. 칼이 살짝 흔들릴 뿐 빗나감으로 세지 않는다.
func _tap_empty_board() -> void:
	_progress_label.text = EMPTY_TEXT
	_knife.rotation = empty_wobble_angle
	var tween: Tween = create_tween()
	tween.tween_property(_knife, "rotation", 0.0, empty_wobble_duration)


## 다 썰었다. 남은 끝 조각도 조각 더미로 옮기고 완성한다.
func _finish() -> void:
	_is_mouse_down = false
	_target_zone.hide()
	if _ingredient.size.x > 0.0:
		_fly_slice(_ingredient_left, _ingredient.size.x)
		_ingredient.size.x = 0.0
	_complete(DONE_TEXT)


## 잘린 조각(from_x 부터 width 폭)이 도마 위에서 조각 더미로 날아간다. 더미의 조각은 날아간 조각이 닿으면 보인다.
func _fly_slice(from_x: float, width: float) -> void:
	var piece_width: float = maxf(width, min_piece_width)
	var slice: ColorRect = ColorRect.new()
	slice.color = _ingredient_color
	slice.custom_minimum_size = Vector2(piece_width, slice_size.y)
	slice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slice.modulate.a = 0.0
	_slices.add_child(slice)
	var flying: ColorRect = ColorRect.new()
	flying.color = _ingredient_color
	flying.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying.position = Vector2(from_x, _ingredient.position.y)
	flying.size = Vector2(piece_width, _ingredient.size.y)
	flying.pivot_offset = flying.size / 2.0
	_board.add_child(flying)
	# 더미 안 자리는 다음 프레임에 정해진다.
	await get_tree().process_frame
	if not is_instance_valid(slice) or not is_instance_valid(flying):
		return
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(flying, "position", _slices.position + slice.position, slice_fly_duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flying, "size", slice.size, slice_fly_duration)
	# 날아가며 살짝 기울었다가 더미에 닿을 때 다시 바로 선다.
	tween.tween_property(flying, "rotation", slice_fly_tilt, slice_fly_duration / 2.0)
	tween.tween_property(flying, "rotation", 0.0, slice_fly_duration / 2.0).set_delay(slice_fly_duration / 2.0)
	tween.chain().tween_callback(func() -> void:
		slice.modulate.a = 1.0
		flying.queue_free())


## 썰 자리(하얀 칸)는 남은 재료 오른쪽 끝에서 고른 두께 한 조각만큼 안쪽에 둔다.
func _update_target() -> void:
	_target_center = _ingredient_right() - _even_width
	_target_zone.position.x = _target_center - _target_width / 2.0
	_target_zone.size.x = _target_width


func _update_knife() -> void:
	_knife.position = Vector2(_knife_x - _knife.size.x / 2.0, knife_low_top - knife_raise * (1.0 - _knife_depth))
	var is_over_target: bool = absf(_knife_x - _target_center) <= _target_width / 2.0
	_target_zone.color.a = target_hover_alpha if is_over_target else _target_base_alpha


func _bounce_board() -> void:
	_board.scale = Vector2.ONE * bounce_scale
	var tween: Tween = create_tween()
	tween.tween_property(_board, "scale", Vector2.ONE, bounce_duration)
