class_name SeasonEnding
extends Resource
## 계절 마무리 장면(잔치, 할머니 편지, 다음 계절 예고)에 쓰는 글. data/seasons/ 에 계절마다 하나씩 만든다.

## 잔치를 시작할 때 나오는 설명
@export_multiline var feast_intro_text: String = ""
## 레시피 노트를 다 모았다고 알려 주는 글
@export var notes_complete_text: String = ""
## 할머니 편지 제목과 내용
@export var letter_title: String = ""
@export_multiline var letter_text: String = ""
## 마지막에 나오는 다음 계절 예고
@export_multiline var next_season_teaser: String = ""
## 마지막 버튼 글자
@export var finish_button_text: String = "타이틀로"
