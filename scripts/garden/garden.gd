extends Control
## 아침 당근 텃밭 장면. 다 자란 칸을 눌러 채소를 거두고, 빈 칸에 심을 작물을 고르고,
## 이웃이 두고 간 바구니를 열어 본 뒤 오늘의 메뉴를 골라 부엌으로 간다.
## 버섯 원목으로 가는 길도 여기서 간다. 장날(MarketSettings)에는 숲속 장터로 가는 버튼도 생긴다. 칸을 다루는 일은 PlotRow 가 맡는다.
## 물 주기나 비료 같은 복잡한 농사는 없다.

const DAY_TEXT_FORMAT: String = "%d일째 아침"
const PLANTED_FORMAT: String = "%s%s 심었어요. %d일 뒤에 거둘 수 있어요."
const HARVEST_POP_FORMAT: String = "+%d %s"
const GIFT_FORMAT: String = "%s%s %s %d개를 두고 갔어요."
const GIFT_READY_TEXT: String = "이웃 바구니\n(뭔가 들어 있어요)"
const GIFT_EMPTY_TEXT: String = "이웃 바구니\n(비었어요)"
const WELCOME_TEXT: String = "좋은 아침이에요. 텃밭을 둘러볼까요?"
const MARKET_DAY_TEXT: String = "오늘은 장날! 숲속 장터가 열렸어요."
## 이웃 바구니에서 재료를 꺼낼 때 나는 소리 (data/sounds/ 의 id)
const RECEIVE_SOUND: StringName = &"receive"

## 이 화면을 켤 때 게임이 아직 시작 전이면 새 게임을 시작한다 (시작 재료, 레시피, 텃밭을 받는다).
@export var start_new_game_on_ready: bool = true
## 텃밭을 다 둘러본 뒤 넘어갈 점심 부엌 장면
@export_file("*.tscn") var kitchen_scene_path: String = "res://scenes/kitchen/kitchen.tscn"
## 버섯 원목 장면
@export_file("*.tscn") var logs_scene_path: String = "res://scenes/garden/mushroom_logs.tscn"
## 숲속 장터 장면 (장날에만 갈 수 있다)
@export_file("*.tscn") var market_scene_path: String = "res://scenes/garden/market.tscn"
## 이웃이 바구니에 두고 가는 재료 개수
@export var gift_amount: int = 1
## 거둘 때 "+1 당근"이 떠오르는 높이(픽셀)와 시간(초)
@export var harvest_pop_rise: float = 90.0
@export var harvest_pop_duration: float = 0.8
@export var harvest_pop_font_size: int = 36
@export var harvest_pop_color: Color = Color(1, 0.84, 0.25)

@onready var _day_label: Label = %DayLabel
@onready var _plot_row: PlotRow = %PlotRow
@onready var _logs_button: Button = %LogsButton
@onready var _market_button: Button = %MarketButton
@onready var _basket_button: Button = %BasketButton
@onready var _kitchen_button: Button = %KitchenButton
@onready var _status_label: Label = %StatusLabel
@onready var _notebook: GuestNotebook = %GuestNotebook
@onready var _notebook_button: Button = %NotebookButton
@onready var _menu_board: MenuBoard = %MenuBoard


func _ready() -> void:
	if start_new_game_on_ready and not GameState.is_game_started:
		GameState.start_new_game()
	_day_label.text = DAY_TEXT_FORMAT % GameState.current_day
	_status_label.text = WELCOME_TEXT
	var setup: StartingSetup = GameData.get_starting_setup()
	if GameState.current_day == GameState.STARTING_DAY and setup != null and not setup.first_morning_text.is_empty():
		_status_label.text = setup.first_morning_text
	_market_button.visible = GameData.get_market_settings().is_market_day(GameState.current_day)
	if _market_button.visible:
		_status_label.text = WELCOME_TEXT + "\n" + MARKET_DAY_TEXT
	_market_button.pressed.connect(get_tree().change_scene_to_file.bind(market_scene_path))
	_basket_button.pressed.connect(_on_basket_button_pressed)
	_kitchen_button.pressed.connect(_on_kitchen_button_pressed)
	_notebook_button.pressed.connect(_notebook.open)
	_menu_board.confirmed.connect(_on_menu_confirmed)
	_logs_button.pressed.connect(get_tree().change_scene_to_file.bind(logs_scene_path))
	_plot_row.harvested.connect(_on_harvested)
	_plot_row.planted.connect(_on_planted)
	_update_basket()
	_focus_next_thing_to_do()


## 거두면 "+1 당근", 심으면 상태 글에 알려 준다.
func _on_harvested(crop: Crop, plot_button: Button) -> void:
	_pop_text(HARVEST_POP_FORMAT % [crop.harvest_amount, crop.ingredient.display_name], plot_button)
	_focus_next_thing_to_do()


func _on_planted(crop: Crop, _plot_button: Button) -> void:
	var crop_name: String = crop.ingredient.display_name
	_status_label.text = PLANTED_FORMAT % [crop_name, Korean.object_particle(crop_name), crop.grow_days]
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
	Sound.play(RECEIVE_SOUND)
	_status_label.text = GIFT_FORMAT % [neighbor.display_name, Korean.subject_particle(neighbor.display_name),
			gift.display_name, gift_amount]
	_pop_text(HARVEST_POP_FORMAT % [gift_amount, gift.display_name], _basket_button)
	_focus_next_thing_to_do()


func _update_basket() -> void:
	_basket_button.disabled = GameState.is_todays_gift_collected
	_basket_button.text = GIFT_EMPTY_TEXT if GameState.is_todays_gift_collected else GIFT_READY_TEXT


## 부엌으로 가기 전에 오늘의 메뉴부터 고른다.
func _on_kitchen_button_pressed() -> void:
	_menu_board.open()


func _on_menu_confirmed(recipe_ids: Array[StringName]) -> void:
	GameState.menu_recipe_ids = recipe_ids
	get_tree().change_scene_to_file(kitchen_scene_path)


## 아직 할 일(거둘 칸, 심을 수 있는 빈 칸, 안 연 바구니, 장날에 안 가 본 장터)이 있으면 그걸, 없으면 부엌으로 가기 버튼을 선택해 둔다.
## 그래야 게임패드 A 버튼만으로도 아침을 진행할 수 있다.
func _focus_next_thing_to_do() -> void:
	var plot_button: Button = _plot_row.get_next_action_button()
	if plot_button != null:
		plot_button.grab_focus()
		return
	if not _basket_button.disabled:
		_basket_button.grab_focus()
		return
	if _market_button.visible and not GameState.has_visited_market_today:
		_market_button.grab_focus()
		return
	_kitchen_button.grab_focus()


## 버튼 위로 글자가 떠오르며 사라진다. (예: "+1 당근")
func _pop_text(text: String, from: Control) -> void:
	FloatingText.pop(self, text, from, harvest_pop_rise, harvest_pop_duration, harvest_pop_font_size, harvest_pop_color)

