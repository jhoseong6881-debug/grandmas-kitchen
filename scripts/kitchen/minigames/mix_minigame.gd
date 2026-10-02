class_name MixMinigame
extends Minigame
## 버무리기 미니게임 (골고루 묻히기). 넓은 그릇에 재료 조각이 흩어져 있고, 주걱이 좌우로 오간다.
## 주걱이 아직 양념이 안 묻은 조각 위를 지날 때(조각이 금색으로 빛날 때) 누르면 그 조각에 양념이 묻는다.
## 모든 조각에 묻히면 완성. 아무 조각도 없는 곳에서 누르면 빗나감이지만 벌칙은 없다.
## 무엇을 묻힐지(Coating)와 어떤 재료에 묻힐지는 레시피 데이터에서 정한다. 새 양념은 data/coatings/ 에 추가한다.
## 누르기 입력, 연타 방지, 완벽 표시는 공통 틀(Minigame)이 맡는다.

## 재료 이름 + 동작 이름 (예: "도토리 버무리기")
const TITLE_FORMAT: String = "%s %s"
const COUNT_FORMAT: String = "%s 묻힌 조각 %d / %d"
const READY_TEXT: String = "주걱이 안 묻은 조각 위를 지날 때 눌러요"
const HIT_FORMAT: String = "쓱싹! %d / %d"
const MISS_TEXT: String = "빈 곳을 저었어요. 빛나는 조각을 노려요"
const DONE_TEXT: String = "골고루 버무렸어요!"
const FALLBACK_INGREDIENT_NAME: String = "재료"

## 그릇에 놓이는 조각 수
@export var piece_count: int = 7
## 주걱이 그릇 한쪽 끝에서 다른 쪽 끝까지 가는 시간(초)
@export var sweep_duration: float = 2.0
## 주걱 가운데와 조각 가운데가 이 거리(픽셀) 안이면 맞은 것. 클수록 쉽다.
@export var catch_half_width: float = 34.0
## 판정을 후하게 해 주는 여유(픽셀). 화면에는 안 보인다.
@export var judge_margin: float = 8.0
## 조각이 자기 칸 가운데에서 좌우로 벗어나는 정도 (칸 폭에 대한 비율). 조각끼리 겹치지 않게 0.3 이하로.
@export var slot_jitter: float = 0.25
## 레시피에 양념이 정해져 있지 않을 때 쓰는 이름과 색
@export var fallback_coating_name: String = "양념"
@export var fallback_coating_color: Color = Color(0.85, 0.35, 0.2)
## 양념이 묻은 조각에 덮이는 색의 진하기 (0 ~ 1)
@export var coat_alpha: float = 0.85
## 양념이 묻을 때 조각이 살짝 커졌다 돌아오는 정도와 시간(초)
@export var coat_pop_scale: float = 1.25
@export var coat_pop_duration: float = 0.12

## 지금 주걱이 오간 정도. 0~1 은 왼쪽→오른쪽, 1~2 는 오른쪽→왼쪽.
var _sweep_t: float = 0.0
var _pieces: Array[Control] = []
var _is_coated: Array[bool] = []
var _coated_count: int = 0
var _coating_name: String = ""

@onready var _piece_area: Control = %PieceArea
@onready var _piece_template: Control = %PieceTemplate
@onready var _spatula: Control = %Spatula
@onready var _side_label: Label = %SideLabel


func _ready() -> void:
	super()
	_piece_template.hide()


func _on_start(recipe: Recipe) -> void:
	_sweep_t = 0.0
	_coated_count = 0
	var coating_color: Color = fallback_coating_color
	_coating_name = fallback_coating_name
	if recipe.mix_coating != null:
		coating_color = recipe.mix_coating.color
		_coating_name = recipe.mix_coating.display_name
	var piece_ingredient: Ingredient = recipe.get_mix_piece_ingredient()
	_place_pieces(piece_ingredient, Color(coating_color, coat_alpha))
	var ingredient_name: String = piece_ingredient.display_name if piece_ingredient != null else FALLBACK_INGREDIENT_NAME
	_title_label.text = TITLE_FORMAT % [ingredient_name, recipe.get_action_name(Recipe.MinigameType.MIX)]
	_progress_label.text = READY_TEXT
	_update_count()
	_update_spatula()


