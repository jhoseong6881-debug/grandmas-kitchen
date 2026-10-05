class_name PorchScenery
extends TextureRect
## 저녁 평상 장면의 그림 한 겹. 구도: 나는 평상에 앉아 있고, 손님은 낮은 돌담 너머 마을 길에 서서 이야기한다.
## 뒤에서부터 BACKDROP(밤하늘·먼 숲·담 너머 길) → 손님 → WALL(등불 달린 돌담, 손님 아랫몸을 가림) → BENCH(화면 아래 평상 끝).
## picture 칸에 그림(원본 크기, 배경 투명)을 넣으면 그 그림을 pixel_scale 배로 또렷하게 키워 쓴다.
## 비워 두면 kind 에 맞는 임시 도트 그림을 코드로 그린다.

enum Kind { BACKDROP, WALL, BENCH }

## 임시 그림 원본 크기 (게임 화면의 1/3)
const BACKDROP_SIZE: Vector2i = Vector2i(640, 360)
const WALL_SIZE: Vector2i = Vector2i(640, 110)
const BENCH_SIZE: Vector2i = Vector2i(640, 40)
## 돌담 그림에서 담이 시작하는 높이 (위쪽은 등불 기둥만 있는 투명한 자리)
const WALL_TOP: int = 37
## 임시 그림의 별 수와 별자리를 정하는 수 (매번 같은 하늘이 나오게)
const STAR_COUNT: int = 70
const STAR_SEED: int = 7

@export var kind: Kind = Kind.BACKDROP
## 진짜 그림 (원본 크기). 비우면 임시 도트 그림.
@export var picture: Texture2D
@export var pixel_scale: int = 3
@export_group("임시 그림 색")
@export var sky_top_color: Color = Color(0.12, 0.13, 0.27)
@export var sky_bottom_color: Color = Color(0.36, 0.27, 0.4)
@export var star_color: Color = Color(1.0, 0.95, 0.8)
@export var far_hill_color: Color = Color(0.17, 0.2, 0.27)
@export var forest_color: Color = Color(0.11, 0.17, 0.16)
@export var path_color: Color = Color(0.3, 0.27, 0.25)
@export var stone_color: Color = Color(0.5, 0.48, 0.45)
@export var stone_light_color: Color = Color(0.6, 0.58, 0.54)
@export var mortar_color: Color = Color(0.28, 0.26, 0.25)
@export var lantern_pole_color: Color = Color(0.3, 0.2, 0.13)
@export var lantern_color: Color = Color(1.0, 0.72, 0.35)
@export var lantern_glow_color: Color = Color(1.0, 0.78, 0.45, 0.18)
@export var wood_color: Color = Color(0.55, 0.37, 0.22)
@export var wood_dark_color: Color = Color(0.4, 0.26, 0.15)
@export var wood_light_color: Color = Color(0.66, 0.47, 0.29)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var image: Image = picture.get_image().duplicate() if picture != null else _draw_placeholder()
	if image.is_compressed():
		image.decompress()
	image.resize(image.get_width() * pixel_scale, image.get_height() * pixel_scale, Image.INTERPOLATE_NEAREST)
	texture = ImageTexture.create_from_image(image)


func _draw_placeholder() -> Image:
	match kind:
		Kind.WALL:
			return _draw_wall()
		Kind.BENCH:
			return _draw_bench()
	return _draw_backdrop()


## 밤하늘(위는 짙고 아래는 노을빛), 별, 먼 산, 숲 그림자, 담 너머 마을 길
func _draw_backdrop() -> Image:
	var image: Image = Image.create(BACKDROP_SIZE.x, BACKDROP_SIZE.y, false, Image.FORMAT_RGBA8)
	var horizon: int = 200
	for y: int in horizon:
		# 띠 모양으로 끊어서 칠한다 (도트 그림 느낌)
		var band: float = floorf(float(y) / horizon * 8.0) / 8.0
		image.fill_rect(Rect2i(0, y, BACKDROP_SIZE.x, 1), sky_top_color.lerp(sky_bottom_color, band))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = STAR_SEED
	for i: int in STAR_COUNT:
		image.set_pixel(rng.randi_range(0, BACKDROP_SIZE.x - 1), rng.randi_range(0, horizon - 60), star_color)
	for x: int in BACKDROP_SIZE.x:
		var hill: int = 150 + int(12.0 * sin(x / 70.0) + 6.0 * sin(x / 23.0))
		image.fill_rect(Rect2i(x, hill, 1, horizon + 10 - hill), far_hill_color)
		# 뾰족뾰족한 나무 꼭대기
		var tree: int = 178 + absi((x % 18) - 9) - (6 if (x / 18) % 3 == 0 else 0)
		image.fill_rect(Rect2i(x, tree, 1, BACKDROP_SIZE.y - tree), forest_color)
	image.fill_rect(Rect2i(0, 215, BACKDROP_SIZE.x, BACKDROP_SIZE.y - 215), path_color)
	return image


