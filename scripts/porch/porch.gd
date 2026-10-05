extends Control
## 저녁 평상 장면. 오늘 대접한 손님 중 한 명이 찾아와 이야기를 하고, 대답을 골라 주면 손님이 반응한다.
## 단골 보상이나 사연 막을 기다리는 손님이 더 있으면 max_evening_guests 명까지 이어서 찾아온다.
## 계절 잔치 준비를 알려 주는 날(FeastPrep.announce_day)에는 알려 줄 손님이 맨 먼저 와서 장보기 목록을 준다.
## 손님은 옆에서 걸어 들어와 평상에 앉고, 평상에 처음 온 손님은 인사(porch_greeting_line)부터 한다.
## 단골 단계가 오른 손님이면 그 단계의 새 이야기를 나누고 단골 선물을 건넨다.
## 사연(AnimalGuest.story_chapters)의 다음 막이 열렸으면 평소 이야기 대신 그 막을 한다.
## 손님끼리 대화(DuoTalkBook)가 열렸으면 첫 손님 이야기 뒤에 다른 손님이 옆에 와 앉아 둘이 이야기한다 (주인공은 듣기만).
## 이미 되찾은 레시피의 할머니 비법을 아는 손님이면 비법을 알려 준다.
## 돌려줄 할머니 레시피 노트 페이지가 있으면 건네준다. 다 듣고 나면 잠자리에 들어 다음 날 아침 텃밭으로 간다.
## 장면은 "다음" 버튼을 누를 때마다 한 단계씩 진행한다. 대답을 고르는 동안에는 "다음" 버튼이 숨는다.

const DAY_TEXT_FORMAT: String = "%s %d일째 저녁"
const QUIET_EVENING_TEXT: String = "오늘 저녁은 조용하네요. 별이 참 많아요."
const NOTE_FOUND_TEXT: String = "할머니 레시피 노트 한 장을 되찾았어요!"
const SECRET_LEARNED_FORMAT: String = "할머니 비법을 알았어요!  ★ %s"
const GIFT_INGREDIENT_FORMAT: String = "단골 선물을 받았어요!  %s ×%d"
const GIFT_PLOT_FORMAT: String = "단골 선물!  %s에 칸이 하나 늘었어요"
const GIFT_KEEPSAKE_FORMAT: String = "할머니의 기념품을 받았어요!  「%s」"
const GIFT_SEPARATOR: String = "\n"
const NOTE_INGREDIENTS_FORMAT: String = "재료: %s"
const NOTE_INGREDIENT_SEPARATOR: String = ", "
const FALLBACK_STORY_LINE: String = "오늘도 잘 먹었어요."
const REPLY_FORMAT: String = "▸ %s"
const NEXT_TEXT: String = "다음"
const SLEEP_TEXT: String = "잠자리에 들기"
## 효과음 이름 (data/sounds/ 의 id)
const SECRET_SOUND: StringName = &"secret"
const GIFT_SOUND: StringName = &"gift"
const NOTE_PAGE_SOUND: StringName = &"note_page"

## 날마다 바뀌는 배경음악 (하루 동안은 한 곡. 텃밭·원목·부엌·평상이 같은 곡이라 장면이 바뀌어도 끊기지 않는다).
## 비워 두면 지금 계절의 곡 목록(SeasonData.daily_music)을 쓴다. 장터와 계절 마무리는 따로 곡이 있다.
@export var daily_music: DailyMusic
## 잠자리에 든 뒤 넘어갈 다음 날 아침 장면
@export_file("*.tscn") var morning_scene_path: String = "res://scenes/garden/garden.tscn"
## 잠드는 장면 (할머니 꿈 한 줄, 저장, 아침으로 밝아지기)
@export var sleep_transition_scene: PackedScene = preload("res://scenes/ui/sleep_transition.tscn")
## 할머니 회상 장면 목록 (노트를 3·6·9장 되찾은 날 밤, 손님 사연을 다 본 날 밤에 하나씩)
@export var memory_book: MemoryBook = preload("res://data/story/memories.tres")
## 노트 카드가 뜰 때 커졌다 돌아오는 정도와 시간(초)
@export var note_pop_scale: float = 1.1
@export var note_pop_duration: float = 0.2
@export var reply_font_size: int = 36
@export var reply_button_height: float = 72.0
## 손님끼리 대화 목록
@export var duo_book: DuoTalkBook = preload("res://data/story/porch_duos.tres")
## 저녁에 찾아오는 손님 수의 최대. 첫 손님 다음 손님들은 단골 보상이나 사연 막을 기다리는 손님만 온다.
@export var max_evening_guests: int = 2

