class_name PlotRow
extends HBoxContainer
## 밭 한 곳(GardenPlace)의 칸들을 버튼으로 보여 준다. 당근 텃밭과 버섯 원목이 함께 쓴다.
## 다 자란 칸을 누르면 거두고, 빈 칸을 누르면 plant_picker 를 열어 심을 작물을 고른다.
## 거두거나 심으면 시그널로 알려서, 장면이 "+1 당근" 같은 글을 띄우고 다음 할 일을 고르게 한다.
## 칸 안에는 자란 정도만큼 작물(PlotPlant)이 그려지고, 글은 칸 아래쪽에 작게 쓴다.
## 그날 처음 이 밭에 오면 어제 크기에서 오늘 크기로 쑥 자란다. 칸을 누르면 작물이 부시럭 흔들린다
## (자라는 중인 칸은 흔들리면서 "2일 뒤"가 떠오른다).

signal harvested(crop: Crop, plot_button: Button)
signal planted(crop: Crop, plot_button: Button)

const RIPE_FORMAT: String = "%s 거두기"
const GROWING_FORMAT: String = "%s · %d일 뒤"
const EMPTY_FORMAT: String = "빈 %s · 심기"
const DAYS_LEFT_POP_FORMAT: String = "%d일 뒤에 거둬요"
## 효과음 이름 (data/sounds/ 의 id)
const HARVEST_SOUND: StringName = &"harvest"
const PLANT_SOUND: StringName = &"plant"
const RUSTLE_SOUND: StringName = &"rustle"

## 보여 줄 밭 (data/places/ 의 id)
@export var place_id: StringName = &""
## 빈 칸을 눌렀을 때 여는 "무엇을 심을까요?" 창
@export var plant_picker: PlantPicker
@export var plot_size: Vector2 = Vector2(260, 240)
@export var plot_font_size: int = 24
## 칸 아래쪽 글이 차지하는 높이 (그 위가 작물 자리)
@export var label_height: float = 56.0
## 자라는 중인 칸을 눌렀을 때 떠오르는 글
@export var pop_rise: float = 60.0
@export var pop_duration: float = 0.8
@export var pop_font_size: int = 24
@export var pop_color: Color = Color(1, 0.96, 0.85)
## 칸이 많아 줄 폭(이 노드의 크기)에 다 안 들어가면, 칸 사이를 이만큼으로 줄이고 칸 폭도 줄여서 맞춘다.
@export var crowded_separation: int = 16

var _place: GardenPlace
var _buttons: Array[Button] = []
var _plants: Array[PlotPlant] = []
var _labels: Array[Label] = []


func _ready() -> void:
	_place = GameData.get_garden_place(place_id)
	if _place == null:
		push_warning("밭 '%s' 을(를) data/places/ 에서 찾지 못했습니다" % place_id)
		return
	# 칸을 넣으면 줄이 칸에 맞춰 넓어지므로, 장면에서 정한 줄 폭은 칸을 넣기 전에 잰다.
	var row_width: float = size.x
	# 칸 수는 단골 선물, 가게 단계 업으로 늘어날 수 있어서 GameState 에서 읽는다.
	for i: int in GameState.get_plot_count(place_id):
		var button: Button = Button.new()
		button.custom_minimum_size = plot_size
		button.pressed.connect(_on_plot_pressed.bind(i))
		var plant: PlotPlant = PlotPlant.new()
		plant.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		plant.offset_bottom = -label_height
		# 땅은 작물이 흔들려도 가만히 있게 따로 그린다 (작물 그림의 아래쪽 ground_height 자리).
		var ground: ColorRect = ColorRect.new()
		ground.color = _place.ground_color
		ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ground.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		ground.offset_top = -label_height - plant.ground_height
		ground.offset_bottom = -label_height
		button.add_child(ground)
		button.add_child(plant)
		var label: Label = Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", plot_font_size)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		label.offset_top = -label_height
		button.add_child(label)
		add_child(button)
		_buttons.append(button)
		_plants.append(plant)
		_labels.append(label)
	_fit_to_width(row_width)
	refresh()
	_grow_overnight()


