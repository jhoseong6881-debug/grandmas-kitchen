class_name GoalBoard
extends PanelContainer
## 목표판. 아침 텃밭과 점심 부엌 왼쪽에 늘 떠 있으면서 "다음에 무엇이 있는지"를 보여 준다:
## 이번 계절 할머니 노트 수와 노트를 가진 손님, 다음 가게 단계까지 남은 소문, 다음 장날,
## 잔치 준비 (장보기 목록을 받은 뒤), 계절 잔치까지 남은 날.
## GameState 의 시그널(노트, 소문, 날짜, 잔치 준비)을 듣고 스스로 다시 쓴다. 누를 수 없는 판이라 입력은 지나간다.

const TITLE_TEXT: String = "봄 목표"
const NOTES_FORMAT: String = "할머니 노트  %d / %d"
const HOLDER_FORMAT: String = "  노트를 가진 손님: %s"
const HOLDER_SEPARATOR: String = " · "
## 아직 만나지 않은 손님은 이름 대신 이렇게 묶어서 보여 준다 (예: "??? 3")
const UNKNOWN_HOLDER_FORMAT: String = "??? %d"
const NOTES_DONE_TEXT: String = "올봄 노트를 다 모았어요!"
const SHOP_FORMAT: String = "%s까지 소문 %d"
const SHOP_MAX_FORMAT: String = "%s!"
const MARKET_TODAY_TEXT: String = "오늘은 장날!"
const MARKET_FORMAT: String = "장날까지 %d일"
const FEAST_TODAY_TEXT: String = "오늘 저녁 봄 잔치!"
const FEAST_FORMAT: String = "봄 잔치까지 %d일"
const FEAST_PREP_FORMAT: String = "잔치 준비  %d / %d"
const FEAST_PREP_DONE_TEXT: String = "잔치 준비 끝! 상다리가 휘어지겠어요"

@onready var _title_label: Label = %Title
@onready var _notes_label: Label = %NotesLabel
@onready var _holder_label: Label = %HolderLabel
@onready var _shop_label: Label = %ShopLabel
@onready var _market_label: Label = %MarketLabel
@onready var _feast_label: Label = %FeastLabel
@onready var _feast_prep_label: Label = %FeastPrepLabel


func _ready() -> void:
	GameState.recipe_unlocked.connect(_refresh.unbind(1))
	GameState.reputation_changed.connect(_refresh.unbind(1))
	GameState.day_changed.connect(_refresh.unbind(1))
	GameState.feast_prep_changed.connect(_refresh)
	_title_label.text = TITLE_TEXT
	_refresh()


func _refresh() -> void:
	_refresh_notes()
	_refresh_shop()
	_refresh_market_and_feast()


## 이번 계절 노트 수와, 아직 노트를 가진 손님 (만난 손님만 이름으로)
func _refresh_notes() -> void:
	var total: int = 0
	var found: int = 0
	for recipe: Recipe in GameData.get_all_recipes():
		if recipe.note_season != GameState.current_season:
			continue
		total += 1
		if GameState.is_recipe_unlocked(recipe.id):
			found += 1
	_notes_label.text = NOTES_FORMAT % [found, total]
	var holders: PackedStringArray = []
	var unknown_count: int = 0
	for guest: AnimalGuest in GameData.get_all_guests():
		var has_page: bool = guest.note_recipes.any(func(recipe: Recipe) -> bool:
				return recipe.note_season == GameState.current_season and not GameState.is_recipe_unlocked(recipe.id))
		if not has_page:
			continue
		if GameState.has_met_guest(guest.id):
			holders.append(guest.display_name)
		else:
			unknown_count += 1
	if unknown_count > 0:
		holders.append(UNKNOWN_HOLDER_FORMAT % unknown_count)
	if found >= total:
		_holder_label.text = NOTES_DONE_TEXT
	else:
		_holder_label.text = HOLDER_FORMAT % HOLDER_SEPARATOR.join(holders)
	_holder_label.visible = found >= total or not holders.is_empty()


func _refresh_shop() -> void:
	var settings: ReputationSettings = GameData.get_reputation_settings()
	var tier: int = GameState.get_shop_tier()
	var next_threshold: int = settings.get_next_threshold(tier)
	if next_threshold > settings.get_threshold(tier):
		_shop_label.text = SHOP_FORMAT % [settings.get_shop_name(tier + 1), next_threshold - GameState.reputation]
	else:
		_shop_label.text = SHOP_MAX_FORMAT % settings.get_shop_name(tier)


## 다음 장날 (계절이 끝나기 전에 있을 때만)과 계절 잔치까지 남은 날
func _refresh_market_and_feast() -> void:
	var day: int = GameState.current_day
	var ending: SeasonEnding = GameData.get_season_ending()
	var last_day: int = ending.last_day if ending != null else day
	var market: MarketSettings = GameData.get_market_settings()
	var next_market_day: int = -1
	for d: int in range(day, last_day + 1):
		if market.is_market_day(d):
			next_market_day = d
			break
	_market_label.visible = next_market_day >= 0
	if next_market_day >= 0:
		_market_label.text = MARKET_TODAY_TEXT if next_market_day == day else MARKET_FORMAT % (next_market_day - day)
	var prep: FeastPrep = ending.feast_prep if ending != null else null
	_feast_prep_label.visible = prep != null and GameState.is_feast_prep_announced
	if _feast_prep_label.visible:
		var delivered: int = GameState.get_feast_delivered_total()
		_feast_prep_label.text = FEAST_PREP_DONE_TEXT if delivered >= prep.get_total() \
				else FEAST_PREP_FORMAT % [delivered, prep.get_total()]
	_feast_label.visible = ending != null
	_feast_label.text = FEAST_TODAY_TEXT if day >= last_day else FEAST_FORMAT % (last_day - day)
