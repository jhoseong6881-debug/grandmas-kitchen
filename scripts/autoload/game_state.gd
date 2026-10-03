extends Node
## 게임 전체에서 쓰는 상태(인벤토리, 날짜, 해금된 레시피)를 관리하는 오토로드.
## 프로젝트 설정 > 전역 > 자동 로드 에 "GameState" 이름으로 등록해서 쓴다.
## 재료와 레시피는 Resource 대신 id(StringName)로 기억한다. 그래야 세이브 파일에 그대로 저장할 수 있다.

signal inventory_changed(ingredient_id: StringName, new_count: int)
signal day_changed(new_day: int)
signal recipe_unlocked(recipe_id: StringName)
signal reputation_changed(new_reputation: int)
signal feast_prep_changed

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
## 지금까지 쌓인 가게 소문. 쌓일수록 가게 단계(이름)가 오른다 (ReputationSettings).
var reputation: int = 0
## 재료 id → 개수
var inventory: Dictionary[StringName, int] = {}
var unlocked_recipe_ids: Array[StringName] = []
## 밭 id → 칸마다 심은 작물 id (EMPTY_PLOT = 빈 칸)
var plot_crop_ids: Dictionary[StringName, Array] = {}
## 밭 id → 칸마다 다 자라기까지 남은 날 수 (0 = 거둘 수 있음)
var plot_days_left: Dictionary[StringName, Array] = {}
## 오늘 아침 이웃 바구니를 이미 열어 봤는지. 하루가 지나면 다시 false.
var is_todays_gift_collected: bool = false
## 숲속 장터: 너구리 상인을 만났는지 (첫 인사를 한 번만 하려고 저장한다)
var has_met_merchant: bool = false
## 오늘 장터에서 거래마다 바꾼 횟수 (거래 id → 횟수). 하루가 지나면 비운다. 장날 낮의 일이라 저장하지 않는다.
var todays_market_trades: Dictionary[StringName, int] = {}
## 오늘 장터에 다녀왔는지. 텃밭이 장터 버튼과 부엌 버튼 중 무엇을 먼저 선택해 둘지 정할 때 쓴다. 저장하지 않는다.
var has_visited_market_today: bool = false
## 아침에 고른 오늘의 메뉴 (레시피 id). 점심 손님은 이 안에서만 주문한다.
## 다음 날 아침 메뉴판에서 미리 골라 두는 데도 쓰고, 세이브에도 넣는다. 비어 있으면 메뉴 제한이 없다.
var menu_recipe_ids: Array[StringName] = []
## 한 번이라도 대접한 손님 id. 손님 수첩에 그 손님 정보를 보여 줄 때 쓴다.
var met_guest_ids: Array[StringName] = []
## 손님 id → 저녁 평상에서 지금까지 들려준 이야기 수
var guest_story_progress: Dictionary[StringName, int] = {}
## 손님에게 들어서 알게 된 할머니 비법 (레시피 id)
var learned_secret_ids: Array[StringName] = []
## 할머니 손맛으로 한 번이라도 대접한 레시피 (레시피 노트 도장)
var grandma_taste_recipe_ids: Array[StringName] = []
## 손님 id → 단골도 (대접할수록 오른다. 단계는 RegularSettings 로 정한다)
var guest_affection: Dictionary[StringName, int] = {}
## 입맛(좋아하는 고명)을 알아낸 손님 id. 손님 수첩에 입맛을 보여 줄 때 쓴다.
var known_taste_guest_ids: Array[StringName] = []
## 손님 id → 단계는 올랐지만 아직 저녁에 보상(새 이야기, 선물)을 받지 않은 단골 단계들
var pending_reward_tiers: Dictionary[StringName, Array] = {}
## 손님에게 받은 할머니 기념품 id
var keepsake_ids: Array[StringName] = []
## 밭 id → 단골 선물로 늘어난 칸 수
var extra_plots: Dictionary[StringName, int] = {}
## 계절 잔치 준비: 장보기 목록을 받았는지, 잔치 바구니에 모은 재료 (재료 id → 개수). 계절이 끝나면 비운다.
var is_feast_prep_announced: bool = false
var feast_prep_delivered: Dictionary[StringName, int] = {}
## 오늘 텃밭에서 잔치 바구니를 열어 봤는지 (텃밭이 무엇을 먼저 선택해 둘지 정할 때). 저장하지 않는다.
var has_opened_feast_prep_today: bool = false
## 지금 계절. 평상에서는 이 계절의 레시피 노트만 돌려받는다.
var current_season: Season.Id = Season.Id.SPRING
## 봄 잔치까지 보고 봄을 마쳤는지
var is_spring_completed: bool = false
## 새 게임을 시작했거나 세이브를 불러왔으면 true. 화면이 바뀌어도 게임을 다시 시작하지 않게 할 때 쓴다.
var is_game_started: bool = false
## 오늘 대접한 손님 id → 한 번도 안 틀리고 대접했는지. 저녁 평상에 올 손님을 고를 때 쓴다.
## 하루가 지나면 비운다. 하루가 끝날 때 저장할 것이라 세이브에는 넣지 않는다.
var todays_served_guests: Dictionary[StringName, bool] = {}


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
	todays_market_trades.clear()
	has_visited_market_today = false
	has_opened_feast_prep_today = false
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


