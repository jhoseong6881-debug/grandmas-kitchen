class_name Minigame
extends Control
## 요리 미니게임들의 공통 틀. 썰기, 담기, 볶기 미니게임이 이 스크립트를 물려받는다(extends Minigame).
## 공통으로 맡는 일: 시작 전 "준비~ 시작!" 보여 주기(그동안 입력은 무시), 누르기/손 떼기 입력(클릭, 스페이스/Enter,
## 게임패드 A) 감지, 연타 방지, 빗나간 횟수 세기, "완벽 도전 중" 표시, 완벽 도장, 끝나면 finished 시그널 보내기,
## 효과음 (맞힐 때 "hit_미니게임종류" 소리, 없으면 "hit". 빗나감, 준비~ 시작!, 완성/완벽/할머니 손맛 소리),
## 할머니 비법(요리 단계의 비법 자리) 확인과 "할머니 손맛" 도장, 비법을 알면 비법 한 줄 보여 주기,
## 손님의 오늘의 부탁(GuestRequest) 보여 주기와 들어줬는지 확인하기,
## 가게가 커지면 생기는 조리도구(ShopTool) 찾기와 보여 주기 (효과는 _window_scale, _duration_scale 로 각 미니게임이 쓴다).
## 시간 제한과 실패는 없다. 빗나가도 벌칙 없이 다시 하면 된다.
##
## 물려받는 미니게임 씬에는 %TitleLabel, %ProgressLabel, %PerfectStreakLabel, %PerfectStamp 노드가 있어야 한다.
## 요리 단계(CookStep)의 횟수와 빠르기, 제목은 _step_count(), _speed, _step_title() 로 읽는다.
## 물려받는 스크립트가 채우는 함수:
##   _get_minigame_type() : 이 미니게임의 종류 (조리도구를 찾을 때 쓴다)
##   _on_start(recipe)  : 미니게임을 처음 상태로 준비한다.
##   _on_press()        : 누를 때마다 불린다. 맞으면 진행하고, 빗나가면 _register_miss() 를 부른다.
##   _on_release()      : 손을 뗄 때마다 불린다. 꾹 누르는 미니게임에서 쓴다. (필요 없으면 안 채워도 된다)
##   _show_zone(start, end, color, zone_name) : 금색 칸 안에 비법 자리나 부탁 자리를 그린다. (그릴 수 없으면 안 채워도 된다)
##   맞힐 때마다 _register_hit(금색 칸 안의 위치 0~1) 을 부르고, 다 끝나면 _complete(완료 문구) 를 부른다.

## is_perfect: 한 번도 빗나가지 않았으면 true
## is_grandma_taste: 이 단계에 할머니 비법이 있고, 모든 동작을 비법 자리에서 해냈으면 true
## is_request_met: 이 단계에 오늘의 부탁이 있고, 부탁대로 해냈으면 true
signal finished(is_perfect: bool, is_grandma_taste: bool, is_request_met: bool)

## 미니게임 제목: 이름 + 동작 (예: "당근 채썰기")
const STEP_TITLE_FORMAT: String = "%s %s"
## 레시피에 재료가 하나도 없을 때 제목에 쓰는 이름
const FALLBACK_SUBJECT: String = "재료"
const SECRET_HINT_FORMAT: String = "★ 할머니 비법: %s"
const REQUEST_GUIDE_FORMAT: String = "♪ 오늘의 부탁: %s"
const REQUEST_DONE_TEXT: String = "   ♪ 부탁대로 했어요!"
const TOOL_FORMAT: String = "도구: %s (%s)"
const TOOL_SEPARATOR: String = " · "
## 금색 칸 안에 그리는 표시의 이름 (지울 때 찾는 데 쓴다)
const SECRET_ZONE_NAME: String = "SecretZone"
const REQUEST_ZONE_NAME: String = "RequestZone"
## 효과음 이름 (data/sounds/ 의 id). 맞히는 소리는 HIT_SOUND_PREFIX + 미니게임 종류 (예: hit_chop)
const HIT_SOUND_PREFIX: String = "hit_"
const HIT_SOUND_FALLBACK: StringName = &"hit"
const MISS_SOUND: StringName = &"miss"
const READY_SOUND: StringName = &"ready"
const GO_SOUND: StringName = &"go"
const DONE_SOUND: StringName = &"done"
const PERFECT_SOUND: StringName = &"perfect"
const GRANDMA_TASTE_SOUND: StringName = &"grandma_taste"

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
## 시작 전에 보여 주는 글과 각각 보여 주는 시간(초). 이 동안은 눌러도 빗나감으로 치지 않는다.
@export var ready_text: String = "준비~"
@export var go_text: String = "시작!"
@export var ready_duration: float = 0.9
@export var go_duration: float = 0.5
## 할머니 비법대로 해냈을 때 도장 글
@export var grandma_stamp_text: String = "♥ 할머니 손맛 ♥"
## 비법 자리 표시 색 (금색 칸보다 진하게)
@export var secret_zone_color: Color = Color(0.95, 0.55, 0.1, 0.9)
## 부탁 자리 표시 색
@export var request_zone_color: Color = Color(0.35, 0.78, 0.95, 0.9)
## 부탁 한 줄이 비법 한 줄 아래로 떨어진 거리(픽셀). 도구 한 줄은 그 아래로 한 번 더.
@export var request_guide_gap: float = 48.0
## 도구 한 줄 색
@export var tool_text_color: Color = Color(0.6, 0.9, 0.55)
## 비법 한 줄이 보이는 자리와 글자 크기
@export var secret_hint_rect: Rect2 = Rect2(60, 240, 900, 48)
@export var secret_hint_font_size: int = 24

