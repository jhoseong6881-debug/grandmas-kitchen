class_name MenuBoard
extends Control
## 오늘의 메뉴판. 아침에 부엌으로 가기 전에 열려서, 되찾은 레시피 중 오늘 낼 요리를 메뉴 칸 수만큼 고른다.
## 메뉴 칸 수는 되찾은 레시피가 늘수록 는다 (GameState.get_menu_slots, data/menu_settings.tres).
## 요리마다 필요한 재료(아이콘 ×개수, 모자라면 "재료 부족")와, 위쪽에 오늘 점심에 올 손님(GameState.get_todays_guest_ids)을 보여 준다.
## 누가 무엇을 좋아하는지는 보여 주지 않는다 (손님 수첩에서 찾아보게).
## 다 고르면 confirmed 시그널로 고른 레시피 id 들을 알려 준다. 돌아가기를 누르면 cancelled.

signal confirmed(recipe_ids: Array[StringName])
signal cancelled

const SELECTED_FORMAT: String = "● %s"
const UNSELECTED_FORMAT: String = "○ %s"
const COUNT_FORMAT: String = "%d / %d"
const LIMIT_TEXT: String = "메뉴는 %d개까지 고를 수 있어요."
const PICK_ONE_TEXT: String = "메뉴를 하나 이상 골라 주세요."
const SHORT_BLOCK_FORMAT: String = "재료가 부족해요: %s"
## 재료가 모자라 만들 수 있는 요리가 하나도 없는 날: 메뉴 없이도 장사를 열 수 있다 (손님은 아쉬워하며 돌아간다). 아침에 갇히지 않게.
const NOTHING_TO_COOK_TEXT: String = "오늘은 만들 수 있는 요리가 없어요.\n그래도 문을 열면 손님께 사정을 말해요."
const NAME_SEPARATOR: String = ", "
const SHORT_TEXT: String = "  재료 부족"
const INGREDIENT_FORMAT: String = "×%d  "
const PROMISE_FORMAT: String = "★ %s%s 약속"
## 아직 못 읽은 번진 할머니 노트가 있는 요리 줄에 붙는 글 (만들면 노트 퍼즐이 나온다)
const NOTE_PUZZLE_TAG: String = "번진 할머니 노트"
## 번진 노트 요리를 둘 이상 골랐을 때 그 줄들에 붙는 글 (퍼즐은 점심 한 번에 한 장, 먼저 만드는 요리에서)
const NOTE_PUZZLE_ONE_PER_LUNCH_TAG: String = "번진 노트 · 점심에 한 장"
## 장사를 시작할 수 없을 때(재료 부족, 아무것도 안 고름) 나는 작고 부드러운 소리 (장터의 "재료 부족"과 같은 소리)
const BLOCKED_SOUND: StringName = &"miss"
const INVENTORY_ITEM_FORMAT: String = "%s ×%d"
const INVENTORY_EMPTY_TEXT: String = "없어요"
const TODAY_GUESTS_TITLE: String = "오늘 손님"
## 약속한 손님 이름 앞에 붙는 표시, 아직 만나지 못한 손님의 이름 자리
const PROMISE_MARK: String = "★"
const UNMET_GUEST_TEXT: String = "?"

@export var row_font_size: int = 36
@export var detail_font_size: int = 24
@export var dish_button_width: float = 480.0
@export var ingredients_width: float = 360.0
@export var row_height: float = 60.0
@export var ingredient_icon_size: int = 32
## 오늘 손님 줄의 얼굴 아이콘 크기(픽셀, 원본 16×16 의 배수)와 글자 색
@export var guest_icon_size: int = 48
@export var guest_text_color: Color = Color(0.97, 0.95, 0.88)
## 왼쪽 아래 가진 재료 줄에 한 줄로 놓는 재료 수
@export var inventory_items_per_line: int = 3
@export var inventory_text_color: Color = Color(0.92, 0.9, 0.82)
@export var short_color: Color = Color(1, 0.55, 0.45)
## 고른 요리의 글자 색
@export var selected_color: Color = Color(1, 0.84, 0.25)
## 번진 할머니 노트 글 색 (약속 표시보다 차분하게)
@export var note_puzzle_tag_color: Color = Color(0.85, 0.76, 0.62)
var _selected_ids: Array[StringName] = []
var _dish_buttons: Dictionary[StringName, Button] = {}
## 메뉴판을 열 때 처음 골라 둔 요리 (확정할 때 플레이어가 직접 뺀 번진 노트 요리를 찾으려고)
var _initial_ids: Array[StringName] = []
## 번진 노트 표시를 붙이는 줄의 글 (요리 id → 글)
var _note_tag_labels: Dictionary[StringName, Label] = {}
## 메뉴판을 열기 전에 선택돼 있던 것. 돌아가기를 누르면 다시 선택한다.
var _previous_focus: Control

