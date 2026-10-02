class_name RegularReward
extends Resource
## 손님의 단골 단계가 올랐을 때 받는 보상 하나. AnimalGuest 의 regular_rewards 에 단계 순서대로 넣는다
## (첫 칸 = 이웃, 둘째 = 단골, 셋째 = 식구). 단계가 오른 뒤 그 손님이 저녁에 오면 새 이야기를 나누고 선물을 건넨다.
## 새 이야기는 그다음부터 그 손님의 평소 저녁 대화에도 섞인다.

## 이 단계에서 새로 열리는 저녁 이야기
@export var talk: EveningTalk
## 선물을 건넬 때 손님이 하는 말 ({name} = 주인공 이름)
@export_multiline var gift_line: String = ""
## 선물 재료와 개수 (없으면 비워 둔다)
@export var gift_ingredient: Ingredient
@export var gift_amount: int = 0
## 칸을 하나 늘려 주는 밭 id (예: carrot_field). 없으면 비워 둔다.
@export var extra_plot_place_id: StringName = &""
## 기념품 (없으면 비워 둔다)
@export var keepsake: Keepsake
