class_name GuestSpot
extends Control
## 손님 자리. 손님 모습과 말풍선을 보여 준다. 부엌 조리대 앞과 저녁 평상에서 쓴다.
## 누가 무엇을 말할지는 정하지 않는다. 부엌이나 평상이 정해서 show_order / show_guest 로 알려 준다.

@onready var _portrait: TextureRect = %Portrait
@onready var _portrait_placeholder: ColorRect = %PortraitPlaceholder
@onready var _name_label: Label = %NameLabel
@onready var _bubble_text: Label = %BubbleText


func _ready() -> void:
	hide()


func show_order(guest: AnimalGuest, recipe: Recipe) -> void:
	show_guest(guest, guest.order_line.format({"recipe": recipe.display_name}))


## 손님 모습을 보여 주고 말풍선에 text 를 띄운다.
func show_guest(guest: AnimalGuest, text: String) -> void:
	var has_portrait: bool = guest.portrait != null
	_portrait.texture = guest.portrait
	_portrait.visible = has_portrait
	_portrait_placeholder.visible = not has_portrait
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
