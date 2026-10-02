extends CanvasLayer
## 일시 정지 메뉴. 오토로드로 등록해서 모든 장면에서 쓴다 (프로젝트 설정 > 전역 > 오토로드, 이름 "PauseMenu").
## Esc 또는 게임패드 Start 로 열고 닫는다. 열려 있는 동안 게임이 멈춘다(get_tree().paused).
## 게임이 시작될 때 기본 입력(게임패드 A/B, 일시 정지)도 여기서 채운다 (InputDefaults).
## 타이틀 화면에서는 열리지 않는다.

## 이 장면에서는 일시 정지 메뉴를 열지 않는다. "타이틀로"를 누르면 이 장면으로 간다.
@export_file("*.tscn") var title_scene_path: String = "res://scenes/ui/title.tscn"

## 메뉴를 열기 전에 선택돼 있던 것. 닫으면 다시 선택한다.
var _previous_focus: Control

@onready var _resume_button: Button = %ResumeButton
@onready var _title_button: Button = %TitleButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	# 게임이 멈춰 있어도 이 메뉴는 움직여야 한다.
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputDefaults.apply()
	_resume_button.pressed.connect(resume)
	_title_button.pressed.connect(_on_title_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)
	_keep_focus_inside([_resume_button, _title_button, _quit_button])
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputDefaults.PAUSE_ACTION):
		if visible:
			resume()
		elif _can_pause():
			open()
		else:
			return
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		resume()
		get_viewport().set_input_as_handled()


func open() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	get_tree().paused = true
	show()
	_resume_button.grab_focus()


func resume() -> void:
	hide()
	get_tree().paused = false
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()


func _can_pause() -> bool:
	var scene: Node = get_tree().current_scene
	return scene != null and scene.scene_file_path != title_scene_path


func _on_title_button_pressed() -> void:
	hide()
	get_tree().paused = false
	get_tree().change_scene_to_file(title_scene_path)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


## 메뉴가 열린 동안 방향키로 뒤쪽 화면의 버튼에 가지 않도록, 선택이 메뉴 버튼 사이에서만 위아래로 돌게 한다.
func _keep_focus_inside(buttons: Array[Button]) -> void:
	for i: int in buttons.size():
		var button: Button = buttons[i]
		var above: Button = buttons[i - 1]
		var below: Button = buttons[(i + 1) % buttons.size()]
		button.focus_neighbor_top = button.get_path_to(above)
		button.focus_neighbor_bottom = button.get_path_to(below)
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
		button.focus_previous = button.focus_neighbor_top
		button.focus_next = button.focus_neighbor_bottom
