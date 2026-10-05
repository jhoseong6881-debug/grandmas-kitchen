class_name DishArt
extends RefCounted
## 완성 요리 그림 (원본 64×64). 레시피에 완성 그림(Recipe.finished_image)이 있으면 그 그림,
## 없으면 접시(국물 요리는 그릇) 위에 재료 색 음식을 올린 임시 도트 그림을 그린다.
## 레시피 노트, 요리 완성 장면, 대접할 때 미끄러지는 접시가 같이 쓴다.

const PIXELS: int = 64
const PLATE_COLOR: Color = Color(0.95, 0.95, 0.92)
const PLATE_RIM_COLOR: Color = Color(0.62, 0.55, 0.47)
const BOWL_COLOR: Color = Color(0.86, 0.82, 0.74)
const BROTH_COLOR: Color = Color(0.78, 0.6, 0.38)
const DEFAULT_FOOD_COLOR: Color = Color(0.85, 0.55, 0.3)


## 그림 (원본 크기). scale 배로 또렷하게(가장 가까운 점으로) 키운 텍스처는 get_texture 로.
static func get_image(recipe: Recipe) -> Image:
	if recipe.finished_image != null:
		var image: Image = recipe.finished_image.get_image().duplicate()
		if image.is_compressed():
			image.decompress()
		return image
	return _draw_placeholder(recipe)


static func get_texture(recipe: Recipe, scale: int = 3) -> ImageTexture:
	var image: Image = get_image(recipe)
	image.resize(image.get_width() * scale, image.get_height() * scale, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


## 접시(테두리 있는 타원) 또는 그릇(깊은 테두리 + 국물) 위에 재료 색 음식 더미. 재료가 둘 이상이면 두 색을 섞는다.
static func _draw_placeholder(recipe: Recipe) -> Image:
	var image: Image = Image.create(PIXELS, PIXELS, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var colors: Array[Color] = []
	for ingredient: Ingredient in recipe.ingredients:
		if ingredient != null and ingredient.placeholder_color not in colors:
			colors.append(ingredient.placeholder_color)
	if colors.is_empty():
		colors.append(DEFAULT_FOOD_COLOR)
	var is_bowl: bool = recipe.serve_in_bowl
	var center: Vector2 = Vector2(PIXELS / 2.0, PIXELS * 0.6)
	var dish_half: Vector2 = Vector2(30.0, 16.0 if is_bowl else 14.0)
	for y: int in PIXELS:
		for x: int in PIXELS:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var dish: float = pow((p.x - center.x) / dish_half.x, 2) + pow((p.y - center.y) / dish_half.y, 2)
			if dish <= 1.0:
				var rim: float = 0.6 if is_bowl else 0.78
				var inside: Color = BROTH_COLOR if is_bowl else PLATE_COLOR
				image.set_pixel(x, y, (BOWL_COLOR if is_bowl else PLATE_RIM_COLOR) if dish > rim else inside)
			var food_center: Vector2 = center - Vector2(0.0, 2.0 if is_bowl else 6.0)
			var food: float = pow((p.x - food_center.x) / (16.0 if is_bowl else 18.0), 2) \
					+ pow((p.y - food_center.y) / (9.0 if is_bowl else 12.0), 2)
			if food <= 1.0:
				# 두 색이면 얼룩덜룩 섞는다 (볶음, 전 고명처럼)
				var color: Color = colors[0]
				if colors.size() > 1 and (x / 4 + y / 3) % 3 == 0:
					color = colors[1]
				var shade: Color = color.lightened(0.25) if p.y < food_center.y - 5.0 else color
				image.set_pixel(x, y, shade.darkened(0.3) if food > 0.85 else shade)
	return image
