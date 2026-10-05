extends Control
## 부엌 화면. 점심 장사를 한다.
## 손님이 한 명씩 와서 주문하면 요리(미니게임)를 하고, 대접한 뒤 밥값으로 재료를 받는다.
## 오늘 올 손님은 아침에 정해져 있다 (GameState.get_todays_guest_ids, 메뉴판에 미리 보인다).
## 메뉴에 먹을 수 있는 요리가 없는 손님은 아쉬워하며 그냥 돌아간다 (호감도는 깎이지 않는다).
## 오늘 손님을 다 맞으면 점심 장사가 끝나고 저녁 평상으로 간다.
## 특별한 점심 날(SpecialLunch.PICNIC, 소풍 도시락 날)에는 주인 손님 한 명이 오늘 손님 모두의 도시락을 주문하고,
## 도시락마다 넣을 요리를 내가 골라 요리한다 (_start_picnic). 요리·대접·밥값 흐름은 평소와 같다.
## 손님 생일 날(SpecialLunch.BIRTHDAY)에는 생일 손님이 첫 손님으로 와서 생일 소원 요리를 부탁하고 (해 주면 덤 재료와 단골도),
## 다른 손님들은 주문 앞에 축하 한마디를 한다.
## "아무거나 맛있는 거" 날(SpecialLunch.CHEF_CHOICE)에는 손님마다 "알아서 해 주세요" 하고, 요리하기 대신 요리 고르기를 눌러
## 낼 요리를 내가 고른다 (_choose_chef_dish). 좋아하는 요리면 밥값 전부와 단골도 덤, 아니면 평소 대신 시킨 요리처럼.

const DAY_TEXT_FORMAT: String = "%s %d일째"
const LUNCH_PROGRESS_FORMAT: String = "점심 손님 %d / %d"
const PICNIC_PROGRESS_FORMAT: String = "소풍 도시락 %d / %d"
const PICNIC_PACK_BUTTON_TEXT: String = "도시락 싸기"
const PICNIC_HAND_OVER_TEXT: String = "도시락 건네기"
const PICNIC_DONE_TEXT: String = "도시락을 다 쌌어요! 오늘 점심 장사 끝."
const PICNIC_NAME_SEPARATOR: String = ", "
const COOKED_TEXT_FORMAT: String = "%s 완성!"
const PERFECT_COOKED_TEXT_FORMAT: String = "%s 완성! 한 번도 안 틀렸어요!"
const GRANDMA_COOKED_TEXT_FORMAT: String = "%s 완성! ♥ 할머니 손맛이 났어요!"
const GRANDMA_STAMP_TEXT: String = "♥ 레시피 노트에 할머니 손맛 도장!"
const TASTE_MATCH_POP_TEXT: String = "♥ 입맛 딱!"
const TIER_UP_FORMAT: String = "%s%s 더 가까워졌어요 · %s"
const REQUEST_JOIN: String = " "
const REQUEST_DONE_POP_TEXT: String = "♪ 부탁을 들어줬어요!"
const PROMISE_KEPT_POP_TEXT: String = "★ 약속을 지켰어요!"
const PROMISE_BONUS_FORMAT: String = "  약속 덤 +%d"
const BIRTHDAY_BONUS_FORMAT: String = " (생일 덤 +%d)"
const REQUEST_MISSED_LINE: String = "부탁한 대로는 아니지만… 그래도 맛있어요!"
const REQUEST_BONUS_FORMAT: String = " (부탁 +%d)"
const PAYMENT_PREFIX: String = "밥값으로 "
const PAYMENT_SUFFIX: String = " 받았어요"
const PAYMENT_ITEM_FORMAT: String = " %s ×%d"
const PAYMENT_ITEM_ICON_ONLY_FORMAT: String = " ×%d"
const PAYMENT_ITEM_SEPARATOR: String = ", "
const PERFECT_BONUS_FORMAT: String = " (완벽 +%d)"
const REGULAR_BONUS_FORMAT: String = " (%s 덤 +%d)"
const LUNCH_DONE_TEXT: String = "오늘 점심 장사 끝! 수고했어요."
## 입맛 힌트를 주문 뒤에 붙일 때 사이에 넣는 글, 고명 창에 다시 보여 줄 때의 모양
const TASTE_HINT_JOIN: String = " "
const TASTE_HINT_REMINDER_FORMAT: String = "%s: \"%s\""
## 호기심 주문 기본 문장 (손님 데이터의 curious_order_line 이 비어 있을 때)
const DEFAULT_CURIOUS_ORDER_LINE: String = "아까 그 냄새가 궁금했어요. {recipe} 주세요!"
## 먹을 게 없어서 돌아갈 때 기본 문장 (손님 데이터의 no_dish_line 이 비어 있을 때)
const DEFAULT_NO_DISH_LINE: String = "오늘은 먹을 게 없네요… 다음에 또 올게요."
## 효과음 이름 (data/sounds/ 의 id)
const GUEST_ARRIVE_SOUND: StringName = &"guest_arrive"
const SERVE_SOUND: StringName = &"serve"
## 대접할 때 접시가 조리대 위를 미끄러지는 소리
const SERVE_SLIDE_SOUND: StringName = &"dish_slide"
const RECEIVE_SOUND: StringName = &"receive"
const POP_SOUND: StringName = &"pop"
const TIER_UP_SOUND: StringName = &"tier_up"

