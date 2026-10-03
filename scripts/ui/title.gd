extends Control
## 타이틀 화면. 저장된 게임이 있으면 이어 하기, 없으면 새 게임으로 시작한다. 설정 창도 여기서 연다.
## 새 게임을 고를 때 저장된 게임이 있으면 지워도 되는지 한 번 묻는다. 새 게임은 프롤로그부터 시작한다.

const CONTINUE_FORMAT: String = "이어 하기 (%d일째 아침)"
const SPRING_COMPLETED_TEXT: String = "봄 완료 (여름은 준비 중)"
const LOAD_FAILED_TEXT: String = "저장된 게임을 불러오지 못했어요. 새 게임으로 시작해 주세요."

## 이 장면의 배경음악. 비워 두면 앞 장면의 음악을 서서히 끈다.
@export var music: AudioStream = preload("res://assets/audio/music/title_spring.mp3")
## 이어 하기로 시작할 아침 장면
@export_file("*.tscn") var morning_scene_path: String = "res://scenes/garden/garden.tscn"
## 새 게임을 시작하면 먼저 보여 주는 프롤로그 장면
@export_file("*.tscn") var prologue_scene_path: String = "res://scenes/story/prologue.tscn"

## 이어 할 수 있는 세이브가 있는지 (봄을 마친 세이브는 아직 이어 할 수 없다)
var _can_continue: bool = false

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _settings_panel: SettingsPanel = %SettingsPanel
@onready var _message_label: Label = %MessageLabel
@onready var _confirm_panel: Control = %ConfirmPanel
@onready var _confirm_yes_button: Button = %ConfirmYesButton
@onready var _confirm_no_button: Button = %ConfirmNoButton


func _ready() -> void:
	Sound.play_music(music)
	_continue_button.pressed.connect(_on_continue_button_pressed)
	_new_game_button.pressed.connect(_on_new_game_button_pressed)
	_settings_button.pressed.connect(_on_settings_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)
	_confirm_yes_button.pressed.connect(_start_new_game)
	_confirm_no_button.pressed.connect(_close_confirm)
	_message_label.text = ""
	_confirm_panel.hide()
	var summary: Dictionary = GameState.read_save_summary()
	if summary.is_empty():
		_continue_button.hide()
		_new_game_button.grab_focus()
	elif bool(summary.get("is_spring_completed", false)):
		# 봄을 마친 세이브는 남겨 두고, 다음 계절이 생기면 여기서 이어 하게 한다.
		_continue_button.text = SPRING_COMPLETED_TEXT
		_continue_button.disabled = true
		_continue_button.focus_mode = Control.FOCUS_NONE
		_continue_button.show()
		_new_game_button.grab_focus()
	else:
		_can_continue = true
		_continue_button.text = CONTINUE_FORMAT % int(summary.get("current_day", GameState.STARTING_DAY))
		_continue_button.show()
		_continue_button.grab_focus()


func _on_continue_button_pressed() -> void:
	if not GameState.load_game():
		_message_label.text = LOAD_FAILED_TEXT
		_continue_button.hide()
		_new_game_button.grab_focus()
		return
	get_tree().change_scene_to_file(morning_scene_path)


func _on_new_game_button_pressed() -> void:
	if GameState.has_save():
		_set_menu_enabled(false)
		_confirm_panel.show()
		_confirm_no_button.grab_focus()
	else:
		_start_new_game()


func _start_new_game() -> void:
	GameState.delete_save()
	GameState.start_new_game()
	get_tree().change_scene_to_file(prologue_scene_path)


func _close_confirm() -> void:
	_confirm_panel.hide()
	_set_menu_enabled(true)
	_new_game_button.grab_focus()


## 설정 창이 떠 있는 동안 뒤의 버튼을 막고, 닫히면 설정 버튼을 다시 선택한다.
func _on_settings_button_pressed() -> void:
	_set_menu_enabled(false)
	_settings_panel.open()
	await _settings_panel.closed
	_set_menu_enabled(true)
	_settings_button.grab_focus()


## 확인 창이나 설정 창이 떠 있는 동안 뒤의 버튼을 막는다. 비활성 버튼도 선택은 될 수 있어서 선택 자체를 끈다.
## 그래야 방향키로 뒤 버튼에 가지 않는다.
func _set_menu_enabled(is_enabled: bool) -> void:
	for button: Button in [_continue_button, _new_game_button, _settings_button, _quit_button]:
		var can_use: bool = is_enabled and (button != _continue_button or _can_continue)
		button.disabled = not can_use
		button.focus_mode = Control.FOCUS_ALL if can_use else Control.FOCUS_NONE


func _on_quit_button_pressed() -> void:
	get_tree().quit()
