class_name TutorialTip
extends Resource
## 처음 하는 사람에게 한 번만 보여 주는 안내 한 묶음. 그 화면에 처음 왔을 때 안내 캐릭터(TutorialBook.guide)가 말한다.
## 어느 화면에서 나오는지는 id 로 정해져 있다 (garden, menu, garnish, result, porch).

## 안내 이름. 화면 쪽 코드가 이 이름으로 찾는다.
@export var id: StringName
## 줄마다 따로 정하지 않은 줄의 표정 (AnimalGuest.EXPRESSION_*: 비우면 기본, happy, surprised, sad)
@export var expression: StringName = &""
## 한 번에 한 줄씩 보여 준다. {name} 은 주인공 이름으로 바뀐다.
@export_multiline var lines: Array[String] = []
## 줄마다 표정 (lines 와 같은 차례). 모자라거나 비어 있으면 expression 을 쓴다.
@export var line_expressions: Array[StringName] = []


func get_line_expression(index: int) -> StringName:
	return line_expressions[index] if index < line_expressions.size() else expression
