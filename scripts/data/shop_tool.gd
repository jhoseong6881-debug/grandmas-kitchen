class_name ShopTool
extends Resource
## 가게가 커지면 생기는 조리도구 하나 (예: 넓은 도마). data/shop_tools/ 에 .tres 파일로 하나씩 만든다.
## 정해 둔 미니게임을 쉽게 만든다: 맞는 칸을 넓히거나(window_scale), 빨리 끝나게(duration_scale) 한다.

@export var id: StringName = &""
@export var display_name: String = ""
## 미니게임 화면에 보이는 한 줄 (예: "판정 칸이 넓어졌어요")
@export var effect_text: String = ""
## 이 도구가 쓰이는 미니게임 종류
@export var minigame_types: Array[Recipe.MinigameType] = []
## 맞는 칸(하얀 칸, 금색 칸, 금색 띠)을 이만큼 넓힌다. 1 = 그대로.
@export var window_scale: float = 1.0
## 끝나기까지 걸리는 시간이나 횟수를 이만큼 줄인다. 1 = 그대로, 0.7 = 30% 빨리.
@export var duration_scale: float = 1.0
