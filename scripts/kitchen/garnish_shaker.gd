class_name GarnishShaker
extends Control
## 요리 "완성~!" 장면 옆에 놓이는 고명 병 하나 (DishShowcase 가 만든다).
## 마우스를 올리거나 게임패드로 선택하면 병이 공중으로 들리고 노란 테두리가 생긴다 (그림자는 제자리에 남는다).
## 마우스로 누르면 picked, 게임패드·키보드로 누르면 chosen 을 보낸다. 집어서 옮기고 뿌리는 건 DishShowcase 가 한다.
## 고명 그림(Garnish.shaker_image)이 없으면 뚜껑 + 유리병 + 이름표 임시 모양을 그린다.
## 재료가 모자라 못 쓰는 고명은 살짝 회색 톤으로 그리고 들리지 않는다 (마우스를 올리면 DishShowcase 가 "꿀이 모자라요!").

signal picked(shaker: GarnishShaker)
signal chosen(shaker: GarnishShaker)
## 마우스가 병에 올라가거나(true) 벗어났을 때(false)
signal hover_changed(shaker: GarnishShaker, hovered: bool)

## 병 크기(픽셀). 그림자는 병 아래에 붙는다.
const BOTTLE_SIZE: Vector2 = Vector2(150, 210)
const SHADOW_HEIGHT: float = 28.0

## 들리는 높이(픽셀)와 시간(초)
@export var lift_height: float = 36.0
@export var lift_duration: float = 0.12
## 하이라이트 테두리 색과 두께
@export var highlight_color: Color = Color(1, 0.84, 0.1)
@export var highlight_width: int = 8
## 임시 병 색: 뚜껑, 유리, 유리 안 고명 칸
@export var cap_color: Color = Color(0.55, 0.6, 0.66)
@export var glass_color: Color = Color(0.78, 0.84, 0.9, 0.95)
@export var label_color: Color = Color(0.95, 0.94, 0.9)
@export var label_font_size: int = 36
@export var shadow_color: Color = Color(0, 0, 0, 0.22)
## 못 쓰는 고명(재료 부족)을 회색으로 바꾸는 정도(0~1)와 어둡게 하는 정도(0~1)
@export var unavailable_gray: float = 0.75
@export var unavailable_darken: float = 0.15

var garnish: Garnish
var is_available: bool = true
## 손에 들려 있는지 (들려 있으면 계속 들린 모습, 그림자는 그리지 않는다)
var is_held: bool = false:
	set(value):
		is_held = value
		queue_redraw()

## 0(내려놓음) ~ 1(다 들림)
var _lift: float = 0.0
var _is_hovered: bool = false
## 선택(포커스)됐을 때 들어 올려 강조할지. 마우스로 하는 중에는 끈다 (안 고른 병이 골라진 것처럼 보이지 않게).
var show_focus: bool = true
var _lift_tween: Tween


func setup(new_garnish: Garnish, available: bool) -> void:
	garnish = new_garnish
	is_available = available
	custom_minimum_size = BOTTLE_SIZE + Vector2(0, SHADOW_HEIGHT)
	size = custom_minimum_size
	focus_mode = Control.FOCUS_ALL if available else Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
	tooltip_text = garnish.display_name


func _ready() -> void:
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	focus_entered.connect(_update_lift)
	focus_exited.connect(_update_lift)


func set_show_focus(value: bool) -> void:
	if show_focus == value:
		return
	show_focus = value
	_update_lift()


func _set_hovered(hovered: bool) -> void:
	_is_hovered = hovered
	_update_lift()
	hover_changed.emit(self, hovered)