var _miss_count: int = 0
## 지금 하는 요리 단계. 없으면 null (기본값으로 한다).
var _step: CookStep
## 요리 단계의 빠르기 배율 (1 = 보통)
var _speed: float = 1.0
var _is_playing: bool = false
var _cooldown_left: float = 0.0
## 이번 단계에서 맞힌 수와, 그중 비법 자리에서 맞힌 수
var _hit_count: int = 0
var _secret_hit_count: int = 0
## 이번 단계에 걸린 오늘의 부탁 (없으면 null)과, 부탁 자리에서 맞힌 수
var _request: GuestRequest
var _request_hit_count: int = 0
## 가게 조리도구 효과: 맞는 칸 넓이 배율, 끝나기까지 시간/횟수 배율 (1 = 그대로)
var _window_scale: float = 1.0
var _duration_scale: float = 1.0
## 오늘의 부탁 때문에 원래와 다른 미니게임으로 하는 중이면 true (단계의 횟수, 빠르기, 비법을 쓰지 않는다)
var _is_converted: bool = false
## 처음 보여 줄 완벽 도장 글 (할머니 손맛 도장을 썼다가 되돌릴 때 쓴다)
var _perfect_stamp_text: String = ""
## 이 미니게임의 맞히는 소리 이름 (예: &"hit_chop")
var _hit_sound: StringName

@onready var _title_label: Label = %TitleLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _perfect_streak_label: Label = %PerfectStreakLabel
@onready var _perfect_stamp: Label = %PerfectStamp
## "준비~ 시작!" 글. 완벽 도장과 같은 모양으로 쓰려고 도장을 복사해서 만든다.
@onready var _ready_label: Label = _perfect_stamp.duplicate()
## "★ 할머니 비법: …" 한 줄. "완벽 도전 중" 글과 같은 모양으로 쓰려고 복사해서 만든다.
@onready var _secret_hint_label: Label = _perfect_streak_label.duplicate()
## "♪ 오늘의 부탁: …" 한 줄
@onready var _request_label: Label = _perfect_streak_label.duplicate()
## "도구: 넓은 도마 (…)" 한 줄
@onready var _tool_label: Label = _perfect_streak_label.duplicate()


func _ready() -> void:
	_perfect_stamp.pivot_offset = _perfect_stamp.size / 2.0
	_perfect_stamp_text = _perfect_stamp.text
	_hit_sound = StringName(HIT_SOUND_PREFIX + String(Recipe.MinigameType.find_key(_get_minigame_type())).to_lower())
	add_child(_ready_label)
	_ready_label.pivot_offset = _ready_label.size / 2.0
	_ready_label.hide()
	add_child(_secret_hint_label)
	_secret_hint_label.position = secret_hint_rect.position
	_secret_hint_label.size = secret_hint_rect.size
	_secret_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_secret_hint_label.add_theme_font_size_override("font_size", secret_hint_font_size)
	_secret_hint_label.hide()
	add_child(_request_label)
	_request_label.position = secret_hint_rect.position + Vector2(0.0, request_guide_gap)
	_request_label.size = secret_hint_rect.size
	_request_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_request_label.add_theme_font_size_override("font_size", secret_hint_font_size)
	_request_label.add_theme_color_override("font_color", request_zone_color)
	_request_label.hide()
	add_child(_tool_label)
	_tool_label.position = secret_hint_rect.position + Vector2(0.0, request_guide_gap * 2.0)
	_tool_label.size = secret_hint_rect.size
	_tool_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_tool_label.add_theme_font_size_override("font_size", secret_hint_font_size)
	_tool_label.add_theme_color_override("font_color", tool_text_color)
	_tool_label.hide()
	hide()


