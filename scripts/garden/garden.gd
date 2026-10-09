extends Control
## 아침 당근 텃밭 장면. 다 자란 칸을 눌러 채소를 거두고, 빈 칸에 심을 작물을 고르고,
## 이웃이 두고 간 바구니를 열어 본 뒤 오늘의 메뉴를 골라 부엌으로 간다.
## 이웃 바구니에는 어젯밤 평상에 왔던 손님들이 한 명에 하나씩 밥값 재료를 두고 간다 (평상에 아무도 안 왔으면 비어 있다).
## 버섯 원목으로 가는 길도 여기서 간다. 장날(MarketSettings)에는 숲속 장터로 가는 버튼도 생긴다. 칸을 다루는 일은 PlotRow 가 맡는다.
## 물 주기나 비료 같은 복잡한 농사는 없다.

const DAY_TEXT_FORMAT: String = "%s %d일째 아침"
const PLANTED_FORMAT: String = "%s%s 심었어요. %d일 뒤에 거둘 수 있어요."
const HARVEST_POP_FORMAT: String = "+%d %s"
const GIFT_FORMAT: String = "%s%s %s %d개를 두고 갔어요."
const GIFT_LINE_SEPARATOR: String = "\n"
const GIFT_POP_SEPARATOR: String = "  "
const GIFT_READY_TEXT: String = "이웃 바구니\n(뭔가 들어 있어요)"
const GIFT_EMPTY_TEXT: String = "이웃 바구니\n(비었어요)"
const WELCOME_TEXT: String = "좋은 아침이에요. 텃밭을 둘러볼까요?"
const MARKET_DAY_TEXT: String = "오늘은 장날! 숲속 장터가 열렸어요."
const FEAST_BUTTON_FORMAT: String = "봄 잔치 바구니\n%d / %d"
## 버섯 원목으로 가는 버튼이 가리키는 밭 (잠겨 있으면 버튼을 숨긴다)
const LOGS_PLACE_ID: StringName = &"mushroom_logs"
## 이웃 바구니에서 재료를 꺼낼 때 나는 소리, 바구니를 건드릴 때 부시럭 소리 (data/sounds/ 의 id)
const RECEIVE_SOUND: StringName = &"receive"
const RUSTLE_SOUND: StringName = &"rustle"
## 아침 텃밭에 그날 처음 나왔을 때 한 번 나는 새소리 (비 오는 날은 안 난다)
const MORNING_SOUND: StringName = &"morning_birds"

## 날마다 바뀌는 배경음악 (하루 동안은 한 곡. 텃밭·원목·부엌·평상이 같은 곡이라 장면이 바뀌어도 끊기지 않는다).
## 비워 두면 지금 계절의 곡 목록(SeasonData.daily_music)을 쓴다. 장터와 계절 마무리는 따로 곡이 있다.
@export var daily_music: DailyMusic
## 이 화면을 켤 때 게임이 아직 시작 전이면 새 게임을 시작한다 (시작 재료, 레시피, 텃밭을 받는다).
@export var start_new_game_on_ready: bool = true
## 텃밭을 다 둘러본 뒤 넘어갈 점심 부엌 장면
@export_file("*.tscn") var kitchen_scene_path: String = "res://scenes/kitchen/kitchen.tscn"
## 버섯 원목 장면
@export_file("*.tscn") var logs_scene_path: String = "res://scenes/garden/mushroom_logs.tscn"
## 숲속 장터 장면 (장날에만 갈 수 있다)
@export_file("*.tscn") var market_scene_path: String = "res://scenes/garden/market.tscn"
## 목표판 (노트, 소문, 장날, 봄 잔치)과 놓을 자리 (손님 수첩 버튼 아래)
## 계절 목표 버튼 (누르면 목표판이 크게 뜬다)
@export var goal_board_scene: PackedScene = preload("res://scenes/ui/goal_button.tscn")
@export var goal_board_position: Vector2 = Vector2(48, 230)
## 이웃이 바구니에 두고 가는 재료 개수
@export var gift_amount: int = 1
## 거둘 때 "+1 당근"이 떠오르는 높이(픽셀)와 시간(초)
@export var harvest_pop_rise: float = 90.0
@export var harvest_pop_duration: float = 0.8
@export var harvest_pop_font_size: int = 36
@export var harvest_pop_color: Color = Color(1, 0.84, 0.25)

