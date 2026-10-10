extends Control
## 아침 마을 길 장면. 텃밭에서 건너와 이웃 손님의 집 중 하루에 한 곳(VillageSettings.visits_per_day)에 들른다.
## 할머니가 그린 마을 지도(VillageMap) 위에 손님 집이 자리(AnimalGuest.home_map_position)마다 놓이고,
## 집 이름 아래에 단골 하트, 오늘 들른 집에는 도장이 붙는다.
## 밥집에서 만난 손님의 집만 갈 수 있고, 못 만난 손님 집은 "?"로 가려 둔다.
## 집에 들르면 인사 → 집 이야기(대답 고르기) → 남는 재료를 선물로 두고 오기(단골도). 선물은 안 해도 된다.
## 손님마다 집 이름·인사·이야기·좋아하는 선물은 손님 데이터(AnimalGuest 의 "마을 길 집")에 있다.

const DAY_TEXT_FORMAT: String = "%s %d일째 · 마을 길"
const HOME_NAME_FORMAT: String = "%s네 집"
const GIFT_REPLY_FORMAT: String = "%s %d개 드리기"
const TIER_UP_FORMAT: String = "%s%s 더 가까워졌어요 · %s"
const AFFECTION_POP_FORMAT: String = "♥ +%d"
const REPLY_FORMAT: String = "\"%s\""
const HEART_FULL: String = "♥"
const HEART_EMPTY: String = "♡"
## 효과음 이름 (data/sounds/ 의 id)
const GIFT_SOUND: StringName = &"receive"

## 돌아갈 당근 텃밭 장면
@export_file("*.tscn") var garden_scene_path: String = "res://scenes/garden/garden.tscn"
## 집 버튼 크기와 글자 크기, 집 그림을 키우는 배수 (그림은 nearest 로 키운다)
@export var home_button_size: Vector2 = Vector2(240.0, 240.0)
@export var home_font_size: int = 30
@export var home_picture_scale: int = 3
## 지도 원본(640x360) 픽셀을 화면 픽셀로 키우는 배수
@export var map_scale: float = 3.0
## 지도 위 이름 글자 색과 테두리 (종이 위에서도 잘 읽히게)
@export var map_text_color: Color = Color(0.32, 0.22, 0.14)
@export var map_text_outline_color: Color = Color(1.0, 0.97, 0.88)
@export var map_text_outline_size: int = 10
## 막힌 집(못 만났거나 오늘 이미 다른 집에 들름) 이름 글자 색
@export var map_text_disabled_color: Color = Color(0.32, 0.22, 0.14, 0.6)
## 단골 하트 글자 크기와 색
@export var heart_font_size: int = 26
@export var heart_color: Color = Color(0.86, 0.38, 0.45)
## 오늘 들른 집 도장: 글자 크기, 색, 기울기(도)
@export var stamp_font_size: int = 28
@export var stamp_color: Color = Color(0.8, 0.25, 0.22)
@export var stamp_tilt_degrees: float = -12.0
## 할매식당 이름표 글자 크기와, 식당 자리에서 아래로 내린 거리(화면 픽셀)
@export var restaurant_font_size: int = 30
@export var restaurant_label_drop: float = 70.0
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
@onready var _map: VillageMap = %MapPicture
@onready var _home_map: Control = %HomeMap
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
	var guests: Array[AnimalGuest] = GameData.get_season_guests()
	var points: Array[Vector2] = _home_points(guests)
	var known: Array[bool] = []
	for guest: AnimalGuest in guests:
		known.append(GameState.has_met_guest(guest.id))
	var buttons: Array[Button] = _add_home_buttons(guests, points)
	var rects: Array[Rect2] = []
	for button: Button in buttons:
		var rect: Rect2 = button.get_rect()
		for child: Node in button.get_children():
			rect = rect.merge(Rect2(button.position + (child as Control).position, (child as Control).size))
		rects.append(rect)
	_map.setup(_settings.map_picture, map_scale, _settings.restaurant_map_position, points, known, rects)
	_add_restaurant_label()
	if GameState.can_visit_home_today():
		_set_status(_settings.choose_text)
	else:
		_set_status(_settings.visited_text)
	_link_focus_by_direction(buttons)
	var first_open: Array[Button] = buttons.filter(func(button: Button) -> bool: return not button.disabled)
	(first_open[0] if not first_open.is_empty() else _back_button).grab_focus()


## 손님마다 지도 위 집 자리 (원본 픽셀). 자리가 비어 있으면 할매식당 둘레에 고르게 놓는다.
func _home_points(guests: Array[AnimalGuest]) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i: int in guests.size():
		var point: Vector2 = guests[i].home_map_position
		if point.x < 0.0 or point.y < 0.0:
			var angle: float = TAU * float(i) / float(guests.size()) - PI * 0.5
			point = _settings.restaurant_map_position + Vector2(cos(angle), sin(angle)) * _settings.auto_home_radius
		points.append(point)
	return points


func _add_restaurant_label() -> void:
	var label: Label = _map_label(_settings.restaurant_name, restaurant_font_size)
	_map.add_child(label)
	label.reset_size()
	label.position = _settings.restaurant_map_position * map_scale + Vector2(-label.size.x * 0.5, restaurant_label_drop)


