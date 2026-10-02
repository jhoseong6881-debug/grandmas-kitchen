extends Control
## 부엌 화면. 점심 장사를 한다.
## 손님이 한 명씩 와서 주문하면 요리(미니게임)를 하고, 대접한 뒤 밥값으로 재료를 받는다.
## 정해진 수만큼 대접하거나, 재료가 떨어져 아무도 주문할 수 없으면 점심 장사가 끝나고 저녁 평상으로 간다.

const DAY_TEXT_FORMAT: String = "%d일째"
const LUNCH_PROGRESS_FORMAT: String = "점심 손님 %d / %d"
const COOKED_TEXT_FORMAT: String = "%s 완성!"
const PERFECT_COOKED_TEXT_FORMAT: String = "%s 완성! 한 번도 안 틀렸어요!"
const PAYMENT_PREFIX: String = "밥값으로 "
const PAYMENT_SUFFIX: String = " 받았어요"
const PAYMENT_ITEM_FORMAT: String = " %s ×%d"
const PAYMENT_ITEM_ICON_ONLY_FORMAT: String = " ×%d"
const PAYMENT_ITEM_SEPARATOR: String = ", "
const PERFECT_BONUS_FORMAT: String = " (완벽 보너스 +%d!)"
const LUNCH_DONE_TEXT: String = "오늘 점심 장사 끝! 수고했어요."
const OUT_OF_INGREDIENTS_TEXT: String = "재료가 다 떨어져서 오늘 장사는 여기까지예요."

## 점심 한 번에 받는 손님 수
@export var guests_per_lunch: int = 3
## 이 화면을 켤 때 게임이 아직 시작 전이면 새 게임을 시작한다 (시작 재료와 레시피를 받는다).
## 타이틀 화면과 불러오기가 생기면 그쪽에서 새 게임을 시작하고 이 값은 끈다.
@export var start_new_game_on_ready: bool = true
## 점심 장사가 끝나면 넘어갈 저녁 평상 장면
@export_file("*.tscn") var porch_scene_path: String = "res://scenes/porch/porch.tscn"
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

## 지금 와 있는 손님과 그 손님의 주문. 손님이 없으면 null.
var current_guest: AnimalGuest
var current_order: Recipe
## 지금 주문이 좋아하는 요리 대신 고른 요리인지
var _is_fallback_order: bool = false

## 오늘 점심에 대접을 마친 손님 수
var _guests_served: int = 0
## 다음에 올 손님 차례. 비면 손님 목록을 섞어서 다시 채운다.
var _guest_queue: Array[AnimalGuest] = []
## 바로 앞에 왔던 손님 (같은 손님이 연달아 오지 않게 할 때 쓴다)
var _last_guest: AnimalGuest
## 요리 중에 아직 남은 미니게임 단계
var _remaining_steps: Array[Recipe.MinigameType] = []
## 이번 요리의 미니게임을 지금까지 전부 한 번도 안 틀렸는지
var _is_perfect_cook: bool = true
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
@onready var _chop_minigame: ChopMinigame = %ChopMinigame
@onready var _stir_fry_minigame: StirFryMinigame = %StirFryMinigame
@onready var _plate_minigame: PlateMinigame = %PlateMinigame
## 레시피의 미니게임 종류마다 실제로 실행할 미니게임
@onready var _minigames: Dictionary[Recipe.MinigameType, Minigame] = {
	Recipe.MinigameType.CHOP: _chop_minigame,
	Recipe.MinigameType.STIR_FRY: _stir_fry_minigame,
	Recipe.MinigameType.PLATE: _plate_minigame,
}
@onready var _buttons: Array[Button] = [_cook_button, _serve_button, _next_guest_button, _evening_button]


func _ready() -> void:
	GameState.day_changed.connect(_on_day_changed)
	_cook_button.pressed.connect(_on_cook_button_pressed)
	_serve_button.pressed.connect(_on_serve_button_pressed)
	_next_guest_button.pressed.connect(_on_next_guest_button_pressed)
	_evening_button.pressed.connect(_on_evening_button_pressed)
	_notebook_button.pressed.connect(_notebook.open)
	for minigame: Minigame in _minigames.values():
		minigame.finished.connect(_on_minigame_finished)
	_status_default_color = _cook_status_label.get_theme_color("default_color")
	if start_new_game_on_ready and not GameState.is_game_started:
		GameState.start_new_game()
	_on_day_changed(GameState.current_day)
	_start_lunch()


# --- 점심 장사 흐름 ---

