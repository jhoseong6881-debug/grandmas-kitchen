extends Control
## 저녁 평상 장면. 오늘 대접한 손님 중 한 명이 찾아와 이야기를 하고, 대답을 골라 주면 손님이 반응한다.
## 돌려줄 할머니 레시피 노트 페이지가 있으면 건네준다. 다 듣고 나면 잠자리에 들어 다음 날 아침 텃밭으로 간다.
## 장면은 "다음" 버튼을 누를 때마다 한 단계씩 진행한다. 대답을 고르는 동안에는 "다음" 버튼이 숨는다.

const DAY_TEXT_FORMAT: String = "%d일째 저녁"
const QUIET_EVENING_TEXT: String = "오늘 저녁은 조용하네요. 별이 참 많아요."
const NOTE_FOUND_TEXT: String = "할머니 레시피 노트 한 장을 되찾았어요!"
const NOTE_INGREDIENTS_FORMAT: String = "재료: %s"
const NOTE_INGREDIENT_SEPARATOR: String = ", "
const FALLBACK_STORY_LINE: String = "오늘도 잘 먹었어요."
const REPLY_FORMAT: String = "▸ %s"
const NEXT_TEXT: String = "다음"
const SLEEP_TEXT: String = "잠자리에 들기"

## 잠자리에 든 뒤 넘어갈 다음 날 아침 장면
@export_file("*.tscn") var morning_scene_path: String = "res://scenes/garden/garden.tscn"
## 노트 카드가 뜰 때 커졌다 돌아오는 정도와 시간(초)
@export var note_pop_scale: float = 1.1
@export var note_pop_duration: float = 0.2
@export var reply_font_size: int = 36
@export var reply_button_height: float = 72.0

## 버튼을 누를 때마다 하나씩 실행할 장면 단계
var _beats: Array[Callable] = []
var _evening_guest: AnimalGuest
## 지금 대답을 기다리는 대화 (없으면 null)
var _current_talk: EveningTalk

@onready var _day_label: Label = %DayLabel
@onready var _guest_spot: GuestSpot = %GuestSpot
@onready var _status_label: Label = %StatusLabel
@onready var _note_card: Control = %NoteCard
@onready var _note_recipe_label: Label = %NoteRecipeLabel
@onready var _note_ingredients_label: Label = %NoteIngredientsLabel
@onready var _next_button: Button = %NextButton
@onready var _reply_box: VBoxContainer = %ReplyBox
@onready var _notebook: GuestNotebook = %GuestNotebook
@onready var _notebook_button: Button = %NotebookButton


func _ready() -> void:
	_day_label.text = DAY_TEXT_FORMAT % GameState.current_day
	_note_card.hide()
	_reply_box.hide()
	_status_label.text = ""
	_next_button.pressed.connect(_on_next_button_pressed)
	_notebook_button.pressed.connect(_notebook.open)
	_evening_guest = _choose_evening_guest()
	if _evening_guest == null:
		_beats.append(func() -> void: _status_label.text = QUIET_EVENING_TEXT)
	else:
		_beats.append(_tell_story)
		var page: Recipe = _next_note_page(_evening_guest)
		if page != null:
			_beats.append(func() -> void: _guest_spot.say(_evening_guest.note_line.format({"recipe": page.display_name})))
			_beats.append(func() -> void: _receive_note_page(page))
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


## 오늘 대접한 손님 중 한 명. 완벽하게 대접한 손님이 있으면 그중에서,
## 그 안에서도 돌려줄 레시피 노트가 남은 손님이 있으면 그중에서 고른다. 아무도 없으면 null.
func _choose_evening_guest() -> AnimalGuest:
	var served: Array[AnimalGuest] = []
	for guest_id: StringName in GameState.todays_served_guests:
		var guest: AnimalGuest = GameData.get_guest(guest_id)
		if guest != null:
			served.append(guest)
	if served.is_empty():
		return null
	var perfect: Array[AnimalGuest] = served.filter(
			func(guest: AnimalGuest) -> bool: return GameState.todays_served_guests[guest.id])
	var candidates: Array[AnimalGuest] = perfect if not perfect.is_empty() else served
	var with_page: Array[AnimalGuest] = candidates.filter(
			func(guest: AnimalGuest) -> bool: return _next_note_page(guest) != null)
	if not with_page.is_empty():
		candidates = with_page
	return candidates.pick_random()


## 손님이 아직 돌려주지 않은 첫 번째 레시피 노트 페이지. 없으면 null.
func _next_note_page(guest: AnimalGuest) -> Recipe:
	for recipe: Recipe in guest.note_recipes:
		if not GameState.is_recipe_unlocked(recipe.id):
			return recipe
	return null


## 찾아올 때마다 대화를 하나씩 순서대로 나눈다. 다 나누면 처음부터 다시.
## 대답이 있는 대화면 대답 버튼을 띄우고, 고를 때까지 "다음" 버튼을 숨긴다.
func _tell_story() -> void:
	var talks: Array[EveningTalk] = _evening_guest.evening_talks
	GameState.advance_story(_evening_guest.id)
	if talks.is_empty():
		_guest_spot.show_guest(_evening_guest, FALLBACK_STORY_LINE)
		return
	_current_talk = talks[(GameState.get_story_progress(_evening_guest.id) - 1) % talks.size()]
	_guest_spot.show_guest(_evening_guest, _current_talk.line)
	if not _current_talk.replies.is_empty():
		_show_replies(_current_talk.replies)


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
		_guest_spot.say(reactions[mini(reply_index, reactions.size() - 1)])
	_current_talk = null
	_reply_box.hide()
	_next_button.show()
	_next_button.grab_focus()


func _receive_note_page(recipe: Recipe) -> void:
	GameState.unlock_recipe(recipe.id)
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
func _go_to_sleep() -> void:
	GameState.advance_day()
	GameState.has_unshown_save_notice = GameState.save_game()
	get_tree().change_scene_to_file(morning_scene_path)
