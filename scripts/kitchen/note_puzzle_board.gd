class_name NotePuzzleBoard
extends Control
## 번진 할머니 노트 창. 퍼즐(NotePuzzle)이 있는 요리를 처음 만들 때, 미니게임 전에 열린다.
## 왼쪽은 할머니 노트(손글씨 줄, 번진 칸), 오른쪽 조리대에서 번진 칸을 하나씩 채운다.
## 빈칸 고르기(CHOOSE_WORD): 번진 낱말을 보기에서 고른다.
## 넣는 순서(ORDER): 섞인 재료 카드(가짜 카드 포함)를 노트 순서대로 하나씩 그릇에 넣는다. 넣을 때마다 노트 칸이 채워진다.
## 틀려도 손해 없이 한 줄만 떠오르고 (카드는 톡 튀었다 돌아온다) 다시 고를 수 있다. 다 채우면 "요리 시작"을 눌러 closed 를 보낸다.
## 처음 퍼즐을 만나면 안내 손님이 한 번 알려 준다 (TutorialDialog, 안내 id note_puzzle).
## 조리대 위 질문은 줄마다 다르다 (NotePuzzleLine.prompt, 비면 기본 문구).
## 노트 아래에는 할머니 말씀(NotePuzzle.hint)이 처음부터 흐린 손글씨로 보이고 (단서), 두 번 틀리면 또렷해진다.
## 번진 칸은 잉크 얼룩 그림이다 (smudge_texture, 비면 코드로 그린 임시 얼룩). 지금 채울 칸만 천천히 깜빡인다.
## 칸을 채우면 번진 자국이 스르르 걷히며 글씨가 나타나고, 다 채우면 종이가 한 번 환해진다.
## 마우스와 게임패드 모두: 보기와 카드는 모두 버튼이라 십자키 + Ⓐ 로 고른다.
## 마우스로는 보기·카드를 끌어다 왼쪽 노트 종이에 놓아도 된다 (누른 것과 같다).

signal closed

const TITLE_FORMAT: String = "할머니 노트 · %s"
const PROMPT_TEXT: String = "번진 자리에 뭐라고 적혀 있었을까?"
## 넣는 순서 안내: "번진 순서대로 팬에 넣어요"
const ORDER_PROMPT_FORMAT: String = "번진 순서대로 %s에 넣어요"
const DONE_TEXT: String = "할머니 노트를 다 읽었어요!"
const DEFAULT_WRONG_LINE: String = "음… 할머니는 이렇게 안 하셨던 것 같은데."
const DEFAULT_ORDER_WRONG_LINE: String = "음… 이건 조금 나중이었던 것 같은데."
const DEFAULT_EXTRA_CARD_LINE: String = "음… 노트에 이건 없었던 것 같은데."
## 노트 아래에 보이는 할머니 말씀
const MEMORY_FORMAT: String = "할머니가 하시던 말씀\n\"%s\""
const LINE_SEPARATOR: String = "\n\n"
const LINE_PREFIX: String = "· "
## 처음 퍼즐을 만났을 때 한 번 보여 주는 안내 (data/story/tutorial.tres 의 id)
const TUTORIAL_ID: StringName = &"note_puzzle"
## 임시 얼룩 모양 가짓수 (칸마다 돌려 쓴다)
const SMUDGE_VARIANT_COUNT: int = 3

## 손에 든 카드 모양을 그리는 높이. 이 창(z_index 1)보다 위에 그려야 보인다.
const DRAG_PREVIEW_Z_INDEX: int = 10
## 번진 노트 퍼즐이 나오기 시작하는 날 (1일째는 처음 15분이 무거워지지 않게 없음)
const FIRST_DAY: int = 2

