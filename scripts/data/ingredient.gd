class_name Ingredient
extends Resource
## 재료 하나의 정보. data/ingredients/ 에 .tres 파일로 하나씩 만든다.

## 세이브 파일에 저장되는 고유 이름표. 영어 소문자로 짓고 한 번 정하면 바꾸지 않는다. (예: carrot)
@export var id: StringName = &""
## 화면에 보이는 이름 (예: 당근)
@export var display_name: String = ""
## 재료 그림. 비워 두면 임시 도형으로 표시한다.
@export var icon: Texture2D
@export_multiline var description: String = ""
