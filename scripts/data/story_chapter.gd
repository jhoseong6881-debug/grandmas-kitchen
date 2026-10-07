class_name StoryChapter
extends Resource
## 이야기 장면의 한 장 (예: "1장. 회색 도시"). Story 안에 차례대로 넣는다.
##
## lines 쓰는 법:
##   - 한 칸 = 한 번 눌러서 넘기는 한 줄
##   - "토끼: 안녕" 처럼 쓰면 "토끼"가 말하는 사람으로 따로 보인다. 없으면 설명 글.
##   - "#이름" 한 줄만 쓰면 그 자리에서 이름 입력 칸이 나온다.
##   - {name} 은 주인공 이름으로 바뀐다.
## is_letter 를 켜면 편지지 위에 손글씨로, 누를 때마다 문단이 아래에 이어 붙는다.

## 화면 위에 보이는 장 제목
@export var title: String = ""
## 배경 색 (그림이 아직 없을 때)
@export var background_color: Color = Color(0.2, 0.2, 0.25)
## 배경 그림. 비워 두면 background_color 만 보인다.
@export var background_image: Texture2D
## 편지 장면인지
@export var is_letter: bool = false
## 이 장 동안 깔리는 소리 (data/sounds/ 의 id, 예: 1장 지하철 &"subway"). 비워 두면 없다.
@export var ambient_sound: StringName = &""
@export_multiline var lines: Array[String] = []
