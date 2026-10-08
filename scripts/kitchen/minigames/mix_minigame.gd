class_name MixMinigame
extends Minigame
## 버무리기 미니게임 (쓱쓱 문지르기). 넓은 그릇에 재료 조각이 흩어져 있고, 주걱이 커서를 따라다닌다.
## 누르지 않고 주걱으로 조각 위를 쓱쓱 지나가면 지나간 만큼 양념이 조금씩 묻고 (조각 색이 진해진다), 다 묻으면 톡 반짝인다.
## 주걱 밑의 덜 묻은 조각은 빛난다. 모든 조각에 다 묻히면 완성. 빗나감·실패는 없다 (완벽 도장도 없다).
## 할머니 비법 자리·부탁 자리: 조각을 문지르는 동안 주걱이 조각 가운데에서 좌우로 평균 얼마나 치우쳐 지나갔는지.
## 0.5 = 한가운데, 0 / 1 = 왼쪽 / 오른쪽 가장자리. 위아래로 문지르는 것은 치우침으로 치지 않는다.
## 게임패드·방향키: 스틱으로 주걱을 옮기며 문지른다.
## 무엇을 묻힐지(Coating)와 어떤 재료에 묻힐지는 레시피 데이터에서 정한다. 새 양념은 data/coatings/ 에 추가한다.

const COUNT_FORMAT: String = "%s 묻힌 조각 %d / %d"
const READY_TEXT: String = "주걱으로 조각을 쓱쓱 문질러요"
const HIT_FORMAT: String = "쓱싹! %d / %d"
const DONE_TEXT: String = "골고루 버무렸어요!"

## 그릇에 놓이는 조각 수
@export var piece_count: int = 7
## 주걱 머리 가운데와 조각 가운데가 이 거리(픽셀) 안이면 문지르는 중이다. 클수록 쉽다.
@export var rub_reach: float = 50.0
## 조각 하나에 양념이 다 묻으려면 그 위에서 주걱이 움직여야 하는 거리(픽셀)
@export var rub_distance_needed: float = 180.0
## 게임패드·방향키로 주걱을 옮기는 빠르기(초당 픽셀)
@export var pad_spatula_speed: float = 600.0
## 조각이 자기 칸 가운데에서 좌우로 벗어나는 정도 (칸 폭에 대한 비율). 조각끼리 겹치지 않게 0.3 이하로.
@export var slot_jitter: float = 0.25
## 레시피에 양념이 정해져 있지 않을 때 쓰는 이름과 색
@export var fallback_coating_name: String = "양념"
@export var fallback_coating_color: Color = Color(0.85, 0.35, 0.2)
## 양념이 다 묻은 조각에 덮이는 색의 진하기 (0 ~ 1). 묻는 동안 0 에서 여기까지 진해진다.
@export var coat_alpha: float = 0.85
## 양념이 다 묻을 때 조각이 살짝 커졌다 돌아오는 정도와 시간(초)
@export var coat_pop_scale: float = 1.25
@export var coat_pop_duration: float = 0.12

## 이번 단계의 조각 수 (요리 단계에서 정한 값, 없으면 위의 기본값)
var _piece_count: int = 0
var _pieces: Array[Control] = []
var _is_coated: Array[bool] = []
## 조각마다 문지른 거리와, 문지르는 동안 주걱이 조각 가운데에서 좌우로 떨어진 거리(크기, 부호 있는 값)의 합 (평균을 내는 데 쓴다)
var _rubbed: Array[float] = []
var _offset_sum: Array[float] = []
var _side_sum: Array[float] = []
var _coated_count: int = 0
var _coating_name: String = ""
var _coat_color: Color
## 주걱 머리 가운데 자리 (조각 영역 기준). NAN 이면 아직 커서가 들어오지 않았다.
var _spatula_point: Vector2 = Vector2(NAN, NAN)
## 이번에 쓰는 문지르는 거리 (조리도구가 있으면 넓어진다)
var _rub_reach: float = 50.0

@onready var _piece_area: Control = %PieceArea
@onready var _piece_template: Control = %PieceTemplate
@onready var _spatula: Control = %Spatula
@onready var _spatula_head: Control = get_node("%Spatula/Head")
@onready var _side_label: Label = %SideLabel


func _ready() -> void:
	super()
	_piece_template.hide()


func _get_minigame_type() -> Recipe.MinigameType:
	return Recipe.MinigameType.MIX


func _on_start(recipe: Recipe) -> void:
	_piece_count = _step_count(piece_count)
	_rub_reach = rub_reach * _window_scale
	_coated_count = 0
	var coating_color: Color = fallback_coating_color
	_coating_name = fallback_coating_name
	if recipe.mix_coating != null:
		coating_color = recipe.mix_coating.color
		_coating_name = recipe.mix_coating.display_name
	_coat_color = Color(coating_color, coat_alpha)
	var piece_ingredient: Ingredient = _step.ingredient if _step != null and _step.ingredient != null \
			else recipe.get_mix_piece_ingredient()
	_place_pieces(piece_ingredient)
	var ingredient_name: String = piece_ingredient.display_name if piece_ingredient != null else FALLBACK_SUBJECT
	_title_label.text = _step_title(Recipe.MinigameType.MIX, ingredient_name)
	_progress_label.text = READY_TEXT
	_update_count()
	_place_spatula(Vector2(_piece_area.size.x / 2.0, _piece_area.size.y + _rub_reach))
	_spatula_point = Vector2(NAN, NAN)