## 번진 잉크 얼룩 그림. 흰색·회색으로 그리면 smudge_color 로 물든다. 비워 두면 코드로 그린 임시 얼룩.
@export var smudge_texture: Texture2D
## 번진 칸 크기(픽셀, 화면 기준). 넣는 순서 칸은 재료 이름이 짧아서 좁게. 픽셀 그림 3배 규칙에 맞춰 3의 배수로.
@export var smudge_size: Vector2i = Vector2i(216, 48)
@export var order_smudge_size: Vector2i = Vector2i(144, 48)
## 임시 얼룩을 그릴 때 한 점의 크기 (도트 그림 3배 규칙)
@export var smudge_pixel_scale: int = 3
## 번진 자국 색 (잉크색 하나만 쓴다)
@export var smudge_color: Color = Color(0.3, 0.28, 0.45, 0.9)
## 지금 채울 칸이 깜빡이는 빠르기와 가장 옅을 때의 진하기(0~1)
@export var smudge_pulse_speed: float = 3.0
@export var smudge_pulse_min_alpha: float = 0.45
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
## 할머니 말씀이 또렷해질 때 소리
@export var memory_sound: StringName = &"secret"
## 몇 번 틀리면 할머니 말씀이 또렷해지는지
@export var wrong_count_for_memory: int = 2
## 할머니 말씀이 또렷해지는 시간(초)
@export var memory_fade_duration: float = 0.8
## 처음 보이는 할머니 말씀의 진하기 (0~1). 두 번 틀리면 1 로 또렷해진다.
@export var memory_start_alpha: float = 0.7
## 번진 자국이 걷히며 글씨가 나타나는 시간(초)
@export var reveal_duration: float = 0.6
## 노트를 다 채웠을 때 종이가 환해지는 색과 시간(초)
@export var paper_glow_color: Color = Color(1.25, 1.2, 1.05)
@export var paper_glow_duration: float = 0.8
## 보기·카드를 끄는 동안 노트 종이 색 (여기에 놓으라는 표시), 끄는 카드의 흐림 정도, 손에 든 카드 모양의 흐림 정도
@export var paper_drop_color: Color = Color(1.1, 1.08, 0.9)
@export var dragging_alpha: float = 0.4
@export var drag_preview_alpha: float = 1.0

var _puzzle: NotePuzzle
var _puzzle_lines: Array[NotePuzzleLine] = []
var _solved_count: int = 0
## 지금 넣는 순서 줄에서 몇 번째 칸까지 채웠는지 (처음부터 읽히는 칸 포함)
var _order_filled: int = 0
## 이번 퍼즐에서 틀린 횟수 (wrong_count_for_memory 번이면 할머니 말씀이 또렷해진다)
var _wrong_count: int = 0
## 지금 번진 자국이 걷히는 칸 (빈칸 고르기: "줄 번호", 넣는 순서: "줄 번호:칸 번호")과 걷힌 정도(0~1)
var _reveal_key: String = ""
var _reveal_t: float = 1.0
var _reveal_tween: Tween
## 지금 끌고 있는 보기·카드 (끌지 않으면 null)
var _dragging_button: Button
## 할머니 말씀이 또렷해졌는지
var _is_memory_clear: bool = false
## 지금 채울 칸이 깜빡이는 시간
var _pulse_time: float = 0.0
## 크기·모양별로 한 번 그린 임시 얼룩
var _smudge_cache: Dictionary[String, Texture2D] = {}

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
	# 노트 종이는 끌어 온 보기·카드를 받는다.
	_paper.set_drag_forwarding(Callable(), _can_drop_on_paper, _drop_on_paper)
	hide()


## 이 요리에 풀 퍼즐이 있는지 (퍼즐이 없거나 채울 칸이 없으면 false)
static func has_puzzle(recipe: Recipe) -> bool:
	return recipe != null and recipe.note_puzzle != null and not recipe.note_puzzle.get_puzzle_lines().is_empty()


## 오늘 이 요리를 만들면 번진 노트 퍼즐이 나올 수 있는지: 아직 안 푼 퍼즐이 있고, FIRST_DAY 일째부터이며, 계절 끝 잔치 날이 아닐 때.
## (1일째는 처음 15분이 무거워지지 않게, 잔치 날은 저녁에 요령 한 줄을 적는 장면이 없어서 퍼즐을 내지 않는다.)
## 부엌(퍼즐을 여는 곳)과 메뉴판(번진 노트 표시)이 같은 규칙을 쓴다. 점심 한 번에 하나 규칙은 부엌이 따로 본다.
static func is_waiting_today(recipe: Recipe) -> bool:
	return has_puzzle(recipe) and not GameState.is_note_puzzle_solved(recipe.id) \
			and GameState.current_day >= FIRST_DAY and not GameState.is_season_end_day()


