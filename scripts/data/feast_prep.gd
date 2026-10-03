class_name FeastPrep
extends Resource
## 계절 잔치 준비: announce_day 저녁 평상에서 손님(announcer)이 장보기 목록을 주고,
## 다음 날 아침부터 텃밭의 잔치 바구니에 재료를 모은다. 모은 만큼 잔칫상 단계(tiers)가 오른다.
## SeasonEnding 의 feast_prep 에 넣는다. 글과 개수는 모두 여기서 바꾼다.

## 장보기 목록을 알려 주는 날 (그날 저녁 평상)과 알려 주는 손님 id
@export var announce_day: int = 10
@export var announcer_id: StringName = &"hen"
## 알려 줄 때 하는 말 (한 줄씩 차례로)
@export_multiline var announce_lines: Array[String] = []
## 알려 준 뒤 아래에 나오는 글
@export_multiline var announced_status_text: String = ""
## 장보기 목록
@export var items: Array[FeastItem] = []
## 잔치 바구니에서 한 번 누를 때 내는 최대 개수
@export var give_step: int = 5
## 잔칫상 단계 (min_ratio 가 낮은 것부터)
@export var tiers: Array[FeastTier] = []
## 다 모았을 때만 잔치에서 나오는 특별한 장면 글
@export_multiline var full_special_text: String = ""


func get_total() -> int:
	var total: int = 0
	for item: FeastItem in items:
		total += item.amount
	return total


## 모은 개수에 맞는 잔칫상 단계 (단계가 없으면 null)
func get_tier(delivered_total: int) -> FeastTier:
	var total: int = get_total()
	var ratio: float = float(delivered_total) / total if total > 0 else 1.0
	var result: FeastTier = null
	for tier: FeastTier in tiers:
		if ratio >= tier.min_ratio:
			result = tier
	return result
