class_name GuestSpot
extends Control
## 손님 자리. 손님 모습과 말풍선을 보여 준다. 부엌 조리대 앞과 저녁 평상에서 쓴다.
## 누가 무엇을 말할지는 정하지 않는다. 부엌이나 평상이 정해서 show_order / show_guest 로 알려 준다.
## walk_in() 을 부르면 옆에서 통통 걸어 들어와 앉은 뒤에 말풍선이 보인다 (저녁 평상).
## fade_in() / fade_out() 은 제자리에서 스르륵 나타나고 사라진다.
## pop_up() 은 아래에서 쏙 올라온다 (점심, 부엌 문이 열린 뒤. 부엌에서는 손님을 조리대 뒤에 그려서 조리대 뒤에서 올라오는 것처럼 보인다).
## 봄비 오는 날에는 우비를 입은 모습으로 보여 준다 (우비 그림이 없으면 임시 우비 도형을 씌운다).
## 대사마다 표정(AnimalGuest.EXPRESSION_*)을 바꿀 수 있다. 그림이 없으면 임시 도형 위에 표정 이름을 작게 보여 준다.
## bubble_above 를 켜면 이름과 말풍선이 오른쪽 대신 머리 위에 뜬다 (평상에서 옆에 같이 앉은 손님).

## 걸어 들어와 자리에 앉았을 때 (walk_in 이 끝나고 말풍선이 뜬 뒤)
signal arrived

## 그림이 없을 때 임시 도형 위에 보여 줄 표정 이름
const EXPRESSION_NAMES: Dictionary[StringName, String] = {
	AnimalGuest.EXPRESSION_HAPPY: "(웃음)",
	AnimalGuest.EXPRESSION_SURPRISED: "(놀람)",
	AnimalGuest.EXPRESSION_SAD: "(시무룩)",
}

const WALK_SOUND: StringName = &"walk"

## 걸어 들어오는 거리(픽셀, 오른쪽에서), 걸리는 시간(초), 걸음 수, 걸음마다 통통 튀는 높이, 앉을 때 내려앉는 정도
@export var walk_distance: float = 700.0
@export var walk_duration: float = 1.2
@export var walk_steps: int = 4
@export var walk_bob_height: float = 14.0
@export var sit_drop: float = 10.0
@export var sit_duration: float = 0.15
## 제자리에서 나타나고 사라지는 시간(초)
@export var fade_duration: float = 0.35
## 아래에서 쏙 올라오는 거리(픽셀)와 시간(초). 처음 조금 동안은 투명에서 또렷해진다.
@export var pop_distance: float = 360.0
@export var pop_duration: float = 0.45
@export var pop_fade_duration: float = 0.12
## 켜면 이름과 말풍선을 머리 위에 띄운다. 말풍선 위치(손님 그림 왼쪽 위 기준)와 폭, 높이, 이름 칸 높이
@export var bubble_above: bool = false
@export var above_bubble_offset: Vector2 = Vector2(0.0, -150.0)
@export var above_bubble_size: Vector2 = Vector2(640.0, 120.0)
@export var above_name_height: float = 48.0
## 다른 손님이 말하는 동안 듣는 손님 그림을 이만큼 어둡게 (1 = 그대로)
@export var listening_brightness: float = 0.6

@onready var _portrait: TextureRect = %Portrait
@onready var _portrait_placeholder: ColorRect = %PortraitPlaceholder
@onready var _name_label: Label = %NameLabel
@onready var _expression_label: Label = %ExpressionLabel
@onready var _bubble_text: Label = %BubbleText
## 말풍선 (걸어 들어오는 동안 숨긴다)
@onready var _bubble: Control = _bubble_text.get_parent().get_parent()
var _home_position: Vector2
## 지금 보여 주는 손님과 우비 여부 (say 로 표정만 바꿀 때 쓴다)
var _guest: AnimalGuest
var _in_raincoat: bool = false
var _walk_tween: Tween
## 임시 우비 (손님 모습 위, 이름 아래에 겹친다)
var _raincoat: RaincoatShape = RaincoatShape.new()


