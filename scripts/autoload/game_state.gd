extends Node
## 게임 전체에서 쓰는 상태(인벤토리, 날짜, 해금된 레시피)를 관리하는 오토로드.
## 프로젝트 설정 > 전역 > 자동 로드 에 "GameState" 이름으로 등록해서 쓴다.
## 재료와 레시피는 Resource 대신 id(StringName)로 기억한다. 그래야 세이브 파일에 그대로 저장할 수 있다.

signal inventory_changed(ingredient_id: StringName, new_count: int)
signal day_changed(new_day: int)
signal recipe_unlocked(recipe_id: StringName)

const SAVE_PATH: String = "user://save.json"
## 세이브 파일 구조가 바뀌면 숫자를 올린다. 옛 세이브를 읽을 때 구분하는 데 쓴다.
const SAVE_VERSION: int = 1
const STARTING_DAY: int = 1

var current_day: int = STARTING_DAY
## 재료 id → 개수
var inventory: Dictionary[StringName, int] = {}
var unlocked_recipe_ids: Array[StringName] = []


# --- 인벤토리 ---

func add_ingredient(ingredient_id: StringName, amount: int = 1) -> void:
	var new_count: int = get_ingredient_count(ingredient_id) + amount
	inventory[ingredient_id] = new_count
	inventory_changed.emit(ingredient_id, new_count)


## 재료가 충분하면 빼고 true, 모자라면 아무것도 안 하고 false.
func remove_ingredient(ingredient_id: StringName, amount: int = 1) -> bool:
	var count: int = get_ingredient_count(ingredient_id)
	if count < amount:
		return false
	var new_count: int = count - amount
	if new_count == 0:
		inventory.erase(ingredient_id)
	else:
		inventory[ingredient_id] = new_count
	inventory_changed.emit(ingredient_id, new_count)
	return true


func get_ingredient_count(ingredient_id: StringName) -> int:
	return inventory.get(ingredient_id, 0)


# --- 날짜 ---

func advance_day() -> void:
	current_day += 1
	day_changed.emit(current_day)


# --- 레시피 ---

func unlock_recipe(recipe_id: StringName) -> void:
	if is_recipe_unlocked(recipe_id):
		return
	unlocked_recipe_ids.append(recipe_id)
	recipe_unlocked.emit(recipe_id)


func is_recipe_unlocked(recipe_id: StringName) -> bool:
	return recipe_id in unlocked_recipe_ids


# --- 새 게임 / 세이브 / 로드 ---

func new_game() -> void:
	current_day = STARTING_DAY
	inventory.clear()
	unlocked_recipe_ids.clear()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("세이브 실패: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(_to_save_data(), "\t"))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary:
		push_error("세이브 파일을 읽을 수 없습니다: %s" % SAVE_PATH)
		return false
	_from_save_data(data)
	return true


func _to_save_data() -> Dictionary:
	var inventory_data: Dictionary = {}
	for ingredient_id: StringName in inventory:
		inventory_data[String(ingredient_id)] = inventory[ingredient_id]
	var recipe_data: Array[String] = []
	for recipe_id: StringName in unlocked_recipe_ids:
		recipe_data.append(String(recipe_id))
	return {
		"version": SAVE_VERSION,
		"current_day": current_day,
		"inventory": inventory_data,
		"unlocked_recipe_ids": recipe_data,
	}


## JSON은 숫자를 소수(float)로, id를 문자열로 돌려주므로 여기서 원래 타입으로 바꾼다.
func _from_save_data(data: Dictionary) -> void:
	new_game()
	current_day = int(data.get("current_day", STARTING_DAY))
	var inventory_data: Dictionary = data.get("inventory", {})
	for ingredient_id: String in inventory_data:
		inventory[StringName(ingredient_id)] = int(inventory_data[ingredient_id])
	var recipe_data: Array = data.get("unlocked_recipe_ids", [])
	for recipe_id: Variant in recipe_data:
		unlocked_recipe_ids.append(StringName(str(recipe_id)))
