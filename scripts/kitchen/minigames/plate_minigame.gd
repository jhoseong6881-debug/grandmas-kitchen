class_name PlateMinigame
extends Minigame
## 담기 미니게임. 위에서 내려다본 접시(국물 요리는 그릇)에 점선 자리가 몇 개 있다.
## 뒤집개가 요리 한 조각을 들고 접시 위를 좌우로 오가고, 금색 자리 위에 왔을 때 누르면 그 자리에 톡 놓인다.
## 자리 가운데에 가까울수록 반듯하게 놓인다. 자리를 벗어나면 조각이 미끄러져 다시 집는다 (벌칙 없음).
## 조각 색은 그 요리 재료 색 (그림이 생기기 전 임시). 누르기 입력, 연타 방지, 완벽 표시는 공통 틀(Minigame)이 맡는다.

const READY_FORMAT: String = "0 / %d"
const HIT_FORMAT: String = "톡! %d / %d"
const MISS_FORMAT: String = "앗, 미끄러졌어요. 다시 놓아요 %d / %d"
const DONE_TEXT: String = "예쁘게 담았어요!"

## 놓을 조각 수 (요리 단계의 횟수가 없을 때)
@export var piece_count: int = 4
## 한 줄에 놓는 자리 수
@export var slots_per_row: int = 4
## 자리(조각) 크기와 자리 사이 간격
@export var slot_size: Vector2 = Vector2(96, 72)
@export var slot_gap: Vector2 = Vector2(24, 36)
## 맞는 폭 (자리 폭에 대한 배율). 클수록 쉽다. 큰 국자(조리도구)가 있으면 넓어진다.
@export var hit_width_ratio: float = 1.0
## 판정을 후하게 해 주는 여유(픽셀). 화면에는 안 보인다.
@export var judge_margin: float = 8.0
## 뒤집개가 좌우로 오가는 빠르기(1초에 픽셀)와, 접시 가장자리에서 돌아서는 여백
@export var tool_speed: float = 450.0
@export var tool_edge_padding: float = 70.0
## 뒤집개가 자리 위로 떠 있는 높이(픽셀)
@export var tool_hover_height: float = 90.0
## 조각이 내려앉는 시간, 빗나간 조각이 미끄러져 사라지는 시간(초)
@export var drop_duration: float = 0.12
@export var slip_duration: float = 0.3
## 다 놓았을 때 접시가 살짝 커졌다 돌아오는 정도와 시간(초)
@export var bounce_scale: float = 1.04
@export var bounce_duration: float = 0.12
## 조각 색이 재료 색보다 조금 밝게, 테두리는 진하게
@export var piece_lighten: float = 0.1
@export var piece_outline_darken: float = 0.45
## 재료 색을 알 수 없을 때 조각 색
@export var default_piece_color: Color = Color(0.9, 0.6, 0.35)
@export var empty_slot_color: Color = Color(0.55, 0.5, 0.45, 0.35)
@export var target_slot_color: Color = Color(1, 0.84, 0.25, 0.55)
## 국물 요리(Recipe.serve_in_bowl)일 때 그릇 안쪽 색 (국물)
@export var broth_color: Color = Color(0.78, 0.62, 0.42)

var _piece_total: int = 0
var _pieces_done: int = 0
## 자리마다 접시 안 위치 (자리의 왼쪽 위)
var _slot_positions: Array[Vector2] = []
var _slot_nodes: Array[Panel] = []
var _piece_colors: Array[Color] = []
var _tool_direction: float = 1.0
var _tool_speed: float = 520.0
var _hit_width: float = 96.0
var _is_dropping: bool = false

@onready var _plate: Panel = %Plate
@onready var _plate_inner: Panel = %PlateInner
@onready var _slots: Control = %Slots
@onready var _target_marker: Control = %TargetMarker
@onready var _tool: Control = %Tool
@onready var _held_piece: Panel = %HeldPiece
@onready var _hint_label: Label = %HintLabel


func _ready() -> void:
	super()
	_plate.pivot_offset = _plate.size / 2.0


func _get_minigame_type() -> Recipe.MinigameType:
	return Recipe.MinigameType.PLATE