## 버튼을 누를 때마다 하나씩 실행할 장면 단계
var _beats: Array[Callable] = []
var _evening_guest: AnimalGuest
## 오늘 저녁 평상에 온 손님 id (잠들 때 이웃 바구니에 넘긴다)
var _met_tonight_ids: Array[StringName] = []
## 지금 대답을 기다리는 대화 (없으면 null)
var _current_talk: EveningTalk

@onready var _day_label: Label = %DayLabel
@onready var _guest_spot: GuestSpot = %GuestSpot
## 손님끼리 대화할 때 옆에 와 앉는 손님 자리 (말풍선이 머리 위)
@onready var _side_spot: GuestSpot = %SideGuestSpot
@onready var _status_label: Label = %StatusLabel
@onready var _note_card: Control = %NoteCard
@onready var _note_recipe_label: Label = %NoteRecipeLabel
@onready var _note_ingredients_label: Label = %NoteIngredientsLabel
@onready var _next_button: Button = %NextButton
@onready var _reply_box: VBoxContainer = %ReplyBox
@onready var _notebook: GuestNotebook = %GuestNotebook
@onready var _notebook_button: Button = %NotebookButton


func _ready() -> void:
	var music: DailyMusic = daily_music if daily_music != null else GameData.get_daily_music()
	Sound.play_music(music.get_today_track(false) if music != null else null)
	# 낮에 깔리던 빗소리가 남아 있으면 끈다 (봄비는 해 질 녘에 그친다).
	Sound.stop_loop(GameData.get_rain_settings().rain_sound)
	_day_label.text = DAY_TEXT_FORMAT % [GameData.get_season_name(), GameState.current_day]
	_note_card.hide()
	_reply_box.hide()
	_status_label.text = ""
	_next_button.pressed.connect(_on_next_button_pressed)
	_notebook_button.pressed.connect(_notebook.open)
	_add_feast_announcement_beats()
	var first_guest: AnimalGuest = _choose_evening_guest()
	if first_guest == null:
		_beats.append(func() -> void: _status_label.text = QUIET_EVENING_TEXT)
	else:
		_add_guest_beats(first_guest, true)
		var duo: GuestDuoTalk = _choose_duo_talk(first_guest)
		if duo != null:
			# 대화하러 온 손님이 두 번째 손님이 된다. 기다리는 단골 보상이나 사연 막이 있으면 대화 뒤에 이어서 한다.
			var partner: AnimalGuest = GameData.get_guest(duo.get_partner_id(first_guest.id))
			_add_duo_beats(duo, first_guest, partner)
			if _has_waiting_beats(partner):
				_add_guest_beats(partner, false)
		else:
			for guest: AnimalGuest in _choose_extra_guests(first_guest):
				_add_guest_beats(guest, false)
	_run_next_beat()
	if _next_button.visible:
		_next_button.grab_focus()


func _on_next_button_pressed() -> void:
	if _beats.is_empty():
		_go_to_sleep()
	else:
		_run_next_beat()


func _run_next_beat() -> void:
	var beat: Callable = _beats.pop_front()
	beat.call()
	_next_button.text = SLEEP_TEXT if _beats.is_empty() else NEXT_TEXT


