class_name MinceMinigame
extends Minigame
## 다지기 미니게임 (탁탁 쪼개기). 큰 식칼의 칼날 끝이 커서를 따라 도마 위를 다닌다.
## 클릭(Ⓐ·스페이스)하면 칼이 탁 내려가고, 칼날에 닿은 조각만 둘로 쪼개져 그 근처에 흩어진다.
## 조각마다 쪼개진 횟수(잘기)가 있고, 요리 단계의 횟수만큼 쪼개진 조각은 더 쪼개지지 않는다. 모든 조각이 그만큼 잘게 되면 완성.
## 아직 덜 잘린 조각은 조금 진하게 보여서 어디를 다질지 알 수 있다. 빗나감·실패는 없다 (완벽 도장도 없다).
## 게임패드·방향키: 스틱으로 칼을 옮기고 Ⓐ(스페이스)로 다진다. 넓은 도마(조리도구)가 있으면 칼날이 닿는 폭이 넓어진다.

const STAGE_FORMAT: String = "곱게 다지는 중 %d / %d"
const READY_TEXT: String = "큰 조각을 찾아 탁탁 다져요"
const HIT_TEXT: String = "탁!"
const DONE_TEXT: String = "곱게 다졌어요!"

## 조각이 잘게 되기까지 쪼개지는 횟수 (요리 단계의 횟수가 없을 때)
@export var stages_needed: int = 4
## 처음 재료 조각 수와 크기(픽셀). 쪼개질 때마다 넓이가 반이 된다.
@export var start_piece_count: int = 2
@export var start_piece_size: Vector2 = Vector2(150, 110)
## 재료 조각이 놓이는 구역(도마 기준)
@export var pile_rect: Rect2 = Rect2(140, 110, 620, 260)
## 칼날이 닿는 구역: 칼날 끝(커서 자리)을 가운데로 한 폭과 높이(픽셀)
@export var blade_reach: Vector2 = Vector2(140, 80)
## 쪼개진 두 조각이 원래 자리에서 흩어지는 거리 (조각 크기에 대한 비율)
@export var split_scatter: float = 0.6
## 그림이 없는 재료의 임시 색과, 덜 잘린 조각이 진해지는 정도 (가장 큰 조각 기준, 0~1)
@export var ingredient_color: Color = Color(0.93, 0.55, 0.25)
@export var coarse_darken: float = 0.3
## 칼이 내려찍는 깊이(픽셀)와 내려갔다 올라오는 시간(초). 그동안은 다음 칼질을 받지 않는다.
@export var knife_drop: float = 30.0
@export var knife_drop_duration: float = 0.12
## 게임패드·방향키로 칼을 옮기는 빠르기(초당 픽셀)
@export var pad_knife_speed: float = 500.0
## 쪼개질 때 조각이 살짝 커졌다 돌아오는 정도와 시간(초)
@export var split_pop_scale: float = 1.15
@export var split_pop_duration: float = 0.1

## 이번 단계의 쪼개는 횟수와 재료 색
var _stages_needed: int = 0
var _ingredient_color: Color
## 도마 위 조각들과 조각마다 쪼개진 횟수
var _pieces: Array[ColorRect] = []
var _levels: Array[int] = []
## 지금까지 쪼갠 수와 다 쪼개려면 필요한 수 (진행 막대)
var _splits_done: int = 0
var _splits_needed: int = 0
## 칼날 끝 자리 (도마 기준)
var _blade_point: Vector2
## 칼이 내려갔다 올라오기까지 남은 시간(초)
var _drop_time_left: float = 0.0
## 이번에 쓰는 칼날 닿는 구역 크기 (넓은 도마가 있으면 넓어진다)
var _blade_reach: Vector2

@onready var _board: Control = %Board
@onready var _pile: Control = %Pile
@onready var _knife: Control = %Knife
@onready var _rate_bar: Control = %RateBar
@onready var _rate_label: Label = $RateLabel
@onready var _fine_bar: Control = %FineBar
@onready var _fine_fill: Control = %FineFill
@onready var _side_label: Label = %SideLabel


func _ready() -> void:
	super()
	# 빠르기 막대는 쓰지 않는다 (예전 박자 다지기의 것)
	_rate_bar.hide()
	_rate_label.hide()


func _get_minigame_type() -> Recipe.MinigameType:
	return Recipe.MinigameType.MINCE


func _uses_perfect_stamp() -> bool:
	return false


func _on_start(recipe: Recipe) -> void:
	_stages_needed = _step_count(stages_needed)
	_ingredient_color = _step_color(ingredient_color)
	_blade_reach = blade_reach * Vector2(_window_scale, 1.0)
	_splits_done = 0
	_splits_needed = start_piece_count * (int(pow(2.0, _stages_needed)) - 1)
	_drop_time_left = 0.0
	for piece: Node in _pile.get_children():
		piece.queue_free()
	_pieces.clear()
	_levels.clear()
	for i: int in start_piece_count:
		# 큰 조각은 도마 가운데에 나란히 놓는다
		var center: Vector2 = pile_rect.get_center() + Vector2((i - (start_piece_count - 1) / 2.0) * start_piece_size.x * 1.2, 0.0)
		_add_piece(center, start_piece_size, 0)
	_blade_point = pile_rect.get_center() + Vector2(0.0, pile_rect.size.y / 2.0 + 40.0)
	_title_label.text = _step_title(Recipe.MinigameType.MINCE, _default_subject(recipe))
	_progress_label.text = READY_TEXT
	_update_view()


