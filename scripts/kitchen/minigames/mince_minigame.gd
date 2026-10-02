class_name MinceMinigame
extends Minigame
## 다지기 미니게임 (탁탁탁 박자 다지기). 칼이 제자리에서 톡톡 다진다.
## 최근 rate_window 초 동안 누른 횟수로 "누르는 빠르기"를 재서 바늘로 보여 준다.
## 바늘이 금색 칸(알맞은 빠르기)에 있는 동안 "곱게 다지는 중" 막대가 차고, 재료가 점점 잘게 쪼개진다.
## 금색 칸보다 빨라지면 재료가 튀어 빗나감(넘을 때마다 한 번). 느린 건 막대가 멈출 뿐 빗나감이 아니다.
## 요리 단계의 횟수 = 곱게 되는 단계 수. 누르기 입력, 연타 방지, 완벽 표시는 공통 틀(Minigame)이 맡는다.
## 빠르게 마구 누르는 것도 재야 해서, 씬에서 연타 방지 시간(press_cooldown)을 짧게 해 둔다.

enum Pace { SLOW, GOOD, FAST }

const STAGE_FORMAT: String = "곱게 다지는 중 %d / %d"
const READY_TEXT: String = "톡톡톡, 알맞은 빠르기로 계속 눌러요"
const SLOW_TEXT: String = "조금 더 빠르게 톡톡!"
const GOOD_TEXT: String = "좋아요, 그 빠르기 그대로!"
const FAST_TEXT: String = "너무 급해요! 재료가 튀어요"
const DONE_TEXT: String = "곱게 다졌어요!"

## 곱게 되는 단계 수 (요리 단계의 횟수가 없을 때)
@export var stages_needed: int = 4
## 한 단계를 넘기는 데 금색 칸 안에서 다져야 하는 시간(초)
@export var seconds_per_stage: float = 1.0
## 누르는 빠르기를 재는 시간 폭(초). 이 시간 동안 누른 횟수로 빠르기를 잰다.
@export var rate_window: float = 1.0
## 바늘 끝(오른쪽 끝)이 가리키는 빠르기 (1초에 누르는 횟수)
@export var max_rate: float = 8.0
## 금색 칸 (1초에 누르는 횟수). 요리 단계의 빠르기 배율만큼 함께 빨라진다.
@export var target_rate_min: float = 3.0
@export var target_rate_max: float = 5.0
## 바늘이 따라 움직이는 부드러움 (클수록 빨리 따라온다)
@export var needle_follow: float = 10.0
## 처음 재료 조각 수와 크기(픽셀). 단계마다 조각이 두 배로 늘고 작아진다.
@export var start_piece_count: int = 2
@export var start_piece_size: Vector2 = Vector2(150, 110)
@export var max_piece_count: int = 64
## 재료 조각이 흩어지는 구역(도마 기준)
@export var pile_rect: Rect2 = Rect2(140, 110, 620, 260)
## 그림이 없는 재료의 임시 색
@export var ingredient_color: Color = Color(0.93, 0.55, 0.25)
## 칼이 내려찍는 깊이(픽셀)와 시간(초)
@export var knife_drop: float = 50.0
@export var knife_drop_duration: float = 0.06

var _stages_needed: int = 0
var _target_min: float = 3.0
var _target_max: float = 5.0
var _press_times: Array[float] = []
var _time: float = 0.0
var _needle: float = 0.0
var _pace: Pace = Pace.SLOW
## 곱게 다진 정도 (0 ~ 1)
var _fineness: float = 0.0
var _shown_stage: int = -1
var _knife_home_y: float = 0.0
var _ingredient_color: Color

@onready var _board: Control = %Board
@onready var _pile: Control = %Pile
@onready var _knife: Control = %Knife
@onready var _rate_bar: Control = %RateBar
@onready var _rate_gold_zone: ColorRect = %RateGoldZone
@onready var _rate_fast_zone: ColorRect = %RateFastZone
@onready var _rate_marker: Control = %RateMarker
@onready var _fine_bar: Control = %FineBar
@onready var _fine_fill: Control = %FineFill
@onready var _side_label: Label = %SideLabel


func _ready() -> void:
	super()
	_knife_home_y = _knife.position.y


func _get_minigame_type() -> Recipe.MinigameType:
	return Recipe.MinigameType.MINCE


