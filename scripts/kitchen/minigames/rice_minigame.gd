class_name RiceMinigame
extends Minigame
## 밥 짓기 미니게임. 쌀은 밥집에 늘 있어서 재료로 따로 내지 않는다. 두 단계로 한다.
##   1. 쌀 씻기: 손이 커서를 따라 바가지 안을 다닌다. 물 위에 뽀얀 자리가 씻을 횟수만큼 흩어져 있고,
##      그 자리를 클릭(Ⓐ·스페이스)하면 박박 씻겨 사라지고 물이 맑아진다. 빈 곳을 누르면 쌀만 살짝 흔들린다.
##      뽀얀 자리를 다 씻으면 솥에 안친다.
##   2. 불 조절: 누르지 않고 커서를 좌우로 움직이면 불 손잡이(바늘)가 따라간다 (왼쪽 = 약불, 오른쪽 = 센불).
##      불은 저절로 조금씩 일렁여서 가끔 손잡이를 고쳐 잡아야 한다. 바늘이 금색 칸 안에 있는 동안에만 밥이 지어진다.
##      금색 칸보다 세면 솥뚜껑이 들썩이고 밥이 멈출 뿐, 약한 것도 멈출 뿐이다. 빗나감·실패는 없다 (완벽 도장도 없다).
## 게임패드·방향키: 스틱으로 손을 옮기고 Ⓐ로 씻는다. 불 조절은 스틱 좌우.
## 할머니 비법 자리·부탁 자리 = 씻을 때 누른 자리: 0.5 = 뽀얀 자리 한가운데, 0 / 1 = 왼쪽 / 오른쪽 가장자리.

enum Phase { WASHING, MOVING, COOKING }
enum Heat { LOW, GOOD, HIGH }

const WASH_TITLE: String = "쌀 씻기"
const WASH_STEP_FORMAT: String = "① 쌀 씻기 %d / %d"
const COOK_STEP_TEXT: String = "② 불 조절"
const WASH_READY_TEXT: String = "뽀얀 자리를 클릭해서 박박 씻어요"
const WASH_HIT_FORMAT: String = "박박! %d / %d"
const WASHED_TEXT: String = "뽀득뽀득 깨끗해졌어요! 솥에 안쳐요"
const HEAT_LOW_TEXT: String = "불이 약해요. 손잡이를 오른쪽으로"
const HEAT_GOOD_TEXT: String = "좋아요, 그대로! 밥 짓는 중"
const HEAT_HIGH_TEXT: String = "앗, 불이 너무 세요! 손잡이를 왼쪽으로"
const DONE_TEXT: String = "고슬고슬 밥 완성!"
const WASH_HINT_TEXT: String = "손으로 뽀얀 자리를 클릭해서 박박 씻어요   (패드: 스틱으로 옮기고 Ⓐ)"
const COOK_HINT_TEXT: String = "커서를 좌우로 움직여 불 손잡이를 돌려요. 바늘을 금색 칸 안에 두세요   (패드: 스틱 좌우)"

@export_group("쌀 씻기")
@export var washes_needed: int = 5
## 뽀얀 자리 지름(픽셀)과 색 (뽀얀 물보다 조금 진하게)
@export var murky_spot_size: float = 110.0
@export var murky_spot_color: Color = Color(0.78, 0.74, 0.6, 0.95)
## 뽀얀 자리가 흩어지는 반지름(바가지 가운데에서, 픽셀)과 자리끼리 떨어져야 하는 거리(픽셀)
@export var murky_spread_radius: float = 140.0
@export var murky_min_gap: float = 90.0
## 씻긴 뽀얀 자리가 흐려지며 사라지는 시간(초)
@export var murky_fade_duration: float = 0.3
## 게임패드·방향키로 손을 옮기는 빠르기(초당 픽셀)
@export var pad_hand_speed: float = 500.0
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
## 바늘이 손잡이를 따라가는 빠르기 (1초에 따라잡는 정도)와, 게임패드·방향키로 손잡이를 돌리는 빠르기 (1초에 막대의 비율)
@export var heat_follow: float = 6.0
@export var pad_heat_speed: float = 0.6
## 불이 저절로 일렁이는 정도 (불 세기 0~1 중)와 빠르기
@export var heat_drift_amount: float = 0.18
@export var heat_drift_speed: float = 0.8
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
## 솥 끓는 보글보글 소리(loop_cook_rice) 크기: 불이 꺼져 갈 때와 가장 셀 때 (데시벨, 소리 파일 크기에서 더하는 값)
@export var boil_quiet_db: float = -16.0
@export var boil_loud_db: float = 3.0

