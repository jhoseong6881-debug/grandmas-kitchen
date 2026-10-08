class_name Garnish
extends Resource
## 대접하기 전에 올리는 마무리 고명 하나 (예: 꿀 한 숟갈). data/garnishes/ 에 .tres 파일로 하나씩 만든다.
## 요리 "완성~!" 장면 옆에 고명 병으로 놓이고, 병을 집어 요리에 뿌린다 (DishShowcase, GarnishShaker).
## 손님마다 좋아하는 고명(AnimalGuest.favorite_garnish)이 있어서, 맞추면 단골도가 더 오른다.

## 세이브 파일에 저장되는 고유 이름표. 영어 소문자로 짓고 한 번 정하면 바꾸지 않는다. (예: honey_spoon)
@export var id: StringName = &""
## 화면에 보이는 이름 (예: 꿀 한 숟갈)
@export var display_name: String = ""
## 이 고명의 맛 (예: 달콤한 맛). 손님 수첩의 입맛 칸에 쓴다.
@export var taste_name: String = ""
## 완성 장면에 병이 놓이는 순서 (작을수록 위)
@export var sort_order: int = 0
## 올릴 때 드는 재료와 개수. 비워 두면 공짜 (밥집에 늘 있는 양념).
@export var cost_ingredient: Ingredient
@export var cost_amount: int = 1
## 고명 없이 그대로 내는 선택지인지. true 면 병 대신 "그대로 내기" 버튼이 된다.
@export var serve_as_is: bool = false
## 병에 붙는 이름표 (짧게, 줄바꿈 \n 가능. 예: "고춧\n가루"). 비워 두면 display_name.
@export var short_name: String = ""
## 뿌릴 때 떨어지는 알갱이 색
@export var sprinkle_color: Color = Color(0.95, 0.9, 0.75)
## 고명 병 그림 (서 있는 모습, 배경 투명). 비워 두면 임시 병 모양을 코드로 그린다.
@export var shaker_image: Texture2D


## 올리는 데 드는 재료 {id: 개수}. 공짜면 빈 Dictionary.
func get_cost() -> Dictionary[StringName, int]:
	var cost: Dictionary[StringName, int] = {}
	if cost_ingredient != null and cost_amount > 0:
		cost[cost_ingredient.id] = cost_amount
	return cost


## 병 이름표에 쓸 글
func get_short_name() -> String:
	return short_name if not short_name.is_empty() else display_name
