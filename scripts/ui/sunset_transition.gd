class_name SunsetTransition
extends Control
## 해 지는 장면. 점심 장사 결과판 다음, 저녁 평상(이나 계절 잔치)으로 넘어가기 전에 부엌 위에 띄운다.
## 하늘이 노을빛으로 물들고 해가 산 너머로 내려가면서 "해가 뉘엿뉘엿 지고 있어요…" → "N일째 저녁"을 보여 준다.
## play() 를 await 하면 끝난 뒤 돌아온다. 클릭, 스페이스/Enter, 게임패드 A 로 기다리는 시간을 건너뛴다.

const SETTING_TEXT: String = "해가 뉘엿뉘엿 지고 있어요…"
const EVENING_FORMAT: String = "%s %d일째 저녁"

## 노을이 물드는 시간, 해가 내려가는 시간, 글을 보여 주는 시간(초)
@export var fade_in_duration: float = 0.7
@export var sun_set_duration: float = 1.8
@export var evening_hold: float = 0.9
## 해가 내려가는 거리(픽셀)
@export var sun_drop: float = 300.0

var _is_skipping: bool = false

@onready var _sun: Control = %Sun
@onready var _text_label: Label = %TextLabel


func _ready() -> void:
	hide()


## setting_text: "해가 뉘엿뉘엿…" 대신 보여 줄 글 (봄비가 그친 날 등). 비워 두면 기본 글.
func play(day: int, setting_text: String = "") -> void:
	_is_skipping = false
	var sun_home_y: float = _sun.position.y
	_text_label.text = setting_text if not setting_text.is_empty() else SETTING_TEXT
	modulate.a = 0.0
	show()
	# 포커스를 가져와야 A 버튼이 뒤에 있는 부엌 버튼으로 새지 않는다.
	grab_focus()
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)
	tween.tween_property(_sun, "position:y", sun_home_y + sun_drop, sun_set_duration).set_trans(Tween.TRANS_SINE)
	while tween.is_running() and not _is_skipping:
		await get_tree().process_frame
	if tween.is_running():
		tween.kill()
		modulate.a = 1.0
		_sun.position.y = sun_home_y + sun_drop
	_text_label.text = EVENING_FORMAT % [GameData.get_season_name(), day]
	_is_skipping = false
	var waited: float = 0.0
	while waited < evening_hold and not _is_skipping:
		await get_tree().process_frame
		if not get_tree().paused:
			waited += get_process_delta_time()


func _gui_input(event: InputEvent) -> void:
	var is_click: bool = event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT
	if is_click or event.is_action_pressed("ui_accept"):
		_is_skipping = true
		accept_event()