## 이번 단계의 씻는 수 (요리 단계에서 정한 값, 없으면 위의 기본값)
var _washes_needed: int = 0
## 이번에 밥이 다 되기까지 금색 칸에서 보내야 하는 시간 (무쇠솥이 있으면 짧아진다)
var _cook_time_needed: float = 4.0
var _phase: Phase = Phase.WASHING
var _washes_done: int = 0
## 아직 안 씻은 뽀얀 자리들
var _murky_spots: Array[Panel] = []
## 손 자리 (바가지 영역 기준)
var _hand_point: Vector2
## 불 손잡이 자리 (0~1)와, 일렁임을 더한 지금 불 세기
var _knob: float = 0.0
var _heat: float = 0.0
var _heat_state: Heat = Heat.LOW
var _flame_time: float = 0.0
## 밥이 지어진 정도 (0 ~ 1)
var _cook_progress: float = 0.0
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
	# 예전 금색 자리는 쓰지 않는다 (뽀얀 자리를 새로 만든다).
	_wash_spot.hide()
	_lid_home_y = _lid.position.y
	_flame.pivot_offset = Vector2(_flame.size.x / 2.0, _flame.size.y)


## 보글보글 소리는 쌀을 다 씻고 불 조절을 시작할 때 켠다.
func _loop_from_start() -> bool:
	return false


func _get_minigame_type() -> Recipe.MinigameType:
	return Recipe.MinigameType.COOK_RICE


func _uses_perfect_stamp() -> bool:
	return false


func _on_start(recipe: Recipe) -> void:
	_washes_needed = _step_count(washes_needed)
	_cook_time_needed = cook_time_needed * _duration_scale
	_cook_title = _step_action(Recipe.MinigameType.COOK_RICE)
	_start_washing()


# --- 쌀 씻기 ---

func _start_washing() -> void:
	_phase = Phase.WASHING
	_washes_done = 0
	_wash_area.show()
	_fire_area.hide()
	_scatter_rice()
	_scatter_murky_spots()
	_water.self_modulate = murky_color
	_hand_point = _wash_area.size / 2.0 + Vector2(0.0, murky_spread_radius + murky_spot_size / 2.0)
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


## 뽀얀 자리를 씻을 횟수만큼 바가지 물 위에 서로 떨어지게 흩어 놓는다 (쌀알 위, 손 아래).
func _scatter_murky_spots() -> void:
	for spot: Panel in _murky_spots:
		spot.queue_free()
	_murky_spots.clear()
	var center: Vector2 = _wash_area.size / 2.0
	var placed: Array[Vector2] = []
	for i: int in _washes_needed:
		var point: Vector2 = center
		# 다른 자리와 겹치지 않는 곳을 몇 번 찾아보고, 못 찾으면 마지막 자리에 둔다.
		for attempt: int in 30:
			point = center + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * murky_spread_radius
			if placed.all(func(other: Vector2) -> bool: return other.distance_to(point) >= murky_min_gap):
				break
		placed.append(point)
		var spot: Panel = Panel.new()
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = murky_spot_color
		style.set_corner_radius_all(int(murky_spot_size / 2.0))
		spot.add_theme_stylebox_override("panel", style)
		spot.size = Vector2.ONE * murky_spot_size
		spot.position = point - spot.size / 2.0
		spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_wash_area.add_child(spot)
		_wash_area.move_child(spot, _hand.get_index())
		_murky_spots.append(spot)


## 손 자리에서 가장 가까운, 손이 올라가 있는 뽀얀 자리. 없으면 null.
func _murky_spot_under_hand() -> Panel:
	var best: Panel = null
	var best_distance: float = murky_spot_size / 2.0
	for spot: Panel in _murky_spots:
		var distance: float = _hand_point.distance_to(spot.position + spot.size / 2.0)
		if distance <= best_distance:
			best = spot
			best_distance = distance
	return best


## 손 자리를 누른다. 뽀얀 자리 위면 박박 씻고, 아니면 쌀만 살짝 흔들린다.
func _press_wash() -> void:
	var spot: Panel = _murky_spot_under_hand()
	_jiggle_rice()
	if spot == null:
		_play_hit_sound()
		return
	# 뽀얀 자리 한가운데 = 0.5, 왼쪽 끝 = 0, 오른쪽 끝 = 1
	var offset: Vector2 = _hand_point - (spot.position + spot.size / 2.0)
	var side: float = -1.0 if offset.x < 0.0 else 1.0
	_register_hit(0.5 + 0.5 * clampf(offset.length() / (murky_spot_size / 2.0), 0.0, 1.0) * side)
	_murky_spots.erase(spot)
	var tween: Tween = create_tween()
	tween.tween_property(spot, "modulate:a", 0.0, murky_fade_duration)
	tween.tween_callback(spot.queue_free)
	_wash()


