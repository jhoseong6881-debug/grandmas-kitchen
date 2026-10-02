extends Node
## 게임 전체에서 쓰는 상태(인벤토리, 날짜, 해금된 레시피)를 관리하는 오토로드.
## 프로젝트 설정 > 전역 > 자동 로드 에 "GameState" 이름으로 등록해서 쓴다.
## 재료와 레시피는 Resource 대신 id(StringName)로 기억한다. 그래야 세이브 파일에 그대로 저장할 수 있다.

signal inventory_changed(ingredient_id: StringName, new_count: int)
signal day_changed(new_day: int)
signal recipe_unlocked(recipe_id: StringName)

const SAVE_PATH: String = "user://save.json"
## 세이브 파일 구조가 바뀌면 숫자를 올린다. 옛 세이브를 읽을 때 구분하는 데 쓴다.
## 2: 텃밭이 여러 곳(GardenPlace)이 되고 칸마다 심은 작물을 저장한다.
const SAVE_VERSION: int = 2
## 빈 칸의 작물 id
const EMPTY_PLOT: StringName = &""
## 옛 세이브(버전 1)의 텃밭 칸이 속한 밭
const LEGACY_GARDEN_PLACE_ID: StringName = &"carrot_field"
const STARTING_DAY: int = 1

var current_day: int = STARTING_DAY
## 프롤로그에서 지은 주인공 이름 (할머니의 손주). 아직 안 지었으면 빈 문자열.
var player_name: String = ""
## 재료 id → 개수
var inventory: Dictionary[StringName, int] = {}
var unlocked_recipe_ids: Array[StringName] = []
## 밭 id → 칸마다 심은 작물 id (EMPTY_PLOT = 빈 칸)
var plot_crop_ids: Dictionary[StringName, Array] = {}
## 밭 id → 칸마다 다 자라기까지 남은 날 수 (0 = 거둘 수 있음)
var plot_days_left: Dictionary[StringName, Array] = {}
## 오늘 아침 이웃 바구니를 이미 열어 봤는지. 하루가 지나면 다시 false.
var is_todays_gift_collected: bool = false
## 아침에 고른 오늘의 메뉴 (레시피 id). 점심 손님은 이 안에서만 주문한다.
## 다음 날 아침 메뉴판에서 미리 골라 두는 데도 쓰고, 세이브에도 넣는다. 비어 있으면 메뉴 제한이 없다.
var menu_recipe_ids: Array[StringName] = []
## 한 번이라도 대접한 손님 id. 손님 수첩에 그 손님 정보를 보여 줄 때 쓴다.
var met_guest_ids: Array[StringName] = []
## 손님 id → 저녁 평상에서 지금까지 들려준 이야기 수
var guest_story_progress: Dictionary[StringName, int] = {}
## 레시피 노트를 다 모은 날 (0 = 아직). 그다음 날 저녁에 봄 잔치가 열린다.
var notes_completed_day: int = 0
## 봄 잔치까지 보고 봄을 마쳤는지
var is_spring_completed: bool = false
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
	for place_id: StringName in plot_days_left:
		var days: Array = plot_days_left[place_id]
		for i: int in days.size():
			days[i] = maxi(days[i] - 1, 0)
	day_changed.emit(current_day)


## 오늘 대접한 손님을 기록한다. 같은 손님을 여러 번 대접했으면 한 번이라도 완벽했는지를 남긴다.
func record_served_guest(guest_id: StringName, is_perfect: bool) -> void:
	todays_served_guests[guest_id] = todays_served_guests.get(guest_id, false) or is_perfect
	if guest_id not in met_guest_ids:
		met_guest_ids.append(guest_id)


func has_met_guest(guest_id: StringName) -> bool:
	return guest_id in met_guest_ids


## 오늘의 메뉴에 있는 요리인지. 메뉴를 아직 안 골랐으면(비어 있으면) 모든 요리를 낼 수 있다.
func is_on_menu(recipe_id: StringName) -> bool:
	return menu_recipe_ids.is_empty() or recipe_id in menu_recipe_ids


# --- 텃밭 ---

