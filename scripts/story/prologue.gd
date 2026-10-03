extends Control
## 프롤로그 장면. story(data/story/prologue.tres)의 장들을 차례로 보여 준다.
## 클릭, 스페이스/Enter, 게임패드 A 로 한 줄씩 넘긴다. 글자가 다 나오기 전에 누르면 그 줄을 바로 다 보여 준다.
## "#이름" 줄에서 이름 입력 칸이 나오고, 지은 이름은 GameState.player_name 에 저장된다.
## Esc 나 게임패드 B 로 건너뛸 수 있다. 이름을 아직 안 지었으면 이름부터 짓고 넘어간다.
## 다 보면 1일째 아침 텃밭으로 간다.

## 이 줄에서 이름 입력 칸을 연다
const NAME_INPUT_LINE: String = "#이름"
## 글 속의 이 표시는 주인공 이름으로 바뀐다
const NAME_TOKEN: String = "{name}"
## "토끼: 안녕" 처럼 말하는 사람과 말을 나누는 표시. 말하는 사람 이름이 이보다 길면 그냥 설명 글로 본다.
const SPEAKER_SEPARATOR: String = ": "
const MAX_SPEAKER_LENGTH: int = 8
## 편지 문단 사이 빈 줄
const LETTER_PARAGRAPH_GAP: String = "\n\n"

## 이 장면의 배경음악. 비워 두면 앞 장면의 음악을 서서히 끈다.
@export var music: AudioStream
@export var story: Story
## 다 보면 넘어갈 장면
@export_file("*.tscn") var next_scene_path: String = "res://scenes/garden/garden.tscn"
## 1초에 나오는 글자 수
@export var chars_per_second: float = 40.0
## 장이 바뀔 때 배경 색이 바뀌는 시간(초)
@export var chapter_fade_duration: float = 0.6
## 이름 최대 글자 수
@export var name_max_length: int = 8
## 이름 칸이 열린 뒤 이 시간(초) 동안은 "정했어요"를 받지 않는다. 넘기던 손으로 실수로 바로 정해 버리지 않게.
@export var name_confirm_delay: float = 0.6
## "다음" 표시가 깜빡이는 빠르기
@export var next_mark_blink_speed: float = 4.0

var _chapter_index: int = -1
var _line_index: int = -1
var _typing_label: Label
var _shown_chars: float = 0.0
var _is_waiting_for_name: bool = false
var _name_box_open_time: float = 0.0
var _is_skipping: bool = false
var _blink_time: float = 0.0

@onready var _background: ColorRect = %Background
@onready var _background_image: TextureRect = %BackgroundImage
@onready var _chapter_label: Label = %ChapterLabel
@onready var _text_box: Control = %TextBox
@onready var _speaker_label: Label = %SpeakerLabel
@onready var _line_label: Label = %LineLabel
@onready var _next_mark: Label = %NextMark
@onready var _paper: Control = %Paper
@onready var _letter_label: Label = %LetterLabel
@onready var _name_box: Control = %NameBox
@onready var _name_prompt: Label = %NamePrompt
@onready var _name_edit: LineEdit = %NameEdit
@onready var _name_confirm_button: Button = %NameConfirmButton
@onready var _skip_button: Button = %SkipButton


func _ready() -> void:
	Sound.play_music(music)
	_name_box.hide()
	_name_edit.max_length = name_max_length
	_name_edit.text_submitted.connect(_confirm_name.unbind(1))
	_name_confirm_button.pressed.connect(_confirm_name)
	_skip_button.pressed.connect(_skip)
	if story == null or story.chapters.is_empty():
		_finish()
		return
	_name_prompt.text = story.name_prompt
	_start_chapter(0)


func _process(delta: float) -> void:
	_blink_time += delta
	if _is_waiting_for_name:
		_name_box_open_time += delta
	_next_mark.modulate.a = 0.5 + 0.5 * sin(_blink_time * next_mark_blink_speed)
	if _typing_label == null:
		return
	_shown_chars += chars_per_second * delta
	_typing_label.visible_characters = int(_shown_chars)
	if _shown_chars >= _typing_label.get_total_character_count():
		_stop_typing()


