class_name NotePuzzleBoard
extends Control
## 번진 할머니 노트 창. 퍼즐(NotePuzzle)이 있는 요리를 처음 만들 때, 미니게임 전에 열린다.
## 왼쪽은 할머니 노트(손글씨 줄, 번진 칸), 오른쪽 조리대에서 번진 칸을 하나씩 채운다.
## 빈칸 고르기(CHOOSE_WORD): 번진 낱말을 보기에서 고른다.
## 넣는 순서(ORDER): 섞인 재료 카드(가짜 카드 포함)를 노트 순서대로 하나씩 그릇에 넣는다. 넣을 때마다 노트 칸이 채워진다.
## 틀려도 손해 없이 한 줄만 떠오르고 (카드는 톡 튀었다 돌아온다) 다시 고를 수 있다. 다 채우면 "요리 시작"을 눌러 closed 를 보낸다.
## "추억 떠올리기"를 누르거나 두 번 틀리면 노트 아래에 할머니 말씀(NotePuzzle.hint)이 손글씨로 떠오른다.
## 칸을 채우면 번진 자국이 스르르 걷히며 글씨가 나타나고, 다 채우면 종이가 한 번 환해진다.
## 마우스와 게임패드 모두: 보기와 카드는 모두 버튼이라 십자키 + Ⓐ 로 고른다.

signal closed

const TITLE_FORMAT: String = "할머니 노트 · %s"
const PROMPT_TEXT: String = "번진 칸에 들어갈 말은?"
## 넣는 순서 안내: "번진 순서대로 팬에 넣어요"
const ORDER_PROMPT_FORMAT: String = "번진 순서대로 %s에 넣어요"
const DONE_TEXT: String = "할머니 노트를 다 읽었어요!"
const DEFAULT_WRONG_LINE: String = "음… 할머니는 이렇게 안 하셨던 것 같은데."
const DEFAULT_ORDER_WRONG_LINE: String = "음… 이건 조금 나중이었던 것 같은데."
const DEFAULT_EXTRA_CARD_LINE: String = "음… 노트에 이건 없었던 것 같은데."
## 노트 아래에 떠오르는 할머니 말씀
const MEMORY_FORMAT: String = "\"%s\""
const LINE_SEPARATOR: String = "\n\n"
const LINE_PREFIX: String = "· "
## 번진 칸을 그리는 빈칸 (줄바꿈 안 되는 띄어쓰기)
const SMUDGE_SPACE: String = " "

## 번진 칸 너비 (띄어쓰기 몇 칸). 넣는 순서 칸은 재료 이름이 짧아서 좁게.
@export var smudge_width: int = 14
@export var order_smudge_width: int = 10
## 번진 자국 색, 지금 채우는 칸의 번진 자국 색
@export var smudge_color: Color = Color(0.42, 0.36, 0.48, 0.85)
@export var current_smudge_color: Color = Color(0.85, 0.55, 0.25, 0.9)
## 채운 칸 글자 색 (노트 손글씨보다 조금 진한 잉크)
@export var answer_color: Color = Color(0.55, 0.2, 0.12)
@export var choice_font_size: int = 36
@export var choice_height: float = 72.0
## 재료 카드 아이콘 크기(픽셀). 픽셀 글꼴에 맞춰 12의 배수로.
@export var card_icon_size: int = 48
## 틀린 카드가 톡 튀는 높이(픽셀)와 시간(초)
@export var card_hop_height: float = 18.0
@export var card_hop_duration: float = 0.25
## 맞혔을 때, 틀렸을 때, 노트를 다 읽었을 때 소리
@export var correct_sound: StringName = &"pop"
@export var wrong_sound: StringName = &"click"
@export var done_sound: StringName = &"note_page"
## 할머니 말씀이 떠오를 때 소리
@export var memory_sound: StringName = &"secret"
## 몇 번 틀리면 할머니 말씀이 저절로 떠오르는지
@export var wrong_count_for_memory: int = 2
## 할머니 말씀이 떠오르는 시간(초)
@export var memory_fade_duration: float = 0.8
## 번진 자국이 걷히며 글씨가 나타나는 시간(초)
@export var reveal_duration: float = 0.6
## 노트를 다 채웠을 때 종이가 환해지는 색과 시간(초)
@export var paper_glow_color: Color = Color(1.25, 1.2, 1.05)
@export var paper_glow_duration: float = 0.8

