extends Control
## 아침 마을 길 장면. 텃밭에서 건너와 이웃 손님의 집 중 하루에 한 곳(VillageSettings.visits_per_day)에 들른다.
## 밥집에서 만난 손님의 집만 갈 수 있고, 못 만난 손님 집은 "?"로 가려 둔다.
## 집에 들르면 인사 → 집 이야기(대답 고르기) → 남는 재료를 선물로 두고 오기(단골도). 선물은 안 해도 된다.
## 손님마다 집 이름·인사·이야기·좋아하는 선물은 손님 데이터(AnimalGuest 의 "마을 길 집")에 있다.

const DAY_TEXT_FORMAT: String = "%s %d일째 · 마을 길"
const HOME_NAME_FORMAT: String = "%s네 집"
const GIFT_REPLY_FORMAT: String = "%s %d개 드리기"
const TIER_UP_FORMAT: String = "%s%s 더 가까워졌어요 · %s"
const AFFECTION_POP_FORMAT: String = "♥ +%d"
const REPLY_FORMAT: String = "\"%s\""
## 효과음 이름 (data/sounds/ 의 id)
const GIFT_SOUND: StringName = &"receive"

## 돌아갈 당근 텃밭 장면
@export_file("*.tscn") var garden_scene_path: String = "res://scenes/garden/garden.tscn"
## 집 버튼 크기와 글자 크기, 집 그림을 키우는 배수 (그림은 nearest 로 키운다)
@export var home_button_size: Vector2 = Vector2(300.0, 300.0)
@export var home_font_size: int = 30
@export var home_picture_scale: int = 3
## 집 안 배경을 집 색보다 얼마나 어둡게 할지 (0 ~ 1)
@export_range(0.0, 1.0) var backdrop_darken: float = 0.35
@export var reply_font_size: int = 36
@export var reply_button_height: float = 72.0
## 단골도가 오를 때 "♥ +2"가 떠오르는 높이(픽셀), 시간(초), 글자 크기, 색
@export var pop_rise: float = 90.0
@export var pop_duration: float = 0.9
@export var pop_font_size: int = 40
@export var pop_color: Color = Color(1, 0.55, 0.6)

var _settings: VillageSettings
var _guest: AnimalGuest
var _visit_count: int = 0
## 지금 대답을 기다리는 집 이야기 (없으면 null)
var _current_talk: EveningTalk
## 선물 고르기에 띄운 재료 (대답 버튼과 같은 순서. 마지막 "선물 없이"는 들어 있지 않다)
var _gift_choices: Array[Ingredient] = []
## "다음"을 누르면 할 일
var _next_step: Callable

@onready var _day_label: Label = %DayLabel
@onready var _home_row: HBoxContainer = %HomeRow
@onready var _backdrop: ColorRect = %HomeBackdrop
@onready var _guest_spot: GuestSpot = %GuestSpot
@onready var _reply_box: VBoxContainer = %ReplyBox
@onready var _next_button: Button = %NextButton
@onready var _status_label: Label = %StatusLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	RainOverlay.apply_daytime(self, true)
	_settings = GameData.get_village_settings()
	_day_label.text = DAY_TEXT_FORMAT % [GameData.get_season_name(), GameState.current_day]
	_backdrop.hide()
	_guest_spot.clear()
	_reply_box.hide()
	_next_button.hide()
	_next_button.pressed.connect(_on_next_pressed)
	_back_button.pressed.connect(get_tree().change_scene_to_file.bind(garden_scene_path))
	var buttons: Array[Button] = _add_home_buttons()
	if GameState.can_visit_home_today():
		_set_status(_settings.choose_text)
	else:
		_set_status(_settings.visited_text)
	_keep_focus_in_row(buttons)
	var first_open: Array[Button] = buttons.filter(func(button: Button) -> bool: return not button.disabled)
	(first_open[0] if not first_open.is_empty() else _back_button).grab_focus()