## 이웃 바구니 아이콘 그림 (원본 32×32, 배경 투명): 뭔가 들어 있을 때 / 비었을 때. 비워 두면 임시 도트 그림.
@export var basket_full_icon: Texture2D
@export var basket_empty_icon: Texture2D

@onready var _day_label: Label = %DayLabel
@onready var _sun: ColorRect = $Sun
@onready var _plot_row: PlotRow = %PlotRow
@onready var _logs_button: Button = %LogsButton
@onready var _market_button: Button = %MarketButton
@onready var _feast_button: Button = %FeastButton
@onready var _feast_prep_panel: FeastPrepPanel = %FeastPrepPanel
@onready var _basket_button: Button = %BasketButton
@onready var _kitchen_button: Button = %KitchenButton
@onready var _status_label: Label = %StatusLabel
@onready var _notebook: GuestNotebook = %GuestNotebook
@onready var _notebook_button: Button = %NotebookButton
@onready var _menu_board: MenuBoard = %MenuBoard
@onready var _basket_note: BasketNote = %BasketNote

## 아래 안내 글 (줄바꿈을 넣기 전 원래 글). 한 줄 더할 때 쓴다.
var _status_text: String = ""
## 새소리를 낸 아침 ("계절-날짜"). 장터나 버섯 원목에서 돌아와 텃밭이 다시 열릴 때는 새소리를 또 내지 않으려고 기억한다 (저장하지 않는다).
static var _birds_morning: String = ""


func _ready() -> void:
	var music: DailyMusic = daily_music if daily_music != null else GameData.get_daily_music()
	Sound.play_music(music.get_today_track(true) if music != null else null)
	if start_new_game_on_ready and not GameState.is_game_started:
		GameState.start_new_game()
	_day_label.text = DAY_TEXT_FORMAT % [GameData.get_season_name(), GameState.current_day]
	_set_status(WELCOME_TEXT)
	var setup: StartingSetup = GameData.get_starting_setup()
	# 게임 첫날(봄 1일째)에만. 여름 1일째에는 나오지 않는다.
	if GameState.current_day == GameState.STARTING_DAY and GameState.current_season == Season.Id.SPRING \
			and setup != null and not setup.first_morning_text.is_empty():
		_set_status(setup.first_morning_text)
	_update_logs_button()
	# 이웃 바구니에서 버섯이 나오면 텃밭에 있는 동안에도 바로 열린다.
	GameState.inventory_changed.connect(_update_logs_button.unbind(2))
	var morning_text: String = WELCOME_TEXT
	var rain: RainSettings = GameData.get_rain_settings()
	var morning_key: String = "%d-%d" % [GameState.current_season, GameState.current_day]
	if not GameState.is_raining_today and _birds_morning != morning_key:
		_birds_morning = morning_key
		Sound.play(MORNING_SOUND)
	if GameState.is_raining_today:
		# 비 오는 날은 해가 구름에 가려 안 보인다.
		_sun.hide()
		if not rain.morning_text.is_empty():
			morning_text = rain.morning_text
			_set_status(morning_text)
	_market_button.visible = GameData.get_market_settings().is_market_day(GameState.current_day)
	if _market_button.visible:
		_set_status(morning_text + "\n" + MARKET_DAY_TEXT)
	# 첫 봄 며칠은 안내 한 줄 (손님 수첩, 봄 목표 등). 두 번째 봄부터는 안 나온다.
	if setup != null and setup.morning_tips.has(GameState.current_day) and GameState.current_season == Season.Id.SPRING \
			and not GameState.is_spring_completed:
		_set_status(_status_text + "\n" + setup.morning_tips[GameState.current_day])
	_show_unlock_notice()
	_market_button.pressed.connect(get_tree().change_scene_to_file.bind(market_scene_path))
	_feast_button.pressed.connect(_on_feast_button_pressed)
	_feast_prep_panel.closed.connect(_focus_next_thing_to_do)
	_basket_note.closed.connect(_focus_next_thing_to_do)
	GameState.feast_prep_changed.connect(_update_feast_button)
	_update_feast_button()
	_basket_button.pressed.connect(_on_basket_button_pressed)
	# 바구니는 비어 있어도 누르면 부시럭 흔들린다 (막힌 버튼도 입력은 받는다).
	_basket_button.gui_input.connect(_on_basket_gui_input)
	_kitchen_button.pressed.connect(_on_kitchen_button_pressed)
	_notebook_button.pressed.connect(_notebook.open)
	_menu_board.confirmed.connect(_on_menu_confirmed)
	_logs_button.pressed.connect(get_tree().change_scene_to_file.bind(logs_scene_path))
	_plot_row.harvested.connect(_on_harvested)
	_plot_row.planted.connect(_on_planted)
	_update_basket()
	_add_goal_board()
	RainOverlay.apply_daytime(self, true)
	_focus_next_thing_to_do()
	TutorialDialog.show_once(self, &"garden")


