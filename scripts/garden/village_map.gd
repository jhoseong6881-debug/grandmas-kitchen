class_name VillageMap
extends ColorRect
## 아침 마을 길의 지도 바탕. 할머니가 그린 마을 지도 그림(VillageSettings.map_picture)이 있으면 화면 가득 그린다.
## 그림이 없으면 임시로 종이 한 장, 시냇물, 할매식당, 집마다 이어지는 점선 길을 도형으로 그린다.
## ColorRect 를 바탕으로 둔 까닭: 비 오는 날 빗줄기(RainOverlay)가 맨 앞 ColorRect 들 바로 위에 끼어들어 지도 위에 보이게.
## 집 버튼과 이름표는 village.gd 가 따로 얹는다. 이 노드는 그리기만 한다.

## 임시 지도: 종이 둘레 여백(화면 픽셀), 종이·테두리·시냇물·점선 색
@export var paper_margin: Vector2 = Vector2(36.0, 120.0)
@export var paper_color: Color = Color(0.96, 0.9, 0.76)
@export var paper_edge_color: Color = Color(0.62, 0.48, 0.32)
@export var paper_edge_width: float = 6.0
@export var stream_color: Color = Color(0.55, 0.76, 0.85)
@export var stream_width: float = 28.0
## 시냇물이 지나가는 점들 (지도 원본 640x360 픽셀)
@export var stream_points: PackedVector2Array = PackedVector2Array([
		Vector2(415, 40), Vector2(395, 110), Vector2(425, 175), Vector2(390, 245), Vector2(405, 320)])
## 점선 길: 점 사이 간격·점 반지름(화면 픽셀), 만난 손님 집 길 / 못 만난 손님 집 길 색
@export var path_dot_spacing: float = 26.0
@export var path_dot_radius: float = 5.0
@export var path_color: Color = Color(0.45, 0.33, 0.22)
@export var unknown_path_color: Color = Color(0.45, 0.33, 0.22, 0.3)
## 점선이 식당 가까이에서 멈추는 거리, 집(그림·이름·하트 둘레) 가까이에서 멈추는 여백 (화면 픽셀)
@export var path_end_gap: float = 100.0
@export var home_gap: float = 16.0
## 임시 할매식당 그림: 크기(화면 픽셀), 벽·지붕 색
@export var restaurant_size: Vector2 = Vector2(110.0, 80.0)
@export var restaurant_wall_color: Color = Color(0.93, 0.82, 0.62)
@export var restaurant_roof_color: Color = Color(0.72, 0.36, 0.28)

var _picture: Texture2D
var _map_scale: float = 3.0
var _restaurant_point: Vector2 = Vector2.ZERO
var _home_points: Array[Vector2] = []
## 집마다 버튼·이름·하트가 차지하는 화면 영역 (점선이 이 안으로는 안 들어간다)
var _home_rects: Array[Rect2] = []
var _home_known: Array[bool] = []


## picture: 지도 그림 (없으면 null). 점들은 지도 원본 픽셀, map_scale 배로 키워 그린다. home_rects 는 화면 픽셀.
func setup(picture: Texture2D, map_scale: float, restaurant_point: Vector2,
		home_points: Array[Vector2], home_known: Array[bool], home_rects: Array[Rect2]) -> void:
	_picture = picture
	_map_scale = map_scale
	_restaurant_point = restaurant_point * map_scale
	_home_points.assign(home_points.map(func(point: Vector2) -> Vector2: return point * map_scale))
	_home_known = home_known
	_home_rects.assign(home_rects.map(func(rect: Rect2) -> Rect2: return rect.grow(home_gap)))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func _draw() -> void:
	if _picture != null:
		draw_texture_rect(_picture, Rect2(Vector2.ZERO, size), false)
		return
	var paper: Rect2 = Rect2(paper_margin, size - paper_margin * 2.0)
	draw_rect(paper, paper_color)
	draw_rect(paper, paper_edge_color, false, paper_edge_width)
	var stream: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in stream_points:
		stream.append(point * _map_scale)
	draw_polyline(stream, stream_color, stream_width, true)
	for i: int in _home_points.size():
		_draw_dotted_path(_restaurant_point, _home_points[i], path_color if _home_known[i] else unknown_path_color)
	_draw_restaurant(_restaurant_point)


func _draw_dotted_path(from: Vector2, to: Vector2, color: Color) -> void:
	var direction: Vector2 = from.direction_to(to)
	var distance: float = path_end_gap
	while distance < from.distance_to(to):
		var dot: Vector2 = from + direction * distance
		if not _home_rects.any(func(rect: Rect2) -> bool: return rect.has_point(dot)):
			draw_circle(dot, path_dot_radius, color)
		distance += path_dot_spacing


## 임시 할매식당: 벽 사각형 위에 세모 지붕
func _draw_restaurant(center: Vector2) -> void:
	var wall: Rect2 = Rect2(center - Vector2(restaurant_size.x * 0.5, 0.0), Vector2(restaurant_size.x, restaurant_size.y * 0.6))
	draw_rect(wall, restaurant_wall_color)
	draw_rect(wall, paper_edge_color, false, 3.0)
	var roof: PackedVector2Array = PackedVector2Array([
			Vector2(wall.position.x - 12.0, wall.position.y), Vector2(wall.end.x + 12.0, wall.position.y),
			Vector2(center.x, center.y - restaurant_size.y * 0.4)])
	draw_colored_polygon(roof, restaurant_roof_color)
