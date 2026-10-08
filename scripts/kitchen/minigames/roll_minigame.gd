class_name RollMinigame
extends Minigame
## 말기 미니게임 (붓고 → 밀어서 돌돌 말기). 계란말이를 한 겹씩 쌓는다. 한 겹은 두 동작이다.
##   1. 붓기: 국자가 커서를 따라다니고, 팬 위에서는 "여기까지 퍼져요"가 흐린 계란물로 미리 보인다.
##      클릭(Ⓐ·스페이스)하면 말린 계란 옆에서 그 자리까지 계란물이 주르륵 퍼진다.
##   2. 말기: 국자가 뒤집개로 바뀐다. 누르지 않고 커서를 오른쪽으로 움직인 만큼 말린 계란이 계란물 위를 굴러가며
##      지나간 계란물을 말아 들인다 (굴러가는 빠르기에는 한도가 있다). 계란물 끝까지 가면 '착' 한 겹.
## layers_needed 겹을 다 말면 완성. 겹이 쌓일수록 말린 계란이 두툼해진다. 빗나감·실패는 없다 (완벽 도장도 없다).
## 게임패드·방향키: 스틱으로 국자·뒤집개를 옮기고 Ⓐ(스페이스)로 붓는다.
## 할머니 비법 자리·부탁 자리 = 붓는 자리: 0 = 말린 계란 바로 옆, 1 = 팬 끝. 팬 위쪽 띠에 그린다.

enum Phase { POURING, ROLLING, MOVING }

const LAYER_FORMAT: String = "%d / %d겹 · %s"
const POUR_STEP_TEXT: String = "붓기"
const ROLL_STEP_TEXT: String = "말기"
const POUR_READY_TEXT: String = "팬을 클릭해서 그 자리까지 계란물을 부어요"
const ROLL_READY_TEXT: String = "뒤집개로 오른쪽으로 밀어 돌돌 말아요"
const ROLL_GOOD_TEXT: String = "착! 한 겹 말았어요"
const DONE_TEXT: String = "돌돌 예쁘게 말았어요!"

## 말아야 하는 겹 수
@export var layers_needed: int = 3
## 아무리 가까이 클릭해도 이만큼은 붓는다 (팬 빈자리에 대한 비율)
@export_range(0.0, 1.0) var min_pour: float = 0.15
## 계란물이 클릭한 자리까지 퍼지는 시간(초)
@export var pour_spread_duration: float = 0.35
## 붓기 전 미리 보이는 계란물의 진하기 (0 ~ 1)
@export var preview_alpha: float = 0.35
## 말린 계란이 굴러가는 가장 빠른 빠르기(초당 픽셀). 커서가 앞서가도 이보다 빨리 구르지 않는다.
@export var roll_max_speed: float = 900.0
## 게임패드·방향키로 국자·뒤집개를 옮기는 빠르기(초당 픽셀)
@export var pad_tool_speed: float = 600.0
## 말린 계란의 처음 두께와 한 겹마다 두꺼워지는 정도(픽셀)
@export var roll_start_width: float = 36.0
@export var roll_growth: float = 36.0
## 다 만 계란이 처음 자리로 밀려 돌아가는 시간(초)
@export var push_back_duration: float = 0.35
## 한 겹 말았을 때 계란이 살짝 커졌다 돌아오는 정도와 시간(초)
@export var bounce_scale: float = 1.08
@export var bounce_duration: float = 0.1
## 붓는 자리 띠의 높이(픽셀)와 진하기
@export var pour_band_height: float = 18.0
@export var pour_band_alpha: float = 0.35
## 국자(그림이 없을 때 동그라미)의 지름과 색, 뒤집개(막대)의 폭과 색
@export var ladle_size: float = 64.0
@export var ladle_color: Color = Color(0.7, 0.72, 0.76)
@export var spatula_width: float = 14.0
@export var spatula_color: Color = Color(0.45, 0.3, 0.18)