@onready var _rows: VBoxContainer = %MenuRows
@onready var _count_label: Label = %CountLabel
@onready var _message_label: Label = %MessageLabel
## 왼쪽 아래: 지금 가진 재료 (아이콘 + 이름 ×개수)
@onready var _inventory_grid: GridContainer = %InventoryGrid
## 위쪽: 오늘 점심에 올 손님 (얼굴 + 이름, 약속한 손님은 ★, 처음 오는 손님은 ?)
@onready var _today_guests: HBoxContainer = %TodayGuests
## 제목 아래 안내 줄 (특별한 점심 날에는 그날 안내로 바꾼다)
@onready var _subtitle: Label = $Board/Subtitle
var _default_subtitle: String = ""
var _default_subtitle_color: Color
@onready var _start_button: Button = %StartButton
@onready var _back_button: Button = %BackButton


## 오늘 고를 수 있는 메뉴 수
func _max_dishes() -> int:
	return GameState.get_menu_slots()


func _ready() -> void:
	_start_button.pressed.connect(_on_start_button_pressed)
	_default_subtitle = _subtitle.text
	_default_subtitle_color = _subtitle.get_theme_color("font_color")
	_back_button.pressed.connect(_on_back_button_pressed)
	hide()


func open() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	for child: Node in _rows.get_children():
		child.queue_free()
	_dish_buttons.clear()
	_note_tag_labels.clear()
	var recipes: Array[Recipe] = GameData.get_all_recipes().filter(
			func(recipe: Recipe) -> bool: return GameState.is_recipe_unlocked(recipe.id))
	_selected_ids = _initial_selection(recipes)
	_initial_ids = _selected_ids.duplicate()
	var buttons: Array[Button] = []
	for recipe: Recipe in recipes:
		var row: HBoxContainer = _make_row(recipe)
		_rows.add_child(row)
		buttons.append(_dish_buttons[recipe.id])
	_message_label.text = "" if _can_make_any() else NOTHING_TO_COOK_TEXT
	_fill_inventory()
	_fill_today_guests()
	var special: SpecialLunch = GameData.get_special_lunch(GameState.current_day)
	_subtitle.text = special.fill(special.menu_notice) if special != null and not special.menu_notice.is_empty() else _default_subtitle
	_subtitle.add_theme_color_override("font_color", selected_color if special != null else _default_subtitle_color)
	_refresh()
	_keep_focus_inside(buttons)
	show()
	if not buttons.is_empty():
		buttons[0].grab_focus()
	TutorialDialog.show_once(self, &"menu")


## 되찾은 레시피 중 지금 가진 재료로 만들 수 있는 것이 하나라도 있는지
func _can_make_any() -> bool:
	return GameData.get_all_recipes().any(func(recipe: Recipe) -> bool:
		return GameState.is_recipe_unlocked(recipe.id) and GameState.has_ingredients(recipe.get_ingredient_counts()))


## 처음에 골라 둘 메뉴: 되찾은 레시피가 메뉴 칸 이하면 전부, 아니면 어제 메뉴.
## 메뉴 칸이 늘어서 자리가 남으면 어제 메뉴에 없던 레시피로 채운다 (새로 되찾은 레시피가 바로 메뉴에 오르게, 뒤에 되찾은 것부터).
func _initial_selection(recipes: Array[Recipe]) -> Array[StringName]:
	var ids: Array[StringName] = []
	# 오늘 약속한 요리와 생일 소원 요리는 처음부터 골라 둔다.
	for recipe: Recipe in recipes:
		if _is_promised(recipe.id) or _is_birthday_wish(recipe.id):
			ids.append(recipe.id)
	for recipe: Recipe in recipes:
		if (recipes.size() <= _max_dishes() or recipe.id in GameState.menu_recipe_ids) and recipe.id not in ids:
			ids.append(recipe.id)
	for i: int in range(GameState.unlocked_recipe_ids.size() - 1, -1, -1):
		if ids.size() >= _max_dishes():
			break
		var recipe_id: StringName = GameState.unlocked_recipe_ids[i]
		# 플레이어가 직접 뺀 번진 노트 요리는 빈 칸에도 다시 채우지 않는다.
		if GameState.is_note_puzzle_declined(recipe_id):
			continue
		if recipe_id not in ids and recipes.any(func(recipe: Recipe) -> bool: return recipe.id == recipe_id):
			ids.append(recipe_id)
	ids = ids.slice(0, _max_dishes())
	_add_note_puzzle_dish(recipes, ids)
	return ids


