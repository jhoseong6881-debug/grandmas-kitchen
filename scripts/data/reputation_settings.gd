class_name ReputationSettings
extends Resource
## 소문 규칙. data/reputation_settings.tres 하나만 만든다.
## 점심 장사에서 한 일만큼 소문이 쌓이고, 소문이 쌓이면 가게 단계(ShopLevel)가 오른다.

## 한 일마다 쌓이는 소문
## 대접 한 번 (예전 "완벽" 소문 1을 합친 값)
@export var serve_points: int = 2
@export var taste_match_points: int = 1
@export var request_points: int = 2
@export var grandma_taste_points: int = 2
## 오늘 쌓인 소문이 이만큼 넘으면 별 하나씩 (★ / ★★ / ★★★)
@export var star_thresholds: Array[int] = [3, 6, 10]
## 가게 단계들 (낮은 단계부터 차례대로, data/shop_levels/)
@export var shop_levels: Array[ShopLevel] = []


## 소문이 reputation 일 때의 가게 단계 번호 (0 = 첫 단계)
func get_shop_tier(reputation: int) -> int:
	var tier: int = 0
	for i: int in shop_levels.size():
		if reputation >= shop_levels[i].reputation:
			tier = i
	return tier


## 가게 단계. 단계가 하나도 없으면 null.
func get_shop_level(tier: int) -> ShopLevel:
	return shop_levels[clampi(tier, 0, shop_levels.size() - 1)] if not shop_levels.is_empty() else null


func get_shop_name(tier: int) -> String:
	var level: ShopLevel = get_shop_level(tier)
	return level.display_name if level != null else ""


## 이 단계가 되는 소문 (없는 단계면 -1)
func get_threshold(tier: int) -> int:
	return shop_levels[tier].reputation if tier >= 0 and tier < shop_levels.size() else -1


## 다음 가게 단계가 되는 소문. 마지막 단계면 -1.
func get_next_threshold(tier: int) -> int:
	return get_threshold(tier + 1)


## 이 단계까지 생긴 조리도구 전부
func get_tools(tier: int) -> Array[ShopTool]:
	var tools: Array[ShopTool] = []
	for i: int in mini(tier + 1, shop_levels.size()):
		tools.append_array(shop_levels[i].tools)
	return tools


## 오늘 쌓인 소문으로 받는 별 수 (0 ~ star_thresholds 길이)
func get_stars(points: int) -> int:
	var stars: int = 0
	for threshold: int in star_thresholds:
		if points >= threshold:
			stars += 1
	return stars
