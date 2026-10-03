class_name GardenPlace
extends Resource
## 아침에 둘러보는 밭 한 곳 (예: 당근 텃밭, 버섯 원목). data/places/ 에 .tres 파일로 하나씩 만든다.
## 칸마다 crops 중 하나를 골라 심을 수 있다.

## 세이브 파일에 저장되는 고유 이름표. 영어 소문자로 짓고 한 번 정하면 바꾸지 않는다. (예: carrot_field)
@export var id: StringName = &""
## 화면에 보이는 이름 (예: 당근 텃밭)
@export var display_name: String = ""
## 칸 하나를 부르는 이름 (예: 밭, 원목). 빈 칸에 "빈 밭"처럼 쓴다.
@export var plot_name: String = "밭"
## 칸 아래쪽에 그리는 땅 색 (흙, 원목). 그림이 생기기 전 임시.
@export var ground_color: Color = Color(0.42, 0.28, 0.17)
## 칸 수
@export var plot_count: int = 2
## 이곳에 심을 수 있는 작물
@export var crops: Array[Crop] = []
## 새 게임을 시작할 때 칸마다 다 자란 채로 심겨 있는 작물. 비워 두면 빈 칸으로 시작한다.
@export var starting_crop: Crop
## 이 재료를 처음 얻으면 갈 수 있게 된다 (그전에는 가는 버튼이 숨어 있다). 비워 두면 처음부터 열려 있다.
@export var unlock_ingredient: Ingredient
## 열린 뒤 처음 텃밭에 오면 보여 주는 글
@export_multiline var unlocked_text: String = ""
