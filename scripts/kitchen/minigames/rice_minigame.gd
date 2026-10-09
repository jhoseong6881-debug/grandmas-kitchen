class_name RiceMinigame
extends Minigame
## 밥 짓기 미니게임. 쌀은 밥집에 늘 있어서 재료로 따로 내지 않는다. 세 단계로 한다.
##   1. 쌀 씻기 (요리 단계의 횟수만큼 되풀이):
##      비비기 - 손이 커서를 따라다니고, 누르지 않고 쌀 위를 쓱쓱 문지르면 물이 점점 뽀얘진다.
##      뜨물 버리기 - 다 비비면 커서를 오른쪽으로 밀어 바가지를 기울인다. 많이 기울일수록 뜨물이 빨리 빠진다.
##      너무 확 기울이면 쌀알 몇 개가 톡 흘러나갔다가 다시 쏙 들어온다 (손해 없음). 물이 다 빠지면 새 물을 받는다.
##      되풀이할수록 뜨물이 덜 뽀얘진다.
##   2. 물 맞추기: 솥 안 쌀 위에 손이 납작하게 얹혀 있다. 누르고 있는 동안 물이 차오르고, 떼면 멈춘다.
##      떼고 water_settle_time 초가 지나면 그 물 높이로 정하고 넘어간다 (그 전에 다시 누르면 더 붓는다).
##      솥 양쪽 안벽의 하얀 표시 사이(눈금의 초록 칸, water_min_level ~ water_max_level)가 알맞은 물이다. 모자라면 "조금 더 부어요",
##      넘치면 물을 따라 내고 처음부터 다시 받는다 (손해 없음. 2026-10-09 "아무렇게나 부어도 성공한다"는 피드백으로 바꿈).
##      할머니 비법 자리·부탁 자리 = 물 높이: 0 = 쌀 바로 위, 0.5 = 손등, 1 = 손등 위로 손 두께만큼. 솥 왼쪽 눈금에 그린다.
##   3. 불 조절 (가마솥 3단 불, 2026-10-09 "밋밋하다"는 피드백으로 바꿈): 누르지 않고 커서를 좌우로 움직이면 불 손잡이(바늘)가
##      따라간다 (왼쪽 = 약불, 오른쪽 = 센불). 진짜 가마솥 밥처럼 센불 → 끓어오르면 중불 → 약불로 뜸 들이기.
##      지금 단계의 금색 칸 안에 바늘이 있는 동안에만 그 단계가 진행된다. 센불이 거의 차면 보글보글 뚜껑이 살짝 들썩이고,
##      다 차면 뚜껑이 "들썩! 들썩!" 두 번 뛰며 중불로 넘어간다. 그때 불을 안 줄이면 거품이 넘치려 하고 뚜껑이 들썩일 뿐
##      (진행만 멈춤), 너무 약해도 멈출 뿐이다. 단계별 칸과 시간 비율은 cook_stage_ranges / cook_stage_shares.
## 빗나감·실패는 없다 (완벽 도장도 없다).
## 게임패드·방향키: 스틱으로 손을 옮기고 바가지를 기울인다. Ⓐ를 누르고 있으면 물을 붓는다. 불 조절은 스틱 좌우.

enum Phase { RUBBING, DRAINING, WATERING, MOVING, COOKING }
enum Heat { LOW, GOOD, HIGH }
## 불 조절 단계: 센불로 끓이기 → 중불 → 약불로 뜸 들이기
enum CookStage { BOIL, SIMMER, REST }

