class_name GarnishPicker
extends ChoicePicker
## "어떻게 마무리할까요?" 창. 요리를 다 하고 대접하기 전에 열려서, 올릴 고명(data/garnishes/)을 고른다.
## 고명마다 맛과 드는 재료를 보여 주고, 재료가 모자라면 고를 수 없다.
## 손님의 입맛 힌트를 받으면 제목 아래에 다시 보여 준다 (주문 때 한 말을 잊었어도 고를 수 있게).
## 고르면 closed(고명), 그만두면 closed(null).

signal closed(garnish: Garnish)

const TITLE_TEXT: String = "어떻게 마무리할까요?"
const GARNISH_FORMAT: String = "%s  ·  %s  ·  %s"
const FREE_TEXT: String = "공짜"
const COST_FORMAT: String = "%s %d개 필요 (가진 것 %d)"
## 제목 아래 손님 줄: "[얼굴] 곰 · 꿀 당근 조림 주문"
const GUEST_FORMAT: String = " %s  ·  %s 주문"
## 손님 얼굴 아이콘 크기
@export var guest_icon_size: int = 36

var _garnishes: Array[Garnish] = []


func _ready() -> void:
	super()
	chosen.connect(_on_chosen)


## hint: 제목 아래에 보여 줄 손님의 입맛 힌트 (없으면 빈 글)
## guest, recipe: 누구의 어떤 주문인지 (제목 아래 한 줄. 없으면 안 보인다)
func open(hint: String = "", guest: AnimalGuest = null, recipe: Recipe = null) -> void:
	var guest_label: RichTextLabel = %GuestLabel
	guest_label.clear()
	guest_label.visible = guest != null
	if guest != null:
		guest_label.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		guest_label.add_image(guest.get_icon_texture(), guest_icon_size, guest_icon_size, Color.WHITE, INLINE_ALIGNMENT_CENTER)
		guest_label.add_text(GUEST_FORMAT % [guest.display_name, recipe.display_name if recipe != null else ""])
		guest_label.pop()
	var hint_label: Label = %HintLabel
	hint_label.text = hint
	hint_label.visible = not hint.is_empty()
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