## 손님 한 명이 평상에서 할 일을 단계(beat)로 쌓는다: 단골 보상 → 사연 막 (둘 다 없으면 평소 이야기) → 할머니 비법 → 레시피 노트.
## is_first 가 아니면(이어서 온 손님) 단골 보상과 사연 막만 한다. 첫 단계에서 지금 손님을 이 손님으로 바꾼다.
func _add_guest_beats(guest: AnimalGuest, is_first: bool) -> void:
	var guest_beats: Array[Callable] = []
	if _needs_greeting(guest):
		guest_beats.append(_guest_spot.show_guest.bind(guest, _with_name(guest.porch_greeting_line), false, AnimalGuest.EXPRESSION_HAPPY))
	var reward_tier: int = GameState.get_pending_reward_tier(guest.id)
	var reward: RegularReward = guest.get_regular_reward(reward_tier)
	if reward != null:
		guest_beats.append(_tell_talk.bind(reward.talk))
		guest_beats.append(func() -> void: _guest_spot.say(reward.gift_line.format({"name": GameState.player_name}), AnimalGuest.EXPRESSION_HAPPY))
		guest_beats.append(_receive_gift.bind(reward_tier, reward))
	elif reward_tier >= 0:
		GameState.finish_reward_tier(guest.id, reward_tier)
	var chapter: GuestStoryChapter = GameState.get_next_story_chapter(guest)
	if chapter != null and not chapter.talks.is_empty():
		for i: int in chapter.talks.size():
			var talk: EveningTalk = chapter.talks[i]
			if i == 0:
				guest_beats.append(func() -> void:
					GameState.see_story_chapter(chapter.id)
					_tell_talk(talk))
			else:
				guest_beats.append(_tell_talk.bind(talk))
	elif reward == null:
		guest_beats.append(_tell_story)
	if is_first:
		var secret: Recipe = _next_secret(guest)
		if secret != null:
			guest_beats.append(func() -> void: _guest_spot.say(secret.secret_reveal_line.format({"name": GameState.player_name})))
			guest_beats.append(func() -> void: _learn_secret(secret))
		var page: Recipe = _next_note_page(guest)
		if page != null:
			guest_beats.append(func() -> void: _guest_spot.say(guest.note_line.format({"recipe": page.display_name}), AnimalGuest.EXPRESSION_HAPPY))
			guest_beats.append(func() -> void: _receive_note_page(page))
	var first_beat: Callable = guest_beats[0]
	guest_beats[0] = func() -> void:
		_switch_guest(guest)
		first_beat.call()
	_beats.append_array(guest_beats)


## 잔치 준비를 알려 주는 날이면 (그날 대접하지 않았어도) 알려 줄 손님이 먼저 와서 장보기 목록을 준다.
## 마지막 단계에서 목록을 받은 것으로 기록한다.
func _add_feast_announcement_beats() -> void:
	var ending: SeasonEnding = GameData.get_season_ending()
	var prep: FeastPrep = ending.feast_prep if ending != null else null
	if prep == null or GameState.is_feast_prep_announced or GameState.current_day < prep.announce_day:
		return
	var announcer: AnimalGuest = GameData.get_guest(prep.announcer_id)
	if announcer != null:
		var lines: Array[String] = []
		if _needs_greeting(announcer):
			lines.append(_with_name(announcer.porch_greeting_line))
		for line: String in prep.announce_lines:
			lines.append(_with_name(line))
		for i: int in lines.size():
			var line: String = lines[i]
			if i == 0:
				_beats.append(func() -> void:
					_switch_guest(announcer)
					_guest_spot.show_guest(announcer, line))
			else:
				_beats.append(_guest_spot.say.bind(line))
	_beats.append(func() -> void:
		GameState.is_feast_prep_announced = true
		GameState.feast_prep_changed.emit()
		Sound.play(GIFT_SOUND)
		_status_label.text = prep.announced_status_text)


## 다음 손님으로 바꾼다. 앞 손님이 남긴 아래 글과 노트 카드는 치운다. 옆에 앉았던 손님은 사라진다.
func _switch_guest(guest: AnimalGuest) -> void:
	if _side_spot.visible:
		_side_spot.fade_out()
	_evening_guest = guest
	if guest.id not in _met_tonight_ids:
		_met_tonight_ids.append(guest.id)
	_status_label.text = ""
	_note_card.hide()
	if guest.id not in GameState.porch_met_guest_ids:
		GameState.porch_met_guest_ids.append(guest.id)
	_guest_spot.walk_in()


## 오늘 저녁 손님끼리 대화: 첫 손님이 낀 대화 중, 다른 손님도 오늘 대접했고 평상에 와 본 적 있는 손님인 것. 없으면 null.
## 사연 막을 기다리는 다른 손님이 있으면 그 손님과의 대화만 고른다 (대화하러 온 손님이 사연 손님 자리를 빼앗지 않게).
func _choose_duo_talk(first_guest: AnimalGuest) -> GuestDuoTalk:
	if duo_book == null:
		return null
	var others: Array[AnimalGuest] = _todays_served_guests().filter(func(guest: AnimalGuest) -> bool:
			return guest != first_guest and guest.id in GameState.porch_met_guest_ids)
	var with_chapter: Array[AnimalGuest] = others.filter(
			func(guest: AnimalGuest) -> bool: return GameState.get_next_story_chapter(guest) != null)
	var served_ids: Array[StringName] = []
	for guest: AnimalGuest in (with_chapter if not with_chapter.is_empty() else others):
		served_ids.append(guest.id)
	return duo_book.get_ready(GameState.current_season, GameState.current_day, first_guest.id, served_ids,
			GameState.seen_duo_talk_ids, GameState.seen_story_chapter_ids)


