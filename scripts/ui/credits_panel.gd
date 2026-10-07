class_name CreditsPanel
extends Control
## "만든 사람들" 창. 타이틀 화면에서 연다. open() 으로 열고, 닫히면 closed 시그널을 보낸다.
## 글은 data/credits.tres (Credits) 에서 가져오고, 그 아래에 라이선스 원문과 Godot 엔진 저작권 표시를 붙인다.
## 게임패드: 위아래(십자키·왼쪽 스틱)로 글을 움직이고, A(닫기 버튼)나 B 버튼(ui_cancel)으로 닫는다. 마우스는 휠로 움직인다.

signal closed

const SECTION_SEPARATOR: String = "\n\n"
const ENGINE_PART_FORMAT: String = "· %s"
const ENGINE_COPYRIGHT_FORMAT: String = "    © %s"
const ENGINE_LICENSE_FORMAT: String = "    License: %s"

## 보여 줄 글 (비워 두면 data/credits.tres)
@export var credits: Credits
## 위아래를 누르고 있을 때 1초에 움직이는 거리(픽셀)
@export var scroll_speed: float = 900.0

## 열기 전에 선택돼 있던 것. 닫으면 다시 선택한다.
var _previous_focus: Control
var _is_filled: bool = false

@onready var _title_label: Label = %TitleLabel
@onready var _text: RichTextLabel = %Text
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	if credits == null:
		credits = load("res://data/credits.tres") as Credits
	_close_button.pressed.connect(close)
	# 닫기 버튼 하나만 선택되게 해서, 위아래 입력은 글을 움직이는 데만 쓴다.
	for path: String in ["focus_neighbor_top", "focus_neighbor_bottom", "focus_neighbor_left", "focus_neighbor_right", "focus_previous", "focus_next"]:
		_close_button.set(path, _close_button.get_path_to(_close_button))
	hide()


func open() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	if not _is_filled:
		_fill()
	_text.get_v_scroll_bar().value = 0.0
	show()
	_close_button.grab_focus()


func close() -> void:
	hide()
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	closed.emit()


## 글을 한 번만 채운다 (엔진 저작권 표시가 길어서 열 때마다 만들지 않는다).
func _fill() -> void:
	_is_filled = true
	if credits == null:
		return
	_title_label.text = credits.title
	_close_button.text = credits.close_text
	var parts: PackedStringArray = [credits.body]
	var license_parts: PackedStringArray = []
	for path: String in credits.license_files:
		var license_text: String = FileAccess.get_file_as_string(path)
		if license_text.is_empty():
			push_warning("라이선스 파일을 읽지 못했습니다: %s" % path)
			continue
		license_parts.append(license_text.strip_edges())
	if credits.show_engine_license:
		license_parts.append(_engine_license_text())
	if not license_parts.is_empty():
		parts.append(credits.license_title)
		parts.append_array(license_parts)
	_text.text = SECTION_SEPARATOR.join(parts)


## Godot 엔진 라이선스와, 엔진에 들어 있는 다른 프로그램들의 저작권 표시·라이선스 원문 (엔진이 직접 알려 주는 글)
func _engine_license_text() -> String:
	var lines: PackedStringArray = [credits.engine_license_title, Engine.get_license_text().strip_edges(), ""]
	for info: Dictionary in Engine.get_copyright_info():
		lines.append(ENGINE_PART_FORMAT % info.get("name", ""))
		for part: Dictionary in info.get("parts", []):
			for holder: String in part.get("copyright", []):
				lines.append(ENGINE_COPYRIGHT_FORMAT % holder)
			lines.append(ENGINE_LICENSE_FORMAT % part.get("license", ""))
	var licenses: Dictionary = Engine.get_license_info()
	for license_name: String in licenses:
		lines.append("")
		lines.append(license_name)
		lines.append(String(licenses[license_name]).strip_edges())
	return "\n".join(lines)


## 위아래를 누르고 있는 동안 글을 움직인다 (키보드 방향키, 게임패드 십자키·왼쪽 스틱).
func _process(delta: float) -> void:
	if not visible:
		return
	var direction: float = Input.get_axis("ui_up", "ui_down")
	if not is_zero_approx(direction):
		_text.get_v_scroll_bar().value += direction * scroll_speed * delta


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