var _puzzle: NotePuzzle
var _puzzle_lines: Array[NotePuzzleLine] = []
var _solved_count: int = 0
## 지금 넣는 순서 줄에서 몇 번째 칸까지 채웠는지 (처음부터 읽히는 칸 포함)
var _order_filled: int = 0
## 이번 퍼즐에서 틀린 횟수 (wrong_count_for_memory 번이면 할머니 말씀이 떠오른다)
var _wrong_count: int = 0
## 지금 번진 자국이 걷히는 칸 (빈칸 고르기: "줄 번호", 넣는 순서: "줄 번호:칸 번호")과 걷힌 정도(0~1)
var _reveal_key: String = ""
var _reveal_t: float = 1.0
var _reveal_tween: Tween

@onready var _title_label: Label = %TitleLabel
@onready var _note_text: RichTextLabel = %NoteText
@onready var _prompt_label: Label = %PromptLabel
@onready var _choice_rows: VBoxContainer = %ChoiceRows
@onready var _line_label: Label = %LineLabel
@onready var _start_button: Button = %StartButton
@onready var _hint_button: Button = %HintButton
@onready var _memory_label: Label = %MemoryLabel
@onready var _paper: Control = %Paper


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_hint_button.pressed.connect(_recall_memory)
	_keep_focus_inside([_start_button])
	hide()


## 이 요리에 풀 퍼즐이 있는지 (퍼즐이 없거나 채울 칸이 없으면 false)
static func has_puzzle(recipe: Recipe) -> bool:
	return recipe != null and recipe.note_puzzle != null and not recipe.note_puzzle.get_puzzle_lines().is_empty()


func open(recipe: Recipe) -> void:
	_puzzle = recipe.note_puzzle
	_puzzle_lines = _puzzle.get_puzzle_lines()
	_solved_count = 0
	_wrong_count = 0
	_reveal_key = ""
	_reveal_t = 1.0
	_title_label.text = TITLE_FORMAT % recipe.display_name
	_line_label.text = ""
	_memory_label.text = ""
	_hint_button.visible = not _puzzle.hint.is_empty()
	_paper.self_modulate = Color.WHITE
	_start_button.hide()
	show()
	_show_current()


## 지금 채울 줄의 보기나 카드를 조리대에 놓는다. 다 채웠으면 마무리.
func _show_current() -> void:
	if _solved_count >= _puzzle_lines.size():
		_refresh_note()
		_clear_rows()
		_finish()
		return
	var line: NotePuzzleLine = _puzzle_lines[_solved_count]
	if line.kind == NotePuzzleLine.Kind.ORDER:
		_order_filled = line.get_readable_count()
		_refresh_note()
		_show_order_cards(line)
	else:
		_refresh_note()
		_show_word_choices(line)


func _clear_rows() -> void:
	for child: Node in _choice_rows.get_children():
		_choice_rows.remove_child(child)
		child.queue_free()


# --- 빈칸 고르기 ---

func _show_word_choices(line: NotePuzzleLine) -> void:
	_clear_rows()
	_prompt_label.text = PROMPT_TEXT
	var buttons: Array[Button] = []
	for i: int in line.choices.size():
		var button: Button = _make_row_button(line.choices[i])
		button.pressed.connect(_on_choice_pressed.bind(i))
		buttons.append(button)
	_keep_focus_inside(buttons)
	buttons[0].grab_focus()


func _on_choice_pressed(index: int) -> void:
	var line: NotePuzzleLine = _puzzle_lines[_solved_count]
	if index == line.answer_index:
		_start_reveal(str(_solved_count))
		_solve_line()
	else:
		Sound.play(wrong_sound)
		_line_label.text = line.wrong_line if not line.wrong_line.is_empty() else DEFAULT_WRONG_LINE
		_count_wrong()


# --- 넣는 순서 ---

