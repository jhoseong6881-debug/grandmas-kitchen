class_name ChoicePicker
extends Control
## 여러 개 중 하나를 고르는 창의 공통 틀. 텃밭 "무엇을 심을까요?"(PlantPicker)와
## 부엌 "어떻게 마무리할까요?"(GarnishPicker)가 물려받는다.
## open_choices() 로 제목과 고를 것들을 넣어 열고, 고르면 chosen(번호), 그만두면 chosen(-1).
## 씬에는 %TitleLabel, %ChoiceRows(VBoxContainer), %CancelButton 이 있어야 한다.

signal chosen(index: int)

@export var row_font_size: int = 36
@export var row_height: float = 72.0

@onready var _title_label: Label = %TitleLabel
@onready var _choice_rows: VBoxContainer = %ChoiceRows
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	_cancel_button.pressed.connect(_close.bind(-1))
	hide()


## texts 와 enabled 는 같은 길이. enabled 가 false 인 줄은 보이지만 고를 수 없다.
func open_choices(title: String, texts: Array[String], enabled: Array[bool]) -> void:
	for child: Node in _choice_rows.get_children():
		child.queue_free()
	_title_label.text = title
	var buttons: Array[Button] = []
	for i: int in texts.size():
		var button: Button = Button.new()
		button.custom_minimum_size.y = row_height
		button.add_theme_font_size_override("font_size", row_font_size)
		button.text = texts[i]
		button.disabled = not enabled[i]
		button.pressed.connect(_close.bind(i))
		_choice_rows.add_child(button)
		buttons.append(button)
	_keep_focus_inside(buttons)
	show()
	var first_enabled: Array[Button] = buttons.filter(func(button: Button) -> bool: return not button.disabled)
	(first_enabled[0] if not first_enabled.is_empty() else _cancel_button).grab_focus()


func _close(index: int) -> void:
	hide()
	chosen.emit(index)


## 창이 열린 동안 방향키로 뒤쪽 버튼에 가지 않도록, 선택이 고를 것들과 그만두기 버튼 사이에서만 위아래로 돈다.
func _keep_focus_inside(choice_buttons: Array[Button]) -> void:
	var order: Array[Button] = choice_buttons.duplicate()
	order.append(_cancel_button)
	for i: int in order.size():
		var button: Button = order[i]
		button.focus_neighbor_top = button.get_path_to(order[i - 1])
		button.focus_neighbor_bottom = button.get_path_to(order[(i + 1) % order.size()])
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
		button.focus_previous = button.focus_neighbor_top
		button.focus_next = button.focus_neighbor_bottom


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close(-1)