func _on_start(recipe: Recipe) -> void:
	_piece_total = maxi(_step_count(piece_count), 1)
	_pieces_done = 0
	_tool_speed = tool_speed * _speed
	_hit_width = slot_size.x * hit_width_ratio * _window_scale
	_is_dropping = false
	_piece_colors = _recipe_colors(recipe)
	_set_bowl_style(recipe.serve_in_bowl)
	_build_slots()
	_clear_zones(_target_marker)
	_target_marker.size = Vector2(_hit_width, slot_size.y)
	_move_target_to(0)
	_tool_direction = 1.0
	_tool.position.x = _plate.position.x + tool_edge_padding
	_prepare_next_piece()
	_title_label.text = _step_title(Recipe.MinigameType.PLATE, recipe.display_name)
	_progress_label.text = READY_FORMAT % _piece_total


func _process(delta: float) -> void:
	super(delta)
	if not _is_playing:
		return
	var left: float = _plate.position.x + tool_edge_padding
	var right: float = _plate.position.x + _plate.size.x - tool_edge_padding
	_tool.position.x += _tool_direction * _tool_speed * delta
	if _tool.position.x >= right:
		_tool.position.x = right
		_tool_direction = -1.0
	elif _tool.position.x <= left:
		_tool.position.x = left
		_tool_direction = 1.0


func _on_press() -> void:
	if _is_dropping or _pieces_done >= _piece_total:
		return
	var offset: float = _tool_tip_x() - _slot_center_x(_pieces_done)
	if absf(offset) <= _hit_width / 2.0 + judge_margin:
		# 맞는 폭의 왼쪽 끝 = 0, 오른쪽 끝 = 1
		_register_hit((offset + _hit_width / 2.0) / _hit_width)
		_drop_piece(offset)
	else:
		_register_miss()
		_progress_label.text = MISS_FORMAT % [_pieces_done, _piece_total]
		_slip_piece()


## 금색 자리 안에 비법 자리나 부탁 자리를 그린다. 왼쪽이 0, 오른쪽이 1. 자리가 옮겨 가면 함께 옮겨 간다.
func _show_zone(start: float, end: float, color: Color, zone_name: String) -> void:
	_make_zone(_target_marker, Rect2(_hit_width * start, 0.0, _hit_width * (end - start), slot_size.y), color, zone_name)


## 뒤집개 끝(들고 있는 조각 가운데)의 x (이 미니게임 화면 기준)
func _tool_tip_x() -> float:
	return _tool.position.x + _held_piece.position.x + _held_piece.size.x / 2.0


func _slot_center_x(index: int) -> float:
	return _plate.position.x + _slots.position.x + _slot_positions[index].x + slot_size.x / 2.0