## 그릇 폭을 piece_count 칸으로 나눠 칸마다 조각 하나를 놓는다. 칸 안에서 위치는 조금씩 흩뜨린다.
func _place_pieces(ingredient: Ingredient, coat_color: Color) -> void:
	for piece: Node in _piece_area.get_children():
		if piece != _spatula:
			piece.queue_free()
	_pieces.clear()
	_is_coated.clear()
	var slot_width: float = _piece_area.size.x / piece_count
	for i: int in piece_count:
		var piece: Control = _piece_template.duplicate()
		var center_x: float = slot_width * (i + 0.5 + randf_range(-slot_jitter, slot_jitter))
		var top: float = randf_range(0.0, _piece_area.size.y - piece.size.y)
		piece.position = Vector2(center_x - piece.size.x / 2.0, top)
		piece.pivot_offset = piece.size / 2.0
		if ingredient != null:
			(piece.get_node("Icon") as TextureRect).texture = ingredient.get_icon_texture()
		piece.get_node("Coat").self_modulate = coat_color
		piece.get_node("Coat").hide()
		piece.get_node("Glow").hide()
		piece.show()
		_piece_area.add_child(piece)
		_pieces.append(piece)
		_is_coated.append(false)
	# 주걱이 조각들 위에 그려지도록 맨 뒤로 보낸다.
	_piece_area.move_child(_spatula, -1)


func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing:
		return
	_sweep_t = fmod(_sweep_t + delta / sweep_duration, 2.0)
	_update_spatula()


func _on_press() -> void:
	var index: int = _bare_piece_under_spatula()
	if index < 0:
		_register_miss()
		_progress_label.text = MISS_TEXT
		return
	_coat(index)


## 주걱 아래에 있는, 아직 안 묻은 조각 중 가장 가까운 것의 번호. 없으면 -1.
func _bare_piece_under_spatula() -> int:
	var spatula_x: float = _spatula_x()
	var best: int = -1
	var best_distance: float = catch_half_width + judge_margin
	for i: int in _pieces.size():
		if _is_coated[i]:
			continue
		var distance: float = absf(_pieces[i].position.x + _pieces[i].size.x / 2.0 - spatula_x)
		if distance <= best_distance:
			best = i
			best_distance = distance
	return best


func _coat(index: int) -> void:
	_is_coated[index] = true
	_coated_count += 1
	var piece: Control = _pieces[index]
	piece.get_node("Glow").hide()
	piece.get_node("Coat").show()
	var tween: Tween = create_tween()
	tween.tween_property(piece, "scale", Vector2.ONE * coat_pop_scale, coat_pop_duration)
	tween.tween_property(piece, "scale", Vector2.ONE, coat_pop_duration)
	_update_count()
	_progress_label.text = HIT_FORMAT % [_coated_count, piece_count]
	if _coated_count >= piece_count:
		_complete(DONE_TEXT)


## 주걱 가운데의 x (조각 영역 기준). 왼쪽 끝 0 ~ 오른쪽 끝 영역 폭을 오간다.
func _spatula_x() -> float:
	return pingpong(_sweep_t, 1.0) * _piece_area.size.x


## 주걱을 옮기고, 주걱 아래에 있는 안 묻은 조각만 금색으로 빛나게 한다.
func _update_spatula() -> void:
	var spatula_x: float = _spatula_x()
	_spatula.position.x = spatula_x - _spatula.size.x / 2.0
	for i: int in _pieces.size():
		var center_x: float = _pieces[i].position.x + _pieces[i].size.x / 2.0
		_pieces[i].get_node("Glow").visible = not _is_coated[i] \
				and absf(center_x - spatula_x) <= catch_half_width


func _update_count() -> void:
	_side_label.text = COUNT_FORMAT % [_coating_name, _coated_count, piece_count]
