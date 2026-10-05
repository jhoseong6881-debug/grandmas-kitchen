extends Node
## data/ 폴더의 재료, 레시피, 동물 손님, 작물, 밭, 고명, 오늘의 부탁, 계절 .tres 파일을 게임 시작 때 모두 읽어 id로 찾을 수 있게 하는 오토로드.
## 계절마다 다른 것(손님, 날마다 바뀌는 곡, 비 오는 날, 장터, 계절 마무리)은 지금 계절의 SeasonData 에서 꺼내 준다.
## 프로젝트 설정 > 전역 > 오토로드 에 "GameData" 이름으로 등록해서 쓴다.
## 읽기 전용 원본 데이터만 다룬다. 플레이 중 바뀌는 상태는 GameState 가 맡는다.

const INGREDIENTS_DIR: String = "res://data/ingredients/"
const RECIPES_DIR: String = "res://data/recipes/"
const GUESTS_DIR: String = "res://data/guests/"
const CROPS_DIR: String = "res://data/crops/"
const PLACES_DIR: String = "res://data/places/"
const GARNISHES_DIR: String = "res://data/garnishes/"
const REQUESTS_DIR: String = "res://data/requests/"
const REGULAR_SETTINGS_PATH: String = "res://data/regular_settings.tres"
const REPUTATION_SETTINGS_PATH: String = "res://data/reputation_settings.tres"
const STARTING_SETUP_PATH: String = "res://data/starting_setup.tres"
const MENU_SETTINGS_PATH: String = "res://data/menu_settings.tres"
## 계절 데이터(SeasonData) 폴더. 같은 폴더의 계절 마무리·잔치 준비 파일은 계절 데이터가 가리키므로 여기서는 건너뛴다.
const SEASONS_DIR: String = "res://data/seasons/"
const RESOURCE_EXTENSIONS: PackedStringArray = ["tres", "res"]

var _ingredients: Dictionary[StringName, Ingredient] = {}
var _recipes: Dictionary[StringName, Recipe] = {}
var _guests: Dictionary[StringName, AnimalGuest] = {}
var _crops: Dictionary[StringName, Crop] = {}
var _places: Dictionary[StringName, GardenPlace] = {}
var _garnishes: Dictionary[StringName, Garnish] = {}
var _requests: Dictionary[StringName, GuestRequest] = {}
var _regular_settings: RegularSettings
var _reputation_settings: ReputationSettings
var _menu_settings: MenuSettings
var _starting_setup: StartingSetup
var _seasons: Dictionary[Season.Id, SeasonData] = {}
## 비가 오지 않는 계절, 장터가 없는 계절에 돌려주는 빈 설정
var _no_rain: RainSettings
var _no_market: MarketSettings


func _ready() -> void:
	if ResourceLoader.exists(STARTING_SETUP_PATH):
		_starting_setup = load(STARTING_SETUP_PATH)
	else:
		push_warning("시작 설정 파일이 없습니다: %s" % STARTING_SETUP_PATH)
	for resource: Resource in _load_folder(SEASONS_DIR):
		if resource is SeasonData:
			if _seasons.has(resource.id):
				push_warning("계절이 겹칩니다: %s (건너뜁니다)" % resource.resource_path)
			else:
				_seasons[resource.id] = resource
	if not _seasons.has(Season.Id.SPRING):
		push_warning("봄 계절 데이터가 없습니다: %sspring.tres" % SEASONS_DIR)
	_no_rain = RainSettings.new()
	_no_rain.rain_days.clear()
	_no_rain.rain_chance = 0.0
	_no_market = MarketSettings.new()
	_no_market.interval_days = 0
	for resource: Resource in _load_folder(INGREDIENTS_DIR):
		if resource is Ingredient:
			_register(_ingredients, resource.id, resource)
		else:
			_warn_wrong_type(resource, "Ingredient")
	for resource: Resource in _load_folder(RECIPES_DIR):
		if resource is Recipe:
			_register(_recipes, resource.id, resource)
		else:
			_warn_wrong_type(resource, "Recipe")
	for resource: Resource in _load_folder(GUESTS_DIR):
		if resource is AnimalGuest:
			_register(_guests, resource.id, resource)
		else:
			_warn_wrong_type(resource, "AnimalGuest")
	for resource: Resource in _load_folder(CROPS_DIR):
		if resource is Crop:
			_register(_crops, resource.id, resource)
		else:
			_warn_wrong_type(resource, "Crop")
	if ResourceLoader.exists(REGULAR_SETTINGS_PATH):
		_regular_settings = load(REGULAR_SETTINGS_PATH)
	else:
		push_warning("단골도 설정 파일이 없습니다: %s" % REGULAR_SETTINGS_PATH)
		_regular_settings = RegularSettings.new()
	if ResourceLoader.exists(REPUTATION_SETTINGS_PATH):
		_reputation_settings = load(REPUTATION_SETTINGS_PATH)
	else:
		push_warning("소문 설정 파일이 없습니다: %s" % REPUTATION_SETTINGS_PATH)
		_reputation_settings = ReputationSettings.new()
	if ResourceLoader.exists(MENU_SETTINGS_PATH):
		_menu_settings = load(MENU_SETTINGS_PATH)
	else:
		push_warning("메뉴 설정 파일이 없습니다: %s" % MENU_SETTINGS_PATH)
		_menu_settings = MenuSettings.new()
	for resource: Resource in _load_folder(GARNISHES_DIR):
		if resource is Garnish:
			_register(_garnishes, resource.id, resource)
		else:
			_warn_wrong_type(resource, "Garnish")
	for resource: Resource in _load_folder(REQUESTS_DIR):
		if resource is GuestRequest:
			_register(_requests, resource.id, resource)
		else:
			_warn_wrong_type(resource, "GuestRequest")
	for resource: Resource in _load_folder(PLACES_DIR):
		if resource is GardenPlace:
			_register(_places, resource.id, resource)
		else:
			_warn_wrong_type(resource, "GardenPlace")


