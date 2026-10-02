class_name PlantPicker
extends ChoicePicker
## "무엇을 심을까요?" 창. 빈 칸을 누르면 열려서, 그 밭에 심을 수 있는 작물을 보여 준다.
## 작물마다 자라는 날, 거두는 개수, 씨앗(심는 데 드는 재료)을 보여 주고, 씨앗이 모자라면 고를 수 없다.
## 고르면 closed(작물), 그만두면 closed(null).

signal closed(crop: Crop)

const TITLE_FORMAT: String = "%s에 무엇을 심을까요?"
const CROP_FORMAT: String = "%s  ·  %d일 뒤 %d개  ·  %s"
const FREE_SEED_TEXT: String = "씨앗 공짜"
const SEED_FORMAT: String = "%s %d개 필요 (가진 것 %d)"

var _crops: Array[Crop] = []


func _ready() -> void:
	super()
	chosen.connect(_on_chosen)


func open(place: GardenPlace) -> void:
	_crops = place.crops.duplicate()
	var texts: Array[String] = []
	var enabled: Array[bool] = []
	for crop: Crop in _crops:
		texts.append(CROP_FORMAT % [crop.ingredient.display_name, crop.grow_days, crop.harvest_amount, _seed_text(crop)])
		enabled.append(GameState.can_plant(crop))
	open_choices(TITLE_FORMAT % place.display_name, texts, enabled)


func _seed_text(crop: Crop) -> String:
	if crop.seed_ingredient == null or crop.seed_amount <= 0:
		return FREE_SEED_TEXT
	return SEED_FORMAT % [crop.seed_ingredient.display_name, crop.seed_amount,
			GameState.get_ingredient_count(crop.seed_ingredient.id)]


func _on_chosen(index: int) -> void:
	closed.emit(_crops[index] if index >= 0 else null)
