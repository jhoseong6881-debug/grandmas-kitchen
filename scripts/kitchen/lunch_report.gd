class_name LunchReport
extends RefCounted
## 오늘 점심 장사 기록. 부엌이 대접할 때마다 채우고, 장사가 끝나면 장사 결과판(ResultBoard)이 보여 준다.

## 대접한 손님 이름 (온 순서대로)
var guest_names: Array[String] = []
## 받은 밥값: 재료 id → 개수
var payment: Dictionary[StringName, int] = {}
var perfect_count: int = 0
var grandma_taste_count: int = 0
var request_count: int = 0
var request_met_count: int = 0
var taste_match_count: int = 0
## 손님 이름 → 오늘 오른 단골도
var affection_gains: Dictionary[String, int] = {}
## 오늘 쌓인 소문
var reputation: int = 0


func add_payment(payment_today: Dictionary[StringName, int]) -> void:
	for ingredient_id: StringName in payment_today:
		payment[ingredient_id] = payment.get(ingredient_id, 0) + payment_today[ingredient_id]


func add_affection(guest_name: String, points: int) -> void:
	affection_gains[guest_name] = affection_gains.get(guest_name, 0) + points
