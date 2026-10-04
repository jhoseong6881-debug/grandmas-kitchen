class_name GuestSpot
extends Control
## 손님 자리. 손님 모습과 말풍선을 보여 준다. 부엌 조리대 앞과 저녁 평상에서 쓴다.
## 누가 무엇을 말할지는 정하지 않는다. 부엌이나 평상이 정해서 show_order / show_guest 로 알려 준다.
## walk_in() 을 부르면 옆에서 통통 걸어 들어와 앉은 뒤에 말풍선이 보인다 (저녁 평상).
## 봄비 오는 날에는 우비를 입은 모습으로 보여 준다 (우비 그림이 없으면 임시 우비 도형을 씌운다).

const WALK_SOUND: StringName = &"walk"

## 걸어 들어오는 거리(픽셀, 오른쪽에서), 걸리는 시간(초), 걸음 수, 걸음마다 통통 튀는 높이, 앉을 때 내려앉는 정도
@export var walk_distance: float = 700.0
@export var walk_duration: float = 1.2
@export var walk_steps: int = 4
@export var walk_bob_height: float = 14.0
@export var sit_drop: float = 10.0
@export var sit_duration: float = 0.15

@onready var _portrait: TextureRect = %Portrait
@onready var _portrait_placeholder: ColorRect = %PortraitPlaceholder
@onready var _name_label: Label = %NameLabel
@onready var _bubble_text: Label = %BubbleText
## 말풍선 (걸어 들어오는 동안 숨긴다)
@onready var _bubble: Control = _bubble_text.get_parent().get_parent()
var _home_position: Vector2
var _walk_tween: Tween
## 임시 우비 (손님 모습 위, 이름 아래에 겹친다)
var _raincoat: RaincoatShape = RaincoatShape.new()


func walk_in() -> void:
	if _walk_tween != null and _walk_tween.is_valid():
		_walk_tween.kill()
	if _home_position == Vector2.ZERO:
		_home_position = position
	position = _home_position + Vector2(walk_distance, 0.0)
	_bubble.hide()
	show()
	_walk_tween = create_tween()
	var step_time: float = walk_duration / walk_steps
	for i: int in walk_steps:
		var step_end: Vector2 = _home_position + Vector2(walk_distance * (1.0 - float(i + 1) / walk_steps), 0.0)
		_walk_tween.tween_callback(Sound.play.bind(WALK_SOUND))
		_walk_tween.tween_property(self, "position", step_end + Vector2(0.0, -walk_bob_height), step_time / 2.0)
		_walk_tween.tween_property(self, "position:y", step_end.y, step_time / 2.0)
	# 평상에 앉기: 살짝 내려앉았다가 제자리
	_walk_tween.tween_property(self, "position:y", _home_position.y + sit_drop, sit_duration)
	_walk_tween.tween_property(self, "position:y", _home_position.y, sit_duration)
	_walk_tween.tween_callback(_bubble.show)


func _ready() -> void:
	hide()
	_raincoat.position = _portrait_placeholder.position
	_raincoat.size = _portrait_placeholder.size
	_raincoat.hide()
	add_child(_raincoat)
	move_child(_raincoat, _portrait.get_index() + 1)


func show_order(guest: AnimalGuest, recipe: Recipe) -> void:
	show_guest(guest, guest.order_line.format({"recipe": recipe.display_name}))


## 손님 모습을 보여 주고 말풍선에 text 를 띄운다. in_raincoat: 우비를 입은 모습으로 (봄비 오는 날)
func show_guest(guest: AnimalGuest, text: String, in_raincoat: bool = false) -> void:
	var texture: Texture2D = guest.raincoat_portrait if in_raincoat and guest.raincoat_portrait != null else guest.portrait
	var has_portrait: bool = texture != null
	_portrait.texture = texture
	_portrait.visible = has_portrait
	_portrait_placeholder.visible = not has_portrait
	_raincoat.visible = in_raincoat and guest.raincoat_portrait == null
	if _raincoat.visible:
		_raincoat.color = GameData.get_rain_settings().raincoat_color
	_name_label.text = guest.display_name
	show()
	_set_bubble_text(text)


## 말풍선 내용을 바꾼다.
func say(text: String) -> void:
	_set_bubble_text(text)


## 한글이 낱말 중간에서 잘리지 않게 띄어쓰기 자리에서 줄을 바꿔 넣는다.
## (말풍선 폭을 아직 모르면 그대로 넣고 Godot 자동 줄바꿈에 맡긴다)
func _set_bubble_text(text: String) -> void:
	# 말풍선(장면에서 폭을 정해 둔 칸)의 폭에서 안쪽 여백을 뺀다. 숨겨져 있던 안쪽 칸은 폭이 아직 0일 수 있어서.
	var margin: MarginContainer = _bubble_text.get_parent() as MarginContainer
	var bubble: Control = margin.get_parent() as Control if margin != null else null
	var width: float = 0.0
	if bubble != null:
		width = bubble.size.x - margin.get_theme_constant("margin_left") - margin.get_theme_constant("margin_right")
	if width <= 0.0:
		_bubble_text.text = text
		return
	_bubble_text.text = Korean.wrap_by_spaces(text, _bubble_text.get_theme_font("font"),
			_bubble_text.get_theme_font_size("font_size"), width)


func clear() -> void:
	hide()
