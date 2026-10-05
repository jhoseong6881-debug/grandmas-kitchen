class_name SeasonData
extends Resource
## 계절 하나에 필요한 것을 모은 데이터. data/seasons/ 에 계절마다 하나씩 만든다 (spring.tres, summer.tres …).
## 게임은 지금 계절(GameState.current_season)의 이 파일에서 손님, 날마다 바뀌는 곡, 비 오는 날, 장터, 계절 마무리를 꺼내 쓴다.
## 계절은 ending.last_day 날 저녁에 끝나고, next_season 데이터가 있으면 intro_story 를 보여 준 뒤 그 계절 1일째로 넘어간다.

@export var id: Season.Id = Season.Id.SPRING
## 화면에 쓰는 이름 (예: "봄", "여름")
@export var display_name: String = ""
## 계절 마지막 날 행사 이름 (예: "봄 잔치", "낚시 대회"). 목표판에 "○○까지 N일" 로 나온다.
@export var ending_name: String = ""
## 이 계절에 점심을 먹으러 오는 손님
@export var guests: Array[AnimalGuest] = []
## 날마다 바뀌는 배경음악 (텃밭, 부엌, 평상)
@export var daily_music: DailyMusic
## 비 오는 날 설정. 비워 두면 이 계절에는 비가 오지 않는다.
@export var rain: RainSettings
## 숲속 장터 설정. 비워 두면 이 계절에는 장터가 열리지 않는다.
@export var market: MarketSettings
## 특별한 점심 날 (예: 8일째 소풍 도시락 날). 그날은 점심 방식이 바뀐다.
@export var special_lunches: Array[SpecialLunch] = []
## 계절 마무리 (마지막 날, 잔치 준비, 노트 카드, 예고). 비워 두면 이 계절은 끝나지 않는다 (만드는 중인 계절).
@export var ending: SeasonEnding
## 계절이 시작될 때 보여 주는 짧은 장면 (프롤로그 화면으로 보여 준다). 비워 두면 바로 1일째 아침.
@export var intro_story: Story
## 이 계절이 끝나면 넘어갈 계절. 그 계절 데이터가 없으면 지금처럼 타이틀로 돌아간다.
@export var next_season: Season.Id = Season.Id.SUMMER