const WASH_TITLE: String = "쌀 씻기"
const WATER_TITLE: String = "물 맞추기"
const WASH_STEP_FORMAT: String = "① 쌀 씻기 %d / %d"
const WATER_STEP_TEXT: String = "② 물 맞추기"
const COOK_STEP_FORMAT: String = "③ 불 조절 · %s"
const RUB_TEXT: String = "쌀을 쓱쓱 문질러 비벼요"
const DRAIN_TEXT: String = "뽀얘졌어요! 오른쪽으로 기울여 뜨물을 버려요"
const SPILL_TEXT: String = "앗, 쌀알이 톡! 살살 기울여요"
const REFILL_TEXT: String = "새 물을 받았어요. 또 박박 비벼요"
const WASHED_TEXT: String = "뽀득뽀득 깨끗해졌어요! 솥에 안쳐요"
const WATER_TEXT: String = "누르고 있으면 물이 차요. 솥 벽의 하얀 표시 사이에서 떼요 (손등이 찰랑찰랑)"
const WATER_TOO_MUCH_TEXT: String = "넘쳐요! 손을 떼요"
const WATER_POUR_OFF_TEXT: String = "앗, 물이 너무 많아요! 따라 내고 다시 받아요"
## 물이 너무 많아 따라 낼 때 나는 소리 ("할 수 없어요" 소리)
const WATER_POUR_OFF_SOUND: StringName = &"miss"
const WATER_MORE_TEXT: String = "조금 더 부어요"
const WATER_DONE_TEXT: String = "물 맞췄어요! 불을 지펴요"
const DONE_TEXT: String = "고슬고슬 밥 완성!"
const WASH_HINT_TEXT: String = "쌀 위를 쓱쓱 문질러 비비고, 커서를 오른쪽으로 밀어 뜨물을 버려요   (패드: 스틱)"
const WATER_HINT_TEXT: String = "누르고 있는 동안 물을 부어요. 솥 벽의 하얀 표시 사이에서 손을 떼요   (패드: Ⓐ 누르고 있기)"
const COOK_HINT_TEXT: String = "커서를 좌우로 움직여 불 손잡이를 돌려요. 센불 → 끓어오르면 중불 → 약불로 뜸   (패드: 스틱 좌우)"
## 단계 이름 (CookStage 차례)
const COOK_STAGE_NAMES: PackedStringArray = ["센불", "중불", "약불 뜸"]
## 단계마다 불이 약할 때 / 알맞을 때 / 셀 때 글 (CookStage 차례, 안은 Heat 차례)
const COOK_STAGE_TEXTS: Array = [
	["불이 약해요. 처음엔 센불로! 손잡이를 오른쪽 끝으로", "센불로 끓이는 중… 보글보글 소리가 날 때까지", "센불로 끓이는 중… 보글보글 소리가 날 때까지"],
	["불이 너무 약해요. 손잡이를 가운데로", "중불로 자작자작… 좋아요", "앗, 거품이 넘치려 해요! 불을 줄여요 (가운데로)"],
	["불이 꺼지겠어요. 아주 살짝만 켜 둬요", "약불로 뜸 들이는 중… 구수한 냄새", "뜸 들일 땐 약불로! 손잡이를 왼쪽으로"],
]
const BOIL_SOON_TEXT: String = "보글보글… 곧 끓어올라요!"
const BOILED_TEXT: String = "들썩! 들썩! 끓어올랐어요. 이제 불을 줄여요 (가운데로)"
const SIMMERED_TEXT: String = "물이 잦아들었어요. 이제 약불로 뜸 들여요 (왼쪽으로)"
## 솥뚜껑이 들썩 뛸 때 소리 (아직 전용 소리가 없어 퐁 소리. docs/audio-todo.md)
const LID_HOP_SOUND: StringName = &"pop"

@export_group("쌀 씻기")
## 씻는 횟수 (요리 단계의 횟수가 없을 때). 한 번 = 비비기 + 뜨물 버리기.
@export var washes_needed: int = 3
## 한 번 씻을 때 다 비비려면 쌀 위에서 손이 움직여야 하는 거리(픽셀)
@export var rub_distance_needed: float = 900.0
## 손이 바가지 가운데에서 이 거리(픽셀) 안에 있어야 쌀을 비빈다
@export var rub_reach: float = 170.0
## 비빌 때 이 거리(픽셀)를 움직일 때마다 쌀이 살짝 흔들린다
@export var rub_jiggle_step: float = 120.0
## 게임패드·방향키로 손을 옮기는 빠르기(초당 픽셀)
@export var pad_hand_speed: float = 500.0
## 뜨물 버리기: 커서를 이만큼(픽셀) 오른쪽으로 밀면 바가지가 끝까지 기운다.
## 위에서 본 바가지라서, 끝까지 기울면 가로로 이만큼 납작해지고(1 = 그대로) 물이 오른쪽 가장자리로 이만큼(픽셀) 쏠린다.
@export var tilt_distance: float = 260.0
@export var tilt_squash: float = 0.75
@export var tilt_water_shift: float = 45.0
## 게임패드: 스틱을 오른쪽으로 밀면 기우는 빠르기, 놓으면 돌아오는 빠르기 (1초에 끝까지 기우는 정도)
@export var pad_tilt_speed: float = 1.5
## 이만큼(0~1) 기울여야 뜨물이 흐르기 시작한다. 끝까지 기울이면 1초에 이만큼 빠진다 (물 1 = 가득).
@export var pour_start_tilt: float = 0.35
@export var drain_speed: float = 0.9
## 이만큼(0~1) 넘게 기울이면 쌀알이 톡 흘러나간다. 흘러나간 쌀알이 돌아오기까지 시간(초)과 다시 흘러나가기까지 쉬는 시간(초).
@export var spill_tilt: float = 0.92
@export var spill_return_delay: float = 0.6
@export var spill_cooldown: float = 0.8
@export var spill_grain_count: int = 3
## 바가지가 바로 서는 시간(초)
@export var untilt_duration: float = 0.3
## 맑은 물 색과 다 비볐을 때 뽀얀 물 색 (되풀이할수록 덜 뽀얘진다)
@export var clear_color: Color = Color(0.62, 0.8, 0.92)
@export var murky_color: Color = Color(0.93, 0.91, 0.84)
## 뜨물 줄기 폭과 길이(픽셀)
@export var stream_width: float = 18.0
@export var stream_length: float = 220.0
## 쌀알 수, 쌀알이 흩어지는 반지름(픽셀), 쌀알 색
@export var rice_grain_count: int = 40
@export var rice_area_radius: float = 140.0
@export var rice_color: Color = Color(1, 1, 0.97)
## 쌀이 흔들리는 각도(라디안)와 시간(초)
@export var rub_jiggle_angle: float = 0.08
@export var rub_duration: float = 0.1
## 다 씻은 뒤, 물을 맞춘 뒤 다음으로 넘어가기까지 쉬는 시간(초)
@export var move_delay: float = 0.9

