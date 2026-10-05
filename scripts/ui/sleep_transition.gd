class_name SleepTransition
extends Control
## 잠드는 장면. 저녁 평상에서 "잠자리에 들기"를 누르면 평상 장면 위에 띄운다.
## 밤하늘로 어두워짐 → (문자가 오는 밤이면 휴대폰이 울리고 말풍선이 하나씩, PhoneBook) →
## 달과 할머니 꿈 한 줄(DreamBook), z z z → 구석에서 저장 아이콘이 돌며 저장 → "N일째 아침"으로 밝아짐.
## play() 를 await 하면 다 끝난 뒤에 돌아온다. 그다음 장면 넘기기는 부른 쪽이 한다.
## 클릭, 스페이스/Enter, 게임패드 A 를 누르면 기다리는 시간을 건너뛴다 (저장은 건너뛰지 않는다).

const SAVING_TEXT: String = "저장 중…"
const SAVED_TEXT: String = "저장했어요"
const SAVE_FAILED_TEXT: String = "저장하지 못했어요. 다음 밤에 다시 저장해요."
const MORNING_FORMAT: String = "%s %d일째 아침"
const PHONE_SOUND: StringName = &"phone_buzz"

## 꿈 문구 모음
@export var dream_book: DreamBook = preload("res://data/story/dreams.tres")
## 휴대폰 문자 모음 (주인공 이야기)
@export var phone_book: PhoneBook = preload("res://data/story/phone_messages.tres")
## 휴대폰: 나타나는 시간, 말풍선 사이 시간, 답장 글자 하나 쓰는/지우는 시간, 다 보여 준 뒤 기다리는 시간(초)
@export var phone_fade_duration: float = 0.4
@export var phone_bubble_interval: float = 1.1
@export var phone_type_interval: float = 0.09
@export var phone_erase_interval: float = 0.035
@export var phone_hold: float = 1.6
## 말풍선 글자 크기, 가장 넓은 폭, 색 (받은 것 / 내가 보낸 것)
@export var bubble_font_size: int = 36
@export var bubble_max_width: float = 420.0
@export var bubble_color: Color = Color(0.3, 0.3, 0.35)
@export var my_bubble_color: Color = Color(0.95, 0.85, 0.45)
@export var bubble_text_color: Color = Color(0.98, 0.94, 0.84)
@export var my_bubble_text_color: Color = Color(0.2, 0.15, 0.1)
## 밤하늘 색과 아침 색 (그림이 생기기 전 임시 배경)
@export var night_color: Color = Color(0.1, 0.12, 0.25)
@export var morning_color: Color = Color(0.98, 0.9, 0.7)
## 어두워지는 시간, 꿈 글이 나타나는 시간, 꿈을 보여 주는 시간(초)
@export var fade_in_duration: float = 0.8
@export var dream_fade_duration: float = 0.6
@export var dream_hold: float = 2.4
## 저장이 금방 끝나도 저장 아이콘을 이만큼은 돌린다(초). 너무 빨리 지나가면 저장한 줄 모른다.
@export var save_spin_min: float = 0.8
## 저장 아이콘이 도는 빠르기 (1초에 도는 각도, 라디안)
@export var save_spin_speed: float = 4.0
## z z z 가 위아래로 둥실거리는 높이(픽셀)와 한 번 오르내리는 시간(초)
@export var zzz_bob_height: float = 12.0
@export var zzz_bob_duration: float = 0.9
## 아침으로 밝아지는 시간과, 밝아진 뒤 "N일째 아침"을 보여 주는 시간(초)
@export var morning_fade_duration: float = 0.9
@export var morning_hold: float = 0.8

var _is_skipping: bool = false
var _is_saving: bool = false

@onready var _sky: ColorRect = %Sky
@onready var _night_content: Control = %NightContent
@onready var _dream_label: Label = %DreamLabel
@onready var _zzz_label: Label = %ZzzLabel
@onready var _save_icon: Control = %SaveIcon
@onready var _save_label: Label = %SaveLabel
@onready var _morning_label: Label = %MorningLabel
@onready var _phone: Control = %Phone
@onready var _sender_label: Label = %SenderLabel
@onready var _bubbles: VBoxContainer = %Bubbles
@onready var _draft_label: Label = %DraftLabel


func _ready() -> void:
	_save_icon.pivot_offset = _save_icon.size / 2.0
	hide()


