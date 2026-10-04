class_name RaincoatShape
extends Control
## 우비 그림이 아직 없을 때 손님 위에 씌우는 임시 우비 (얼굴을 감싸는 모자 + 망토 + 단추).
## 손님 자리(GuestSpot)가 손님 모습과 같은 크기로 겹쳐 놓는다. 그림(AnimalGuest.raincoat_portrait)이 오면 쓰지 않는다.

@export var color: Color = Color(1.0, 0.82, 0.2):
	set(value):
		color = value
		queue_redraw()
## 모자: 얼굴을 감싸는 테두리. 가운데 높이(손님 모습 높이에 대한 비율), 반지름(폭에 대한 비율), 두께(픽셀)
@export var hood_center_ratio: float = 0.36
@export var hood_radius_ratio: float = 0.42
@export var hood_width: float = 34.0
## 망토가 시작하는 높이 (손님 모습 높이에 대한 비율). 이름 글자 아래에서 시작한다.
@export var cape_top_ratio: float = 0.62
@export var button_color: Color = Color(0.95, 0.95, 0.9)
@export var button_radius: float = 7.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	# 모자: 위쪽 반원 테두리 + 양옆으로 망토까지 내려오는 끈
	var center: Vector2 = Vector2(w / 2.0, h * hood_center_ratio)
	var radius: float = w * hood_radius_ratio
	var cape_top: float = h * cape_top_ratio
	draw_arc(center, radius, PI, TAU, 32, color, hood_width)
	for side: float in [-1.0, 1.0]:
		var x: float = center.x + side * radius
		draw_line(Vector2(x, center.y), Vector2(x, cape_top), color, hood_width)
	# 망토: 아래로 갈수록 넓어지는 사다리꼴
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.08 - hood_width / 2.0, cape_top), Vector2(w * 0.92 + hood_width / 2.0, cape_top),
		Vector2(w * 1.04, h), Vector2(-w * 0.04, h)]), color)
	for i: int in 3:
		draw_circle(Vector2(w / 2.0, cape_top + (h - cape_top) * (0.25 + 0.25 * i)), button_radius, button_color)
