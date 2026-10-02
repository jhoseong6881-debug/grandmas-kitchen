class_name ResultBoard
extends Control
## 장사 결과판. 점심 장사가 끝나고 "저녁으로"를 누르면 열려서 오늘 장사(LunchReport)를 보여 준다.
## 줄이 하나씩 나타나고, 소문 숫자와 가게 게이지가 올라간다. 보여 주는 중에 누르면 한 번에 다 보여 준다.
## 오늘 쌓인 소문은 열릴 때 GameState 에 더한다. "저녁 평상으로"를 누르면 continued 시그널을 보낸다.

signal continued

const TITLE_FORMAT: String = "오늘의 장사 · %d일째"
const GUESTS_FORMAT: String = "손님 %d명   %s"
const GUEST_SEPARATOR: String = " · "
const PAYMENT_PREFIX: String = "받은 밥값   "
const PAYMENT_ITEM_FORMAT: String = " %s ×%d    "
const NONE_TEXT: String = "없음"
const HIGHLIGHT_FORMAT: String = "완벽 %d   ·   할머니 손맛 %d   ·   부탁 %d/%d   ·   입맛 딱 %d"
const AFFECTION_PREFIX: String = "단골도   "
const AFFECTION_ITEM_FORMAT: String = "%s ♥+%d   "
const REPUTATION_FORMAT: String = "소문 +%d"
const STAR_FULL: String = "★"
const STAR_EMPTY: String = "☆"
const GAUGE_FORMAT: String = "%s   %d / %d   다음: %s"
const GAUGE_MAX_FORMAT: String = "%s   소문 %d"
const SHOP_UP_FORMAT: String = "가게 이름이 바뀌었어요!  「%s」"
const SHOP_UNLOCK_FORMAT: String = "\n%s"
## 효과음 이름 (data/sounds/ 의 id): 줄이 하나씩 나타날 때, 가게 이름이 바뀔 때
const LINE_SOUND: StringName = &"result_line"
const SHOP_UP_SOUND: StringName = &"shop_up"

## 줄이 하나씩 나타나는 간격(초)과 나타나는 시간(초)
@export var line_interval: float = 0.35
@export var line_fade_duration: float = 0.2
## 소문 숫자와 게이지가 올라가는 시간(초)
@export var count_duration: float = 0.8
@export var payment_icon_size: int = 36

var _tween: Tween
var _is_revealing: bool = false
## 마지막에 보여 줄 값 (건너뛸 때 바로 채운다)
var _final_reputation_points: int = 0
var _gauge_from: float = 0.0
var _gauge_to: float = 0.0
var _new_shop_tier: int = -1

@onready var _title_label: Label = %TitleLabel
@onready var _guests_label: Label = %GuestsLabel
@onready var _payment_label: RichTextLabel = %PaymentLabel
@onready var _highlight_label: Label = %HighlightLabel
@onready var _affection_label: Label = %AffectionLabel
@onready var _reputation_row: Control = %ReputationRow
@onready var _reputation_label: Label = %ReputationLabel
@onready var _stars_label: Label = %StarsLabel
@onready var _gauge_row: Control = %GaugeRow
@onready var _gauge_label: Label = %GaugeLabel
@onready var _gauge_bar: Control = %GaugeBar
@onready var _gauge_fill: Control = %GaugeFill
@onready var _shop_up_label: Label = %ShopUpLabel
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	hide()