## 칸이 늘어 (가게 단계 업, 단골 선물) 줄에 다 안 들어가면 칸 사이와 칸 폭을 줄인다. 양옆 버튼을 덮지 않게.
func _fit_to_width(row_width: float) -> void:
	var count: int = _buttons.size()
	var separation: int = get_theme_constant("separation")
	if count <= 1 or count * plot_size.x + (count - 1) * separation <= row_width:
		return
	separation = mini(separation, crowded_separation)
	add_theme_constant_override("separation", separation)
	# 양옆 버튼과 붙지 않게 양쪽에 칸 사이만큼 여백을 남긴다 (줄은 가운데 정렬).
	var width: float = (row_width - (count + 1) * separation) / count
	for button: Button in _buttons:
		button.custom_minimum_size.x = width


func get_place() -> GardenPlace:
	return _place


## 칸마다 글과 작물 그림을 새로 그린다.
func refresh() -> void:
	for i: int in _buttons.size():
		var crop: Crop = GameState.get_plot_crop(place_id, i)
		var is_ripe: bool = GameState.is_plot_ripe(place_id, i)
		if crop == null:
			_labels[i].text = EMPTY_FORMAT % _place.plot_name
		elif is_ripe:
			_labels[i].text = RIPE_FORMAT % crop.ingredient.display_name
		else:
			_labels[i].text = GROWING_FORMAT % [crop.ingredient.display_name, GameState.get_plot_days_left(place_id, i)]
		_plants[i].set_state(crop, _growth(i, 0), is_ripe)


## 칸의 자란 정도 (0 = 막 심음, 1 = 다 자람). days_ago 일 전의 정도를 구할 수도 있다.
func _growth(plot_index: int, days_ago: int) -> float:
	var crop: Crop = GameState.get_plot_crop(place_id, plot_index)
	if crop == null or crop.grow_days <= 0:
		return 0.0
	var days_left: int = GameState.get_plot_days_left(place_id, plot_index) + days_ago
	return clampf(1.0 - float(days_left) / crop.grow_days, 0.0, 1.0)


## 그날 처음 이 밭에 오면, 하룻밤 사이 자란 칸들이 어제 크기에서 오늘 크기로 쑥 자란다.
func _grow_overnight() -> void:
	if GameState.growth_shown_day.get(place_id, 0) == GameState.current_day:
		return
	GameState.growth_shown_day[place_id] = GameState.current_day
	for i: int in _buttons.size():
		var crop: Crop = GameState.get_plot_crop(place_id, i)
		# 오늘 막 심은 칸(아직 하루도 안 지난 칸)은 자랄 게 없다.
		if crop != null and GameState.get_plot_days_left(place_id, i) < crop.grow_days:
			_plants[i].grow_from(_growth(i, 1))


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
	_plants[plot_index].wiggle()
	var growing_crop: Crop = GameState.get_plot_crop(place_id, plot_index)
	if growing_crop != null and not GameState.is_plot_ripe(place_id, plot_index):
		# 자라는 중: 부시럭 흔들리며 며칠 남았는지 알려 준다.
		Sound.play(RUSTLE_SOUND)
		FloatingText.pop(get_tree().current_scene, DAYS_LEFT_POP_FORMAT % GameState.get_plot_days_left(place_id, plot_index),
				_buttons[plot_index], pop_rise, pop_duration, pop_font_size, pop_color)
		return
	if GameState.is_plot_ripe(place_id, plot_index):
		var crop: Crop = GameState.harvest_plot(place_id, plot_index)
		Sound.play(HARVEST_SOUND)
		refresh()
		harvested.emit(crop, _buttons[plot_index])
	elif GameState.get_plot_crop(place_id, plot_index) == null and plant_picker != null:
		plant_picker.open(_place)
		var crop: Crop = await plant_picker.closed
		if crop != null and GameState.plant_plot(place_id, plot_index, crop):
			Sound.play(PLANT_SOUND)
			refresh()
			planted.emit(crop, _buttons[plot_index])
		else:
			_buttons[plot_index].grab_focus()
