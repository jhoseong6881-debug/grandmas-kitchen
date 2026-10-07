extends Control
## 타이틀 화면. 저장된 게임이 있으면 이어 하기, 없으면 새 게임으로 시작한다. 설정 창도 여기서 연다.
## 새 게임을 고를 때 저장된 게임이 있으면 지워도 되는지 한 번 묻는다. 새 게임은 프롤로그부터 시작한다.

## 해 질 녘부터 저녁 평상까지 깔리는 풀벌레 소리 (data/sounds/ 의 id)
const EVENING_SOUND: StringName = &"porch_night"

const CONTINUE_FORMAT: String = "이어 하기 (%s %d일째 아침)"
const SPRING_COMPLETED_TEXT: String = "봄 완료 (여름은 준비 중)"
const LOAD_FAILED_TEXT: String = "저장된 게임을 불러오지 못했어요. 새 게임으로 시작해 주세요."
## 이어 하기 요약: 노트 수, 그날 있는 일 (DayPreview)
const SUMMARY_NOTES_FORMAT: String = "할머니 노트 %d / %d"
const SUMMARY_TODAY_FORMAT: String = "오늘은   %s"
const SUMMARY_SEPARATOR: String = "\n"

## 이 장면의 배경음악. 비워 두면 앞 장면의 음악을 서서히 끈다.
@export var music: AudioStream
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
@onready var _credits_button: Button = %CreditsButton
@onready var _credits_panel: CreditsPanel = %CreditsPanel
@onready var _message_label: Label = %MessageLabel
## 이어 하기 버튼 아래: 지난번 이어 갈 실마리 (노트 수, 오늘 있는 일)
@onready var _summary_label: Label = %SummaryLabel
@onready var _confirm_panel: Control = %ConfirmPanel
@onready var _confirm_yes_button: Button = %ConfirmYesButton
@onready var _confirm_no_button: Button = %ConfirmNoButton


func _ready() -> void:
	Sound.play_music(music)
	# 낮에 깔리던 빗소리가 남아 있으면 끈다 (봄비는 해 질 녘에 그친다).
	Sound.stop_loop(GameData.get_rain_settings().rain_sound)
	# 해 질 녘에 깔리기 시작한 풀벌레 소리도 (해 지는 중에 처음 화면으로 나온 경우) 끈다.
	Sound.stop_loop(EVENING_SOUND)
	_continue_button.pressed.connect(_on_continue_button_pressed)
	_new_game_button.pressed.connect(_on_new_game_button_pressed)
	_settings_button.pressed.connect(_on_settings_button_pressed)
	_credits_button.pressed.connect(_on_credits_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)
	_confirm_yes_button.pressed.connect(_start_new_game)
	_confirm_no_button.pressed.connect(_close_confirm)
	_message_label.text = ""
	_summary_label.text = ""
	_confirm_panel.hide()
	var summary: Dictionary = GameState.read_save_summary()
	if summary.is_empty():
		_continue_button.hide()
		_new_game_button.grab_focus()
	else:
		var season_id: Season.Id = clampi(int(summary.get("current_season", Season.Id.SPRING)), 0, Season.Id.size() - 1) as Season.Id
		var day: int = int(summary.get("current_day", GameState.STARTING_DAY))
		# 예전 세이브: 봄을 마치고 타이틀로 돌아갔던 세이브는 불러올 때 다음 계절 1일째로 넘어간다.
		if bool(summary.get("is_spring_completed", false)) and season_id == Season.Id.SPRING:
			var spring: SeasonData = GameData.get_season(Season.Id.SPRING)
			var next: SeasonData = GameData.get_season(spring.next_season) if spring != null else null
			if next == null or GameData.is_demo_end_season(Season.Id.SPRING):
				# 다음 계절이 아직 없거나 봄 잔치에서 데모가 끝나면, 봄 완료 세이브는 남겨 두기만 한다.
				_continue_button.text = SPRING_COMPLETED_TEXT
				_continue_button.disabled = true
				_continue_button.focus_mode = Control.FOCUS_NONE
				_continue_button.show()
				_new_game_button.grab_focus()
				return
			season_id = next.id
			day = GameState.STARTING_DAY
		var season: SeasonData = GameData.get_season(season_id)
		_can_continue = true
		_continue_button.text = CONTINUE_FORMAT % [season.display_name if season != null else "", day]
		_continue_button.show()
		_continue_button.grab_focus()
		_show_summary()


## 세이브를 미리 불러와서, 이어 하면 오늘 무엇이 있는지 보여 준다 (며칠 만에 켜도 바로 이어 가게).
## 새 게임을 고르면 GameState.start_new_game 이 다시 비우므로 미리 불러 둬도 괜찮다.
func _show_summary() -> void:
	if not GameState.load_game():
		return
	var season_recipes: Array[Recipe] = GameData.get_all_recipes().filter(
			func(recipe: Recipe) -> bool: return recipe.note_season == GameState.current_season)
	var parts: PackedStringArray = []
	# 노트가 없는 계절(아직 만들지 않은 여름 등)에는 "0 / 0" 대신 노트 줄을 뺀다.
	if not season_recipes.is_empty():
		parts.append(SUMMARY_NOTES_FORMAT % [GameState.count_found_notes(), season_recipes.size()])
	var today: String = DayPreview.get_text(GameState.current_day, false)
	if not today.is_empty():
		parts.append(SUMMARY_TODAY_FORMAT % today)
	_summary_label.text = SUMMARY_SEPARATOR.join(parts)


func _on_continue_button_pressed() -> void:
	if not GameState.load_game():
		_message_label.text = LOAD_FAILED_TEXT
		_summary_label.text = ""
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


## "만든 사람들" 창 (글꼴·소리 출처와 라이선스 원문)
func _on_credits_button_pressed() -> void:
	_set_menu_enabled(false)
	_credits_panel.open()
	await _credits_panel.closed
	_set_menu_enabled(true)
	_credits_button.grab_focus()


## 확인 창이나 설정 창이 떠 있는 동안 뒤의 버튼을 막는다. 비활성 버튼도 선택은 될 수 있어서 선택 자체를 끈다.
## 그래야 방향키로 뒤 버튼에 가지 않는다.
func _set_menu_enabled(is_enabled: bool) -> void:
	for button: Button in [_continue_button, _new_game_button, _settings_button, _credits_button, _quit_button]:
		var can_use: bool = is_enabled and (button != _continue_button or _can_continue)
		button.disabled = not can_use
		button.focus_mode = Control.FOCUS_ALL if can_use else Control.FOCUS_NONE


func _on_quit_button_pressed() -> void:
	get_tree().quit()
