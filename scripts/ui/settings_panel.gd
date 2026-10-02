class_name SettingsPanel
extends Control
## 설정 창. 타이틀 화면과 일시 정지 메뉴가 함께 쓴다. open() 으로 열고, 닫히면 closed 시그널을 보낸다.
## 효과음 크기, 음악 크기, 전체 화면을 바꾸면 바로 적용되고, 닫을 때 저장한다 (GameSettings).
## 게임패드: 위아래로 줄 고르기, 좌우로 크기 조절, B 버튼(ui_cancel)으로 닫기.

signal closed

const PERCENT_FORMAT: String = "%d%%"
const FULLSCREEN_ON_TEXT: String = "전체 화면: 켜짐"
const FULLSCREEN_OFF_TEXT: String = "전체 화면: 꺼짐"
## 효과음 크기를 바꿀 때 들려 주는 소리 (data/sounds/ 의 id)
const PREVIEW_SOUND: StringName = &"click"

## 열기 전에 선택돼 있던 것. 닫으면 다시 선택한다.
var _previous_focus: Control

@onready var _sfx_row: PanelContainer = %SfxRow
@onready var _music_row: PanelContainer = %MusicRow
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _sfx_value_label: Label = %SfxValueLabel
@onready var _music_slider: HSlider = %MusicSlider
@onready var _music_value_label: Label = %MusicValueLabel
@onready var _fullscreen_button: Button = %FullscreenButton
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	# 일시 정지 메뉴 안에서도 움직여야 한다.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_fullscreen_button.toggled.connect(_on_fullscreen_toggled)
	_close_button.pressed.connect(close)
	# 막대는 선택돼도 테두리를 그리지 않아서, 막대가 있는 줄 전체에 버튼과 같은 노란 테두리를 두른다.
	for row_and_slider: Array in [[_sfx_row, _sfx_slider], [_music_row, _music_slider]]:
		var row: PanelContainer = row_and_slider[0]
		var slider: HSlider = row_and_slider[1]
		var empty_style: StyleBox = row.get_theme_stylebox("panel")
		var focus_style: StyleBox = get_theme_stylebox("focus", "Button")
		slider.focus_entered.connect(row.add_theme_stylebox_override.bind("panel", focus_style))
		slider.focus_exited.connect(row.add_theme_stylebox_override.bind("panel", empty_style))
	_keep_focus_inside([_sfx_slider, _music_slider, _fullscreen_button, _close_button])
	hide()


func open() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	# 값을 채우는 동안에는 미리 듣기 소리가 나지 않게 시그널 없이 넣는다.
	_sfx_slider.set_value_no_signal(GameSettings.sfx_volume * _sfx_slider.max_value)
	_music_slider.set_value_no_signal(GameSettings.music_volume * _music_slider.max_value)
	_fullscreen_button.set_pressed_no_signal(GameSettings.is_fullscreen)
	_update_value_labels()
	_update_fullscreen_text()
	show()
	_sfx_slider.grab_focus()


func close() -> void:
	GameSettings.save()
	hide()
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_sfx_changed(value: float) -> void:
	GameSettings.sfx_volume = value / _sfx_slider.max_value
	GameSettings.apply()
	_update_value_labels()
	Sound.play(PREVIEW_SOUND)


func _on_music_changed(value: float) -> void:
	GameSettings.music_volume = value / _music_slider.max_value
	GameSettings.apply()
	_update_value_labels()


func _on_fullscreen_toggled(is_on: bool) -> void:
	GameSettings.is_fullscreen = is_on
	GameSettings.apply()
	_update_fullscreen_text()


func _update_fullscreen_text() -> void:
	_fullscreen_button.text = FULLSCREEN_ON_TEXT if GameSettings.is_fullscreen else FULLSCREEN_OFF_TEXT


func _update_value_labels() -> void:
	_sfx_value_label.text = PERCENT_FORMAT % roundi(GameSettings.sfx_volume * 100.0)
	_music_value_label.text = PERCENT_FORMAT % roundi(GameSettings.music_volume * 100.0)


## 창이 열린 동안 방향키로 뒤쪽 화면에 가지 않도록, 선택이 창 안에서만 위아래로 돌게 한다.
## 좌우는 막대(슬라이더)가 크기 조절에 쓰고, 나머지는 제자리에 머문다.
func _keep_focus_inside(controls: Array[Control]) -> void:
	for i: int in controls.size():
		var control: Control = controls[i]
		control.focus_neighbor_top = control.get_path_to(controls[i - 1])
		control.focus_neighbor_bottom = control.get_path_to(controls[(i + 1) % controls.size()])
		control.focus_neighbor_left = control.get_path_to(control)
		control.focus_neighbor_right = control.get_path_to(control)
		control.focus_previous = control.focus_neighbor_top
		control.focus_next = control.focus_neighbor_bottom