# --- 하나 찾기 (없으면 null) ---

func get_ingredient(ingredient_id: StringName) -> Ingredient:
	return _ingredients.get(ingredient_id)


func get_recipe(recipe_id: StringName) -> Recipe:
	return _recipes.get(recipe_id)


func get_guest(guest_id: StringName) -> AnimalGuest:
	return _guests.get(guest_id)


func get_crop(crop_id: StringName) -> Crop:
	return _crops.get(crop_id)


func get_garden_place(place_id: StringName) -> GardenPlace:
	return _places.get(place_id)


func get_garnish(garnish_id: StringName) -> Garnish:
	return _garnishes.get(garnish_id)


## 단골도 규칙 (파일이 없으면 기본값)
func get_regular_settings() -> RegularSettings:
	return _regular_settings


## 소문 규칙 (파일이 없으면 기본값)
func get_reputation_settings() -> ReputationSettings:
	return _reputation_settings


## 오늘의 메뉴 칸 수 규칙
func get_menu_settings() -> MenuSettings:
	return _menu_settings


## 지금 계절의 장터 설정 (장터가 없는 계절이면 장날이 없는 빈 설정)
func get_market_settings() -> MarketSettings:
	var season: SeasonData = get_current_season()
	return season.market if season != null and season.market != null else _no_market


## 지금 계절의 비 오는 날 설정 (비가 없는 계절이면 비가 오지 않는 빈 설정)
func get_rain_settings() -> RainSettings:
	var season: SeasonData = get_current_season()
	return season.rain if season != null and season.rain != null else _no_rain


## 새 게임 시작 설정 (없으면 null)
func get_starting_setup() -> StartingSetup:
	return _starting_setup


## 계절 데이터 (없으면 null)
func get_season(season_id: Season.Id) -> SeasonData:
	return _seasons.get(season_id)


## 지금 계절(GameState.current_season)의 데이터
func get_current_season() -> SeasonData:
	return get_season(GameState.current_season)


## 지금 계절 이름 (예: "봄"). 날짜 글("봄 3일째 아침")에 쓴다.
func get_season_name() -> String:
	var season: SeasonData = get_current_season()
	return season.display_name if season != null else ""


## 지금 계절의 마무리 장면 글 (없으면 null = 이 계절은 끝나지 않는다)
func get_season_ending() -> SeasonEnding:
	var season: SeasonData = get_current_season()
	return season.ending if season != null else null


## 지금 계절의 날마다 바뀌는 곡 (없으면 null)
func get_daily_music() -> DailyMusic:
	var season: SeasonData = get_current_season()
	return season.daily_music if season != null else null


## 지금 계절에 점심을 먹으러 오는 손님 (계절 데이터가 없으면 모든 손님)
func get_season_guests() -> Array[AnimalGuest]:
	var season: SeasonData = get_current_season()
	if season == null or season.guests.is_empty():
		return get_all_guests()
	return season.guests.duplicate()


# --- 전부 가져오기 ---

func get_all_ingredients() -> Array[Ingredient]:
	return _ingredients.values()


func get_all_recipes() -> Array[Recipe]:
	return _recipes.values()


func get_all_guests() -> Array[AnimalGuest]:
	return _guests.values()


func get_all_garden_places() -> Array[GardenPlace]:
	return _places.values()


func get_all_requests() -> Array[GuestRequest]:
	return _requests.values()


## 고명 전부, 고르는 창에 놓일 순서대로
func get_all_garnishes() -> Array[Garnish]:
	var garnishes: Array[Garnish] = _garnishes.values()
	garnishes.sort_custom(func(a: Garnish, b: Garnish) -> bool: return a.sort_order < b.sort_order)
	return garnishes


# --- 내부 ---

func _load_folder(dir_path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	for file_name: String in ResourceLoader.list_directory(dir_path):
		if file_name.get_extension() not in RESOURCE_EXTENSIONS:
			continue
		var resource: Resource = load(dir_path + file_name)
		if resource == null:
			push_warning("데이터 파일을 읽지 못했습니다: %s" % (dir_path + file_name))
			continue
		resources.append(resource)
	return resources


func _register(table: Dictionary, id: StringName, resource: Resource) -> void:
	if id.is_empty():
		push_warning("id가 비어 있어 건너뜁니다: %s" % resource.resource_path)
		return
	if table.has(id):
		push_warning("id '%s'가 겹칩니다: %s 와 %s (뒤의 파일은 건너뜁니다)" % [id, table[id].resource_path, resource.resource_path])
		return
	table[id] = resource


func _warn_wrong_type(resource: Resource, expected_type: String) -> void:
	push_warning("%s 는 %s 가 아니라서 건너뜁니다" % [resource.resource_path, expected_type])
