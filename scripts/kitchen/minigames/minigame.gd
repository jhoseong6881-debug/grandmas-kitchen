class_name Minigame
extends Control
## 요리 미니게임들의 공통 틀. 썰기, 담기, 볶기 미니게임이 이 스크립트를 물려받는다(extends Minigame).
## 공통으로 맡는 일: 누르기/손 떼기 입력(클릭, 스페이스/Enter, 게임패드 A) 감지, 연타 방지,
## 빗나간 횟수 세기, "완벽 도전 중" 표시, 완벽 도장, 끝나면 finished 시그널 보내기.
## 시간 제한과 실패는 없다. 빗나가도 벌칙 없이 다시 하면 된다.
##
## 물려받는 미니게임 씬에는 %TitleLabel, %ProgressLabel, %PerfectStreakLabel, %PerfectStamp 노드가 있어야 한다.
## 물려받는 스크립트가 채우는 함수:
##   _on_start(recipe)  : 미니게임을 처음 상태로 준비한다.
##   _on_press()        : 누를 때마다 불린다. 맞으면 진행하고, 빗나가면 _register_miss() 를 부른다.
##   _on_release()      : 손을 뗄 때마다 불린다. 꾹 누르는 미니게임에서 쓴다. (필요 없으면 안 채워도 된다)
##   다 끝나면 _complete(완료 문구) 를 부른다.

## is_perfect: 한 번도 빗나가지 않았으면 true
signal finished(is_perfect: bool)

## 한 번 누른 뒤 다음 입력을 받기까지 쉬는 시간(초). 마구 눌러 통과하는 것을 막는다.
@export var press_cooldown: float = 0.15
## 다 끝난 뒤 화면을 보여 주는 시간(초). 완벽했을 때는 도장이 잘 보이게 더 길게 보여 준다.
@export var finish_delay: float = 0.8
@export var perfect_finish_delay: float = 1.5
## 완벽 도장이 튀어나오는 크기 변화와 시간(초)
@export var stamp_start_scale: float = 0.3
@export var stamp_overshoot_scale: float = 1.15
@export var stamp_pop_duration: float = 0.18
@export var stamp_settle_duration: float = 0.1
## 처음 빗나갔을 때 "완벽 도전 중" 표시가 사라지는 시간(초)
@export var streak_fade_duration: float = 0.3

var _miss_count: int = 0
var _is_playing: bool = false
var _cooldown_left: float = 0.0

@onready var _title_label: Label = %TitleLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _perfect_streak_label: Label = %PerfectStreakLabel
@onready var _perfect_stamp: Label = %PerfectStamp


func _ready() -> void:
	_perfect_stamp.pivot_offset = _perfect_stamp.size / 2.0
	hide()


func start(recipe: Recipe) -> void:
	_miss_count = 0
	_is_playing = true
	_cooldown_left = 0.0
	_perfect_streak_label.modulate.a = 1.0
	_perfect_streak_label.show()
	_perfect_stamp.hide()
	_on_start(recipe)
	show()
	# 포커스를 가져와야 키보드와 게임패드 입력이 뒤에 있는 버튼으로 새지 않는다.
	grab_focus()


func _process(delta: float) -> void:
	if _is_playing:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func _gui_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	var is_left_click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT
	if (is_left_click and event.pressed) or event.is_action_pressed("ui_accept"):
		accept_event()
		if _cooldown_left > 0.0:
			return
		_cooldown_left = press_cooldown
		_on_press()
	elif (is_left_click and not event.pressed) or event.is_action_released("ui_accept"):
		accept_event()
		_on_release()


# --- 물려받는 스크립트가 채우는 함수 ---

func _on_start(_recipe: Recipe) -> void:
	pass


func _on_press() -> void:
	pass


func _on_release() -> void:
	pass


# --- 물려받는 스크립트가 부르는 함수 ---

func _register_miss() -> void:
	_miss_count += 1
	if _miss_count == 1:
		var tween: Tween = create_tween()
		tween.tween_property(_perfect_streak_label, "modulate:a", 0.0, streak_fade_duration)
		tween.tween_callback(_perfect_streak_label.hide)


func _complete(done_text: String) -> void:
	_is_playing = false
	_progress_label.text = done_text
	var is_perfect: bool = _miss_count == 0
	if is_perfect:
		_pop_perfect_stamp()
	# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
	await get_tree().create_timer(perfect_finish_delay if is_perfect else finish_delay, false).timeout
	hide()
	finished.emit(is_perfect)


## 완벽 도장이 작게 시작해서 살짝 크게 튀어나왔다가 제자리로 돌아온다.
func _pop_perfect_stamp() -> void:
	_perfect_streak_label.hide()
	_perfect_stamp.scale = Vector2.ONE * stamp_start_scale
	_perfect_stamp.show()
	var tween: Tween = create_tween()
	tween.tween_property(_perfect_stamp, "scale", Vector2.ONE * stamp_overshoot_scale, stamp_pop_duration)
	tween.tween_property(_perfect_stamp, "scale", Vector2.ONE, stamp_settle_duration)