func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing:
		return
	_drop_time_left = maxf(_drop_time_left - delta, 0.0)
	var pad: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if pad != Vector2.ZERO:
		_move_knife_to(_blade_point + pad * pad_knife_speed * delta)
	_update_knife()


## 마우스는 칼을 옮기고, 클릭·Ⓐ(스페이스)는 다진다. 방향은 포커스가 다른 버튼으로 새지 않게 먹는다.
func _gui_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if event is InputEventMouseMotion:
		accept_event()
		_move_knife_to(_board_point(event.position))
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_move_knife_to(_board_point(event.position))
		if event.pressed:
			_chop()
		return
	if event.is_action_pressed(&"ui_accept"):
		accept_event()
		_chop()
		return
	for action: StringName in [&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"ui_accept"]:
		if event.is_action(action):
			accept_event()
			return


## 미니게임 좌표를 도마 좌표로 바꾼다.
func _board_point(at: Vector2) -> Vector2:
	return _board.get_global_transform().affine_inverse() * (get_global_transform() * at)


## 칼날 끝을 도마 안의 at 으로 옮긴다.
func _move_knife_to(at: Vector2) -> void:
	_blade_point = at.clamp(Vector2.ZERO, _board.size)
	_update_knife()


## 칼을 탁 내린다. 칼날에 닿은, 아직 덜 잘린 조각을 모두 둘로 쪼갠다.
func _chop() -> void:
	if _drop_time_left > 0.0:
		return
	_drop_time_left = knife_drop_duration
	var reach: Rect2 = Rect2(_blade_point - _blade_reach / 2.0, _blade_reach)
	var targets: Array[int] = []
	for i: int in _pieces.size():
		if _levels[i] < _stages_needed and reach.intersects(Rect2(_pieces[i].position, _pieces[i].size)):
			targets.append(i)
	if targets.is_empty():
		# 빈 도마나 다 잘린 조각만 쳤다. 탁 소리만 난다.
		_play_hit_sound()
		return
	# 다지기에는 비법 자리가 없다. 맞힌 수만 센다.
	_register_hit(0.5, false)
	# 뒤에서부터 쪼개야 앞 번호가 흔들리지 않는다.
	targets.reverse()
	for i: int in targets:
		_split(i)
	_progress_label.text = HIT_TEXT
	_update_view()
	if _splits_done >= _splits_needed:
		_complete(DONE_TEXT)


## index 조각을 넓이가 반인 두 조각으로 쪼개 원래 자리 근처에 흩는다.
func _split(index: int) -> void:
	var piece: ColorRect = _pieces[index]
	var center: Vector2 = piece.position + piece.size / 2.0
	var new_size: Vector2 = piece.size / sqrt(2.0)
	var level: int = _levels[index] + 1
	piece.queue_free()
	_pieces.remove_at(index)
	_levels.remove_at(index)
	var direction: Vector2 = Vector2.from_angle(randf() * TAU)
	for side: float in [-1.0, 1.0]:
		var offset: Vector2 = direction * side * new_size.length() * split_scatter / 2.0
		var added: ColorRect = _add_piece(center + offset, new_size, level)
		added.scale = Vector2.ONE * split_pop_scale
		var tween: Tween = create_tween()
		tween.tween_property(added, "scale", Vector2.ONE, split_pop_duration)
	_splits_done += 1


## center 를 가운데로 size 크기 조각을 놓는다 (조각 구역 안에서).
func _add_piece(center: Vector2, size: Vector2, level: int) -> ColorRect:
	var piece: ColorRect = ColorRect.new()
	piece.size = size
	piece.pivot_offset = size / 2.0
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece.position = (center - size / 2.0).clamp(pile_rect.position, pile_rect.end - size)
	piece.rotation = randf_range(-0.3, 0.3)
	# 덜 잘린 조각일수록 진하게
	var coarseness: float = 1.0 - float(level) / _stages_needed
	piece.color = _ingredient_color.darkened(coarse_darken * coarseness)
	_pile.add_child(piece)
	_pieces.append(piece)
	_levels.append(level)
	return piece


func _update_view() -> void:
	_fine_fill.size.x = float(_splits_done) / maxi(_splits_needed, 1) * _fine_bar.size.x
	var lowest: int = _stages_needed
	for level: int in _levels:
		lowest = mini(lowest, level)
	_side_label.text = STAGE_FORMAT % [lowest, _stages_needed]


## 칼날 아래쪽 가운데가 칼날 끝 자리에 오게 놓는다. 다지는 중에는 살짝 내려갔다 올라온다.
func _update_knife() -> void:
	var drop: float = 0.0
	if _drop_time_left > 0.0:
		drop = knife_drop * sin(PI * (1.0 - _drop_time_left / knife_drop_duration))
	_knife.position = _blade_point - Vector2(_knife.size.x / 2.0, _knife.size.y - drop)
