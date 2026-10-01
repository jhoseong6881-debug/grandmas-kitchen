class_name Recipe
extends Resource
## 레시피 하나의 정보. data/recipes/ 에 .tres 파일로 하나씩 만든다.

## 요리 미니게임 종류
enum MinigameType { CHOP, STIR_FRY, PLATE }

## 세이브 파일에 저장되는 고유 이름표. 영어 소문자로 짓고 한 번 정하면 바꾸지 않는다. (예: spring_bibimbap)
@export var id: StringName = &""
## 화면에 보이는 이름 (예: 봄나물 비빔밥)
@export var display_name: String = ""
## 필요한 재료. 같은 재료가 2개 필요하면 두 번 넣는다.
@export var ingredients: Array[Ingredient] = []
## 미니게임을 진행하는 순서 (예: 썰기 → 볶기 → 담기)
@export var minigame_steps: Array[MinigameType] = []
## 완성된 요리 그림. 비워 두면 임시 도형으로 표시한다.
@export var finished_image: Texture2D