## 밭의 칸 수 (밭 데이터의 칸 수 + 단골 선물로 늘어난 칸)
func get_plot_count(place_id: StringName) -> int:
	return plot_crop_ids.get(place_id, []).size()


## 밭에 빈 칸을 하나 늘린다 (단골 선물, 가게 단계 업).
func add_plot(place_id: StringName) -> void:
	if not plot_crop_ids.has(place_id):
		return
	extra_plots[place_id] = extra_plots.get(place_id, 0) + 1
	plot_crop_ids[place_id].append(EMPTY_PLOT)
	plot_days_left[place_id].append(0)


## data/places/ 의 밭마다 칸을 만든다. 시작 작물이 있으면 다 자란 채로 심어 두고, 늘어난 칸은 빈 칸으로 둔다.
func _reset_garden() -> void:
	plot_crop_ids.clear()
	plot_days_left.clear()
	for place: GardenPlace in GameData.get_all_garden_places():
		var count: int = place.plot_count + extra_plots.get(place.id, 0)
		var crop_ids: Array = []
		crop_ids.resize(count)
		crop_ids.fill(place.starting_crop.id if place.starting_crop != null else EMPTY_PLOT)
		for i: int in range(place.plot_count, count):
			crop_ids[i] = EMPTY_PLOT
		var days: Array = []
		days.resize(count)
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


## 봄 마무리 날(SeasonEnding.last_day)부터, 봄을 마치기 전까지는 저녁에 평상 대신 봄 잔치가 열린다.
## 노트를 다 모았는지와는 상관없다.
func is_spring_feast_day() -> bool:
	var ending: SeasonEnding = GameData.get_season_ending()
	return ending != null and current_day >= ending.last_day and not is_spring_completed


func is_recipe_unlocked(recipe_id: StringName) -> bool:
	return recipe_id in unlocked_recipe_ids


# --- 할머니 비법 ---

func is_secret_learned(recipe_id: StringName) -> bool:
	return recipe_id in learned_secret_ids


func learn_secret(recipe_id: StringName) -> void:
	if recipe_id not in learned_secret_ids:
		learned_secret_ids.append(recipe_id)


## 레시피 노트에 "할머니 손맛" 도장이 찍혔는지
func has_grandma_taste(recipe_id: StringName) -> bool:
	return recipe_id in grandma_taste_recipe_ids


func record_grandma_taste(recipe_id: StringName) -> void:
	if recipe_id not in grandma_taste_recipe_ids:
		grandma_taste_recipe_ids.append(recipe_id)


# --- 소문 ---

## 가게 단계 번호 (0 = 첫 단계)
func get_shop_tier() -> int:
	return GameData.get_reputation_settings().get_shop_tier(reputation)


## 지금 가게 단계 (단계 데이터가 없으면 null)
func get_shop_level() -> ShopLevel:
	return GameData.get_reputation_settings().get_shop_level(get_shop_tier())


## 지금까지 생긴 조리도구 중 이 미니게임에 쓰이는 것들
func get_shop_tools_for(minigame_type: Recipe.MinigameType) -> Array[ShopTool]:
	var tools: Array[ShopTool] = []
	for tool: ShopTool in GameData.get_reputation_settings().get_tools(get_shop_tier()):
		if minigame_type in tool.minigame_types:
			tools.append(tool)
	return tools


## 소문을 더한다. 가게 단계가 오르면 새 단계를, 그대로면 -1 을 돌려준다.
func add_reputation(points: int) -> int:
	var before: int = get_shop_tier()
	reputation += points
	reputation_changed.emit(reputation)
	var after: int = get_shop_tier()
	# 새로 오른 단계마다 밭 칸을 늘린다 (한 번에 두 단계가 올라도 둘 다 준다).
	for tier: int in range(before + 1, after + 1):
		var level: ShopLevel = GameData.get_reputation_settings().get_shop_level(tier)
		if level != null and not level.bonus_plot_place_id.is_empty():
			for i: int in level.bonus_plot_count:
				add_plot(level.bonus_plot_place_id)
	return after if after > before else -1


# --- 단골도와 입맛 ---

func get_affection(guest_id: StringName) -> int:
	return guest_affection.get(guest_id, 0)


