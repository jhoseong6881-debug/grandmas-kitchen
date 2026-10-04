class_name EveningTalk
extends Resource
## 저녁 평상 대화 하나. 손님이 이야기를 하면 대답을 하나 고르고, 고른 대답에 따라 손님이 반응한다.
## 손님 데이터(AnimalGuest)의 evening_talks 안에 대화마다 하나씩 넣는다.

## 손님이 먼저 하는 이야기
@export_multiline var line: String = ""
## 이야기할 때의 표정 (happy, surprised, sad. 비워 두면 기본). 대답 뒤 반응에는 reaction_expressions.
@export var expression: StringName = &""
## 고를 수 있는 대답 (2~3개). 비워 두면 대답 없이 이야기만 한다.
@export var replies: Array[String] = []
## 대답마다 손님의 반응. replies 와 같은 순서로 하나씩 넣는다.
@export_multiline var reactions: Array[String] = []
## 반응마다 표정 (reactions 와 같은 순서). 비워 두면 기본 표정.
@export var reaction_expressions: Array[StringName] = []
