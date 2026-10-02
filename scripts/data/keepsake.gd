class_name Keepsake
extends Resource
## 손님이 식구가 되면 건네주는 할머니의 기념품. data/keepsakes/ 에 .tres 파일로 하나씩 만든다.
## 지금은 손님 수첩에 모이기만 하고, 나중에 가게 꾸미기에서 가게에 건다.

## 세이브 파일에 저장되는 고유 이름표. 영어 소문자로 짓고 한 번 정하면 바꾸지 않는다. (예: grandma_handkerchief)
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## 기념품 그림. 비워 두면 그림 없이 이름만 보인다.
@export var icon: Texture2D
