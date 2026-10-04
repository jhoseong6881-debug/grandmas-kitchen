class_name RainSettings
extends Resource
## 봄비 오는 날. data/weather/rain_settings.tres 하나로 정한다.
## 정해 둔 날(rain_days)에는 꼭 오고, random_from_day 부터는 날마다 rain_chance 확률로 온다.
## 비 오는 날: 아침 텃밭에 빗줄기와 안내 한 줄, 낮 동안 빗소리, 손님은 우비를 입고 와서 따뜻한 요리(warm_recipes)를 더 찾는다.
## 해 질 녘에 비가 그친다 (저녁 평상은 평소와 같다). 작물이 자라는 건 비와 상관없다.

## 꼭 비가 오는 날
@export var rain_days: Array[int] = [3]
## 이날부터는 날마다 rain_chance 확률로 비가 온다
@export var random_from_day: int = 4
@export_range(0.0, 1.0) var rain_chance: float = 0.2
## 이틀 연달아 비가 와도 되는지 (꼭 오는 날은 상관없이 온다)
@export var allow_two_days_in_a_row: bool = false
## 비가 오지 않는 날 (봄 잔치 날)
@export var dry_days: Array[int] = [15]
## 비 오는 날 아침 텃밭 안내 글
@export_multiline var morning_text: String = ""
## 해 지는 장면에서 "해가 뉘엿뉘엿…" 대신 보여 주는 글
@export var sunset_text: String = ""
## 비 오는 날 손님이 더 찾는 따뜻한 요리
@export var warm_recipes: Array[Recipe] = []
## 손님이 따뜻한 요리를 찾을 확률 (낼 수 있고 싫어하지 않는 따뜻한 요리가 있을 때)
@export_range(0.0, 1.0) var warm_order_chance: float = 0.7
## 낮 동안 깔리는 빗소리 (data/sounds/ 의 id). 해 지는 장면에서 서서히 꺼진다.
@export var rain_sound: StringName = &"rain"
## 빗소리가 꺼지는 시간(초)
@export var rain_sound_fade: float = 2.5
## 그림이 없을 때 손님에게 씌우는 임시 우비 색
@export var raincoat_color: Color = Color(1.0, 0.82, 0.2)


## day 에 비가 오는지 정한다. rained_yesterday: 어제 비가 왔는지 (이틀 연달아 오지 않게)
func will_rain(day: int, rained_yesterday: bool) -> bool:
	if day in dry_days:
		return false
	if day in rain_days:
		return true
	if day < random_from_day or (rained_yesterday and not allow_two_days_in_a_row):
		return false
	return randf() < rain_chance