## 번진 할머니 노트가 있는 요리가 메뉴에 하나도 없으면, 그중 가장 최근에 되찾았고 지금 재료로 만들 수 있는 요리 하나를 미리 올려 둔다.
## 칸이 다 찼으면 재료가 모자란 요리, 없으면 맨 뒤의 요리(약속·생일 소원 요리는 빼고)와 바꾼다. 플레이어가 메뉴판에서 다시 바꿀 수 있다.
## 새로 되찾은 요리가 어제 메뉴에 밀려 한 번도 안 나가는 일을 막으려는 것 (퍼즐을 고르게 만나게).
## 플레이어가 (재료가 있는데도) 직접 뺀 요리는 그 선택을 존중해서 다시 밀어 넣지 않는다 (줄의 "번진 할머니 노트" 표시는 그대로라 언제든 다시 고를 수 있다).
## 재료가 없어서 뺀 요리는 선택이 아니므로 재료가 생기면 다시 권한다.
func _add_note_puzzle_dish(recipes: Array[Recipe], ids: Array[StringName]) -> void:
	for id: StringName in ids:
		var chosen: Recipe = GameData.get_recipe(id)
		if NotePuzzleBoard.is_waiting_today(chosen) and GameState.has_ingredients(chosen.get_ingredient_counts()):
			return
	for i: int in range(GameState.unlocked_recipe_ids.size() - 1, -1, -1):
		var recipe: Recipe = GameData.get_recipe(GameState.unlocked_recipe_ids[i])
		if recipe == null or recipe not in recipes or not NotePuzzleBoard.is_waiting_today(recipe) \
				or GameState.is_note_puzzle_declined(recipe.id) or not GameState.has_ingredients(recipe.get_ingredient_counts()):
			continue
		if ids.size() < _max_dishes():
			ids.append(recipe.id)
			return
		# 재료가 모자란 요리를 먼저 뺀다 (그대로 두면 장사를 시작할 수 없다). 없으면 맨 뒤의 요리.
		var target: int = -1
		for j: int in range(ids.size() - 1, -1, -1):
			if _is_promised(ids[j]) or _is_birthday_wish(ids[j]):
				continue
			if target == -1:
				target = j
			if not GameState.has_ingredients(GameData.get_recipe(ids[j]).get_ingredient_counts()):
				target = j
				break
		if target != -1:
			ids[target] = recipe.id
		return


func _make_row(recipe: Recipe) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size.y = row_height
	var button: Button = Button.new()
	button.custom_minimum_size.x = dish_button_width
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", row_font_size)
	button.pressed.connect(_toggle.bind(recipe.id))
	row.add_child(button)
	_dish_buttons[recipe.id] = button
	row.add_child(_make_ingredients_label(recipe))
	# 누가 좋아하는지는 손님 수첩에서 찾아본다. 여기서는 오늘 점심 약속한 요리에만 표시를 붙인다.
	var likes: Label = Label.new()
	likes.add_theme_font_size_override("font_size", detail_font_size)
	if _is_promised(recipe.id):
		var guest: AnimalGuest = GameData.get_guest(GameState.promise_guest_id)
		var guest_name: String = guest.display_name if guest != null else ""
		likes.text = PROMISE_FORMAT % [guest_name, Korean.with_particle(guest_name)]
		likes.add_theme_color_override("font_color", selected_color)
	elif _is_birthday_wish(recipe.id):
		var special: SpecialLunch = GameData.get_special_lunch(GameState.current_day)
		likes.text = special.fill(special.menu_tag_format)
		likes.add_theme_color_override("font_color", selected_color)
	elif NotePuzzleBoard.is_waiting_today(recipe):
		# 글은 _refresh 가 정한다 (고른 메뉴에 따라 바뀐다).
		likes.add_theme_color_override("font_color", note_puzzle_tag_color)
		_note_tag_labels[recipe.id] = likes
	likes.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(likes)
	return row


