class_name SimmerMinigame
extends Minigame
## 조리기 미니게임 (빙글빙글 젓기). 국자가 커서를 따라 냄비 안을 다닌다.
## 누르지 않고 냄비 안에서 커서를 빙글빙글 돌리면 국자가 저어 준다 (어느 쪽으로 돌려도 된다). 게임패드는 스틱을 돌린다.
## 저을수록 국물이 조금씩 졸아들고 재료에 윤기가 돌며, 재료가 국자를 따라 함께 돈다.
## turns_per_stir 바퀴마다 "휘~" 한 번. 요리 단계의 횟수만큼 저으면 완성. 빗나감·실패는 없다 (완벽 도장도 없다).
## 냄비 옆 "젓는 빠르기" 막대: 0 = 느긋하게, 1 = 빠르게. 한 번 저을 때마다 그때 빠르기로 할머니 비법 자리·부탁 자리를 본다.
## 조림장(Coating)은 레시피의 Simmer Sauce 칸에서 정하고, 졸이는 재료는 요리 단계의 재료(없으면 첫 번째 재료)를 쓴다.

const COUNT_FORMAT: String = "저어 주기 %d / %d"
const SAUCE_FORMAT: String = "%s 졸이는 중"
const READY_TEXT: String = "냄비 안에서 빙글빙글 저어 주세요"
const HIT_FORMAT: String = "휘~ %d / %d"
const DONE_TEXT: String = "윤기 나게 졸였어요!"
const METER_TITLE: String = "젓는 빠르기"
const METER_SLOW_TEXT: String = "느긋하게"
const METER_FAST_TEXT: String = "빠르게"

## 저어야 하는 횟수
@export var stirs_needed: int = 8
## 한 번 저은 것으로 치는 바퀴 수 (0.5 = 반 바퀴마다 한 번)
@export var turns_per_stir: float = 0.5
## 냄비 가운데에서 이만큼(픽셀) 떨어져 돌려야 돈 것으로 센다. 한 번에 이보다 크게 돈 각도(라디안)는 튄 값이라 세지 않는다.
@export var stir_min_distance: float = 40.0
@export var stir_max_step: float = 1.2
## 국자 그릇이 다닐 수 있는 냄비 가운데에서의 거리(픽셀)
@export var ladle_max_radius: float = 200.0
## 게임패드: 스틱을 이만큼 기울여야 돌린 것으로 센다 (0~1), 국자가 도는 원의 반지름(픽셀)
@export var pad_deadzone: float = 0.5
@export var pad_stir_radius: float = 150.0
## 국자 그릇 가운데가 국자 노드(Spoon)의 자리에서 손잡이 반대쪽으로 떨어진 거리(픽셀). 씬의 Bowl 가운데.
@export var ladle_bowl_offset: float = 58.0
## 빠르기 막대 양 끝이 가리키는 빠르기 (1초에 도는 바퀴 수)
@export var meter_slow_turns: float = 0.3
@export var meter_fast_turns: float = 1.8
## 빠르기 바늘이 따라 움직이는 부드러움 (클수록 빨리 따라온다)
@export var meter_smoothing: float = 6.0
## 빠르기 막대 자리와 크기, 색
@export var meter_rect: Rect2 = Rect2(240, 470, 400, 28)
@export var meter_color: Color = Color(0.25, 0.18, 0.12, 0.85)
@export var meter_needle_color: Color = Color(1, 1, 1)
@export var meter_font_size: int = 24
## 재료가 국자를 따라 도는 정도 (국자가 돈 각도에 곱한다)
@export var piece_swirl: float = 0.35
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

## 이번 단계의 젓는 수 (요리 단계에서 정한 값, 없으면 위의 기본값. 무쇠솥이 있으면 줄어든다)
var _stirs_needed: int = 0
var _stirs_done: int = 0
## 저은 각도 합(라디안, 방향 상관없이)과 방향을 살린 합 (재료가 따라 도는 데 쓴다)
var _angle_total: float = 0.0
var _angle_signed: float = 0.0
## 이번 프레임에 저은 각도 (빠르기를 재는 데 쓴다)
var _angle_this_frame: float = 0.0
## 지금 젓는 빠르기 (1초에 도는 바퀴 수, 부드럽게 따라간다)
var _turn_speed: float = 0.0
## 마지막으로 국자가 있던 각도 (NAN = 아직 없음)와 국자가 가리키는 바깥 방향
var _last_angle: float = NAN
var _ladle_dir: Vector2 = Vector2.RIGHT
var _pieces: Array[Control] = []
var _sauce_color: Color
var _meter: ColorRect
var _meter_needle: ColorRect

