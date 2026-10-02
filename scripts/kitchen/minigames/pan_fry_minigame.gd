class_name PanFryMinigame
extends Minigame
## 부치기 미니게임 (노릇할 때 뒤집기). 팬 위의 전이 지글지글 익으며 색이 하양 → 노랑 → 금색 → 갈색으로 변한다.
## 금색(노릇노릇)일 때 누르면 뒤집는다. 앞면을 뒤집고, 뒷면까지 익으면 다시 눌러 접시로 옮긴다.
## 전 jeon_count 장을 다 부치면 완성.
## 너무 일찍 누르면 빗나감이지만 그대로 계속 익는다. 늦게 누르면 조금 진하게 익었을 뿐 넘어가고, 빗나감으로 센다.
## 타서 실패하는 일은 없다. 누르기 입력, 연타 방지, 완벽 표시는 공통 틀(Minigame)이 맡는다.

enum JeonState { COOKING, MOVING }

const SIDE_FORMAT: String = "전 %d / %d · %s"
const READY_TEXT: String = "전이 금색으로 노릇해지면 눌러요"
const FRONT_SIDE_TEXT: String = "앞면"
const BACK_SIDE_TEXT: String = "뒷면"
const FLIP_TEXT: String = "착! 노릇노릇하게 뒤집었어요"
const LIFT_TEXT: String = "노릇노릇! 접시에 담았어요"
const EARLY_TEXT: String = "아직 덜 익었어요. 조금 더 기다려요"
const LATE_TEXT: String = "앗, 조금 진하게 익었어요"
const DONE_TEXT: String = "노릇노릇 다 부쳤어요!"
## 한 장을 다 부치려면 앞면, 뒷면 두 번 눌러야 한다.
const SIDES_PER_JEON: int = 2

@export var jeon_count: int = 3
## 한 면이 하양에서 완전히 갈색이 될 때까지 걸리는 시간(초). 면마다 cook_duration_variance 만큼 조금씩 달라진다.
@export var cook_duration: float = 2.4
@export var cook_duration_variance: float = 0.15
## 익은 정도(0~1) 중 금색(노릇노릇) 구간. 이때 누르면 성공. 넓을수록 쉽다.
@export_range(0.0, 1.0) var golden_start: float = 0.6
@export_range(0.0, 1.0) var golden_end: float = 0.8
## 금색 구간 양쪽으로 이만큼 더 봐준다. 화면에는 안 보인다.
@export var judge_margin: float = 0.03
## 익는 색: 처음(하양) → 노랑 → 금색(노릇) → 다 지나면 갈색
@export var raw_color: Color = Color(0.98, 0.95, 0.82)
@export var light_color: Color = Color(0.98, 0.86, 0.45)
@export var golden_color: Color = Color(0.93, 0.66, 0.2)
@export var over_color: Color = Color(0.55, 0.32, 0.14)
## 금색 구간일 때 전 둘레가 빛나는 정도
@export var glow_alpha: float = 0.9
## 뒤집을 때 전이 튀어 오르는 높이(픽셀)와 시간(초)
@export var flip_hop_height: float = 80.0
@export var flip_duration: float = 0.3
## 다 익은 전이 접시로 미끄러져 가는 시간(초)과 다음 전이 놓이기까지 쉬는 시간(초)
@export var lift_duration: float = 0.35
## 접시로 가면서 작아지는 크기 (접시 줄의 작은 전 크기에 맞춘다)
@export var lift_end_scale: float = 0.2
@export var next_jeon_delay: float = 0.3

## 이번 단계의 전 장수와 한 면 익는 시간 (요리 단계에서 정한 값, 없으면 위의 기본값)
var _jeon_count: int = 0
var _cook_duration: float = 2.4
var _state: JeonState = JeonState.COOKING
## 지금 익히는 면의 익은 정도. 0 = 날것, 1 = 완전히 갈색.
var _doneness: float = 0.0
var _side_duration: float = 2.4
## 다 부친 전 수, 지금 전에서 끝낸 면 수
var _jeons_done: int = 0
var _sides_done: int = 0
## 전의 처음 자리 (뒤집고 옮긴 뒤 되돌릴 때 쓴다)
var _jeon_home: Vector2

@onready var _jeon: Control = %Jeon
@onready var _glow: Control = %Glow
@onready var _doneness_bar: Control = %DonenessBar
@onready var _gold_zone: ColorRect = %GoldZone
@onready var _over_zone: ColorRect = %OverZone
@onready var _marker: Control = %Marker
@onready var _done_row: HBoxContainer = %DoneRow
@onready var _done_template: Control = %DoneTemplate
@onready var _side_label: Label = %SideLabel


func _ready() -> void:
	super()
	_done_template.hide()
	_jeon_home = _jeon.position
	_jeon.pivot_offset = _jeon.size / 2.0


func _on_start(recipe: Recipe) -> void:
	_jeon_count = _step_count(jeon_count)
	_cook_duration = cook_duration / _speed
	_jeons_done = 0
	for child: Node in _done_row.get_children():
		child.queue_free()
	_layout_doneness_bar()
	_clear_secret_zone(_gold_zone)
	_title_label.text = _step_title(Recipe.MinigameType.PAN_FRY, _default_subject(recipe))
	_progress_label.text = READY_TEXT
	_place_new_jeon()


