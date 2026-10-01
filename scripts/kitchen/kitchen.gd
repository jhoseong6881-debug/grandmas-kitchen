extends Control
## 부엌 화면. 지금은 날짜와 가진 재료를 보여 주는 첫 화면이다.

const DAY_TEXT_FORMAT: String = "%d일째"

## 테스트 버튼을 누르면 받는 재료. 실제로 재료를 얻는 흐름이 생기면 버튼과 함께 지운다.
@export var test_ingredient: Ingredient

## 지금 와 있는 손님과 그 손님의 주문. 손님이 없으면 null.
var current_guest: AnimalGuest
var current_order: Recipe

@onready var _day_label: Label = %DayLabel
@onready var _test_button: Button = %TestButton
@onready var _guest_spot: GuestSpot = %GuestSpot


func _ready() -> void:
	GameState.day_changed.connect(_on_day_changed)
	_test_button.pressed.connect(_on_test_button_pressed)
	_on_day_changed(GameState.current_day)
	_call_next_guest()


## data/guests 의 손님 중 한 명을 불러, 그 손님이 좋아하는 요리 중 하나를 주문받는다.
func _call_next_guest() -> void:
	var guests: Array[AnimalGuest] = GameData.get_all_guests()
	if guests.is_empty():
		push_warning("data/guests 에 손님이 없습니다")
		return
	var guest: AnimalGuest = guests.pick_random()
	if guest.favorite_recipes.is_empty():
		push_warning("손님 '%s'의 Favorite Recipes 가 비어 있어 주문할 수 없습니다" % guest.id)
		return
	current_guest = guest
	current_order = guest.favorite_recipes.pick_random()
	_guest_spot.show_order(current_guest, current_order)


func _on_day_changed(new_day: int) -> void:
	_day_label.text = DAY_TEXT_FORMAT % new_day


func _on_test_button_pressed() -> void:
	if test_ingredient == null:
		push_warning("Kitchen 노드의 Test Ingredient 칸이 비어 있습니다")
		return
	GameState.add_ingredient(test_ingredient.id)