func _add_goal_board() -> void:
	if goal_board_scene == null:
		return
	var board: Control = goal_board_scene.instantiate()
	board.position = goal_board_position
	add_child(board)
	# 손님 수첩과 메뉴판 같은 창보다 뒤에 그려지게, 창들보다 앞 순서에 둔다.
	move_child(board, _notebook.get_index())


## 거두면 "+1 당근", 심으면 상태 글에 알려 준다.
func _on_harvested(crop: Crop, plot_button: Button) -> void:
	_pop_text(HARVEST_POP_FORMAT % [crop.harvest_amount, crop.ingredient.display_name], plot_button)
	_focus_next_thing_to_do()


func _on_planted(crop: Crop, _plot_button: Button) -> void:
	var crop_name: String = crop.ingredient.display_name
	_set_status(PLANTED_FORMAT % [crop_name, Korean.object_particle(crop_name), crop.grow_days])
	_focus_next_thing_to_do()


## 이웃 바구니: 어젯밤 평상에 왔던 손님들이 자기 밥값 재료 하나와 쪽지를 두고 간다. 하루에 한 번.
## (며칠 안 열었으면 온 밤만큼 재료가 쌓여 있고, 쪽지는 손님마다 한 장)
func _on_basket_button_pressed() -> void:
	if GameState.basket_guest_ids.is_empty():
		return
	var lines: PackedStringArray = []
	var pops: PackedStringArray = []
	var notes: Array[String] = []
	var signatures: Array[String] = []
	# 바구니를 며칠 안 열면 같은 손님이 여러 번 쌓인다. 손님마다 한 줄로 합치고(온 밤만큼 재료), 쪽지는 한 장만.
	var visits: Dictionary[StringName, int] = {}
	for guest_id: StringName in GameState.basket_guest_ids:
		visits[guest_id] = visits.get(guest_id, 0) + 1
	for guest_id: StringName in visits:
		var neighbor: AnimalGuest = GameData.get_guest(guest_id)
		if neighbor == null or neighbor.payment_ingredients.is_empty():
			continue
		var gift: Ingredient = neighbor.payment_ingredients.pick_random()
		var amount: int = gift_amount * visits[guest_id]
		GameState.add_ingredient(gift.id, amount)
		lines.append(GIFT_FORMAT % [neighbor.display_name, Korean.subject_particle(neighbor.display_name),
				gift.display_name, amount])
		pops.append(HARVEST_POP_FORMAT % [amount, gift.display_name])
		var note: String = _pick_basket_note(neighbor, gift)
		if not note.is_empty():
			notes.append(note)
			signatures.append(neighbor.display_name)
	GameState.basket_guest_ids.clear()
	_update_basket()
	if lines.is_empty():
		return
	Sound.play(RECEIVE_SOUND)
	_set_status(GIFT_LINE_SEPARATOR.join(lines))
	_pop_text(GIFT_POP_SEPARATOR.join(pops), _basket_button)
	_show_unlock_notice()
	if notes.is_empty():
		_focus_next_thing_to_do()
	else:
		_basket_note.open(notes, signatures)


## 바구니 쪽지: 아직 쪽지로 남기지 않은 본 사연 막 쪽지가 있으면 그것(가장 최근 막), 없으면 평소 쪽지 중 오늘 차례인 것.
func _pick_basket_note(guest: AnimalGuest, gift: Ingredient) -> String:
	var text: String = ""
	for chapter: GuestStoryChapter in guest.story_chapters:
		if chapter != null and not chapter.basket_note.is_empty() and chapter.id in GameState.seen_story_chapter_ids \
				and chapter.id not in GameState.used_basket_note_ids:
			GameState.used_basket_note_ids.append(chapter.id)
			text = chapter.basket_note
	if text.is_empty() and not guest.basket_notes.is_empty():
		text = guest.basket_notes[GameState.current_day % guest.basket_notes.size()]
	return text.format({"name": GameState.player_name, "ingredient": gift.display_name})


