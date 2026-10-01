extends Control
## 부엌 화면. 손님이 와서 주문하면 요리(미니게임)를 하고, 대접한 뒤 밥값으로 재료를 받는다.

const DAY_TEXT_FORMAT: String = "%d일째"
const COOKED_TEXT_FORMAT: String = "%s 완성!"
const PERFECT_COOKED_TEXT_FORMAT: String = "%s 완성! 한 번도 안 틀렸어요!"
const PAYMENT_TEXT_FORMAT: String = "밥값으로 %s 받았어요"
const PAYMENT_ITEM_FORMAT: String = "%s ×%d"
const PAYMENT_ITEM_SEPARATOR: String = ", "
const PERFECT_BONUS_FORMAT: String = " (완벽 보너스 +%d!)"

## 미니게임을 한 번도 안 틀리면 밥값 재료마다 이만큼 더 받는다.
@export var perfect_bonus_amount: int = 1
## 완벽하게 요리했을 때 아래 안내 글자 색
@export var perfect_text_color: Color = Color(1, 0.84, 0.25)

## 지금 와 있는 손님과 그 손님의 주문. 손님이 없으면 null.
var current_guest: AnimalGuest
var current_order: Recipe

## 요리 중에 아직 남은 미니게임 단계
var _remaining_steps: Array[Recipe.MinigameType] = []
## 이번 요리의 미니게임을 지금까지 전부 한 번도 안 틀렸는지
var _is_perfect_cook: bool = true
## 안내 글자의 원래 색 (완벽 색에서 되돌릴 때 쓴다)
var _status_default_color: Color

@onready var _day_label: Label = %DayLabel
@onready var _guest_spot: GuestSpot = %GuestSpot
@onready var _cook_button: Button = %CookButton
@onready var _serve_button: Button = %ServeButton
@onready var _cook_status_label: Label = %CookStatusLabel
@onready var _chop_minigame: ChopMinigame = %ChopMinigame
@onready var _plate_minigame: PlateMinigame = %PlateMinigame
## 레시피의 미니게임 종류마다 실제로 실행할 미니게임
@onready var _minigames: Dictionary[Recipe.MinigameType, Minigame] = {
	Recipe.MinigameType.CHOP: _chop_minigame,
	Recipe.MinigameType.PLATE: _plate_minigame,
}


func _ready() -> void:
	GameState.day_changed.connect(_on_day_changed)
	_cook_button.pressed.connect(_on_cook_button_pressed)
	_serve_button.pressed.connect(_on_serve_button_pressed)
	for minigame: Minigame in _minigames.values():
		minigame.finished.connect(_on_minigame_finished)
	_cook_button.hide()
	_serve_button.hide()
	_cook_status_label.text = ""
	_status_default_color = _cook_status_label.get_theme_color("font_color")
	_on_day_changed(GameState.current_day)
	_call_next_guest()


## data/guests 의 손님 중 한 명을 불러, 그 손님이 좋아하는 요리 중 하나를 주문받는다.
func _call_next_guest() -> void:
	var guests: Array[AnimalGuest] = GameData.get_all_guests()
	if guests.is_empty():
		push_warning("data/guests 에 손님이 없습니다")
		return
	var guest: AnimalGuest = guests.pick_random()
	if guest.favorite_recipes.is_empty():
		push_warning("손님 '%s'의 Favorite Recipes 가 비어 있어 주문할 수 없습니다" % guest.id)
		return
	current_guest = guest
	current_order = guest.favorite_recipes.pick_random()
	_guest_spot.show_order(current_guest, current_order)
	_show_button(_cook_button)


func _on_cook_button_pressed() -> void:
	_cook_button.hide()
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
		_cook_status_label.text = format % current_order.display_name
		_cook_status_label.add_theme_color_override("font_color",
				perfect_text_color if _is_perfect_cook else _status_default_color)
		_show_button(_serve_button)
		return
	var step: Recipe.MinigameType = _remaining_steps.pop_front()
	if _minigames.has(step):
		_minigames[step].start(current_order)
	else:
		# 볶기 미니게임은 아직 없어서 건너뛴다.
		_run_next_step()


## 대접하면 손님이 고맙다고 말하고, 밥값 재료를 준다. 완벽했으면 재료마다 보너스를 더 준다.
func _on_serve_button_pressed() -> void:
	_serve_button.hide()
	var payment: Dictionary[StringName, int] = {}
	for ingredient: Ingredient in current_guest.payment_ingredients:
		payment[ingredient.id] = payment.get(ingredient.id, 0) + 1
	if _is_perfect_cook:
		for ingredient_id: StringName in payment:
			payment[ingredient_id] += perfect_bonus_amount
	var payment_texts: PackedStringArray = []
	for ingredient_id: StringName in payment:
		GameState.add_ingredient(ingredient_id, payment[ingredient_id])
		var ingredient: Ingredient = GameData.get_ingredient(ingredient_id)
		var ingredient_name: String = ingredient.display_name if ingredient != null else String(ingredient_id)
		payment_texts.append(PAYMENT_ITEM_FORMAT % [ingredient_name, payment[ingredient_id]])
	_guest_spot.say(current_guest.perfect_line if _is_perfect_cook else current_guest.thanks_line)
	var payment_text: String = PAYMENT_TEXT_FORMAT % PAYMENT_ITEM_SEPARATOR.join(payment_texts)
	if _is_perfect_cook:
		payment_text += PERFECT_BONUS_FORMAT % perfect_bonus_amount
	_cook_status_label.text = payment_text


## 버튼을 보여 주고 선택해 둔다. 그래야 게임패드 A 버튼으로도 바로 누를 수 있다.
func _show_button(button: Button) -> void:
	button.show()
	button.grab_focus()


func _on_day_changed(new_day: int) -> void:
	_day_label.text = DAY_TEXT_FORMAT % new_day
