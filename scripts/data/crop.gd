class_name Crop
extends Resource
## 심을 수 있는 작물 하나의 정보. data/crops/ 에 .tres 파일로 하나씩 만든다.
## 빈 칸을 골라 심으면 grow_days 일 뒤 아침에 거둘 수 있다. 거두면 그 칸은 다시 비어서 또 심을 수 있다.
## 물 주기나 비료 같은 복잡한 농사는 없다.
## 칸 안에는 자라는 정도에 맞춰 작물이 그려진다 (PlotPlant). 그림이 없으면 placeholder_shape 모양의 도형으로 그린다.

## 그림이 없을 때 쓰는 도형: 새싹(줄기와 잎, 다 자라면 뿌리 끝이 보인다) / 버섯(갓이 커지고 늘어난다)
enum PlaceholderShape { SPROUT, MUSHROOM }

## 세이브 파일에 저장되는 고유 이름표. 영어 소문자로 짓고 한 번 정하면 바꾸지 않는다. (예: carrot)
@export var id: StringName = &""
## 거두면 들어오는 재료와 개수
@export var ingredient: Ingredient
@export var harvest_amount: int = 1
## 심고 나서 다 자라기까지 걸리는 날 수
@export var grow_days: int = 2
## 심을 때 드는 재료와 개수 (예: 버섯 종균으로 버섯 1개). 비워 두면 공짜로 심는다.
@export var seed_ingredient: Ingredient
@export var seed_amount: int = 1
## 그림이 없을 때 칸 안에 그리는 도형
@export var placeholder_shape: PlaceholderShape = PlaceholderShape.SPROUT
## 자라는 단계별 그림 (첫 장 = 막 심음, 마지막 장 = 다 자람). 비워 두면 도형으로 그린다.
@export var growth_textures: Array[Texture2D] = []


## 심는 데 드는 재료 {id: 개수}. 공짜면 빈 Dictionary.
func get_seed_cost() -> Dictionary[StringName, int]:
	var cost: Dictionary[StringName, int] = {}
	if seed_ingredient != null and seed_amount > 0:
		cost[seed_ingredient.id] = seed_amount
	return cost
