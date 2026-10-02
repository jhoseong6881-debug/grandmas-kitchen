extends Node
## 효과음을 내는 오토로드. 프로젝트 설정 > 전역 > 오토로드 에 "Sound" 이름으로 등록해서 쓴다.
## data/sounds/ 의 SoundEffect(.tres)를 게임 시작 때 모두 읽고, 코드에서는 Sound.play(&"id") 로 부른다.
## 효과음은 "SFX" 버스로, 배경음악은 "Music" 버스로 보낸다 (버스 = 소리를 모아 크기를 한 번에 조절하는 통로.
## 화면 아래 "오디오" 탭이나 default_bus_layout.tres 에서 볼 수 있다). 나중에 설정 메뉴에서 버스마다 크기를 조절한다.
## 모든 버튼은 눌리면 저절로 click 소리를 낸다 (장면마다 따로 연결하지 않아도 된다).
## 소리 파일이 없거나 id가 없으면 조용히 넘어간다 (경고는 한 번만 띄운다).

const SOUNDS_DIR: String = "res://data/sounds/"
const RESOURCE_EXTENSIONS: PackedStringArray = ["tres", "res"]
const SFX_BUS: StringName = &"SFX"
## 버튼을 누르면 나는 소리
const BUTTON_CLICK_ID: StringName = &"click"

## 동시에 낼 수 있는 효과음 수. 다 차 있으면 가장 오래된 소리를 끊고 새 소리를 낸다.
@export var max_voices: int = 12

var _effects: Dictionary[StringName, SoundEffect] = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
## 이미 경고한 id (같은 경고를 계속 띄우지 않으려고)
var _warned_ids: Dictionary[StringName, bool] = {}


func _ready() -> void:
	# 일시 정지 메뉴에서도 버튼 소리가 나야 한다.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for file_name: String in ResourceLoader.list_directory(SOUNDS_DIR):
		if file_name.get_extension() not in RESOURCE_EXTENSIONS:
			continue
		var effect: SoundEffect = load(SOUNDS_DIR + file_name) as SoundEffect
		if effect == null or effect.id.is_empty():
			push_warning("효과음 파일을 읽지 못했거나 id가 비어 있습니다: %s" % (SOUNDS_DIR + file_name))
			continue
		_effects[effect.id] = effect
	for i: int in max_voices:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_players.append(player)
	# 이 오토로드보다 먼저 만들어진 버튼(다른 오토로드의 버튼 등)에도 연결하고, 앞으로 생길 버튼은 생길 때 연결한다.
	_connect_buttons_in(get_tree().root)
	get_tree().node_added.connect(_on_node_added)


## 효과음을 낸다. 없는 id면 조용히 넘어간다.
func play(id: StringName) -> void:
	var effect: SoundEffect = _effects.get(id)
	if effect == null:
		_warn_once(id)
		return
	var stream: AudioStream = effect.pick_stream()
	if stream == null:
		return
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.volume_db = effect.volume_db
	player.pitch_scale = effect.pick_pitch()
	player.play()


## id 소리가 있으면 그걸, 없으면 fallback_id 소리를 낸다. (예: 미니게임마다 다른 소리가 없으면 공통 소리)
func play_or(id: StringName, fallback_id: StringName) -> void:
	play(id if _effects.has(id) else fallback_id)


func has_effect(id: StringName) -> bool:
	return _effects.has(id)


func _connect_buttons_in(node: Node) -> void:
	_on_node_added(node)
	for child: Node in node.get_children():
		_connect_buttons_in(child)


func _on_node_added(node: Node) -> void:
	# 같은 버튼이 장면 트리에 다시 들어와도(옮겨 붙이기 등) 소리가 두 번 나지 않게 한 번만 연결한다.
	if node is BaseButton and not (node as BaseButton).pressed.is_connected(_on_button_pressed):
		(node as BaseButton).pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	play(BUTTON_CLICK_ID)


func _warn_once(id: StringName) -> void:
	if _warned_ids.has(id):
		return
	_warned_ids[id] = true
	push_warning("효과음 '%s' 이(가) data/sounds/ 에 없습니다" % id)
