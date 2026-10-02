class_name PlotRow
extends HBoxContainer
## 밭 한 곳(GardenPlace)의 칸들을 버튼으로 보여 준다. 당근 텃밭과 버섯 원목이 함께 쓴다.
## 다 자란 칸을 누르면 거두고, 빈 칸을 누르면 plant_picker 를 열어 심을 작물을 고른다.
## 거두거나 심으면 시그널로 알려서, 장면이 "+1 당근" 같은 글을 띄우고 다음 할 일을 고르게 한다.

signal harvested(crop: Crop, plot_button: Button)
signal planted(crop: Crop, plot_button: Button)

const RIPE_FORMAT: String = "%s\n거두기"
const GROWING_FORMAT: String = "%s\n%d일 뒤"
const EMPTY_FORMAT: String = "빈 %s\n심기"

## 보여 줄 밭 (data/places/ 의 id)
@export var place_id: StringName = &""
## 빈 칸을 눌렀을 때 여는 "무엇을 심을까요?" 창
@export var plant_picker: PlantPicker
@export var plot_size: Vector2 = Vector2(260, 240)
@export var plot_font_size: int = 36

var _place: GardenPlace
var _buttons: Array[Button] = []


func _ready() -> void:
	_place = GameData.get_garden_place(place_id)
	if _place == null:
		push_warning("밭 '%s' 을(를) data/places/ 에서 찾지 못했습니다" % place_id)
		return
	# 칸 수는 단골 선물로 늘어날 수 있어서 GameState 에서 읽는다.
	for i: int in GameState.get_plot_count(place_id):
		var button: Button = Button.new()
		button.custom_minimum_size = plot_size
		button.add_theme_font_size_override("font_size", plot_font_size)
		button.pressed.connect(_on_plot_pressed.bind(i))
		add_child(button)
		_buttons.append(button)
	refresh()


func get_place() -> GardenPlace:
	return _place


## 칸마다 글을 새로 쓴다. 자라는 중인 칸은 누를 수 없다.
func refresh() -> void:
	for i: int in _buttons.size():
		var button: Button = _buttons[i]
		var crop: Crop = GameState.get_plot_crop(place_id, i)
		if crop == null:
			button.text = EMPTY_FORMAT % _place.plot_name
			button.disabled = false
		elif GameState.is_plot_ripe(place_id, i):
			button.text = RIPE_FORMAT % crop.ingredient.display_name
			button.disabled = false
		else:
			button.text = GROWING_FORMAT % [crop.ingredient.display_name, GameState.get_plot_days_left(place_id, i)]
			button.disabled = true


## 지금 할 일이 있는 칸(거둘 칸, 또는 씨앗이 있어 심을 수 있는 빈 칸)의 버튼. 없으면 null.
func get_next_action_button() -> Button:
	for i: int in _buttons.size():
		if GameState.is_plot_ripe(place_id, i):
			return _buttons[i]
	for i: int in _buttons.size():
		if GameState.get_plot_crop(place_id, i) == null and _place.crops.any(GameState.can_plant):
			return _buttons[i]
	return null


func _on_plot_pressed(plot_index: int) -> void:
	if GameState.is_plot_ripe(place_id, plot_index):
		var crop: Crop = GameState.harvest_plot(place_id, plot_index)
		refresh()
		harvested.emit(crop, _buttons[plot_index])
	elif GameState.get_plot_crop(place_id, plot_index) == null and plant_picker != null:
		plant_picker.open(_place)
		var crop: Crop = await plant_picker.closed
		if crop != null and GameState.plant_plot(place_id, plot_index, crop):
			refresh()
			planted.emit(crop, _buttons[plot_index])
		else:
			_buttons[plot_index].grab_focus()
