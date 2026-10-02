class_name ReputationSettings
extends Resource
## 소문 규칙. data/reputation_settings.tres 하나만 만든다.
## 점심 장사에서 한 일만큼 소문이 쌓이고, 소문이 쌓이면 가게 이름(단계)이 바뀐다.

## 한 일마다 쌓이는 소문
@export var serve_points: int = 1
@export var perfect_points: int = 1
@export var taste_match_points: int = 1
@export var request_points: int = 2
@export var grandma_taste_points: int = 2
## 오늘 쌓인 소문이 이만큼 넘으면 별 하나씩 (★ / ★★ / ★★★)
@export var star_thresholds: Array[int] = [3, 6, 10]
## 가게 이름과 그 이름이 되는 소문. 두 목록의 길이를 같게, 점수는 작은 것부터 쓴다.
@export var shop_names: Array[String] = ["작은 밥집", "동네 밥집", "숲속 맛집", "소문난 할매식당"]
@export var shop_thresholds: Array[int] = [0, 20, 50, 100]


## 소문이 reputation 일 때의 가게 단계 (0 = 첫 단계)
func get_shop_tier(reputation: int) -> int:
	var tier: int = 0
	for i: int in shop_thresholds.size():
		if reputation >= shop_thresholds[i]:
			tier = i
	return tier


func get_shop_name(tier: int) -> String:
	return shop_names[clampi(tier, 0, shop_names.size() - 1)] if not shop_names.is_empty() else ""


## 다음 가게 단계가 되는 소문. 마지막 단계면 -1.
func get_next_threshold(tier: int) -> int:
	return shop_thresholds[tier + 1] if tier + 1 < shop_thresholds.size() else -1


## 오늘 쌓인 소문으로 받는 별 수 (0 ~ star_thresholds 길이)
func get_stars(points: int) -> int:
	var stars: int = 0
	for threshold: int in star_thresholds:
		if points >= threshold:
			stars += 1
	return stars
