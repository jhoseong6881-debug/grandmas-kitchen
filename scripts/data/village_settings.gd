class_name VillageSettings
extends Resource
## 아침 마을 길 설정: 언제 열리는지, 선물 개수와 단골도, 안내 글.
## data/village_settings.tres 하나만 만든다. 텃밭의 마을 길 버튼과 마을 길 장면(village.gd)이 읽는다.
## 손님마다 집 이름·인사·이야기·좋아하는 선물은 손님 데이터(AnimalGuest 의 "마을 길 집")에 있다.

## 이 날부터 마을 길로 갈 수 있다 (첫 봄에만 안내 한 줄)
@export var open_day: int = 2
## 하루에 들를 수 있는 집 수
@export var visits_per_day: int = 1
## 선물로 두고 오는 재료 개수
@export var gift_amount: int = 1
## 선물을 주면 오르는 단골도 / 좋아하는 선물을 주면 오르는 단골도
@export var gift_points: int = 1
@export var favorite_gift_points: int = 2
## 마을 길이 열린 날 텃밭 아래 글에 한 줄
@export_multiline var unlocked_text: String = ""
## 마을 길에 처음 나왔을 때 / 오늘 이미 들렀을 때 아래 글
@export_multiline var choose_text: String = ""
@export_multiline var visited_text: String = ""
## 아직 밥집에서 못 만난 손님의 집 (이름 대신)
@export var unknown_home_text: String = "?"
## 선물을 고를 때 아래 글, 선물 없이 이야기만 하고 갈 때의 대답
@export_multiline var gift_prompt_text: String = ""
@export var no_gift_reply: String = ""
## 선물을 받은 손님이 따로 할 말이 없을 때
@export_multiline var default_gift_thanks_line: String = ""


func is_open(day: int) -> bool:
	return day >= open_day
