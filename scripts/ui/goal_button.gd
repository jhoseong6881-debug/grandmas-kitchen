class_name GoalButton
extends Control
## 계절 목표 버튼 (텃밭, 부엌 왼쪽). 과녁 아이콘 옆에 "봄 목표" 글자. 누르면 화면 가운데에 목표판(GoalBoard)이 크게 뜬다.
## 오늘 단골과 약속이 있으면 버튼 글자에 ★ 이 붙는다. 큰 목표판은 아무 데나 누르거나 A·B·Esc 로 닫는다.
## 아이콘 그림은 Board Icon 칸에 넣으면 바뀐다 (원본 32×32, 배경 투명). 없으면 도트로 그린 임시 과녁과 화살.

const TITLE_FORMAT: String = "%s 목표"
const PROMISE_MARK: String = " ★"
const PLACEHOLDER_PIXELS: int = 32

@export var board_icon: Texture2D
@export var icon_scale: int = 3
## 임시 아이콘(과녁과 화살) 색
@export var target_red_color: Color = Color(0.96, 0.17, 0.22)
@export var target_shade_color: Color = Color(0.68, 0.1, 0.17)
@export var target_white_color: Color = Color(0.92, 0.9, 0.88)
@export var target_orange_color: Color = Color(1.0, 0.66, 0.2)
@export var arrow_color: Color = Color(0.33, 0.4, 0.55)
@export var arrow_light_color: Color = Color(0.55, 0.62, 0.73)
## 크게 뜬 목표판이 나타나는 시간(초)
@export var popup_fade_duration: float = 0.15

@onready var _button: Button = %Button
@onready var _popup: Control = %Popup


func _ready() -> void:
	var image: Image = board_icon.get_image().duplicate() if board_icon != null else _draw_placeholder()
	if image.is_compressed():
		image.decompress()
	image.resize(image.get_width() * icon_scale, image.get_height() * icon_scale, Image.INTERPOLATE_NEAREST)
	_button.icon = ImageTexture.create_from_image(image)
	_button.pressed.connect(open)
	_popup.hide()
	GameState.day_changed.connect(_refresh_text.unbind(1))
	_refresh_text()


func _refresh_text() -> void:
	var season: SeasonData = GameData.get_current_season()
	_button.text = TITLE_FORMAT % (season.display_name if season != null else "")
	if GameState.has_promise_on(GameState.current_day):
		_button.text += PROMISE_MARK


## 누를 수 있는지 (부엌에서 요리 미니게임을 하는 동안은 막는다)
func set_enabled(enabled: bool) -> void:
	_button.disabled = not enabled
	_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


func open() -> void:
	# 버튼 자리와 상관없이 화면 전체를 덮는다.
	_popup.global_position = Vector2.ZERO
	_popup.size = get_viewport_rect().size
	_popup.modulate.a = 0.0
	_popup.show()
	_popup.grab_focus()
	create_tween().tween_property(_popup, "modulate:a", 1.0, popup_fade_duration)


func close() -> void:
	_popup.hide()
	_button.grab_focus()


func _on_popup_gui_input(event: InputEvent) -> void:
	var is_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if is_click or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_popup.accept_event()
		close()


## 임시 아이콘: 과녁에 화살 하나 (빨강·흰색·빨강·주황·빨강 고리, 왼쪽은 그늘, 오른쪽에서 꽂힌 화살)
func _draw_placeholder() -> Image:
	var size: int = PLACEHOLDER_PIXELS
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var center: Vector2 = Vector2(13.5, 15.5)
	for y: int in size:
		for x: int in size:
			var d: Vector2 = (Vector2(x, y) - center).abs()
			# 팔각형 모양 거리 (도트 과녁처럼 모서리가 깎인 모양)
			var r: float = maxf(maxf(d.x, d.y), (d.x + d.y) * 0.72)
			var color: Color = Color.TRANSPARENT
			if r <= 12.0:
				color = target_red_color
			if r <= 9.5:
				color = target_white_color
			if r <= 7.5:
				color = target_red_color
			if r <= 5.5:
				color = target_orange_color
			if r <= 3.5:
				color = target_red_color
			if color == target_red_color and r > 9.5 and x < center.x - 8.0:
				color = target_shade_color
			if color.a > 0.0:
				image.set_pixel(x, y, color)
	# 화살: 과녁 가운데에서 오른쪽으로 뻗은 대와 깃
	image.fill_rect(Rect2i(14, 14, 15, 1), arrow_light_color)
	image.fill_rect(Rect2i(14, 15, 15, 2), arrow_color)
	image.fill_rect(Rect2i(24, 11, 7, 3), arrow_light_color)
	image.fill_rect(Rect2i(24, 17, 7, 3), arrow_color)
	return image