## 손님끼리 대화: 다른 손님이 옆에 스르륵 와 앉고, 한 줄씩 번갈아 말한다. 말하는 손님만 말풍선이 뜨고 듣는 손님은 조금 어두워진다.
func _add_duo_beats(duo: GuestDuoTalk, first_guest: AnimalGuest, partner: AnimalGuest) -> void:
	for i: int in duo.lines.size():
		var line: DuoLine = duo.lines[i]
		if i == 0:
			_beats.append(func() -> void:
				GameState.seen_duo_talk_ids.append(duo.id)
				if partner.id not in _met_tonight_ids:
					_met_tonight_ids.append(partner.id)
				_status_label.text = ""
				_note_card.hide()
				_side_spot.show_guest(partner, "")
				_side_spot.fade_in(false)
				_say_duo_line(line, first_guest))
		else:
			_beats.append(_say_duo_line.bind(line, first_guest))


func _say_duo_line(line: DuoLine, first_guest: AnimalGuest) -> void:
	var is_first_speaking: bool = line.speaker == first_guest.id
	var speaker: GuestSpot = _guest_spot if is_first_speaking else _side_spot
	var listener: GuestSpot = _side_spot if is_first_speaking else _guest_spot
	speaker.say(_with_name(line.text), line.expression)
	speaker.set_bubble_shown(true)
	speaker.set_listening(false)
	listener.set_bubble_shown(false)
	listener.set_listening(true)


## 평상에 처음 온 손님이면 인사부터 한다 (인사 글이 있을 때).
func _needs_greeting(guest: AnimalGuest) -> bool:
	return guest.id not in GameState.porch_met_guest_ids and not guest.porch_greeting_line.is_empty()


## 첫 손님 다음에 이어서 올 손님: 오늘 대접한 손님 중 단골 보상이나 사연 막을 기다리는 손님 (max_evening_guests - 1 명까지).
## 사연 막을 기다리는 손님이 먼저 온다 (사연은 계절이 끝나면 못 보지만, 단골 보상은 다음에 받아도 되니까).
func _choose_extra_guests(first_guest: AnimalGuest) -> Array[AnimalGuest]:
	var waiting: Array[AnimalGuest] = _todays_served_guests().filter(
			func(guest: AnimalGuest) -> bool: return guest != first_guest and _has_waiting_beats(guest))
	waiting.shuffle()
	var with_chapter: Array[AnimalGuest] = waiting.filter(
			func(guest: AnimalGuest) -> bool: return GameState.get_next_story_chapter(guest) != null)
	var others: Array[AnimalGuest] = waiting.filter(func(guest: AnimalGuest) -> bool: return guest not in with_chapter)
	return (with_chapter + others).slice(0, maxi(max_evening_guests - 1, 0))


func _todays_served_guests() -> Array[AnimalGuest]:
	var served: Array[AnimalGuest] = []
	for guest_id: StringName in GameState.todays_served_guests:
		var guest: AnimalGuest = GameData.get_guest(guest_id)
		if guest != null:
			served.append(guest)
	return served


## 단골 보상이나 사연 막을 기다리는 손님인지
func _has_waiting_beats(guest: AnimalGuest) -> bool:
	return GameState.get_pending_reward_tier(guest.id) >= 0 or GameState.get_next_story_chapter(guest) != null