@export_group("물 맞추기")
## 솥 안: 쌀 층 높이(픽셀), 손(손바닥을 쌀에 대고 누운 모습)의 폭과 두께(픽셀)
@export var pot_rice_height: float = 70.0
@export var hand_width: float = 160.0
@export var hand_thickness: float = 36.0
## 누르고 있을 때 물이 차오르는 빠르기(초당 픽셀)
@export var water_fill_speed: float = 40.0
## 손을 떼고 이 시간(초)이 지나면 그 물 높이로 정한다. 그 전에 다시 누르면 더 붓는다.
@export var water_settle_time: float = 1.0
## 이보다 적게(물 높이 0~1 중) 붓고 떼면 "조금 더 부어요" 하고 기다린다.
@export var water_min_level: float = 0.15
## 이보다 많이(물 높이 0~1 중) 붓고 떼면 물을 따라 내고 다시 받는다. 비법 자리·부탁 자리가 이 칸 안에 있어야 한다.
@export var water_max_level: float = 0.8
## 눈금의 알맞은 물 칸 색, 솥 안쪽 벽에 그리는 알맞은 물 위·아래 표시 색과 길이(픽셀), 넘친 물을 따라 내는 시간(초)
@export var water_ok_color: Color = Color(0.75, 0.95, 0.75, 0.6)
@export var water_tick_color: Color = Color(1, 1, 1, 0.85)
@export var water_tick_length: float = 28.0
@export var water_pour_off_time: float = 0.6
## 물 색 (손이 비쳐 보이게 반투명), 쌀 층 색, 손 색, 눈금 색과 폭, 솥에서 떨어진 거리(픽셀)
@export var pot_water_color: Color = Color(0.62, 0.8, 0.92, 0.55)
@export var pot_rice_color: Color = Color(0.97, 0.96, 0.9)
@export var hand_color: Color = Color(0.96, 0.8, 0.66)
@export var gauge_color: Color = Color(0.25, 0.22, 0.2, 0.9)
@export var gauge_width: float = 36.0
@export var gauge_gap: float = 40.0

@export_group("불 조절")
## 바늘이 손잡이를 따라가는 빠르기 (1초에 따라잡는 정도)와, 게임패드·방향키로 손잡이를 돌리는 빠르기 (1초에 막대의 비율)
@export var heat_follow: float = 6.0
@export var pad_heat_speed: float = 0.6
## 불이 저절로 일렁이는 정도 (불 세기 0~1 중)와 빠르기. 살아 있는 불처럼 보일 만큼만.
@export var heat_drift_amount: float = 0.05
@export var heat_drift_speed: float = 0.8
## 단계별 금색 칸 (불 세기 0~1 중, x = 시작, y = 끝): 센불, 중불, 약불 뜸. 넓을수록 쉽다.
@export var cook_stage_ranges: Array[Vector2] = [Vector2(0.72, 1.0), Vector2(0.38, 0.64), Vector2(0.06, 0.3)]
## 금색 칸 밖으로 이만큼은 봐준다. 화면에는 안 보인다.
@export var heat_margin: float = 0.03
## 금색 칸 안에서 보내야 하는 시간(초)의 합. 단계별로는 cook_stage_shares 비율로 나눈다.
@export var cook_time_needed: float = 7.0
@export var cook_stage_shares: Array[float] = [0.4, 0.35, 0.25]
## 센불 단계가 이만큼 차면 보글보글 소리가 커지고 뚜껑이 가끔 살짝 들썩인다 (곧 끓는다는 신호)
@export var boil_soon_share: float = 0.7
## 끓어오를 때 뚜껑이 뛰는 높이(픽셀)와 한 번 뛰는 시간(초)
@export var lid_hop_height: float = 26.0
@export var lid_hop_duration: float = 0.18
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
var _phase: Phase = Phase.RUBBING
var _washes_done: int = 0
## 손 자리 (바가지 영역 기준, NAN = 아직 커서가 안 들어옴)
var _hand_point: Vector2 = Vector2(NAN, NAN)
## 이번에 비빈 정도 (0 ~ 1), 바가지 물의 양 (0 ~ 1), 다음 흔들림까지 남은 거리
var _rub: float = 0.0
var _bowl_water: float = 1.0
var _jiggle_left: float = 0.0
## 바가지 기울기 (0 ~ 1)와, 기울이기를 시작한 커서 x (NAN = 아직 없음)
var _tilt: float = 0.0
var _tilt_origin_x: float = NAN
var _spill_cooldown_left: float = 0.0
## 솥에 부은 물 높이 (0 = 쌀 바로 위, 0.5 = 손등, 1 = 손등 위로 손 두께만큼, 넘으면 더 높이),
## 붓는 중인지, 손을 뗀 뒤 지난 시간, 한 번이라도 부었는지
var _water_level: float = 0.0
var _is_pouring_water: bool = false
var _settle_time: float = 0.0
var _has_poured: bool = false
## 넘친 물을 따라 내는 중 (그동안은 붓지 않는다)
var _is_pouring_off: bool = false
## 불 손잡이 자리 (0~1)와, 일렁임을 더한 지금 불 세기
var _knob: float = 0.0
var _heat: float = 0.0
var _heat_state: Heat = Heat.LOW
var _cook_stage: CookStage = CookStage.BOIL
## 지금 단계의 진행 (0~1)
var _stage_progress: float = 0.0
## 뚜껑이 "들썩! 들썩!" 뛰는 중 (그동안은 흔들기를 하지 않는다)
var _is_lid_hopping: bool = false
var _flame_time: float = 0.0
## 밥이 지어진 정도 (0 ~ 1)
var _cook_progress: float = 0.0
var _rattle_time: float = 0.0
var _lid_home_y: float = 0.0
## 불 조절 단계의 제목 (레시피의 동작 이름, 기본 "밥 짓기")
var _cook_title: String = ""
## 뜨물 줄기, 물 맞추기 화면(쌀 층·손·물·눈금)과 눈금 위 물 높이 표시
var _stream: ColorRect
var _water_view: Control
var _pot_water: ColorRect
var _gauge: ColorRect
var _gauge_marker: ColorRect
## 솥 안 쌀 층 윗면의 y (불 영역 기준)와 물 높이 1 에 해당하는 픽셀
var _rice_top_y: float = 0.0
var _water_range: float = 72.0
## 바가지 물이 처음 놓인 자리 (기울면 오른쪽으로 쏠린다)
var _water_home: Vector2

