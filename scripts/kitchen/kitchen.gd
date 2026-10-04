extends Control
## 부엌 화면. 점심 장사를 한다.
## 손님이 한 명씩 와서 주문하면 요리(미니게임)를 하고, 대접한 뒤 밥값으로 재료를 받는다.
## 정해진 수만큼 대접하거나, 재료가 떨어져 아무도 주문할 수 없으면 점심 장사가 끝나고 저녁 평상으로 간다.

const DAY_TEXT_FORMAT: String = "%d일째"
const LUNCH_PROGRESS_FORMAT: String = "점심 손님 %d / %d"
const COOKED_TEXT_FORMAT: String = "%s 완성!"
const PERFECT_COOKED_TEXT_FORMAT: String = "%s 완성! 한 번도 안 틀렸어요!"
const GRANDMA_COOKED_TEXT_FORMAT: String = "%s 완성! ♥ 할머니 손맛이 났어요!"
const GRANDMA_STAMP_TEXT: String = "♥ 레시피 노트에 할머니 손맛 도장!"
const TASTE_MATCH_POP_TEXT: String = "♥ 입맛 딱!"
const TIER_UP_FORMAT: String = "%s%s 더 가까워졌어요 · %s"
const REQUEST_JOIN: String = " "
const REQUEST_DONE_POP_TEXT: String = "♪ 부탁을 들어줬어요!"
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
const OUT_OF_INGREDIENTS_TEXT: String = "재료가 다 떨어져서 오늘 장사는 여기까지예요."
## 입맛 힌트를 주문 뒤에 붙일 때 사이에 넣는 글, 고명 창에 다시 보여 줄 때의 모양
const TASTE_HINT_JOIN: String = " "
const TASTE_HINT_REMINDER_FORMAT: String = "%s: \"%s\""
## 호기심 주문 기본 문장 (손님 데이터의 curious_order_line 이 비어 있을 때)
const DEFAULT_CURIOUS_ORDER_LINE: String = "아까 그 냄새가 궁금했어요. {recipe} 주세요!"
## 효과음 이름 (data/sounds/ 의 id)
const GUEST_ARRIVE_SOUND: StringName = &"guest_arrive"
const SERVE_SOUND: StringName = &"serve"
const RECEIVE_SOUND: StringName = &"receive"
const POP_SOUND: StringName = &"pop"
const TIER_UP_SOUND: StringName = &"tier_up"

## 이 장면의 배경음악. 비워 두면 앞 장면의 음악을 서서히 끈다.
## 봄 동안 깔리는 곡을 넣어 둔다 (텃밭·원목·장터·부엌·평상·잔치가 같은 곡이라 장면이 바뀌어도 끊기지 않는다).
@export var music: AudioStream = preload("res://assets/audio/music/spring_theme.mp3")
## 점심 한 번에 받는 손님 수의 최대값 (가게 단계 데이터가 없을 때만 쓴다. 보통은 ShopLevel.max_guests)
@export var guests_per_lunch: int = 3
## 오늘 손님 수 = 오늘 메뉴 수 + 이 값 (최대 guests_per_lunch).
## 메뉴가 하나뿐인 첫날에 같은 요리만 여러 번 하지 않도록, 메뉴가 늘수록 손님도 는다.
@export var extra_guests_over_menu: int = 1
## 이 화면을 켤 때 게임이 아직 시작 전이면 새 게임을 시작한다 (시작 재료와 레시피를 받는다).
## 타이틀 화면과 불러오기가 생기면 그쪽에서 새 게임을 시작하고 이 값은 끈다.
@export var start_new_game_on_ready: bool = true
## 점심 장사가 끝나면 넘어갈 저녁 평상 장면
@export_file("*.tscn") var porch_scene_path: String = "res://scenes/porch/porch.tscn"
## 가게 모습(간판, 등불, 평상, 기념품 선반). 부엌이 켜질 때 배경 바로 위에 붙인다.
@export var shop_decor_scene: PackedScene = preload("res://scenes/kitchen/shop_decor.tscn")
## 목표판 (노트, 소문, 장날, 봄 잔치)과 놓을 자리 (손님 수첩 버튼 아래). kitchen.tscn 을 고치지 않으려고 코드로 붙인다.
@export var goal_board_scene: PackedScene = preload("res://scenes/ui/goal_board.tscn")
@export var goal_board_position: Vector2 = Vector2(48, 250)
## 점심 장사가 끝나고 저녁으로 넘어갈 때 보여 주는 해 지는 장면
@export var sunset_transition_scene: PackedScene = preload("res://scenes/ui/sunset_transition.tscn")
## 레시피 노트를 다 모은 다음 날, 평상 대신 넘어갈 봄 잔치 장면
@export_file("*.tscn") var feast_scene_path: String = "res://scenes/porch/spring_feast.tscn"
## 좋아하는 요리 대신 다른 요리를 주문한 손님은 첫 번째 밥값 재료를 이만큼만 낸다.
@export var fallback_payment_amount: int = 1
## 미니게임을 한 번도 안 틀리면 밥값 재료마다 이만큼 더 받는다.
@export var perfect_bonus_amount: int = 1
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
## 지금 손님의 오늘의 부탁 (없으면 null), 부탁을 미니게임 단계에 이미 걸었는지, 부탁을 들어줬는지
var current_request: GuestRequest
var _is_request_assigned: bool = false
var _is_request_met: bool = false