## 날마다 바뀌는 배경음악 (하루 동안은 한 곡. 텃밭·원목·부엌·평상이 같은 곡이라 장면이 바뀌어도 끊기지 않는다).
## 비워 두면 지금 계절의 곡 목록(SeasonData.daily_music)을 쓴다. 장터와 계절 마무리는 따로 곡이 있다.
@export var daily_music: DailyMusic
## 이 화면을 켤 때 게임이 아직 시작 전이면 새 게임을 시작한다 (시작 재료와 레시피를 받는다).
## 타이틀 화면과 불러오기가 생기면 그쪽에서 새 게임을 시작하고 이 값은 끈다.
@export var start_new_game_on_ready: bool = true
## 점심 장사가 끝나면 넘어갈 저녁 평상 장면
@export_file("*.tscn") var porch_scene_path: String = "res://scenes/porch/porch.tscn"
## 가게 모습(간판, 등불, 평상, 기념품 선반). 부엌이 켜질 때 배경 바로 위에 붙인다.
@export var shop_decor_scene: PackedScene = preload("res://scenes/kitchen/shop_decor.tscn")
## 목표판 (노트, 소문, 장날, 봄 잔치)과 놓을 자리 (손님 수첩 버튼 아래). kitchen.tscn 을 고치지 않으려고 코드로 붙인다.
## 계절 목표 버튼 (누르면 목표판이 크게 뜬다)
@export var goal_board_scene: PackedScene = preload("res://scenes/ui/goal_button.tscn")
@export var goal_board_position: Vector2 = Vector2(48, 290)
## 점심 장사가 끝나고 저녁으로 넘어갈 때 보여 주는 해 지는 장면
@export var sunset_transition_scene: PackedScene = preload("res://scenes/ui/sunset_transition.tscn")
## 레시피 노트를 다 모은 다음 날, 평상 대신 넘어갈 봄 잔치 장면
@export_file("*.tscn") var feast_scene_path: String = "res://scenes/porch/spring_feast.tscn"
## 좋아하는 요리 대신 다른 요리를 주문한 손님은 첫 번째 밥값 재료를 이만큼만 낸다.
@export var fallback_payment_amount: int = 1
## 미니게임을 한 번도 안 틀리면 밥값 재료마다 이만큼 더 받는다.
@export var perfect_bonus_amount: int = 1
## 손님이 들어올 때: 문이 다 열리고 손님이 쏙 올라오기까지 기다리는 시간(초), 올라오기 시작하고 문이 닫히기까지 시간(초)
@export var guest_appear_delay: float = 0.35
@export var door_close_delay: float = 0.5
## 앞 손님이 나가고 문이 닫힌 뒤, 다음 손님이 문을 열기까지 쉬는 시간(초)
@export var next_guest_delay: float = 1.0
## 소풍 도시락 날 "○○ 도시락에 넣을 요리" 창
@export var lunchbox_picker_scene: PackedScene = preload("res://scenes/kitchen/lunchbox_picker.tscn")
## 대접할 때 접시가 조리대 위를 드윽 미끄러져 손님 앞으로 가는 시간(초)과, 내 쪽(화면 아래)에서 출발하는 거리(픽셀), 처음 크기
@export var serve_slide_duration: float = 0.5
@export var serve_slide_distance: float = 360.0
@export var serve_slide_start_scale: float = 1.35
## 밥값 문구에서 재료 아이콘 크기(픽셀). 픽셀 글꼴에 맞춰 12의 배수로.
@export var payment_icon_size: int = 48
## true: "아이콘 당근 ×2", false: "아이콘 ×2". 재료 그림이 다 생기면 false로 바꿔도 된다.
@export var show_ingredient_names_with_icons: bool = true
## 완벽하게 요리했을 때 아래 안내 글자 색
@export var perfect_text_color: Color = Color(1, 0.84, 0.25)
## 처음 할머니 손맛을 냈을 때 손님 위로 떠오르는 도장 글의 높이(픽셀), 시간(초), 글자 크기
@export var stamp_pop_rise: float = 140.0
@export var stamp_pop_duration: float = 2.4
@export var stamp_pop_font_size: int = 48
## 떠오르는 글이 여러 개일 때 하나씩 띄우는 간격(초)
@export var pop_interval: float = 0.9

## 지금 와 있는 손님과 그 손님의 주문. 손님이 없으면 null.
var current_guest: AnimalGuest
var current_order: Recipe
## 지금 주문이 좋아하는 요리 대신 고른 요리인지
var _is_fallback_order: bool = false
## 지금 손님이 어젯밤 약속한 요리를 주문했는지 (단골의 약속 주문)
var _is_promise_order: bool = false
## 지금 손님의 오늘의 부탁 (없으면 null), 부탁을 미니게임 단계에 이미 걸었는지, 부탁을 들어줬는지
var current_request: GuestRequest
var _is_request_assigned: bool = false
var _is_request_met: bool = false

## 오늘 점심 장사 기록 (장사가 끝나면 장사 결과판에 보여 준다)
var _report: LunchReport = LunchReport.new()
## 오늘 점심에 맞은 손님 수 (먹을 게 없어 돌아간 손님도 센다)와 오늘 올 손님 (오는 차례대로)
var _guests_served: int = 0
var _todays_guests: Array[AnimalGuest] = []
## 오늘 주문받은 요리 id → 횟수. 손님이 오늘 덜 나간 요리를 먼저 시키게 할 때 쓴다 (같은 요리만 반복되지 않게).
var _orders_today: Dictionary[StringName, int] = {}
var _guests_today: int = 0
## 오늘의 특별한 점심 (없으면 null), 소풍 도시락 날 주문하러 온 손님, 지금 요리가 도시락인지, 싼 도시락 요리 id
var _special: SpecialLunch
var _picnic_host: AnimalGuest
var _is_picnic: bool = false
var _picnic_dishes: Array[StringName] = []
## 손님 생일 날의 생일 손님 (아니면 null)과, 지금 주문이 생일 소원 요리인지
var _birthday_host: AnimalGuest
var _is_birthday_order: bool = false
## "아무거나 맛있는 거" 날인지, 지금 손님 요리를 아직 고르기 전인지, 고른 요리가 그 손님이 좋아하는 요리인지
var _is_chef_day: bool = false
var _is_choosing_dish: bool = false
var _is_chef_hit: bool = false
var _cook_text: String = ""
var _next_guest_text: String = ""
var _lunchbox_picker: LunchboxPicker
## 요리 중에 아직 남은 미니게임 단계
var _remaining_steps: Array[CookStep] = []
## 이번 요리의 미니게임을 지금까지 전부 한 번도 안 틀렸는지
var _is_perfect_cook: bool = true
## 이번 요리에서 할머니 비법이 있는 단계 수와, 그중 비법대로 해낸 단계 수
var _secret_step_count: int = 0
var _grandma_step_count: int = 0
## 안내 글자의 원래 색 (완벽 색에서 되돌릴 때 쓴다)
var _status_default_color: Color

@onready var _day_label: Label = %DayLabel
@onready var _lunch_label: Label = %LunchLabel
@onready var _guest_spot: GuestSpot = %GuestSpot
## 손님이 드나드는 가게 문 (없으면 손님이 바로 나타난다)
@onready var _door: KitchenDoor = get_node_or_null("%KitchenDoor")
@onready var _cook_button: Button = %CookButton
@onready var _serve_button: Button = %ServeButton
@onready var _next_guest_button: Button = %NextGuestButton
@onready var _evening_button: Button = %EveningButton
@onready var _cook_status_label: RichTextLabel = %CookStatusLabel
@onready var _notebook: GuestNotebook = %GuestNotebook
@onready var _notebook_button: Button = %NotebookButton
## 계절 목표 버튼 (부엌이 켜질 때 붙인다)
var _goal_button: GoalButton
@onready var _garnish_picker: GarnishPicker = %GarnishPicker
@onready var _result_board: ResultBoard = %ResultBoard
## 요리 완성 장면 ("완성~!")과 대접한 접시 (손님 앞 조리대 위)
@onready var _dish_showcase: DishShowcase = %DishShowcase
@onready var _served_dish: TextureRect = %ServedDish
@onready var _chop_minigame: ChopMinigame = %ChopMinigame
@onready var _stir_fry_minigame: StirFryMinigame = %StirFryMinigame
@onready var _pan_fry_minigame: PanFryMinigame = %PanFryMinigame
@onready var _roll_minigame: RollMinigame = %RollMinigame
@onready var _rice_minigame: RiceMinigame = %RiceMinigame
@onready var _mix_minigame: MixMinigame = %MixMinigame
@onready var _simmer_minigame: SimmerMinigame = %SimmerMinigame
@onready var _mince_minigame: MinceMinigame = %MinceMinigame
## 레시피의 미니게임 종류마다 실제로 실행할 미니게임
@onready var _minigames: Dictionary[Recipe.MinigameType, Minigame] = {
	Recipe.MinigameType.CHOP: _chop_minigame,
	Recipe.MinigameType.STIR_FRY: _stir_fry_minigame,
	Recipe.MinigameType.PAN_FRY: _pan_fry_minigame,
	Recipe.MinigameType.ROLL: _roll_minigame,
	Recipe.MinigameType.COOK_RICE: _rice_minigame,
	Recipe.MinigameType.MIX: _mix_minigame,
	Recipe.MinigameType.SIMMER: _simmer_minigame,
	Recipe.MinigameType.MINCE: _mince_minigame,
}
@onready var _buttons: Array[Button] = [_cook_button, _serve_button, _next_guest_button, _evening_button]