## 그 칸에 심긴 작물. 빈 칸이면 null.
func get_plot_crop(place_id: StringName, plot_index: int) -> Crop:
	var crop_ids: Array = plot_crop_ids.get(place_id, [])
	if plot_index >= crop_ids.size() or crop_ids[plot_index] == EMPTY_PLOT:
		return null
	return GameData.get_crop(crop_ids[plot_index])


func get_plot_days_left(place_id: StringName, plot_index: int) -> int:
	var days: Array = plot_days_left.get(place_id, [])
	return days[plot_index] if plot_index < days.size() else 0


func is_plot_ripe(place_id: StringName, plot_index: int) -> bool:
	return get_plot_crop(place_id, plot_index) != null and get_plot_days_left(place_id, plot_index) == 0


## 씨앗(심는 데 드는 재료)이 넉넉한지
func can_plant(crop: Crop) -> bool:
	return has_ingredients(crop.get_seed_cost())


## 빈 칸에 작물을 심는다. 씨앗 재료를 쓰고, grow_days 일 뒤에 거둘 수 있다. 빈 칸이 아니거나 씨앗이 모자라면 false.
func plant_plot(place_id: StringName, plot_index: int, crop: Crop) -> bool:
	if get_plot_crop(place_id, plot_index) != null or not can_plant(crop):
		return false
	remove_ingredients(crop.get_seed_cost())
	plot_crop_ids[place_id][plot_index] = crop.id
	plot_days_left[place_id][plot_index] = crop.grow_days
	return true


## 다 자란 칸을 거둔다. 재료를 받고 그 칸은 빈 칸이 된다. 거둔 작물을 돌려준다. 아직 안 자랐으면 null.
func harvest_plot(place_id: StringName, plot_index: int) -> Crop:
	if not is_plot_ripe(place_id, plot_index):
		return null
	var crop: Crop = get_plot_crop(place_id, plot_index)
	add_ingredient(crop.ingredient.id, crop.harvest_amount)
	plot_crop_ids[place_id][plot_index] = EMPTY_PLOT
	plot_days_left[place_id][plot_index] = 0
	return crop


## data/places/ 의 밭마다 칸을 만든다. 시작 작물이 있으면 다 자란 채로 심어 둔다.
func _reset_garden() -> void:
	plot_crop_ids.clear()
	plot_days_left.clear()
	for place: GardenPlace in GameData.get_all_garden_places():
		var crop_ids: Array = []
		crop_ids.resize(place.plot_count)
		crop_ids.fill(place.starting_crop.id if place.starting_crop != null else EMPTY_PLOT)
		var days: Array = []
		days.resize(place.plot_count)
		days.fill(0)
		plot_crop_ids[place.id] = crop_ids
		plot_days_left[place.id] = days


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
	if notes_completed_day == 0 and unlocked_recipe_ids.size() >= GameData.get_all_recipes().size():
		notes_completed_day = current_day


## 레시피 노트를 다 모은 다음 날부터, 봄을 마치기 전까지는 저녁에 평상 대신 봄 잔치가 열린다.
func is_spring_feast_day() -> bool:
	return notes_completed_day > 0 and current_day > notes_completed_day and not is_spring_completed


func is_recipe_unlocked(recipe_id: StringName) -> bool:
	return recipe_id in unlocked_recipe_ids


# --- 새 게임 / 세이브 / 로드 ---

func new_game() -> void:
	current_day = STARTING_DAY
	player_name = ""
	inventory.clear()
	unlocked_recipe_ids.clear()
	guest_story_progress.clear()
	todays_served_guests.clear()
	plot_crop_ids.clear()
	plot_days_left.clear()
	met_guest_ids.clear()
	menu_recipe_ids.clear()
	notes_completed_day = 0
	is_spring_completed = false
	is_todays_gift_collected = false
	is_game_started = false