## 이번 단계의 겹 수 (요리 단계에서 정한 값, 없으면 위의 기본값)
var _layers_needed: int = 0
var _phase: Phase = Phase.POURING
var _layers_done: int = 0
## 지금 겹에서 부은 양 (0 = 없음, 1 = 팬 빈자리 끝까지). 붓기 전에는 미리 보기 양.
var _pour_level: float = 0.0
## 계란물이 퍼지는 중인지
var _is_spreading: bool = false
## 말린 계란 오른쪽 끝이 가려는 자리와 지금 자리 (팬 안쪽 기준 x). 가려는 자리는 커서·스틱을 오른쪽으로 민 만큼 늘어난다.
var _roll_target_x: float = 0.0
var _roll_right: float = 0.0
var _roll_width: float = 36.0
## 국자·뒤집개 자리 (팬 안쪽 기준)
var _tool_point: Vector2
var _ladle: Panel
var _spatula_bar: ColorRect

@onready var _pan_inner: Control = %PanInner
@onready var _sheet: ColorRect = %Sheet
@onready var _roll: Control = %Roll
@onready var _pour_zone: ColorRect = %PourZone
@onready var _roll_zone: ColorRect = %RollZone
@onready var _side_label: Label = %SideLabel


func _ready() -> void:
	super()
	# 금색 칸 대신: 붓는 자리 띠(PourZone)는 팬 위쪽에 얇게, 말기 금색 칸(RollZone)은 쓰지 않는다.
	_roll_zone.hide()
	_pour_zone.color.a = pour_band_alpha
	_ladle = Panel.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = ladle_color
	style.set_corner_radius_all(int(ladle_size / 2.0))
	_ladle.add_theme_stylebox_override("panel", style)
	_ladle.size = Vector2.ONE * ladle_size
	_ladle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pan_inner.add_child(_ladle)
	_spatula_bar = ColorRect.new()
	_spatula_bar.color = spatula_color
	_spatula_bar.size = Vector2(spatula_width, _pan_inner.size.y)
	_spatula_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pan_inner.add_child(_spatula_bar)


func _get_minigame_type() -> Recipe.MinigameType:
	return Recipe.MinigameType.ROLL


func _uses_perfect_stamp() -> bool:
	return false


func _on_start(recipe: Recipe) -> void:
	_layers_needed = _step_count(layers_needed)
	_layers_done = 0
	_roll_width = roll_start_width
	_title_label.text = _step_title(Recipe.MinigameType.ROLL, _default_subject(recipe))
	_roll.position.x = 0.0
	_roll.scale = Vector2.ONE
	_tool_point = Vector2(_pan_inner.size.x * 0.75, _pan_inner.size.y / 2.0)
	_clear_zones(_pour_zone)
	_start_pour()


func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing:
		return
	var pad: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if pad != Vector2.ZERO:
		_move_tool_to(_tool_point + pad * pad_tool_speed * delta)
		_push(pad.x * pad_tool_speed * delta)
	if _phase == Phase.ROLLING:
		_roll_right = move_toward(_roll_right, _roll_target_x, roll_max_speed * delta)
		_update_roll()
		if _roll_right >= _sheet_end() - 0.5:
			_finish_layer()


## 마우스는 국자·뒤집개를 옮기고, 클릭·Ⓐ(스페이스)는 붓는다. 방향은 포커스가 다른 버튼으로 새지 않게 먹는다.
func _gui_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if event is InputEventMouseMotion:
		accept_event()
		_move_tool_to(event.position - _pan_inner.position)
		_push(event.relative.x)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_move_tool_to(event.position - _pan_inner.position)
		if event.pressed:
			_pour()
		return
	if event.is_action_pressed(&"ui_accept"):
		accept_event()
		_pour()
		return
	for action: StringName in [&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"ui_accept"]:
		if event.is_action(action):
			accept_event()
			return


## 붓는 자리 띠 안에 비법 자리나 부탁 자리를 그린다. 띠는 겹마다 폭이 바뀌어서 비율로 붙여 둔다.
func _show_zone(start: float, end: float, color: Color, zone_name: String) -> void:
	var zone: ColorRect = _make_zone(_pour_zone, Rect2(), color, zone_name)
	zone.anchor_left = start
	zone.anchor_right = end
	zone.anchor_bottom = 1.0
	zone.offset_left = 0.0
	zone.offset_right = 0.0
	zone.offset_top = 0.0
	zone.offset_bottom = 0.0


## 국자·뒤집개를 팬 안의 at 으로 옮긴다. 붓기 전에는 미리 보기 계란물을, 말기 중에는 굴러갈 자리를 바꾼다.
func _move_tool_to(at: Vector2) -> void:
	_tool_point = at.clamp(Vector2.ZERO, _pan_inner.size)
	if _phase == Phase.POURING and not _is_spreading:
		_pour_level = _pour_level_at(_tool_point.x)
		_update_sheet()
	_update_tools()