func open(recipe: Recipe) -> void:
	_puzzle = recipe.note_puzzle
	_puzzle_lines = _puzzle.get_puzzle_lines()
	_solved_count = 0
	_wrong_count = 0
	_reveal_key = ""
	_reveal_t = 1.0
	_title_label.text = TITLE_FORMAT % recipe.display_name
	_line_label.text = ""
	_pulse_time = 0.0
	# 할머니 말씀은 처음부터 노트 아래에 보이니 "추억 떠올리기" 버튼은 쓰지 않는다.
	_hint_button.hide()
	_paper.self_modulate = Color.WHITE
	_start_button.hide()
	show()
	_show_memory()
	_show_current()
	# 처음 퍼즐을 만났으면 무엇을 하는 건지 한 번 알려 준다 (안내가 열린 동안 뒤 버튼은 눌리지 않는다).
	TutorialDialog.show_once(self, TUTORIAL_ID)


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
	_set_prompt(line.prompt if not line.prompt.is_empty() else PROMPT_TEXT)
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
	_set_prompt(line.prompt if not line.prompt.is_empty() else ORDER_PROMPT_FORMAT % line.container_name)
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


# --- 할머니 말씀 (단서) ---

func _count_wrong() -> void:
	_wrong_count += 1
	if _wrong_count >= wrong_count_for_memory:
		_recall_memory()


## 할머니 말씀을 노트 아래에 흐린 손글씨로 놓는다 (말씀이 없는 퍼즐이면 비운다).
func _show_memory() -> void:
	_is_memory_clear = false
	if _puzzle.hint.is_empty():
		_memory_label.text = ""
		return
	# 한글이 낱말 중간에서 줄이 바뀌지 않게 띄어쓰기 자리에서 미리 줄을 나눈다.
	_memory_label.text = Korean.wrap_by_spaces(MEMORY_FORMAT % _puzzle.hint, _memory_label.get_theme_font("font"),
			_memory_label.get_theme_font_size("font_size"), _memory_label.size.x)
	_memory_label.modulate.a = memory_start_alpha


## 두 번 틀리면 할머니 말씀이 또렷해진다 (한 번만).
func _recall_memory() -> void:
	if _memory_label.text.is_empty() or _is_memory_clear:
		return
	_is_memory_clear = true
	Sound.play(memory_sound)
	create_tween().tween_property(_memory_label, "modulate:a", 1.0, memory_fade_duration)


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


## 채운 칸의 글씨를 쓴다. 막 채운 칸이면 앞 절반 동안 번진 자국이 옅어지고, 뒤 절반 동안 글씨가 짙어진다.
func _write_filled(text: String, key: String, slot_size: Vector2i, variant: int) -> void:
	if key != _reveal_key or _reveal_t >= 1.0:
		_note_text.append_text(_answer_text(text))
		return
	if _reveal_t < 0.5:
		var smudge: Color = smudge_color
		smudge.a *= 1.0 - _reveal_t * 2.0
		_note_text.add_image(_get_smudge_texture(slot_size, variant), slot_size.x, slot_size.y, smudge)
		return
	var ink: Color = answer_color
	ink.a = (_reveal_t - 0.5) * 2.0
	_note_text.append_text("[color=#%s]%s[/color]" % [ink.to_html(true), _escape(text)])


# --- 공통 ---

## 조리대 위 질문. 한글이 낱말 중간에서 줄이 바뀌지 않게 띄어쓰기 자리에서 미리 줄을 나눈다.
func _set_prompt(text: String) -> void:
	var counter: Control = _prompt_label.get_parent_control()
	_prompt_label.text = Korean.wrap_by_spaces(text, _prompt_label.get_theme_font("font"),
			_prompt_label.get_theme_font_size("font_size"), counter.size.x)


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
	button.set_drag_forwarding(_get_row_drag_data.bind(button), Callable(), Callable())
	_choice_rows.add_child(button)
	return button