## 단골 단계 (0 = 낯선 손님)
func get_regular_tier(guest_id: StringName) -> int:
	return GameData.get_regular_settings().get_tier(get_affection(guest_id))


## 단골도를 올린다. 단골 단계가 오르면 새 단계를, 그대로면 -1 을 돌려준다.
## 오른 단계들은 저녁에 보상을 받을 때까지 pending_reward_tiers 에 남는다.
func add_affection(guest_id: StringName, points: int) -> int:
	var before: int = get_regular_tier(guest_id)
	guest_affection[guest_id] = get_affection(guest_id) + points
	var after: int = get_regular_tier(guest_id)
	if after <= before:
		return -1
	var pending: Array = pending_reward_tiers.get(guest_id, [])
	for tier: int in range(before + 1, after + 1):
		pending.append(tier)
	pending_reward_tiers[guest_id] = pending
	return after


## 저녁에 받을 단골 보상 중 가장 낮은 단계. 없으면 -1.
func get_pending_reward_tier(guest_id: StringName) -> int:
	var pending: Array = pending_reward_tiers.get(guest_id, [])
	return pending.min() if not pending.is_empty() else -1


func finish_reward_tier(guest_id: StringName, tier: int) -> void:
	var pending: Array = pending_reward_tiers.get(guest_id, [])
	pending.erase(tier)
	if pending.is_empty():
		pending_reward_tiers.erase(guest_id)


## 보상(새 이야기)을 이미 받은 단골 단계인지
func has_received_reward(guest_id: StringName, tier: int) -> bool:
	return tier <= get_regular_tier(guest_id) and tier not in pending_reward_tiers.get(guest_id, [])


func add_keepsake(keepsake_id: StringName) -> void:
	if keepsake_id not in keepsake_ids:
		keepsake_ids.append(keepsake_id)


func has_keepsake(keepsake_id: StringName) -> bool:
	return keepsake_id in keepsake_ids


func knows_taste(guest_id: StringName) -> bool:
	return guest_id in known_taste_guest_ids


func learn_taste(guest_id: StringName) -> void:
	if guest_id not in known_taste_guest_ids:
		known_taste_guest_ids.append(guest_id)


# --- 숲속 장터 ---

func get_market_trade_count(trade_id: StringName) -> int:
	return todays_market_trades.get(trade_id, 0)


## 장터에서 한 번 바꾼다. 재료가 모자라면 아무것도 안 하고 false.
func trade_at_market(trade: MarketTrade) -> bool:
	if trade.give_ingredient == null or trade.get_ingredient == null or not has_ingredients(trade.get_cost()):
		return false
	remove_ingredients(trade.get_cost())
	add_ingredient(trade.get_ingredient.id, trade.get_amount)
	todays_market_trades[trade.id] = get_market_trade_count(trade.id) + 1
	return true


# --- 계절 잔치 준비 ---

func get_feast_delivered(ingredient_id: StringName) -> int:
	return feast_prep_delivered.get(ingredient_id, 0)


func get_feast_delivered_total() -> int:
	var total: int = 0
	for ingredient_id: StringName in feast_prep_delivered:
		total += feast_prep_delivered[ingredient_id]
	return total


## 잔치 바구니에 재료를 낸다. 가진 만큼, 목록에 남은 만큼만 낸다. 실제로 낸 개수를 돌려준다.
func deliver_to_feast(item: FeastItem, max_amount: int) -> int:
	var remaining: int = item.amount - get_feast_delivered(item.ingredient.id)
	var amount: int = mini(mini(max_amount, remaining), get_ingredient_count(item.ingredient.id))
	if amount <= 0:
		return 0
	var cost: Dictionary[StringName, int] = {item.ingredient.id: amount}
	remove_ingredients(cost)
	feast_prep_delivered[item.ingredient.id] = get_feast_delivered(item.ingredient.id) + amount
	feast_prep_changed.emit()
	return amount


# --- 새 게임 / 세이브 / 로드 ---

