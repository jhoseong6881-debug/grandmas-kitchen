class_name ShopLevel
extends Resource
## 가게 단계 하나 (예: 동네 밥집). 소문이 reputation 만큼 쌓이면 이 단계가 된다.
## ReputationSettings 의 shop_levels 에 낮은 단계부터 차례대로 넣는다.

@export var display_name: String = ""
## 이 단계가 되는 소문
@export var reputation: int = 0
## 점심 손님 수 = 오늘 메뉴 수 + 1 + extra_guests (최대 max_guests)
@export var extra_guests: int = 0
@export var max_guests: int = 3
## 부엌 벽 기념품 선반 칸 수
@export var keepsake_slots: int = 2
## 가게 앞 간판과 처마 등불을 다는지
@export var has_sign: bool = false
@export var has_lantern: bool = false
## 이 단계가 되면 칸이 늘어나는 밭 (data/places/ 의 id, 비워 두면 안 늘어남)과 늘어나는 칸 수
@export var bonus_plot_place_id: StringName = &""
@export var bonus_plot_count: int = 0
## 이 단계에서 새로 생기는 조리도구 (앞 단계의 도구도 계속 쓴다)
@export var tools: Array[ShopTool] = []
## 단계가 오를 때 장사 결과판에 보여 주는, 새로 생긴 것 (예: "손님 +1 · 간판 · 평상 하나 더")
@export var unlock_text: String = ""
