class_name InputDefaults
extends RefCounted
## 게임이 시작될 때 기본 입력에 게임패드 버튼을 채워 준다.
## Godot 4.7 기본 입력 맵에는 방향(ui_up 등)만 게임패드가 연결돼 있고,
## 누르기(ui_accept)와 취소(ui_cancel)에는 게임패드 버튼이 없어서 여기서 더한다.
## 프로젝트 설정 > 입력 맵에서 직접 정해 두었다면 그 설정을 그대로 두고 빠진 것만 더한다.

## 일시 정지 동작 이름
const PAUSE_ACTION: StringName = &"pause"

const ACCEPT_JOY_BUTTON: JoyButton = JOY_BUTTON_A
const CANCEL_JOY_BUTTON: JoyButton = JOY_BUTTON_B
const PAUSE_KEY: Key = KEY_ESCAPE
## 일시 정지는 Start 와 Select/Back 둘 다로 열린다. 게임패드마다 Start 위치가 달라서 둘 다 연결한다.
const PAUSE_JOY_BUTTONS: Array[JoyButton] = [JOY_BUTTON_START, JOY_BUTTON_BACK]
## 어느 게임패드에서 눌러도 받도록 하는 기기 번호 (-1 = 모든 기기)
const ALL_DEVICES: int = -1


static func apply() -> void:
	_add_joy_button(&"ui_accept", ACCEPT_JOY_BUTTON)
	_add_joy_button(&"ui_cancel", CANCEL_JOY_BUTTON)
	if not InputMap.has_action(PAUSE_ACTION):
		InputMap.add_action(PAUSE_ACTION)
		var key_event: InputEventKey = InputEventKey.new()
		key_event.physical_keycode = PAUSE_KEY
		key_event.device = ALL_DEVICES
		InputMap.action_add_event(PAUSE_ACTION, key_event)
	for button: JoyButton in PAUSE_JOY_BUTTONS:
		_add_joy_button(PAUSE_ACTION, button)


## 그 동작에 같은 게임패드 버튼이 아직 없으면 더한다.
static func _add_joy_button(action: StringName, button: JoyButton) -> void:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return
	var joy_event: InputEventJoypadButton = InputEventJoypadButton.new()
	joy_event.button_index = button
	# 기본값(0)이면 0번 게임패드에서만 동작한다. Mac에서는 게임패드가 다른 번호를 받을 수 있다.
	joy_event.device = ALL_DEVICES
	InputMap.action_add_event(action, joy_event)