func _jiggle_rice() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_rice_layer, "rotation", rub_jiggle_angle, rub_duration)
	tween.tween_property(_rice_layer, "rotation", 0.0, rub_duration)


func _wash() -> void:
	_washes_done += 1
	_water.self_modulate = murky_color.lerp(clear_color, float(_washes_done) / _washes_needed)
	_side_label.text = WASH_STEP_FORMAT % [_washes_done, _washes_needed]
	_progress_label.text = WASH_HIT_FORMAT % [_washes_done, _washes_needed]
	if _washes_done >= _washes_needed:
		_phase = Phase.MOVING
		_progress_label.text = WASHED_TEXT
		# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
		await get_tree().create_timer(move_delay, false).timeout
		if _is_playing:
			_start_cooking()


func _update_hand() -> void:
	_hand.position = _hand_point - _hand.size / 2.0
	_hand.visible = _phase == Phase.WASHING


# --- 불 조절 ---

func _start_cooking() -> void:
	_phase = Phase.COOKING
	_knob = 0.0
	_heat = 0.0
	_flame_time = 0.0
	_heat_state = Heat.LOW
	_cook_progress = 0.0
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
	Sound.start_loop(_loop_sound, boil_quiet_db)


func _cook(delta: float) -> void:
	_flame_time += delta
	# 손잡이 자리에 불이 저절로 일렁이는 만큼을 더한다.
	var drift: float = heat_drift_amount * (0.6 * sin(_flame_time * heat_drift_speed * TAU / 3.0) \
			+ 0.4 * sin(_flame_time * heat_drift_speed * TAU / 1.3 + 1.0))
	_heat = lerpf(_heat, clampf(_knob + drift, 0.0, 1.0), clampf(heat_follow * delta, 0.0, 1.0))
	var new_state: Heat = Heat.GOOD
	if _heat < heat_target_start:
		new_state = Heat.LOW
	elif _heat > heat_target_end + heat_margin:
		new_state = Heat.HIGH
	if new_state != _heat_state:
		_heat_state = new_state
		_progress_label.text = [HEAT_LOW_TEXT, HEAT_GOOD_TEXT, HEAT_HIGH_TEXT][new_state]
	if _heat_state == Heat.GOOD:
		_cook_progress = minf(_cook_progress + delta / _cook_time_needed, 1.0)
	_update_fire(delta)
	Sound.set_loop_volume(_loop_sound, lerpf(boil_quiet_db, boil_loud_db, _heat))
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
	var pad: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if _phase == Phase.WASHING and pad != Vector2.ZERO:
		_move_hand_to(_hand_point + pad * pad_hand_speed * delta)
	elif _phase == Phase.COOKING:
		if pad.x != 0.0:
			_knob = clampf(_knob + pad.x * pad_heat_speed * delta, 0.0, 1.0)
		_cook(delta)


## 마우스는 손(씻기)이나 불 손잡이(불 조절)를 옮기고, 클릭·Ⓐ(스페이스)는 씻는다.
## 방향은 포커스가 다른 버튼으로 새지 않게 먹는다.
func _gui_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		accept_event()
		_follow_mouse(event.position)
		if event is InputEventMouseButton and event.pressed and _phase == Phase.WASHING:
			_press_wash()
		return
	if event.is_action_pressed(&"ui_accept"):
		accept_event()
		if _phase == Phase.WASHING:
			_press_wash()
		return
	for action: StringName in [&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"ui_accept"]:
		if event.is_action(action):
			accept_event()
			return


## 씻기 중에는 손을 커서 자리로, 불 조절 중에는 불 손잡이를 커서의 좌우 자리(불 막대 기준)로 옮긴다.
func _follow_mouse(at: Vector2) -> void:
	if _phase == Phase.WASHING:
		_move_hand_to(_local_point(_wash_area, at))
	elif _phase == Phase.COOKING:
		_knob = clampf(_local_point(_heat_bar, at).x / _heat_bar.size.x, 0.0, 1.0)


func _move_hand_to(at: Vector2) -> void:
	_hand_point = at.clamp(Vector2.ZERO, _wash_area.size)
	_update_hand()


## 미니게임 좌표 at 을 target 안쪽 좌표로 바꾼다.
func _local_point(target: Control, at: Vector2) -> Vector2:
	return target.get_global_transform().affine_inverse() * (get_global_transform() * at)
