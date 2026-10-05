class_name SpecialLunch
extends Resource
## 계절 후반 점심이 늘 똑같지 않게 하는 "특별한 점심 날" 하나. SeasonData.special_lunches 에 넣는다.
## 그날은 점심 방식 자체가 바뀐다. 전날 밤 "내일은…" 예고와 아침 메뉴판에서 미리 알려 준다.
##
## PICNIC (소풍 도시락 날): 손님이 한 명씩 오는 대신 host 손님이 오늘 손님 모두의 도시락을 한꺼번에 주문한다.
## 도시락마다 그 손님에게 넣을 요리를 내가 고르고 요리한다. 그 손님이 좋아하는 요리면 밥값을 다 받고,
## 도시락이 모두 다른 요리면 "골고루" 덤 소문을 받는다. 도시락을 받은 손님은 저녁 평상에 평소처럼 온다.
## 글에서 {guest} 는 도시락 주인 이름, {particle} 은 그 이름 뒤 "이/가", {names} 는 host 말고 도시락 받을 손님 이름들,
## {count} 는 도시락 수, {name} 은 주인공 이름으로 바뀐다.

enum Kind { PICNIC }

@export var id: StringName
@export var kind: Kind = Kind.PICNIC
## 계절 몇째 날인지
@export var day: int = 8
## 이름 (예: "소풍 도시락 날")
@export var display_name: String = ""
## 주문하러 오는 손님 (오늘 손님 맨 앞에 온다)
@export var host_id: StringName
## 전날 밤 "내일은…" 예고 한 줄
@export var preview_text: String = ""
## 아침 메뉴판 위에 보여 주는 안내
@export_multiline var menu_notice: String = ""
## host 가 들어와서 하는 주문
@export_multiline var intro_line: String = ""
## 도시락 요리 고르는 창 제목
@export var choose_title_format: String = "도시락에 넣을 요리를 골라요"
## 고르는 창에서 그만두기 버튼 대신 쓰는 글 (누르면 손님 수첩을 연다)
@export var notebook_button_text: String = "손님 수첩 보기"
## 도시락을 하나 다 쌌을 때 host 가 하는 말: 그 손님이 좋아하는 요리일 때 / 아닐 때
@export_multiline var favorite_line: String = ""
@export_multiline var other_line: String = ""
## host 자기 도시락일 때 (좋아하는 요리 / 아닐 때)
@export_multiline var self_favorite_line: String = ""
@export_multiline var self_other_line: String = ""
## 재료가 모자라 그 손님 도시락을 못 쌀 때
@export_multiline var skipped_line: String = ""
## 다 싸고 나서 host 의 마지막 말, 모두 다른 요리로 쌌을 때 덧붙이는 말과 덤 소문
@export_multiline var done_line: String = ""
@export_multiline var variety_line: String = ""
@export var variety_reputation: int = 3
## 위로 떠오르는 글
@export var variety_pop_text: String = "♪ 골고루 담았어요!"