## 오늘 점심 장사 기록 (장사가 끝나면 장사 결과판에 보여 준다)
var _report: LunchReport = LunchReport.new()
## 오늘 점심에 대접을 마친 손님 수와 받을 손님 수
var _guests_served: int = 0
## 오늘 주문받은 요리 id → 횟수. 손님이 오늘 덜 나간 요리를 먼저 시키게 할 때 쓴다 (같은 요리만 반복되지 않게).
var _orders_today: Dictionary[StringName, int] = {}
var _guests_today: int = 0
## 다음에 올 손님 차례. 비면 손님 목록을 섞어서 다시 채운다.
var _guest_queue: Array[AnimalGuest] = []
## 바로 앞에 왔던 손님 (같은 손님이 연달아 오지 않게 할 때 쓴다)
var _last_guest: AnimalGuest
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
@onready var _cook_button: Button = %CookButton
@onready var _serve_button: Button = %ServeButton
@onready var _next_guest_button: Button = %NextGuestButton
@onready var _evening_button: Button = %EveningButton
@onready var _cook_status_label: RichTextLabel = %CookStatusLabel
@onready var _notebook: GuestNotebook = %GuestNotebook
@onready var _notebook_button: Button = %NotebookButton
@onready var _garnish_picker: GarnishPicker = %GarnishPicker
@onready var _result_board: ResultBoard = %ResultBoard
@onready var _chop_minigame: ChopMinigame = %ChopMinigame
@onready var _stir_fry_minigame: StirFryMinigame = %StirFryMinigame
@onready var _plate_minigame: PlateMinigame = %PlateMinigame
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
	Recipe.MinigameType.PLATE: _plate_minigame,
	Recipe.MinigameType.PAN_FRY: _pan_fry_minigame,
	Recipe.MinigameType.ROLL: _roll_minigame,
	Recipe.MinigameType.COOK_RICE: _rice_minigame,
	Recipe.MinigameType.MIX: _mix_minigame,
	Recipe.MinigameType.SIMMER: _simmer_minigame,
	Recipe.MinigameType.MINCE: _mince_minigame,
}
@onready var _buttons: Array[Button] = [_cook_button, _serve_button, _next_guest_button, _evening_button]


func _ready() -> void:
	Sound.play_music(music)
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
	# 미니게임과 창들보다 뒤에 그려지게, 첫 미니게임보다 앞 순서에 둔다.
	move_child(board, get_node("%ChopMinigame").get_index())


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
	_guests_today = _count_guests_today()
	_guest_queue.clear()
	_update_lunch_label()
	_call_next_guest()


## 다음 손님을 부른다. 지금 재료로 만들 수 있는 요리를 주문할 손님이 올 때까지 차례를 넘긴다.
func _call_next_guest() -> void:
	_show_only_button(null)
	_set_status("", false)
	_guest_spot.clear()
	current_guest = null
	current_order = null
	current_request = null
	if _guests_served >= _guests_today:
		_end_lunch(LUNCH_DONE_TEXT)
		return
	var guest_count: int = GameData.get_all_guests().size()
	for i: int in guest_count:
		var guest: AnimalGuest = _pop_next_guest()
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
			_last_guest = guest
			var order_text: String = guest.order_line.format({"recipe": order.display_name})
			if _is_fallback_order:
				order_text = guest.fallback_order_line.format({"recipe": order.display_name})
			elif warm_order != null and not guest.rain_order_line.is_empty():
				order_text = guest.rain_order_line.format({"recipe": order.display_name})
			elif curious_order != null:
				var curious_line: String = guest.curious_order_line if not guest.curious_order_line.is_empty() \
						else DEFAULT_CURIOUS_ORDER_LINE
				order_text = curious_line.format({"recipe": order.display_name})
			# 처음 온 손님은 할머니 밥집 단골이었다는 인사와 함께 주문한다.
			if not GameState.has_met_guest(guest.id) and not guest.first_order_line.is_empty():
				order_text = guest.first_order_line.format({"recipe": order.display_name})
			if _taste_hint(guest) != "":
				order_text += TASTE_HINT_JOIN + _taste_hint(guest)
			current_request = _choose_request(guest, order)
			if current_request != null:
				order_text += REQUEST_JOIN + current_request.line
			_guest_spot.show_guest(guest, order_text, GameState.is_raining_today)
			Sound.play(GUEST_ARRIVE_SOUND)
			_show_only_button(_cook_button)
			return
	_end_lunch(OUT_OF_INGREDIENTS_TEXT)