func new_game() -> void:
	current_day = STARTING_DAY
	player_name = ""
	reputation = 0
	inventory.clear()
	unlocked_recipe_ids.clear()
	guest_story_progress.clear()
	todays_served_guests.clear()
	plot_crop_ids.clear()
	plot_days_left.clear()
	met_guest_ids.clear()
	menu_recipe_ids.clear()
	learned_secret_ids.clear()
	grandma_taste_recipe_ids.clear()
	guest_affection.clear()
	known_taste_guest_ids.clear()
	pending_reward_tiers.clear()
	keepsake_ids.clear()
	extra_plots.clear()
	current_season = Season.Id.SPRING
	is_spring_completed = false
	is_todays_gift_collected = false
	has_met_merchant = false
	todays_market_trades.clear()
	has_visited_market_today = false
	is_feast_prep_announced = false
	feast_prep_delivered.clear()
	has_opened_feast_prep_today = false
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
		"reputation": reputation,
		"inventory": inventory_data,
		"unlocked_recipe_ids": recipe_data,
		"guest_story_progress": story_data,
		"garden": _garden_save_data(),
		"met_guest_ids": Array(met_guest_ids).map(func(guest_id: StringName) -> String: return String(guest_id)),
		"menu_recipe_ids": Array(menu_recipe_ids).map(func(recipe_id: StringName) -> String: return String(recipe_id)),
		"learned_secret_ids": Array(learned_secret_ids).map(func(recipe_id: StringName) -> String: return String(recipe_id)),
		"grandma_taste_recipe_ids": Array(grandma_taste_recipe_ids).map(func(recipe_id: StringName) -> String: return String(recipe_id)),
		"guest_affection": _string_keys(guest_affection),
		"known_taste_guest_ids": Array(known_taste_guest_ids).map(func(guest_id: StringName) -> String: return String(guest_id)),
		"pending_reward_tiers": _string_keys(pending_reward_tiers),
		"keepsake_ids": Array(keepsake_ids).map(func(keepsake_id: StringName) -> String: return String(keepsake_id)),
		"extra_plots": _string_keys(extra_plots),
		"current_season": current_season,
		"is_spring_completed": is_spring_completed,
		"has_met_merchant": has_met_merchant,
		"is_feast_prep_announced": is_feast_prep_announced,
		"feast_prep_delivered": _string_keys(feast_prep_delivered),
	}


## JSON은 숫자를 소수(float)로, id를 문자열로 돌려주므로 여기서 원래 타입으로 바꾼다.
func _from_save_data(data: Dictionary) -> void:
	new_game()
	current_day = int(data.get("current_day", STARTING_DAY))
	player_name = str(data.get("player_name", ""))
	reputation = int(data.get("reputation", 0))
	var inventory_data: Dictionary = data.get("inventory", {})
	for ingredient_id: String in inventory_data:
		inventory[StringName(ingredient_id)] = int(inventory_data[ingredient_id])
	var recipe_data: Array = data.get("unlocked_recipe_ids", [])
	for recipe_id: Variant in recipe_data:
		unlocked_recipe_ids.append(StringName(str(recipe_id)))
	var story_data: Dictionary = data.get("guest_story_progress", {})
	for guest_id: String in story_data:
		guest_story_progress[StringName(guest_id)] = int(story_data[guest_id])
	var extra_plot_data: Dictionary = data.get("extra_plots", {})
	for place_id: String in extra_plot_data:
		extra_plots[StringName(place_id)] = int(extra_plot_data[place_id])
	_load_garden(data)
	var met_data: Array = data.get("met_guest_ids", [])
	for guest_id: Variant in met_data:
		met_guest_ids.append(StringName(str(guest_id)))
	var menu_data: Array = data.get("menu_recipe_ids", [])
	for recipe_id: Variant in menu_data:
		menu_recipe_ids.append(StringName(str(recipe_id)))
	for recipe_id: Variant in data.get("learned_secret_ids", []):
		learned_secret_ids.append(StringName(str(recipe_id)))
	for recipe_id: Variant in data.get("grandma_taste_recipe_ids", []):
		grandma_taste_recipe_ids.append(StringName(str(recipe_id)))
	var affection_data: Dictionary = data.get("guest_affection", {})
	for guest_id: String in affection_data:
		guest_affection[StringName(guest_id)] = int(affection_data[guest_id])
	for guest_id: Variant in data.get("known_taste_guest_ids", []):
		known_taste_guest_ids.append(StringName(str(guest_id)))
	var pending_data: Dictionary = data.get("pending_reward_tiers", {})
	for guest_id: String in pending_data:
		pending_reward_tiers[StringName(guest_id)] = Array(pending_data[guest_id]).map(func(tier: Variant) -> int: return int(tier))
	for keepsake_id: Variant in data.get("keepsake_ids", []):
		keepsake_ids.append(StringName(str(keepsake_id)))
	current_season = clampi(int(data.get("current_season", Season.Id.SPRING)), 0, Season.Id.size() - 1) as Season.Id
	is_spring_completed = bool(data.get("is_spring_completed", false))
	has_met_merchant = bool(data.get("has_met_merchant", false))
	is_feast_prep_announced = bool(data.get("is_feast_prep_announced", false))
	var feast_data: Dictionary = data.get("feast_prep_delivered", {})
	for ingredient_id: String in feast_data:
		feast_prep_delivered[StringName(ingredient_id)] = int(feast_data[ingredient_id])


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


## Dictionary 의 StringName 키를 JSON 에 넣을 수 있게 String 키로 바꾼다.
func _string_keys(table: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: Variant in table:
		result[String(key)] = table[key]
	return result