## 번진 칸의 재료와 가짜 카드를 섞어서 놓는다.
func _show_order_cards(line: NotePuzzleLine) -> void:
	_clear_rows()
	_prompt_label.text = ORDER_PROMPT_FORMAT % line.container_name
	var cards: Array[Ingredient] = line.get_order_cards()
	cards.shuffle()
	var buttons: Array[Button] = []
	for card: Ingredient in cards:
		var button: Button = _make_row_button(card.display_name)
		button.icon = card.get_icon_texture()
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", card_icon_size)
		button.pressed.connect(_on_card_pressed.bind(card, button))
		buttons.append(button)
	_keep_focus_inside(buttons)
	buttons[0].grab_focus()


func _on_card_pressed(card: Ingredient, button: Button) -> void:
	var line: NotePuzzleLine = _puzzle_lines[_solved_count]
	if card == line.order_answer[_order_filled]:
		_start_reveal("%d:%d" % [_solved_count, _order_filled])
		_order_filled += 1
		if _order_filled >= line.order_answer.size():
			_solve_line()
			return
		Sound.play(correct_sound)
		_line_label.text = ""
		_refresh_note()
		# 넣은 카드는 조리대에서 치우고, 남은 카드 첫 장으로 선택을 옮긴다.
		_choice_rows.remove_child(button)
		button.queue_free()
		_row_buttons()[0].grab_focus()
		_keep_focus_inside(_row_buttons())
		return
	Sound.play(wrong_sound)
	if card in line.order_answer:
		_line_label.text = line.wrong_line if not line.wrong_line.is_empty() else DEFAULT_ORDER_WRONG_LINE
	else:
		_line_label.text = line.extra_card_line if not line.extra_card_line.is_empty() else DEFAULT_EXTRA_CARD_LINE
	_hop(button)
	_count_wrong()


## 틀린 카드가 톡 튀었다 제자리로 돌아온다 (그림만 움직이고 자리는 그대로).
## 튀는 도중에 또 누르면 앞 움직임을 멈추고 원래 자리에서 다시 튄다 (카드가 제자리를 잃지 않게).
func _hop(button: Button) -> void:
	if button.has_meta(&"hop_tween"):
		(button.get_meta(&"hop_tween") as Tween).kill()
	var base_y: float = button.get_meta(&"hop_base_y", button.position.y)
	button.position.y = base_y
	button.set_meta(&"hop_base_y", base_y)
	var tween: Tween = button.create_tween()
	button.set_meta(&"hop_tween", tween)
	tween.tween_property(button, "position:y", base_y - card_hop_height, card_hop_duration / 2.0) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(button, "position:y", base_y, card_hop_duration / 2.0) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.finished.connect(func() -> void:
		button.remove_meta(&"hop_tween")
		button.remove_meta(&"hop_base_y"))


# --- 추억 떠올리기 ---

func _count_wrong() -> void:
	_wrong_count += 1
	if _wrong_count >= wrong_count_for_memory:
		_recall_memory()


## 할머니 말씀을 노트 아래에 손글씨로 떠올린다 (한 번만). 버튼은 치우고 선택은 보기로 옮긴다.
func _recall_memory() -> void:
	if _puzzle.hint.is_empty() or not _memory_label.text.is_empty():
		return
	Sound.play(memory_sound)
	# 한글이 낱말 중간에서 줄이 바뀌지 않게 띄어쓰기 자리에서 미리 줄을 나눈다.
	_memory_label.text = Korean.wrap_by_spaces(MEMORY_FORMAT % _puzzle.hint, _memory_label.get_theme_font("font"),
			_memory_label.get_theme_font_size("font_size"), _memory_label.size.x)
	_memory_label.modulate.a = 0.0
	create_tween().tween_property(_memory_label, "modulate:a", 1.0, memory_fade_duration)
	var had_focus: bool = _hint_button.has_focus()
	_hint_button.hide()
	var rows: Array[Button] = _row_buttons()
	if not rows.is_empty():
		_keep_focus_inside(rows)
		if had_focus:
			rows[0].grab_focus()


# --- 번진 자국이 걷히는 연출 ---

func _start_reveal(key: String) -> void:
	if _reveal_tween != null:
		_reveal_tween.kill()
	_reveal_key = key
	_reveal_t = 0.0
	_reveal_tween = create_tween()
	_reveal_tween.tween_method(_set_reveal, 0.0, 1.0, reveal_duration)


func _set_reveal(t: float) -> void:
	_reveal_t = t
	_refresh_note()