@onready var _wash_area: Control = %WashArea
@onready var _water: Control = %Water
@onready var _rice_layer: Control = %RiceLayer
@onready var _rice_template: Control = %RiceTemplate
@onready var _hand: Control = %Hand
@onready var _wash_spot: Control = %WashSpot
@onready var _fire_area: Control = %FireArea
@onready var _pot: Control = get_node("%FireArea/Pot")
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
	# 예전 금색 자리는 쓰지 않는다.
	_wash_spot.hide()
	_lid_home_y = _lid.position.y
	_flame.pivot_offset = Vector2(_flame.size.x / 2.0, _flame.size.y)
	_wash_area.pivot_offset = _wash_area.size / 2.0
	_water.pivot_offset = _water.size / 2.0
	_water_home = _water.position
	_stream = ColorRect.new()
	_stream.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stream.hide()
	add_child(_stream)
	_build_water_view()


## 솥 안을 그린다: 쌀 층, 쌀 위에 누운 손, 반투명 물, 솥 왼쪽 물 높이 눈금. 불 영역 위에 얹는다.
func _build_water_view() -> void:
	_water_view = Control.new()
	_water_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fire_area.add_child(_water_view)
	var inner_left: float = _pot.position.x + 20.0
	var inner_width: float = _pot.size.x - 40.0
	var bottom: float = _pot.position.y + _pot.size.y - 20.0
	_rice_top_y = bottom - pot_rice_height
	_water_range = hand_thickness * 2.0
	_water_view.add_child(_make_rect(Rect2(inner_left, _rice_top_y, inner_width, pot_rice_height), pot_rice_color))
	var hand_rect: Rect2 = Rect2(_pot.position.x + _pot.size.x / 2.0 - hand_width / 2.0,
			_rice_top_y - hand_thickness, hand_width, hand_thickness)
	_water_view.add_child(_make_rect(hand_rect, hand_color))
	_pot_water = _make_rect(Rect2(inner_left, bottom, inner_width, 0.0), pot_water_color)
	_water_view.add_child(_pot_water)
	# 솥 양쪽 안벽에 알맞은 물의 아래·위 높이 표시 (물을 보면서 맞출 수 있게)
	for level: float in [water_min_level, water_max_level]:
		var y: float = _rice_top_y - level * _water_range - 2.0
		_water_view.add_child(_make_rect(Rect2(inner_left, y, water_tick_length, 4.0), water_tick_color))
		_water_view.add_child(_make_rect(Rect2(inner_left + inner_width - water_tick_length, y, water_tick_length, 4.0),
				water_tick_color))
	_gauge = _make_rect(Rect2(_pot.position.x - gauge_gap - gauge_width, _rice_top_y - _water_range,
			gauge_width, _water_range), gauge_color)
	_water_view.add_child(_gauge)
	_gauge.add_child(_make_rect(Rect2(0.0, (1.0 - water_max_level) * _water_range, gauge_width,
			(water_max_level - water_min_level) * _water_range), water_ok_color))
	_gauge_marker = _make_rect(Rect2(-8.0, 0.0, gauge_width + 16.0, 4.0), Color(clear_color, 1.0))
	_gauge.add_child(_gauge_marker)
	_water_view.hide()


