extends Control
## 봄 잔치 (봄 마무리 장면). 레시피 노트를 다 모은 다음 날 저녁, 평상 대신 열린다.
## 손님들이 모두 모여 한마디씩 하고, 완성된 노트 맨 뒷장의 할머니 편지를 읽은 뒤 다음 계절 예고를 보여 준다.
## 마지막 버튼을 누르면 "봄 완료"로 저장하고 타이틀로 돌아간다. 글은 data/seasons/ 의 SeasonEnding 에서 가져온다.

const NEXT_TEXT: String = "다음"
const RECIPE_ITEM_FORMAT: String = "· %s"

## 이 장면의 배경음악. 비워 두면 앞 장면의 음악을 서서히 끈다.
## 봄 잔치 날 저녁의 잔잔한 잔치 곡을 넣어 둔다.
@export var music: AudioStream = preload("res://assets/audio/music/spring_feast_night.mp3")
## 봄을 마친 뒤 돌아갈 타이틀 장면
@export_file("*.tscn") var title_scene_path: String = "res://scenes/ui/title.tscn"
## 손님 그림이 아직 없을 때 쓰는 임시 사각형 크기와 색
@export var figure_size: Vector2 = Vector2(180, 240)
@export var figure_placeholder_color: Color = Color(0.86, 0.84, 0.8)
@export var figure_name_font_size: int = 24
## 말하지 않는 손님은 이만큼 어둡게 보인다 (1 = 그대로)
@export var listener_brightness: float = 0.55
## 노트 카드와 편지가 뜰 때 커졌다 돌아오는 정도와 시간(초)
@export var pop_scale: float = 1.08
@export var pop_duration: float = 0.2
## 노트 카드에 적히는 요리 이름 글자
@export var recipe_font_size: int = 36
@export var recipe_font_color: Color = Color(0.45, 0.33, 0.2)

## 버튼을 누를 때마다 하나씩 실행할 장면 단계
var _beats: Array[Callable] = []
var _figures: Dictionary[StringName, Control] = {}
var _ending: SeasonEnding

@onready var _guest_row: HBoxContainer = %GuestRow
@onready var _dialogue_box: Control = %DialogueBox
@onready var _speaker_label: Label = %SpeakerLabel
@onready var _dialogue_label: Label = %DialogueLabel
@onready var _note_card: Control = %NoteCard
@onready var _notes_title_label: Label = %NotesTitleLabel
@onready var _notes_grid: GridContainer = %NotesGrid
@onready var _letter: Control = %Letter
@onready var _letter_title_label: Label = %LetterTitleLabel
@onready var _letter_label: Label = %LetterLabel
@onready var _teaser: Control = %Teaser
@onready var _teaser_label: Label = %TeaserLabel
@onready var _next_button: Button = %NextButton


func _ready() -> void:
	Sound.play_music(music)
	# 낮에 깔리던 빗소리가 남아 있으면 끈다 (봄비는 해 질 녘에 그친다).
	Sound.stop_loop(GameData.get_rain_settings().rain_sound)
	_ending = GameData.get_season_ending()
	if _ending == null:
		_ending = SeasonEnding.new()
	_note_card.hide()
	_letter.hide()
	_teaser.hide()
	_next_button.pressed.connect(_on_next_button_pressed)
	var guests: Array[AnimalGuest] = GameData.get_all_guests()
	for guest: AnimalGuest in guests:
		var figure: Control = _make_figure(guest)
		_guest_row.add_child(figure)
		_figures[guest.id] = figure
	# 잔치 준비를 했으면 모은 만큼의 잔칫상 단계로 시작 글과 알려 준 손님의 한마디가 달라진다.
	var prep: FeastPrep = _ending.feast_prep
	var tier: FeastTier = prep.get_tier(GameState.get_feast_delivered_total()) \
			if prep != null and GameState.is_feast_prep_announced else null
	var intro: String = tier.intro_text if tier != null and not tier.intro_text.is_empty() else _ending.feast_intro_text
	_beats.append(func() -> void: _say("", intro, &""))
	for guest: AnimalGuest in guests:
		_beats.append(func() -> void: _say(guest.display_name, guest.feast_line, guest.id))
	if tier != null and not tier.announcer_line.is_empty():
		var announcer: AnimalGuest = GameData.get_guest(prep.announcer_id)
		if announcer != null:
			_beats.append(func() -> void: _say(announcer.display_name, tier.announcer_line, announcer.id))
	if tier != null and GameState.get_feast_delivered_total() >= prep.get_total() and not prep.full_special_text.is_empty():
		_beats.append(func() -> void: _say("", prep.full_special_text, &""))
	_beats.append(_show_notes)
	if _ending.show_letter:
		_beats.append(_show_letter)
	_beats.append(_show_teaser)
	_run_next_beat()
	_next_button.grab_focus()