## 첫 손님: 오늘 대접한 손님 중 한 명. 완벽하게 대접한 손님 중에서 돌려줄 레시피 노트나 알려 줄 할머니 비법이 남은 손님을
## 먼저 고르고 (그중에서도 단골 보상이나 사연 막을 기다리는 손님 먼저), 그런 손님이 없으면 단골 보상이나 사연 막을 기다리는 손님을 고른다.
## 기다리는 다른 손님은 _choose_extra_guests 가 두 번째 손님으로 부른다. 아무도 없으면 null.
func _choose_evening_guest() -> AnimalGuest:
	var served: Array[AnimalGuest] = _todays_served_guests()
	if served.is_empty():
		return null
	var perfect: Array[AnimalGuest] = served.filter(
			func(guest: AnimalGuest) -> bool: return GameState.todays_served_guests[guest.id])
	var candidates: Array[AnimalGuest] = perfect if not perfect.is_empty() else served
	var with_page: Array[AnimalGuest] = candidates.filter(
			func(guest: AnimalGuest) -> bool: return _next_note_page(guest) != null or _next_secret(guest) != null)
	if not with_page.is_empty():
		var with_page_and_waiting: Array[AnimalGuest] = with_page.filter(_has_waiting_beats)
		return (with_page_and_waiting if not with_page_and_waiting.is_empty() else with_page).pick_random()
	var with_waiting: Array[AnimalGuest] = served.filter(_has_waiting_beats)
	if not with_waiting.is_empty():
		return with_waiting.pick_random()
	return candidates.pick_random()


## 손님이 아직 돌려주지 않은 첫 번째 레시피 노트 페이지. 없으면 null.
func _next_note_page(guest: AnimalGuest) -> Recipe:
	for recipe: Recipe in guest.note_recipes:
		if recipe.note_season == GameState.current_season and not GameState.is_recipe_unlocked(recipe.id):
			return recipe
	return null


## 이 손님이 알려 줄 할머니 비법: 이미 되찾았고 아직 비법을 모르는 레시피 중 이 손님이 알려 주는 것. 없으면 null.
func _next_secret(guest: AnimalGuest) -> Recipe:
	for recipe: Recipe in GameData.get_all_recipes():
		if recipe.secret_teller_id == guest.id and not recipe.secret_hint.is_empty() \
				and GameState.is_recipe_unlocked(recipe.id) and not GameState.is_secret_learned(recipe.id):
			return recipe
	return null


func _learn_secret(recipe: Recipe) -> void:
	GameState.learn_secret(recipe.id)
	Sound.play(SECRET_SOUND)
	_status_label.text = SECRET_LEARNED_FORMAT % recipe.secret_hint


## 찾아올 때마다 대화를 하나씩 순서대로 나눈다. 다 나누면 처음부터 다시.
## 대답이 있는 대화면 대답 버튼을 띄우고, 고를 때까지 "다음" 버튼을 숨긴다.
func _tell_story() -> void:
	var talks: Array[EveningTalk] = _evening_guest.evening_talks.duplicate()
	# 이미 받은 단골 단계의 이야기도 평소 대화에 섞는다.
	for i: int in _evening_guest.regular_rewards.size():
		var reward: RegularReward = _evening_guest.regular_rewards[i]
		if reward.talk != null and GameState.has_received_reward(_evening_guest.id, i + 1):
			talks.append(reward.talk)
	GameState.advance_story(_evening_guest.id)
	if talks.is_empty():
		_guest_spot.show_guest(_evening_guest, FALLBACK_STORY_LINE)
		return
	_tell_talk(talks[(GameState.get_story_progress(_evening_guest.id) - 1) % talks.size()])


## 대화 하나를 보여 준다. 대답이 있으면 대답 버튼을 띄운다.
func _tell_talk(talk: EveningTalk) -> void:
	_current_talk = talk
	_guest_spot.show_guest(_evening_guest, _with_name(talk.line), false, talk.expression)
	if not talk.replies.is_empty():
		_show_replies(talk.replies)


## 글 속 {name} 을 주인공 이름으로 바꾼다.
func _with_name(text: String) -> String:
	return text.format({"name": GameState.player_name})


## 단골 선물을 받는다: 재료, 밭 한 칸, 기념품. 받은 것을 아래 글로 알려 준다.
func _receive_gift(tier: int, reward: RegularReward) -> void:
	var lines: PackedStringArray = []
	if reward.gift_ingredient != null and reward.gift_amount > 0:
		GameState.add_ingredient(reward.gift_ingredient.id, reward.gift_amount)
		lines.append(GIFT_INGREDIENT_FORMAT % [reward.gift_ingredient.display_name, reward.gift_amount])
	if not reward.extra_plot_place_id.is_empty():
		GameState.add_plot(reward.extra_plot_place_id)
		var place: GardenPlace = GameData.get_garden_place(reward.extra_plot_place_id)
		lines.append(GIFT_PLOT_FORMAT % (place.display_name if place != null else String(reward.extra_plot_place_id)))
	if reward.keepsake != null:
		GameState.add_keepsake(reward.keepsake.id)
		lines.append(GIFT_KEEPSAKE_FORMAT % reward.keepsake.display_name)
	GameState.finish_reward_tier(_evening_guest.id, tier)
	Sound.play(GIFT_SOUND)
	_status_label.text = GIFT_SEPARATOR.join(lines)