## 지금 계절 손님마다 집 버튼 하나. 못 만난 손님은 "?", 오늘 더 들를 수 없으면 모두 막는다.
func _add_home_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	var can_visit: bool = GameState.can_visit_home_today()
	for guest: AnimalGuest in GameData.get_season_guests():
		var button: Button = Button.new()
		button.custom_minimum_size = home_button_size
		button.add_theme_font_size_override("font_size", home_font_size)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		var is_known: bool = GameState.has_met_guest(guest.id)
		button.text = _home_name(guest) if is_known else _settings.unknown_home_text
		button.icon = _home_icon(guest, is_known)
		button.disabled = not is_known or not can_visit
		button.pressed.connect(_visit.bind(guest))
		_home_row.add_child(button)
		buttons.append(button)
	return buttons


func _home_name(guest: AnimalGuest) -> String:
	return guest.home_name if not guest.home_name.is_empty() else HOME_NAME_FORMAT % guest.display_name


## 집 그림 (원본을 home_picture_scale 배로). 그림이 없거나 못 만난 손님이면 집 색(못 만났으면 회색) 임시 사각형.
func _home_icon(guest: AnimalGuest, is_known: bool) -> ImageTexture:
	var image: Image
	if is_known and guest.home_picture != null:
		image = guest.home_picture.get_image().duplicate()
		if image.is_compressed():
			image.decompress()
		image.resize(image.get_width() * home_picture_scale, image.get_height() * home_picture_scale, Image.INTERPOLATE_NEAREST)
	else:
		var side: int = int(home_button_size.x * 0.6)
		image = Image.create(side, side, false, Image.FORMAT_RGBA8)
		image.fill(guest.home_color if is_known else Color(0.55, 0.55, 0.55))
	return ImageTexture.create_from_image(image)


## 집에 들른다: 마을 길을 숨기고 집 안에서 손님이 인사한다.
func _visit(guest: AnimalGuest) -> void:
	_guest = guest
	_visit_count = GameState.visit_home(guest.id)
	_home_row.hide()
	_back_button.hide()
	_backdrop.color = guest.home_color.darkened(backdrop_darken)
	_backdrop.show()
	_set_status(_home_name(guest))
	var greeting: String = ""
	if not guest.home_greeting_lines.is_empty():
		greeting = guest.home_greeting_lines[(_visit_count - 1) % guest.home_greeting_lines.size()]
	_guest_spot.show_guest(guest, _with_name(greeting), false, AnimalGuest.EXPRESSION_HAPPY)
	_next_step = _tell_home_talk
	_show_next()


## 집 이야기: 들를 때마다 순서대로 하나. 이야기가 없으면 바로 선물 고르기.
func _tell_home_talk() -> void:
	if _guest.home_talks.is_empty():
		_offer_gift()
		return
	_current_talk = _guest.home_talks[(_visit_count - 1) % _guest.home_talks.size()]
	_guest_spot.say(_with_name(_current_talk.line), _current_talk.expression)
	if _current_talk.replies.is_empty():
		_current_talk = null
		_next_step = _offer_gift
		_show_next()
		return
	_show_replies(_current_talk.replies, _on_talk_reply)


func _on_talk_reply(index: int) -> void:
	var reactions: Array[String] = _current_talk.reactions
	if not reactions.is_empty():
		var i: int = mini(index, reactions.size() - 1)
		var expression: StringName = _current_talk.reaction_expressions[i] \
				if i < _current_talk.reaction_expressions.size() else AnimalGuest.EXPRESSION_DEFAULT
		_guest_spot.say(_with_name(reactions[i]), expression)
	_current_talk = null
	_next_step = _offer_gift
	_show_next()


## 남는 재료 중 gift_amount 개 이상 있는 것을 선물로 고른다. 맨 아래는 선물 없이 가기.
func _offer_gift() -> void:
	_set_status(_settings.gift_prompt_text)
	_gift_choices.clear()
	var texts: Array[String] = []
	for ingredient: Ingredient in GameData.get_all_ingredients():
		if GameState.get_ingredient_count(ingredient.id) >= _settings.gift_amount:
			_gift_choices.append(ingredient)
			texts.append(GIFT_REPLY_FORMAT % [ingredient.display_name, _settings.gift_amount])
	texts.append(_settings.no_gift_reply)
	_show_replies(texts, _on_gift_chosen, false)


