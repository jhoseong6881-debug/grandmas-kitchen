class_name RecipeNoteBook
extends Control
## 저녁 평상에서 할머니 레시피 노트 한 장을 되찾을 때 뜨는 펼친 책.
## 왼쪽 쪽에 완성 요리 그림(Recipe.finished_image, 원본 64×64 → 3배), 오른쪽 쪽에 요리 이름과 재료를 손글씨로.
## 책 그림(book_texture, 원본 280×160)이 있으면 그 그림을, 없으면 밤색 표지와 크림색 두 쪽 임시 모양을 보여 준다.
## 요리 그림이 없으면 DishArt 가 임시 그림을 그린다 (국물 요리는 그릇).

const INGREDIENTS_FORMAT: String = "재료: %s"
const INGREDIENT_SEPARATOR: String = ", "

## 펼친 책 그림 (원본 280×160, 배경 투명). 비워 두면 임시 모양.
@export var book_texture: Texture2D
## 도트 그림을 화면에서 키우는 배수
@export var pixel_scale: int = 3
## 뜰 때 커졌다 돌아오는 정도와 시간(초)
@export var pop_scale: float = 1.08
@export var pop_duration: float = 0.2

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
	_dish_image.texture = DishArt.get_texture(recipe, pixel_scale)
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