func open(report: LunchReport) -> void:
	var settings: ReputationSettings = GameData.get_reputation_settings()
	_title_label.text = TITLE_FORMAT % GameState.current_day
	_guests_label.text = GUESTS_FORMAT % [report.guest_names.size(),
			GUEST_SEPARATOR.join(report.guest_names) if not report.guest_names.is_empty() else NONE_TEXT]
	_fill_payment(report.payment)
	_highlight_label.text = HIGHLIGHT_FORMAT % [report.perfect_count, report.grandma_taste_count,
			report.request_met_count, report.request_count, report.taste_match_count]
	var affection_text: String = AFFECTION_PREFIX
	for guest_name: String in report.affection_gains:
		affection_text += AFFECTION_ITEM_FORMAT % [guest_name, report.affection_gains[guest_name]]
	_affection_label.text = affection_text if not report.affection_gains.is_empty() else AFFECTION_PREFIX + NONE_TEXT
	var stars: int = settings.get_stars(report.reputation)
	_stars_label.text = STAR_FULL.repeat(stars) + STAR_EMPTY.repeat(settings.star_thresholds.size() - stars)
	# 소문을 더하고, 게이지는 지금 가게 단계 안에서 전 → 후로 올라간다.
	var before: int = GameState.reputation
	_new_shop_tier = GameState.add_reputation(report.reputation)
	_final_reputation_points = report.reputation
	var tier: int = GameState.get_shop_tier()
	var low: int = maxi(settings.get_threshold(tier), 0)
	var high: int = settings.get_next_threshold(tier)
	if high > low:
		_gauge_from = clampf(float(before - low) / (high - low), 0.0, 1.0)
		_gauge_to = clampf(float(GameState.reputation - low) / (high - low), 0.0, 1.0)
		_gauge_label.text = GAUGE_FORMAT % [settings.get_shop_name(tier), GameState.reputation, high,
				settings.get_shop_name(tier + 1)]
	else:
		_gauge_from = 1.0
		_gauge_to = 1.0
		_gauge_label.text = GAUGE_MAX_FORMAT % [settings.get_shop_name(tier), GameState.reputation]
	if _new_shop_tier >= 0:
		_shop_up_label.text = SHOP_UP_FORMAT % settings.get_shop_name(_new_shop_tier)
		var level: ShopLevel = settings.get_shop_level(_new_shop_tier)
		if level != null and not level.unlock_text.is_empty():
			_shop_up_label.text += SHOP_UNLOCK_FORMAT % level.unlock_text
	show()
	_reveal()


## "받은 밥값   [아이콘] 당근 ×4   [아이콘] 꿀 ×2"
func _fill_payment(payment: Dictionary[StringName, int]) -> void:
	_payment_label.clear()
	_payment_label.add_text(PAYMENT_PREFIX)
	if payment.is_empty():
		_payment_label.add_text(NONE_TEXT)
	for ingredient_id: StringName in payment:
		var ingredient: Ingredient = GameData.get_ingredient(ingredient_id)
		var ingredient_name: String = String(ingredient_id)
		if ingredient != null:
			ingredient_name = ingredient.display_name
			_payment_label.add_image(ingredient.get_icon_texture(), payment_icon_size, payment_icon_size,
					Color.WHITE, INLINE_ALIGNMENT_CENTER)
		_payment_label.add_text(PAYMENT_ITEM_FORMAT % [ingredient_name, payment[ingredient_id]])


## 줄을 하나씩 보여 주고, 소문 숫자와 게이지를 올린다.
func _reveal() -> void:
	var rows: Array[Control] = [_guests_label, _payment_label, _highlight_label, _affection_label, _reputation_row, _gauge_row]
	for row: Control in rows:
		row.modulate.a = 0.0
	_shop_up_label.hide()
	_continue_button.hide()
	_reputation_label.text = REPUTATION_FORMAT % 0
	_gauge_fill.size.x = _gauge_from * _gauge_bar.size.x
	_is_revealing = true
	_tween = create_tween()
	for row: Control in rows:
		_tween.tween_callback(Sound.play.bind(LINE_SOUND))
		_tween.tween_property(row, "modulate:a", 1.0, line_fade_duration)
		_tween.tween_interval(line_interval)
	_tween.tween_method(_set_reputation_count, 0, _final_reputation_points, count_duration)
	_tween.parallel().tween_property(_gauge_fill, "size:x", _gauge_to * _gauge_bar.size.x, count_duration)
	_tween.tween_callback(_finish_reveal)


func _set_reputation_count(points: int) -> void:
	_reputation_label.text = REPUTATION_FORMAT % points


## 다 보여 준 상태로 만든다 (끝까지 갔거나, 보여 주는 중에 눌렀을 때).
func _finish_reveal() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_is_revealing = false
	for row: Control in [_guests_label, _payment_label, _highlight_label, _affection_label, _reputation_row, _gauge_row]:
		row.modulate.a = 1.0
	_set_reputation_count(_final_reputation_points)
	_gauge_fill.size.x = _gauge_to * _gauge_bar.size.x
	_shop_up_label.visible = _new_shop_tier >= 0
	if _new_shop_tier >= 0:
		Sound.play(SHOP_UP_SOUND)
	_continue_button.show()
	_continue_button.grab_focus()


func _on_continue_pressed() -> void:
	hide()
	continued.emit()


func _gui_input(event: InputEvent) -> void:
	_skip_if_pressed(event)


func _unhandled_input(event: InputEvent) -> void:
	_skip_if_pressed(event)


## 보여 주는 중에 클릭, 스페이스/Enter, 게임패드 A 를 누르면 한 번에 다 보여 준다.
func _skip_if_pressed(event: InputEvent) -> void:
	if not visible or not _is_revealing:
		return
	var is_click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if is_click or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_finish_reveal()