## 채운 칸의 글씨. 막 채운 칸이면 번진 자국이 옅어지면서 글씨가 짙어진다.
func _filled_text(text: String, key: String) -> String:
	if key != _reveal_key or _reveal_t >= 1.0:
		return _answer_text(text)
	var smudge: Color = smudge_color
	smudge.a *= 1.0 - _reveal_t
	var ink: Color = answer_color
	ink.a = _reveal_t
	return "[bgcolor=#%s][color=#%s]%s[/color][/bgcolor]" % [smudge.to_html(true), ink.to_html(true), _escape(text)]


# --- 공통 ---

## 조리대에 놓인 보기·카드 버튼들
func _row_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for child: Node in _choice_rows.get_children():
		buttons.append(child as Button)
	return buttons


func _make_row_button(text: String) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size.y = choice_height
	button.add_theme_font_size_override("font_size", choice_font_size)
	button.text = text
	_choice_rows.add_child(button)
	return button


## 지금 줄을 다 채웠다: 다음 줄로.
func _solve_line() -> void:
	Sound.play(correct_sound)
	_line_label.text = ""
	_solved_count += 1
	_show_current()


func _finish() -> void:
	Sound.play(done_sound)
	_prompt_label.text = DONE_TEXT
	_line_label.text = ""
	_hint_button.hide()
	_paper.self_modulate = paper_glow_color
	create_tween().tween_property(_paper, "self_modulate", Color.WHITE, paper_glow_duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
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
			if line.kind == NotePuzzleLine.Kind.ORDER:
				blank = _order_blank(line, puzzle_index)
			elif puzzle_index < _solved_count:
				blank = _filled_text(line.get_answer(), str(puzzle_index))
			else:
				blank = _smudge(puzzle_index == _solved_count, smudge_width)
			text = text.replace(_escape(NotePuzzleLine.BLANK_MARK), blank)
			puzzle_index += 1
		parts.append(LINE_PREFIX + text)
	_note_text.text = LINE_SEPARATOR.join(parts)


## 넣는 순서 칸들: 처음부터 읽히는 칸은 노트 글씨, 넣은 칸은 정답 글씨, 나머지는 번진 자국 (다음에 넣을 칸만 다른 색)
func _order_blank(line: NotePuzzleLine, puzzle_index: int) -> String:
	var filled: int = line.order_answer.size() if puzzle_index < _solved_count else line.get_readable_count()
	if puzzle_index == _solved_count:
		filled = _order_filled
	var slots: PackedStringArray = []
	for i: int in line.order_answer.size():
		var card: Ingredient = line.order_answer[i]
		var card_name: String = card.display_name if card != null else ""
		if i < line.get_readable_count():
			slots.append(_escape(card_name))
		elif i < filled:
			slots.append(_filled_text(card_name, "%d:%d" % [puzzle_index, i]))
		else:
			slots.append(_smudge(puzzle_index == _solved_count and i == filled, order_smudge_width))
	return NotePuzzleLine.ORDER_SEPARATOR.join(slots)


func _answer_text(text: String) -> String:
	return "[color=#%s]%s[/color]" % [answer_color.to_html(false), _escape(text)]


func _smudge(is_current: bool, width: int) -> String:
	var color: Color = current_smudge_color if is_current else smudge_color
	return "[bgcolor=#%s]%s[/bgcolor]" % [color.to_html(true), SMUDGE_SPACE.repeat(width)]


## 노트 글 속 [ 가 꾸밈 글(BBCode)로 읽히지 않게
func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


## 창이 열린 동안 방향키로 창 밖 버튼에 가지 않도록, 보기들 (과 추억 떠올리기 버튼) 사이에서만 위아래로 돈다.
func _keep_focus_inside(choice_buttons: Array[Button]) -> void:
	var buttons: Array[Button] = choice_buttons.duplicate()
	if _hint_button != null and _hint_button.visible and _start_button not in buttons:
		buttons.append(_hint_button)
	for i: int in buttons.size():
		var button: Button = buttons[i]
		button.focus_neighbor_top = button.get_path_to(buttons[i - 1])
		button.focus_neighbor_bottom = button.get_path_to(buttons[(i + 1) % buttons.size()])
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
		button.focus_previous = button.focus_neighbor_top
		button.focus_next = button.focus_neighbor_bottom
