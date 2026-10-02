class_name GuestNotebook
extends Control
## 손님 수첩. 손님마다 성격, 좋아하는/싫어하는 요리, 밥값, 단골도와 입맛, 그 손님이 알려 주는 할머니 비법을 보여 준다.
## 입맛은 고명을 맞춰 대접해서 알아낸 뒤에만 보인다.
## 비법은 아직 모르면 ●●●●, 알면 비법 한 줄, 할머니 손맛으로 대접한 적이 있으면 도장(♥)이 붙는다.
## 한 번도 대접하지 않은 손님과 아직 노트로 되찾지 못한 요리는 "???"로 가린다.
## open() 으로 열고, 닫기 버튼이나 Esc/게임패드 B(ui_cancel)로 닫는다.

const UNKNOWN_TEXT: String = "???"
const UNMET_GUEST_TEXT: String = "아직 만나지 못한 손님이에요. 대접하면 수첩에 적혀요."
const LIKES_FORMAT: String = "좋아하는 요리: %s"
const DISLIKES_FORMAT: String = "싫어하는 요리: %s"
const PAYMENT_FORMAT: String = "밥값으로 가져오는 것: %s"
const NOTE_HINT_TEXT: String = "할머니 레시피 노트를 아직 가지고 있는 것 같아요."
const NO_NOTE_TEXT: String = "가지고 있던 레시피 노트는 다 돌려받았어요."
const LIST_SEPARATOR: String = ", "
const NONE_TEXT: String = "없음"
const REGULAR_FORMAT: String = "%s %s   ·   입맛: %s"
const TASTE_FORMAT: String = "%s (%s)"
const KEEPSAKE_FORMAT: String = "\n받은 기념품: %s"
const HEART_FULL: String = "♥"
const HEART_EMPTY: String = "♡"
const SECRET_TITLE_TEXT: String = "할머니 비법"
const SECRET_LINE_FORMAT: String = "• %s — %s%s"
const SECRET_UNKNOWN_TEXT: String = "●●●●"
const GRANDMA_STAMP_TEXT: String = "  ♥ 할머니 손맛"
## 수첩을 펼 때 나는 소리 (data/sounds/ 의 id)
const OPEN_SOUND: StringName = &"book"

@export var guest_button_font_size: int = 36
@export var guest_button_height: float = 72.0

## 수첩을 열기 전에 선택돼 있던 버튼. 닫으면 다시 선택한다.
var _previous_focus: Control

@onready var _guest_list: VBoxContainer = %GuestList
@onready var _name_label: Label = %NameLabel
@onready var _personality_label: Label = %PersonalityLabel
@onready var _likes_label: Label = %LikesLabel
@onready var _dislikes_label: Label = %DislikesLabel
@onready var _payment_label: Label = %PaymentLabel
@onready var _note_label: Label = %NoteLabel
@onready var _regular_label: Label = %RegularLabel
@onready var _secret_label: Label = %SecretLabel
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_close_button.pressed.connect(close)
	hide()


func open() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	for child: Node in _guest_list.get_children():
		child.queue_free()
	var buttons: Array[Button] = []
	for guest: AnimalGuest in GameData.get_all_guests():
		var button: Button = Button.new()
		button.text = guest.display_name if GameState.has_met_guest(guest.id) else UNKNOWN_TEXT
		button.custom_minimum_size.y = guest_button_height
		button.add_theme_font_size_override("font_size", guest_button_font_size)
		# 방향키로 옮기기만 해도 오른쪽 내용이 바뀌게 한다.
		button.focus_entered.connect(_show_guest.bind(guest))
		button.pressed.connect(_show_guest.bind(guest))
		_guest_list.add_child(button)
		buttons.append(button)
	_keep_focus_inside(buttons)
	show()
	Sound.play(OPEN_SOUND)
	if not buttons.is_empty():
		buttons[0].grab_focus()


## 수첩이 열려 있는 동안 방향키로 뒤쪽 화면의 버튼에 가지 않도록, 선택이 수첩 안에서만 돌게 한다.
## 손님 목록은 위아래로 돌고, 오른쪽은 닫기 버튼, 닫기 버튼에서 왼쪽은 첫 손님이다.
func _keep_focus_inside(buttons: Array[Button]) -> void:
	if buttons.is_empty():
		return
	for i: int in buttons.size():
		var button: Button = buttons[i]
		var above: Button = buttons[i - 1]
		var below: Button = buttons[(i + 1) % buttons.size()]
		button.focus_neighbor_top = button.get_path_to(above)
		button.focus_neighbor_bottom = button.get_path_to(below)
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(_close_button)
		button.focus_previous = button.focus_neighbor_top
		button.focus_next = button.focus_neighbor_bottom
	var self_path: NodePath = _close_button.get_path_to(_close_button)
	var first_path: NodePath = _close_button.get_path_to(buttons[0])
	_close_button.focus_neighbor_left = first_path
	_close_button.focus_neighbor_top = first_path
	_close_button.focus_neighbor_right = self_path
	_close_button.focus_neighbor_bottom = self_path
	_close_button.focus_next = first_path
	_close_button.focus_previous = first_path


