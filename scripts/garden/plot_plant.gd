class_name PlotPlant
extends Control
## 텃밭 칸(PlotRow 의 버튼) 안에 그리는 작물. 자란 정도(0 ~ 1)에 맞춰 크기가 달라진다.
## 작물(Crop)에 단계별 그림(growth_textures)이 있으면 그림을, 없으면 도형(placeholder_shape)으로 그린다.
## 자라는 중에는 살랑살랑 흔들리고, grow_from() 으로 어제 크기에서 오늘 크기로 쑥 자라는 모습을 보여 준다.
## 누르면 wiggle() 로 부시럭 흔들린다. 누르는 입력은 버튼이 받는다 (이 그림은 입력을 지나보낸다).
## 땅(흙, 원목)은 흔들리지 않게 PlotRow 가 따로 그리고, 이 그림은 아래쪽 ground_height 만큼 비워 두고 그 위에 작물을 그린다.

## 땅(흙, 원목) 높이와 줄기 길이 (픽셀, 칸 높이 기준)
@export var ground_height: float = 34.0
@export var min_stem: float = 10.0
@export var max_stem: float = 92.0
@export var stem_width: float = 6.0
@export var stem_color: Color = Color(0.36, 0.62, 0.3)
@export var leaf_color: Color = Color(0.45, 0.75, 0.35)
## 버섯 갓 크기 (반지름, 픽셀)와 갓 수 (자랄수록 늘어난다)
@export var min_cap_radius: float = 8.0
@export var max_cap_radius: float = 26.0
@export var max_caps: int = 3
## 살랑거림 (라디안, 1초에 오가는 빠르기)
@export var sway_angle: float = 0.04
@export var sway_speed: float = 2.2
## 하룻밤 사이 자라는 움직임 시간(초)
@export var grow_duration: float = 0.9

var crop: Crop
var is_ripe: bool = false
## 그리는 자란 정도 (0 ~ 1). grow_from() 이 이 값을 천천히 바꾼다.
var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()

var _time: float = 0.0
## 흔들기(wiggle)로 더해지는 각도. 살랑거림과 따로 더한다.
var _wiggle_angle: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time = randf() * TAU


func set_state(new_crop: Crop, new_progress: float, ripe: bool) -> void:
	crop = new_crop
	is_ripe = ripe
	progress = clampf(new_progress, 0.0, 1.0)


## 어제 크기(from)에서 지금 크기로 쑥 자란다.
func grow_from(from: float) -> void:
	var to: float = progress
	progress = clampf(from, 0.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "progress", to, grow_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## 부시럭: 좌우로 몇 번 흔들린다.
func wiggle() -> void:
	var tween: Tween = create_tween()
	for i: int in 4:
		var side: float = 1.0 if i % 2 == 0 else -1.0
		tween.tween_property(self, "_wiggle_angle", side * 0.25 * (1.0 - i / 4.0), 0.06)
	tween.tween_property(self, "_wiggle_angle", 0.0, 0.06)


func _process(delta: float) -> void:
	_time += delta * sway_speed
	var sway: float = sin(_time) * sway_angle if crop != null else 0.0
	pivot_offset = Vector2(size.x / 2.0, size.y - ground_height)
	rotation = sway + _wiggle_angle


func _draw() -> void:
	var bottom: float = size.y - ground_height
	var center_x: float = size.x / 2.0
	if crop == null:
		return
	if not crop.growth_textures.is_empty():
		_draw_texture_stage(bottom)
	elif crop.placeholder_shape == Crop.PlaceholderShape.MUSHROOM:
		_draw_mushrooms(center_x, bottom)
	else:
		_draw_sprout(center_x, bottom)


func _draw_texture_stage(bottom: float) -> void:
	var count: int = crop.growth_textures.size()
	var stage: int = count - 1 if is_ripe else clampi(int(progress * (count - 1)), 0, count - 1)
	var texture: Texture2D = crop.growth_textures[stage]
	if texture == null:
		return
	var texture_size: Vector2 = texture.get_size()
	var scale_factor: float = minf(size.x / texture_size.x, bottom / texture_size.y)
	var draw_size: Vector2 = texture_size * scale_factor
	draw_texture_rect(texture, Rect2(Vector2((size.x - draw_size.x) / 2.0, bottom - draw_size.y), draw_size), false)


## 새싹: 줄기가 길어지고 잎이 커진다. 다 자라면 흙 위로 뿌리 끝(재료 색)이 보인다.
func _draw_sprout(center_x: float, bottom: float) -> void:
	var stem: float = lerpf(min_stem, max_stem, progress)
	var top: Vector2 = Vector2(center_x, bottom - stem)
	draw_line(Vector2(center_x, bottom), top, stem_color, stem_width)
	var leaf: float = lerpf(5.0, 20.0, progress)
	draw_circle(top + Vector2(-leaf * 0.8, 0.0), leaf, leaf_color)
	draw_circle(top + Vector2(leaf * 0.8, 0.0), leaf, leaf_color)
	if progress > 0.5:
		draw_circle(top + Vector2(0.0, -leaf * 0.9), leaf * 0.8, leaf_color)
	if is_ripe:
		draw_circle(Vector2(center_x, bottom + 4.0), 22.0, crop.ingredient.placeholder_color)


## 버섯: 갓이 커지고, 자랄수록 갓 수가 늘어난다. 다 자라면 재료 색, 그전에는 옅은 색.
func _draw_mushrooms(center_x: float, bottom: float) -> void:
	var caps: int = clampi(1 + int(progress * max_caps), 1, max_caps)
	var radius: float = lerpf(min_cap_radius, max_cap_radius, progress)
	var cap_color: Color = crop.ingredient.placeholder_color if is_ripe \
			else crop.ingredient.placeholder_color.lerp(Color.WHITE, 0.45)
	for i: int in caps:
		var x: float = center_x + (i - (caps - 1) / 2.0) * radius * 2.1
		var stem_top: Vector2 = Vector2(x, bottom - radius * 1.2)
		draw_line(Vector2(x, bottom), stem_top, Color(0.95, 0.92, 0.85), radius * 0.6)
		draw_circle(stem_top, radius, cap_color)