## 그릇 폭을 piece_count 칸으로 나눠 칸마다 조각 하나를 놓는다. 칸 안에서 위치는 조금씩 흩뜨린다.
func _place_pieces(ingredient: Ingredient) -> void:
	for piece: Node in _piece_area.get_children():
		if piece != _spatula:
			piece.queue_free()
	_pieces.clear()
	_is_coated.clear()
	_rubbed.clear()
	_offset_sum.clear()
	_side_sum.clear()
	var slot_width: float = _piece_area.size.x / _piece_count
	for i: int in _piece_count:
		var piece: Control = _piece_template.duplicate()
		var center_x: float = slot_width * (i + 0.5 + randf_range(-slot_jitter, slot_jitter))
		var top: float = randf_range(0.0, _piece_area.size.y - piece.size.y)
		piece.position = Vector2(center_x - piece.size.x / 2.0, top)
		piece.pivot_offset = piece.size / 2.0
		if ingredient != null:
			(piece.get_node("Icon") as TextureRect).texture = ingredient.get_piece_texture()
		piece.get_node("Coat").self_modulate = Color(_coat_color, 0.0)
		piece.get_node("Coat").show()
		piece.get_node("Glow").hide()
		piece.show()
		_piece_area.add_child(piece)
		_pieces.append(piece)
		_is_coated.append(false)
		_rubbed.append(0.0)
		_offset_sum.append(0.0)
		_side_sum.append(0.0)
	# 주걱이 조각들 위에 그려지도록 맨 뒤로 보낸다.
	_piece_area.move_child(_spatula, -1)


func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing:
		return
	var pad: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if pad != Vector2.ZERO:
		var from: Vector2 = _spatula.position + _head_center() if is_nan(_spatula_point.x) else _spatula_point
		_rub_to(from + pad * pad_spatula_speed * delta)


## 마우스는 움직임만 쓴다 (누르지 않아도 문질러진다). 누르기와 방향은 포커스가 다른 버튼으로 새지 않게 먹는다.
func _gui_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if event is InputEventMouseMotion:
		accept_event()
		_rub_to(event.position - _piece_area.position)
		return
	if event is InputEventMouseButton:
		accept_event()
		return
	for action: StringName in [&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"ui_accept"]:
		if event.is_action(action):
			accept_event()
			return


## 주걱을 at(조각 영역 기준)으로 옮기며, 움직인 거리만큼 주걱 밑의 덜 묻은 조각에 양념을 묻힌다.
func _rub_to(at: Vector2) -> void:
	var margin: Vector2 = Vector2.ONE * _rub_reach
	var target: Vector2 = at.clamp(-margin, _piece_area.size + margin)
	var moved: float = 0.0 if is_nan(_spatula_point.x) else target.distance_to(_spatula_point)
	_spatula_point = target
	_place_spatula(target)
	for i: int in _pieces.size():
		var offset: Vector2 = target - _piece_center(i)
		var is_under: bool = not _is_coated[i] and offset.length() <= _rub_reach
		_pieces[i].get_node("Glow").visible = is_under
		if not is_under or moved <= 0.0:
			continue
		_rubbed[i] += moved
		_offset_sum[i] += absf(offset.x) * moved
		_side_sum[i] += offset.x * moved
		var amount: float = minf(_rubbed[i] / rub_distance_needed, 1.0)
		_pieces[i].get_node("Coat").self_modulate = Color(_coat_color, coat_alpha * amount)
		if amount >= 1.0:
			_coat(i)


func _piece_center(index: int) -> Vector2:
	return _pieces[index].position + _pieces[index].size / 2.0


func _head_center() -> Vector2:
	return _spatula_head.position + _spatula_head.size / 2.0


## 주걱 머리 가운데가 at 에 오게 놓는다.
func _place_spatula(at: Vector2) -> void:
	_spatula.position = at - _head_center()


## index 조각에 양념이 다 묻었다. 문지르는 동안 주걱이 지나간 자리로 비법·부탁 자리를 본다.
func _coat(index: int) -> void:
	# 평균으로 가운데에서 좌우로 떨어진 거리 (0 = 한가운데, 1 = 문지를 수 있는 끝), 어느 쪽으로 치우쳤는지
	var average_distance: float = clampf(_offset_sum[index] / _rubbed[index] / _rub_reach, 0.0, 1.0)
	var side: float = -1.0 if _side_sum[index] < 0.0 else 1.0
	# 한가운데 = 0.5, 왼쪽 끝 = 0, 오른쪽 끝 = 1
	_register_hit(0.5 + 0.5 * average_distance * side)
	_is_coated[index] = true
	_coated_count += 1
	var piece: Control = _pieces[index]
	piece.get_node("Glow").hide()
	var tween: Tween = create_tween()
	tween.tween_property(piece, "scale", Vector2.ONE * coat_pop_scale, coat_pop_duration)
	tween.tween_property(piece, "scale", Vector2.ONE, coat_pop_duration)
	_update_count()
	_progress_label.text = HIT_FORMAT % [_coated_count, _piece_count]
	if _coated_count >= _piece_count:
		_complete(DONE_TEXT)


func _update_count() -> void:
	_side_label.text = COUNT_FORMAT % [_coating_name, _coated_count, _piece_count]
