class_name FeastPrepPanel
extends Control
## "봄 잔치 바구니" 창. 텃밭에서 연다. 장보기 목록(FeastPrep)의 재료마다 버튼이 있고,
## 누르면 그 재료를 give_step 개까지 잔치 바구니에 낸다 (가진 만큼, 목록에 남은 만큼만).
## 위에는 모은 개수와 지금 잔칫상 단계를 보여 준다. 닫기 버튼이나 B 버튼(ui_cancel)으로 닫는다.

signal closed

const TITLE_TEXT: String = "봄 잔치 장보기"
const PROGRESS_FORMAT: String = "모은 재료 %d / %d   ·   %s"
const ITEM_FORMAT: String = "%s   %d / %d      (가진 것 %d)   → %d개 내기"
const ITEM_DONE_FORMAT: String = "%s   %d / %d      다 모았어요!"
const ITEM_NONE_FORMAT: String = "%s   %d / %d      (가진 것 없음)"
const GIVE_POP_FORMAT: String = "-%d %s"
const GIVE_SOUND: StringName = &"receive"
const NONE_SOUND: StringName = &"miss"

@export var item_button_height: float = 72.0
@export var item_font_size: int = 36
@export var give_pop_rise: float = 70.0
@export var give_pop_duration: float = 0.7
@export var give_pop_font_size: int = 36
@export var give_pop_color: Color = Color(1, 0.84, 0.25)

var _prep: FeastPrep
var _item_buttons: Array[Button] = []
var _previous_focus: Control

@onready var _title_label: Label = %TitleLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _item_list: VBoxContainer = %ItemList
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_close_button.pressed.connect(close)
	_title_label.text = TITLE_TEXT
	hide()


func open(prep: FeastPrep) -> void:
	_prep = prep
	_previous_focus = get_viewport().gui_get_focus_owner()
	for child: Node in _item_list.get_children():
		child.queue_free()
	_item_buttons.clear()
	for i: int in prep.items.size():
		var button: Button = Button.new()
		button.custom_minimum_size.y = item_button_height
		button.add_theme_font_size_override("font_size", item_font_size)
		button.pressed.connect(_on_item_pressed.bind(i))
		_item_list.add_child(button)
		_item_buttons.append(button)
	_keep_focus_inside()
	_refresh()
	show()
	if not _item_buttons.is_empty():
		_item_buttons[0].grab_focus()
	else:
		_close_button.grab_focus()


func close() -> void:
	hide()
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_item_pressed(index: int) -> void:
	var item: FeastItem = _prep.items[index]
	var given: int = GameState.deliver_to_feast(item, _prep.give_step)
	if given <= 0:
		Sound.play(NONE_SOUND)
		return
	Sound.play(GIVE_SOUND)
	FloatingText.pop(self, GIVE_POP_FORMAT % [given, item.ingredient.display_name], _item_buttons[index],
			give_pop_rise, give_pop_duration, give_pop_font_size, give_pop_color)
	_refresh()


func _refresh() -> void:
	var delivered_total: int = GameState.get_feast_delivered_total()
	var tier: FeastTier = _prep.get_tier(delivered_total)
	_progress_label.text = PROGRESS_FORMAT % [delivered_total, _prep.get_total(), tier.display_name if tier != null else ""]
	for i: int in _prep.items.size():
		var item: FeastItem = _prep.items[i]
		var name_text: String = item.ingredient.display_name
		var delivered: int = GameState.get_feast_delivered(item.ingredient.id)
		var have: int = GameState.get_ingredient_count(item.ingredient.id)
		var next_give: int = mini(mini(_prep.give_step, item.amount - delivered), have)
		if delivered >= item.amount:
			_item_buttons[i].text = ITEM_DONE_FORMAT % [name_text, delivered, item.amount]
		elif have <= 0:
			_item_buttons[i].text = ITEM_NONE_FORMAT % [name_text, delivered, item.amount]
		else:
			_item_buttons[i].text = ITEM_FORMAT % [name_text, delivered, item.amount, have, next_give]


## 위아래로 재료 버튼 → 닫기 버튼 → 다시 첫 재료로 돈다 (게임패드). 뒤쪽 텃밭 버튼으로 빠지지 않게.
func _keep_focus_inside() -> void:
	var order: Array[Button] = _item_buttons.duplicate()
	order.append(_close_button)
	for i: int in order.size():
		var button: Button = order[i]
		button.focus_neighbor_top = button.get_path_to(order[i - 1])
		button.focus_neighbor_bottom = button.get_path_to(order[(i + 1) % order.size()])
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
