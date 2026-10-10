class_name GuestNotebook
extends Control
## 손님 수첩. 손님마다 성격, 좋아하는/싫어하는 요리, 밥값, 단골도와 입맛, 그 손님이 알려 주는 할머니 비법을 보여 준다.
## 입맛은 고명을 맞춰 대접해서 알아낸 뒤에만 보인다.
## 비법은 아직 모르면 ●●●●, 알면 비법 한 줄, 할머니 손맛으로 대접한 적이 있으면 도장(♥)이 붙는다.
## 한 번도 대접하지 않은 손님은 "???"로 가린다.
## 좋아하는 요리는 그 손님에게 그 요리를 대접해야 한 칸씩 적힌다 (GameState.knows_guest_dish). 싫어하는 요리는
## 대접해 봤거나 단골 단계가 RegularSettings.dislike_reveal_tier 가 되면 적힌다. 아직 모르는 칸은 "???".
## 손님마다 알아낸 칸 수(성격·밥값, 좋아하는/싫어하는 요리, 입맛, 할머니 비법)를 보여 주고, 다 알아내면 목록 이름 옆에 ★.
## 점심에 왔다가 대접받지 못하고 돌아간 손님은 이름만 보이고 기록은 비어 있다.
## 기록 왼쪽에 손님 얼굴 그림(AnimalGuest.portrait, 360×480 그대로)이 나온다. 그림이 없으면 손님 색(icon_placeholder_color)의 임시 네모.
## 아직 얼굴을 못 본 손님은 까만 실루엣과 "?" 로 보여서 누구일지 궁금하게 한다.
## open() 으로 열고, 닫기 버튼이나 Esc/게임패드 B(ui_cancel)로 닫는다.

const UNKNOWN_TEXT: String = "???"
const UNMET_GUEST_TEXT: String = "아직 만나지 못한 손님이에요. 대접하면 수첩에 적혀요."
const UNSERVED_GUEST_TEXT: String = "아직 대접하지 못했어요. 대접하면 수첩에 적혀요."
const LIKES_FORMAT: String = "좋아하는 요리: %s"
const DISLIKES_FORMAT: String = "싫어하는 요리: %s"
## 아직 털어놓지 않은 싫어하는 요리: "??? (이웃이 되면 털어놓을지도)"
const DISLIKE_HINT_FORMAT: String = "%s (%s%s 되면 털어놓을지도)"
const PROGRESS_FORMAT: String = "알아낸 것 %d / %d"
## 다 알아낸 손님의 목록 이름 옆 표시
const COMPLETE_MARK: String = " ★"
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
## 실루엣: 그림 모양(투명도)만 남기고 한 가지 색으로 칠한다
const SILHOUETTE_SHADER_CODE: String = """
shader_type canvas_item;
uniform vec4 fill_color : source_color;
void fragment() {
	COLOR = vec4(fill_color.rgb, texture(TEXTURE, UV).a * fill_color.a);
}
"""
## 수첩을 펼 때 나는 소리 (data/sounds/ 의 id)
const OPEN_SOUND: StringName = &"book"

@export var guest_button_font_size: int = 36
@export var guest_button_height: float = 72.0
## 아직 못 만난 손님의 실루엣 색
@export var silhouette_color: Color = Color(0.3, 0.22, 0.16)

## 수첩을 열기 전에 선택돼 있던 버튼. 닫으면 다시 선택한다.
var _previous_focus: Control
var _silhouette_material: ShaderMaterial

@onready var _guest_list: VBoxContainer = %GuestList
@onready var _name_label: Label = %NameLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _personality_label: Label = %PersonalityLabel
@onready var _likes_label: Label = %LikesLabel
@onready var _dislikes_label: Label = %DislikesLabel
@onready var _payment_label: Label = %PaymentLabel
@onready var _note_label: Label = %NoteLabel
@onready var _regular_label: Label = %RegularLabel
@onready var _secret_label: Label = %SecretLabel
@onready var _close_button: Button = %CloseButton
@onready var _portrait: TextureRect = %Portrait
@onready var _portrait_placeholder: ColorRect = %PortraitPlaceholder
@onready var _unknown_mark: Label = %UnknownMark


func _ready() -> void:
	_close_button.pressed.connect(close)
	var shader: Shader = Shader.new()
	shader.code = SILHOUETTE_SHADER_CODE
	_silhouette_material = ShaderMaterial.new()
	_silhouette_material.shader = shader
	_silhouette_material.set_shader_parameter("fill_color", silhouette_color)
	hide()