func _make_rect(rect: Rect2, color: Color) -> ColorRect:
	var node: ColorRect = ColorRect.new()
	node.position = rect.position
	node.size = rect.size
	node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## 보글보글 소리는 불 조절을 시작할 때 켠다.
func _loop_from_start() -> bool:
	return false


func _get_minigame_type() -> Recipe.MinigameType:
	return Recipe.MinigameType.COOK_RICE


func _on_start(recipe: Recipe) -> void:
	_washes_needed = _step_count(washes_needed)
	_cook_time_needed = cook_time_needed * _duration_scale
	_cook_title = _step_action(Recipe.MinigameType.COOK_RICE)
	_clear_zones(_gauge)
	_start_washing()


## 물 높이 눈금 오른쪽 절반에 비법 자리나 부탁 자리를 그린다 (눈금 위쪽이 1). 왼쪽 절반은 알맞은 물 칸이 보이게 남긴다.
func _show_zone(start: float, end: float, color: Color, zone_name: String) -> void:
	_make_zone(_gauge, Rect2(gauge_width / 2.0, (1.0 - end) * _water_range, gauge_width / 2.0, (end - start) * _water_range),
			color, zone_name)
	_gauge.move_child(_gauge_marker, -1)


# --- 쌀 씻기 ---

func _start_washing() -> void:
	_washes_done = 0
	_wash_area.show()
	_fire_area.hide()
	_scatter_rice()
	_title_label.text = WASH_TITLE
	_hint_label.text = WASH_HINT_TEXT
	_hand_point = Vector2(NAN, NAN)
	_start_rubbing()


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


## 새 물을 받고 비비기를 시작한다.
func _start_rubbing() -> void:
	_phase = Phase.RUBBING
	_rub = 0.0
	_bowl_water = 1.0
	_tilt = 0.0
	_tilt_origin_x = NAN
	_jiggle_left = rub_jiggle_step
	_set_tilt_look(0.0)
	_update_bowl()
	_side_label.text = WASH_STEP_FORMAT % [_washes_done + 1, _washes_needed]
	_progress_label.text = RUB_TEXT if _washes_done == 0 else REFILL_TEXT
	_update_hand()


## 손을 at(바가지 영역 기준)으로 옮기며, 쌀 위에서 움직인 만큼 비빈다.
func _rub_to(at: Vector2) -> void:
	var target: Vector2 = at.clamp(Vector2.ZERO, _wash_area.size)
	var moved: float = 0.0 if is_nan(_hand_point.x) else target.distance_to(_hand_point)
	_hand_point = target
	_update_hand()
	if _phase != Phase.RUBBING or target.distance_to(_wash_area.size / 2.0) > rub_reach:
		return
	_rub = minf(_rub + moved / rub_distance_needed, 1.0)
	_jiggle_left -= moved
	if _jiggle_left <= 0.0:
		_jiggle_left = rub_jiggle_step
		_jiggle_rice()
		_play_hit_sound()
	_update_bowl()
	if _rub >= 1.0:
		_phase = Phase.DRAINING
		_tilt_origin_x = NAN
		_progress_label.text = DRAIN_TEXT
		_update_hand()


func _jiggle_rice() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_rice_layer, "rotation", rub_jiggle_angle * (1.0 if randf() < 0.5 else -1.0), rub_duration)
	tween.tween_property(_rice_layer, "rotation", 0.0, rub_duration)


## 바가지 물 색과 양: 비빈 만큼 뽀얘지고 (되풀이할수록 덜), 버린 만큼 줄어든다.
func _update_bowl() -> void:
	var murk_strength: float = 1.0 - float(_washes_done) / _washes_needed
	_water.self_modulate = clear_color.lerp(murky_color, _rub * murk_strength)
	_water.scale = Vector2.ONE * lerpf(0.45, 1.0, _bowl_water)


## 뜨물 버리기: 기울기(0~1)만큼 바가지를 기울이고, 많이 기울수록 빨리 빠진다. 너무 기울면 쌀알이 톡.
func _drain(delta: float) -> void:
	_set_tilt_look(_tilt)
	_spill_cooldown_left = maxf(_spill_cooldown_left - delta, 0.0)
	var flow: float = clampf((_tilt - pour_start_tilt) / (1.0 - pour_start_tilt), 0.0, 1.0)
	_bowl_water = maxf(_bowl_water - flow * drain_speed * delta, 0.0)
	_update_bowl()
	_update_stream(flow)
	if _tilt >= spill_tilt and _spill_cooldown_left <= 0.0:
		_spill_cooldown_left = spill_cooldown
		_spill_grains()
	if _bowl_water <= 0.0:
		_finish_wash()