## 잔치 준비 목록을 받았으면 (계절을 마치기 전까지) 봄 잔치 바구니 버튼을 보여 준다.
func _update_feast_button() -> void:
	var prep: FeastPrep = _get_feast_prep()
	_feast_button.visible = prep != null and GameState.is_feast_prep_announced
	if prep != null:
		_feast_button.text = FEAST_BUTTON_FORMAT % [GameState.get_feast_delivered_total(), prep.get_total()]


func _on_feast_button_pressed() -> void:
	GameState.has_opened_feast_prep_today = true
	_feast_prep_panel.open(_get_feast_prep())


func _get_feast_prep() -> FeastPrep:
	var ending: SeasonEnding = GameData.get_season_ending()
	return ending.feast_prep if ending != null else null


## 버섯 원목이 잠겨 있으면 가는 버튼을 숨긴다. 뭐가 있는지 미리 알 수 없게 해서, 열릴 때 반가운 발견이 되게.
func _update_logs_button() -> void:
	_logs_button.visible = GameState.is_place_unlocked(LOGS_PLACE_ID)


## 아래 안내 글을 바꾼다. 한글이 낱말 중간에서 잘리지 않게 띄어쓰기 자리에서 줄을 바꾼다.
func _set_status(text: String) -> void:
	_status_text = text
	var font: Font = _status_label.get_theme_font("font")
	var font_size: int = _status_label.get_theme_font_size("font_size")
	_status_label.text = Korean.wrap_by_spaces(text, font, font_size, _status_label.size.x)


## 방금 열린 밭이 있으면 아래 글에 한 줄 더해 알려 준다 (한 번만).
func _show_unlock_notice() -> void:
	for place_id: StringName in GameState.newly_unlocked_place_ids:
		var place: GardenPlace = GameData.get_garden_place(place_id)
		if place != null and not place.unlocked_text.is_empty():
			_set_status(_status_text + "\n" + place.unlocked_text)
	GameState.newly_unlocked_place_ids.clear()


func _on_basket_gui_input(event: InputEvent) -> void:
	var is_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if is_click or event.is_action_pressed("ui_accept"):
		Wiggle.shake(_basket_button)
		if _basket_button.disabled:
			Sound.play(RUSTLE_SOUND)


func _update_basket() -> void:
	var is_empty: bool = GameState.basket_guest_ids.is_empty()
	_basket_button.disabled = is_empty
	_basket_button.text = GIFT_EMPTY_TEXT if is_empty else GIFT_READY_TEXT
	_basket_button.icon = _basket_icon(not is_empty)


## 바구니 아이콘 (원본 32×32를 3배로). 그림이 있으면 그 그림, 없으면 BasketIcon 이 그린 임시 그림.
func _basket_icon(is_full: bool) -> ImageTexture:
	var texture: Texture2D = basket_full_icon if is_full else basket_empty_icon
	var image: Image = texture.get_image().duplicate() if texture != null else BasketIcon.draw(is_full)
	if image.is_compressed():
		image.decompress()
	image.resize(image.get_width() * 3, image.get_height() * 3, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


## 부엌으로 가기 전에 오늘의 메뉴부터 고른다.
func _on_kitchen_button_pressed() -> void:
	_menu_board.open()


func _on_menu_confirmed(recipe_ids: Array[StringName]) -> void:
	GameState.menu_recipe_ids = recipe_ids
	get_tree().change_scene_to_file(kitchen_scene_path)


## 아직 할 일(거둘 칸, 심을 수 있는 빈 칸, 안 연 바구니, 장날에 안 가 본 장터, 오늘 안 열어 본 잔치 바구니)이 있으면 그걸, 없으면 부엌으로 가기 버튼을 선택해 둔다.
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
	if _feast_button.visible and not GameState.has_opened_feast_prep_today:
		_feast_button.grab_focus()
		return
	_kitchen_button.grab_focus()


## 버튼 위로 글자가 떠오르며 사라진다. (예: "+1 당근")
func _pop_text(text: String, from: Control) -> void:
	FloatingText.pop(self, text, from, harvest_pop_rise, harvest_pop_duration, harvest_pop_font_size, harvest_pop_color)

