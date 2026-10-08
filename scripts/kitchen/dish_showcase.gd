class_name DishShowcase
extends Control
## 요리 완성 장면. 요리 미니게임이 다 끝나면 접시에 담긴 완성 요리가 가운데 톡 튀어나오며 "완성~!".
## 할머니 비법대로 했으면 "♥ 할머니 손맛" 한 줄이 붙는다.
## 오른쪽에 고명 병(GarnishShaker)이 세로로 놓이고, 하나를 골라 요리에 뿌리면 닫힌다. show_dish 를 await 하면 고른 고명이 돌아온다.
##   마우스: 병에 올리면 들리고, 누르면 집어서 마우스를 따라온다. 요리 위에서 누르거나 끌어다 놓으면 뿌린다.
##           요리 밖을 누르거나 오른쪽 클릭·Esc 면 제자리로 돌려놓는다.
##   게임패드·키보드: 십자키로 병을 고르고 Ⓐ 를 누르면 병이 요리 위로 날아가 뿌린다.
## 고명 없이 내는 선택지(Garnish.serve_as_is)는 병 대신 "그대로 내기" 버튼이다.
## 재료가 모자란 고명 병은 회색 톤이고 집을 수 없다 (마우스를 올리거나 누르면 "꿀이 모자라요!").

signal closed
signal _garnish_done(garnish: Garnish)

const DONE_SOUND: StringName = &"done"
const PICK_SOUND: StringName = &"click"
const SPRINKLE_SOUND: StringName = &"rustle"
const SHORT_FORMAT: String = "%s%s 모자라요!"

@export var done_text: String = "완성~!"
@export var grandma_text: String = "♥ 할머니 손맛"
## 완성 요리 그림을 키우는 배수 (원본 64×64)
@export var dish_scale: int = 4
## 튀어나오는 크기 변화와 시간(초)
@export var pop_start_scale: float = 0.4
@export var pop_overshoot_scale: float = 1.12
@export var pop_duration: float = 0.22
@export var settle_duration: float = 0.12
## 접시가 위아래로 살짝 둥실거리는 높이(픽셀)와 한 번 오르내리는 시간(초)
@export var bob_height: float = 8.0
@export var bob_duration: float = 1.2
## 고명 병을 세우는 자리: 왼쪽 위 x, 첫 병 y, 병 사이 간격(픽셀)
@export var shaker_column_x: float = 1500.0
@export var shaker_top: float = 200.0
@export var shaker_step: float = 195.0
## 뿌릴 때: 병 바닥이 갈 자리(요리 가운데에서), 기울기(라디안), 날아가는 시간(초)
@export var pour_offset: Vector2 = Vector2(225, -230)
@export var pour_rotation: float = -1.9
@export var fly_duration: float = 0.3
## 톡톡 흔드는 횟수, 한 번 흔드는 시간(초)과 흔드는 각도(라디안), 한 번에 떨어지는 알갱이 수
@export var shake_count: int = 3
@export var shake_duration: float = 0.16
@export var shake_angle: float = 0.25
@export var grains_per_shake: int = 7
## 알갱이 크기(픽셀), 떨어지는 시간(초), 요리 위에 흩어지는 반지름(픽셀)
@export var grain_size: float = 12.0
@export var grain_fall_duration: float = 0.4
@export var grain_spread: float = 90.0
## 다 뿌리고 닫기 전에 보여 주는 시간(초)
@export var after_sprinkle_hold: float = 0.7
## 병을 들고 요리 위에 있을 때 요리 빛 색, 놓던 자리로 돌아가는 시간(초)
@export var dish_hover_color: Color = Color(1.15, 1.1, 0.85)
@export var put_back_duration: float = 0.15
## 끌었다고 보는 거리(픽셀). 이보다 적게 움직이고 떼면 "클릭으로 집기"로 보고 계속 들고 있는다.
@export var drag_threshold: float = 16.0
## 재료가 모자라요 안내를 (누른 뒤) 보여 주는 시간(초). 마우스를 올린 동안은 계속 보인다.
@export var message_duration: float = 1.5

var _is_open: bool = false
var _bob_tween: Tween
var _shakers: Array[GarnishShaker] = []
var _plain_garnish: Garnish
var _held: GarnishShaker
var _held_home: Vector2
var _grab_offset: Vector2
var _press_position: Vector2
var _is_sprinkling: bool = false
var _hint_text: String = ""
var _grains: Array[Control] = []
## 마지막으로 받은 마우스 위치 (화면 좌표). 입력 이벤트에서 바로 읽는다.
var _mouse_position: Vector2 = Vector2.ZERO
## 둥실거리는 요리 그림의 제자리 높이 (여러 번 열어도 자리가 밀리지 않게 처음 값을 기억한다)
var _dish_home_y: float = 0.0

@onready var _dish_box: Control = %DishBox
@onready var _dish_image: TextureRect = %DishImage
@onready var _glow: Control = $DishBox/Glow
@onready var _done_label: Label = %DoneLabel
@onready var _name_label: Label = %NameLabel
@onready var _badge_label: Label = %BadgeLabel
@onready var _shaker_layer: Control = %Shakers
@onready var _plain_button: Button = %PlainButton
@onready var _hint_label: Label = %HintLabel