func open() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	for child: Node in _guest_list.get_children():
		child.queue_free()
	var buttons: Array[Button] = []
	for guest: AnimalGuest in GameData.get_all_guests():
		var button: Button = Button.new()
		button.text = guest.display_name if GameState.has_seen_guest(guest.id) else UNKNOWN_TEXT
		var knowledge: Vector2i = _get_knowledge(guest)
		if GameState.has_met_guest(guest.id) and knowledge.x >= knowledge.y:
			button.text += COMPLETE_MARK
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
	_show_portrait(guest, GameState.has_seen_guest(guest.id))
	if not GameState.has_met_guest(guest.id):
		var is_seen: bool = GameState.has_seen_guest(guest.id)
		_name_label.text = guest.display_name if is_seen else UNKNOWN_TEXT
		_set_wrapped(_personality_label, UNSERVED_GUEST_TEXT if is_seen else UNMET_GUEST_TEXT)
		for label: Label in [_progress_label, _likes_label, _dislikes_label, _payment_label, _regular_label, _note_label, _secret_label]:
			label.text = ""
		return
	_name_label.text = guest.display_name
	var knowledge: Vector2i = _get_knowledge(guest)
	_progress_label.text = PROGRESS_FORMAT % [knowledge.x, knowledge.y] + (COMPLETE_MARK if knowledge.x >= knowledge.y else "")
	_set_wrapped(_personality_label, guest.personality)
	_set_wrapped(_likes_label, LIKES_FORMAT % _dish_names(guest, guest.favorite_recipes, false))
	_set_wrapped(_dislikes_label, DISLIKES_FORMAT % _dish_names(guest, guest.disliked_recipes, true))
	var payment_names: PackedStringArray = []
	for ingredient: Ingredient in guest.payment_ingredients:
		if ingredient.display_name not in payment_names:
			payment_names.append(ingredient.display_name)
	_set_wrapped(_payment_label, PAYMENT_FORMAT % (LIST_SEPARATOR.join(payment_names) if not payment_names.is_empty() else NONE_TEXT))
	var has_page_left: bool = guest.note_recipes.any(
			func(recipe: Recipe) -> bool: return not GameState.is_recipe_unlocked(recipe.id))
	_set_wrapped(_note_label, NOTE_HINT_TEXT if has_page_left else (NO_NOTE_TEXT if not guest.note_recipes.is_empty() else ""))
	_secret_label.text = _secret_text(guest)
	_regular_label.text = _regular_text(guest)


## 손님 얼굴 그림. 얼굴을 본 손님은 그대로, 아직 못 본 손님은 실루엣과 "?".
## 그림이 없으면 손님 색 임시 네모 (못 본 손님이면 실루엣 색 네모).
func _show_portrait(guest: AnimalGuest, is_face_known: bool) -> void:
	var texture: Texture2D = guest.get_portrait()
	_portrait.texture = texture
	_portrait.visible = texture != null
	_portrait.material = null if is_face_known else _silhouette_material
	_portrait_placeholder.visible = texture == null
	_portrait_placeholder.color = guest.icon_placeholder_color if is_face_known else silhouette_color
	_unknown_mark.visible = not is_face_known


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


## 수첩에 적힌 요리는 이름으로, 아직 모르는 요리는 ??? 로 적는다.
## 싫어하는 요리를 하나도 모르면 언제 털어놓을지 한마디 덧붙인다.
func _dish_names(guest: AnimalGuest, recipes: Array[Recipe], is_dislike: bool) -> String:
	if recipes.is_empty():
		return NONE_TEXT
	var names: PackedStringArray = []
	var known_count: int = 0
	for recipe: Recipe in recipes:
		if recipe == null:
			continue
		var is_known: bool = GameState.knows_guest_dislike(guest.id, recipe.id) if is_dislike \
				else GameState.knows_guest_dish(guest.id, recipe.id)
		names.append(recipe.display_name if is_known else UNKNOWN_TEXT)
		if is_known:
			known_count += 1
	var text: String = LIST_SEPARATOR.join(names)
	if is_dislike and known_count == 0:
		var settings: RegularSettings = GameData.get_regular_settings()
		var tier_name: String = settings.get_tier_name(settings.dislike_reveal_tier)
		text = DISLIKE_HINT_FORMAT % [text, tier_name, Korean.subject_particle(tier_name)]
	return text


## 이 손님에 대해 알아낸 칸 수(x)와 모든 칸 수(y): 성격·밥값 한 칸, 좋아하는 요리, 싫어하는 요리, 입맛, 할머니 비법
func _get_knowledge(guest: AnimalGuest) -> Vector2i:
	var known: int = 1 if GameState.has_met_guest(guest.id) else 0
	var total: int = 1
	for recipe: Recipe in guest.favorite_recipes:
		if recipe != null:
			total += 1
			known += 1 if GameState.knows_guest_dish(guest.id, recipe.id) else 0
	for recipe: Recipe in guest.disliked_recipes:
		if recipe != null:
			total += 1
			known += 1 if GameState.knows_guest_dislike(guest.id, recipe.id) else 0
	if guest.favorite_garnish != null:
		total += 1
		known += 1 if GameState.knows_taste(guest.id) else 0
	for recipe: Recipe in GameData.get_all_recipes():
		if recipe.secret_teller_id == guest.id and not recipe.secret_hint.is_empty():
			total += 1
			known += 1 if GameState.is_secret_learned(recipe.id) else 0
	return Vector2i(known, total)


## 한글이 낱말 중간에서 줄이 바뀌지 않게 띄어쓰기 자리에서 미리 줄을 나눠 넣는다.
func _set_wrapped(label: Label, text: String) -> void:
	label.text = Korean.wrap_by_spaces(text, label.get_theme_font("font"), label.get_theme_font_size("font_size"),
			label.get_parent_control().size.x)