func _ready() -> void:
	var music: DailyMusic = daily_music if daily_music != null else GameData.get_daily_music()
	Sound.play_music(music.get_today_track(true) if music != null else null)
	GameState.day_changed.connect(_on_day_changed)
	_cook_button.pressed.connect(_on_cook_button_pressed)
	_serve_button.pressed.connect(_on_serve_button_pressed)
	_next_guest_button.pressed.connect(_on_next_guest_button_pressed)
	_evening_button.pressed.connect(_on_evening_button_pressed)
	_notebook_button.pressed.connect(_notebook.open)
	for minigame: Minigame in _minigames.values():
		minigame.finished.connect(_on_minigame_finished)
	_status_default_color = _cook_status_label.get_theme_color("default_color")
	_add_shop_decor()
	_add_goal_board()
	_lunchbox_picker = lunchbox_picker_scene.instantiate()
	add_child(_lunchbox_picker)
	_next_guest_text = _next_guest_button.text
	_cook_text = _cook_button.text
	RainOverlay.apply_daytime(self, false)
	if start_new_game_on_ready and not GameState.is_game_started:
		GameState.start_new_game()
	_on_day_changed(GameState.current_day)
	_start_lunch()


## 가게 모습을 배경과 조리대 바로 위(손님과 버튼 아래)에 붙인다.
func _add_goal_board() -> void:
	if goal_board_scene == null:
		return
	var board: Control = goal_board_scene.instantiate()
	board.position = goal_board_position
	add_child(board)
	_goal_button = board as GoalButton
	# 미니게임과 창들보다 뒤에 그려지게, 첫 미니게임보다 앞 순서에 둔다. 손님 수첩 버튼도 같이.
	move_child(board, get_node("%ChopMinigame").get_index())
	move_child(_notebook_button, get_node("%ChopMinigame").get_index())


## 손님 수첩과 계절 목표 버튼을 누를 수 있게 / 없게 (요리 미니게임과 완성 장면 동안은 막는다)
func _set_side_buttons_enabled(enabled: bool) -> void:
	_notebook_button.disabled = not enabled
	_notebook_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if _goal_button != null:
		_goal_button.set_enabled(enabled)


func _add_shop_decor() -> void:
	if shop_decor_scene == null:
		return
	var decor: Node = shop_decor_scene.instantiate()
	add_child(decor)
	move_child(decor, $Counter.get_index() + 1)


# --- 점심 장사 흐름 ---

func _start_lunch() -> void:
	_report = LunchReport.new()
	_guests_served = 0
	_orders_today.clear()
	_todays_guests.clear()
	for guest_id: StringName in GameState.get_todays_guest_ids():
		var guest: AnimalGuest = GameData.get_guest(guest_id)
		if guest != null:
			_todays_guests.append(guest)
	_guests_today = _todays_guests.size()
	_take_promise()
	_special = GameData.get_special_lunch(GameState.current_day)
	_picnic_host = GameData.get_guest(_special.host_id) if _special != null else null
	# 특별한 점심 날의 주인 손님은 늘 첫 손님이다 (이 기능이 생기기 전에 정해 둔 오늘 손님이면 맨 앞에 넣고 맨 뒤를 뺀다).
	if _picnic_host != null and _picnic_host not in _todays_guests:
		_todays_guests.push_front(_picnic_host)
		if _todays_guests.size() > maxi(_guests_today, 1):
			_todays_guests.pop_back()
		_guests_today = _todays_guests.size()
	_is_picnic = _special != null and _special.kind == SpecialLunch.Kind.PICNIC and _picnic_host != null \
			and not _todays_guests.is_empty()
	_picnic_dishes.clear()
	_birthday_host = _picnic_host if _special != null and _special.kind == SpecialLunch.Kind.BIRTHDAY else null
	_is_birthday_order = false
	_is_chef_day = _special != null and _special.kind == SpecialLunch.Kind.CHEF_CHOICE
	_is_choosing_dish = false
	if _is_picnic:
		_update_lunch_label()
		_start_picnic()
		return
	_update_lunch_label()
	_call_next_guest()


