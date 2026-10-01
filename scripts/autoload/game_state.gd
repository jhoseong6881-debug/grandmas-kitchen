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
## 텃밭 칸마다 다시 다 자라기까지 남은 날 수 (0 = 지금 거둘 수 있음). 칸 순서는 StartingSetup.garden_plots 와 같다.
var garden_days_left: Array[int] = []
## 오늘 아침 이웃 바구니를 이미 열어 봤는지. 하루가 지나면 다시 false.
var is_todays_gift_collected: bool = false
## 손님 id → 저녁 평상에서 지금까지 들려준 이야기 수
var guest_story_progress: Dictionary[StringName, int] = {}
## 새 게임을 시작했거나 세이브를 불러왔으면 true. 화면이 바뀌어도 게임을 다시 시작하지 않게 할 때 쓴다.
var is_game_started: bool = false
## 오늘 대접한 손님 id → 한 번도 안 틀리고 대접했는지. 저녁 평상에 올 손님을 고를 때 쓴다.
## 하루가 지나면 비운다. 하루가 끝날 때 저장할 것이라 세이브에는 넣지 않는다.
var todays_served_guests: Dictionary[StringName, bool] = {}
## 방금 잠자리에 들며 자동 저장했으면 true. 다음 날 아침 텃밭이 "저장했어요"를 한 번 보여 주고 끈다.
var has_unshown_save_notice: bool = false


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


## counts: 재료 id → 필요한 개수 (Recipe.get_ingredient_counts() 결과)
func has_ingredients(counts: Dictionary[StringName, int]) -> bool:
	for ingredient_id: StringName in counts:
		if get_ingredient_count(ingredient_id) < counts[ingredient_id]:
			return false
	return true


## 전부 충분하면 한꺼번에 빼고 true, 하나라도 모자라면 아무것도 안 빼고 false.
func remove_ingredients(counts: Dictionary[StringName, int]) -> bool:
	if not has_ingredients(counts):
		return false
	for ingredient_id: StringName in counts:
		remove_ingredient(ingredient_id, counts[ingredient_id])
	return true


# --- 날짜 ---

func advance_day() -> void:
	current_day += 1
	todays_served_guests.clear()
	is_todays_gift_collected = false
	for i: int in garden_days_left.size():
		garden_days_left[i] = maxi(garden_days_left[i] - 1, 0)
	day_changed.emit(current_day)


## 오늘 대접한 손님을 기록한다. 같은 손님을 여러 번 대접했으면 한 번이라도 완벽했는지를 남긴다.
func record_served_guest(guest_id: StringName, is_perfect: bool) -> void:
	todays_served_guests[guest_id] = todays_served_guests.get(guest_id, false) or is_perfect


# --- 텃밭 ---

func is_plot_ripe(plot_index: int) -> bool:
	return garden_days_left[plot_index] == 0


## 다 자란 칸을 거둔다. 재료를 받고, 그 칸은 regrow_days 일 뒤에 다시 자란다. 아직 안 자랐으면 false.
func harvest_plot(plot_index: int, crop: Crop) -> bool:
	if not is_plot_ripe(plot_index):
		return false
	add_ingredient(crop.ingredient.id, crop.harvest_amount)
	garden_days_left[plot_index] = crop.regrow_days
	return true


# --- 저녁 이야기 ---

func get_story_progress(guest_id: StringName) -> int:
	return guest_story_progress.get(guest_id, 0)


func advance_story(guest_id: StringName) -> void:
	guest_story_progress[guest_id] = get_story_progress(guest_id) + 1


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
	guest_story_progress.clear()
	todays_served_guests.clear()
	garden_days_left.clear()
	is_todays_gift_collected = false
	is_game_started = false


## 새 게임을 시작하고, data/starting_setup.tres 에 적힌 시작 재료와 레시피를 받는다.
func start_new_game() -> void:
	new_game()
	is_game_started = true
	var setup: StartingSetup = GameData.get_starting_setup()
	if setup == null:
		return
	for ingredient: Ingredient in setup.starting_ingredients:
		add_ingredient(ingredient.id)
	for recipe: Recipe in setup.starting_recipes:
		unlock_recipe(recipe.id)
	# 텃밭은 처음에 모두 다 자란 상태로 시작한다.
	garden_days_left.resize(setup.garden_plots.size())
	garden_days_left.fill(0)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## 세이브 파일을 불러오지 않고 내용만 읽는다. 타이틀 화면에서 "N일째"를 보여 줄 때 쓴다. 못 읽으면 빈 Dictionary.
func read_save_summary() -> Dictionary:
	if not has_save():
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return data if data is Dictionary else {}


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


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
	is_game_started = true
	return true


func _to_save_data() -> Dictionary:
	var inventory_data: Dictionary = {}
	for ingredient_id: StringName in inventory:
		inventory_data[String(ingredient_id)] = inventory[ingredient_id]
	var recipe_data: Array[String] = []
	for recipe_id: StringName in unlocked_recipe_ids:
		recipe_data.append(String(recipe_id))
	var story_data: Dictionary = {}
	for guest_id: StringName in guest_story_progress:
		story_data[String(guest_id)] = guest_story_progress[guest_id]
	return {
		"version": SAVE_VERSION,
		"current_day": current_day,
		"inventory": inventory_data,
		"unlocked_recipe_ids": recipe_data,
		"guest_story_progress": story_data,
		"garden_days_left": garden_days_left,
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
	var story_data: Dictionary = data.get("guest_story_progress", {})
	for guest_id: String in story_data:
		guest_story_progress[StringName(guest_id)] = int(story_data[guest_id])
	var garden_data: Array = data.get("garden_days_left", [])
	for days_left: Variant in garden_data:
		garden_days_left.append(int(days_left))