func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing or _state != JeonState.COOKING:
		return
	_doneness = minf(_doneness + delta / _side_duration, 1.0)
	_update_jeon_look()


func _on_press() -> void:
	if _state != JeonState.COOKING:
		return
	if _doneness < golden_start - judge_margin:
		_register_miss()
		_progress_label.text = EARLY_TEXT
		return
	if _doneness > golden_end + judge_margin:
		_register_miss()
		_progress_label.text = LATE_TEXT
	else:
		# 막 금색이 됐을 때 = 0, 짙은 금색 끝 = 1
		_register_hit((_doneness - golden_start) / (golden_end - golden_start))
	_sides_done += 1
	if _sides_done >= SIDES_PER_JEON:
		_lift_jeon()
	else:
		_flip_jeon()


## 익힘 막대의 금색 칸 안에 비법 자리를 그린다.
func _show_secret_zone(start: float, end: float) -> void:
	var width: float = _gold_zone.size.x
	_make_secret_zone(_gold_zone, Rect2(start * width, 0.0, (end - start) * width, _gold_zone.size.y))


func is_golden() -> bool:
	return _state == JeonState.COOKING \
			and _doneness >= golden_start - judge_margin and _doneness <= golden_end + judge_margin


## 새 전을 팬에 놓고 앞면부터 익힌다.
func _place_new_jeon() -> void:
	_sides_done = 0
	_jeon.position = _jeon_home
	_jeon.scale = Vector2.ONE
	_jeon.show()
	_start_side()


func _start_side() -> void:
	_state = JeonState.COOKING
	_doneness = 0.0
	_side_duration = _cook_duration * (1.0 + randf_range(-cook_duration_variance, cook_duration_variance))
	_update_jeon_look()
	_side_label.text = SIDE_FORMAT % [_jeons_done + 1, _jeon_count,
			FRONT_SIDE_TEXT if _sides_done == 0 else BACK_SIDE_TEXT]


## 전이 살짝 튀어 오르며 납작해졌다가(뒤집히는 중) 다시 펴진다. 펴지면 뒷면을 익힌다.
func _flip_jeon() -> void:
	_state = JeonState.MOVING
	if _doneness <= golden_end + judge_margin:
		_progress_label.text = FLIP_TEXT
	var half: float = flip_duration / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(_jeon, "scale:y", 0.0, half)
	tween.parallel().tween_property(_jeon, "position:y", _jeon_home.y - flip_hop_height, half) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(_show_raw_side)
	tween.tween_property(_jeon, "scale:y", 1.0, half)
	tween.parallel().tween_property(_jeon, "position:y", _jeon_home.y, half) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.finished.connect(_start_side)


func _show_raw_side() -> void:
	_doneness = 0.0
	_update_jeon_look()


## 다 익은 전을 왼쪽 접시로 옮긴다. 다 부쳤으면 완성.
func _lift_jeon() -> void:
	_state = JeonState.MOVING
	if _doneness <= golden_end + judge_margin:
		_progress_label.text = LIFT_TEXT
	_glow.modulate.a = 0.0
	var finished_color: Color = _jeon.self_modulate
	# 접시 가운데로 미끄러져 간다.
	var target: Vector2 = _done_row.global_position + _done_row.size / 2.0 - _jeon.get_parent().global_position
	var tween: Tween = create_tween()
	tween.tween_property(_jeon, "position", target - _jeon.size / 2.0, lift_duration) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(_jeon, "scale", Vector2.ONE * lift_end_scale, lift_duration)
	tween.tween_callback(_on_jeon_lifted.bind(finished_color))


func _on_jeon_lifted(finished_color: Color) -> void:
	_jeon.hide()
	var done_jeon: Control = _done_template.duplicate()
	done_jeon.self_modulate = finished_color
	done_jeon.show()
	_done_row.add_child(done_jeon)
	_jeons_done += 1
	if _jeons_done >= _jeon_count:
		_complete(DONE_TEXT)
		return
	# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
	await get_tree().create_timer(next_jeon_delay, false).timeout
	if _is_playing:
		_place_new_jeon()


## 익은 정도에 따라 전 색을 바꾸고, 금색 구간이면 둘레를 빛나게, 막대 표시를 옮긴다.
func _update_jeon_look() -> void:
	_jeon.self_modulate = _doneness_color(_doneness)
	_glow.modulate.a = glow_alpha if is_golden() else 0.0
	_marker.position.x = _doneness * _doneness_bar.size.x - _marker.size.x / 2.0


func _doneness_color(doneness: float) -> Color:
	if doneness < golden_start:
		var t: float = doneness / golden_start
		return raw_color.lerp(light_color, t * 2.0) if t < 0.5 else light_color.lerp(golden_color, t * 2.0 - 1.0)
	if doneness <= golden_end:
		return golden_color
	return golden_color.lerp(over_color, (doneness - golden_end) / (1.0 - golden_end))


## 익힘 막대에서 금색 구간과 갈색 구간의 자리를 golden_start, golden_end 에 맞춘다.
func _layout_doneness_bar() -> void:
	var width: float = _doneness_bar.size.x
	_gold_zone.position.x = golden_start * width
	_gold_zone.size.x = (golden_end - golden_start) * width
	_over_zone.position.x = golden_end * width
	_over_zone.size.x = (1.0 - golden_end) * width
