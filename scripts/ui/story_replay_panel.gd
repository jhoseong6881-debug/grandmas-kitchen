class_name StoryReplayPanel
extends Control
## "이야기 다시 보기" 창. 타이틀 화면에서 연다. 세이브를 건드리지 않고 프롤로그와 이미 본 할머니 회상을 다시 본다.
## open() 으로 열고, 이야기를 고르면 story_chosen, 그냥 닫으면 closed 시그널을 보낸다.
## 할머니 회상은 세이브의 seen_memory_ids 에 있는 것만 고를 수 있고, 아직 못 본 것은 잠긴 칸으로 보인다.
## 게임패드: 위아래로 고르고, A 로 보고, B 버튼(ui_cancel)으로 닫는다.

signal story_chosen(story: Story)
signal closed

const LOCKED_TEXT: String = "??? (아직 떠오르지 않은 기억)"

## 언제나 다시 볼 수 있는 프롤로그
@export var prologue_story: Story = preload("res://data/story/prologue.tres")
## 할머니 회상 목록 (이미 본 것만 고를 수 있다)
@export var memory_book: MemoryBook = preload("res://data/story/memories.tres")
@export var prologue_text: String = "프롤로그"
@export var item_font_size: int = 36
@export var item_height: float = 72.0

## 열기 전에 선택돼 있던 것. 닫으면 다시 선택한다.
var _previous_focus: Control

@onready var _list: VBoxContainer = %List
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_close_button.pressed.connect(close)
	hide()


## seen_memory_ids: 세이브에 적힌 이미 본 회상 id (세이브가 없으면 빈 목록)
func open(seen_memory_ids: Array) -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	for child: Node in _list.get_children():
		child.queue_free()
	var buttons: Array[Button] = [_add_item(prologue_text, prologue_story, true)]
	if memory_book != null:
		for memory: GrandmaMemory in memory_book.memories:
			if memory == null or memory.story == null or memory.story.chapters.is_empty():
				continue
			var is_seen: bool = String(memory.id) in seen_memory_ids.map(func(id: Variant) -> String: return String(id))
			var button: Button = _add_item(memory.story.chapters[0].title if is_seen else LOCKED_TEXT, memory.story, is_seen)
			if is_seen:
				buttons.append(button)
	buttons.append(_close_button)
	# 위아래로 고를 수 있는 것(본 이야기와 닫기)만 차례로 잇고, 처음과 끝을 돌게 한다.
	for i: int in buttons.size():
		var button: Button = buttons[i]
		button.focus_neighbor_top = button.get_path_to(buttons[i - 1])
		button.focus_neighbor_bottom = button.get_path_to(buttons[(i + 1) % buttons.size()])
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
	show()
	buttons[0].grab_focus()


func close() -> void:
	hide()
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	closed.emit()


func _add_item(text: String, story: Story, is_enabled: bool) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, item_height)
	button.add_theme_font_size_override("font_size", item_font_size)
	button.disabled = not is_enabled
	button.focus_mode = Control.FOCUS_ALL if is_enabled else Control.FOCUS_NONE
	if is_enabled:
		button.pressed.connect(_choose.bind(story))
	_list.add_child(button)
	return button


func _choose(story: Story) -> void:
	hide()
	story_chosen.emit(story)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
