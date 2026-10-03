class_name FeastTier
extends Resource
## 잔칫상 단계 하나 (예: 푸짐한 잔칫상). 장보기 목록을 min_ratio 만큼 모으면 이 단계가 된다.
## FeastPrep 의 tiers 에 낮은 단계부터 차례대로 넣는다.

@export var display_name: String = ""
## 이 단계가 되는 모은 비율 (0 ~ 1). 첫 단계는 0, 다 모은 단계는 1.
@export_range(0.0, 1.0, 0.05) var min_ratio: float = 0.0
## 잔치를 시작할 때 나오는 글 (SeasonEnding 의 feast_intro_text 대신)
@export_multiline var intro_text: String = ""
## 잔치에서 알려 준 손님(announcer)이 잔칫상을 보고 하는 말
@export_multiline var announcer_line: String = ""
