class_name SeasonEnding
extends Resource
## 계절 마무리 장면(잔치, 할머니 편지, 다음 계절 예고)에 쓰는 글. data/seasons/ 에 계절마다 하나씩 만든다.
## 계절은 last_day 날 저녁에 잔치로 끝난다. 그 계절 노트를 다 못 모아도 끝나고, 남은 노트는 돌아오는 같은 계절에 이어서 받는다.

## 어느 계절의 마무리인지
@export var season: Season.Id = Season.Id.SPRING
## 이 날 저녁(점심 장사가 끝난 뒤)에 평상 대신 잔치가 열리고 계절이 끝난다
@export var last_day: int = 15
## 잔치 준비 (장보기 목록, 잔칫상 단계). 비워 두면 준비 없이 feast_intro_text 로 잔치를 연다.
@export var feast_prep: FeastPrep

## 잔치를 시작할 때 나오는 설명
@export_multiline var feast_intro_text: String = ""
## 노트 카드 제목 (이번 계절에 되찾은 레시피 목록 위)
@export var notes_title_text: String = ""
## 노트 카드 맨 아래 한 줄: 못 모은 노트가 있을 때 (%d = 남은 장 수) / 다 모았을 때
@export var notes_hidden_format: String = ""
@export var notes_all_found_text: String = ""
## 할머니 편지를 이 잔치에서 보여 줄지. 편지는 사계절 노트를 다 모았을 때 읽게 하려고 봄에는 끈다.
@export var show_letter: bool = false
## 할머니 편지 제목과 내용
@export var letter_title: String = ""
@export_multiline var letter_text: String = ""
## 잔치가 끝난 뒤 다음 계절 예고 전에 나오는 마무리 한 줄 (주인공 이야기). 비워 두면 건너뛴다.
@export_multiline var closing_text: String = ""
## 마지막에 나오는 다음 계절 예고
@export_multiline var next_season_teaser: String = ""
## 마지막 버튼 글자
@export var finish_button_text: String = "처음 화면으로"

@export_group("데모 끝")
## 켜면 이 계절 잔치에서 데모가 끝난다: 다음 계절 예고 뒤 고마움 인사를 보여 주고, 다음 계절로 넘어가지 않고
## "봄 완료"로 저장한 뒤 처음 화면으로 돌아간다. 다음 계절을 다 만들면 끈다 (그러면 지금처럼 다음 계절 1일째로 이어진다).
@export var is_demo_end: bool = false
## 데모 끝 인사 (다음 계절 예고 다음 화면)
@export_multiline var demo_end_text: String = ""
## 데모 끝 인사 화면의 버튼 글자
@export var demo_end_button_text: String = "처음 화면으로"
