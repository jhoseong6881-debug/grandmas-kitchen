extends Control
## 아침 버섯 원목 장면. 당근 텃밭에서 건너온다. 다 자란 원목에서 버섯을 거두고, 빈 원목에 버섯을 심는다.
## 칸을 다루는 일은 PlotRow 가 맡는다. 다 둘러보면 당근 텃밭으로 돌아가서 부엌으로 간다.

const DAY_TEXT_FORMAT: String = "%d일째 아침"
const WELCOME_TEXT: String = "숲 그늘의 버섯 원목이에요. 버섯 하나를 종균으로 심으면 며칠 뒤 여러 개가 나요."
const PLANTED_FORMAT: String = "%s%s 심었어요. %d일 뒤에 거둘 수 있어요."
const HARVEST_POP_FORMAT: String = "+%d %s"

## 이 장면의 배경음악. 비워 두면 앞 장면의 음악을 서서히 끈다.
@export var music: AudioStream
## 돌아갈 당근 텃밭 장면
@export_file("*.tscn") var garden_scene_path: String = "res://scenes/garden/garden.tscn"
## 거둘 때 "+3 버섯"이 떠오르는 높이(픽셀)와 시간(초)
@export var harvest_pop_rise: float = 90.0
@export var harvest_pop_duration: float = 0.8
@export var harvest_pop_font_size: int = 36
@export var harvest_pop_color: Color = Color(1, 0.84, 0.25)

@onready var _day_label: Label = %DayLabel
@onready var _status_label: Label = %StatusLabel
@onready var _plot_row: PlotRow = %PlotRow
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	Sound.play_music(music)
	_day_label.text = DAY_TEXT_FORMAT % GameState.current_day
	_status_label.text = WELCOME_TEXT
	_back_button.pressed.connect(get_tree().change_scene_to_file.bind(garden_scene_path))
	_plot_row.harvested.connect(_on_harvested)
	_plot_row.planted.connect(_on_planted)
	_focus_next_thing_to_do()


func _on_harvested(crop: Crop, plot_button: Button) -> void:
	FloatingText.pop(self, HARVEST_POP_FORMAT % [crop.harvest_amount, crop.ingredient.display_name], plot_button,
			harvest_pop_rise, harvest_pop_duration, harvest_pop_font_size, harvest_pop_color)
	_focus_next_thing_to_do()


func _on_planted(crop: Crop, _plot_button: Button) -> void:
	var crop_name: String = crop.ingredient.display_name
	_status_label.text = PLANTED_FORMAT % [crop_name, Korean.object_particle(crop_name), crop.grow_days]
	_focus_next_thing_to_do()


## 할 일이 있는 원목이 있으면 그걸, 없으면 돌아가기 버튼을 선택해 둔다. (게임패드 A 버튼만으로도 진행)
func _focus_next_thing_to_do() -> void:
	var plot_button: Button = _plot_row.get_next_action_button()
	(plot_button if plot_button != null else _back_button).grab_focus()