@onready var _sauce: Control = %Sauce
@onready var _piece_layer: Control = %PieceLayer
@onready var _piece_template: Control = %PieceTemplate
@onready var _spoon: Control = %Spoon
@onready var _sauce_bar: Control = %SauceBar
@onready var _sauce_fill: ColorRect = %SauceFill
@onready var _sauce_label: Label = %SauceLabel
@onready var _side_label: Label = %SideLabel


func _ready() -> void:
	super()
	_piece_template.hide()
	_sauce.pivot_offset = _sauce.size / 2.0
	_build_meter()


func _get_minigame_type() -> Recipe.MinigameType:
	return Recipe.MinigameType.SIMMER


func _uses_perfect_stamp() -> bool:
	return false


## 냄비 옆의 "젓는 빠르기" 막대와 바늘, 글을 만든다.
func _build_meter() -> void:
	_meter = ColorRect.new()
	_meter.color = meter_color
	_meter.position = meter_rect.position
	_meter.size = meter_rect.size
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_meter)
	_meter_needle = ColorRect.new()
	_meter_needle.color = meter_needle_color
	_meter_needle.size = Vector2(6.0, meter_rect.size.y + 16.0)
	_meter_needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meter.add_child(_meter_needle)
	for text_align: Array in [[METER_TITLE, HORIZONTAL_ALIGNMENT_CENTER, -1.0],
			[METER_SLOW_TEXT, HORIZONTAL_ALIGNMENT_LEFT, 1.0], [METER_FAST_TEXT, HORIZONTAL_ALIGNMENT_RIGHT, 1.0]]:
		var label: Label = Label.new()
		label.text = text_align[0]
		label.horizontal_alignment = text_align[1]
		label.add_theme_font_size_override("font_size", meter_font_size)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.size = Vector2(meter_rect.size.x, meter_font_size * 1.6)
		# 제목은 막대 위, 양 끝 글은 막대 아래
		var below: bool = text_align[2] > 0.0
		label.position = Vector2(0.0, meter_rect.size.y + 12.0 if below else -label.size.y - 6.0)
		_meter.add_child(label)


func _on_start(recipe: Recipe) -> void:
	_stirs_needed = maxi(roundi(_step_count(stirs_needed) * _duration_scale), 1)
	_stirs_done = 0
	_angle_total = 0.0
	_angle_signed = 0.0
	_angle_this_frame = 0.0
	_turn_speed = 0.0
	_last_angle = NAN
	_ladle_dir = Vector2.RIGHT
	_piece_layer.rotation = 0.0
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
	_clear_zones(_meter)
	_place_ladle(_pot_center() + Vector2.RIGHT * pad_stir_radius)
	_update_simmer()
	_update_meter()


## 재료 조각을 냄비 가운데를 둘러싸게 놓는다.
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
			(piece.get_node("Icon") as TextureRect).texture = ingredient.get_piece_texture()
		piece.get_node("Gloss").self_modulate = Color(_sauce_color, 0.0)
		piece.show()
		_piece_layer.add_child(piece)
		_pieces.append(piece)


func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing:
		return
	_stir_with_pad()
	var instant: float = _angle_this_frame / TAU / delta if delta > 0.0 else 0.0
	_angle_this_frame = 0.0
	_turn_speed = lerpf(_turn_speed, instant, clampf(meter_smoothing * delta, 0.0, 1.0))
	_update_meter()


## 마우스는 움직임만 쓴다 (누르지 않아도 저어진다). 누르기와 방향은 포커스가 다른 버튼으로 새지 않게 먹는다.
func _gui_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if event is InputEventMouseMotion:
		accept_event()
		_stir_toward(event.position)
		return
	if event is InputEventMouseButton:
		accept_event()
		return
	for action: StringName in [&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"ui_accept"]:
		if event.is_action(action):
			accept_event()
			return