## 마우스가 올라가 있거나 선택돼 있거나 손에 들려 있으면 들고, 아니면 내린다.
func _update_lift() -> void:
	var target: float = 1.0 if is_available and (_is_hovered or (has_focus() and show_focus) or is_held) else 0.0
	if _lift_tween != null:
		_lift_tween.kill()
	_lift_tween = create_tween()
	_lift_tween.tween_method(_set_lift, _lift, target, lift_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_lift(value: float) -> void:
	_lift = value
	queue_redraw()


## 병 바닥 가운데 (병 왼쪽 위에서). 옮기고 기울일 때 기준점.
func get_base_offset() -> Vector2:
	return Vector2(BOTTLE_SIZE.x / 2.0, BOTTLE_SIZE.y)


## 병 바닥 가운데가 base(화면 좌표)에 오도록 놓고, 바닥을 중심으로 angle(라디안)만큼 기울인다.
func set_pose(base: Vector2, angle: float) -> void:
	rotation = angle
	global_position = base - get_base_offset().rotated(angle)


## 병 입구(뚜껑 꼭대기 가운데) 위치. 알갱이가 여기서 나온다.
func get_mouth_global_position() -> Vector2:
	return get_global_transform() * Vector2(BOTTLE_SIZE.x / 2.0, -_lift * lift_height)


## 못 쓰는 고명도 마우스로 누르면 picked 를 보낸다 (DishShowcase 가 "재료가 모자라요"를 띄운다).
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		picked.emit(self)
	elif is_available and event.is_action_pressed("ui_accept"):
		accept_event()
		chosen.emit(self)


func _draw() -> void:
	if garnish == null:
		return
	var lifted: float = 1.0 if is_held else _lift
	if not is_held:
		# 그림자는 바닥(병 아래)에 남고, 병이 들릴수록 조금 작아진다.
		var shadow_width: float = BOTTLE_SIZE.x * (1.1 - 0.2 * lifted)
		var center: Vector2 = Vector2(BOTTLE_SIZE.x / 2.0, BOTTLE_SIZE.y + SHADOW_HEIGHT / 2.0 - 4.0)
		draw_set_transform(center, 0.0, Vector2(1.0, SHADOW_HEIGHT / shadow_width))
		draw_circle(Vector2.ZERO, shadow_width / 2.0, shadow_color)
		draw_set_transform(Vector2.ZERO)
	var top: float = -lifted * lift_height
	var body: Rect2 = Rect2(Vector2(0, top), BOTTLE_SIZE)
	var is_lit: bool = is_available and lifted > 0.5
	if garnish.shaker_image != null:
		if is_lit:
			draw_rect(body.grow(highlight_width / 2.0), highlight_color, false, highlight_width)
		draw_texture_rect(garnish.shaker_image, body, false, Color.WHITE if is_available else _tone(Color.WHITE))
		return
	_draw_placeholder(body, is_lit)


## 임시 병: 둥근 뚜껑(구멍 넷) + 유리병 + 가운데 이름표
func _draw_placeholder(body: Rect2, is_lit: bool) -> void:
	var cap: Rect2 = Rect2(body.position + Vector2(body.size.x * 0.12, 0), Vector2(body.size.x * 0.76, body.size.y * 0.3))
	var glass: Rect2 = Rect2(body.position + Vector2(0, body.size.y * 0.26), Vector2(body.size.x, body.size.y * 0.74))
	if is_lit:
		_draw_round(cap.grow(highlight_width), highlight_color, 34)
		_draw_round(glass.grow(highlight_width), highlight_color, 40)
	_draw_round(glass, _tone(glass_color), 34)
	_draw_round(glass.grow(-14), _tone(label_color), 24)
	_draw_round(cap, _tone(cap_color), 30)
	for hole: Vector2 in [Vector2(-0.18, 0.35), Vector2(0.0, 0.25), Vector2(0.18, 0.35), Vector2(0.0, 0.55)]:
		draw_circle(cap.get_center() + Vector2(hole.x * cap.size.x, (hole.y - 0.4) * cap.size.y), 5.0, _tone(cap_color.darkened(0.45)))
	var font: Font = get_theme_font("font", "Label")
	var text: String = garnish.get_short_name()
	var lines: int = text.count("\n") + 1
	var line_height: float = font.get_height(label_font_size)
	var label_top: float = glass.get_center().y - line_height * lines / 2.0 + font.get_ascent(label_font_size)
	draw_multiline_string(font, Vector2(glass.position.x, label_top), text, HORIZONTAL_ALIGNMENT_CENTER, glass.size.x,
			label_font_size, -1, _tone(Color(0.15, 0.12, 0.1)))


## 못 쓰는 고명이면 색을 회색 톤으로 바꾼다 (쓸 수 있으면 그대로).
func _tone(color: Color) -> Color:
	if is_available:
		return color
	var gray: float = color.get_luminance()
	return color.lerp(Color(gray, gray, gray, color.a), unavailable_gray).darkened(unavailable_darken)


func _draw_round(rect: Rect2, color: Color, radius: int) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.draw(get_canvas_item(), rect)