func start(recipe: Recipe, step: CookStep = null, request: GuestRequest = null) -> void:
	_step = step
	_request = request
	_is_converted = request != null and request.use_new_minigame
	_speed = step.speed if step != null and step.speed > 0.0 and not _is_converted else 1.0
	if request != null:
		_speed *= request.speed_multiplier
	_apply_shop_tools()
	_miss_count = 0
	_hit_count = 0
	_secret_hit_count = 0
	_request_hit_count = 0
	_is_playing = false
	_cooldown_left = 0.0
	_perfect_streak_label.modulate.a = 1.0
	_perfect_streak_label.show()
	_perfect_stamp.hide()
	_perfect_stamp.text = _perfect_stamp_text
	_on_start(recipe)
	# 비법을 알면 비법 한 줄과 비법 자리를 보여 준다. 몰라도 비법 자리에서 해내면 할머니 손맛이 된다.
	var is_secret_known: bool = _step != null and _step.has_secret() and not _is_converted \
			and GameState.is_secret_learned(recipe.id)
	_secret_hint_label.visible = is_secret_known and not recipe.secret_hint.is_empty()
	_secret_hint_label.text = SECRET_HINT_FORMAT % recipe.secret_hint
	if is_secret_known:
		_show_zone(_step.secret_start, _step.secret_end, secret_zone_color, SECRET_ZONE_NAME)
	_request_label.visible = request != null
	if request != null:
		_request_label.text = REQUEST_GUIDE_FORMAT % request.guide_text
		if request.has_zone():
			_show_zone(request.zone_start, request.zone_end, request_zone_color, REQUEST_ZONE_NAME)
	show()
	# 포커스를 가져와야 키보드와 게임패드 입력이 뒤에 있는 버튼으로 새지 않는다.
	grab_focus()
	await _show_ready()
	_is_playing = true


## "준비~"와 "시작!"을 차례로 톡 튀어나오게 보여 준다. 끝날 때까지 _is_playing 이 false 라 입력과 움직임이 멈춰 있다.
func _show_ready() -> void:
	for text_duration_sound: Array in [[ready_text, ready_duration, READY_SOUND], [go_text, go_duration, GO_SOUND]]:
		_ready_label.text = text_duration_sound[0]
		_pop(_ready_label)
		Sound.play(text_duration_sound[2])
		# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
		await get_tree().create_timer(text_duration_sound[1], false).timeout
	_ready_label.hide()


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


## 가게 조리도구 중 이 미니게임에 쓰이는 것을 찾아 효과를 정하고, 도구 한 줄을 만든다.
func _apply_shop_tools() -> void:
	_window_scale = 1.0
	_duration_scale = 1.0
	var names: PackedStringArray = []
	for tool: ShopTool in GameState.get_shop_tools_for(_get_minigame_type()):
		_window_scale *= tool.window_scale
		_duration_scale *= tool.duration_scale
		names.append(TOOL_FORMAT % [tool.display_name, tool.effect_text])
	_tool_label.text = TOOL_SEPARATOR.join(names)
	_tool_label.visible = not names.is_empty()


# --- 물려받는 스크립트가 채우는 함수 ---

func _get_minigame_type() -> Recipe.MinigameType:
	return Recipe.MinigameType.CHOP


func _on_start(_recipe: Recipe) -> void:
	pass


func _on_press() -> void:
	pass


func _on_release() -> void:
	pass


func _show_zone(_start: float, _end: float, _color: Color, _zone_name: String) -> void:
	pass


# --- 물려받는 스크립트가 부르는 함수 ---

## 요리 단계에 이름도 재료도 없을 때 쓰는 이름: 레시피에서 정한 이름 → 첫 번째 재료 이름 → "재료"
func _default_subject(recipe: Recipe) -> String:
	var subject: String = recipe.get_minigame_ingredient_name()
	return subject if not subject.is_empty() else FALLBACK_SUBJECT


## 요리 단계에서 정한 횟수 (정하지 않았으면 default_count). 오늘의 부탁이 있으면 부탁에 맞춰 바꾼다.
func _step_count(default_count: int) -> int:
	var count: int = _step.count if _step != null and _step.count > 0 and not _is_converted else default_count
	return _request.adjust_count(count) if _request != null else count


## 요리 단계에서 정한 동작 이름. 정하지 않았으면 미니게임 기본 이름 (썰기, 볶기 …).
func _step_action(minigame_type: Recipe.MinigameType) -> String:
	if _is_converted and not _request.action_name.is_empty():
		return _request.action_name
	if _step != null and not _step.action_name.is_empty() and not _is_converted:
		return _step.action_name
	return Recipe.get_default_action_name(minigame_type)


