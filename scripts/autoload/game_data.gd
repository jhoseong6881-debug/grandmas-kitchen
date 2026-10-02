extends Node
## data/ 폴더의 재료, 레시피, 동물 손님 .tres 파일을 게임 시작 때 모두 읽어 id로 찾을 수 있게 하는 오토로드.
## 프로젝트 설정 > 전역 > 오토로드 에 "GameData" 이름으로 등록해서 쓴다.
## 읽기 전용 원본 데이터만 다룬다. 플레이 중 바뀌는 상태는 GameState 가 맡는다.

const INGREDIENTS_DIR: String = "res://data/ingredients/"
const RECIPES_DIR: String = "res://data/recipes/"
const GUESTS_DIR: String = "res://data/guests/"
const STARTING_SETUP_PATH: String = "res://data/starting_setup.tres"
const SEASON_ENDING_PATH: String = "res://data/seasons/spring_ending.tres"
const RESOURCE_EXTENSIONS: PackedStringArray = ["tres", "res"]

var _ingredients: Dictionary[StringName, Ingredient] = {}
var _recipes: Dictionary[StringName, Recipe] = {}
var _guests: Dictionary[StringName, AnimalGuest] = {}
var _starting_setup: StartingSetup
var _season_ending: SeasonEnding


func _ready() -> void:
	if ResourceLoader.exists(STARTING_SETUP_PATH):
		_starting_setup = load(STARTING_SETUP_PATH)
	else:
		push_warning("시작 설정 파일이 없습니다: %s" % STARTING_SETUP_PATH)
	if ResourceLoader.exists(SEASON_ENDING_PATH):
		_season_ending = load(SEASON_ENDING_PATH)
	else:
		push_warning("계절 마무리 파일이 없습니다: %s" % SEASON_ENDING_PATH)
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


# --- 하나 찾기 (없으면 null) ---

func get_ingredient(ingredient_id: StringName) -> Ingredient:
	return _ingredients.get(ingredient_id)


func get_recipe(recipe_id: StringName) -> Recipe:
	return _recipes.get(recipe_id)


func get_guest(guest_id: StringName) -> AnimalGuest:
	return _guests.get(guest_id)


## 새 게임 시작 설정 (없으면 null)
func get_starting_setup() -> StartingSetup:
	return _starting_setup


## 지금 계절의 마무리 장면 글 (없으면 null)
func get_season_ending() -> SeasonEnding:
	return _season_ending


# --- 전부 가져오기 ---

func get_all_ingredients() -> Array[Ingredient]:
	return _ingredients.values()


func get_all_recipes() -> Array[Recipe]:
	return _recipes.values()


func get_all_guests() -> Array[AnimalGuest]:
	return _guests.values()


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