## 말풍선을 닫고 옆으로 걸어 나가며 흐려진다 (to_left 가 false 면 오른쪽으로). 끝나면 숨고 제자리로 돌아간다. 기다리려면 await.
func walk_out(to_left: bool = true) -> void:
	_kill_walk()
	if _home_position == Vector2.ZERO:
		_home_position = position
	_bubble.hide()
	_name_label.hide()
	_walk_tween = create_tween()
	var step_time: float = walk_duration / walk_steps
	for i: int in walk_steps:
		var step_end: Vector2 = _home_position + Vector2((-1.0 if to_left else 1.0) * walk_distance * float(i + 1) / walk_steps, 0.0)
		_walk_tween.tween_callback(Sound.play.bind(WALK_SOUND))
		_walk_tween.tween_property(self, "position", step_end + Vector2(0.0, -walk_bob_height), step_time / 2.0)
		_walk_tween.tween_property(self, "position:y", step_end.y, step_time / 2.0)
	_walk_tween.parallel().tween_property(self, "modulate:a", 0.0, step_time)
	await _walk_tween.finished
	hide()
	position = _home_position
	modulate.a = 1.0
	_name_label.show()


## 제자리에서 스르륵 나타난다. 다 나타나면 이름과 말풍선이 보인다. show_guest 를 먼저 불러 둔다. 기다리려면 await.
## show_bubble 이 false 면 말풍선은 건드리지 않는다 (부르는 쪽이 set_bubble_shown 으로 정한다).
func fade_in(show_bubble: bool = true) -> void:
	_kill_walk()
	if show_bubble:
		_bubble.hide()
	_name_label.hide()
	modulate.a = 0.0
	show()
	_walk_tween = create_tween()
	_walk_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	await _walk_tween.finished
	if show_bubble:
		_bubble.show()
	_name_label.show()