## 바가지가 기운 모습: 가로로 납작해지고 물이 오른쪽 가장자리로 쏠린다.
func _set_tilt_look(tilt: float) -> void:
	_wash_area.scale = Vector2(lerpf(1.0, tilt_squash, tilt), 1.0)
	_water.position = _water_home + Vector2(tilt_water_shift * tilt, 0.0)


## 뜨물 줄기: 기운 바가지 오른쪽 가장자리에서 아래로 흐른다.
func _update_stream(flow: float) -> void:
	_stream.visible = flow > 0.0
	if not _stream.visible:
		return
	var edge: Vector2 = _wash_area.get_global_transform() * Vector2(_wash_area.size.x * 0.92, _wash_area.size.y / 2.0)
	var local_edge: Vector2 = get_global_transform().affine_inverse() * edge
	_stream.color = _water.self_modulate
	_stream.size = Vector2(stream_width * flow + 4.0, stream_length)
	_stream.position = local_edge - Vector2(_stream.size.x / 2.0, 0.0)


## 쌀알 몇 개가 바가지 밖으로 톡 흘러나갔다가 잠시 뒤 쏙 돌아온다 (손해 없음).
func _spill_grains() -> void:
	_progress_label.text = SPILL_TEXT
	var grains: Array[Node] = _rice_layer.get_children()
	grains.shuffle()
	for i: int in mini(spill_grain_count, grains.size()):
		var grain: Control = grains[i]
		var home: Vector2 = grain.position
		var out: Vector2 = home + Vector2(rice_area_radius * 1.6, randf_range(-30.0, 30.0))
		var tween: Tween = create_tween()
		tween.tween_property(grain, "position", out, rub_duration * 2.0)
		tween.tween_interval(spill_return_delay)
		tween.tween_property(grain, "position", home, rub_duration * 3.0)


## 한 번 다 씻었다. 바가지가 바로 서고, 다 씻었으면 솥에 안치고 아니면 새 물을 받는다.
func _finish_wash() -> void:
	_phase = Phase.MOVING
	_washes_done += 1
	_stream.hide()
	var tween: Tween = create_tween()
	tween.tween_method(_set_tilt_look, _tilt, 0.0, untilt_duration)
	if _washes_done < _washes_needed:
		tween.tween_callback(_start_rubbing)
		return
	_progress_label.text = WASHED_TEXT
	await tween.finished
	# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
	await get_tree().create_timer(move_delay, false).timeout
	if _is_playing:
		_start_watering()


## 손은 비비기 중에만 보인다.
func _update_hand() -> void:
	_hand.visible = _phase == Phase.RUBBING and not is_nan(_hand_point.x)
	if _hand.visible:
		_hand.position = _hand_point - _hand.size / 2.0


# --- 물 맞추기 ---

func _start_watering() -> void:
	_phase = Phase.WATERING
	_water_level = 0.0
	_is_pouring_water = false
	_is_pouring_off = false
	_has_poured = false
	_settle_time = 0.0
	_wash_area.hide()
	_fire_area.show()
	_set_water_view(true)
	_update_pot_water()
	_title_label.text = WATER_TITLE
	_side_label.text = WATER_STEP_TEXT
	_progress_label.text = WATER_TEXT
	_hint_label.text = WATER_HINT_TEXT


## 물 맞추기 화면(솥 안)과 불 조절 화면(불꽃·뚜껑·막대)을 바꿔 보여 준다. 솥은 둘 다에서 보인다.
func _set_water_view(is_water: bool) -> void:
	_water_view.visible = is_water
	for child: Node in _fire_area.get_children():
		if child is CanvasItem and child != _pot and child != _water_view:
			(child as CanvasItem).visible = not is_water


func _update_watering(delta: float) -> void:
	if _is_pouring_off:
		return
	if _is_pouring_water:
		_water_level += water_fill_speed * delta / _water_range
		_has_poured = true
		_settle_time = 0.0
		_progress_label.text = WATER_TOO_MUCH_TEXT if _water_level > water_max_level else WATER_TEXT
		_update_pot_water()
		return
	if not _has_poured:
		return
	if _water_level < water_min_level:
		_progress_label.text = WATER_MORE_TEXT
		return
	_settle_time += delta
	if _settle_time >= water_settle_time:
		if _water_level > water_max_level:
			_pour_off_water()
		else:
			_settle_water()


## 물이 너무 많다. 솥의 물을 따라 내고 처음부터 다시 받는다 (빗나감으로 세지 않는다).
func _pour_off_water() -> void:
	_is_pouring_off = true
	_has_poured = false
	_settle_time = 0.0
	_progress_label.text = WATER_POUR_OFF_TEXT
	Sound.play(WATER_POUR_OFF_SOUND)
	var tween: Tween = create_tween()
	tween.tween_method(func(level: float) -> void:
			_water_level = level
			_update_pot_water(), _water_level, 0.0, water_pour_off_time)
	await tween.finished
	_is_pouring_off = false