func _ready() -> void:
	_plain_button.pressed.connect(func() -> void: _finish(_plain_garnish))
	_dish_home_y = _dish_image.position.y
	hide()


## 완성 요리를 보여 주고 고명을 고를 때까지 기다린다. hint: 아래에 보여 줄 손님 입맛 힌트 (없으면 빈 글)
func show_dish(recipe: Recipe, is_grandma_taste: bool, hint: String = "") -> Garnish:
	_dish_image.texture = DishArt.get_texture(recipe, dish_scale)
	_done_label.text = done_text
	_name_label.text = recipe.display_name
	_badge_label.text = grandma_text if is_grandma_taste else ""
	_hint_text = hint
	_hint_label.text = hint
	_clear_grains()
	_is_open = true
	_is_sprinkling = false
	_held = null
	_glow.self_modulate = Color.WHITE
	show()
	Sound.play(DONE_SOUND)
	_dish_box.pivot_offset = _dish_box.size / 2.0
	_dish_box.scale = Vector2.ONE * pop_start_scale
	var tween: Tween = create_tween()
	tween.tween_property(_dish_box, "scale", Vector2.ONE * pop_overshoot_scale, pop_duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_dish_box, "scale", Vector2.ONE, settle_duration)
	_bob()
	_build_shakers()
	var garnish: Garnish = await _garnish_done
	return garnish


## 고명 병을 오른쪽에 세우고 "그대로 내기" 버튼을 준비한다. 게임패드 선택은 병들과 버튼 사이에서 위아래로 돈다.
func _build_shakers() -> void:
	for shaker: GarnishShaker in _shakers:
		shaker.queue_free()
	_shakers.clear()
	_plain_garnish = null
	var index: int = 0
	for garnish: Garnish in GameData.get_all_garnishes():
		if garnish.serve_as_is:
			_plain_garnish = garnish
			continue
		var shaker: GarnishShaker = GarnishShaker.new()
		_shaker_layer.add_child(shaker)
		shaker.setup(garnish, GameState.has_ingredients(garnish.get_cost()))
		shaker.position = Vector2(shaker_column_x, shaker_top + shaker_step * index)
		shaker.picked.connect(_on_shaker_picked)
		shaker.hover_changed.connect(_on_shaker_hover_changed)
		shaker.chosen.connect(_on_shaker_chosen)
		_shakers.append(shaker)
		index += 1
	_plain_button.visible = _plain_garnish != null
	_plain_button.disabled = false
	var order: Array[Control] = []
	for shaker: GarnishShaker in _shakers:
		if shaker.is_available:
			order.append(shaker)
	if _plain_button.visible:
		order.append(_plain_button)
	for i: int in order.size():
		var control: Control = order[i]
		control.focus_neighbor_top = control.get_path_to(order[i - 1])
		control.focus_neighbor_bottom = control.get_path_to(order[(i + 1) % order.size()])
		control.focus_neighbor_left = control.get_path_to(control)
		control.focus_neighbor_right = control.get_path_to(control)
		control.focus_previous = control.focus_neighbor_top
		control.focus_next = control.focus_neighbor_bottom
	if not order.is_empty():
		order[0].grab_focus()


# --- 마우스: 집기, 옮기기, 놓기 ---

func _on_shaker_picked(shaker: GarnishShaker) -> void:
	if _is_sprinkling or _held != null:
		return
	if not shaker.is_available:
		_show_short_message(shaker.garnish)
		return
	Sound.play(PICK_SOUND)
	_held = shaker
	_held_home = shaker.position
	_press_position = _mouse_position
	_grab_offset = _press_position - shaker.global_position
	shaker.is_held = true
	_shaker_layer.move_child(shaker, -1)


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_mouse_position = (event as InputEventMouse).position
	if not _is_open or _held == null or _is_sprinkling:
		return
	var mouse: Vector2 = _mouse_position
	var is_over_dish: bool = _dish_box.get_global_rect().has_point(mouse)
	if event is InputEventMouseMotion:
		_held.global_position = mouse - _grab_offset
		_glow.self_modulate = dish_hover_color if is_over_dish else Color.WHITE
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# 누르면 바로, 끌다가 떼면 그 자리에서: 요리 위면 뿌리고 아니면 돌려놓는다.
		if event.pressed or mouse.distance_to(_press_position) > drag_threshold:
			get_viewport().set_input_as_handled()
			if is_over_dish:
				_sprinkle(_held)
			else:
				_put_back()
	elif (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT) \
			or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_put_back()


func _put_back() -> void:
	var shaker: GarnishShaker = _held
	_held = null
	_glow.self_modulate = Color.WHITE
	shaker.is_held = false
	create_tween().tween_property(shaker, "position", _held_home, put_back_duration).set_trans(Tween.TRANS_QUAD)