## 오늘 손님 차례에서 다음 손님을 부른다. 메뉴에 먹을 수 있는 요리가 없으면 아쉬워하며 돌아간다.
func _call_next_guest() -> void:
	_show_only_button(null)
	_set_status("", false)
	# 앞 손님은 문으로 나간다. 문이 닫히고 조금 쉬었다가 다음 손님이 온다.
	if current_guest != null and _guest_spot.visible:
		await _guest_leaves()
		if _guests_served < _guests_today:
			await get_tree().create_timer(next_guest_delay, false).timeout
	_guest_spot.clear()
	current_guest = null
	current_order = null
	current_request = null
	if _guests_served >= _guests_today:
		_end_lunch(LUNCH_DONE_TEXT)
		return
	# 어젯밤 약속한 손님은 오늘 손님 차례 맨 앞에 있다 (GameState._choose_todays_guests).
	var promised_guest: AnimalGuest = _promised_guest
	var promised_recipe: Recipe = _promised_recipe
	_is_promise_order = false
	var guest: AnimalGuest = _todays_guests[_guests_served]
	var order: Recipe = _choose_order(guest)
	_is_fallback_order = order == null
	if _is_fallback_order:
		order = _choose_fallback_order(guest)
	# 봄비 오는 날에는 따뜻한 요리를 먼저 찾는다. 밥값은 좋아하는 요리와 똑같이 받는다.
	var warm_order: Recipe = _choose_warm_order(guest)
	if warm_order != null:
		order = warm_order
		_is_fallback_order = false
	var curious_order: Recipe = _choose_curious_order(guest, order) \
			if not _is_fallback_order and warm_order == null else null
	if curious_order != null:
		order = curious_order
	if order != null:
		current_guest = guest
		current_order = order
		_orders_today[order.id] = _orders_today.get(order.id, 0) + 1
		var order_text: String = guest.order_line.format({"recipe": order.display_name})
		# 주문할 때 표정: 좋아하는 걸 못 시키면 시무룩, 궁금한 요리는 놀람, 처음 만나면 반가움(웃음)
		var order_expression: StringName = AnimalGuest.EXPRESSION_DEFAULT
		if _is_fallback_order:
			order_text = guest.fallback_order_line.format({"recipe": order.display_name})
			order_expression = AnimalGuest.EXPRESSION_SAD
		elif warm_order != null and not guest.rain_order_line.is_empty():
			order_text = guest.rain_order_line.format({"recipe": order.display_name})
		elif curious_order != null:
			var curious_line: String = guest.curious_order_line if not guest.curious_order_line.is_empty() \
					else DEFAULT_CURIOUS_ORDER_LINE
			order_text = curious_line.format({"recipe": order.display_name})
			order_expression = AnimalGuest.EXPRESSION_SURPRISED
		# 처음 온 손님은 할머니 밥집 단골이었다는 인사와 함께 주문한다.
		if not GameState.has_met_guest(guest.id) and not guest.first_order_line.is_empty():
			order_text = guest.first_order_line.format({"recipe": order.display_name})
			order_expression = AnimalGuest.EXPRESSION_HAPPY
		# 약속한 손님: 약속한 요리를 낼 수 있으면 그걸, 없으면 아쉬운 말 한마디 뒤 평소처럼 주문한다.
		if guest == promised_guest and promised_recipe != null:
			var values: Dictionary = {"recipe": promised_recipe.display_name, "name": GameState.player_name}
			if _can_cook(promised_recipe):
				_orders_today[order.id] = _orders_today.get(order.id, 1) - 1
				order = promised_recipe
				current_order = order
				_orders_today[order.id] = _orders_today.get(order.id, 0) + 1
				_is_fallback_order = false
				_is_promise_order = true
				order_text = guest.promise_order_line.format(values)
				order_expression = AnimalGuest.EXPRESSION_HAPPY
			else:
				order_text = guest.promise_missed_line.format(values) + " " + order_text
				order_expression = AnimalGuest.EXPRESSION_SAD
		# 생일 손님: 생일 소원 요리를 낼 수 있으면 그걸, 없으면 아쉬운 말 한마디 뒤 평소처럼 주문한다.
		_is_birthday_order = false
		if _birthday_host != null and guest == _birthday_host:
			var wish: Recipe = _special.get_wish_recipe()
			if wish != null and _can_cook(wish):
				_orders_today[order.id] = _orders_today.get(order.id, 1) - 1
				order = wish
				current_order = order
				_orders_today[order.id] = _orders_today.get(order.id, 0) + 1
				_is_fallback_order = false
				_is_birthday_order = true
				order_text = _special.fill(_special.intro_line)
				order_expression = AnimalGuest.EXPRESSION_HAPPY
			else:
				order_text = _special.fill(_special.wish_missed_line) + " " + order_text
				order_expression = AnimalGuest.EXPRESSION_SAD
		elif _birthday_host != null and _special.guest_lines.has(guest.id):
			order_text = _special.fill(_special.guest_lines[guest.id]) + " " + order_text
		if _taste_hint(guest) != "":
			order_text += TASTE_HINT_JOIN + _taste_hint(guest)
		# 약속 주문과 생일 소원에는 오늘의 부탁을 덧붙이지 않는다.
		current_request = _choose_request(guest, order) if not _is_promise_order and not _is_birthday_order else null
		if current_request != null:
			order_text += REQUEST_JOIN + current_request.get_line(guest)
		# "아무거나 맛있는 거" 날: 주문 대신 "알아서 해 주세요". 요리는 요리 고르기에서 내가 고른다.
		if _is_chef_day:
			current_request = null
			_is_promise_order = false
			order_text = _special.fill(_special.guest_lines.get(guest.id, _special.default_request_line))
			order_expression = AnimalGuest.EXPRESSION_HAPPY
			_is_choosing_dish = true
			_cook_button.text = _special.choose_button_text
		_guest_spot.show_guest(guest, order_text, GameState.is_raining_today, order_expression)
		await _guest_enters()
		_show_only_button(_cook_button)
		return
	await _send_guest_home(guest, promised_recipe if guest == promised_guest else null)


## 메뉴에 먹을 수 있는 요리가 없는 손님: 아쉬운 말을 하고 다음 손님 버튼을 띄운다. 호감도와 소문은 그대로 (깎지 않는다).
## 약속한 손님이면 약속한 요리가 없다는 말을 앞에 붙인다.
func _send_guest_home(guest: AnimalGuest, promised_recipe: Recipe) -> void:
	var line: String = guest.no_dish_line if not guest.no_dish_line.is_empty() else DEFAULT_NO_DISH_LINE
	if promised_recipe != null:
		var values: Dictionary = {"recipe": promised_recipe.display_name, "name": GameState.player_name}
		line = guest.promise_missed_line.format(values) + " " + line
	current_guest = guest
	# 얼굴을 봤으니 이름은 안다 (수첩과 메뉴판에 이름만). 수첩 기록은 대접해야 적힌다.
	GameState.see_guest(guest.id)
	_guest_spot.show_guest(guest, line, GameState.is_raining_today, AnimalGuest.EXPRESSION_SAD)
	await _guest_enters()
	_guests_served += 1
	_update_lunch_label()
	_show_only_button(_next_guest_button)