## 지금 물 높이로 정하고 불 조절로 넘어간다.
func _settle_water() -> void:
	# 쌀 바로 위 = 0, 손등 = 0.5, 손등 위로 손 두께만큼 = 1 (넘치면 1 너머라 자리로 치지 않는다)
	_register_hit(_water_level, _water_level <= 1.0)
	_phase = Phase.MOVING
	_progress_label.text = WATER_DONE_TEXT
	# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
	await get_tree().create_timer(move_delay, false).timeout
	if _is_playing:
		_start_cooking()


func _update_pot_water() -> void:
	var bottom: float = _rice_top_y + pot_rice_height
	var top: float = maxf(_rice_top_y - _water_level * _water_range, _pot.position.y + 20.0)
	_pot_water.position.y = top
	_pot_water.size.y = bottom - top
	_gauge_marker.position.y = clampf((1.0 - _water_level) * _water_range, -8.0, _water_range) - 2.0


# --- 불 조절 ---

func _start_cooking() -> void:
	_phase = Phase.COOKING
	_set_water_view(false)
	_knob = 0.0
	_heat = 0.0
	_flame_time = 0.0
	_heat_state = Heat.LOW
	_cook_progress = 0.0
	_is_lid_hopping = false
	_title_label.text = _cook_title
	_hint_label.text = COOK_HINT_TEXT
	_enter_cook_stage(CookStage.BOIL)
	_progress_label.text = COOK_STAGE_TEXTS[CookStage.BOIL][Heat.LOW]
	_update_fire(0.0)
	Sound.start_loop(_loop_sound, boil_quiet_db)


func _cook(delta: float) -> void:
	_flame_time += delta
	# 손잡이 자리에 불이 저절로 일렁이는 만큼을 더한다.
	var drift: float = heat_drift_amount * (0.6 * sin(_flame_time * heat_drift_speed * TAU / 3.0) \
			+ 0.4 * sin(_flame_time * heat_drift_speed * TAU / 1.3 + 1.0))
	_heat = lerpf(_heat, clampf(_knob + drift, 0.0, 1.0), clampf(heat_follow * delta, 0.0, 1.0))
	var stage_range: Vector2 = cook_stage_ranges[_cook_stage]
	var new_state: Heat = Heat.GOOD
	if _heat < stage_range.x - heat_margin:
		new_state = Heat.LOW
	elif _heat > stage_range.y + heat_margin:
		new_state = Heat.HIGH
	var was_soon: bool = _is_boil_soon()
	if new_state != _heat_state:
		_heat_state = new_state
		if not _is_lid_hopping:
			_progress_label.text = COOK_STAGE_TEXTS[_cook_stage][new_state]
	if _heat_state == Heat.GOOD and not _is_lid_hopping:
		_stage_progress = minf(_stage_progress + delta / (_cook_time_needed * cook_stage_shares[_cook_stage]), 1.0)
	if _is_boil_soon() and not was_soon:
		_progress_label.text = BOIL_SOON_TEXT
	_cook_progress = _stages_done_share() + cook_stage_shares[_cook_stage] * _stage_progress
	_update_fire(delta)
	var volume: float = lerpf(boil_quiet_db, boil_loud_db, _heat)
	if _is_boil_soon():
		volume = boil_loud_db
	Sound.set_loop_volume(_loop_sound, volume)
	if _stage_progress < 1.0 or _is_lid_hopping:
		return
	match _cook_stage:
		CookStage.BOIL:
			_hop_lid_twice()
		CookStage.SIMMER:
			_enter_cook_stage(CookStage.REST)
			_progress_label.text = SIMMERED_TEXT
		CookStage.REST:
			_phase = Phase.MOVING
			_heat = 0.0
			_update_fire(0.0)
			_complete(DONE_TEXT)


## 센불 단계가 거의 다 차서 곧 끓어오르는 때인지
func _is_boil_soon() -> bool:
	return _cook_stage == CookStage.BOIL and _stage_progress >= boil_soon_share


## 앞 단계들이 차지하는 몫의 합 (밥 짓기 막대를 채우는 데 쓴다)
func _stages_done_share() -> float:
	var total: float = 0.0
	for i: int in _cook_stage:
		total += cook_stage_shares[i]
	return total


## 단계를 바꾸고 불 막대의 금색 칸(이번 단계 자리)과 붉은 칸(넘치는 자리)을 옮긴다.
func _enter_cook_stage(stage: CookStage) -> void:
	_cook_stage = stage
	_stage_progress = 0.0
	_heat_state = Heat.GOOD
	var stage_range: Vector2 = cook_stage_ranges[stage]
	var width: float = _heat_bar.size.x
	_heat_gold_zone.position.x = stage_range.x * width
	_heat_gold_zone.size.x = (stage_range.y - stage_range.x) * width
	_heat_over_zone.visible = stage_range.y < 1.0
	_heat_over_zone.position.x = stage_range.y * width
	_heat_over_zone.size.x = (1.0 - stage_range.y) * width
	_side_label.text = COOK_STEP_FORMAT % COOK_STAGE_NAMES[stage]


