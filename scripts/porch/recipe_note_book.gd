class_name RecipeNoteBook
extends Control
## 저녁 평상에서 할머니 레시피 노트 한 장을 되찾을 때 뜨는 펼친 책.
## 왼쪽 쪽에 완성 요리 그림(Recipe.finished_image, 원본 64×64 → 3배), 오른쪽 쪽에 요리 이름과 재료를 손글씨로.
## 책 그림(book_texture, 원본 280×160)이 있으면 그 그림을, 없으면 밤색 표지와 크림색 두 쪽 임시 모양을 보여 준다.
## 요리 그림이 없으면 접시 위에 첫 재료 색 음식을 올린 임시 그림을 그린다.

const INGREDIENTS_FORMAT: String = "재료: %s"
const INGREDIENT_SEPARATOR: String = ", "
const DISH_PIXELS: int = 64

## 펼친 책 그림 (원본 280×160, 배경 투명). 비워 두면 임시 모양.
@export var book_texture: Texture2D
## 도트 그림을 화면에서 키우는 배수
@export var pixel_scale: int = 3
## 뜰 때 커졌다 돌아오는 정도와 시간(초)
@export var pop_scale: float = 1.08
@export var pop_duration: float = 0.2
## 임시 요리 그림: 접시 색, 접시 테두리 색
@export var plate_color: Color = Color(0.95, 0.95, 0.92)
@export var plate_rim_color: Color = Color(0.62, 0.55, 0.47)

@onready var _book_art: TextureRect = %BookArt
@onready var _placeholder_book: Control = %PlaceholderBook
@onready var _dish_image: TextureRect = %DishImage
@onready var _recipe_label: Label = %RecipeLabel
@onready var _ingredients_label: Label = %IngredientsLabel


func _ready() -> void:
	hide()
	if book_texture != null:
		_book_art.texture = _scaled(book_texture.get_image())
		_placeholder_book.hide()
	else:
		_book_art.hide()


## 레시피 한 장을 펼쳐 보여 준다.
func show_recipe(recipe: Recipe) -> void:
	var names: PackedStringArray = []
	for ingredient: Ingredient in recipe.ingredients:
		if ingredient != null and ingredient.display_name not in names:
			names.append(ingredient.display_name)
	_recipe_label.text = recipe.display_name
	_ingredients_label.text = INGREDIENTS_FORMAT % INGREDIENT_SEPARATOR.join(names)
	var dish: Image = recipe.finished_image.get_image() if recipe.finished_image != null else _draw_dish(recipe)
	_dish_image.texture = _scaled(dish)
	pivot_offset = size / 2.0
	scale = Vector2.ONE * pop_scale
	show()
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, pop_duration)


func _scaled(source: Image) -> ImageTexture:
	var image: Image = source.duplicate()
	if image.is_compressed():
		image.decompress()
	image.resize(image.get_width() * pixel_scale, image.get_height() * pixel_scale, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


## 임시 요리 그림: 접시(테두리 있는 타원) 위에 첫 재료 색의 음식 더미
func _draw_dish(recipe: Recipe) -> Image:
	var image: Image = Image.create(DISH_PIXELS, DISH_PIXELS, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var food_color: Color = Color(0.85, 0.55, 0.3)
	if not recipe.ingredients.is_empty() and recipe.ingredients[0] != null:
		food_color = recipe.ingredients[0].placeholder_color
	var center: Vector2 = Vector2(DISH_PIXELS / 2.0, DISH_PIXELS * 0.62)
	for y: int in DISH_PIXELS:
		for x: int in DISH_PIXELS:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var plate: float = pow((p.x - center.x) / 30.0, 2) + pow((p.y - center.y) / 14.0, 2)
			if plate <= 1.0:
				image.set_pixel(x, y, plate_rim_color if plate > 0.78 else plate_color)
			var food: float = pow((p.x - center.x) / 18.0, 2) + pow((p.y - (center.y - 6.0)) / 12.0, 2)
			if food <= 1.0:
				var shade: Color = food_color.lightened(0.25) if p.y < center.y - 11.0 else food_color
				image.set_pixel(x, y, shade.darkened(0.3) if food > 0.85 else shade)
	return image
