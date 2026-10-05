class_name GuestStoryChapter
extends Resource
## 손님 사연의 한 막. 계절 동안 이어지는 짧은 이야기를 막(장면) 몇 개로 나눈다.
## AnimalGuest 의 story_chapters 에 막 순서대로 넣는다. 앞 막을 봤고 open_day 가 되면, 그 손님이 저녁 평상에 올 때 다음 막을 한다.
## 한 번 본 막은 다시 하지 않는다 (평소 이야기는 그대로 돈다).

## 세이브 파일에 저장되는 고유 이름표 (본 막을 다시 보여 주지 않으려고). 예: rabbit_spring_1
@export var id: StringName = &""
## 이 막이 나오는 계절
@export var season: Season.Id = Season.Id.SPRING
## 이 날부터 열린다 (그 계절 몇째 날)
@export var open_day: int = 3
## 차례대로 나누는 대화. 대화마다 "다음"을 누르면 넘어가고, 대답이 있으면 고른 뒤에 넘어간다.
@export var talks: Array[EveningTalk] = []
## 이 막을 본 다음 날 아침, 이웃 바구니에 이 손님이 남기는 쪽지 (비워 두면 평소 쪽지). {name}, {ingredient} 를 쓸 수 있다.
@export_multiline var basket_note: String = ""
