class_name KitchenDoor
extends Control
## 부엌 뒷벽의 가게 문. 점심 손님이 이 문을 열고 들어왔다가, 다 먹으면 이 문으로 나간다.
## 문짝(Leaf)은 왼쪽 경첩을 축으로 가로로 접히며 열리고, 열린 틈으로 바깥(Outside)이 보인다.
## 그림이 오기 전까지 단색 사각형으로 그린다.

## 문을 열 때 나는 소리 (data/sounds/ 의 id)
const OPEN_SOUND: StringName = &"guest_arrive"

## 문이 열리고 닫히는 시간(초), 열렸을 때 문짝이 남는 폭(비율. 0.15 = 경첩 쪽에 15%만 보인다)
@export var open_duration: float = 0.25
@export var close_duration: float = 0.3
@export var open_leaf_scale: float = 0.15

@onready var _leaf: Control = %Leaf


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leaf.pivot_offset = Vector2(0.0, _leaf.size.y / 2.0)


## 문을 연다. 다 열릴 때까지 기다리려면 await.
func open() -> void:
	Sound.play(OPEN_SOUND)
	var tween: Tween = create_tween()
	tween.tween_property(_leaf, "scale:x", open_leaf_scale, open_duration).set_trans(Tween.TRANS_SINE)
	await tween.finished


func close() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_leaf, "scale:x", 1.0, close_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

