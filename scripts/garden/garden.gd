extends Control
## 아침 텃밭 장면. 다 자란 텃밭 칸을 눌러 채소를 거두고, 이웃이 두고 간 바구니를 열어 본 뒤 부엌으로 간다.
## 씨 뿌리기나 물 주기는 없다 (복잡한 농사는 MVP 범위 밖).

const DAY_TEXT_FORMAT: String = "%d일째 아침"
const RIPE_PLOT_FORMAT: String = "%s\n거두기"
const GROWING_PLOT_FORMAT: String = "%s\n%d일 뒤"
const HARVEST_POP_FORMAT: String = "+%d %s"
const GIFT_FORMAT: String = "%s%s %s %d개를 두고 갔어요."
const GIFT_READY_TEXT: String = "이웃 바구니\n(뭔가 들어 있어요)"
const GIFT_EMPTY_TEXT: String = "이웃 바구니\n(비었어요)"
const WELCOME_TEXT: String = "좋은 아침이에요. 텃밭을 둘러볼까요?"
const SAVED_NOTICE_TEXT: String = "어젯밤까지의 이야기를 저장했어요."

## 이 화면을 켤 때 게임이 아직 시작 전이면 새 게임을 시작한다 (시작 재료, 레시피, 텃밭을 받는다).
@export var start_new_game_on_ready: bool = true
## 텃밭을 다 둘러본 뒤 넘어갈 점심 부엌 장면
@export_file("*.tscn") var kitchen_scene_path: String = "res://scenes/kitchen/kitchen.tscn"
## 이웃이 바구니에 두고 가는 재료 개수
@export var gift_amount: int = 1
## 텃밭 칸 하나의 크기
@export var plot_size: Vector2 = Vector2(260, 240)
@export var plot_font_size: int = 36
## 거둘 때 "+1 당근"이 떠오르는 높이(픽셀)와 시간(초)
@export var harvest_pop_rise: float = 90.0
@export var harvest_pop_duration: float = 0.8
@export var harvest_pop_font_size: int = 36
@export var harvest_pop_color: Color = Color(1, 0.84, 0.25)

var _plot_buttons: Array[Button] = []

@onready var _day_label: Label = %DayLabel
@onready var _plot_row: HBoxContainer = %PlotRow
@onready var _basket_button: Button = %BasketButton
@onready var _kitchen_button: Button = %KitchenButton
@onready var _status_label: Label = %StatusLabel
@onready var _notebook: GuestNotebook = %GuestNotebook
@onready var _notebook_button: Button = %NotebookButton


func _ready() -> void:
	if start_new_game_on_ready and not GameState.is_game_started:
		GameState.start_new_game()
	_day_label.text = DAY_TEXT_FORMAT % GameState.current_day
	_status_label.text = WELCOME_TEXT
	if GameState.has_unshown_save_notice:
		_status_label.text = SAVED_NOTICE_TEXT + "\n" + WELCOME_TEXT
		GameState.has_unshown_save_notice = false
	_basket_button.pressed.connect(_on_basket_button_pressed)
	_kitchen_button.pressed.connect(_on_kitchen_button_pressed)
	_notebook_button.pressed.connect(_notebook.open)
	_build_plots()
	_update_basket()
	_focus_next_thing_to_do()


func _build_plots() -> void:
	var setup: StartingSetup = GameData.get_starting_setup()
	if setup == null:
		return
	for i: int in setup.garden_plots.size():
		var button: Button = Button.new()
		button.custom_minimum_size = plot_size
		button.add_theme_font_size_override("font_size", plot_font_size)
		button.pressed.connect(_on_plot_pressed.bind(i))
		_plot_row.add_child(button)
		_plot_buttons.append(button)
		_update_plot(i)


func _update_plot(plot_index: int) -> void:
	var crop: Crop = GameData.get_starting_setup().garden_plots[plot_index]
	var button: Button = _plot_buttons[plot_index]
	var crop_name: String = crop.ingredient.display_name
	if GameState.is_plot_ripe(plot_index):
		button.text = RIPE_PLOT_FORMAT % crop_name
		button.disabled = false
	else:
		button.text = GROWING_PLOT_FORMAT % [crop_name, GameState.garden_days_left[plot_index]]
		button.disabled = true


func _on_plot_pressed(plot_index: int) -> void:
	var crop: Crop = GameData.get_starting_setup().garden_plots[plot_index]
	if not GameState.harvest_plot(plot_index, crop):
		return
	_update_plot(plot_index)
	_pop_text(HARVEST_POP_FORMAT % [crop.harvest_amount, crop.ingredient.display_name],
			_plot_buttons[plot_index])
	_focus_next_thing_to_do()


## 이웃 바구니: 손님 중 한 명이 자기 밥값 재료 하나를 두고 간다. 하루에 한 번.
func _on_basket_button_pressed() -> void:
	if GameState.is_todays_gift_collected:
		return
	var neighbors: Array[AnimalGuest] = GameData.get_all_guests().filter(
			func(guest: AnimalGuest) -> bool: return not guest.payment_ingredients.is_empty())
	GameState.is_todays_gift_collected = true
	_update_basket()
	if neighbors.is_empty():
		return
	var neighbor: AnimalGuest = neighbors.pick_random()
	var gift: Ingredient = neighbor.payment_ingredients.pick_random()
	GameState.add_ingredient(gift.id, gift_amount)
	_status_label.text = GIFT_FORMAT % [neighbor.display_name, _subject_particle(neighbor.display_name),
			gift.display_name, gift_amount]
	_pop_text(HARVEST_POP_FORMAT % [gift_amount, gift.display_name], _basket_button)
	_focus_next_thing_to_do()


func _update_basket() -> void:
	_basket_button.disabled = GameState.is_todays_gift_collected
	_basket_button.text = GIFT_EMPTY_TEXT if GameState.is_todays_gift_collected else GIFT_READY_TEXT


func _on_kitchen_button_pressed() -> void:
	get_tree().change_scene_to_file(kitchen_scene_path)


## 아직 할 일(거둘 칸, 안 연 바구니)이 있으면 그걸, 없으면 부엌으로 가기 버튼을 선택해 둔다.
## 그래야 게임패드 A 버튼만으로도 아침을 진행할 수 있다.
func _focus_next_thing_to_do() -> void:
	for button: Button in _plot_buttons:
		if not button.disabled:
			button.grab_focus()
			return
	if not _basket_button.disabled:
		_basket_button.grab_focus()
		return
	_kitchen_button.grab_focus()


## 버튼 위로 글자가 떠오르며 사라진다. (예: "+1 당근")
func _pop_text(text: String, from: Control) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", harvest_pop_font_size)
	label.add_theme_color_override("font_color", harvest_pop_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	label.position = from.global_position - global_position + Vector2(from.size.x / 2.0 - label.size.x / 2.0, 0.0)
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - harvest_pop_rise, harvest_pop_duration)
	tween.tween_property(label, "modulate:a", 0.0, harvest_pop_duration)
	tween.chain().tween_callback(label.queue_free)


## 받침이 있으면 "이", 없으면 "가" (예: 암탉이, 토끼가)
func _subject_particle(word: String) -> String:
	if word.is_empty():
		return "가"
	var code: int = word.unicode_at(word.length() - 1)
	var is_hangul: bool = code >= 0xAC00 and code <= 0xD7A3
	return "이" if is_hangul and (code - 0xAC00) % 28 != 0 else "가"
