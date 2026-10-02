class_name SimmerMinigame
extends Minigame
## 조리기 미니게임 (보글보글 박자 젓기). 냄비 가운데 금색 원이 있고, 하얀 원이 일정한 박자로 줄어든다.
## 하얀 원이 금색 원에 딱 겹칠 때 누르면 숟가락으로 휘~ 젓는다. 저을 때마다 국물이 졸아들고 재료에 윤기가 돈다.
## stirs_needed 번 저으면 완성. 너무 빨리 누르거나 박자를 놓치면 빗나감이지만, 다음 박자가 바로 온다.
## 조림장(Coating)은 레시피의 Simmer Sauce 칸에서 정하고, 졸이는 재료는 요리 단계의 재료(없으면 첫 번째 재료)를 쓴다.
## 누르기 입력, 연타 방지, 완벽 표시는 공통 틀(Minigame)이 맡는다.

const COUNT_FORMAT: String = "저어 주기 %d / %d"
const SAUCE_FORMAT: String = "%s 졸이는 중"
const READY_TEXT: String = "하얀 원이 금색 원에 겹칠 때 눌러요"
const HIT_FORMAT: String = "휘~ %d / %d"
const EARLY_TEXT: String = "조금 빨라요. 박자에 맞춰요"
const MISSED_TEXT: String = "박자를 놓쳤어요. 다음 박자에!"
const DONE_TEXT: String = "윤기 나게 졸였어요!"

## 저어야 하는 횟수
@export var stirs_needed: int = 8
## 박자 사이 시간(초). 하얀 원이 바깥에서 금색 원까지 줄어드는 시간이기도 하다.
@export var beat_interval: float = 0.9
## 시작하고 첫 원이 나오기까지 쉬는 시간(초)
@export var lead_in: float = 0.6
## 박자 앞뒤로 이 시간(초) 안에 누르면 맞은 것. 클수록 쉽다.
@export var hit_window: float = 0.12
## 판정을 후하게 해 주는 여유(초). 화면에는 안 보인다.
@export var judge_margin: float = 0.03
## 하얀 원이 처음 나올 때 크기 (금색 원의 몇 배)
@export var ring_start_scale: float = 3.0
## 박자가 지난 뒤 하얀 원이 더 작아지며 사라지는 정도
@export var ring_after_scale: float = 0.6
## 국물: 처음과 다 졸였을 때의 크기 (냄비 안쪽에 대한 비율)
@export var sauce_start_scale: float = 1.0
@export var sauce_end_scale: float = 0.78
## 재료 조각 수와 냄비 가운데에서 떨어진 거리(픽셀)
@export var piece_count: int = 6
@export var piece_orbit_radius: float = 165.0
## 조각마다 제자리에서 조금씩 벗어나는 각도(라디안)
@export var piece_angle_jitter: float = 0.2
## 다 졸였을 때 재료에 덮이는 조림장 색의 진하기 (0 ~ 1)
@export var gloss_max_alpha: float = 0.75
## 레시피에 조림장이 정해져 있지 않을 때 쓰는 이름과 색
@export var fallback_sauce_name: String = "조림장"
@export var fallback_sauce_color: Color = Color(0.6, 0.35, 0.15)
## 국물이 처음에 얼마나 묽은지 (조림장 색에 흰색을 섞는 비율)
@export var thin_sauce_whiten: float = 0.45
## 저을 때 숟가락이 도는 각도(라디안)와 시간(초)
@export var spoon_turn: float = 0.9
@export var spoon_turn_duration: float = 0.2
## 박자마다 국물이 보글 하고 커지는 정도와 시간(초)
@export var bubble_pulse_scale: float = 1.04
@export var bubble_pulse_duration: float = 0.1

## 미니게임을 시작한 뒤 흐른 시간과, 지금 하얀 원이 금색 원에 닿는 시각
## 이번 단계의 젓는 수와 박자 사이 시간 (요리 단계에서 정한 값, 없으면 위의 기본값)
var _stirs_needed: int = 0
var _beat_interval: float = 0.9
var _time: float = 0.0
var _beat_time: float = 0.0
var _stirs_done: int = 0
var _pieces: Array[Control] = []
var _sauce_color: Color

@onready var _sauce: Control = %Sauce
@onready var _piece_layer: Control = %PieceLayer
@onready var _piece_template: Control = %PieceTemplate
@onready var _spoon: Control = %Spoon
@onready var _beat_ring: Control = %BeatRing
@onready var _sauce_bar: Control = %SauceBar
@onready var _sauce_fill: ColorRect = %SauceFill
@onready var _sauce_label: Label = %SauceLabel
@onready var _side_label: Label = %SideLabel


func _ready() -> void:
	super()
	_piece_template.hide()
	_sauce.pivot_offset = _sauce.size / 2.0
	_beat_ring.pivot_offset = _beat_ring.size / 2.0