## 끓어올랐다: 뚜껑이 "들썩! 들썩!" 두 번 뛰고 중불 단계로 넘어간다 (할머니: "뚜껑이 두 번 들썩이면 불 줄여").
func _hop_lid_twice() -> void:
	_is_lid_hopping = true
	_progress_label.text = BOILED_TEXT
	for i: int in 2:
		Sound.play(LID_HOP_SOUND)
		var tween: Tween = create_tween()
		tween.tween_property(_lid, "position:y", _lid_home_y - lid_hop_height, lid_hop_duration / 2.0) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_lid, "position:y", _lid_home_y, lid_hop_duration / 2.0) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tween.finished
	if not _is_playing or _phase != Phase.COOKING:
		return
	_enter_cook_stage(CookStage.SIMMER)
	_is_lid_hopping = false
	_progress_label.text = BOILED_TEXT


## 불꽃 크기, 바늘, 밥 짓기 막대, 김, 솥뚜껑 들썩임을 지금 상태에 맞춘다.
func _update_fire(delta: float) -> void:
	_flame.scale = Vector2.ONE * lerpf(flame_min_scale, flame_max_scale, _heat)
	_heat_marker.position.x = _heat * _heat_bar.size.x - _heat_marker.size.x / 2.0
	_cook_fill.size.x = _cook_progress * _cook_bar.size.x
	_steam.modulate.a = _cook_progress
	if _is_lid_hopping:
		return
	var rattle: float = 0.0
	if _heat_state == Heat.HIGH and _cook_stage != CookStage.BOIL:
		rattle = lid_rattle_height
	elif _is_boil_soon() and _heat_state == Heat.GOOD and fmod(_flame_time, 0.9) < 0.25:
		# 곧 끓는다: 가끔 살짝 들썩
		rattle = lid_rattle_height * 0.4
	if rattle > 0.0:
		_rattle_time += delta
		_lid.position.y = _lid_home_y - absf(sin(_rattle_time * lid_rattle_speed)) * rattle
	else:
		_lid.position.y = _lid_home_y


# --- 입력과 매 프레임 ---

func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing:
		return
	var pad: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	match _phase:
		Phase.RUBBING:
			if pad != Vector2.ZERO:
				var from: Vector2 = _wash_area.size / 2.0 if is_nan(_hand_point.x) else _hand_point
				_rub_to(from + pad * pad_hand_speed * delta)
		Phase.DRAINING:
			if pad.x > 0.0:
				_tilt = minf(_tilt + pad.x * pad_tilt_speed * delta, 1.0)
			elif is_nan(_tilt_origin_x):
				# 마우스로 기울이지 않는 동안 스틱을 놓으면 바가지가 천천히 돌아온다.
				_tilt = maxf(_tilt - pad_tilt_speed * delta, 0.0)
			_drain(delta)
		Phase.WATERING:
			_update_watering(delta)
		Phase.COOKING:
			if pad.x != 0.0:
				_knob = clampf(_knob + pad.x * pad_heat_speed * delta, 0.0, 1.0)
			_cook(delta)


## 마우스: 씻기 중에는 손을 옮겨 비비고, 뜨물 버리기 중에는 오른쪽으로 민 만큼 기울이고,
## 물 맞추기 중에는 누르고 있는 동안 붓고, 불 조절 중에는 불 손잡이를 옮긴다. Ⓐ(스페이스)를 누르고 있어도 붓는다.
## 방향은 포커스가 다른 버튼으로 새지 않게 먹는다.
func _gui_input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		accept_event()
		_follow_mouse(event.position)
		if event is InputEventMouseButton and _phase == Phase.WATERING:
			_is_pouring_water = event.pressed
		return
	if event.is_action(&"ui_accept"):
		accept_event()
		if _phase == Phase.WATERING:
			_is_pouring_water = event.is_pressed()
		return
	for action: StringName in [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]:
		if event.is_action(action):
			accept_event()
			return


func _follow_mouse(at: Vector2) -> void:
	match _phase:
		Phase.RUBBING:
			_rub_to(_local_point(_wash_area, at))
		Phase.DRAINING:
			# 기울이기를 시작한 자리에서 오른쪽으로 민 만큼 기운다 (기운 바가지 좌표가 아니라 화면 좌표로 잰다).
			if is_nan(_tilt_origin_x):
				_tilt_origin_x = at.x
			_tilt = clampf((at.x - _tilt_origin_x) / tilt_distance, 0.0, 1.0)
		Phase.COOKING:
			_knob = clampf(_local_point(_heat_bar, at).x / _heat_bar.size.x, 0.0, 1.0)


## 미니게임 좌표 at 을 target 안쪽 좌표로 바꾼다.
func _local_point(target: Control, at: Vector2) -> Vector2:
	return target.get_global_transform().affine_inverse() * (get_global_transform() * at)
