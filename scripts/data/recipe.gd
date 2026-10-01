class_name Recipe
extends Resource
## 레시피 하나의 정보. data/recipes/ 에 .tres 파일로 하나씩 만든다.

## 요리 미니게임 종류
enum MinigameType { CHOP, STIR_FRY, PLATE }

## 미니게임 화면 제목에 쓰는 기본 동작 이름. 레시피의 ○○ Action Name 칸이 비어 있으면 이걸 쓴다.
const DEFAULT_ACTION_NAMES: Dictionary[MinigameType, String] = {
	MinigameType.CHOP: "썰기",
	MinigameType.STIR_FRY: "볶기",
	MinigameType.PLATE: "담기",
}

## 세이브 파일에 저장되는 고유 이름표. 영어 소문자로 짓고 한 번 정하면 바꾸지 않는다. (예: spring_bibimbap)
@export var id: StringName = &""
## 화면에 보이는 이름 (예: 봄나물 비빔밥)
@export var display_name: String = ""
## 필요한 재료. 같은 재료가 2개 필요하면 두 번 넣는다.
@export var ingredients: Array[Ingredient] = []
## 미니게임을 진행하는 순서 (예: 썰기 → 볶기 → 담기)
@export var minigame_steps: Array[MinigameType] = []
## 썰기/볶기 화면 제목에 쓰는 재료 이름 (예: "도토리묵" → "도토리묵 썰기").
## 비워 두면 첫 번째 재료 이름을 쓴다.
@export var minigame_ingredient_name: String = ""
## 미니게임 화면 제목에 쓰는 동작 이름 (예: 볶기 대신 "부치기" → "당근 부치기"). 비워 두면 기본 이름을 쓴다.
@export var chop_action_name: String = ""
@export var stir_fry_action_name: String = ""
@export var plate_action_name: String = ""
## 완성된 요리 그림. 비워 두면 임시 도형으로 표시한다.
@export var finished_image: Texture2D


## 썰기/볶기 화면 제목에 쓸 재료 이름. 정해 둔 이름이 없으면 첫 번째 재료 이름, 재료도 없으면 빈 문자열.
func get_minigame_ingredient_name() -> String:
	if not minigame_ingredient_name.is_empty():
		return minigame_ingredient_name
	if not ingredients.is_empty():
		return ingredients[0].display_name
	return ""


## 미니게임 화면 제목에 쓸 동작 이름. 이 레시피에 정해 둔 이름이 없으면 기본 이름(썰기/볶기/담기).
func get_action_name(minigame_type: MinigameType) -> String:
	var custom_names: Dictionary[MinigameType, String] = {
		MinigameType.CHOP: chop_action_name,
		MinigameType.STIR_FRY: stir_fry_action_name,
		MinigameType.PLATE: plate_action_name,
	}
	if not custom_names[minigame_type].is_empty():
		return custom_names[minigame_type]
	return DEFAULT_ACTION_NAMES[minigame_type]


## 재료 id별로 몇 개 필요한지 센다. (예: {carrot: 1, egg: 2})
func get_ingredient_counts() -> Dictionary[StringName, int]:
	var counts: Dictionary[StringName, int] = {}
	for ingredient: Ingredient in ingredients:
		counts[ingredient.id] = counts.get(ingredient.id, 0) + 1
	return counts