## 완성한 요리 접시가 내 쪽(화면 아래)에서 조리대 위를 드윽 미끄러져 손님 앞에 놓인다.
func _slide_dish_to_guest() -> void:
	var home: Vector2 = _served_dish.position
	if _served_dish.has_meta(&"home"):
		home = _served_dish.get_meta(&"home")
	else:
		_served_dish.set_meta(&"home", home)
	_served_dish.texture = DishArt.get_texture(current_order)
	_served_dish.pivot_offset = _served_dish.size / 2.0
	_served_dish.position = home + Vector2(0.0, serve_slide_distance)
	_served_dish.scale = Vector2.ONE * serve_slide_start_scale
	_served_dish.show()
	Sound.play(SERVE_SLIDE_SOUND)
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_served_dish, "position", home, serve_slide_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(_served_dish, "scale", Vector2.ONE, serve_slide_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tween.finished


## 문이 열리고 잠깐 뒤, 손님이 조리대 아래에서 쏙 올라오고 문이 닫힌다. (문 장면이 없으면 바로 나타난다)
func _guest_enters() -> void:
	if _door == null:
		Sound.play(GUEST_ARRIVE_SOUND)
		return
	# show_guest 가 손님을 보이게 해 두므로, 문이 열리는 동안은 숨겨 둔다.
	_guest_spot.hide()
	await _door.open()
	await get_tree().create_timer(guest_appear_delay, false).timeout
	_close_door_after(door_close_delay)
	await _guest_spot.pop_up()


func _close_door_after(delay: float) -> void:
	# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
	await get_tree().create_timer(delay, false).timeout
	_door.close()


## 문이 열리고, 손님이 스르륵 사라진 뒤 문이 닫힌다.
func _guest_leaves() -> void:
	_served_dish.hide()
	if _door == null:
		return
	await _door.open()
	await _guest_spot.fade_out()
	await _door.close()


## 가끔(request_chance) 이 요리에 나올 수 있는 오늘의 부탁 하나를 고른다. request_start_day 전에는 부탁하지 않는다. 없으면 null.
## 고명 부탁은 손님 입맛(좋아하는 고명)과 같은 것만 한다 (꿀을 좋아하는 곰이 "고소하게"를 부탁하지 않게).
func _choose_request(guest: AnimalGuest, order: Recipe) -> GuestRequest:
	var settings: RegularSettings = GameData.get_regular_settings()
	if GameState.current_day < settings.request_start_day or randf() >= settings.request_chance:
		return null
	var possible: Array[GuestRequest] = GameData.get_all_requests().filter(
			func(request: GuestRequest) -> bool:
				return request.applies_to(order) and (not request.is_garnish_request()
						or guest.favorite_garnish == null or request.garnish == guest.favorite_garnish))
	return possible.pick_random() if not possible.is_empty() else null


## 오늘 약속한 손님과 요리 (없으면 null). 약속은 점심을 시작할 때 끝낸다 (지키든 못 지키든).
## 약속한 손님은 오늘 손님 차례 맨 앞에 이미 들어 있다.
var _promised_guest: AnimalGuest
var _promised_recipe: Recipe


func _take_promise() -> void:
	_promised_guest = null
	_promised_recipe = null
	if not GameState.has_promise_on(GameState.current_day):
		return
	_promised_guest = GameData.get_guest(GameState.promise_guest_id)
	_promised_recipe = GameData.get_recipe(GameState.promise_recipe_id)
	GameState.clear_promise()


## 손님이 좋아하는 요리 중, 지금 낼 수 있는(_can_cook) 것 하나. 없으면 null.
## 그중에서도 오늘 덜 나간 요리를 먼저 고른다. 모두가 좋아하는 요리(김밥)만 하루 종일 나오지 않게.
func _choose_order(guest: AnimalGuest) -> Recipe:
	var possible: Array[Recipe] = guest.favorite_recipes.filter(_can_cook)
	if possible.is_empty():
		return null
	var fewest: int = possible.map(func(recipe: Recipe) -> int: return _orders_today.get(recipe.id, 0)).min()
	return possible.filter(func(recipe: Recipe) -> bool: return _orders_today.get(recipe.id, 0) == fewest).pick_random()


## 좋아하는 요리를 못 낼 때 대신 주문할 요리: 지금 낼 수 있고 싫어하지 않는 아무 요리 하나. 없으면 null.
## 입맛 힌트: 손님의 입맛(고명)을 아직 모를 때만 준다. 알게 되면 빈 글.
func _taste_hint(guest: AnimalGuest) -> String:
	if guest == null or guest.favorite_garnish == null or GameState.knows_taste(guest.id):
		return ""
	return guest.taste_hint_line


## 호기심 주문: 손님이 시키려던 요리가 오늘 이미 나갔고, 메뉴에 오늘 아직 아무도 안 시킨 요리가 있으면 그걸 시킨다.
## (싫어하는 요리는 빼고). 밥값은 좋아하는 요리와 똑같이 받는다. 해당하지 않으면 null.
func _choose_curious_order(guest: AnimalGuest, planned: Recipe) -> Recipe:
	if planned == null or _orders_today.get(planned.id, 0) == 0:
		return null
	var untried: Array[Recipe] = GameData.get_all_recipes().filter(
			func(recipe: Recipe) -> bool:
				return _can_cook(recipe) and recipe not in guest.disliked_recipes \
						and _orders_today.get(recipe.id, 0) == 0)
	return untried.pick_random() if not untried.is_empty() else null


## 봄비 오는 날, warm_order_chance 확률로 따뜻한 요리 중 지금 낼 수 있고 싫어하지 않는 것 하나 (오늘 덜 나간 요리 먼저).
## 비가 안 오거나 해당하는 요리가 없으면 null.
func _choose_warm_order(guest: AnimalGuest) -> Recipe:
	var rain: RainSettings = GameData.get_rain_settings()
	if not GameState.is_raining_today or randf() >= rain.warm_order_chance:
		return null
	var possible: Array[Recipe] = rain.warm_recipes.filter(
			func(recipe: Recipe) -> bool: return recipe != null and _can_cook(recipe) and recipe not in guest.disliked_recipes)
	if possible.is_empty():
		return null
	var fewest: int = possible.map(func(recipe: Recipe) -> int: return _orders_today.get(recipe.id, 0)).min()
	return possible.filter(func(recipe: Recipe) -> bool: return _orders_today.get(recipe.id, 0) == fewest).pick_random()


func _choose_fallback_order(guest: AnimalGuest) -> Recipe:
	var possible: Array[Recipe] = GameData.get_all_recipes().filter(
			func(recipe: Recipe) -> bool: return _can_cook(recipe) and recipe not in guest.disliked_recipes)
	return possible.pick_random() if not possible.is_empty() else null


## 레시피 노트로 되찾았고, 오늘의 메뉴에 있고, 지금 재료로 만들 수 있는지
func _can_cook(recipe: Recipe) -> bool:
	return GameState.is_recipe_unlocked(recipe.id) and GameState.is_on_menu(recipe.id) \
			and GameState.has_ingredients(recipe.get_ingredient_counts())


func _end_lunch(message: String) -> void:
	_guest_spot.clear()
	_set_status(message, false)
	_show_only_button(_evening_button)


func _on_next_guest_button_pressed() -> void:
	if _is_picnic:
		_pack_next_lunchbox()
	else:
		_call_next_guest()


## 장사 결과판을 보여 준 뒤 저녁으로 간다.
func _on_evening_button_pressed() -> void:
	_show_only_button(null)
	_result_board.open(_report)
	await _result_board.continued
	if sunset_transition_scene != null:
		var sunset: SunsetTransition = sunset_transition_scene.instantiate()
		add_child(sunset)
		var sunset_text: String = ""
		if GameState.is_raining_today:
			# 해 질 녘에 비가 그친다.
			var rain: RainSettings = GameData.get_rain_settings()
			Sound.stop_loop(rain.rain_sound, rain.rain_sound_fade)
			sunset_text = rain.sunset_text
		await sunset.play(GameState.current_day, sunset_text)
	get_tree().change_scene_to_file(feast_scene_path if GameState.is_season_end_day() else porch_scene_path)


# --- 소풍 도시락 날 ---

## 주인 손님이 들어와서 오늘 손님 모두의 도시락을 주문한다.
func _start_picnic() -> void:
	# 주인 손님이 들어오는 동안 평소 버튼(요리하기 등)이 눌리지 않게 모두 숨긴다.
	_show_only_button(null)
	var others: PackedStringArray = []
	for guest: AnimalGuest in _todays_guests:
		if guest != _picnic_host:
			others.append(guest.display_name)
	current_guest = _picnic_host
	current_order = null
	_guest_spot.show_guest(_picnic_host, _picnic_text(_special.intro_line, _picnic_host,
			{"names": PICNIC_NAME_SEPARATOR.join(others), "count": _guests_today}),
			GameState.is_raining_today, AnimalGuest.EXPRESSION_HAPPY)
	await _guest_enters()
	_next_guest_button.text = PICNIC_PACK_BUTTON_TEXT
	_show_only_button(_next_guest_button)


## 다음 도시락: 넣을 요리를 고르고 (수첩을 보고 와도 된다) 바로 요리를 시작한다. 다 쌌으면 마무리.
func _pack_next_lunchbox() -> void:
	_show_only_button(null)
	_set_status("", false)
	_served_dish.hide()
	if _guests_served >= _guests_today:
		_finish_picnic()
		return
	var guest: AnimalGuest = _todays_guests[_guests_served]
	var recipes: Array[Recipe] = GameData.get_all_recipes().filter(
			func(recipe: Recipe) -> bool: return GameState.is_recipe_unlocked(recipe.id) and GameState.is_on_menu(recipe.id))
	if not recipes.any(func(recipe: Recipe) -> bool: return GameState.has_ingredients(recipe.get_ingredient_counts())):
		# 재료가 모자라 이 손님 도시락은 못 싼다 (벌점 없음).
		_guest_spot.say(_picnic_text(_special.skipped_line, guest), AnimalGuest.EXPRESSION_SAD)
		_guests_served += 1
		_update_lunch_label()
		if _guests_served >= _guests_today:
			_next_guest_button.text = PICNIC_HAND_OVER_TEXT
		_show_only_button(_next_guest_button)
		return
	var packed: Array[String] = []
	for recipe_id: StringName in _picnic_dishes:
		packed.append(GameData.get_recipe(recipe_id).display_name)
	var recipe: Recipe = null
	while recipe == null:
		_lunchbox_picker.open(_picnic_text(_special.choose_title_format, guest), guest, recipes, packed,
				_special.notebook_button_text)
		recipe = await _lunchbox_picker.closed
		if recipe == null:
			# 손님 수첩을 보고 오면 다시 고른다.
			_notebook.open()
			while _notebook.visible:
				await _notebook.visibility_changed
	current_guest = guest
	current_order = recipe
	current_request = null
	_is_promise_order = false
	_is_fallback_order = recipe not in guest.favorite_recipes
	_orders_today[recipe.id] = _orders_today.get(recipe.id, 0) + 1
	_picnic_dishes.append(recipe.id)
	_on_cook_button_pressed()


## 도시락을 다 쌌다: 주인 손님의 마지막 말. 모두 다른 요리로 쌌으면 덤 소문.
func _finish_picnic() -> void:
	current_guest = _picnic_host
	var line: String = _picnic_text(_special.done_line, _picnic_host)
	var unique: Dictionary = {}
	for recipe_id: StringName in _picnic_dishes:
		unique[recipe_id] = true
	if _picnic_dishes.size() >= 2 and unique.size() == _picnic_dishes.size():
		line += " " + _picnic_text(_special.variety_line, _picnic_host)
		_report.reputation += _special.variety_reputation
		_pop_one_by_one([_special.variety_pop_text], [POP_SOUND])
	_guest_spot.say(line, AnimalGuest.EXPRESSION_HAPPY)
	_next_guest_button.text = _next_guest_text
	_set_status(PICNIC_DONE_TEXT, false)
	_show_only_button(_evening_button)


## 도시락 하나를 다 쌌을 때 주인 손님의 말 (도시락 주인이 좋아하는 요리인지, 주인 손님 자기 것인지에 따라)
func _picnic_line(guest: AnimalGuest) -> String:
	var is_favorite: bool = not _is_fallback_order
	if guest == _picnic_host:
		return _picnic_text(_special.self_favorite_line if is_favorite else _special.self_other_line, guest)
	return _picnic_text(_special.favorite_line if is_favorite else _special.other_line, guest)


func _picnic_text(text: String, guest: AnimalGuest, extra: Dictionary = {}) -> String:
	var values: Dictionary = {"guest": guest.display_name, "particle": Korean.subject_particle(guest.display_name),
			"name": GameState.player_name}
	values.merge(extra)
	return text.format(values)


# --- "아무거나 맛있는 거" 날 ---

## 지금 손님에게 낼 요리를 고른다 (수첩을 보고 와도 된다). 고르면 바로 요리를 시작한다.
func _choose_chef_dish() -> void:
	_show_only_button(null)
	var guest: AnimalGuest = current_guest
	var recipes: Array[Recipe] = GameData.get_all_recipes().filter(
			func(recipe: Recipe) -> bool: return GameState.is_recipe_unlocked(recipe.id) and GameState.is_on_menu(recipe.id))
	var served: Array[String] = []
	for recipe_id: StringName in _orders_today:
		var served_recipe: Recipe = GameData.get_recipe(recipe_id)
		if served_recipe != null and _orders_today[recipe_id] > 0 and served_recipe != current_order:
			served.append(served_recipe.display_name)
	var recipe: Recipe = null
	while recipe == null:
		_lunchbox_picker.open(_picnic_text(_special.choose_title_format, guest), guest, recipes, served,
				_special.notebook_button_text, _special.chooser_guest_format, _special.chooser_served_format)
		recipe = await _lunchbox_picker.closed
		if recipe == null:
			_notebook.open()
			while _notebook.visible:
				await _notebook.visibility_changed
	if current_order != null:
		_orders_today[current_order.id] = _orders_today.get(current_order.id, 1) - 1
	current_order = recipe
	_orders_today[recipe.id] = _orders_today.get(recipe.id, 0) + 1
	_is_fallback_order = recipe not in guest.favorite_recipes
	_is_chef_hit = not _is_fallback_order
	_is_choosing_dish = false
	_cook_button.text = _cook_text
	_on_cook_button_pressed()


# --- 요리 ---

func _on_cook_button_pressed() -> void:
	if _is_choosing_dish:
		_choose_chef_dish()
		return
	_show_only_button(null)
	_set_side_buttons_enabled(false)
	GameState.remove_ingredients(current_order.get_ingredient_counts())
	_is_perfect_cook = true
	_remaining_steps = current_order.cook_steps.duplicate()
	_secret_step_count = _remaining_steps.filter(func(step: CookStep) -> bool: return step.has_secret()).size()
	_grandma_step_count = 0
	_is_request_assigned = false
	_is_request_met = false
	_run_next_step()


func _on_minigame_finished(is_perfect: bool, is_grandma_taste: bool, is_request_met: bool) -> void:
	if not is_perfect:
		_is_perfect_cook = false
	if is_grandma_taste:
		_grandma_step_count += 1
	if is_request_met:
		_is_request_met = true
	_run_next_step()


## 비법이 있는 단계를 모두 비법대로 해냈는지
func _is_grandma_cook() -> bool:
	return _secret_step_count > 0 and _grandma_step_count == _secret_step_count


## 레시피의 요리 단계(cook_steps)를 순서대로 하나씩 진행한다. 다 끝나면 요리 완성.
func _run_next_step() -> void:
	if _remaining_steps.is_empty():
		await _dish_showcase.show_dish(current_order, _is_perfect_cook, _is_grandma_cook())
		_set_side_buttons_enabled(true)
		var format: String = PERFECT_COOKED_TEXT_FORMAT if _is_perfect_cook else COOKED_TEXT_FORMAT
		if _is_grandma_cook():
			format = GRANDMA_COOKED_TEXT_FORMAT
		_set_status(format % current_order.display_name, _is_perfect_cook or _is_grandma_cook())
		_show_only_button(_serve_button)
		return
	var step: CookStep = _remaining_steps.pop_front()
	# 오늘의 부탁은 걸 수 있는 첫 번째 단계에만 건다. 부탁에 따라 미니게임이 바뀔 수도 있다 (예: 썰기 → 잘게 다지기).
	var request: GuestRequest = null
	var minigame_type: Recipe.MinigameType = step.type if step != null else Recipe.MinigameType.CHOP
	if step != null and current_request != null and not _is_request_assigned and current_request.applies_to_step(step):
		request = current_request
		_is_request_assigned = true
		minigame_type = request.get_minigame_type(step)
	if step != null and _minigames.has(minigame_type):
		_minigames[minigame_type].start(current_order, step, request)
	else:
		push_warning("요리 단계에 연결된 미니게임이 없어 건너뜁니다: %s" % current_order.id)
		_run_next_step()


## 대접하기 전에 마무리 고명을 고른다. 그만두면 다시 대접하기 버튼으로 돌아간다.
func _on_serve_button_pressed() -> void:
	var hint: String = _taste_hint(current_guest)
	_garnish_picker.open(TASTE_HINT_REMINDER_FORMAT % [current_guest.display_name, hint] if hint != "" else "",
			current_guest, current_order)
	var garnish: Garnish = await _garnish_picker.closed
	if garnish == null:
		_serve_button.grab_focus()
		return
	_serve(garnish)


## 대접하면 손님이 말하고, 밥값 재료를 준다. 완벽하면 재료마다 보너스, 단골이면 덤, 부탁을 들어줬으면 더 준다.
## 고명이 손님 입맛에 맞거나, 할머니 손맛이거나, 부탁을 들어줬으면 단골도가 더 오르고 손님 말도 달라진다.
func _serve(garnish: Garnish) -> void:
	GameState.remove_ingredients(garnish.get_cost())
	_show_only_button(null)
	await _slide_dish_to_guest()
	var guest: AnimalGuest = current_guest
	var settings: RegularSettings = GameData.get_regular_settings()
	var tier: int = GameState.get_regular_tier(guest.id)
	var is_grandma_taste: bool = _is_grandma_cook()
	var is_taste_match: bool = guest.favorite_garnish != null and guest.favorite_garnish.id == garnish.id
	if current_request != null and current_request.is_garnish_request():
		_is_request_met = current_request.garnish.id == garnish.id
	var is_request_met: bool = current_request != null and _is_request_met

	# 밥값
	var payment: Dictionary[StringName, int] = _base_payment(guest)
	var bonus_text: String = ""
	if _is_perfect_cook:
		for ingredient_id: StringName in payment:
			payment[ingredient_id] += perfect_bonus_amount
	var regular_bonus: int = settings.get_payment_bonus(tier)
	if regular_bonus > 0 and not payment.is_empty():
		payment[payment.keys()[0]] += regular_bonus
		bonus_text += REGULAR_BONUS_FORMAT % [settings.get_tier_name(tier), regular_bonus]
	if is_request_met and settings.request_payment_bonus > 0 and not payment.is_empty():
		payment[payment.keys()[0]] += settings.request_payment_bonus
		bonus_text += REQUEST_BONUS_FORMAT % settings.request_payment_bonus
	if _is_birthday_order and _special.gift_ingredient != null and _special.gift_amount > 0:
		payment[_special.gift_ingredient.id] = payment.get(_special.gift_ingredient.id, 0) + _special.gift_amount
		bonus_text += BIRTHDAY_BONUS_FORMAT % _special.gift_amount
	if _is_promise_order and settings.promise_payment_bonus > 0 and not payment.is_empty():
		payment[payment.keys()[0]] += settings.promise_payment_bonus
		bonus_text += PROMISE_BONUS_FORMAT % settings.promise_payment_bonus
	for ingredient_id: StringName in payment:
		GameState.add_ingredient(ingredient_id, payment[ingredient_id])

	# 손님 말과 표정: 할머니 손맛 > 부탁 (들어줌 / 못 들어줌) > 입맛 (맞음 / 힌트) > 완벽 / 보통
	var line: String = guest.perfect_line if _is_perfect_cook else guest.thanks_line
	var expression: StringName = AnimalGuest.EXPRESSION_HAPPY if _is_perfect_cook else AnimalGuest.EXPRESSION_DEFAULT
	if guest.favorite_garnish != null:
		line = guest.taste_match_line if is_taste_match else guest.taste_miss_line
		expression = AnimalGuest.EXPRESSION_HAPPY if is_taste_match else AnimalGuest.EXPRESSION_DEFAULT
	if current_request != null:
		var missed_line: String = guest.request_missed_line if not guest.request_missed_line.is_empty() else REQUEST_MISSED_LINE
		line = current_request.get_thanks_line(guest) if is_request_met else missed_line
		expression = AnimalGuest.EXPRESSION_HAPPY if is_request_met else AnimalGuest.EXPRESSION_SAD
	if _is_promise_order and not guest.promise_kept_line.is_empty():
		line = guest.promise_kept_line.format({"name": GameState.player_name})
		expression = AnimalGuest.EXPRESSION_HAPPY
	if _is_chef_day and _is_chef_hit:
		line = _special.fill(_special.hit_lines.get(guest.id, _special.default_hit_line))
		expression = AnimalGuest.EXPRESSION_HAPPY
	elif _is_chef_day and current_order in guest.disliked_recipes:
		line = _special.fill(_special.dislike_lines.get(guest.id, _special.default_dislike_line))
		expression = AnimalGuest.EXPRESSION_SAD
	elif _is_birthday_order and not _special.wish_thanks_line.is_empty():
		line = _special.fill(_special.wish_thanks_line)
		expression = AnimalGuest.EXPRESSION_HAPPY
	elif _is_picnic:
		# 소풍 도시락: 도시락 주인 대신 주문한 손님(host)이 도시락을 받아 들고 말한다.
		line = _picnic_line(guest)
		expression = AnimalGuest.EXPRESSION_HAPPY if not _is_fallback_order else AnimalGuest.EXPRESSION_DEFAULT
	elif is_grandma_taste:
		# 비법을 알려 준 손님은 그 요리만의 말을, 다른 손님은 자기 말투의 말을 한다.
		var taste_line: String = current_order.grandma_taste_line
		if guest.id != current_order.secret_teller_id and not guest.grandma_taste_line.is_empty():
			taste_line = guest.grandma_taste_line
		if not taste_line.is_empty():
			line = taste_line.format({"name": GameState.player_name})
			expression = AnimalGuest.EXPRESSION_HAPPY

	# 손님 위로 떠오르는 글(과 그때 나는 소리)과 단골도
	var pops: Array[String] = []
	var pop_sounds: Array[StringName] = []
	var points: int = settings.serve_points
	if is_grandma_taste:
		if not GameState.has_grandma_taste(current_order.id):
			pops.append(GRANDMA_STAMP_TEXT)
			pop_sounds.append(POP_SOUND)
		GameState.record_grandma_taste(current_order.id)
		points += settings.grandma_taste_points
	if is_request_met:
		pops.append(REQUEST_DONE_POP_TEXT)
		pop_sounds.append(POP_SOUND)
		points += settings.request_points
	if _is_promise_order:
		pops.append(PROMISE_KEPT_POP_TEXT)
		pop_sounds.append(POP_SOUND)
		points += settings.promise_points
		_is_promise_order = false
	if _is_chef_hit:
		pops.append(_special.hit_pop_text)
		pop_sounds.append(POP_SOUND)
		points += _special.bonus_affection
		_is_chef_hit = false
	if _is_birthday_order:
		pops.append(_special.birthday_pop_text)
		pop_sounds.append(POP_SOUND)
		points += _special.bonus_affection
		_is_birthday_order = false
	if is_taste_match:
		GameState.learn_taste(guest.id)
		pops.append(TASTE_MATCH_POP_TEXT)
		pop_sounds.append(POP_SOUND)
		points += settings.taste_match_points
	var new_tier: int = GameState.add_affection(guest.id, points)
	_record_serve(guest, payment, is_grandma_taste, is_request_met, is_taste_match, points)
	if new_tier >= 0:
		pops.append(TIER_UP_FORMAT % [guest.display_name, Korean.with_particle(guest.display_name), settings.get_tier_name(new_tier)])
		pop_sounds.append(TIER_UP_SOUND)

	_guest_spot.say(line, expression)
	Sound.play(SERVE_SOUND)
	Sound.play(RECEIVE_SOUND)
	_set_payment_status(payment, _is_perfect_cook, is_grandma_taste or is_request_met, bonus_text)
	GameState.record_served_guest(guest.id, _is_perfect_cook)
	current_request = null
	_guests_served += 1
	_update_lunch_label()
	if _is_picnic and _guests_served >= _guests_today:
		_next_guest_button.text = PICNIC_HAND_OVER_TEXT
	_show_only_button(_next_guest_button)
	_pop_one_by_one(pops, pop_sounds)


## 오늘 장사 기록에 이번 대접을 적고, 쌓인 소문을 센다.
func _record_serve(guest: AnimalGuest, payment: Dictionary[StringName, int], is_grandma_taste: bool,
		is_request_met: bool, is_taste_match: bool, affection_points: int) -> void:
	var rules: ReputationSettings = GameData.get_reputation_settings()
	var points: int = rules.serve_points
	_report.guest_names.append(guest.display_name)
	_report.guests.append(guest)
	_report.add_payment(payment)
	_report.add_affection(guest.display_name, affection_points)
	if _is_perfect_cook:
		_report.perfect_count += 1
		points += rules.perfect_points
	if is_grandma_taste:
		_report.grandma_taste_count += 1
		points += rules.grandma_taste_points
	if current_request != null:
		_report.request_count += 1
	if is_request_met:
		_report.request_met_count += 1
		points += rules.request_points
	if is_taste_match:
		_report.taste_match_count += 1
		points += rules.taste_match_points
	_report.reputation += points


## 기본 밥값: 좋아하는 요리면 밥값 재료 전부, 대신 고른 요리면 첫 번째 재료를 조금만.
func _base_payment(guest: AnimalGuest) -> Dictionary[StringName, int]:
	var payment: Dictionary[StringName, int] = {}
	if _is_fallback_order:
		if not guest.payment_ingredients.is_empty():
			payment[guest.payment_ingredients[0].id] = fallback_payment_amount
	else:
		for ingredient: Ingredient in guest.payment_ingredients:
			payment[ingredient.id] = payment.get(ingredient.id, 0) + 1
	return payment


## 손님 위로 글을 하나씩 띄운다 (도장, 부탁, 입맛, 단골 단계). sounds 는 글마다 낼 효과음 (texts 와 같은 순서).
func _pop_one_by_one(texts: Array[String], sounds: Array[StringName]) -> void:
	for i: int in texts.size():
		if i > 0:
			# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
			await get_tree().create_timer(pop_interval, false).timeout
		Sound.play(sounds[i])
		FloatingText.pop(self, texts[i], _guest_spot, stamp_pop_rise, stamp_pop_duration,
				stamp_pop_font_size, perfect_text_color)


# --- 화면 ---

## 버튼은 한 번에 하나만 보여 주고 선택해 둔다. 그래야 게임패드 A 버튼으로도 바로 누를 수 있다.
## null 이면 모든 버튼을 숨긴다.
func _show_only_button(button: Button) -> void:
	for other: Button in _buttons:
		other.visible = other == button
	if button != null:
		button.grab_focus()


func _set_status(text: String, is_perfect: bool) -> void:
	_begin_status(is_perfect)
	_cook_status_label.add_text(text)
	_cook_status_label.pop()


## "밥값으로 [아이콘] 당근 ×2, [아이콘] 꿀 ×1 받았어요 (완벽 보너스 +1!)"
## is_perfect 면 완벽 보너스를 적고, 완벽이나 할머니 손맛이면 금색으로. extra_text 는 맨 뒤에 덧붙인다 (예: 단골 덤).
func _set_payment_status(payment: Dictionary[StringName, int], is_perfect: bool, is_grandma_taste: bool = false,
		extra_text: String = "") -> void:
	_begin_status(is_perfect or is_grandma_taste)
	_cook_status_label.add_text(PAYMENT_PREFIX)
	var is_first: bool = true
	for ingredient_id: StringName in payment:
		if not is_first:
			_cook_status_label.add_text(PAYMENT_ITEM_SEPARATOR)
		is_first = false
		var ingredient: Ingredient = GameData.get_ingredient(ingredient_id)
		if ingredient == null:
			_cook_status_label.add_text(PAYMENT_ITEM_FORMAT % [String(ingredient_id), payment[ingredient_id]])
			continue
		_cook_status_label.add_image(ingredient.get_icon_texture(), payment_icon_size, payment_icon_size,
				Color.WHITE, INLINE_ALIGNMENT_CENTER)
		if show_ingredient_names_with_icons:
			_cook_status_label.add_text(PAYMENT_ITEM_FORMAT % [ingredient.display_name, payment[ingredient_id]])
		else:
			_cook_status_label.add_text(PAYMENT_ITEM_ICON_ONLY_FORMAT % payment[ingredient_id])
	_cook_status_label.add_text(PAYMENT_SUFFIX)
	if is_perfect:
		_cook_status_label.add_text(PERFECT_BONUS_FORMAT % perfect_bonus_amount)
	_cook_status_label.add_text(extra_text)
	_cook_status_label.pop()


## 안내 글을 비우고 색을 정한 뒤, 가운데 정렬 문단을 연다. 쓰고 나면 pop() 으로 닫는다.
func _begin_status(is_perfect: bool) -> void:
	_cook_status_label.clear()
	_cook_status_label.add_theme_color_override("default_color",
			perfect_text_color if is_perfect else _status_default_color)
	_cook_status_label.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)


func _update_lunch_label() -> void:
	_lunch_label.text = (PICNIC_PROGRESS_FORMAT if _is_picnic else LUNCH_PROGRESS_FORMAT) % [_guests_served, _guests_today]


func _on_day_changed(new_day: int) -> void:
	_day_label.text = DAY_TEXT_FORMAT % [GameData.get_season_name(), new_day]
