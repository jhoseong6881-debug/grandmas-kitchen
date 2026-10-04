class_name DailyMusic
extends Resource
## 날마다 바뀌는 배경음악 목록. data/music/ 에 .tres 로 만든다.
## 하루 동안은 한 곡만 튼다 (텃밭·원목·부엌·평상이 같은 곡이라 장면이 바뀌어도 끊기지 않는다).
## 1일째는 첫 곡, 2일째는 둘째 곡… 다 돌면 처음부터 다시. 곡을 더하거나 순서를 바꾸려면 Tracks 칸만 바꾸면 된다.

@export var tracks: Array[AudioStream] = []


## 오늘 틀 곡. 봄비 오는 날 낮 장면이면 봄비 곡(RainSettings.rain_music), 아니면 그날 곡.
## is_daytime: 낮 장면인지 (텃밭, 버섯 원목, 부엌). 저녁 평상은 해 질 녘에 비가 그쳐서 false.
func get_today_track(is_daytime: bool) -> AudioStream:
	var rain: RainSettings = GameData.get_rain_settings()
	if is_daytime and GameState.is_raining_today and rain.rain_music != null:
		return rain.rain_music
	return get_track(GameState.current_day)


## day: 몇째 날인지 (1부터). 곡이 없으면 null (음악을 서서히 끈다).
func get_track(day: int) -> AudioStream:
	if tracks.is_empty():
		return null
	return tracks[posmod(day - 1, tracks.size())]