## "■×1 ■×2  재료 부족" (재료 아이콘과 필요한 개수, 지금 모자라면 빨간 "재료 부족")
## 왼쪽 아래 가진 재료: [아이콘] 당근 ×6 처럼 한 칸씩, inventory_items_per_line 칸마다 줄을 바꾼다
func _fill_inventory() -> void:
	for child: Node in _inventory_grid.get_children():
		child.queue_free()
	_inventory_grid.columns = inventory_items_per_line
	var shown: int = 0
	for ingredient_id: StringName in GameState.inventory:
		var count: int = GameState.get_ingredient_count(ingredient_id)
		if count <= 0:
			continue
		var ingredient: Ingredient = GameData.get_ingredient(ingredient_id)
		var cell: HBoxContainer = HBoxContainer.new()
		if ingredient != null:
			var icon: TextureRect = TextureRect.new()
			icon.texture = ingredient.get_icon_texture()
			icon.custom_minimum_size = Vector2(ingredient_icon_size, ingredient_icon_size)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cell.add_child(icon)
		var ingredient_name: String = ingredient.display_name if ingredient != null else String(ingredient_id)
		cell.add_child(_make_inventory_label(INVENTORY_ITEM_FORMAT % [ingredient_name, count]))
		_inventory_grid.add_child(cell)
		shown += 1
	# 지운 칸은 이번 프레임 끝까지 남아 있으므로 자식 수 대신 직접 센다.
	if shown == 0:
		_inventory_grid.add_child(_make_inventory_label(INVENTORY_EMPTY_TEXT))


