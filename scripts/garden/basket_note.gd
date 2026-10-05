class_name BasketNote
extends Control
## 이웃 바구니 쪽지. 바구니를 열면 재료와 함께 손님이 남긴 손글씨 쪽지를 종이 위에 보여 준다 (손님 둘이면 두 장).
## 닫기 버튼(또는 아무 데나 누르기)으로 닫으면 closed 를 보낸다.

signal closed

const SIGNATURE_FORMAT: String = "— %s"

## 쪽지 글자 (손글씨), 크기, 색
@export var note_font: Font = preload("res://assets/fonts/KyoboHandwriting/KyoboHandwriting2025lyb.ttf")
@export var note_font_size: int = 44
@export var note_color: Color = Color(0.36, 0.25, 0.16)
@export var signature_font_size: int = 36
## 쪽지 두 장 사이 점선 색
@export var divider_color: Color = Color(0.36, 0.25, 0.16, 0.35)
## 종이가 뜰 때 커졌다 돌아오는 정도와 시간(초)
@export var pop_scale: float = 1.06
@export var pop_duration: float = 0.2

@onready var _paper: Control = %Paper
@onready var _notes_box: VBoxContainer = %NotesBox
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	hide()
	_close_button.pressed.connect(close)


## notes: 쪽지 글, signatures: 쪽지마다 보낸 손님 이름 (같은 순서)
func open(notes: Array[String], signatures: Array[String]) -> void:
	for child: Node in _notes_box.get_children():
		child.queue_free()
	for i: int in notes.size():
		if i > 0:
			var divider: ColorRect = ColorRect.new()
			divider.color = divider_color
			divider.custom_minimum_size.y = 3.0
			_notes_box.add_child(divider)
		_notes_box.add_child(_make_label(notes[i], note_font_size, HORIZONTAL_ALIGNMENT_LEFT))
		_notes_box.add_child(_make_label(SIGNATURE_FORMAT % signatures[i], signature_font_size, HORIZONTAL_ALIGNMENT_RIGHT))
	show()
	_paper.pivot_offset = _paper.size / 2.0
	_paper.scale = Vector2.ONE * pop_scale
	var tween: Tween = create_tween()
	tween.tween_property(_paper, "scale", Vector2.ONE, pop_duration)
	_close_button.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _make_label(text: String, font_size: int, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = alignment
	label.add_theme_font_override("font", note_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", note_color)
	return label


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		close()
