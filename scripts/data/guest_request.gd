class_name GuestRequest
extends Resource
## 손님이 주문할 때 가끔 덧붙이는 "오늘의 부탁" 하나 (예: "오늘은 바삭하게요!"). data/requests/ 에 .tres 로 하나씩 만든다.
## 두 가지 종류가 있다.
##   - 요리 단계 부탁: step_type 단계의 미니게임에서 지킨다. 부탁 자리(zone)가 있으면 모든 동작을 그 자리에서,
##     없으면 한 번도 안 틀리면 들어준 것. 횟수와 빠르기를 바꿀 수도 있다 (예: 잘게 다지기 = 횟수 1.5배).
##   - 고명 부탁: garnish 를 정해 두면, 마무리에서 그 고명을 올리면 들어준 것.
##   - 미니게임 바꾸기: use_new_minigame 을 켜면 그 단계를 이번만 new_minigame_type 미니게임으로 한다
##     (예: "잘게 다져 주세요" → 재료 썰기를 다지기로). 이때는 재료가 있는 단계에만 붙고,
##     그 단계의 횟수, 빠르기, 할머니 비법은 쓰지 않는다 (새 미니게임의 기본값 + 이 부탁의 값).

## 세이브 파일에 저장되는 고유 이름표 (예: crispy_pan_fry)
@export var id: StringName = &""
## 주문 말 뒤에 덧붙이는 부탁 (예: "오늘은 바삭하게요!")
@export var line: String = ""
## 미니게임 화면에 보이는 하는 법 (예: "바삭하게 (짙은 금색에서 뒤집기)")
@export var guide_text: String = ""
## 들어줬을 때 손님이 하는 말
@export var thanks_line: String = ""
## 고명 부탁이면 올려야 할 고명. 비워 두면 요리 단계 부탁.
@export var garnish: Garnish
## 요리 단계 부탁이 걸리는 미니게임 종류. 그 레시피에 이 단계가 있어야 부탁이 나온다.
@export var step_type: Recipe.MinigameType = Recipe.MinigameType.CHOP
## 켜면 그 단계를 이번만 다른 미니게임으로 한다
@export var use_new_minigame: bool = false
@export var new_minigame_type: Recipe.MinigameType = Recipe.MinigameType.MINCE
## 미니게임 제목에 쓰는 동작 이름 (예: "잘게 다지기"). 비워 두면 원래 동작 이름.
@export var action_name: String = ""
## 부탁 자리: 금색 칸 안의 시작과 끝 (0 ~ 1, 쪽 방향은 CookStep 의 비법 자리와 같다). 끝이 시작보다 크지 않으면 "안 틀리기" 부탁.
@export_range(0.0, 1.0) var zone_start: float = 0.0
@export_range(0.0, 1.0) var zone_end: float = 0.0
## 그 단계의 횟수 배율과 더하는 횟수, 빠르기 배율
@export var count_multiplier: float = 1.0
@export var count_bonus: int = 0
@export var speed_multiplier: float = 1.0


func is_garnish_request() -> bool:
	return garnish != null


func has_zone() -> bool:
	return zone_end > zone_start


func is_in_zone(position: float) -> bool:
	return has_zone() and position >= zone_start and position <= zone_end


## 이 레시피에 나올 수 있는 부탁인지 (고명 부탁은 언제나, 요리 단계 부탁은 걸 수 있는 단계가 있을 때)
func applies_to(recipe: Recipe) -> bool:
	if is_garnish_request():
		return true
	return recipe.cook_steps.any(applies_to_step)


## 이 요리 단계에 걸 수 있는지. 미니게임을 바꾸는 부탁은 재료가 있는 단계에만 (김밥 썰기 같은 완성 음식 자르기는 빼고).
func applies_to_step(step: CookStep) -> bool:
	if is_garnish_request() or step.type != step_type:
		return false
	return not use_new_minigame or step.ingredient != null


## 이 부탁이 걸린 단계에서 실제로 할 미니게임 종류
func get_minigame_type(step: CookStep) -> Recipe.MinigameType:
	return new_minigame_type if use_new_minigame else step.type


## 부탁에 맞춰 바꾼 횟수 (적어도 1)
func adjust_count(count: int) -> int:
	return maxi(roundi(count * count_multiplier) + count_bonus, 1)
