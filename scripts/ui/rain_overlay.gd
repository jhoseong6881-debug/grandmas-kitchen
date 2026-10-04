class_name RainOverlay
extends Control
## 봄비 빗줄기. 화면 전체를 덮고 비스듬한 빗줄기가 계속 내린다. 입력은 지나보낸다.
## 낮 장면(텃밭, 버섯 원목, 장터, 부엌)은 _ready 에서 RainOverlay.apply_daytime(self, 빗줄기를 보일지) 를 부른다.
## 비 오는 날이면 빗소리를 켜고 (밖이면) 빗줄기를 덮고, 아니면 빗소리를 끈다.
## 그림(빗방울 스프라이트)이 오기 전까지 선으로 그린다.

## 빗줄기 수, 길이(픽셀), 굵기, 떨어지는 빠르기(1초에 픽셀), 기울기(가로로 밀리는 비율)
@export var drop_count: int = 90
@export var drop_length: float = 34.0
@export var drop_width: float = 2.0
@export var fall_speed: float = 900.0
@export var slant: float = 0.18
@export var drop_color: Color = Color(0.85, 0.92, 1.0, 0.6)
## 화면을 살짝 어둡고 푸르게 (흐린 날)
@export var tint_color: Color = Color(0.3, 0.38, 0.5, 0.22)

## 빗줄기마다 (x, y, 빠르기 배율)
var _drops: Array[Vector3] = []


## 비 오는 날이면 빗소리를 켜고, show_streaks 면 parent 의 배경(맨 앞에 있는 ColorRect 들) 바로 위에 빗줄기를 덮는다.
## 글, 버튼, 작물, 열리는 창은 빗줄기 위에 그대로 보인다. 비가 안 오면 빗소리를 끈다.
static func apply_daytime(parent: Control, show_streaks: bool) -> void:
	var rain: RainSettings = GameData.get_rain_settings()
	if not GameState.is_raining_today:
		Sound.stop_loop(rain.rain_sound)
		return
	Sound.start_loop(rain.rain_sound)
	if show_streaks:
		var overlay: RainOverlay = RainOverlay.new()
		var background_count: int = 0
		while background_count < parent.get_child_count() and parent.get_child(background_count) is ColorRect:
			background_count += 1
		parent.add_child(overlay)
		parent.move_child(overlay, background_count)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i: int in drop_count:
		_drops.append(Vector3(randf(), randf(), randf_range(0.8, 1.2)))


func _process(delta: float) -> void:
	for i: int in _drops.size():
		var drop: Vector3 = _drops[i]
		drop.y += fall_speed * drop.z * delta / maxf(size.y, 1.0)
		if drop.y > 1.0:
			drop = Vector3(randf(), drop.y - 1.0, drop.z)
		_drops[i] = drop
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), tint_color)
	var step: Vector2 = Vector2(-slant, 1.0).normalized() * drop_length
	for drop: Vector3 in _drops:
		# 기울어져 내리므로 오른쪽 바깥에서도 시작하게 가로를 조금 넓게 쓴다.
		var start: Vector2 = Vector2(drop.x * size.x * (1.0 + slant) - drop.y * size.y * slant, drop.y * size.y)
		draw_line(start, start + step, drop_color, drop_width)
