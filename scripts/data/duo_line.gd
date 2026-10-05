class_name DuoLine
extends Resource
## 손님끼리 대화(GuestDuoTalk)의 한 줄.

## 말하는 손님 id (예: bear)
@export var speaker: StringName = &""
## 이 말을 할 때의 표정 (happy, surprised, sad. 비워 두면 기본)
@export var expression: StringName = &""
## 하는 말. {name} 은 주인공 이름.
@export_multiline var text: String = ""