## 새 게임을 시작하고, data/starting_setup.tres 에 적힌 시작 재료와 레시피를 받는다.
func start_new_game() -> void:
	new_game()
	is_game_started = true
	_reset_garden()
	var setup: StartingSetup = GameData.get_starting_setup()
	if setup == null:
		return
	for ingredient: Ingredient in setup.starting_ingredients:
		add_ingredient(ingredient.id)
	for recipe: Recipe in setup.starting_recipes:
		unlock_recipe(recipe.id)


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
		"player_name": player_name,
		"inventory": inventory_data,
		"unlocked_recipe_ids": recipe_data,
		"guest_story_progress": story_data,
		"garden": _garden_save_data(),
		"met_guest_ids": Array(met_guest_ids).map(func(guest_id: StringName) -> String: return String(guest_id)),
		"menu_recipe_ids": Array(menu_recipe_ids).map(func(recipe_id: StringName) -> String: return String(recipe_id)),
		"notes_completed_day": notes_completed_day,
		"is_spring_completed": is_spring_completed,
	}


## JSON은 숫자를 소수(float)로, id를 문자열로 돌려주므로 여기서 원래 타입으로 바꾼다.
func _from_save_data(data: Dictionary) -> void:
	new_game()
	current_day = int(data.get("current_day", STARTING_DAY))
	player_name = str(data.get("player_name", ""))
	var inventory_data: Dictionary = data.get("inventory", {})
	for ingredient_id: String in inventory_data:
		inventory[StringName(ingredient_id)] = int(inventory_data[ingredient_id])
	var recipe_data: Array = data.get("unlocked_recipe_ids", [])
	for recipe_id: Variant in recipe_data:
		unlocked_recipe_ids.append(StringName(str(recipe_id)))
	var story_data: Dictionary = data.get("guest_story_progress", {})
	for guest_id: String in story_data:
		guest_story_progress[StringName(guest_id)] = int(story_data[guest_id])
	_load_garden(data)
	var met_data: Array = data.get("met_guest_ids", [])
	for guest_id: Variant in met_data:
		met_guest_ids.append(StringName(str(guest_id)))
	var menu_data: Array = data.get("menu_recipe_ids", [])
	for recipe_id: Variant in menu_data:
		menu_recipe_ids.append(StringName(str(recipe_id)))
	notes_completed_day = int(data.get("notes_completed_day", 0))
	is_spring_completed = bool(data.get("is_spring_completed", false))


## {밭 id: [{"crop": 작물 id, "days_left": 남은 날}, ...]}
func _garden_save_data() -> Dictionary:
	var garden_data: Dictionary = {}
	for place_id: StringName in plot_crop_ids:
		var plots: Array = []
		for i: int in plot_crop_ids[place_id].size():
			plots.append({"crop": String(plot_crop_ids[place_id][i]), "days_left": plot_days_left[place_id][i]})
		garden_data[String(place_id)] = plots
	return garden_data


## 지금 data/places/ 의 밭으로 칸을 만든 뒤, 세이브에 있는 칸만 덮어쓴다.
## 그래서 세이브 뒤에 새 밭이 생겨도 그 밭은 처음 상태로 나온다.
## 옛 세이브(버전 1)는 당근 텃밭 칸의 남은 날만 있으므로 그 칸들은 당근이 심긴 것으로 읽는다.
func _load_garden(data: Dictionary) -> void:
	_reset_garden()
	var garden_data: Dictionary = data.get("garden", {})
	for place_id: String in garden_data:
		if not plot_crop_ids.has(StringName(place_id)):
			continue
		var plots: Array = garden_data[place_id]
		for i: int in mini(plots.size(), plot_crop_ids[StringName(place_id)].size()):
			var crop_id: StringName = StringName(str(plots[i].get("crop", "")))
			if crop_id != EMPTY_PLOT and GameData.get_crop(crop_id) == null:
				crop_id = EMPTY_PLOT
			plot_crop_ids[StringName(place_id)][i] = crop_id
			plot_days_left[StringName(place_id)][i] = int(plots[i].get("days_left", 0))
	var legacy_days: Array = data.get("garden_days_left", [])
	if garden_data.is_empty() and plot_days_left.has(LEGACY_GARDEN_PLACE_ID):
		var days: Array = plot_days_left[LEGACY_GARDEN_PLACE_ID]
		for i: int in mini(legacy_days.size(), days.size()):
			days[i] = int(legacy_days[i])
