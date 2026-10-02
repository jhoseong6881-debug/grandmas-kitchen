extends PanelContainer
## 가진 재료 목록 패널. GameState 의 inventory_changed 시그널을 듣고 스스로 다시 그린다.
## 재료 이름과 그림은 GameData 에서 가져온다.

const ROW_TEXT_FORMAT: String = "%s  × %d"
const EMPTY_TEXT: String = "아직 재료가 없어요"

@export var icon_size: Vector2 = Vector2(48, 48)
## 그림이 아직 없는 재료에 쓰는 임시 사각형 색
@export var placeholder_icon_color: Color = Color(0.85, 0.55, 0.3)
@export var row_font_size: int = 24

@onready var _item_rows: VBoxContainer = %ItemRows


func _ready() -> void:
	GameState.inventory_changed.connect(_on_inventory_changed)
	_refresh()


func _on_inventory_changed(_ingredient_id: StringName, _new_count: int) -> void:
	_refresh()


func _refresh() -> void:
	for child: Node in _item_rows.get_children():
		child.queue_free()
	if GameState.inventory.is_empty():
		_item_rows.add_child(_make_label(EMPTY_TEXT))
		return
	for ingredient_id: StringName in GameState.inventory:
		_item_rows.add_child(_make_row(ingredient_id, GameState.get_ingredient_count(ingredient_id)))


func _make_row(ingredient_id: StringName, count: int) -> HBoxContainer:
	var ingredient: Ingredient = GameData.get_ingredient(ingredient_id)
	# data/ 에 없는 id면 이름 대신 id를 그대로 보여 준다.
	var display_name: String = ingredient.display_name if ingredient != null else String(ingredient_id)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_child(_make_icon(ingredient))
	row.add_child(_make_label(ROW_TEXT_FORMAT % [display_name, count]))
	return row


func _make_icon(ingredient: Ingredient) -> Control:
	if ingredient != null and ingredient.icon != null:
		var texture_rect: TextureRect = TextureRect.new()
		texture_rect.texture = ingredient.icon
		texture_rect.custom_minimum_size = icon_size
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return texture_rect
	var placeholder: ColorRect = ColorRect.new()
	placeholder.color = placeholder_icon_color
	placeholder.custom_minimum_size = icon_size
	return placeholder


func _make_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", row_font_size)
	return label