func _on_start(recipe: Recipe) -> void:
	_stages_needed = _step_count(stages_needed)
	var center: float = (target_rate_min + target_rate_max) / 2.0 * _speed
	var half: float = (target_rate_max - target_rate_min) / 2.0 * _speed * _window_scale
	_target_min = center - half
	_target_max = center + half
	_ingredient_color = _step_color(ingredient_color)
	_press_times.clear()
	_time = 0.0
	_needle = 0.0
	_pace = Pace.SLOW
	_fineness = 0.0
	_shown_stage = -1
	var width: float = _rate_bar.size.x
	_rate_gold_zone.position.x = _target_min / max_rate * width
	_rate_gold_zone.size.x = (_target_max - _target_min) / max_rate * width
	_rate_fast_zone.position.x = _target_max / max_rate * width
	_rate_fast_zone.size.x = maxf(width - _rate_fast_zone.position.x, 0.0)
	_clear_zones(_rate_gold_zone)
	_title_label.text = _step_title(Recipe.MinigameType.MINCE, _default_subject(recipe))
	_progress_label.text = READY_TEXT
	_update_view()


func _process(delta: float) -> void:
	super(delta)
	if not visible or not _is_playing:
		return
	_time += delta
	while not _press_times.is_empty() and _press_times[0] < _time - rate_window:
		_press_times.pop_front()
	var rate: float = _press_times.size() / rate_window
	_needle = lerpf(_needle, clampf(rate / max_rate, 0.0, 1.0), clampf(needle_follow * delta, 0.0, 1.0))
	var needle_rate: float = _needle * max_rate
	var new_pace: Pace = Pace.GOOD
	if needle_rate < _target_min:
		new_pace = Pace.SLOW
	elif needle_rate > _target_max:
		new_pace = Pace.FAST
	if new_pace != _pace:
		_pace = new_pace
		if new_pace == Pace.FAST:
			_register_miss()
		_progress_label.text = [SLOW_TEXT, GOOD_TEXT, FAST_TEXT][new_pace]
	if _pace == Pace.GOOD:
		_fineness = minf(_fineness + delta / (seconds_per_stage * _stages_needed), 1.0)
	_update_view()
	if _fineness >= 1.0:
		_complete(DONE_TEXT)


func _on_press() -> void:
	_press_times.append(_time)
	if _pace == Pace.GOOD:
		# 금색 칸 왼쪽(알맞은 빠르기 중 느린 쪽) = 0, 오른쪽 = 1
		_register_hit((_needle * max_rate - _target_min) / (_target_max - _target_min))
	else:
		# 빠르기가 안 맞아도 칼은 내려가니까 탁 소리는 낸다.
		_play_hit_sound()
	_knife.position.y = _knife_home_y + knife_drop
	var tween: Tween = create_tween()
	tween.tween_property(_knife, "position:y", _knife_home_y, knife_drop_duration)


## 빠르기 막대의 금색 칸 안에 비법 자리나 부탁 자리를 그린다.
func _show_zone(start: float, end: float, color: Color, zone_name: String) -> void:
	var width: float = _rate_gold_zone.size.x
	_make_zone(_rate_gold_zone, Rect2(start * width, 0.0, (end - start) * width, _rate_gold_zone.size.y), color, zone_name)


## 바늘, 막대, 재료 조각을 지금 상태에 맞춘다. 단계가 바뀌면 재료를 더 잘게 다시 놓는다.
func _update_view() -> void:
	_rate_marker.position.x = _needle * _rate_bar.size.x - _rate_marker.size.x / 2.0
	_fine_fill.size.x = _fineness * _fine_bar.size.x
	var stage: int = mini(int(_fineness * _stages_needed), _stages_needed)
	_side_label.text = STAGE_FORMAT % [stage, _stages_needed]
	if stage != _shown_stage:
		_shown_stage = stage
		_scatter_pieces(stage)


func _scatter_pieces(stage: int) -> void:
	for piece: Node in _pile.get_children():
		piece.queue_free()
	var count: int = mini(start_piece_count * int(pow(2.0, stage)), max_piece_count)
	var piece_size: Vector2 = start_piece_size / sqrt(float(count) / start_piece_count)
	for i: int in count:
		var piece: ColorRect = ColorRect.new()
		piece.color = _ingredient_color
		piece.size = piece_size
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece.position = pile_rect.position + Vector2(
				randf_range(0.0, maxf(pile_rect.size.x - piece_size.x, 0.0)),
				randf_range(0.0, maxf(pile_rect.size.y - piece_size.y, 0.0)))
		_pile.add_child(piece)