## 말기 중에 오른쪽으로 움직인 만큼(dx) 말린 계란을 민다. 왼쪽으로 움직이면 그대로 둔다 (커서가 팬 끝에 붙어 있어도 밀 수 있다).
func _push(dx: float) -> void:
	if _phase == Phase.ROLLING and dx > 0.0:
		_roll_target_x += dx


# --- 붓기 ---

## 새 겹을 붓기 시작한다. 말린 계란은 팬 왼쪽 끝에 있다.
func _start_pour() -> void:
	_phase = Phase.POURING
	_is_spreading = false
	_roll.size.x = _roll_width
	_roll.pivot_offset = _roll.size / 2.0
	_pour_level = _pour_level_at(_tool_point.x)
	_sheet.modulate.a = preview_alpha
	_sheet.show()
	_update_sheet()
	_pour_zone.position = Vector2(_roll_width, 0.0)
	_pour_zone.size = Vector2(_pour_free_width(), pour_band_height)
	_pour_zone.show()
	_progress_label.text = POUR_READY_TEXT
	_update_side_label(POUR_STEP_TEXT)
	_update_tools()


## x 자리까지 부으면 되는 양 (팬 빈자리에 대한 비율)
func _pour_level_at(x: float) -> float:
	return clampf((x - _roll_width) / _pour_free_width(), min_pour, 1.0)


## 미리 보이던 자리까지 계란물을 붓는다. 다 퍼지면 말기로 넘어간다.
func _pour() -> void:
	if _phase != Phase.POURING or _is_spreading:
		return
	_is_spreading = true
	# 말린 계란 바로 옆 = 0, 팬 끝 = 1
	_register_hit(_pour_level)
	_sheet.modulate.a = 1.0
	var target: float = _pour_level
	var tween: Tween = create_tween()
	tween.tween_method(func(level: float) -> void:
		_pour_level = level
		_update_sheet(), 0.0, target, pour_spread_duration)
	tween.tween_callback(_start_roll)


# --- 말기 ---

func _start_roll() -> void:
	_phase = Phase.ROLLING
	_is_spreading = false
	_pour_zone.hide()
	_roll_right = _roll_width
	_roll_target_x = _roll_right
	_progress_label.text = ROLL_READY_TEXT
	_update_side_label(ROLL_STEP_TEXT)
	_update_tools()


## 한 겹을 다 말았다. 계란이 두꺼워지고, 처음 자리로 밀려 돌아간다. 다 말았으면 완성.
func _finish_layer() -> void:
	_phase = Phase.MOVING
	_progress_label.text = ROLL_GOOD_TEXT
	_layers_done += 1
	_sheet.hide()
	# 두꺼워진 계란의 오른쪽 끝이 계란물이 있던 끝에 오게 한다.
	var end_x: float = _sheet_end()
	_roll_width += roll_growth
	_roll.size.x = _roll_width
	_roll.position.x = end_x - _roll_width
	_roll.pivot_offset = _roll.size / 2.0
	_update_tools()
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


func _update_sheet() -> void:
	_sheet.position.x = _roll_width
	_sheet.size.x = _sheet_end() - _roll_width


## 말린 계란이 굴러간 만큼 오른쪽으로 가고, 지나간 자리의 계란물은 말려 들어가 사라진다.
func _update_roll() -> void:
	_roll.position.x = _roll_right - _roll_width
	_sheet.position.x = _roll_right
	_sheet.size.x = maxf(_sheet_end() - _roll_right, 0.0)
	_update_tools()


## 붓기 중에는 국자(커서 자리), 말기 중에는 말린 계란 바로 왼쪽의 뒤집개를 보여 준다.
func _update_tools() -> void:
	_ladle.visible = _phase == Phase.POURING and not _is_spreading
	_ladle.position = _tool_point - _ladle.size / 2.0
	_spatula_bar.visible = _phase == Phase.ROLLING
	_spatula_bar.position = Vector2(_roll.position.x - _spatula_bar.size.x, 0.0)


func _update_side_label(step_text: String) -> void:
	_side_label.text = LAYER_FORMAT % [mini(_layers_done + 1, _layers_needed), _layers_needed, step_text]
