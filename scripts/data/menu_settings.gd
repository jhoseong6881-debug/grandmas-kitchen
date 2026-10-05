class_name MenuSettings
extends Resource
## 오늘의 메뉴 칸 수 규칙. data/menu_settings.tres 하나만 만든다.
## 되찾은 레시피(모든 계절)가 늘수록 메뉴 칸이 는다. 레시피를 모으는 재미가 계절이 바뀌어도 이어지게.

## 처음 메뉴 칸 수
@export var base_dishes: int = 3
## 레시피를 이만큼 모을 때마다 메뉴 칸 +1 (0 이면 늘지 않는다)
@export var recipes_per_extra_dish: int = 5
## 메뉴 칸 최대
@export var max_dishes: int = 8


## 되찾은 레시피 수 recipe_count 일 때 메뉴 칸 수
func get_max_dishes(recipe_count: int) -> int:
	var extra: int = recipe_count / recipes_per_extra_dish if recipes_per_extra_dish > 0 else 0
	return clampi(base_dishes + extra, 1, max_dishes)