func _on_start(recipe: Recipe) -> void:
	_stirs_needed = _step_count(stirs_needed)
	_beat_interval = beat_interval / _speed
	_time = 0.0
	_beat_time = lead_in + _beat_interval
	_stirs_done = 0
	_spoon.rotation = 0.0
	_sauce_color = fallback_sauce_color
	var sauce_name: String = fallback_sauce_name
	if recipe.simmer_sauce != null:
		_sauce_color = recipe.simmer_sauce.color
		sauce_name = recipe.simmer_sauce.display_name
	var ingredient: Ingredient = recipe.ingredients[0] if not recipe.ingredients.is_empty() else null
	if _step != null and _step.ingredient != null:
		ingredient = _step.ingredient
	_place_pieces(ingredient)
	var ingredient_name: String = ingredient.display_name if ingredient != null else FALLBACK_SUBJECT
	_title_label.text = _step_title(Recipe.MinigameType.SIMMER, ingredient_name)
	_sauce_label.text = SAUCE_FORMAT % sauce_name
	_sauce_fill.color = _sauce_color
	_progress_label.text = READY_TEXT
	_update_simmer()
	_update_ring()


## 재료 조각을 냄비 가운데를 둘러싸게 놓는다 (가운데는 박자 원 자리).
func _place_pieces(ingredient: Ingredient) -> void:
	for piece: Node in _piece_layer.get_children():
		piece.queue_free()
	_pieces.clear()
	for i: int in piece_count:
		var piece: Control = _piece_template.duplicate()
		var angle: float = TAU * i / piece_count + randf_range(-piece_angle_jitter, piece_angle_jitter)
		piece.position = Vector2.from_angle(angle) * piece_orbit_radius - piece.size / 2.0
		piece.pivot_offset = piece.size / 2.0
		piece.rotation = randf() * TAU
		if ingredient != null:
			(piece.get_node("Icon") as TextureRect).texture = ingredient.get_icon_texture()
		piece.get_node("Gloss").self_modulate = Color(_sauce_color, 0.0)
		piece.show()
		_piece_layer.add_child(piece)
		_pieces.append(piece)


func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing:
		return
	_time += delta
	if _time > _beat_time + hit_window + judge_margin:
		_register_miss()
		_progress_label.text = MISSED_TEXT
		_next_beat()
	_update_ring()


func _on_press() -> void:
	if absf(_time - _beat_time) <= hit_window + judge_margin:
		# 박자보다 hit_window 만큼 이르게 = 0, 딱 박자 = 0.5, hit_window 만큼 늦게 = 1
		_register_hit((_time - (_beat_time - hit_window)) / (2.0 * hit_window))
		_stir()
	else:
		_register_miss()
		_progress_label.text = EARLY_TEXT


func _stir() -> void:
	_stirs_done += 1
	_side_label.text = COUNT_FORMAT % [_stirs_done, _stirs_needed]
	_progress_label.text = HIT_FORMAT % [_stirs_done, _stirs_needed]
	var tween: Tween = create_tween()
	tween.tween_property(_spoon, "rotation", _spoon.rotation + spoon_turn, spoon_turn_duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_update_simmer()
	if _stirs_done >= _stirs_needed:
		_beat_ring.hide()
		_complete(DONE_TEXT)
		return
	_next_beat()


## 다음 박자로 넘어간다. 국물이 보글 하고 한 번 커졌다 돌아온다.
func _next_beat() -> void:
	_beat_time += _beat_interval
	var base: Vector2 = _sauce.scale
	var tween: Tween = create_tween()
	tween.tween_property(_sauce, "scale", base * bubble_pulse_scale, bubble_pulse_duration)
	tween.tween_property(_sauce, "scale", base, bubble_pulse_duration)


## 저은 만큼 국물이 졸아들어 작아지고 진해지며, 재료에 윤기(조림장 색)가 돈다.
func _update_simmer() -> void:
	var progress: float = float(_stirs_done) / _stirs_needed
	_sauce.scale = Vector2.ONE * lerpf(sauce_start_scale, sauce_end_scale, progress)
	_sauce.self_modulate = _sauce_color.lerp(Color.WHITE, thin_sauce_whiten * (1.0 - progress))
	_sauce_fill.size.x = (1.0 - progress) * _sauce_bar.size.x
	for piece: Control in _pieces:
		piece.get_node("Gloss").self_modulate = Color(_sauce_color, gloss_max_alpha * progress)
	_side_label.text = COUNT_FORMAT % [_stirs_done, _stirs_needed]


## 하얀 원: 박자 한 칸 전에 바깥에서 나타나 박자 때 금색 원 크기가 되고, 지나면 더 작아지며 사라진다.
func _update_ring() -> void:
	var p: float = 1.0 - (_beat_time - _time) / _beat_interval
	if p < 0.0 or not _is_playing:
		_beat_ring.hide()
		return
	_beat_ring.show()
	if p <= 1.0:
		_beat_ring.scale = Vector2.ONE * lerpf(ring_start_scale, 1.0, p)
		_beat_ring.modulate.a = 1.0
	else:
		var after: float = (p - 1.0) * _beat_interval / (hit_window + judge_margin)
		_beat_ring.scale = Vector2.ONE * lerpf(1.0, ring_after_scale, after)
		_beat_ring.modulate.a = 1.0 - after
