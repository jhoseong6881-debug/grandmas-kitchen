class_name MarketTrade
extends Resource
## 숲속 장터의 거래 하나: give 재료를 give_amount 개 내면 get 재료를 get_amount 개 받는다.
## MarketSettings 의 trades 에 넣어 두면 장날마다 그중 몇 개가 무작위로 나온다.

## 하루에 몇 번 바꿨는지 셀 때 쓰는 이름 (거래마다 달라야 한다)
@export var id: StringName
@export var give_ingredient: Ingredient
@export var give_amount: int = 2
@export var get_ingredient: Ingredient
@export var get_amount: int = 1


func get_cost() -> Dictionary[StringName, int]:
	var cost: Dictionary[StringName, int] = {}
	if give_ingredient != null:
		cost[give_ingredient.id] = give_amount
	return cost
