extends Node
## 효과음을 내는 오토로드. 프로젝트 설정 > 전역 > 오토로드 에 "Sound" 이름으로 등록해서 쓴다.
## data/sounds/ 의 SoundEffect(.tres)를 게임 시작 때 모두 읽고, 코드에서는 Sound.play(&"id") 로 부른다.
## 효과음은 "SFX" 버스로, 배경음악은 "Music" 버스로 보낸다 (버스 = 소리를 모아 크기를 한 번에 조절하는 통로.
## 화면 아래 "오디오" 탭이나 default_bus_layout.tres 에서 볼 수 있다). 나중에 설정 메뉴에서 버스마다 크기를 조절한다.
## 모든 버튼은 눌리면 저절로 click 소리를 낸다 (장면마다 따로 연결하지 않아도 된다).
## 소리 파일이 없거나 id가 없으면 조용히 넘어간다 (경고는 한 번만 띄운다).
## 배경음악: 장면마다 Sound.play_music(곡) 을 부른다. 곡이 바뀌면 서서히 바뀌고(크로스페이드), 끝나면 처음부터 다시 튼다.
## null 을 주면 음악을 서서히 끈다. 같은 곡을 다시 주면 끊지 않고 이어서 튼다.
## 계속 깔리는 소리(볶을 때 지글지글, 밥 지을 때 보글보글): Sound.start_loop(&"id") 로 켜고 stop_loop(&"id") 로 끈다.
## 효과음과 같은 SoundEffect(.tres)를 쓰고, 소리 파일을 처음부터 끝까지 되풀이한다. 게임이 일시 정지되면 같이 멈춘다.

const SOUNDS_DIR: String = "res://data/sounds/"
const RESOURCE_EXTENSIONS: PackedStringArray = ["tres", "res"]
const SFX_BUS: StringName = &"SFX"
const MUSIC_BUS: StringName = &"Music"
## 음악을 "들리지 않게" 할 때의 크기(데시벨)
const SILENT_DB: float = -40.0
## 버튼을 누르면 나는 소리
const BUTTON_CLICK_ID: StringName = &"click"

## 동시에 낼 수 있는 효과음 수. 다 차 있으면 가장 오래된 소리를 끊고 새 소리를 낸다.
@export var max_voices: int = 12
## 배경음악이 서서히 커지고 작아지는 시간(초)
@export var music_fade_duration: float = 1.2
## 깔리는 소리가 켜지고 꺼질 때 서서히 커지고 작아지는 시간(초)
@export var loop_fade_duration: float = 0.3

var _effects: Dictionary[StringName, SoundEffect] = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
## 이미 경고한 id (같은 경고를 계속 띄우지 않으려고)
var _warned_ids: Dictionary[StringName, bool] = {}
## 배경음악 플레이어 두 개를 번갈아 쓴다 (한쪽이 작아지는 동안 다른 쪽이 커진다)
var _music_players: Array[AudioStreamPlayer] = []
var _current_music_player: int = 0
var _current_music: AudioStream
## 지금 깔리고 있는 소리 (id → 플레이어)
var _loop_players: Dictionary[StringName, AudioStreamPlayer] = {}


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
	for i: int in 2:
		var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
		music_player.bus = MUSIC_BUS
		music_player.volume_db = SILENT_DB
		music_player.finished.connect(_on_music_finished.bind(music_player))
		add_child(music_player)
		_music_players.append(music_player)
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
## 배경음악을 바꾼다. 같은 곡이면 그대로 이어서 튼다. null 이면 서서히 끈다.
func play_music(stream: AudioStream) -> void:
	if stream == _current_music:
		return
	_current_music = stream
	var old_player: AudioStreamPlayer = _music_players[_current_music_player]
	_fade(old_player, SILENT_DB, true)
	if stream == null:
		return
	_current_music_player = (_current_music_player + 1) % _music_players.size()
	var new_player: AudioStreamPlayer = _music_players[_current_music_player]
	new_player.stream = stream
	new_player.volume_db = SILENT_DB
	new_player.play()
	_fade(new_player, 0.0, false)


func _fade(player: AudioStreamPlayer, to_db: float, stop_after: bool) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", to_db, music_fade_duration)
	if stop_after:
		tween.tween_callback(player.stop)


## 곡이 끝나면 (지금 트는 곡이면) 처음부터 다시 튼다.
func _on_music_finished(player: AudioStreamPlayer) -> void:
	if player == _music_players[_current_music_player] and player.stream == _current_music:
		player.play()


## 깔리는 소리를 켠다 (서서히 커진다). 이미 켜져 있으면 그대로 둔다. 없는 id면 조용히 넘어간다 (깔리는 소리가 없는 미니게임이 더 많다).
## offset_db: 소리 파일에 정한 크기(Volume Db)에서 더하거나 뺄 크기 (0 = 그대로)
func start_loop(id: StringName, offset_db: float = 0.0) -> void:
	if _loop_players.has(id):
		return
	var effect: SoundEffect = _effects.get(id)
	if effect == null or effect.pick_stream() == null:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = SFX_BUS
	# 이 오토로드는 일시 정지에도 돌지만, 깔리는 소리는 게임과 같이 멈춰야 한다.
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.stream = _make_looping(effect.pick_stream())
	player.pitch_scale = effect.pick_pitch()
	player.volume_db = SILENT_DB
	add_child(player)
	player.play()
	_loop_players[id] = player
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", effect.volume_db + offset_db, loop_fade_duration)


## 깔리는 소리 크기를 바로 바꾼다 (매 프레임 불러도 된다). offset_db 는 start_loop 와 같다.
func set_loop_volume(id: StringName, offset_db: float) -> void:
	var player: AudioStreamPlayer = _loop_players.get(id)
	if player != null:
		player.volume_db = _effects[id].volume_db + offset_db


## 깔리는 소리를 서서히 끈다. 켜져 있지 않으면 아무것도 안 한다.
func stop_loop(id: StringName) -> void:
	var player: AudioStreamPlayer = _loop_players.get(id)
	if player == null:
		return
	_loop_players.erase(id)
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", SILENT_DB, loop_fade_duration)
	tween.tween_callback(player.queue_free)


## 소리 파일이 끝까지 가면 처음으로 돌아가게 만든 복사본 (원본 파일 설정은 그대로 둔다)
func _make_looping(stream: AudioStream) -> AudioStream:
	var looped: AudioStream = stream.duplicate()
	if looped is AudioStreamWAV:
		var wav: AudioStreamWAV = looped as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = roundi(wav.get_length() * wav.mix_rate)
	elif "loop" in looped:
		looped.set("loop", true)
	return looped


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
