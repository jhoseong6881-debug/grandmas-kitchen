class_name LunchboxPicker
extends ChoicePicker
## 소풍 도시락 날(SpecialLunch.PICNIC) "○○ 도시락에 넣을 요리" 창. "아무거나 맛있는 거" 날에도 손님에게 낼 요리를 고를 때 쓴다. 오늘의 메뉴에 있는 되찾은 요리 중 하나를 고른다.
## 요리마다 드는 재료를 보여 주고, 재료가 모자라면 고를 수 없다. 누가 무엇을 좋아하는지는 보여 주지 않는다 (손님 수첩에서 찾아보게).
## 그만두기 버튼 자리는 "손님 수첩 보기"다. 고르면 closed(요리), 수첩 보기를 누르면 closed(null).

signal closed(recipe: Recipe)

const RECIPE_FORMAT: String = "%s  ·  %s"
const INGREDIENT_FORMAT: String = "%s %d"
const INGREDIENT_SEPARATOR: String = ", "
const SHORT_SUFFIX: String = "  (재료 부족)"
## 제목 아래 손님 줄: "[얼굴] 곰 도시락"
const GUEST_FORMAT: String = " %s 도시락"
## 이미 싼 도시락: "이미 싼 도시락: 김밥, 계란말이"
const PACKED_FORMAT: String = "이미 싼 도시락: %s"
const PACKED_SEPARATOR: String = ", "
@export var guest_icon_size: int = 36
## 요리가 많아 줄이 창을 넘칠 때: 줄 높이를 창에 맞게 줄이고, 줄이 이보다 낮아지면 작은 글자를 쓴다
@export var small_row_threshold: float = 64.0
@export var small_font_size: int = 24
@export var row_gap: float = 4.0

var _base_row_height: float = 0.0
var _base_font_size: int = 0

var _recipes: Array[Recipe] = []


func _ready() -> void:
	super()
	chosen.connect(_on_chosen)
	_base_row_height = row_height
	_base_font_size = row_font_size


## title: 창 제목, guest: 도시락 주인, recipes: 고를 수 있는 요리, packed: 이미 싼 요리 이름들,
## notebook_text: 그만두기 버튼 대신 쓰는 글 (누르면 closed(null))
## guest_format, packed_format: 손님 줄과 이미 고른 요리 줄 모양 (비우면 도시락용)
func open(title: String, guest: AnimalGuest, recipes: Array[Recipe], packed: Array[String], notebook_text: String,
		guest_format: String = GUEST_FORMAT, packed_format: String = PACKED_FORMAT) -> void:
	var guest_label: RichTextLabel = %GuestLabel
	guest_label.clear()
	guest_label.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	guest_label.add_image(guest.get_icon_texture(), guest_icon_size, guest_icon_size, Color.WHITE, INLINE_ALIGNMENT_CENTER)
	guest_label.add_text(guest_format % guest.display_name)
	guest_label.pop()
	guest_label.show()
	var packed_label: Label = %HintLabel
	packed_label.text = packed_format % PACKED_SEPARATOR.join(packed) if not packed.is_empty() else ""
	packed_label.visible = not packed.is_empty()
	_cancel_button.text = notebook_text
	_recipes = recipes
	var texts: Array[String] = []
	var enabled: Array[bool] = []
	for recipe: Recipe in recipes:
		var counts: Dictionary[StringName, int] = recipe.get_ingredient_counts()
		var can_cook: bool = GameState.has_ingredients(counts)
		texts.append(RECIPE_FORMAT % [recipe.display_name, _ingredients_text(counts)] + ("" if can_cook else SHORT_SUFFIX))
		enabled.append(can_cook)
	_fit_rows(texts.size())
	open_choices(title, texts, enabled)


## 고를 요리 수에 맞춰 줄 높이와 글자 크기를 정한다 (메뉴 칸이 늘어 요리가 많아져도 창 안에 들어가게).
func _fit_rows(count: int) -> void:
	var available: float = _choice_rows.size.y
	var fitted: float = floorf((available - row_gap * maxi(count - 1, 0)) / maxi(count, 1))
	row_height = minf(_base_row_height, fitted) if available > 0.0 else _base_row_height
	row_font_size = _base_font_size if row_height >= small_row_threshold else small_font_size
	_choice_rows.add_theme_constant_override("separation", int(row_gap))


func _ingredients_text(counts: Dictionary[StringName, int]) -> String:
	var parts: PackedStringArray = []
	for ingredient_id: StringName in counts:
		var ingredient: Ingredient = GameData.get_ingredient(ingredient_id)
		parts.append(INGREDIENT_FORMAT % [ingredient.display_name if ingredient != null else String(ingredient_id), counts[ingredient_id]])
	return INGREDIENT_SEPARATOR.join(parts)


func _on_chosen(index: int) -> void:
	closed.emit(_recipes[index] if index >= 0 else null)