## 재료가 모자란 병에 마우스를 올리면 "꿀이 모자라요!", 벗어나면 다시 입맛 힌트.
func _on_shaker_hover_changed(shaker: GarnishShaker, hovered: bool) -> void:
	if shaker.is_available or not _is_open:
		return
	if hovered:
		_hint_label.text = _short_text(shaker.garnish)
	else:
		_hint_label.text = _hint_text


func _show_short_message(garnish: Garnish) -> void:
	_hint_label.text = _short_text(garnish)
	get_tree().create_timer(message_duration, false).timeout.connect(func() -> void:
		if _is_open and _hint_label.text == _short_text(garnish) and not _is_hovering_short_shaker():
			_hint_label.text = _hint_text)


func _short_text(garnish: Garnish) -> String:
	var ingredient_name: String = garnish.cost_ingredient.display_name if garnish.cost_ingredient != null else garnish.display_name
	return SHORT_FORMAT % [ingredient_name, Korean.subject_particle(ingredient_name)]


func _is_hovering_short_shaker() -> bool:
	for shaker: GarnishShaker in _shakers:
		if not shaker.is_available and shaker.get_global_rect().has_point(_mouse_position):
			return true
	return false


# --- 게임패드·키보드: 고르면 날아가서 뿌린다 ---

func _on_shaker_chosen(shaker: GarnishShaker) -> void:
	if _is_sprinkling or _held != null:
		return
	_sprinkle(shaker)


# --- 뿌리기 ---

## 병이 요리 위로 가서 기울어지고, 톡톡 흔들 때마다 알갱이가 요리 위로 떨어진다. 다 뿌리면 닫는다.
func _sprinkle(shaker: GarnishShaker) -> void:
	_is_sprinkling = true
	_held = null
	_glow.self_modulate = Color.WHITE
	shaker.is_held = true
	_shaker_layer.move_child(shaker, -1)
	_plain_button.hide()
	for other: GarnishShaker in _shakers:
		other.mouse_filter = Control.MOUSE_FILTER_IGNORE
		other.focus_mode = Control.FOCUS_NONE
	# 병 바닥 가운데를 기준으로 옮기고 기울인다.
	var start_base: Vector2 = shaker.global_position + shaker.get_base_offset()
	var target_base: Vector2 = _dish_box.get_global_rect().get_center() + pour_offset
	var fly: Tween = create_tween()
	fly.tween_method(func(t: float) -> void:
		shaker.set_pose(start_base.lerp(target_base, t), lerpf(0.0, pour_rotation, t)), 0.0, 1.0, fly_duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await fly.finished
	for i: int in shake_count:
		var shake: Tween = create_tween()
		shake.tween_method(func(angle: float) -> void: shaker.set_pose(target_base, angle),
				pour_rotation, pour_rotation - shake_angle, shake_duration / 2.0)
		shake.tween_method(func(angle: float) -> void: shaker.set_pose(target_base, angle),
				pour_rotation - shake_angle, pour_rotation, shake_duration / 2.0)
		await shake.finished
		Sound.play(SPRINKLE_SOUND)
		_drop_grains(shaker)
	await get_tree().create_timer(after_sprinkle_hold, false).timeout
	_finish(shaker.garnish)


## 병 입구에서 알갱이가 요리 위로 떨어진다. 떨어진 알갱이는 요리에 붙어 같이 둥실거린다.
func _drop_grains(shaker: GarnishShaker) -> void:
	var mouth: Vector2 = shaker.get_mouth_global_position()
	var dish_center: Vector2 = _dish_image.get_global_rect().get_center()
	for i: int in grains_per_shake:
		var grain: ColorRect = ColorRect.new()
		grain.color = shaker.garnish.sprinkle_color
		grain.size = Vector2.ONE * grain_size
		grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(grain)
		grain.global_position = mouth - grain.size / 2.0
		var landing: Vector2 = dish_center + Vector2.from_angle(randf() * TAU) * randf() * grain_spread - grain.size / 2.0
		var tween: Tween = create_tween()
		tween.tween_property(grain, "global_position", landing, grain_fall_duration * randf_range(0.8, 1.2)) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(func() -> void:
			if is_instance_valid(grain) and grain.get_parent() == self:
				grain.reparent(_dish_image))
		_grains.append(grain)


func _clear_grains() -> void:
	for grain: Control in _grains:
		if is_instance_valid(grain):
			grain.queue_free()
	_grains.clear()


func _finish(garnish: Garnish) -> void:
	if not _is_open:
		return
	_is_sprinkling = false
	_held = null
	_close()
	_garnish_done.emit(garnish)


func _close() -> void:
	if not _is_open:
		return
	_is_open = false
	if _bob_tween != null:
		_bob_tween.kill()
	hide()
	closed.emit()


func _bob() -> void:
	if _bob_tween != null:
		_bob_tween.kill()
	_dish_image.position.y = _dish_home_y
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_dish_image, "position:y", _dish_home_y - bob_height, bob_duration / 2.0).set_trans(Tween.TRANS_SINE)
	_bob_tween.tween_property(_dish_image, "position:y", _dish_home_y, bob_duration / 2.0).set_trans(Tween.TRANS_SINE)
