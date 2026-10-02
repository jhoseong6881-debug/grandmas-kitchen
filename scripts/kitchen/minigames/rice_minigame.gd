class_name RiceMinigame
extends Minigame
## 밥 짓기 미니게임. 쌀은 밥집에 늘 있어서 재료로 따로 내지 않는다. 두 단계로 한다.
##   1. 쌀 씻기: 바가지 안에서 손이 빙글빙글 돈다. 손이 금색 자리에 올 때 누르면 박박 씻는다.
##      씻을 때마다 뽀얀 물이 맑아지고 금색 자리가 옮겨 간다. washes_needed 번 씻으면 솥에 안친다.
##      다른 곳에서 누르면 빗나감. 그냥 지나쳐도 손은 계속 도니까 다음 바퀴에 누르면 된다.
##   2. 불 조절: 꾹 누르면 불이 세지고, 떼면 약해진다. 바늘이 금색 칸 안에 있는 동안에만 밥이 지어진다.
##      금색 칸보다 세지면 솥뚜껑이 들썩이고 빗나감(넘을 때마다 한 번). 약한 건 밥이 멈출 뿐 빗나감이 아니다.
## 누르기/손 떼기 입력, 연타 방지, 완벽 표시는 공통 틀(Minigame)이 맡는다.

enum Phase { WASHING, MOVING, COOKING }
enum Heat { LOW, GOOD, HIGH }

const WASH_TITLE: String = "쌀 씻기"
const WASH_STEP_FORMAT: String = "① 쌀 씻기 %d / %d"
const COOK_STEP_TEXT: String = "② 불 조절"
const WASH_READY_TEXT: String = "손이 금색 자리에 올 때 눌러요"
const WASH_HIT_FORMAT: String = "박박! %d / %d"
const WASH_MISS_FORMAT: String = "조금 빗나갔어요 %d / %d"
const WASHED_TEXT: String = "뽀득뽀득 깨끗해졌어요! 솥에 안쳐요"
const HEAT_LOW_TEXT: String = "불이 약해요. 꾹 눌러서 키워요"
const HEAT_GOOD_TEXT: String = "좋아요, 그대로! 밥 짓는 중"
const HEAT_HIGH_TEXT: String = "앗, 불이 너무 세요! 손을 떼요"
const DONE_TEXT: String = "고슬고슬 밥 완성!"
const WASH_HINT_TEXT: String = "빙글빙글 도는 손이 금색 자리에 오면 눌러서 씻어요 (클릭 / 스페이스 / Ⓐ)"
const COOK_HINT_TEXT: String = "꾹 누르면 불이 세지고, 떼면 약해져요. 바늘을 금색 칸 안에 두세요"

@export_group("쌀 씻기")
@export var washes_needed: int = 5
## 손이 바가지를 한 바퀴 도는 시간(초)
@export var wash_orbit_duration: float = 1.6
## 손이 도는 원의 반지름(픽셀)
@export var orbit_radius: float = 150.0
## 금색 자리 가운데에서 이 각도(라디안)만큼 떨어져 있어도 맞은 것으로 친다. 클수록 쉽다.
@export var wash_window: float = 0.45
## 판정을 후하게 해 주는 여유 각도(라디안). 화면에는 안 보인다.
@export var wash_margin: float = 0.08
## 씻을 때마다 금색 자리가 옮겨 가는 각도 범위(라디안). 바로 손 앞에 생기지 않도록 반 바퀴 근처로.
@export var target_jump_min: float = 2.0
@export var target_jump_max: float = 4.3
## 씻기 전 뽀얀 물 색과 다 씻은 맑은 물 색
@export var murky_color: Color = Color(0.93, 0.91, 0.84)
@export var clear_color: Color = Color(0.62, 0.8, 0.92)
## 쌀알 수, 쌀알이 흩어지는 반지름(픽셀), 쌀알 색
@export var rice_grain_count: int = 40
@export var rice_area_radius: float = 140.0
@export var rice_color: Color = Color(1, 1, 0.97)
## 씻을 때 쌀이 흔들리는 각도(라디안)와 시간(초)
@export var rub_jiggle_angle: float = 0.12
@export var rub_duration: float = 0.12
## 다 씻은 뒤 불 조절로 넘어가기까지 쉬는 시간(초)
@export var move_delay: float = 0.9