func _on_next_button_pressed() -> void:
	if _beats.is_empty():
		_finish_spring()
	else:
		_run_next_beat()


func _run_next_beat() -> void:
	var beat: Callable = _beats.pop_front()
	beat.call()
	_next_button.text = _ending.finish_button_text if _beats.is_empty() else NEXT_TEXT


## 대화 상자에 말을 띄운다. speaker_id 가 있으면 그 손님만 밝게, 나머지는 어둡게 보인다.
func _say(speaker_name: String, text: String, speaker_id: StringName) -> void:
	_speaker_label.text = speaker_name
	_speaker_label.visible = not speaker_name.is_empty()
	_dialogue_label.text = text
	for guest_id: StringName in _figures:
		var is_lit: bool = speaker_id.is_empty() or guest_id == speaker_id
		_figures[guest_id].modulate = Color.WHITE if is_lit else Color(listener_brightness, listener_brightness, listener_brightness)


func _show_notes() -> void:
	_dialogue_box.hide()
	_say("", "", &"")
	_notes_title_label.text = _ending.notes_title_text
	var hidden_count: int = 0
	for recipe: Recipe in GameData.get_all_recipes():
		if recipe.note_season != _ending.season:
			continue
		if not GameState.is_recipe_unlocked(recipe.id):
			hidden_count += 1
			continue
		_notes_grid.add_child(_make_note_label(RECIPE_ITEM_FORMAT % recipe.display_name))
	# 노트 카드 맨 아래: 아직 숨어 있는 노트 수, 또는 다 모았다는 글
	var hidden_text: String = _ending.notes_hidden_format % hidden_count if hidden_count > 0 else _ending.notes_all_found_text
	_notes_grid.get_parent().add_child(_make_note_label(hidden_text))
	_pop_in(_note_card)


func _make_note_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", recipe_font_size)
	label.add_theme_color_override("font_color", recipe_font_color)
	return label


func _show_letter() -> void:
	_note_card.hide()
	_letter_title_label.text = _ending.letter_title
	_letter_label.text = _ending.letter_text
	_pop_in(_letter)


func _show_teaser() -> void:
	_note_card.hide()
	_letter.hide()
	_teaser_label.text = _ending.next_season_teaser
	_teaser.modulate.a = 0.0
	_teaser.show()
	var tween: Tween = create_tween()
	tween.tween_property(_teaser, "modulate:a", 1.0, pop_duration * 4.0)


## 봄을 마쳤다고 저장하고 타이틀로 돌아간다.
func _finish_spring() -> void:
	GameState.is_spring_completed = true
	GameState.save_game()
	get_tree().change_scene_to_file(title_scene_path)


func _pop_in(panel: Control) -> void:
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2.ONE * pop_scale
	panel.show()
	var tween: Tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, pop_duration)


## 평상에 앉은 손님 하나: 그림(없으면 임시 사각형)과 이름
func _make_figure(guest: AnimalGuest) -> Control:
	var figure: VBoxContainer = VBoxContainer.new()
	figure.alignment = BoxContainer.ALIGNMENT_END
	if guest.portrait != null:
		var portrait: TextureRect = TextureRect.new()
		portrait.texture = guest.portrait
		portrait.custom_minimum_size = figure_size
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		figure.add_child(portrait)
	else:
		var placeholder: ColorRect = ColorRect.new()
		placeholder.color = figure_placeholder_color
		placeholder.custom_minimum_size = figure_size
		figure.add_child(placeholder)
	var name_label: Label = Label.new()
	name_label.text = guest.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", figure_name_font_size)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	figure.add_child(name_label)
	return figure