## night: 몇째 날 밤인지 (꿈 문구를 고르는 데 쓴다). next_day: 아침에 보여 줄 날짜.
## save: 저장하는 함수. 성공하면 true 를 돌려준다 (예: GameState.save_game).
## dream_text: 꿈 한 줄 대신 보여 줄 글 (할머니 회상이 있는 밤). show_morning: false 면 아침으로 밝아지기 전에 끝낸다.
func play(night: int, next_day: int, save: Callable, dream_text: String = "", show_morning: bool = true) -> void:
	_is_skipping = false
	_sky.color = night_color
	var phone_message: PhoneMessage = phone_book.get_message(GameState.current_season, night) \
			if phone_book != null else null
	if not dream_text.is_empty():
		_dream_label.text = dream_text
	elif phone_message != null and not phone_message.after_text.is_empty():
		_dream_label.text = _with_name(phone_message.after_text)
	else:
		_dream_label.text = _with_name(dream_book.get_line(night)) if dream_book != null else ""
	_phone.hide()
	_dream_label.modulate.a = 0.0
	_night_content.modulate.a = 1.0
	_save_icon.hide()
	_save_label.text = ""
	_morning_label.text = MORNING_FORMAT % [GameData.get_season_name(), next_day]
	_morning_label.modulate.a = 0.0
	modulate.a = 0.0
	show()
	# 포커스를 가져와야 A 버튼이 뒤에 있는 평상 버튼으로 새지 않는다.
	grab_focus()
	_bob_zzz()

	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)
	await tween.finished
	if phone_message != null:
		await _show_phone(phone_message)
	tween = create_tween()
	tween.tween_property(_dream_label, "modulate:a", 1.0, dream_fade_duration)
	await tween.finished

	_save_icon.show()
	_save_label.text = SAVING_TEXT
	_is_saving = true
	var is_saved: bool = save.call()
	await _wait(save_spin_min)
	_is_saving = false
	_save_icon.rotation = 0.0
	_save_label.text = SAVED_TEXT if is_saved else SAVE_FAILED_TEXT

	await _wait(dream_hold)
	if not show_morning:
		return

	tween = create_tween().set_parallel()
	tween.tween_property(_night_content, "modulate:a", 0.0, morning_fade_duration)
	tween.tween_property(_sky, "color", morning_color, morning_fade_duration)
	tween.tween_property(_morning_label, "modulate:a", 1.0, morning_fade_duration)
	await tween.finished
	await _wait(morning_hold)


## 휴대폰이 울리고, 말풍선이 하나씩 뜨고, 답장을 썼다가 지운 뒤 휴대폰을 내려놓는다.
## 누르면 휴대폰 장면만 건너뛴다 (그다음 꿈 글은 평소처럼 보여 준다).
func _show_phone(message: PhoneMessage) -> void:
	_is_skipping = false
	for child: Node in _bubbles.get_children():
		child.queue_free()
	_sender_label.text = message.sender
	_draft_label.text = ""
	_phone.modulate.a = 0.0
	_phone.show()
	Sound.play(PHONE_SOUND)
	var tween: Tween = create_tween()
	tween.tween_property(_phone, "modulate:a", 1.0, phone_fade_duration)
	await tween.finished
	for text: String in message.messages:
		await _wait(phone_bubble_interval)
		var is_mine: bool = text.begins_with(PhoneMessage.MY_PREFIX)
		_add_bubble(text.trim_prefix(PhoneMessage.MY_PREFIX).strip_edges() if is_mine else _with_name(text), is_mine)
		if not is_mine:
			Sound.play(PHONE_SOUND)
	if not message.draft_text.is_empty():
		await _wait(phone_bubble_interval)
		for i: int in message.draft_text.length():
			_draft_label.text = message.draft_text.left(i + 1)
			await _wait(phone_type_interval)
		await _wait(phone_hold)
		while not _draft_label.text.is_empty():
			_draft_label.text = _draft_label.text.left(-1)
			await _wait(phone_erase_interval)
	await _wait(phone_hold)
	tween = create_tween()
	tween.tween_property(_phone, "modulate:a", 0.0, phone_fade_duration)
	await tween.finished
	_phone.hide()
	_is_skipping = false


## 말풍선 하나. 받은 것은 왼쪽, 내가 보낸 것은 오른쪽.
func _add_bubble(text: String, is_mine: bool) -> void:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", bubble_font_size)
	label.add_theme_color_override("font_color", my_bubble_text_color if is_mine else bubble_text_color)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = my_bubble_color if is_mine else bubble_color
	style.set_corner_radius_all(18)
	style.set_content_margin_all(15)
	label.add_theme_stylebox_override("normal", style)
	label.size_flags_horizontal = Control.SIZE_SHRINK_END if is_mine else Control.SIZE_SHRINK_BEGIN
	_bubbles.add_child(label)
	# 장면에 들어간 뒤에야 테마 글꼴을 알 수 있어서, 넣은 다음에 줄을 나눈다.
	label.text = Korean.wrap_by_spaces(text, label.get_theme_font("font"), bubble_font_size, bubble_max_width)


func _with_name(text: String) -> String:
	return text.format({"name": GameState.player_name})


func _process(delta: float) -> void:
	if _is_saving:
		_save_icon.rotation += save_spin_speed * delta


func _gui_input(event: InputEvent) -> void:
	var is_click: bool = event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT
	if is_click or event.is_action_pressed("ui_accept"):
		_is_skipping = true
		accept_event()


## seconds 초 기다린다. 눌러서 건너뛰면 바로 끝난다. 일시 정지 중에는 시간이 흐르지 않는다.
func _wait(seconds: float) -> void:
	var waited: float = 0.0
	while waited < seconds and not _is_skipping:
		await get_tree().process_frame
		if not get_tree().paused:
			waited += get_process_delta_time()


func _bob_zzz() -> void:
	var home_y: float = _zzz_label.position.y
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_zzz_label, "position:y", home_y - zzz_bob_height, zzz_bob_duration / 2.0) \
			.set_trans(Tween.TRANS_SINE)
	tween.tween_property(_zzz_label, "position:y", home_y, zzz_bob_duration / 2.0).set_trans(Tween.TRANS_SINE)