@export_group("불 조절")
## 꾹 누르고 있을 때 불이 세지는 속도, 떼었을 때 약해지는 속도 (1초에 바늘이 가는 비율)
@export var heat_rise_speed: float = 0.5
@export var heat_fall_speed: float = 0.35
## 금색 칸 (불 세기 0~1 중). 넓을수록 쉽다.
@export_range(0.0, 1.0) var heat_target_start: float = 0.55
@export_range(0.0, 1.0) var heat_target_end: float = 0.78
## 금색 칸 위로 이만큼은 봐준다. 화면에는 안 보인다.
@export var heat_margin: float = 0.03
## 금색 칸 안에서 이 시간(초)을 채우면 밥이 다 된다.
@export var cook_time_needed: float = 4.0
## 불꽃 크기 (불 세기 0일 때와 1일 때)
@export var flame_min_scale: float = 0.25
@export var flame_max_scale: float = 1.4
## 불이 너무 셀 때 솥뚜껑이 들썩이는 높이(픽셀)와 빠르기
@export var lid_rattle_height: float = 8.0
@export var lid_rattle_speed: float = 40.0

## 이번 단계의 씻는 수와 손이 한 바퀴 도는 시간 (요리 단계에서 정한 값, 없으면 위의 기본값)
var _washes_needed: int = 0
var _wash_orbit_duration: float = 1.6
var _phase: Phase = Phase.WASHING
var _washes_done: int = 0
var _hand_angle: float = 0.0
var _target_angle: float = 0.0
var _heat: float = 0.0
var _heat_state: Heat = Heat.LOW
## 밥이 지어진 정도 (0 ~ 1)
var _cook_progress: float = 0.0
var _is_holding: bool = false
var _rattle_time: float = 0.0
var _lid_home_y: float = 0.0
## 불 조절 단계의 제목 (레시피의 동작 이름, 기본 "밥 짓기")
var _cook_title: String = ""

@onready var _wash_area: Control = %WashArea
@onready var _water: Control = %Water
@onready var _rice_layer: Control = %RiceLayer
@onready var _rice_template: Control = %RiceTemplate
@onready var _hand: Control = %Hand
@onready var _wash_spot: Control = %WashSpot
@onready var _fire_area: Control = %FireArea
@onready var _lid: Control = %Lid
@onready var _flame: Control = %Flame
@onready var _steam: CPUParticles2D = %Steam
@onready var _heat_bar: Control = %HeatBar
@onready var _heat_gold_zone: ColorRect = %HeatGoldZone
@onready var _heat_over_zone: ColorRect = %HeatOverZone
@onready var _heat_marker: Control = %HeatMarker
@onready var _cook_bar: Control = %CookBar
@onready var _cook_fill: Control = %CookFill
@onready var _side_label: Label = %SideLabel
@onready var _hint_label: Label = %HintLabel


func _ready() -> void:
	super()
	_rice_template.hide()
	_lid_home_y = _lid.position.y
	_flame.pivot_offset = Vector2(_flame.size.x / 2.0, _flame.size.y)


func _on_start(recipe: Recipe) -> void:
	_washes_needed = _step_count(washes_needed)
	_wash_orbit_duration = wash_orbit_duration / _speed
	_cook_title = _step_action(Recipe.MinigameType.COOK_RICE)
	_start_washing()


# --- 쌀 씻기 ---

func _start_washing() -> void:
	_phase = Phase.WASHING
	_washes_done = 0
	_wash_area.show()
	_fire_area.hide()
	_scatter_rice()
	_water.self_modulate = murky_color
	_target_angle = randf() * TAU
	_hand_angle = _target_angle + PI
	_update_hand()
	_title_label.text = WASH_TITLE
	_side_label.text = WASH_STEP_FORMAT % [_washes_done, _washes_needed]
	_progress_label.text = WASH_READY_TEXT
	_hint_label.text = WASH_HINT_TEXT


func _scatter_rice() -> void:
	for grain: Node in _rice_layer.get_children():
		grain.queue_free()
	for i: int in rice_grain_count:
		var grain: Control = _rice_template.duplicate()
		var spot: Vector2 = Vector2.from_angle(randf() * TAU) * sqrt(randf()) * rice_area_radius
		grain.position = spot - grain.size / 2.0
		grain.pivot_offset = grain.size / 2.0
		grain.rotation = randf() * TAU
		grain.self_modulate = rice_color
		grain.show()
		_rice_layer.add_child(grain)


func is_hand_on_spot() -> bool:
	return _phase == Phase.WASHING \
			and absf(wrapf(_hand_angle - _target_angle, -PI, PI)) <= wash_window + wash_margin


