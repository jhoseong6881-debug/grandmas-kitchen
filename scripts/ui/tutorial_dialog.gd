class_name TutorialDialog
extends CanvasLayer
## 처음 하는 사람에게 화면마다 한 번씩 보여 주는 안내 대화창. 오른쪽에 안내 손님 얼굴이 크게, 아래에 이름표가 달린 글 상자.
## 글은 data/story/tutorial.tres (TutorialBook) 에 있다. 화면 쪽에서는 TutorialDialog.show_once(self, &"menu") 처럼 부르기만 한다.
## 클릭, 스페이스/Enter, 게임패드 A 로 한 줄씩 넘긴다. 글자가 다 나오기 전에 누르면 그 줄을 바로 다 보여 준다.
## 열려 있는 동안 뒤 화면은 눌리지 않는다 (일시 정지 버튼만 지나간다). 포커스는 건드리지 않아서 닫히면 하던 대로 이어진다.
## 얼굴 그림이 없으면 임시 사각형을 보여 준다.

## 다 보고 닫혔을 때
signal closed

const SCENE_PATH: String = "res://scenes/ui/tutorial_dialog.tscn"
## 자동 플레이 봇이 열린 안내를 찾을 때 쓰는 그룹
const GROUP: StringName = &"tutorial_dialog"

## 1초에 나오는 글자 수
@export var chars_per_second: float = 40.0
## 나타나고 사라지는 시간(초)
@export var fade_duration: float = 0.2
## "다음" 표시가 깜빡이는 빠르기
@export var next_mark_blink_speed: float = 4.0

var _tip: TutorialTip
var _guide: AnimalGuest
var _line_index: int = -1
var _shown_chars: float = 0.0
var _blink_time: float = 0.0
var _is_closing: bool = false

@onready var _root: Control = %Root
@onready var _portrait: TextureRect = %Portrait
@onready var _portrait_placeholder: ColorRect = %PortraitPlaceholder
@onready var _name_label: Label = %NameLabel
@onready var _text_label: Label = %TextLabel
@onready var _next_mark: Label = %NextMark


## tip_id 안내를 아직 안 봤으면 화면 위에 띄우고 다 볼 때까지 기다린다. 이미 봤거나 안내가 없으면 바로 끝난다.
## host: 부르는 화면 (그 화면이 속한 장면에 붙여서, 장면이 바뀌면 같이 사라지게 한다)
static func show_once(host: Node, tip_id: StringName) -> void:
	if GameState.has_seen_tutorial(tip_id):
		return
	var setup: StartingSetup = GameData.get_starting_setup()
	var book: TutorialBook = setup.tutorial if setup != null else null
	var tip: TutorialTip = book.get_tip(tip_id) if book != null else null
	if tip == null or tip.lines.is_empty() or book.guide == null or host == null:
		return
	GameState.mark_tutorial_seen(tip_id)
	var dialog: TutorialDialog = (load(SCENE_PATH) as PackedScene).instantiate()
	var scene_root: Node = host.owner if host.owner != null else host
	scene_root.add_child(dialog)
	dialog._open(book.guide, tip)
	await dialog.closed


## 아무 열린 안내가 있는지 (자동 플레이 봇용)
static func is_any_open() -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree != null and not tree.get_nodes_in_group(GROUP).is_empty()


func _ready() -> void:
	add_to_group(GROUP)


func _open(guide: AnimalGuest, tip: TutorialTip) -> void:
	_tip = tip
	_guide = guide
	_name_label.text = guide.display_name
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, fade_duration)
	_show_line(0)


func _show_line(index: int) -> void:
	_line_index = index
	# 줄마다 표정을 바꾼다 (그림 크기가 같아서 얼굴 자리는 흔들리지 않는다)
	var texture: Texture2D = _guide.get_portrait(_tip.get_line_expression(index))
	_portrait.texture = texture
	_portrait.visible = texture != null
	_portrait_placeholder.visible = texture == null
	var text: String = _tip.lines[index].format({"name": GameState.player_name})
	_text_label.text = Korean.wrap_by_spaces(text, _text_label.get_theme_font("font"),
			_text_label.get_theme_font_size("font_size"), _text_label.size.x)
	_shown_chars = 0.0
	_text_label.visible_characters = 0
	_next_mark.hide()


func _is_typing() -> bool:
	return _text_label.visible_characters >= 0 and _text_label.visible_characters < _text_label.get_total_character_count()


func _process(delta: float) -> void:
	if _tip == null or _is_closing:
		return
	if _is_typing():
		_shown_chars += chars_per_second * delta
		_text_label.visible_characters = int(_shown_chars)
		if not _is_typing():
			_text_label.visible_characters = -1
		return
	_blink_time += delta
	_next_mark.visible = fmod(_blink_time * next_mark_blink_speed, 2.0) < 1.0


## 다음 줄로 (글자가 나오는 중이면 그 줄을 다 보여 준다). 다 봤으면 닫는다. 자동 플레이 봇도 부른다.
func advance() -> void:
	if _tip == null or _is_closing:
		return
	if _is_typing():
		_text_label.visible_characters = -1
		return
	if _line_index + 1 < _tip.lines.size():
		_show_line(_line_index + 1)
		return
	_is_closing = true
	remove_from_group(GROUP)
	var tween: Tween = create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, fade_duration)
	await tween.finished
	closed.emit()
	queue_free()


## 뒤 화면보다 먼저 입력을 받는다. 넘기기 입력이면 넘기고, 일시 정지 말고는 뒤 화면에 보내지 않는다.
func _input(event: InputEvent) -> void:
	if _is_closing or event is InputEventMouseMotion or event.is_action(InputDefaults.PAUSE_ACTION):
		return
	var is_click: bool = event is InputEventMouseButton and event.pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if is_click or event.is_action_pressed("ui_accept"):
		advance()
	get_viewport().set_input_as_handled()