## 지금 계절 손님마다 지도 위 자리에 집 버튼 하나. 못 만난 손님은 "?", 오늘 더 들를 수 없으면 모두 막는다.
func _add_home_buttons(guests: Array[AnimalGuest], points: Array[Vector2]) -> Array[Button]:
	var buttons: Array[Button] = []
	var can_visit: bool = GameState.can_visit_home_today()
	for i: int in guests.size():
		var guest: AnimalGuest = guests[i]
		var button: Button = Button.new()
		button.flat = true
		button.custom_minimum_size = home_button_size
		button.add_theme_font_size_override("font_size", home_font_size)
		_outline_text(button, true)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		var is_known: bool = GameState.has_met_guest(guest.id)
		button.text = _home_name(guest) if is_known else _settings.unknown_home_text
		button.icon = _home_icon(guest, is_known)
		button.disabled = not is_known or not can_visit
		if button.disabled:
			button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_visit.bind(guest))
		_home_map.add_child(button)
		button.reset_size()
		button.position = points[i] * map_scale - button.size * 0.5
		if is_known:
			_add_hearts(button, guest)
		if guest.id in GameState.todays_visited_home_ids:
			_add_stamp(button)
		buttons.append(button)
	return buttons


## 집 이름 아래 단골 하트 (손님 수첩과 같은 모양: 단계만큼 찬 하트)
func _add_hearts(button: Button, guest: AnimalGuest) -> void:
	var tier: int = GameState.get_regular_tier(guest.id)
	var max_tier: int = GameData.get_regular_settings().tier_names.size() - 1
	var label: Label = _map_label(HEART_FULL.repeat(tier) + HEART_EMPTY.repeat(maxi(max_tier - tier, 0)), heart_font_size)
	label.add_theme_color_override("font_color", heart_color)
	button.add_child(label)
	label.reset_size()
	label.position = Vector2((button.size.x - label.size.x) * 0.5, button.size.y)


## 오늘 들른 집 그림 위에 비스듬한 도장 글
func _add_stamp(button: Button) -> void:
	var label: Label = _map_label(_settings.visited_stamp_text, stamp_font_size)
	label.add_theme_color_override("font_color", stamp_color)
	button.add_child(label)
	label.reset_size()
	label.pivot_offset = label.size * 0.5
	label.rotation_degrees = stamp_tilt_degrees
	label.position = Vector2((button.size.x - label.size.x) * 0.5, button.size.y * 0.3)


## 지도 위에 얹는 글 (마우스는 통과)
func _map_label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	_outline_text(label, false)
	return label


## 종이 지도 위에서도 읽히게 글자에 밝은 테두리. is_button 이면 눌림·막힘 상태 글자 색도 맞춘다.
func _outline_text(control: Control, is_button: bool) -> void:
	control.add_theme_color_override("font_color", map_text_color)
	control.add_theme_color_override("font_outline_color", map_text_outline_color)
	control.add_theme_constant_override("outline_size", map_text_outline_size)
	if is_button:
		for state: StringName in [&"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
			control.add_theme_color_override(state, map_text_color)
		control.add_theme_color_override("font_disabled_color", map_text_disabled_color)


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
	_home_map.hide()
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


## 게임패드: 십자키를 누르면 그 방향에 있는 가장 가까운 집으로 (옆으로 많이 비켜난 집일수록 멀게 친다).
## 아래쪽에 집이 없으면 돌아가기 버튼으로, 돌아가기 버튼에서 위로 가면 가장 가까운 집으로.
func _link_focus_by_direction(buttons: Array[Button]) -> void:
	var open: Array[Button] = buttons.filter(func(button: Button) -> bool: return not button.disabled)
	var sides: Array[Vector2] = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN]
	for button: Button in open:
		for side: int in sides.size():
			var target: Control = _nearest_toward(button, open, sides[side])
			if target == null:
				target = _back_button if sides[side] == Vector2.DOWN else button
			button.set_focus_neighbor(side as Side, button.get_path_to(target))
	if open.is_empty():
		return
	var nearest: Control = _nearest_toward(_back_button, open, Vector2.UP)
	_back_button.focus_neighbor_top = _back_button.get_path_to(nearest if nearest != null else open[0])
	_back_button.focus_neighbor_left = _back_button.get_path_to(_back_button)
	_back_button.focus_neighbor_right = _back_button.get_path_to(_back_button)


## from 에서 direction 쪽(앞쪽 거리보다 옆으로 두 배 넘게 비켜나지 않은 것)에 있는 가장 가까운 버튼. 없으면 null.
func _nearest_toward(from: Control, candidates: Array[Button], direction: Vector2) -> Control:
	var center: Vector2 = from.get_global_rect().get_center()
	var best: Control = null
	var best_score: float = INF
	for candidate: Button in candidates:
		if candidate == from:
			continue
		var offset: Vector2 = candidate.get_global_rect().get_center() - center
		var ahead: float = offset.dot(direction)
		var aside: float = absf(offset.cross(direction))
		if ahead <= 0.0 or aside > ahead * 2.0:
			continue
		var score: float = ahead + aside * 2.0
		if score < best_score:
			best_score = score
			best = candidate
	return best


func _set_status(text: String) -> void:
	_status_label.text = text


## 글 속 {name} 을 주인공 이름으로 바꾼다.
func _with_name(text: String) -> String:
	return text.format({"name": GameState.player_name})
