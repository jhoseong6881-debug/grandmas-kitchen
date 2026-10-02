class_name PlantPicker
extends Control
## "무엇을 심을까요?" 창. 빈 칸을 누르면 열려서, 그 밭에 심을 수 있는 작물을 보여 준다.
## 작물마다 자라는 날, 거두는 개수, 씨앗(심는 데 드는 재료)을 보여 주고, 씨앗이 모자라면 고를 수 없다.
## 고르면 closed(작물), 그만두면 closed(null).

signal closed(crop: Crop)

const TITLE_FORMAT: String = "%s에 무엇을 심을까요?"
const CROP_FORMAT: String = "%s  ·  %d일 뒤 %d개  ·  %s"
const FREE_SEED_TEXT: String = "씨앗 공짜"
const SEED_FORMAT: String = "%s %d개 필요 (가진 것 %d)"

@export var row_font_size: int = 36
@export var row_height: float = 72.0

@onready var _title_label: Label = %TitleLabel
@onready var _crop_rows: VBoxContainer = %CropRows
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	_cancel_button.pressed.connect(_close.bind(null))
	hide()


func open(place: GardenPlace) -> void:
	for child: Node in _crop_rows.get_children():
		child.queue_free()
	_title_label.text = TITLE_FORMAT % place.display_name
	var buttons: Array[Button] = []
	for crop: Crop in place.crops:
		var button: Button = Button.new()
		button.custom_minimum_size.y = row_height
		button.add_theme_font_size_override("font_size", row_font_size)
		button.text = CROP_FORMAT % [crop.ingredient.display_name, crop.grow_days, crop.harvest_amount, _seed_text(crop)]
		button.disabled = not GameState.can_plant(crop)
		button.pressed.connect(_close.bind(crop))
		_crop_rows.add_child(button)
		buttons.append(button)
	_keep_focus_inside(buttons)
	show()
	var first_enabled: Array[Button] = buttons.filter(func(button: Button) -> bool: return not button.disabled)
	(first_enabled[0] if not first_enabled.is_empty() else _cancel_button).grab_focus()


func _seed_text(crop: Crop) -> String:
	if crop.seed_ingredient == null or crop.seed_amount <= 0:
		return FREE_SEED_TEXT
	return SEED_FORMAT % [crop.seed_ingredient.display_name, crop.seed_amount,
			GameState.get_ingredient_count(crop.seed_ingredient.id)]


func _close(crop: Crop) -> void:
	hide()
	closed.emit(crop)


## 창이 열린 동안 방향키로 뒤쪽 버튼에 가지 않도록, 선택이 작물 목록과 그만두기 버튼 사이에서만 위아래로 돈다.
func _keep_focus_inside(crop_buttons: Array[Button]) -> void:
	var order: Array[Button] = crop_buttons.duplicate()
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
		_close(null)