## 빠르기 막대 안에 비법 자리나 부탁 자리를 그린다.
func _show_zone(start: float, end: float, color: Color, zone_name: String) -> void:
	_make_zone(_meter, Rect2(start * meter_rect.size.x, 0.0, (end - start) * meter_rect.size.x, meter_rect.size.y),
			color, zone_name)
	# 바늘이 자리 표시에 가려지지 않게 맨 위로
	_meter.move_child(_meter_needle, -1)


func _pot_center() -> Vector2:
	return _piece_layer.position


## 스틱을 기울인 방향의 원 위 한 점으로 국자를 옮겨 젓는다. 스틱을 놓으면 다음에 처음부터 잰다.
func _stir_with_pad() -> void:
	var dir: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if dir.length() < pad_deadzone:
		return
	_stir_toward(_pot_center() + dir.normalized() * pad_stir_radius)


## 국자를 at 으로 옮기고, 냄비 가운데를 중심으로 돈 각도만큼 젓는다.
func _stir_toward(at: Vector2) -> void:
	var offset: Vector2 = at - _pot_center()
	_place_ladle(at)
	if offset.length() < stir_min_distance:
		_last_angle = NAN
		return
	var angle: float = offset.angle()
	if not is_nan(_last_angle):
		var step: float = angle_difference(_last_angle, angle)
		if absf(step) <= stir_max_step:
			_angle_total += absf(step)
			_angle_signed += step
			_angle_this_frame += absf(step)
			_on_stirred()
	_last_angle = angle


## 국자 그릇이 at 에 오게 놓는다 (냄비 밖으로는 나가지 않는다). 손잡이는 냄비 바깥쪽을 향한다.
func _place_ladle(at: Vector2) -> void:
	var offset: Vector2 = (at - _pot_center()).limit_length(ladle_max_radius)
	if offset.length() > 1.0:
		_ladle_dir = offset.normalized()
	var bowl: Vector2 = _pot_center() + offset
	_spoon.position = bowl - _ladle_dir * ladle_bowl_offset
	_spoon.rotation = _ladle_dir.angle()


## 저은 만큼 국물을 졸이고, 반 바퀴(turns_per_stir)를 넘길 때마다 한 번 저은 것으로 센다.
## 큰 국자(조리도구)가 있으면 한 바퀴에 더 많이 저어진다.
func _on_stirred() -> void:
	_piece_layer.rotation = _angle_signed * piece_swirl
	var stirs_now: int = floori(_turns_done() / turns_per_stir)
	while _stirs_done < mini(stirs_now, _stirs_needed):
		_stirs_done += 1
		# 빠르기 막대 왼쪽 끝 = 0, 오른쪽 끝 = 1. 막대보다 느리거나 빠르면 끝자리로 친다.
		_register_hit(inverse_lerp(meter_slow_turns, meter_fast_turns, _turn_speed))
		_progress_label.text = HIT_FORMAT % [_stirs_done, _stirs_needed]
	_update_simmer()
	if _stirs_done >= _stirs_needed:
		_complete(DONE_TEXT)


func _turns_done() -> float:
	return _angle_total / TAU * _window_scale


## 저은 만큼 국물이 졸아들어 작아지고 진해지며, 재료에 윤기(조림장 색)가 돈다.
func _update_simmer() -> void:
	var progress: float = clampf(_turns_done() / (_stirs_needed * turns_per_stir), 0.0, 1.0)
	_sauce.scale = Vector2.ONE * lerpf(sauce_start_scale, sauce_end_scale, progress)
	_sauce.self_modulate = _sauce_color.lerp(Color.WHITE, thin_sauce_whiten * (1.0 - progress))
	_sauce_fill.size.x = (1.0 - progress) * _sauce_bar.size.x
	for piece: Control in _pieces:
		piece.get_node("Gloss").self_modulate = Color(_sauce_color, gloss_max_alpha * progress)
	_side_label.text = COUNT_FORMAT % [_stirs_done, _stirs_needed]


func _update_meter() -> void:
	var t: float = clampf(inverse_lerp(meter_slow_turns, meter_fast_turns, _turn_speed), 0.0, 1.0)
	_meter_needle.position = Vector2(t * meter_rect.size.x - _meter_needle.size.x / 2.0, -8.0)
