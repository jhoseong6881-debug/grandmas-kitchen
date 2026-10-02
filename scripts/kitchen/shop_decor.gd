class_name ShopDecor
extends Control
## 부엌 화면의 가게 모습. 가게 단계(ShopLevel)에 따라 간판, 등불, 평상(손님 자리), 기념품 선반이 바뀐다.
## 부엌이 켜질 때 붙이고 refresh() 로 지금 단계에 맞춘다. 그림이 생기면 이 씬의 색 상자만 그림으로 바꾸면 된다.

const SHELF_TITLE: String = "기념품 선반"

@export var bench_size: Vector2 = Vector2(110, 40)
@export var slot_size: Vector2 = Vector2(96, 96)
@export var slot_font_size: int = 12
@export var bench_color: Color = Color(0.55, 0.4, 0.25)
@export var empty_slot_color: Color = Color(1, 1, 1, 0.15)
@export var filled_slot_color: Color = Color(1, 0.92, 0.75)
@export var slot_text_color: Color = Color(0.35, 0.22, 0.12)

@onready var _sign: Control = %Sign
@onready var _sign_label: Label = %SignLabel
@onready var _lanterns: Control = %Lanterns
@onready var _bench_row: HBoxContainer = %BenchRow
@onready var _shelf: Control = %Shelf
@onready var _slot_row: HBoxContainer = %SlotRow


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh()


func refresh() -> void:
	var level: ShopLevel = GameState.get_shop_level()
	if level == null:
		hide()
		return
	_sign.visible = level.has_sign
	_sign_label.text = level.display_name
	_lanterns.visible = level.has_lantern
	_build_benches(level.max_guests)
	_build_shelf(level.keepsake_slots)


## 손님 자리(평상)를 최대 손님 수만큼 놓는다.
func _build_benches(count: int) -> void:
	for child: Node in _bench_row.get_children():
		child.queue_free()
	for i: int in count:
		var bench: ColorRect = ColorRect.new()
		bench.custom_minimum_size = bench_size
		bench.color = bench_color
		bench.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bench_row.add_child(bench)


## 기념품 선반 칸을 만들고, 받은 기념품을 받은 순서대로 놓는다. 칸이 0 이면 선반을 숨긴다.
func _build_shelf(slot_count: int) -> void:
	for child: Node in _slot_row.get_children():
		child.queue_free()
	_shelf.visible = slot_count > 0
	var keepsakes: Array[Keepsake] = []
	for guest: AnimalGuest in GameData.get_all_guests():
		for reward: RegularReward in guest.regular_rewards:
			if reward.keepsake != null and GameState.has_keepsake(reward.keepsake.id):
				keepsakes.append(reward.keepsake)
	keepsakes.sort_custom(func(a: Keepsake, b: Keepsake) -> bool:
		return GameState.keepsake_ids.find(a.id) < GameState.keepsake_ids.find(b.id))
	for i: int in slot_count:
		var keepsake: Keepsake = keepsakes[i] if i < keepsakes.size() else null
		_slot_row.add_child(_make_slot(keepsake))


func _make_slot(keepsake: Keepsake) -> Control:
	var slot: ColorRect = ColorRect.new()
	slot.custom_minimum_size = slot_size
	slot.color = filled_slot_color if keepsake != null else empty_slot_color
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if keepsake == null:
		return slot
	if keepsake.icon != null:
		var icon: TextureRect = TextureRect.new()
		icon.texture = keepsake.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
	else:
		var label: Label = Label.new()
		label.text = keepsake.display_name
		label.add_theme_font_size_override("font_size", slot_font_size)
		label.add_theme_color_override("font_color", slot_text_color)
		label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(label)
	return slot
