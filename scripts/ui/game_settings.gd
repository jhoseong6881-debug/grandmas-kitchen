class_name GameSettings
extends RefCounted
## 게임 설정 (효과음 크기, 음악 크기, 날씨 소리 크기, 전체 화면). 세이브 파일과 따로 user://settings.cfg 에 저장한다.
## 그래서 새 게임을 시작해도 설정은 그대로 남는다.
## 게임이 켜질 때 PauseMenu 오토로드가 load_and_apply() 를 한 번 부른다. 설정 창(SettingsPanel)이 값을 바꾸고 save() 한다.

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "settings"
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
## 빗소리 같은 날씨 소리 (효과음과 따로 조절)
const WEATHER_BUS: StringName = &"Weather"
## 처음 켰을 때 소리 크기 (0 ~ 1)
const DEFAULT_SFX_VOLUME: float = 0.8
const DEFAULT_MUSIC_VOLUME: float = 0.7
const DEFAULT_WEATHER_VOLUME: float = 0.8

## 소리 크기 (0 = 끔, 1 = 가장 크게)
static var sfx_volume: float = DEFAULT_SFX_VOLUME
static var music_volume: float = DEFAULT_MUSIC_VOLUME
static var weather_volume: float = DEFAULT_WEATHER_VOLUME
static var is_fullscreen: bool = false


static func load_and_apply() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		sfx_volume = clampf(float(config.get_value(SECTION, "sfx_volume", DEFAULT_SFX_VOLUME)), 0.0, 1.0)
		music_volume = clampf(float(config.get_value(SECTION, "music_volume", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
		weather_volume = clampf(float(config.get_value(SECTION, "weather_volume", DEFAULT_WEATHER_VOLUME)), 0.0, 1.0)
		is_fullscreen = bool(config.get_value(SECTION, "is_fullscreen", false))
	apply()


static func save() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION, "sfx_volume", sfx_volume)
	config.set_value(SECTION, "music_volume", music_volume)
	config.set_value(SECTION, "weather_volume", weather_volume)
	config.set_value(SECTION, "is_fullscreen", is_fullscreen)
	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("설정을 저장하지 못했습니다: %s (%s)" % [SETTINGS_PATH, error_string(error)])


static func apply() -> void:
	_set_bus_volume(SFX_BUS, sfx_volume)
	_set_bus_volume(MUSIC_BUS, music_volume)
	_set_bus_volume(WEATHER_BUS, weather_volume)
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen \
			else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


## 0 ~ 1 크기를 버스의 데시벨로 바꿔 넣는다. 0이면 아예 끈다.
static func _set_bus_volume(bus_name: StringName, volume: float) -> void:
	var bus: int = AudioServer.get_bus_index(bus_name)
	if bus < 0:
		push_warning("오디오 버스 '%s' 가 없습니다 (default_bus_layout.tres 확인)" % bus_name)
		return
	AudioServer.set_bus_mute(bus, volume <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
