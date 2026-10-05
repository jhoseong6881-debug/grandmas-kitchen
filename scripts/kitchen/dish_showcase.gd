class_name DishShowcase
extends Control
## 요리 완성 장면. 요리 미니게임이 다 끝나면 접시에 담긴 완성 요리가 가운데 톡 튀어나오며 "완성~!".
## 완벽하게 했으면 "★ 완벽!", 할머니 비법대로 했으면 "♥ 할머니 손맛" 한 줄이 붙는다.
## 잠깐 보여 준 뒤 저절로 닫히고, 누르면 바로 닫힌다. show_dish 를 await 하면 닫힐 때까지 기다린다.

signal closed

const DONE_SOUND: StringName = &"done"

@export var done_text: String = "완성~!"
@export var perfect_text: String = "★ 완벽!"
@export var grandma_text: String = "♥ 할머니 손맛"
## 완성 요리 그림을 키우는 배수 (원본 64×64)
@export var dish_scale: int = 4
## 튀어나오는 크기 변화와 시간(초), 보여 주는 시간(초)
@export var pop_start_scale: float = 0.4
@export var pop_overshoot_scale: float = 1.12
@export var pop_duration: float = 0.22
@export var settle_duration: float = 0.12
@export var hold_duration: float = 1.6
## 접시가 위아래로 살짝 둥실거리는 높이(픽셀)와 한 번 오르내리는 시간(초)
@export var bob_height: float = 8.0
@export var bob_duration: float = 1.2

var _is_open: bool = false
var _bob_tween: Tween

@onready var _dish_box: Control = %DishBox
@onready var _dish_image: TextureRect = %DishImage
@onready var _done_label: Label = %DoneLabel
@onready var _name_label: Label = %NameLabel
@onready var _badge_label: Label = %BadgeLabel


func _ready() -> void:
	hide()


func show_dish(recipe: Recipe, is_perfect: bool, is_grandma_taste: bool) -> void:
	_dish_image.texture = DishArt.get_texture(recipe, dish_scale)
	_done_label.text = done_text
	_name_label.text = recipe.display_name
	_badge_label.text = grandma_text if is_grandma_taste else (perfect_text if is_perfect else "")
	_is_open = true
	show()
	grab_focus()
	Sound.play(DONE_SOUND)
	_dish_box.pivot_offset = _dish_box.size / 2.0
	_dish_box.scale = Vector2.ONE * pop_start_scale
	var tween: Tween = create_tween()
	tween.tween_property(_dish_box, "scale", Vector2.ONE * pop_overshoot_scale, pop_duration) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_dish_box, "scale", Vector2.ONE, settle_duration)
	_bob()
	get_tree().create_timer(hold_duration, false).timeout.connect(_close)
	await closed


func _close() -> void:
	if not _is_open:
		return
	_is_open = false
	if _bob_tween != null:
		_bob_tween.kill()
	hide()
	closed.emit()


func _bob() -> void:
	var home_y: float = _dish_image.position.y
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_dish_image, "position:y", home_y - bob_height, bob_duration / 2.0).set_trans(Tween.TRANS_SINE)
	_bob_tween.tween_property(_dish_image, "position:y", home_y, bob_duration / 2.0).set_trans(Tween.TRANS_SINE)


func _gui_input(event: InputEvent) -> void:
	var is_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if _is_open and (is_click or event.is_action_pressed("ui_accept")):
		accept_event()
		_close()