## "당근 채썰기" 같은 제목. 이름은 단계의 이름 → 단계의 재료 → default_subject 순서로 고른다.
func _step_title(minigame_type: Recipe.MinigameType, default_subject: String) -> String:
	var subject: String = default_subject
	if _step != null and not _step.subject_name.is_empty():
		subject = _step.subject_name
	elif _step != null and _step.ingredient != null:
		subject = _step.ingredient.display_name
	return STEP_TITLE_FORMAT % [subject, _step_action(minigame_type)]


## 그림이 없을 때 쓰는 재료 색. 단계의 임시 색 → 단계 재료의 색 → default_color 순서로 고른다.
func _step_color(default_color: Color) -> Color:
	if _step != null and _step.placeholder_color.a > 0.0:
		return _step.placeholder_color
	if _step != null and _step.ingredient != null:
		return _step.ingredient.placeholder_color
	return default_color


## 맞혔을 때 부른다. position: 금색 칸(맞는 구간) 안에서 어디쯤 맞혔는지 (0 ~ 1).
func _register_hit(position: float) -> void:
	_play_hit_sound()
	_hit_count += 1
	var clamped: float = clampf(position, 0.0, 1.0)
	if _step != null and not _is_converted and _step.is_in_secret(clamped):
		_secret_hit_count += 1
	if _request != null and _request.is_in_zone(clamped):
		_request_hit_count += 1


## 부탁 자리가 있으면 모든 동작을 그 자리에서, 없으면 한 번도 안 틀렸으면 부탁을 들어준 것
func _is_request_met() -> bool:
	if _request == null:
		return false
	if _request.has_zone():
		return _hit_count > 0 and _request_hit_count == _hit_count
	return _miss_count == 0


func _is_grandma_taste() -> bool:
	return _step != null and _step.has_secret() and not _is_converted and _hit_count > 0 and _secret_hit_count == _hit_count


## 비법 자리나 부탁 자리 표시를 하나 만든다. parent 안에서 rect 자리에 놓인다. 물려받는 스크립트가 _show_zone 에서 쓴다.
func _make_zone(parent: Control, rect: Rect2, color: Color, zone_name: String) -> ColorRect:
	var zone: ColorRect = ColorRect.new()
	zone.name = zone_name
	zone.color = color
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(zone)
	zone.position = rect.position
	zone.size = rect.size
	return zone


## 지난 단계에서 만든 비법 자리, 부탁 자리 표시를 지운다. 물려받는 스크립트가 _on_start 에서 부른다.
func _clear_zones(parent: Control) -> void:
	for zone_name: String in [SECRET_ZONE_NAME, REQUEST_ZONE_NAME]:
		var old: Node = parent.get_node_or_null(zone_name)
		if old != null:
			parent.remove_child(old)
			old.queue_free()


## 이 미니게임의 맞히는 소리를 낸다. _register_hit 이 부르고, 맞힘으로 치지 않는 동작에도 소리를 내고 싶을 때 쓴다.
func _play_hit_sound() -> void:
	Sound.play_or(_hit_sound, HIT_SOUND_FALLBACK)


func _register_miss() -> void:
	Sound.play(MISS_SOUND)
	_miss_count += 1
	if _miss_count == 1:
		var tween: Tween = create_tween()
		tween.tween_property(_perfect_streak_label, "modulate:a", 0.0, streak_fade_duration)
		tween.tween_callback(_perfect_streak_label.hide)


func _complete(done_text: String) -> void:
	_is_playing = false
	_progress_label.text = done_text
	var is_perfect: bool = _miss_count == 0
	var is_grandma_taste: bool = _is_grandma_taste()
	var is_request_met: bool = _is_request_met()
	if is_request_met:
		_progress_label.text += REQUEST_DONE_TEXT
	if is_grandma_taste:
		_perfect_stamp.text = grandma_stamp_text
	if is_perfect or is_grandma_taste:
		_pop_perfect_stamp()
	if is_grandma_taste:
		Sound.play(GRANDMA_TASTE_SOUND)
	elif is_perfect:
		Sound.play(PERFECT_SOUND)
	else:
		Sound.play(DONE_SOUND)
	# 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
	var delay: float = perfect_finish_delay if is_perfect or is_grandma_taste else finish_delay
	await get_tree().create_timer(delay, false).timeout
	hide()
	finished.emit(is_perfect, is_grandma_taste, is_request_met)


func _pop_perfect_stamp() -> void:
	_perfect_streak_label.hide()
	_pop(_perfect_stamp)


## 글이 작게 시작해서 살짝 크게 튀어나왔다가 제자리로 돌아온다. (완벽 도장, 준비~ 시작!)
func _pop(label: Label) -> void:
	label.scale = Vector2.ONE * stamp_start_scale
	label.show()
	var tween: Tween = create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * stamp_overshoot_scale, stamp_pop_duration)
	tween.tween_property(label, "scale", Vector2.ONE, stamp_settle_duration)
