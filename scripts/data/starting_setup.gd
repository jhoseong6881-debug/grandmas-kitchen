class_name StartingSetup
extends Resource
## 새 게임을 시작할 때의 설정. data/starting_setup.tres 하나만 만든다.

## 시작할 때 받는 재료. 같은 재료를 여러 개 받으려면 여러 번 넣는다.
@export var starting_ingredients: Array[Ingredient] = []
## 처음부터 열려 있는 레시피. 나머지는 저녁 평상에서 손님에게 레시피 노트를 돌려받아 연다.
@export var starting_recipes: Array[Recipe] = []
## 첫날 아침 텃밭에 보여 주는 글 (처음부터 열린 레시피를 어떻게 알게 됐는지 등). 비워 두면 안 보여 준다.
@export_multiline var first_morning_text: String = ""
## 첫 봄 며칠 아침에 안내 글 아래 덧붙이는 한 줄 (날 → 글). 처음 하는 사람에게 손님 수첩·봄 목표 같은 걸 알려 준다.
## 두 번째 봄부터는 나오지 않는다.
@export var morning_tips: Dictionary[int, String] = {}