func _wash() -> void:
	_washes_done += 1
	_water.self_modulate = murky_color.lerp(clear_color, float(_washes_done) / _washes_needed)
	_side_label.text = WASH_STEP_FORMAT % [_washes_done, _washes_needed]
	_progress_label.text = WASH_HIT_FORMAT % [_washes_done, _washes_needed]
	var tween: Tween = create_tween()
	tween.tween_property(_rice_layer, "rotation", rub_jiggle_angle, rub_duration)
	tween.tween_property(_rice_layer, "rotation", 0.0, rub_duration)
	if _washes_done >= _washes_needed:
		_phase = Phase.MOVING
		_wash_spot.hide()
		_progress_label.text = WASHED_TEXT
		# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
		await get_tree().create_timer(move_delay, false).timeout
		if _is_playing:
			_start_cooking()
		return
	_target_angle = wrapf(_target_angle + randf_range(target_jump_min, target_jump_max), 0.0, TAU)
	_update_hand()


## 손과 금색 자리를 원 위에 놓는다. 손이 금색 자리에 있으면 금색 자리가 밝아진다.
func _update_hand() -> void:
	var center: Vector2 = _wash_area.size / 2.0
	_hand.position = center + Vector2.from_angle(_hand_angle) * orbit_radius - _hand.size / 2.0
	_wash_spot.position = center + Vector2.from_angle(_target_angle) * orbit_radius - _wash_spot.size / 2.0
	_wash_spot.visible = _phase == Phase.WASHING
	_wash_spot.modulate.a = 1.0 if is_hand_on_spot() else 0.55


# --- 불 조절 ---

func _start_cooking() -> void:
	_phase = Phase.COOKING
	_heat = 0.0
	_heat_state = Heat.LOW
	_cook_progress = 0.0
	_is_holding = false
	_wash_area.hide()
	_fire_area.show()
	var width: float = _heat_bar.size.x
	_heat_gold_zone.position.x = heat_target_start * width
	_heat_gold_zone.size.x = (heat_target_end - heat_target_start) * width
	_heat_over_zone.position.x = heat_target_end * width
	_heat_over_zone.size.x = (1.0 - heat_target_end) * width
	_title_label.text = _cook_title
	_side_label.text = COOK_STEP_TEXT
	_progress_label.text = HEAT_LOW_TEXT
	_hint_label.text = COOK_HINT_TEXT
	_update_fire(0.0)


func _cook(delta: float) -> void:
	var speed: float = heat_rise_speed if _is_holding else -heat_fall_speed
	_heat = clampf(_heat + speed * delta, 0.0, 1.0)
	var new_state: Heat = Heat.GOOD
	if _heat < heat_target_start:
		new_state = Heat.LOW
	elif _heat > heat_target_end + heat_margin:
		new_state = Heat.HIGH
	if new_state != _heat_state:
		_heat_state = new_state
		if new_state == Heat.HIGH:
			_register_miss()
		_progress_label.text = [HEAT_LOW_TEXT, HEAT_GOOD_TEXT, HEAT_HIGH_TEXT][new_state]
	if _heat_state == Heat.GOOD:
		_cook_progress = minf(_cook_progress + delta / cook_time_needed, 1.0)
	_update_fire(delta)
	if _cook_progress >= 1.0:
		_phase = Phase.MOVING
		_heat = 0.0
		_update_fire(0.0)
		_complete(DONE_TEXT)


## 불꽃 크기, 바늘, 밥 짓기 막대, 김, 솥뚜껑 들썩임을 지금 상태에 맞춘다.
func _update_fire(delta: float) -> void:
	_flame.scale = Vector2.ONE * lerpf(flame_min_scale, flame_max_scale, _heat)
	_heat_marker.position.x = _heat * _heat_bar.size.x - _heat_marker.size.x / 2.0
	_cook_fill.size.x = _cook_progress * _cook_bar.size.x
	_steam.modulate.a = _cook_progress
	if _heat_state == Heat.HIGH:
		_rattle_time += delta
		_lid.position.y = _lid_home_y - absf(sin(_rattle_time * lid_rattle_speed)) * lid_rattle_height
	else:
		_lid.position.y = _lid_home_y


# --- 입력과 매 프레임 ---

func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing:
		return
	if _phase == Phase.WASHING:
		_hand_angle = wrapf(_hand_angle + TAU * delta / _wash_orbit_duration, 0.0, TAU)
		_update_hand()
	elif _phase == Phase.COOKING:
		_cook(delta)


func _on_press() -> void:
	if _phase == Phase.WASHING:
		if is_hand_on_spot():
			# 손이 금색 자리에 들어오는 쪽 = 0, 나가는 쪽 = 1
			_register_hit((wrapf(_hand_angle - _target_angle, -PI, PI) + wash_window) / (2.0 * wash_window))
			_wash()
		else:
			_register_miss()
			_progress_label.text = WASH_MISS_FORMAT % [_washes_done, _washes_needed]
	elif _phase == Phase.COOKING:
		_is_holding = true


func _on_release() -> void:
	_is_holding = false
