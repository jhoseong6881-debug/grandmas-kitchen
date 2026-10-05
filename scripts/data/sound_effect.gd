class_name SoundEffect
extends Resource
## 효과음 하나. data/sounds/ 폴더에 .tres 로 하나씩 만들고, 코드에서는 Sound.play(&"id") 로 부른다.
## 소리를 바꾸고 싶으면 Streams 칸의 소리 파일만 바꾸면 된다. 코드는 고칠 필요가 없다.
## 파일을 여러 개 넣으면 부를 때마다 그중 하나를 골라서, 같은 소리가 반복돼도 덜 질린다.

## 코드에서 부르는 이름 (예: &"hit_chop")
@export var id: StringName
## 소리 파일 (.ogg, .wav). 여러 개면 무작위로 하나를 고른다.
@export var streams: Array[AudioStream] = []
## 소리 크기 (데시벨). 0 = 파일 그대로, -6 = 절반쯤, +6 = 두 배쯤
@export_range(-40.0, 12.0, 0.5) var volume_db: float = 0.0
## 부를 때마다 높낮이를 이 정도까지 무작위로 바꾼다 (0 = 그대로, 0.1 = 위아래로 10%)
@export_range(0.0, 0.5, 0.01) var pitch_variation: float = 0.05
## 이 소리를 보낼 버스 (설정 창에서 크기를 따로 조절하는 묶음). 보통은 효과음 "SFX",
## 빗소리 같은 날씨 소리는 "Weather" (설정 창의 "날씨 소리" 막대로 조절한다).
@export var bus: StringName = &"SFX"


func pick_stream() -> AudioStream:
	return streams.pick_random() if not streams.is_empty() else null


func pick_pitch() -> float:
	return 1.0 + randf_range(-pitch_variation, pitch_variation)