func _unhandled_input(event: InputEvent) -> void:
	if _is_waiting_for_name:
		# 이름 칸에서 게임패드 A 는 글자 입력이 아니라 "정했어요"로 쓴다.
		if event is InputEventJoypadButton and event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_confirm_name()
		return
	var is_click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if is_click or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_skip()


# --- 장과 줄 ---

func _start_chapter(index: int) -> void:
	_chapter_index = index
	_line_index = -1
	var chapter: StoryChapter = story.chapters[index]
	_chapter_label.text = chapter.title
	var tween: Tween = create_tween()
	tween.tween_property(_background, "color", chapter.background_color, chapter_fade_duration)
	_background_image.texture = chapter.background_image
	_background_image.visible = chapter.background_image != null
	_paper.visible = chapter.is_letter
	_text_box.visible = not chapter.is_letter
	_letter_label.text = ""
	_advance()


## 다음 줄로 넘어간다. 글자가 아직 나오는 중이면 그 줄을 바로 다 보여 준다.
func _advance() -> void:
	if _typing_label != null:
		_typing_label.visible_characters = -1
		_stop_typing()
		return
	var chapter: StoryChapter = story.chapters[_chapter_index]
	_line_index += 1
	if _line_index >= chapter.lines.size():
		if _chapter_index + 1 < story.chapters.size():
			_start_chapter(_chapter_index + 1)
		else:
			_finish()
		return
	var line: String = chapter.lines[_line_index]
	if line.strip_edges() == NAME_INPUT_LINE:
		_ask_name()
		return
	line = line.replace(NAME_TOKEN, GameState.player_name)
	if chapter.is_letter:
		var start: int = _letter_label.get_total_character_count()
		_letter_label.text += (LETTER_PARAGRAPH_GAP if not _letter_label.text.is_empty() else "") + line
		_start_typing(_letter_label, start)
	else:
		_show_line(line)


## "토끼: 안녕" 이면 말하는 사람을 따로 보여 준다.
func _show_line(line: String) -> void:
	var speaker: String = ""
	var separator_at: int = line.find(SPEAKER_SEPARATOR)
	if separator_at > 0 and separator_at <= MAX_SPEAKER_LENGTH:
		speaker = line.substr(0, separator_at)
		line = line.substr(separator_at + SPEAKER_SEPARATOR.length())
	_speaker_label.text = speaker
	_speaker_label.visible = not speaker.is_empty()
	_line_label.text = line
	_start_typing(_line_label, 0)


func _start_typing(label: Label, from_chars: int) -> void:
	_typing_label = label
	_shown_chars = from_chars
	label.visible_characters = from_chars
	_next_mark.hide()


func _stop_typing() -> void:
	_typing_label = null
	_next_mark.show()


# --- 이름 짓기 ---

func _ask_name() -> void:
	_is_waiting_for_name = true
	_name_box_open_time = 0.0
	_next_mark.hide()
	_name_edit.text = story.default_name if GameState.player_name.is_empty() else GameState.player_name
	_name_box.show()
	_name_edit.grab_focus()
	_name_edit.select_all()


## 빈 이름이면 미리 적혀 있던 이름을 쓴다.
func _confirm_name() -> void:
	if _name_box_open_time < name_confirm_delay:
		return
	var player_name: String = _name_edit.text.strip_edges().left(name_max_length)
	GameState.player_name = player_name if not player_name.is_empty() else story.default_name
	_is_waiting_for_name = false
	_name_box.hide()
	_name_edit.release_focus()
	if _is_skipping:
		_finish()
	else:
		_advance()


# --- 끝 ---

## 이름을 아직 안 지었으면 이름부터 짓고 끝낸다.
func _skip() -> void:
	_is_skipping = true
	if _typing_label != null:
		_stop_typing()
	if GameState.player_name.is_empty():
		_text_box.hide()
		_paper.hide()
		_ask_name()
	else:
		_finish()


func _finish() -> void:
	if GameState.player_name.is_empty() and story != null:
		GameState.player_name = story.default_name
	get_tree().change_scene_to_file(next_scene_path)