func close() -> void:
	hide()
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _show_guest(guest: AnimalGuest) -> void:
	if not GameState.has_met_guest(guest.id):
		_name_label.text = UNKNOWN_TEXT
		_personality_label.text = UNMET_GUEST_TEXT
		for label: Label in [_likes_label, _dislikes_label, _payment_label, _regular_label, _note_label, _secret_label]:
			label.text = ""
		return
	_name_label.text = guest.display_name
	_personality_label.text = guest.personality
	_likes_label.text = LIKES_FORMAT % _recipe_names(guest.favorite_recipes)
	_dislikes_label.text = DISLIKES_FORMAT % _recipe_names(guest.disliked_recipes)
	var payment_names: PackedStringArray = []
	for ingredient: Ingredient in guest.payment_ingredients:
		if ingredient.display_name not in payment_names:
			payment_names.append(ingredient.display_name)
	_payment_label.text = PAYMENT_FORMAT % (LIST_SEPARATOR.join(payment_names) if not payment_names.is_empty() else NONE_TEXT)
	var has_page_left: bool = guest.note_recipes.any(
			func(recipe: Recipe) -> bool: return not GameState.is_recipe_unlocked(recipe.id))
	_note_label.text = NOTE_HINT_TEXT if has_page_left else (NO_NOTE_TEXT if not guest.note_recipes.is_empty() else "")
	_secret_label.text = _secret_text(guest)
	_regular_label.text = _regular_text(guest)


## "♥♥♡♡ 이웃 · 입맛: 달콤한 맛 (꿀 한 숟갈)". 하트는 단골 단계만큼 찬다 (첫 단계는 하트 없음).
func _regular_text(guest: AnimalGuest) -> String:
	var settings: RegularSettings = GameData.get_regular_settings()
	var tier: int = GameState.get_regular_tier(guest.id)
	var max_tier: int = settings.tier_names.size() - 1
	var hearts: String = HEART_FULL.repeat(tier) + HEART_EMPTY.repeat(maxi(max_tier - tier, 0))
	var taste: String = UNKNOWN_TEXT
	if guest.favorite_garnish != null and GameState.knows_taste(guest.id):
		taste = TASTE_FORMAT % [guest.favorite_garnish.taste_name, guest.favorite_garnish.display_name]
	var text: String = REGULAR_FORMAT % [hearts, settings.get_tier_name(tier), taste]
	for reward: RegularReward in guest.regular_rewards:
		if reward.keepsake != null and GameState.has_keepsake(reward.keepsake.id):
			text += KEEPSAKE_FORMAT % reward.keepsake.display_name
	return text


## 이 손님이 알려 주는 할머니 비법 목록. 하나도 없으면 빈 문자열.
func _secret_text(guest: AnimalGuest) -> String:
	var lines: PackedStringArray = []
	for recipe: Recipe in GameData.get_all_recipes():
		if recipe.secret_teller_id != guest.id or recipe.secret_hint.is_empty():
			continue
		var recipe_name: String = recipe.display_name if GameState.is_recipe_unlocked(recipe.id) else UNKNOWN_TEXT
		var hint: String = recipe.secret_hint if GameState.is_secret_learned(recipe.id) else SECRET_UNKNOWN_TEXT
		var stamp: String = GRANDMA_STAMP_TEXT if GameState.has_grandma_taste(recipe.id) else ""
		lines.append(SECRET_LINE_FORMAT % [recipe_name, hint, stamp])
	if lines.is_empty():
		return ""
	return SECRET_TITLE_TEXT + "\n" + "\n".join(lines)


## 되찾은 레시피는 이름으로, 아직 못 찾은 레시피는 ??? 로 적는다.
func _recipe_names(recipes: Array[Recipe]) -> String:
	if recipes.is_empty():
		return NONE_TEXT
	var names: PackedStringArray = []
	for recipe: Recipe in recipes:
		names.append(recipe.display_name if GameState.is_recipe_unlocked(recipe.id) else UNKNOWN_TEXT)
	return LIST_SEPARATOR.join(names)
