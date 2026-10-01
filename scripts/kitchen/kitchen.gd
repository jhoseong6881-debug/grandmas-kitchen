extends Control
## 부엌 화면. 지금은 날짜와 가진 재료를 보여 주는 첫 화면이다.

const DAY_TEXT_FORMAT: String = "%d일째"

## 테스트 버튼을 누르면 받는 재료. 실제로 재료를 얻는 흐름이 생기면 버튼과 함께 지운다.
@export var test_ingredient: Ingredient

@onready var _day_label: Label = %DayLabel
@onready var _test_button: Button = %TestButton


func _ready() -> void:
	GameState.day_changed.connect(_on_day_changed)
	_test_button.pressed.connect(_on_test_button_pressed)
	_on_day_changed(GameState.current_day)


func _on_day_changed(new_day: int) -> void:
	_day_label.text = DAY_TEXT_FORMAT % new_day


func _on_test_button_pressed() -> void:
	if test_ingredient == null:
		push_warning("Kitchen 노드의 Test Ingredient 칸이 비어 있습니다")
		return
	GameState.add_ingredient(test_ingredient.id)
