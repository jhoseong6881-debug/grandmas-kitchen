class_name Wiggle
extends RefCounted
## 누르면 좌우로 부르르 흔들리는 귀여운 움직임. 바구니, 작물 칸 등에 쓴다.
## pivot_offset 을 바닥 가운데(또는 가운데)로 두고 rotation 을 몇 번 오가게 한다.


## control 을 흔든다. from_bottom 이면 바닥 가운데를 축으로 (작물처럼), 아니면 가운데를 축으로.
static func shake(control: Control, angle: float = 0.12, times: int = 3, step_duration: float = 0.06,
		from_bottom: bool = false) -> void:
	control.pivot_offset = Vector2(control.size.x / 2.0, control.size.y if from_bottom else control.size.y / 2.0)
	var tween: Tween = control.create_tween()
	for i: int in times:
		var side: float = 1.0 if i % 2 == 0 else -1.0
		tween.tween_property(control, "rotation", side * angle * (1.0 - float(i) / times), step_duration)
	tween.tween_property(control, "rotation", 0.0, step_duration)
