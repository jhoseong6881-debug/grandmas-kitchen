class_name RegularSettings
extends Resource
## 단골도 규칙. data/regular_settings.tres 하나만 만든다.
## 손님을 대접할 때마다 단골도가 쌓이고, 정해 둔 점수를 넘으면 단골 단계가 오른다.

## 단골 단계 이름과 그 단계가 되는 단골도. 두 목록의 길이를 같게, 점수는 작은 것부터 쓴다.
@export var tier_names: Array[String] = ["낯선 손님", "이웃", "단골", "식구"]
@export var tier_thresholds: Array[int] = [0, 4, 10, 20]
## 대접할 때마다 오르는 단골도
@export var serve_points: int = 1
## 입맛에 맞는 고명을 올렸을 때 더 오르는 단골도
@export var taste_match_points: int = 2
## 할머니 손맛을 냈을 때 더 오르는 단골도
@export var grandma_taste_points: int = 1
## 손님이 주문할 때 오늘의 부탁을 덧붙일 확률 (0 ~ 1)
@export_range(0.0, 1.0) var request_chance: float = 0.4
## 이 날부터 손님이 부탁을 한다 (첫날은 게임에 익숙해지도록 부탁 없이)
@export var request_start_day: int = 2
## 부탁을 들어줬을 때 더 오르는 단골도와 더 받는 밥값
@export var request_points: int = 2
@export var request_payment_bonus: int = 1
## 단골의 약속 주문: 저녁 평상에서 첫 손님이 "내일 점심에 ○○ 먹으러 와도 돼요?" 하고 물을 확률 (0 ~ 1)과
## 물어볼 수 있는 단골 단계 (1 = 이웃부터). 약속을 지키면 더 오르는 단골도와 더 받는 밥값.
@export_range(0.0, 1.0) var promise_chance: float = 0.35
@export var promise_min_tier: int = 1
@export var promise_points: int = 2
@export var promise_payment_bonus: int = 1
## 약속을 물을 때 주인공이 고르는 대답 (받기, 거절). 거절해도 벌은 없다.
@export var promise_replies: Array[String] = ["좋아요, 준비해 둘게요", "내일은 어려울 것 같아요"]
## 단계마다 밥값에 더해 주는 덤 (첫 번째 밥값 재료에 더한다). 길이는 tier_names 와 같게.
@export var tier_payment_bonus: Array[int] = [0, 1, 1, 2]


func get_payment_bonus(tier: int) -> int:
	return tier_payment_bonus[tier] if tier >= 0 and tier < tier_payment_bonus.size() else 0


## 단골도가 affection 일 때의 단계 (0 = 첫 단계)
func get_tier(affection: int) -> int:
	var tier: int = 0
	for i: int in tier_thresholds.size():
		if affection >= tier_thresholds[i]:
			tier = i
	return tier


func get_tier_name(tier: int) -> String:
	return tier_names[clampi(tier, 0, tier_names.size() - 1)] if not tier_names.is_empty() else ""