func _fill_today_guests() -> void:
	for child: Node in _today_guests.get_children():
		child.queue_free()
	_today_guests.add_child(_make_guest_label(TODAY_GUESTS_TITLE, inventory_text_color))
	var promised: bool = GameState.has_promise_on(GameState.current_day)
	for guest_id: StringName in GameState.get_todays_guest_ids():
		var guest: AnimalGuest = GameData.get_guest(guest_id)
		if guest == null:
			continue
		# 아직 얼굴을 못 본 손님은 누군지 모르게 "?" 만 (만나는 재미는 점심에).
		if not GameState.has_seen_guest(guest_id):
			_today_guests.add_child(_make_guest_label(UNMET_GUEST_TEXT, guest_text_color))
			continue
		var icon: TextureRect = TextureRect.new()
		icon.texture = guest.get_icon_texture()
		icon.custom_minimum_size = Vector2(guest_icon_size, guest_icon_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_today_guests.add_child(icon)
		var is_promise_guest: bool = promised and guest_id == GameState.promise_guest_id
		_today_guests.add_child(_make_guest_label(
				(PROMISE_MARK if is_promise_guest else "") + guest.display_name,
				selected_color if is_promise_guest else guest_text_color))


func _make_guest_label(text: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", detail_font_size)
	label.add_theme_color_override("font_color", color)
	label.size_flags_vertical = Control.SIZE_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _make_inventory_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", detail_font_size)
	label.add_theme_color_override("font_color", inventory_text_color)
	return label


func _make_ingredients_label(recipe: Recipe) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.custom_minimum_size = Vector2(ingredients_width, row_height)
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("normal_font_size", detail_font_size)
	var counts: Dictionary[StringName, int] = recipe.get_ingredient_counts()
	for ingredient_id: StringName in counts:
		var ingredient: Ingredient = GameData.get_ingredient(ingredient_id)
		if ingredient != null:
			label.add_image(ingredient.get_icon_texture(), ingredient_icon_size, ingredient_icon_size,
					Color.WHITE, INLINE_ALIGNMENT_CENTER)
		label.add_text(INGREDIENT_FORMAT % counts[ingredient_id])
	if not GameState.has_ingredients(counts):
		label.push_color(short_color)
		label.add_text(SHORT_TEXT)
		label.pop()
	return label


## 오늘이 손님 생일이고 이 요리가 생일 소원 요리인지
func _is_birthday_wish(recipe_id: StringName) -> bool:
	var special: SpecialLunch = GameData.get_special_lunch(GameState.current_day)
	if special == null or special.kind != SpecialLunch.Kind.BIRTHDAY:
		return false
	var wish: Recipe = special.get_wish_recipe()
	return wish != null and wish.id == recipe_id


## 오늘 점심 약속한 요리인지
func _is_promised(recipe_id: StringName) -> bool:
	return GameState.has_promise_on(GameState.current_day) and GameState.promise_recipe_id == recipe_id


func _toggle(recipe_id: StringName) -> void:
	_message_label.text = ""
	if recipe_id in _selected_ids:
		_selected_ids.erase(recipe_id)
	elif _selected_ids.size() >= _max_dishes():
		_message_label.text = LIMIT_TEXT % _max_dishes()
	else:
		_selected_ids.append(recipe_id)
	_refresh()


func _refresh() -> void:
	for recipe_id: StringName in _dish_buttons:
		var recipe: Recipe = GameData.get_recipe(recipe_id)
		var button: Button = _dish_buttons[recipe_id]
		if recipe_id in _selected_ids:
			button.text = SELECTED_FORMAT % recipe.display_name
			for color_name: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
				button.add_theme_color_override(color_name, selected_color)
		else:
			button.text = UNSELECTED_FORMAT % recipe.display_name
			for color_name: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
				button.remove_theme_color_override(color_name)
	_count_label.text = COUNT_FORMAT % [_selected_ids.size(), _max_dishes()]
	# 퍼즐은 점심 한 번에 한 장이라서, 번진 노트 요리를 둘 이상 고르면 고른 줄에 그 사실을 적는다 (먼저 만드는 요리에서 펼쳐진다).
	var selected_count: int = _note_tag_labels.keys().filter(func(recipe_id: StringName) -> bool: return recipe_id in _selected_ids).size()
	for recipe_id: StringName in _note_tag_labels:
		var is_one_of_many: bool = selected_count >= 2 and recipe_id in _selected_ids
		_note_tag_labels[recipe_id].text = NOTE_PUZZLE_ONE_PER_LUNCH_TAG if is_one_of_many else NOTE_PUZZLE_TAG


func _on_start_button_pressed() -> void:
	# 만들 수 있는 요리가 하나도 없으면 메뉴 없이 연다 (막아 두면 그날 아침에서 더 나아갈 수 없다).
	if not _can_make_any():
		var empty_menu: Array[StringName] = []
		hide()
		confirmed.emit(empty_menu)
		return
	if _selected_ids.is_empty():
		_message_label.text = PICK_ONE_TEXT
		Sound.play(BLOCKED_SOUND)
		return
	# 재료가 모자란 요리를 골라 두면 부엌으로 가지 않는다 (손님이 시켜도 만들 수 없으니까).
	var short_names: PackedStringArray = []
	for recipe_id: StringName in _selected_ids:
		var recipe: Recipe = GameData.get_recipe(recipe_id)
		if recipe != null and not GameState.has_ingredients(recipe.get_ingredient_counts()):
			short_names.append(recipe.display_name)
	if not short_names.is_empty():
		_message_label.text = SHORT_BLOCK_FORMAT % NAME_SEPARATOR.join(short_names)
		Wiggle.shake(_start_button)
		Sound.play(BLOCKED_SOUND)
		return
	# 처음 골라 둔 번진 노트 요리를 재료가 있는데도 뺐으면 플레이어의 선택이라 적어 둔다 (다음부터 다시 밀어 넣지 않게).
	for recipe_id: StringName in _initial_ids:
		var recipe: Recipe = GameData.get_recipe(recipe_id)
		if recipe_id not in _selected_ids and NotePuzzleBoard.is_waiting_today(recipe) \
				and GameState.has_ingredients(recipe.get_ingredient_counts()):
			GameState.decline_note_puzzle(recipe_id)
	hide()
	confirmed.emit(_selected_ids.duplicate())


func _on_back_button_pressed() -> void:
	hide()
	cancelled.emit()
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()


## 메뉴판이 열린 동안 방향키로 뒤쪽 텃밭 버튼에 가지 않도록, 선택이 메뉴판 안에서만 돌게 한다.
## 요리 목록은 위아래로 이어지고, 맨 아래 요리 다음은 시작 버튼, 시작과 돌아가기는 좌우로 오간다.
func _keep_focus_inside(dish_buttons: Array[Button]) -> void:
	var order: Array[Button] = dish_buttons.duplicate()
	order.append(_start_button)
	for i: int in order.size():
		var button: Button = order[i]
		button.focus_neighbor_top = button.get_path_to(order[i - 1])
		button.focus_neighbor_bottom = button.get_path_to(order[(i + 1) % order.size()])
		button.focus_neighbor_left = button.get_path_to(_back_button if button == _start_button else button)
		button.focus_neighbor_right = button.get_path_to(_back_button if button == _start_button else button)
		button.focus_previous = button.focus_neighbor_top
		button.focus_next = button.focus_neighbor_bottom
	_back_button.focus_neighbor_left = _back_button.get_path_to(_start_button)
	_back_button.focus_neighbor_right = _back_button.get_path_to(_start_button)
	_back_button.focus_neighbor_top = _back_button.get_path_to(order[order.size() - 2] if order.size() > 1 else _start_button)
	_back_button.focus_neighbor_bottom = _back_button.get_path_to(order[0])
	_back_button.focus_next = _back_button.get_path_to(_start_button)
	_back_button.focus_previous = _back_button.get_path_to(_start_button)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()