func _on_gift_chosen(index: int) -> void:
	_set_status("")
	if index >= _gift_choices.size():
		_finish_visit()
		return
	var gift: Ingredient = _gift_choices[index]
	GameState.remove_ingredient(gift.id, _settings.gift_amount)
	var is_favorite: bool = _guest.favorite_gift != null and _guest.favorite_gift.id == gift.id
	var points: int = _settings.favorite_gift_points if is_favorite else _settings.gift_points
	var line: String = _guest.favorite_gift_line if is_favorite else _guest.gift_thanks_line
	if line.is_empty():
		line = _settings.default_gift_thanks_line
	Sound.play(GIFT_SOUND)
	_guest_spot.say(_with_name(line.format({"ingredient": gift.display_name})),
			AnimalGuest.EXPRESSION_HAPPY if is_favorite else AnimalGuest.EXPRESSION_DEFAULT)
	FloatingText.pop(self, AFFECTION_POP_FORMAT % points, _guest_spot, pop_rise, pop_duration, pop_font_size, pop_color)
	var new_tier: int = GameState.add_affection(_guest.id, points)
	if new_tier >= 0:
		var tier_name: String = GameData.get_regular_settings().get_tier_name(new_tier)
		_set_status(TIER_UP_FORMAT % [_guest.display_name, Korean.with_particle(_guest.display_name), tier_name])
	_finish_visit()


## 다 들렀으면 텃밭으로 돌아가는 버튼만 남긴다.
func _finish_visit() -> void:
	_reply_box.hide()
	_next_button.hide()
	_back_button.show()
	_back_button.grab_focus()


func _show_next() -> void:
	_reply_box.hide()
	_next_button.show()
	_next_button.grab_focus()


func _on_next_pressed() -> void:
	_next_button.hide()
	_next_step.call()


## 대답(또는 선물) 버튼을 띄운다. 고르면 on_chosen(번호). quoted: 주인공이 하는 말이면 따옴표로 감싼다.
func _show_replies(texts: Array[String], on_chosen: Callable, quoted: bool = true) -> void:
	for child: Node in _reply_box.get_children():
		_reply_box.remove_child(child)
		child.queue_free()
	var buttons: Array[Button] = []
	for i: int in texts.size():
		var button: Button = Button.new()
		button.text = REPLY_FORMAT % texts[i] if quoted else texts[i]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = reply_button_height
		button.add_theme_font_size_override("font_size", reply_font_size)
		button.pressed.connect(on_chosen.bind(i))
		_reply_box.add_child(button)
		buttons.append(button)
	# 대답 버튼 사이에서만 위아래로 돈다 (뒤쪽 버튼으로 빠지지 않게)
	for i: int in buttons.size():
		var button: Button = buttons[i]
		button.focus_neighbor_top = button.get_path_to(buttons[i - 1])
		button.focus_neighbor_bottom = button.get_path_to(buttons[(i + 1) % buttons.size()])
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
	_next_button.hide()
	_reply_box.show()
	buttons[0].grab_focus()


## 좌우로 집 버튼 사이를 돌고, 아래로 가면 돌아가기 버튼 (게임패드)
func _keep_focus_in_row(buttons: Array[Button]) -> void:
	var open: Array[Button] = buttons.filter(func(button: Button) -> bool: return not button.disabled)
	for i: int in open.size():
		var button: Button = open[i]
		button.focus_neighbor_left = button.get_path_to(open[i - 1])
		button.focus_neighbor_right = button.get_path_to(open[(i + 1) % open.size()])
		button.focus_neighbor_bottom = button.get_path_to(_back_button)
	if not open.is_empty():
		_back_button.focus_neighbor_top = _back_button.get_path_to(open[0])


func _set_status(text: String) -> void:
	_status_label.text = text


## 글 속 {name} 을 주인공 이름으로 바꾼다.
func _with_name(text: String) -> String:
	return text.format({"name": GameState.player_name})
