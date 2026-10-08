class_name RecipeNoteBook
extends Control
## 저녁 평상에서 할머니 레시피 노트 한 장을 되찾을 때 뜨는 펼친 책.
## 왼쪽 쪽에 완성 요리 그림(Recipe.finished_image, 원본 64×64 → 3배), 오른쪽 쪽에 요리 이름과 재료를 손글씨로.
## 책 그림(book_texture, 원본 280×160)이 있으면 그 그림을, 없으면 밤색 표지와 크림색 두 쪽 임시 모양을 보여 준다.
## 요리 그림이 없으면 DishArt 가 임시 그림을 그린다 (국물 요리는 그릇).
## 번진 노트 퍼즐을 푼 요리면 재료 아래에 할머니 요령 한 줄(NotePuzzle.hint)이 손글씨로 적혀 있다.
## 그날 점심에 푼 요리는 그 한 줄이 한 글자씩 써진다 (show_recipe 의 write_tip).

const INGREDIENTS_FORMAT: String = "재료: %s"
const INGREDIENT_SEPARATOR: String = ", "
const TIP_FORMAT: String = "\"%s\""

## 펼친 책 그림 (원본 280×160, 배경 투명). 비워 두면 임시 모양.
@export var book_texture: Texture2D
## 도트 그림을 화면에서 키우는 배수
@export var pixel_scale: int = 3
## 뜰 때 커졌다 돌아오는 정도와 시간(초)
@export var pop_scale: float = 1.08
@export var pop_duration: float = 0.2
## 요령 한 줄이 써지기 시작하기까지 기다리는 시간(초)과 한 글자 쓰는 시간(초), 쓸 때 소리
@export var tip_write_delay: float = 0.5
@export var tip_seconds_per_char: float = 0.06
@export var tip_write_sound: StringName = &"rustle"

@onready var _book_art: TextureRect = %BookArt
@onready var _placeholder_book: Control = %PlaceholderBook
@onready var _dish_image: TextureRect = %DishImage
@onready var _recipe_label: Label = %RecipeLabel
@onready var _ingredients_label: Label = %IngredientsLabel
@onready var _tip_label: Label = %TipLabel


func _ready() -> void:
	hide()
	if book_texture != null:
		_book_art.texture = _scaled(book_texture.get_image())
		_placeholder_book.hide()
	else:
		_book_art.hide()


## 레시피 한 장을 펼쳐 보여 준다. write_tip 이면 할머니 요령 한 줄이 한 글자씩 써진다.
func show_recipe(recipe: Recipe, write_tip: bool = false) -> void:
	var names: PackedStringArray = []
	for ingredient: Ingredient in recipe.ingredients:
		if ingredient != null and ingredient.display_name not in names:
			names.append(ingredient.display_name)
	_recipe_label.text = recipe.display_name
	_ingredients_label.text = INGREDIENTS_FORMAT % INGREDIENT_SEPARATOR.join(names)
	_dish_image.texture = DishArt.get_texture(recipe, pixel_scale)
	var has_tip: bool = recipe.note_puzzle != null and not recipe.note_puzzle.hint.is_empty() \
			and GameState.is_note_puzzle_solved(recipe.id)
	_tip_label.visible = has_tip
	_tip_label.visible_ratio = 1.0
	if has_tip:
		# 한글이 낱말 중간에서 줄이 바뀌지 않게 띄어쓰기 자리에서 미리 줄을 나눈다.
		_tip_label.text = Korean.wrap_by_spaces(TIP_FORMAT % recipe.note_puzzle.hint, _tip_label.get_theme_font("font"),
				_tip_label.get_theme_font_size("font_size"), (_tip_label.get_parent() as Control).size.x)
		if write_tip:
			_write_tip()
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


## 요령 한 줄을 한 글자씩 써 내려간다.
func _write_tip() -> void:
	_tip_label.visible_ratio = 0.0
	var tween: Tween = create_tween()
	tween.tween_interval(tip_write_delay)
	tween.tween_callback(Sound.play.bind(tip_write_sound))
	tween.tween_property(_tip_label, "visible_ratio", 1.0, tip_seconds_per_char * _tip_label.text.length())