# --- 마우스로 끌어다 놓기 ---

## 보기·카드를 끌기 시작한다: 손에 든 모양을 마우스에 붙이고, 원래 카드는 흐리게, 노트 종이는 밝게.
func _get_row_drag_data(_at_position: Vector2, button: Button) -> Variant:
	if button.disabled or not is_visible_in_tree():
		return null
	var preview: Button = button.duplicate(0)
	preview.size = button.size
	preview.position = -button.size / 2.0
	preview.modulate.a = drag_preview_alpha
	# 버튼 바탕이 반투명이라 밝은 노트 종이 위에서 흐려 보이지 않게, 손에 든 카드는 바탕을 불투명하게 칠한다.
	var style: StyleBoxFlat = button.get_theme_stylebox("normal") as StyleBoxFlat
	if style != null:
		var solid: StyleBoxFlat = style.duplicate()
		solid.bg_color.a = 1.0
		preview.add_theme_stylebox_override("normal", solid)
	var holder: Control = Control.new()
	holder.z_index = DRAG_PREVIEW_Z_INDEX
	holder.add_child(preview)
	button.set_drag_preview(holder)
	_dragging_button = button
	button.modulate.a = dragging_alpha
	_paper.self_modulate = paper_drop_color
	return {"note_puzzle_button": button}


func _can_drop_on_paper(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).get("note_puzzle_button") is Button


## 노트 종이에 놓으면 그 보기·카드를 누른 것과 같다.
func _drop_on_paper(_at_position: Vector2, data: Variant) -> void:
	var button: Button = (data as Dictionary).get("note_puzzle_button")
	_end_drag()
	if is_instance_valid(button) and button.get_parent() == _choice_rows:
		button.pressed.emit()


## 끌기가 끝나면 (어디에 놓았든) 카드와 종이를 원래대로.
func _end_drag() -> void:
	if is_instance_valid(_dragging_button):
		_dragging_button.modulate.a = 1.0
	_dragging_button = null
	_paper.self_modulate = Color.WHITE


## 지금 채울 칸이 깜빡이도록 노트를 다시 쓴다 (채울 칸이 남아 있을 때만).
func _process(delta: float) -> void:
	if not visible or _puzzle == null or _solved_count >= _puzzle_lines.size():
		return
	_pulse_time += delta
	_refresh_note()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _dragging_button != null:
		_end_drag()


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


## 노트 글을 다시 쓴다: 채운 칸은 정답 글씨, 아직 번진 칸은 잉크 얼룩 (지금 채우는 칸만 깜빡인다).
func _refresh_note() -> void:
	_note_text.clear()
	var puzzle_index: int = 0
	var is_first: bool = true
	for line: NotePuzzleLine in _puzzle.lines:
		if line == null:
			continue
		if not is_first:
			_note_text.append_text(LINE_SEPARATOR)
		is_first = false
		_note_text.append_text(LINE_PREFIX)
		var blank_at: int = line.text.find(NotePuzzleLine.BLANK_MARK)
		if not line.is_puzzle() or blank_at < 0:
			_note_text.append_text(_escape(line.text))
			if line.is_puzzle():
				puzzle_index += 1
			continue
		_note_text.append_text(_escape(line.text.left(blank_at)))
		if line.kind == NotePuzzleLine.Kind.ORDER:
			_write_order_blank(line, puzzle_index)
		elif puzzle_index < _solved_count:
			_write_filled(line.get_answer(), str(puzzle_index), smudge_size, puzzle_index)
		else:
			_write_smudge(puzzle_index == _solved_count, smudge_size, puzzle_index)
		_note_text.append_text(_escape(line.text.substr(blank_at + NotePuzzleLine.BLANK_MARK.length())))
		puzzle_index += 1


