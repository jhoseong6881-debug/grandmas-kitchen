class_name Garnish
extends Resource
## 대접하기 전에 올리는 마무리 고명 하나 (예: 꿀 한 숟갈). data/garnishes/ 에 .tres 파일로 하나씩 만든다.
## 손님마다 좋아하는 고명(AnimalGuest.favorite_garnish)이 있어서, 맞추면 단골도가 더 오른다.

## 세이브 파일에 저장되는 고유 이름표. 영어 소문자로 짓고 한 번 정하면 바꾸지 않는다. (예: honey_spoon)
@export var id: StringName = &""
## 화면에 보이는 이름 (예: 꿀 한 숟갈)
@export var display_name: String = ""
## 이 고명의 맛 (예: 달콤한 맛). 손님 수첩의 입맛 칸에 쓴다.
@export var taste_name: String = ""
## 고르는 창에 놓이는 순서 (작을수록 위)
@export var sort_order: int = 0
## 올릴 때 드는 재료와 개수. 비워 두면 공짜 (밥집에 늘 있는 양념).
@export var cost_ingredient: Ingredient
@export var cost_amount: int = 1


## 올리는 데 드는 재료 {id: 개수}. 공짜면 빈 Dictionary.
func get_cost() -> Dictionary[StringName, int]:
	var cost: Dictionary[StringName, int] = {}
	if cost_ingredient != null and cost_amount > 0:
		cost[cost_ingredient.id] = cost_amount
	return cost
