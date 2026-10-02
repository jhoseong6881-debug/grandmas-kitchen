class_name FloatingText
extends RefCounted
## 버튼 위로 글자가 떠오르며 사라지게 하는 도우미. (예: 거둘 때 "+1 당근")


## host 위에 글을 만들어 from 버튼 가운데 위에서 rise 픽셀 떠오르며 duration 초 동안 사라지게 한다.
static func pop(host: Control, text: String, from: Control, rise: float, duration: float,
		font_size: int, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(label)
	label.position = from.global_position - host.global_position \
			+ Vector2(from.size.x / 2.0 - label.size.x / 2.0, 0.0)
	var tween: Tween = host.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - rise, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(label.queue_free)
