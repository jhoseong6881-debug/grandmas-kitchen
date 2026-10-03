class_name Recipe
extends Resource
## 레시피 하나의 정보. data/recipes/ 에 .tres 파일로 하나씩 만든다.

## 요리 미니게임 종류
## 세이브와 .tres 에는 번호로 저장되니, 새 종류는 맨 뒤에만 붙인다.
enum MinigameType { CHOP, STIR_FRY, PLATE, PAN_FRY, ROLL, COOK_RICE, MIX, SIMMER, MINCE }

## 미니게임 화면 제목에 쓰는 기본 동작 이름. 요리 단계(CookStep)에 동작 이름이 비어 있으면 이걸 쓴다.
const DEFAULT_ACTION_NAMES: Dictionary[MinigameType, String] = {
	MinigameType.CHOP: "썰기",
	MinigameType.STIR_FRY: "볶기",
	MinigameType.PLATE: "담기",
	MinigameType.PAN_FRY: "부치기",
	MinigameType.ROLL: "말기",
	MinigameType.COOK_RICE: "밥 짓기",
	MinigameType.MIX: "버무리기",
	MinigameType.SIMMER: "조리기",
	MinigameType.MINCE: "다지기",
}

## 세이브 파일에 저장되는 고유 이름표. 영어 소문자로 짓고 한 번 정하면 바꾸지 않는다. (예: spring_bibimbap)
@export var id: StringName = &""
## 화면에 보이는 이름 (예: 봄나물 비빔밥)
@export var display_name: String = ""
## 필요한 재료. 같은 재료가 2개 필요하면 두 번 넣는다.
@export var ingredients: Array[Ingredient] = []
## 요리 단계를 차례대로. 단계마다 미니게임 종류, 재료, 횟수, 빠르기를 정한다.
## (예: 밥 짓기 → 당근 채썰기 12번 빠르게 → 당근 볶기 3번 → 김밥 썰기 8번 → 담기 2그릇)
@export var cook_steps: Array[CookStep] = []
## 요리 단계에 이름도 재료도 없을 때 미니게임 제목에 쓰는 이름 (예: "도토리묵" → "도토리묵 썰기").
## 비워 두면 첫 번째 재료 이름을 쓴다.
@export var minigame_ingredient_name: String = ""
## 완성된 요리 그림. 비워 두면 임시 도형으로 표시한다.
@export var finished_image: Texture2D
## 버무리기 미니게임에서 묻히는 양념 (data/coatings/). 버무리기가 없는 레시피는 비워 둔다.
@export var mix_coating: Coating
## 버무리기 미니게임에서 양념을 묻힐 재료. 비워 두면 첫 번째 재료를 쓴다.
@export var mix_piece_ingredient: Ingredient
## 이 레시피 노트를 손님에게서 돌려받을 수 있는 계절. 그 계절에만 평상에서 받을 수 있고, 못 받으면 돌아오는 같은 계절에 이어서 받는다.
@export var note_season: Season.Id = Season.Id.SPRING
## 할머니 비법 (요리 단계 중 하나에 비법 자리를 정해 둔다). 비법이 없는 레시피는 비워 둔다.
## 수첩과 미니게임에 보이는 비법 한 줄 (예: "김밥은 칼을 꼭 한가운데로")
@export var secret_hint: String = ""
## 비법을 알려 주는 손님 id (예: rabbit). 레시피를 되찾은 뒤 이 손님이 저녁에 찾아오면 알려 준다.
@export var secret_teller_id: StringName = &""
## 손님이 비법을 알려 줄 때 하는 말
@export_multiline var secret_reveal_line: String = ""
## 할머니 손맛으로 대접했을 때 손님이 하는 말 ({name} = 주인공 이름)
@export_multiline var grandma_taste_line: String = ""
## 조리기 미니게임에서 졸이는 조림장 (data/coatings/). 조리기가 없는 레시피는 비워 둔다.
## 졸이는 재료 조각은 첫 번째 재료를 쓴다.
@export var simmer_sauce: Coating


## 썰기/볶기 화면 제목에 쓸 재료 이름. 정해 둔 이름이 없으면 첫 번째 재료 이름, 재료도 없으면 빈 문자열.
func get_minigame_ingredient_name() -> String:
	if not minigame_ingredient_name.is_empty():
		return minigame_ingredient_name
	if not ingredients.is_empty():
		return ingredients[0].display_name
	return ""


## 미니게임 종류의 기본 동작 이름 (썰기, 볶기, 담기 …)
static func get_default_action_name(minigame_type: MinigameType) -> String:
	return DEFAULT_ACTION_NAMES[minigame_type]


## 버무리기에서 양념을 묻힐 재료. 정해 둔 재료가 없으면 첫 번째 재료, 재료도 없으면 null.
func get_mix_piece_ingredient() -> Ingredient:
	if mix_piece_ingredient != null:
		return mix_piece_ingredient
	return ingredients[0] if not ingredients.is_empty() else null


## 재료 id별로 몇 개 필요한지 센다. (예: {carrot: 1, egg: 2})
func get_ingredient_counts() -> Dictionary[StringName, int]:
	var counts: Dictionary[StringName, int] = {}
	for ingredient: Ingredient in ingredients:
		counts[ingredient.id] = counts.get(ingredient.id, 0) + 1
	return counts