func _show_replies(replies: Array[String]) -> void:
	for child: Node in _reply_box.get_children():
		child.queue_free()
	var buttons: Array[Button] = []
	for i: int in replies.size():
		var button: Button = Button.new()
		button.text = REPLY_FORMAT % replies[i]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = reply_button_height
		button.add_theme_font_size_override("font_size", reply_font_size)
		button.pressed.connect(_on_reply_chosen.bind(i))
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


## 고른 대답에 손님이 반응한다. 반응이 없으면 마지막 반응을 쓴다.
func _on_reply_chosen(reply_index: int) -> void:
	var reactions: Array[String] = _current_talk.reactions
	if not reactions.is_empty():
		var index: int = mini(reply_index, reactions.size() - 1)
		var expression: StringName = _current_talk.reaction_expressions[index] \
				if index < _current_talk.reaction_expressions.size() else AnimalGuest.EXPRESSION_DEFAULT
		_guest_spot.say(_with_name(reactions[index]), expression)
	_current_talk = null
	_reply_box.hide()
	_next_button.show()
	_next_button.grab_focus()


func _receive_note_page(recipe: Recipe) -> void:
	GameState.unlock_recipe(recipe.id)
	Sound.play(NOTE_PAGE_SOUND)
	var ingredient_names: PackedStringArray = []
	for ingredient: Ingredient in recipe.ingredients:
		ingredient_names.append(ingredient.display_name)
	_note_recipe_label.text = recipe.display_name
	_note_ingredients_label.text = NOTE_INGREDIENTS_FORMAT % NOTE_INGREDIENT_SEPARATOR.join(ingredient_names)
	_status_label.text = NOTE_FOUND_TEXT
	_note_card.pivot_offset = _note_card.size / 2.0
	_note_card.scale = Vector2.ONE * note_pop_scale
	_note_card.show()
	var tween: Tween = create_tween()
	tween.tween_property(_note_card, "scale", Vector2.ONE, note_pop_duration)


## 잠자리에 들면 날짜를 넘기고 자동 저장한다. 이어 하면 다음 날 아침부터 시작한다.
## 저장은 잠드는 장면(SleepTransition)이 꿈 한 줄을 보여 주는 동안 하고, 끝나면 아침 장면으로 넘어간다.
func _go_to_sleep() -> void:
	# 잠드는 동안 버튼이 또 눌려 두 번 잠들지 않게 막는다.
	_next_button.disabled = true
	var night: int = GameState.current_day
	# 오늘 저녁 평상에 온 손님들이 내일 아침 이웃 바구니에 재료를 두고 간다.
	GameState.basket_guest_ids.append_array(_met_tonight_ids)
	GameState.advance_day()
	# 노트를 3·6·9장 되찾은 날 밤, 손님 사연을 다 본 날 밤에는 꿈 한 줄 대신 할머니 회상 장면을 본다 (본 것으로 적고 저장한다).
	# 하룻밤에 하나. 계절 마지막 밤(내일 저녁이 계절 잔치)에는 남은 회상을 모두 이어서 본다.
	var memories: Array[GrandmaMemory] = memory_book.get_ready(GameState.current_season, GameState.count_found_notes(),
			GameState.seen_memory_ids, GameState.are_season_stories_finished()) if memory_book != null else []
	if not GameState.is_season_end_day():
		memories = memories.slice(0, 1)
	var memory_story: Story = MemoryBook.join_stories(memories) if not memories.is_empty() else null
	for seen: GrandmaMemory in memories:
		GameState.seen_memory_ids.append(seen.id)
	var transition: SleepTransition = sleep_transition_scene.instantiate()
	add_child(transition)
	await transition.play(night, GameState.current_day, GameState.save_game,
			memory_book.dream_text if memory_story != null else "", memory_story == null)
	if memory_story != null:
		StoryScene.play_story(get_tree(), memory_story, morning_scene_path)
	else:
		get_tree().change_scene_to_file(morning_scene_path)