## 아래에서 쏙 올라온다 (살짝 튀어 올랐다 자리 잡기). 다 올라오면 이름과 말풍선이 보인다. show_guest 를 먼저 불러 둔다.
func pop_up() -> void:
	_kill_walk()
	if _home_position == Vector2.ZERO:
		_home_position = position
	_bubble.hide()
	_name_label.hide()
	position = _home_position + Vector2(0.0, pop_distance)
	modulate.a = 0.0
	show()
	_walk_tween = create_tween().set_parallel()
	_walk_tween.tween_property(self, "position", _home_position, pop_duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_walk_tween.tween_property(self, "modulate:a", 1.0, pop_fade_duration)
	await _walk_tween.finished
	_bubble.show()
	_name_label.show()


## 말풍선을 닫고 스르륵 사라진다. 끝나면 숨는다.
func fade_out() -> void:
	_kill_walk()
	_bubble.hide()
	_name_label.hide()
	_walk_tween = create_tween()
	_walk_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await _walk_tween.finished
	hide()
	modulate.a = 1.0
	_name_label.show()


## 걸어 들어오는 중인지 (아직 자리에 앉지 않았으면 true)
func is_walking() -> bool:
	return _walk_tween != null and _walk_tween.is_valid() and _walk_tween.is_running()


func _kill_walk() -> void:
	if _walk_tween != null and _walk_tween.is_valid():
		_walk_tween.kill()


## 지금 보여 주는 손님 (없으면 null)
func get_guest() -> AnimalGuest:
	return _guest if visible else null


## 옆에서 걸어와 제자리에 선다. from_offset: 제자리에서 얼마나 떨어진 곳에서 걷기 시작하는지 (비우면 오른쪽 walk_distance).
func walk_in(from_offset: Vector2 = Vector2.INF) -> void:
	if _walk_tween != null and _walk_tween.is_valid():
		_walk_tween.kill()
	if _home_position == Vector2.ZERO:
		_home_position = position
	var start: Vector2 = from_offset if from_offset != Vector2.INF else Vector2(walk_distance, 0.0)
	position = _home_position + start
	modulate.a = 1.0
	_bubble.hide()
	show()
	_walk_tween = create_tween()
	var step_time: float = walk_duration / walk_steps
	for i: int in walk_steps:
		var step_end: Vector2 = _home_position + start * (1.0 - float(i + 1) / walk_steps)
		_walk_tween.tween_callback(Sound.play.bind(WALK_SOUND))
		_walk_tween.tween_property(self, "position", step_end + Vector2(0.0, -walk_bob_height), step_time / 2.0)
		_walk_tween.tween_property(self, "position:y", step_end.y, step_time / 2.0)
	# 멈춰 서기: 살짝 내려앉았다가 제자리 (sit_drop 이 0 이면 그냥 선다)
	_walk_tween.tween_property(self, "position:y", _home_position.y + sit_drop, sit_duration)
	_walk_tween.tween_property(self, "position:y", _home_position.y, sit_duration)
	_walk_tween.tween_callback(_bubble.show)
	_walk_tween.tween_callback(arrived.emit)


func _ready() -> void:
	hide()
	if bubble_above:
		_bubble.position = above_bubble_offset
		_bubble.size = above_bubble_size
		_name_label.position = above_bubble_offset - Vector2(0.0, above_name_height + 2.0)
		_name_label.size = Vector2(above_bubble_size.x, above_name_height)
	_raincoat.position = _portrait_placeholder.position
	_raincoat.size = _portrait_placeholder.size
	_raincoat.hide()
	add_child(_raincoat)
	move_child(_raincoat, _portrait.get_index() + 1)


func show_order(guest: AnimalGuest, recipe: Recipe) -> void:
	show_guest(guest, guest.order_line.format({"recipe": recipe.display_name}))


## 손님 모습을 보여 주고 말풍선에 text 를 띄운다. in_raincoat: 우비를 입은 모습으로 (봄비 오는 날)
## expression: 표정 (AnimalGuest.EXPRESSION_*). 비워 두면 기본 표정.
func show_guest(guest: AnimalGuest, text: String, in_raincoat: bool = false,
		expression: StringName = AnimalGuest.EXPRESSION_DEFAULT) -> void:
	_guest = guest
	_in_raincoat = in_raincoat
	set_listening(false)
	# 임시 우비 도형은 임시 손님 그림 위에만 씌운다 (진짜 그림이 있으면 그림을 가리니까, 우비 그림이 생길 때까지 평소 모습).
	_raincoat.visible = in_raincoat and guest.raincoat_portrait == null and guest.portrait == null
	if _raincoat.visible:
		_raincoat.color = GameData.get_rain_settings().raincoat_color
	_name_label.text = guest.display_name
	_set_expression(expression)
	show()
	_set_bubble_text(text)


## 말풍선 내용을 바꾼다. expression: 이 말을 할 때의 표정 (비워 두면 기본 표정).
func say(text: String, expression: StringName = AnimalGuest.EXPRESSION_DEFAULT) -> void:
	_set_expression(expression)
	_set_bubble_text(text)


func _set_expression(expression: StringName) -> void:
	if _guest == null:
		return
	var texture: Texture2D = _guest.get_portrait(expression, _in_raincoat)
	var has_portrait: bool = texture != null
	_portrait.texture = texture
	_portrait.visible = has_portrait
	_portrait_placeholder.visible = not has_portrait
	_expression_label.text = EXPRESSION_NAMES.get(expression, "")
	_expression_label.visible = not has_portrait and not _expression_label.text.is_empty()


## 한글이 낱말 중간에서 잘리지 않게 띄어쓰기 자리에서 줄을 바꿔 넣는다.
## (말풍선 폭을 아직 모르면 그대로 넣고 Godot 자동 줄바꿈에 맡긴다)
func _set_bubble_text(text: String) -> void:
	# 말풍선(장면에서 폭을 정해 둔 칸)의 폭에서 안쪽 여백을 뺀다. 숨겨져 있던 안쪽 칸은 폭이 아직 0일 수 있어서.
	var margin: MarginContainer = _bubble_text.get_parent() as MarginContainer
	var bubble: Control = margin.get_parent() as Control if margin != null else null
	var width: float = 0.0
	if bubble != null:
		width = bubble.size.x - margin.get_theme_constant("margin_left") - margin.get_theme_constant("margin_right")
	if width <= 0.0:
		_bubble_text.text = text
		return
	_bubble_text.text = Korean.wrap_by_spaces(text, _bubble_text.get_theme_font("font"),
			_bubble_text.get_theme_font_size("font_size"), width)


## 말풍선만 숨기거나 보인다 (손님끼리 대화할 때 듣는 손님은 숨긴다)
func set_bubble_shown(shown: bool) -> void:
	_bubble.visible = shown


## 듣는 중이면 그림을 조금 어둡게 한다
func set_listening(listening: bool) -> void:
	var tint: Color = Color(listening_brightness, listening_brightness, listening_brightness) if listening else Color.WHITE
	_portrait.modulate = tint
	_portrait_placeholder.modulate = tint


func clear() -> void:
	hide()
