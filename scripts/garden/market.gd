extends Control
## 숲속 장터 장면. 장날(MarketSettings)에 당근 텃밭에서 건너온다.
## 너구리 상인이 그날의 거래 몇 가지를 보여 주고, 거래를 누르면 남는 재료를 다른 재료로 바꾼다.
## 같은 거래는 하루에 daily_limit_per_trade 번까지. 재료가 모자라면 상인이 알려 준다. 다 보면 텃밭으로 돌아간다.

const DAY_TEXT_FORMAT: String = "%d일째 · 숲속 장터"
const TRADE_FORMAT: String = "%s ×%d   →   %s ×%d      (오늘 %d번 남음)"
const SOLD_OUT_FORMAT: String = "%s ×%d   →   %s ×%d      (오늘은 다 나갔어요)"
const SPEECH_FORMAT: String = "%s: %s"
const LINE_JOIN: String = "\n"
const TRADE_POP_FORMAT: String = "+%d %s"
## 효과음 이름 (data/sounds/ 의 id)
const TRADE_SOUND: StringName = &"receive"
const SHORT_SOUND: StringName = &"miss"

## 이 장면의 배경음악. 비워 두면 앞 장면의 음악을 서서히 끈다.
## 봄 동안 깔리는 곡을 넣어 둔다 (텃밭·원목·장터·부엌·평상·잔치가 같은 곡이라 장면이 바뀌어도 끊기지 않는다).
@export var music: AudioStream = preload("res://assets/audio/music/spring_theme.mp3")
## 돌아갈 당근 텃밭 장면
@export_file("*.tscn") var garden_scene_path: String = "res://scenes/garden/garden.tscn"
@export var trade_button_height: float = 84.0
@export var trade_font_size: int = 36
## 바꿨을 때 "+1 당근"이 떠오르는 높이(픽셀)와 시간(초)
@export var trade_pop_rise: float = 90.0
@export var trade_pop_duration: float = 0.8
@export var trade_pop_font_size: int = 36
@export var trade_pop_color: Color = Color(1, 0.84, 0.25)

var _settings: MarketSettings
var _trades: Array[MarketTrade] = []
var _trade_buttons: Array[Button] = []
var _trade_done_count: int = 0

@onready var _day_label: Label = %DayLabel
@onready var _merchant_name_label: Label = %MerchantNameLabel
@onready var _speech_label: Label = %SpeechLabel
@onready var _trade_list: VBoxContainer = %TradeList
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	Sound.play_music(music)
	RainOverlay.apply_daytime(self, true)
	_settings = GameData.get_market_settings()
	GameState.has_visited_market_today = true
	_day_label.text = DAY_TEXT_FORMAT % GameState.current_day
	_merchant_name_label.text = _settings.merchant_name
	_back_button.pressed.connect(_on_back_button_pressed)
	if not GameState.has_met_merchant:
		GameState.has_met_merchant = true
		_say(LINE_JOIN.join(_settings.first_meeting_lines))
	else:
		_say(_settings.pick_line(_settings.greeting_lines, _settings.get_market_index(GameState.current_day)))
	_trades = _settings.get_todays_trades(GameState.current_day)
	for i: int in _trades.size():
		var button: Button = Button.new()
		button.custom_minimum_size.y = trade_button_height
		button.add_theme_font_size_override("font_size", trade_font_size)
		button.pressed.connect(_on_trade_pressed.bind(i))
		_trade_list.add_child(button)
		_trade_buttons.append(button)
	_keep_focus_in_order()
	_refresh()
	if not _trade_buttons.is_empty():
		_trade_buttons[0].grab_focus()
	else:
		_back_button.grab_focus()


func _on_trade_pressed(index: int) -> void:
	var trade: MarketTrade = _trades[index]
	if GameState.get_market_trade_count(trade.id) >= _settings.daily_limit_per_trade:
		_say(_settings.sold_out_line)
		return
	if not GameState.trade_at_market(trade):
		Sound.play(SHORT_SOUND)
		_say(_settings.short_line)
		return
	Sound.play(TRADE_SOUND)
	_say(_settings.pick_line(_settings.trade_done_lines, _trade_done_count))
	_trade_done_count += 1
	FloatingText.pop(self, TRADE_POP_FORMAT % [trade.get_amount, trade.get_ingredient.display_name],
			_trade_buttons[index], trade_pop_rise, trade_pop_duration, trade_pop_font_size, trade_pop_color)
	_refresh()


## 거래 버튼 글을 새로 쓴다 (남은 횟수). 다 나간 거래도 선택은 되게 두고, 누르면 상인이 알려 준다.
func _refresh() -> void:
	for i: int in _trades.size():
		var trade: MarketTrade = _trades[i]
		var left: int = _settings.daily_limit_per_trade - GameState.get_market_trade_count(trade.id)
		var format: String = TRADE_FORMAT if left > 0 else SOLD_OUT_FORMAT
		var values: Array = [trade.give_ingredient.display_name, trade.give_amount,
				trade.get_ingredient.display_name, trade.get_amount]
		if left > 0:
			values.append(left)
		_trade_buttons[i].text = format % values


func _on_back_button_pressed() -> void:
	_say(_settings.farewell_line)
	_back_button.disabled = true
	# 인사를 잠깐 보여 주고 떠난다. 두 번째 값 false: 일시 정지 중에는 이 기다림도 멈춘다.
	await get_tree().create_timer(0.8, false).timeout
	get_tree().change_scene_to_file(garden_scene_path)


## 말풍선에 상인의 말을 띄운다. 한글이 낱말 중간에서 잘리지 않게 띄어쓰기 자리에서 줄을 바꿔 넣는다.
func _say(text: String) -> void:
	if text.is_empty():
		_speech_label.text = ""
		return
	var speech: String = SPEECH_FORMAT % [_settings.merchant_name, text.format({"name": GameState.player_name})]
	# 말풍선(장면에서 폭을 정해 둔 칸)의 폭에서 테두리 안쪽 여백을 뺀 만큼이 글 칸의 폭이다.
	var bubble: Control = _speech_label.get_parent() as Control
	var width: float = bubble.size.x - bubble.get_theme_stylebox("panel").get_minimum_size().x
	if width <= 0.0:
		_speech_label.text = speech
		return
	_speech_label.text = Korean.wrap_by_spaces(speech, _speech_label.get_theme_font("font"),
			_speech_label.get_theme_font_size("font_size"), width)


## 위아래로 거래 버튼 → 돌아가기 버튼 → 다시 첫 거래로 돈다 (게임패드).
func _keep_focus_in_order() -> void:
	var order: Array[Button] = _trade_buttons.duplicate()
	order.append(_back_button)
	for i: int in order.size():
		var button: Button = order[i]
		button.focus_neighbor_top = button.get_path_to(order[i - 1])
		button.focus_neighbor_bottom = button.get_path_to(order[(i + 1) % order.size()])
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
