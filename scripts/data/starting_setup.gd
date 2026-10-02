class_name StartingSetup
extends Resource
## 새 게임을 시작할 때의 설정. data/starting_setup.tres 하나만 만든다.

## 시작할 때 받는 재료. 같은 재료를 여러 개 받으려면 여러 번 넣는다.
@export var starting_ingredients: Array[Ingredient] = []
## 처음부터 열려 있는 레시피. 나머지는 저녁 평상에서 손님에게 레시피 노트를 돌려받아 연다.
@export var starting_recipes: Array[Recipe] = []