## 위쪽은 투명하고 왼쪽에 등불 기둥, 아래쪽은 크기가 제각각인 둥근 돌을 쌓은 낮은 담
func _draw_wall() -> Image:
	var image: Image = Image.create(WALL_SIZE.x, WALL_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	# 등불: 둥근 빛 번짐, 기둥, 걸린 등
	var lantern_center: Vector2i = Vector2i(42, 16)
	for radius: int in [22, 16, 11]:
		_fill_circle(image, lantern_center, radius, lantern_glow_color)
	image.fill_rect(Rect2i(lantern_center.x - 1, 0, 3, WALL_TOP), lantern_pole_color)
	image.fill_rect(Rect2i(lantern_center.x - 6, lantern_center.y - 7, 13, 15), lantern_color.darkened(0.35))
	image.fill_rect(Rect2i(lantern_center.x - 4, lantern_center.y - 5, 9, 11), lantern_color)
	# 돌담: 줄마다 높이와 너비가 조금씩 다른 둥근 돌
	image.fill_rect(Rect2i(0, WALL_TOP + 2, WALL_SIZE.x, WALL_SIZE.y - WALL_TOP - 2), mortar_color)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = STAR_SEED
	var y: int = WALL_TOP
	while y < WALL_SIZE.y:
		var row_height: int = rng.randi_range(13, 17)
		var x: int = -rng.randi_range(0, 12)
		while x < WALL_SIZE.x:
			var width: int = rng.randi_range(16, 30)
			var stone: Rect2i = Rect2i(x + 1, y + rng.randi_range(0, 2), width - 2, row_height - 2)
			var shade: Color = stone_color.lerp(stone_light_color, rng.randf_range(0.0, 0.6))
			_fill_round_rect(image, stone, shade)
			# 위쪽 밝은 테
			image.fill_rect(Rect2i(stone.position.x + 2, stone.position.y + 1, stone.size.x - 4, 1), stone_light_color.lightened(0.1))
			x += width
		y += row_height - 1
	return image


## 모서리를 한 칸씩 깎은 네모 (도트 그림의 둥근 돌)
func _fill_round_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var clipped: Rect2i = rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if clipped.size.x <= 0 or clipped.size.y <= 0:
		return
	image.fill_rect(Rect2i(rect.position.x + 2, rect.position.y, rect.size.x - 4, rect.size.y).intersection(clipped), color)
	image.fill_rect(Rect2i(rect.position.x, rect.position.y + 2, rect.size.x, rect.size.y - 4).intersection(clipped), color)
	image.fill_rect(Rect2i(rect.position.x + 1, rect.position.y + 1, rect.size.x - 2, rect.size.y - 2).intersection(clipped), color)


## 반투명 빛 번짐용 원 (겹칠수록 진해진다)
func _fill_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for dy: int in range(-radius, radius + 1):
		for dx: int in range(-radius, radius + 1):
			var p: Vector2i = center + Vector2i(dx, dy)
			if dx * dx + dy * dy <= radius * radius and p.x >= 0 and p.y >= 0 and p.x < image.get_width() and p.y < image.get_height():
				image.set_pixelv(p, image.get_pixelv(p).blend(color))


## 화면 맨 아래 평상 끝: 가로로 놓인 나무판
func _draw_bench() -> Image:
	var image: Image = Image.create(BENCH_SIZE.x, BENCH_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(wood_color)
	image.fill_rect(Rect2i(0, 0, BENCH_SIZE.x, 3), wood_light_color)
	for y: int in [14, 27]:
		image.fill_rect(Rect2i(0, y, BENCH_SIZE.x, 1), wood_dark_color)
	# 나뭇결: 드문드문 짧은 어두운 줄
	for i: int in 40:
		var x: int = (i * 53) % BENCH_SIZE.x
		var y: int = 6 + (i * 7) % 30
		image.fill_rect(Rect2i(x, y, 8, 1), wood_dark_color)
	return image