func _start_lunch() -> void:
	_guests_served = 0
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
	if _guests_served >= guests_per_lunch:
		_end_lunch(LUNCH_DONE_TEXT)
		return
	var guest_count: int = GameData.get_all_guests().size()
	for i: int in guest_count:
		var guest: AnimalGuest = _pop_next_guest()
		var order: Recipe = _choose_order(guest)
		_is_fallback_order = order == null
		if _is_fallback_order:
			order = _choose_fallback_order(guest)
		if order != null:
			current_guest = guest
			current_order = order
			_last_guest = guest
			if _is_fallback_order:
				_guest_spot.show_guest(guest, guest.fallback_order_line.format({"recipe": order.display_name}))
			else:
				_guest_spot.show_order(guest, order)
			_show_only_button(_cook_button)
			return
	_end_lunch(OUT_OF_INGREDIENTS_TEXT)


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
func _choose_order(guest: AnimalGuest) -> Recipe:
	var possible: Array[Recipe] = guest.favorite_recipes.filter(_can_cook)
	return possible.pick_random() if not possible.is_empty() else null


## 좋아하는 요리를 못 낼 때 대신 주문할 요리: 지금 낼 수 있고 싫어하지 않는 아무 요리 하나. 없으면 null.
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


func _on_evening_button_pressed() -> void:
	get_tree().change_scene_to_file(feast_scene_path if GameState.is_spring_feast_day() else porch_scene_path)


# --- 요리 ---

func _on_cook_button_pressed() -> void:
	_show_only_button(null)
	GameState.remove_ingredients(current_order.get_ingredient_counts())
	_is_perfect_cook = true
	_remaining_steps = current_order.minigame_steps.duplicate()
	_run_next_step()


func _on_minigame_finished(is_perfect: bool) -> void:
	if not is_perfect:
		_is_perfect_cook = false
	_run_next_step()


## 레시피의 미니게임 단계를 순서대로 하나씩 진행한다. 다 끝나면 요리 완성.
func _run_next_step() -> void:
	if _remaining_steps.is_empty():
		var format: String = PERFECT_COOKED_TEXT_FORMAT if _is_perfect_cook else COOKED_TEXT_FORMAT
		_set_status(format % current_order.display_name, _is_perfect_cook)
		_show_only_button(_serve_button)
		return
	var step: Recipe.MinigameType = _remaining_steps.pop_front()
	if _minigames.has(step):
		_minigames[step].start(current_order)
	else:
		push_warning("미니게임 종류 %d 에 연결된 미니게임이 없어 건너뜁니다" % step)
		_run_next_step()


## 대접하면 손님이 고맙다고 말하고, 밥값 재료를 준다. 완벽했으면 재료마다 보너스를 더 준다.
func _on_serve_button_pressed() -> void:
	var payment: Dictionary[StringName, int] = {}
	if _is_fallback_order:
		if not current_guest.payment_ingredients.is_empty():
			payment[current_guest.payment_ingredients[0].id] = fallback_payment_amount
	else:
		for ingredient: Ingredient in current_guest.payment_ingredients:
			payment[ingredient.id] = payment.get(ingredient.id, 0) + 1
	if _is_perfect_cook:
		for ingredient_id: StringName in payment:
			payment[ingredient_id] += perfect_bonus_amount
	for ingredient_id: StringName in payment:
		GameState.add_ingredient(ingredient_id, payment[ingredient_id])
	_guest_spot.say(current_guest.perfect_line if _is_perfect_cook else current_guest.thanks_line)
	_set_payment_status(payment, _is_perfect_cook)
	GameState.record_served_guest(current_guest.id, _is_perfect_cook)
	_guests_served += 1
	_update_lunch_label()
	_show_only_button(_next_guest_button)


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
func _set_payment_status(payment: Dictionary[StringName, int], is_perfect: bool) -> void:
	_begin_status(is_perfect)
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
	_cook_status_label.pop()


## 안내 글을 비우고 색을 정한 뒤, 가운데 정렬 문단을 연다. 쓰고 나면 pop() 으로 닫는다.
func _begin_status(is_perfect: bool) -> void:
	_cook_status_label.clear()
	_cook_status_label.add_theme_color_override("default_color",
			perfect_text_color if is_perfect else _status_default_color)
	_cook_status_label.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)


func _update_lunch_label() -> void:
	_lunch_label.text = LUNCH_PROGRESS_FORMAT % [_guests_served, guests_per_lunch]


func _on_day_changed(new_day: int) -> void:
	_day_label.text = DAY_TEXT_FORMAT % new_day
