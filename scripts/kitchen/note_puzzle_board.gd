class_name NotePuzzleBoard
extends Control
## 번진 할머니 노트 창. 퍼즐(NotePuzzle)이 있는 요리를 처음 만들 때, 미니게임 전에 열린다.
## 왼쪽은 할머니 노트(손글씨 줄, 번진 칸), 오른쪽 조리대에서 번진 칸을 하나씩 채운다.
## 틀려도 손해 없이 한 줄만 떠오르고 다시 고를 수 있다. 다 채우면 "요리 시작"을 눌러 closed 를 보낸다.
## 마우스와 게임패드 모두: 보기는 모두 버튼이라 십자키 + Ⓐ 로 고른다.

signal closed

const TITLE_FORMAT: String = "할머니 노트 · %s"
const PROMPT_TEXT: String = "번진 칸에 들어갈 말은?"
const DONE_TEXT: String = "할머니 노트를 다 읽었어요!"
const DEFAULT_WRONG_LINE: String = "음… 할머니는 이렇게 안 하셨던 것 같은데."
const LINE_SEPARATOR: String = "\n\n"
const LINE_PREFIX: String = "· "
## 번진 칸을 그리는 빈칸 (줄바꿈 안 되는 띄어쓰기)
const SMUDGE_SPACE: String = " "

## 번진 칸 너비 (띄어쓰기 몇 칸)
@export var smudge_width: int = 8
## 번진 자국 색, 지금 채우는 칸의 번진 자국 색
@export var smudge_color: Color = Color(0.42, 0.36, 0.48, 0.85)
@export var current_smudge_color: Color = Color(0.85, 0.55, 0.25, 0.9)
## 채운 칸 글자 색 (노트 손글씨보다 조금 진한 잉크)
@export var answer_color: Color = Color(0.55, 0.2, 0.12)
@export var choice_font_size: int = 36
@export var choice_height: float = 72.0
## 맞혔을 때, 틀렸을 때, 노트를 다 읽었을 때 소리
@export var correct_sound: StringName = &"pop"
@export var wrong_sound: StringName = &"click"
@export var done_sound: StringName = &"note_page"

var _puzzle: NotePuzzle
var _puzzle_lines: Array[NotePuzzleLine] = []
var _solved_count: int = 0

@onready var _title_label: Label = %TitleLabel
@onready var _note_text: RichTextLabel = %NoteText
@onready var _prompt_label: Label = %PromptLabel
@onready var _choice_rows: VBoxContainer = %ChoiceRows
@onready var _line_label: Label = %LineLabel
@onready var _start_button: Button = %StartButton


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_keep_focus_inside([_start_button])
	hide()


## 이 요리에 풀 퍼즐이 있는지 (퍼즐이 없거나 채울 칸이 없으면 false)
static func has_puzzle(recipe: Recipe) -> bool:
	return recipe != null and recipe.note_puzzle != null and not recipe.note_puzzle.get_puzzle_lines().is_empty()


func open(recipe: Recipe) -> void:
	_puzzle = recipe.note_puzzle
	_puzzle_lines = _puzzle.get_puzzle_lines()
	_solved_count = 0
	_title_label.text = TITLE_FORMAT % recipe.display_name
	_line_label.text = ""
	_start_button.hide()
	show()
	_show_current()


## 지금 채울 칸의 보기를 조리대에 놓는다. 다 채웠으면 마무리.
func _show_current() -> void:
	_refresh_note()
	for child: Node in _choice_rows.get_children():
		child.queue_free()
	if _solved_count >= _puzzle_lines.size():
		_finish()
		return
	var line: NotePuzzleLine = _puzzle_lines[_solved_count]
	if line.kind != NotePuzzleLine.Kind.CHOOSE_WORD or line.choices.is_empty():
		# 아직 만들지 않은 방식(넣는 순서)이나 보기가 빈 줄은 저절로 채운다 (게임이 멈추지 않게).
		push_warning("노트 퍼즐 줄을 풀 수 없어 건너뜁니다: %s" % line.text)
		_solved_count += 1
		_show_current()
		return
	_prompt_label.text = PROMPT_TEXT
	var buttons: Array[Button] = []
	for i: int in line.choices.size():
		var button: Button = Button.new()
		button.custom_minimum_size.y = choice_height
		button.add_theme_font_size_override("font_size", choice_font_size)
		button.text = line.choices[i]
		button.pressed.connect(_on_choice_pressed.bind(i))
		_choice_rows.add_child(button)
		buttons.append(button)
	_keep_focus_inside(buttons)
	buttons[0].grab_focus()


func _on_choice_pressed(index: int) -> void:
	var line: NotePuzzleLine = _puzzle_lines[_solved_count]
	if index == line.answer_index:
		Sound.play(correct_sound)
		_line_label.text = ""
		_solved_count += 1
		_show_current()
	else:
		Sound.play(wrong_sound)
		_line_label.text = line.wrong_line if not line.wrong_line.is_empty() else DEFAULT_WRONG_LINE


func _finish() -> void:
	Sound.play(done_sound)
	_prompt_label.text = DONE_TEXT
	_line_label.text = ""
	_start_button.show()
	_start_button.grab_focus()


func _on_start_pressed() -> void:
	hide()
	closed.emit()


## 노트 글을 다시 쓴다: 채운 칸은 정답 글씨, 아직 번진 칸은 번진 자국 (지금 채우는 칸은 다른 색).
func _refresh_note() -> void:
	var parts: PackedStringArray = []
	var puzzle_index: int = 0
	for line: NotePuzzleLine in _puzzle.lines:
		if line == null:
			continue
		var text: String = _escape(line.text)
		if line.is_puzzle():
			var blank: String
			if puzzle_index < _solved_count:
				blank = "[color=#%s]%s[/color]" % [answer_color.to_html(false), _escape(line.get_answer())]
			else:
				var color: Color = current_smudge_color if puzzle_index == _solved_count else smudge_color
				blank = "[bgcolor=#%s]%s[/bgcolor]" % [color.to_html(true), SMUDGE_SPACE.repeat(smudge_width)]
			text = text.replace(_escape(NotePuzzleLine.BLANK_MARK), blank)
			puzzle_index += 1
		parts.append(LINE_PREFIX + text)
	_note_text.text = LINE_SEPARATOR.join(parts)


## 노트 글 속 [ 가 꾸밈 글(BBCode)로 읽히지 않게
func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


## 창이 열린 동안 방향키로 창 밖 버튼에 가지 않도록, 보기들 사이에서만 위아래로 돈다.
func _keep_focus_inside(buttons: Array[Button]) -> void:
	for i: int in buttons.size():
		var button: Button = buttons[i]
		button.focus_neighbor_top = button.get_path_to(buttons[i - 1])
		button.focus_neighbor_bottom = button.get_path_to(buttons[(i + 1) % buttons.size()])
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
		button.focus_previous = button.focus_neighbor_top
		button.focus_next = button.focus_neighbor_bottom
