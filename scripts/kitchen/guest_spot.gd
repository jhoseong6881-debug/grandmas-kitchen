class_name GuestSpot
extends Control
## 조리대 앞 손님 자리. 손님 모습과 주문 말풍선을 보여 준다.
## 누가 무엇을 주문할지는 정하지 않는다. 부엌(Kitchen)이 정해서 show_order 로 알려 준다.

@onready var _portrait: TextureRect = %Portrait
@onready var _portrait_placeholder: ColorRect = %PortraitPlaceholder
@onready var _name_label: Label = %NameLabel
@onready var _bubble_text: Label = %BubbleText


func _ready() -> void:
	hide()


func show_order(guest: AnimalGuest, recipe: Recipe) -> void:
	var has_portrait: bool = guest.portrait != null
	_portrait.texture = guest.portrait
	_portrait.visible = has_portrait
	_portrait_placeholder.visible = not has_portrait
	_name_label.text = guest.display_name
	_bubble_text.text = guest.order_line.format({"recipe": recipe.display_name})
	show()


func clear() -> void:
	hide()