## 맞힌 조각: 들고 있던 자리(가운데에서 offset 만큼 비껴서)로 톡 내려앉는다.
func _drop_piece(offset: float) -> void:
	_is_dropping = true
	var index: int = _pieces_done
	var piece: Panel = _make_piece(_piece_colors[index % _piece_colors.size()])
	_slots.add_child(piece)
	piece.global_position = _held_piece.global_position
	_held_piece.hide()
	var landing: Vector2 = _slot_positions[index] + Vector2(clampf(offset, -slot_size.x / 3.0, slot_size.x / 3.0), 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(piece, "position", landing, drop_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	_slot_nodes[index].hide()
	_pieces_done += 1
	_progress_label.text = HIT_FORMAT % [_pieces_done, _piece_total]
	if _pieces_done >= _piece_total:
		_target_marker.hide()
		_plate.scale = Vector2.ONE * bounce_scale
		create_tween().tween_property(_plate, "scale", Vector2.ONE, bounce_duration)
		_complete(DONE_TEXT)
		return
	_move_target_to(_pieces_done)
	_prepare_next_piece()
	_is_dropping = false


## 빗나간 조각: 미끄러지며 사라지고, 뒤집개가 새 조각을 집는다.
func _slip_piece() -> void:
	_is_dropping = true
	var piece: Panel = _make_piece(_held_piece.self_modulate)
	add_child(piece)
	piece.global_position = _held_piece.global_position
	_held_piece.hide()
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(piece, "position", piece.position + Vector2(_tool_direction * 60.0, 50.0), slip_duration)
	tween.tween_property(piece, "rotation", _tool_direction * 0.6, slip_duration)
	tween.tween_property(piece, "modulate:a", 0.0, slip_duration)
	await tween.finished
	piece.queue_free()
	_prepare_next_piece()
	_is_dropping = false


func _prepare_next_piece() -> void:
	_held_piece.self_modulate = _piece_colors[_pieces_done % _piece_colors.size()]
	_held_piece.show()
	# 뒤집개는 지금 놓을 자리 줄 위에 떠 있다.
	_tool.position.y = _plate.position.y + _slots.position.y + _slot_positions[_pieces_done].y - tool_hover_height


func _move_target_to(index: int) -> void:
	_target_marker.show()
	_target_marker.position = _slot_positions[index] + Vector2((slot_size.x - _hit_width) / 2.0, 0.0)


## 자리들을 접시 가운데에 줄지어 놓는다 (한 줄에 slots_per_row 개).
func _build_slots() -> void:
	for child: Node in _slots.get_children():
		if child != _target_marker:
			child.queue_free()
	_slot_positions.clear()
	_slot_nodes.clear()
	var rows: int = ceili(float(_piece_total) / slots_per_row)
	var total_height: float = rows * slot_size.y + (rows - 1) * slot_gap.y
	var area: Vector2 = _slots.size
	for i: int in _piece_total:
		var row: int = i / slots_per_row
		var in_row: int = mini(slots_per_row, _piece_total - row * slots_per_row)
		var column: int = i % slots_per_row
		var row_width: float = in_row * slot_size.x + (in_row - 1) * slot_gap.x
		var slot_position: Vector2 = Vector2((area.x - row_width) / 2.0 + column * (slot_size.x + slot_gap.x),
				(area.y - total_height) / 2.0 + row * (slot_size.y + slot_gap.y))
		_slot_positions.append(slot_position)
		var slot: Panel = Panel.new()
		slot.position = slot_position
		slot.size = slot_size
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.draw_center = false
		style.border_color = empty_slot_color
		style.set_border_width_all(4)
		style.set_corner_radius_all(24)
		slot.add_theme_stylebox_override("panel", style)
		_slots.add_child(slot)
		_slot_nodes.append(slot)
	_slots.move_child(_target_marker, -1)


## 요리 조각 하나 (그림이 생기기 전: 재료 색 둥근 조각 + 진한 테두리)
func _make_piece(color: Color) -> Panel:
	var piece: Panel = Panel.new()
	piece.size = slot_size
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.darkened(piece_outline_darken)
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	piece.add_theme_stylebox_override("panel", style)
	return piece


## 조각 색: 레시피 재료마다 한 색씩 (겹치는 재료는 한 번). 요리 단계에 임시 색이 있으면 그것.
func _recipe_colors(recipe: Recipe) -> Array[Color]:
	var colors: Array[Color] = []
	if _step != null and _step.placeholder_color.a > 0.0:
		colors.append(_step.placeholder_color)
		return colors
	for ingredient: Ingredient in recipe.ingredients:
		if ingredient == null:
			continue
		var color: Color = ingredient.placeholder_color.lightened(piece_lighten)
		if color not in colors:
			colors.append(color)
	if colors.is_empty():
		colors.append(default_piece_color)
	return colors


## 국물 요리는 그릇 안에 국물 색을 깔고 테두리를 두껍게, 아니면 납작한 흰 접시
func _set_bowl_style(is_bowl: bool) -> void:
	var inner: StyleBoxFlat = _plate_inner.get_theme_stylebox("panel").duplicate()
	inner.bg_color = broth_color if is_bowl else Color(0.98, 0.97, 0.94)
	_plate_inner.add_theme_stylebox_override("panel", inner)
	var rim: StyleBoxFlat = _plate.get_theme_stylebox("panel").duplicate()
	rim.set_border_width_all(36 if is_bowl else 18)
	_plate.add_theme_stylebox_override("panel", rim)
