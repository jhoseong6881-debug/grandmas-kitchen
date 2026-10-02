class_name GarnishPicker
extends ChoicePicker
## "어떻게 마무리할까요?" 창. 요리를 다 하고 대접하기 전에 열려서, 올릴 고명(data/garnishes/)을 고른다.
## 고명마다 맛과 드는 재료를 보여 주고, 재료가 모자라면 고를 수 없다.
## 고르면 closed(고명), 그만두면 closed(null).

signal closed(garnish: Garnish)

const TITLE_TEXT: String = "어떻게 마무리할까요?"
const GARNISH_FORMAT: String = "%s  ·  %s  ·  %s"
const FREE_TEXT: String = "공짜"
const COST_FORMAT: String = "%s %d개 필요 (가진 것 %d)"

var _garnishes: Array[Garnish] = []


func _ready() -> void:
	super()
	chosen.connect(_on_chosen)


func open() -> void:
	_garnishes = GameData.get_all_garnishes()
	var texts: Array[String] = []
	var enabled: Array[bool] = []
	for garnish: Garnish in _garnishes:
		texts.append(GARNISH_FORMAT % [garnish.display_name, garnish.taste_name, _cost_text(garnish)])
		enabled.append(GameState.has_ingredients(garnish.get_cost()))
	open_choices(TITLE_TEXT, texts, enabled)


func _cost_text(garnish: Garnish) -> String:
	if garnish.cost_ingredient == null or garnish.cost_amount <= 0:
		return FREE_TEXT
	return COST_FORMAT % [garnish.cost_ingredient.display_name, garnish.cost_amount,
			GameState.get_ingredient_count(garnish.cost_ingredient.id)]


func _on_chosen(index: int) -> void:
	closed.emit(_garnishes[index] if index >= 0 else null)