## 오늘 메뉴 수 + extra_guests_over_menu + 가게 단계의 손님 보너스. 최대는 가게 단계의 max_guests
## (가게 단계 데이터가 없으면 guests_per_lunch). 소문이 퍼질수록 손님이 는다.
## 메뉴를 안 정했으면(메뉴가 비어 있으면 되찾은 레시피 전부를 낼 수 있다) 되찾은 레시피 수로 센다.
func _count_guests_today() -> int:
	var menu_count: int = GameState.menu_recipe_ids.size()
	if menu_count == 0:
		menu_count = GameData.get_all_recipes().filter(
				func(recipe: Recipe) -> bool: return GameState.is_recipe_unlocked(recipe.id)).size()
	var level: ShopLevel = GameState.get_shop_level()
	var bonus: int = level.extra_guests if level != null else 0
	var max_guests: int = level.max_guests if level != null else guests_per_lunch
	return clampi(menu_count + extra_guests_over_menu + bonus, 1, max_guests)


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


## 손님 차례에서 한 명을 꺼낸다. 차례가 비면 손님 목록을 섞어서 다시 채운다.
## 같은 손님이 연달아 오지 않도록, 새로 섞은 차례의 첫 손님이 방금 손님이면 뒤로 보낸다.
func _pop_next_guest() -> AnimalGuest:
	if _guest_queue.is_empty():
		_guest_queue = GameData.get_all_guests()
		_guest_queue.shuffle()
		if _guest_queue.size() > 1 and _guest_queue[0] == _last_guest:
			_guest_queue.push_back(_guest_queue.pop_front())
	return _guest_queue.pop_front()


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
	get_tree().change_scene_to_file(feast_scene_path if GameState.is_spring_feast_day() else porch_scene_path)


# --- 요리 ---

func _on_cook_button_pressed() -> void:
	_show_only_button(null)
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
	_garnish_picker.open(TASTE_HINT_REMINDER_FORMAT % [current_guest.display_name, hint] if hint != "" else "")
	var garnish: Garnish = await _garnish_picker.closed
	if garnish == null:
		_serve_button.grab_focus()
		return
	_serve(garnish)


## 대접하면 손님이 말하고, 밥값 재료를 준다. 완벽하면 재료마다 보너스, 단골이면 덤, 부탁을 들어줬으면 더 준다.
## 고명이 손님 입맛에 맞거나, 할머니 손맛이거나, 부탁을 들어줬으면 단골도가 더 오르고 손님 말도 달라진다.
func _serve(garnish: Garnish) -> void:
	GameState.remove_ingredients(garnish.get_cost())
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
	for ingredient_id: StringName in payment:
		GameState.add_ingredient(ingredient_id, payment[ingredient_id])

	# 손님 말: 할머니 손맛 > 부탁 (들어줌 / 못 들어줌) > 입맛 (맞음 / 힌트) > 완벽 / 보통
	var line: String = guest.perfect_line if _is_perfect_cook else guest.thanks_line
	if guest.favorite_garnish != null:
		line = guest.taste_match_line if is_taste_match else guest.taste_miss_line
	if current_request != null:
		line = current_request.thanks_line if is_request_met else REQUEST_MISSED_LINE
	if is_grandma_taste and not current_order.grandma_taste_line.is_empty():
		line = current_order.grandma_taste_line.format({"name": GameState.player_name})

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

	_guest_spot.say(line)
	Sound.play(SERVE_SOUND)
	Sound.play(RECEIVE_SOUND)
	_set_payment_status(payment, _is_perfect_cook, is_grandma_taste or is_request_met, bonus_text)
	GameState.record_served_guest(guest.id, _is_perfect_cook)
	current_request = null
	_guests_served += 1
	_update_lunch_label()
	_show_only_button(_next_guest_button)
	_pop_one_by_one(pops, pop_sounds)


## 오늘 장사 기록에 이번 대접을 적고, 쌓인 소문을 센다.
func _record_serve(guest: AnimalGuest, payment: Dictionary[StringName, int], is_grandma_taste: bool,
		is_request_met: bool, is_taste_match: bool, affection_points: int) -> void:
	var rules: ReputationSettings = GameData.get_reputation_settings()
	var points: int = rules.serve_points
	_report.guest_names.append(guest.display_name)
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
	_lunch_label.text = LUNCH_PROGRESS_FORMAT % [_guests_served, _guests_today]


func _on_day_changed(new_day: int) -> void:
	_day_label.text = DAY_TEXT_FORMAT % new_day