## 넣는 순서 칸들: 처음부터 읽히는 칸은 노트 글씨, 넣은 칸은 정답 글씨, 나머지는 잉크 얼룩 (다음에 넣을 칸만 깜빡인다)
func _write_order_blank(line: NotePuzzleLine, puzzle_index: int) -> void:
	var filled: int = line.order_answer.size() if puzzle_index < _solved_count else line.get_readable_count()
	if puzzle_index == _solved_count:
		filled = _order_filled
	for i: int in line.order_answer.size():
		if i > 0:
			_note_text.append_text(NotePuzzleLine.ORDER_SEPARATOR)
		var card: Ingredient = line.order_answer[i]
		var card_name: String = card.display_name if card != null else ""
		var variant: int = puzzle_index + i
		if i < line.get_readable_count():
			_note_text.append_text(_escape(card_name))
		elif i < filled:
			_write_filled(card_name, "%d:%d" % [puzzle_index, i], order_smudge_size, variant)
		else:
			_write_smudge(puzzle_index == _solved_count and i == filled, order_smudge_size, variant)


func _answer_text(text: String) -> String:
	return "[color=#%s]%s[/color]" % [answer_color.to_html(false), _escape(text)]


## 번진 잉크 얼룩 하나를 노트에 놓는다. 지금 채울 칸이면 천천히 깜빡인다.
func _write_smudge(is_current: bool, slot_size: Vector2i, variant: int) -> void:
	var color: Color = smudge_color
	if is_current:
		var wave: float = 0.5 + 0.5 * cos(_pulse_time * smudge_pulse_speed)
		color.a *= lerpf(smudge_pulse_min_alpha, 1.0, wave)
	_note_text.add_image(_get_smudge_texture(slot_size, variant), slot_size.x, slot_size.y, color)


## 얼룩 그림. 디자이너 그림(smudge_texture)이 있으면 그것을, 없으면 코드로 그린 임시 얼룩을 쓴다.
func _get_smudge_texture(slot_size: Vector2i, variant: int) -> Texture2D:
	if smudge_texture != null:
		return smudge_texture
	var shape: int = variant % SMUDGE_VARIANT_COUNT
	var key: String = "%dx%d:%d" % [slot_size.x, slot_size.y, shape]
	if not _smudge_cache.has(key):
		_smudge_cache[key] = _draw_smudge(slot_size, shape)
	return _smudge_cache[key]


## 임시 얼룩: 가로로 겹친 잉크 동그라미 몇 개와 튄 방울. 가운데는 진하고 가장자리는 옅다.
## 작은 도트로 그린 뒤 smudge_pixel_scale 배로 키운다 (도트 그림 3배 규칙). 흰색으로 그려서 smudge_color 로 물든다.
func _draw_smudge(slot_size: Vector2i, shape: int) -> Texture2D:
	var pixel_scale: int = maxi(smudge_pixel_scale, 1)
	var width: int = maxi(slot_size.x / pixel_scale, 2)
	var height: int = maxi(slot_size.y / pixel_scale, 2)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = shape + 1
	var blobs: Array[Vector3] = []
	var count: int = maxi(3, width / 8)
	for i: int in count:
		var x: float = lerpf(height * 0.4, width - height * 0.4, float(i) / float(count - 1)) + rng.randf_range(-2.0, 2.0)
		var y: float = height / 2.0 + rng.randf_range(-1.5, 1.5)
		blobs.append(Vector3(x, y, rng.randf_range(height * 0.32, height * 0.48)))
	for i: int in 3:
		blobs.append(Vector3(rng.randf_range(1.0, width - 1.0), rng.randf_range(1.0, height - 1.0), rng.randf_range(0.8, 1.5)))
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for py: int in height:
		for px: int in width:
			var depth: float = 0.0
			for blob: Vector3 in blobs:
				var distance: float = Vector2(px + 0.5, py + 0.5).distance_to(Vector2(blob.x, blob.y))
				depth = maxf(depth, 1.0 - distance / blob.z)
			if depth > 0.35:
				image.set_pixel(px, py, Color.WHITE)
			elif depth > 0.0:
				image.set_pixel(px, py, Color(1.0, 1.0, 1.0, 0.55))
	image.resize(width * pixel_scale, height * pixel_scale, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


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
