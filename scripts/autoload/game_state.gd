extends Node
## 게임 전체에서 쓰는 상태(인벤토리, 날짜, 해금된 레시피)를 관리하는 오토로드.
## 프로젝트 설정 > 전역 > 자동 로드 에 "GameState" 이름으로 등록해서 쓴다.
## 재료와 레시피는 Resource 대신 id(StringName)로 기억한다. 그래야 세이브 파일에 그대로 저장할 수 있다.

signal inventory_changed(ingredient_id: StringName, new_count: int)
signal day_changed(new_day: int)
signal recipe_unlocked(recipe_id: StringName)
signal reputation_changed(new_reputation: int)
signal feast_prep_changed
## 손님 수첩에 새로 적힌 것(새 손님, 알아낸 입맛)이 생기거나 수첩을 봤을 때
signal notebook_changed

const SAVE_PATH: String = "user://save.json"
## 안전하게 저장하려고 먼저 써 보는 임시 파일, 바로 앞 저장을 남겨 두는 백업 파일.
## 저장하다 꺼지거나 세이브가 상해도 백업(하루 전 밤 저장)으로 이어 할 수 있다.
const SAVE_TEMP_PATH: String = "user://save.json.tmp"
const SAVE_BACKUP_PATH: String = "user://save.json.bak"
## 세이브의 각 값이 가져야 할 모양 (모양이 틀린 세이브는 상한 것으로 보고 백업을 쓴다)
const SAVE_DICTIONARY_KEYS: PackedStringArray = ["inventory", "extra_plots", "feast_prep_delivered", "guest_affection",
		"guest_story_progress", "pending_reward_tiers", "garden"]
const SAVE_ARRAY_KEYS: PackedStringArray = ["basket_guest_ids", "grandma_taste_recipe_ids", "keepsake_ids",
		"known_taste_guest_ids", "learned_secret_ids", "menu_recipe_ids", "solved_note_puzzle_ids", "met_guest_ids", "porch_met_guest_ids",
		"seen_duo_talk_ids", "seen_guest_ids", "seen_memory_ids", "seen_story_chapter_ids", "todays_guest_ids",
		"unlocked_place_ids", "unlocked_recipe_ids", "used_basket_note_ids", "garden_days_left", "notebook_viewed_keys"]
const SAVE_NUMBER_KEYS: PackedStringArray = ["version", "current_day", "current_season", "promise_day", "reputation", "todays_guests_day",
		"rewarded_shop_tier"]
## 2026-10-08 전 가게 단계 기준: 마지막 단계(소문난 할매식당)는 소문 220. 그 뒤 데모에서 보이게 150으로 낮췄다.
## rewarded_shop_tier 가 없는 옛 세이브가 그때 이미 받은 단계 보상을 계산할 때만 쓴다.
const OLD_FINAL_SHOP_TIER: int = 3
const OLD_FINAL_SHOP_TIER_REPUTATION: int = 220
const SAVE_BOOL_KEYS: PackedStringArray = ["has_met_merchant", "is_feast_prep_announced", "is_raining_today", "is_spring_completed"]
const SAVE_STRING_KEYS: PackedStringArray = ["player_name", "promise_guest_id", "promise_recipe_id"]
## 세이브 파일 구조가 바뀌면 숫자를 올린다. 옛 세이브를 읽을 때 구분하는 데 쓴다.
## 2: 텃밭이 여러 곳(GardenPlace)이 되고 칸마다 심은 작물을 저장한다.
const SAVE_VERSION: int = 2
## 빈 칸의 작물 id
const EMPTY_PLOT: StringName = &""
## 옛 세이브(버전 1)의 텃밭 칸이 속한 밭
const LEGACY_GARDEN_PLACE_ID: StringName = &"carrot_field"
const STARTING_DAY: int = 1
## 가게 단계 데이터가 없을 때 점심 손님 수의 최대값
const DEFAULT_MAX_GUESTS: int = 3

var current_day: int = STARTING_DAY
## 프롤로그에서 지은 주인공 이름 (할머니의 손주). 아직 안 지었으면 빈 문자열.
var player_name: String = ""
## 지금까지 쌓인 가게 소문. 쌓일수록 가게 단계(이름)가 오른다 (ReputationSettings).
var reputation: int = 0
## 단계 보상(밭 칸)을 이미 준 가장 높은 가게 단계. 소문 기준이 바뀌어도 보상이 빠지거나 두 번 들어가지 않게 따로 적는다.
var rewarded_shop_tier: int = 0
## 재료 id → 개수
var inventory: Dictionary[StringName, int] = {}
var unlocked_recipe_ids: Array[StringName] = []
## 밭 id → 칸마다 심은 작물 id (EMPTY_PLOT = 빈 칸)
var plot_crop_ids: Dictionary[StringName, Array] = {}
## 밭 id → 칸마다 다 자라기까지 남은 날 수 (0 = 거둘 수 있음)
var plot_days_left: Dictionary[StringName, Array] = {}
## 이웃 바구니에 재료를 두고 간 손님 id (저녁 평상에 왔던 손님들. 한 번 올 때마다 한 칸). 바구니를 열면 비운다.
var basket_guest_ids: Array[StringName] = []
## 숲속 장터: 너구리 상인을 만났는지 (첫 인사를 한 번만 하려고 저장한다)
var has_met_merchant: bool = false
## 이미 본 할머니 회상 장면 id (MemoryBook)
var seen_memory_ids: Array[StringName] = []
## 오늘 봄비가 오는지 (RainSettings). 아침에 정해서 저장해 둔다 (불러오기로 다시 뽑지 않게).
var is_raining_today: bool = false
## 오늘 장터에서 거래마다 바꾼 횟수 (거래 id → 횟수). 하루가 지나면 비운다. 장날 낮의 일이라 저장하지 않는다.
var todays_market_trades: Dictionary[StringName, int] = {}
## 오늘 장터에 다녀왔는지. 텃밭이 장터 버튼과 부엌 버튼 중 무엇을 먼저 선택해 둘지 정할 때 쓴다. 저장하지 않는다.
var has_visited_market_today: bool = false
## 아침에 고른 오늘의 메뉴 (레시피 id). 점심 손님은 이 안에서만 주문한다.
## 다음 날 아침 메뉴판에서 미리 골라 두는 데도 쓰고, 세이브에도 넣는다. 비어 있으면 메뉴 제한이 없다.
var menu_recipe_ids: Array[StringName] = []
## 한 번이라도 대접한 손님 id. 손님 수첩에 그 손님 정보를 보여 줄 때 쓴다.
var met_guest_ids: Array[StringName] = []
## 점심에 왔다가 먹을 게 없어 대접받지 못하고 돌아간 손님 id. 얼굴을 봤으니 이름만 알고, 수첩 기록은 대접해야 적힌다.
var seen_guest_ids: Array[StringName] = []
## 손님 id → 저녁 평상에서 지금까지 들려준 이야기 수
var guest_story_progress: Dictionary[StringName, int] = {}
## 저녁 평상에서 이미 본 손님 사연 막 id (GuestStoryChapter)
var seen_story_chapter_ids: Array[StringName] = []
## 단골의 약속 주문: 저녁 평상에서 약속한 손님, 요리, 그 점심 날짜 (약속이 없으면 promise_day = 0)
var promise_guest_id: StringName = &""
var promise_recipe_id: StringName = &""
var promise_day: int = 0
## 오늘 점심에 올 손님 id (오는 차례대로, 약속한 손님이 맨 앞)와 그 날짜. 아침에 메뉴판이나 부엌이 처음 물을 때 정해서 저장한다.
## 메뉴판에 미리 보여 주므로, 불러오기를 해도 다시 뽑지 않는다.
var todays_guest_ids: Array[StringName] = []
var todays_guests_day: int = 0
## 이웃 바구니 쪽지로 이미 남긴 사연 막 id (같은 사연 쪽지를 두 번 남기지 않게)
var used_basket_note_ids: Array[StringName] = []
## 저녁 평상에서 이미 본 손님끼리 대화 id (GuestDuoTalk)
var seen_duo_talk_ids: Array[StringName] = []
## 손님에게 들어서 알게 된 할머니 비법 (레시피 id)
var learned_secret_ids: Array[StringName] = []
## 번진 할머니 노트 퍼즐을 푼 레시피 id (NotePuzzle)
var solved_note_puzzle_ids: Array[StringName] = []
## 할머니 손맛으로 한 번이라도 대접한 레시피 (레시피 노트 도장)
var grandma_taste_recipe_ids: Array[StringName] = []
## 손님 id → 단골도 (대접할수록 오른다. 단계는 RegularSettings 로 정한다)
var guest_affection: Dictionary[StringName, int] = {}
## 입맛(좋아하는 고명)을 알아낸 손님 id. 손님 수첩에 입맛을 보여 줄 때 쓴다.
var known_taste_guest_ids: Array[StringName] = []
## 손님 수첩에서 이미 본 기록 ("guest:토끼 id", "taste:토끼 id"). 아직 안 본 기록이 있으면 수첩 버튼에 ● 표시.
var notebook_viewed_keys: Array[String] = []
## 손님 id → 단계는 올랐지만 아직 저녁에 보상(새 이야기, 선물)을 받지 않은 단골 단계들
var pending_reward_tiers: Dictionary[StringName, Array] = {}
## 손님에게 받은 할머니 기념품 id
var keepsake_ids: Array[StringName] = []
## 밭 id → 단골 선물로 늘어난 칸 수
var extra_plots: Dictionary[StringName, int] = {}
## 밭 id → 하룻밤 사이 자란 모습을 마지막으로 보여 준 날 (그날 처음 밭에 왔을 때만 쑥 자라게). 저장하지 않는다.
var growth_shown_day: Dictionary[StringName, int] = {}
## 저녁 평상에 한 번이라도 온 손님 id (처음 온 손님은 인사부터 한다)
var porch_met_guest_ids: Array[StringName] = []
## 열린 밭 id (GardenPlace.unlock_ingredient 를 처음 얻으면 열린다). 처음부터 열린 밭은 넣지 않는다.
var unlocked_place_ids: Array[StringName] = []
## 방금 열려서 다음 텃밭에서 알려 줄 밭 id. 저장하지 않는다.
var newly_unlocked_place_ids: Array[StringName] = []
## 계절 잔치 준비: 장보기 목록을 받았는지, 잔치 바구니에 모은 재료 (재료 id → 개수). 계절이 끝나면 비운다.
var is_feast_prep_announced: bool = false
var feast_prep_delivered: Dictionary[StringName, int] = {}
## 오늘 텃밭에서 잔치 바구니를 열어 봤는지 (텃밭이 무엇을 먼저 선택해 둘지 정할 때). 저장하지 않는다.
var has_opened_feast_prep_today: bool = false
## 지금 계절. 평상에서는 이 계절의 레시피 노트만 돌려받는다. 계절마다 다른 것은 GameData.get_current_season() 에서.
var current_season: Season.Id = Season.Id.SPRING
## 봄 잔치까지 보고 봄을 마쳤는지 (예전 세이브: 봄을 마치고 타이틀로 돌아간 세이브는 불러올 때 여름 1일째로 넘긴다)
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
	# 밭을 먼저 열어야, 재료가 바뀌었다는 신호를 받은 화면이 열린 상태를 본다.
	if amount > 0:
		_unlock_places_by_ingredient(ingredient_id)
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
	todays_market_trades.clear()
	has_visited_market_today = false
	has_opened_feast_prep_today = false
	for place_id: StringName in plot_days_left:
		var days: Array = plot_days_left[place_id]
		for i: int in days.size():
			days[i] = maxi(days[i] - 1, 0)
	is_raining_today = GameData.get_rain_settings().will_rain(current_day, is_raining_today)
	day_changed.emit(current_day)


## 오늘 대접한 손님을 기록한다. 같은 손님을 여러 번 대접했으면 한 번이라도 완벽했는지를 남긴다.
func record_served_guest(guest_id: StringName, is_perfect: bool) -> void:
	todays_served_guests[guest_id] = todays_served_guests.get(guest_id, false) or is_perfect
	if guest_id not in met_guest_ids:
		met_guest_ids.append(guest_id)
		notebook_changed.emit()


## 손님 수첩에 아직 안 본 기록(처음 대접한 손님, 새로 알아낸 입맛)이 있는지
func has_unviewed_notebook_entries() -> bool:
	return _notebook_keys().any(func(key: String) -> bool: return key not in notebook_viewed_keys)


## 손님 수첩을 열었다: 지금 있는 기록을 모두 본 것으로 적는다.
func mark_notebook_viewed() -> void:
	for key: String in _notebook_keys():
		if key not in notebook_viewed_keys:
			notebook_viewed_keys.append(key)
	notebook_changed.emit()


func _notebook_keys() -> Array[String]:
	var keys: Array[String] = []
	for guest_id: StringName in met_guest_ids:
		keys.append("guest:" + guest_id)
	for guest_id: StringName in known_taste_guest_ids:
		keys.append("taste:" + guest_id)
	return keys


## 이번 계절 레시피 노트 중 되찾은 장 수 (처음부터 가진 레시피도 센다)
func count_found_notes() -> int:
	return GameData.get_all_recipes().filter(func(recipe: Recipe) -> bool:
			return recipe.note_season == current_season and is_recipe_unlocked(recipe.id)).size()


func has_met_guest(guest_id: StringName) -> bool:
	return guest_id in met_guest_ids


## 점심에 얼굴을 본 손님으로 적는다 (대접은 못 했을 때).
func see_guest(guest_id: StringName) -> void:
	if guest_id not in seen_guest_ids:
		seen_guest_ids.append(guest_id)


## 이름을 아는 손님인지: 대접했거나, 왔다가 돌아가는 걸 봤거나
func has_seen_guest(guest_id: StringName) -> bool:
	return has_met_guest(guest_id) or guest_id in seen_guest_ids


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


# --- 단골의 약속 주문 ---

func make_promise(guest_id: StringName, recipe_id: StringName, day: int) -> void:
	promise_guest_id = guest_id
	promise_recipe_id = recipe_id
	promise_day = day


func clear_promise() -> void:
	promise_guest_id = &""
	promise_recipe_id = &""
	promise_day = 0


## day 날 점심에 약속이 있는지
func has_promise_on(day: int) -> bool:
	return promise_day == day and day > 0 and promise_guest_id != &""


## 손님이 지금 할 사연 막 (없으면 null)
func get_next_story_chapter(guest: AnimalGuest) -> GuestStoryChapter:
	return guest.get_next_story_chapter(current_season, current_day, seen_story_chapter_ids)


# --- 오늘 올 손님 ---

## 오늘 점심에 올 손님 id (차례대로). 오늘 아직 안 정했으면 지금 정한다.
func get_todays_guest_ids() -> Array[StringName]:
	if todays_guests_day != current_day:
		_choose_todays_guests()
	return todays_guest_ids


## 오늘 손님 수 = min(되찾은 레시피 수, 메뉴 칸 수) + 메뉴보다 더 오는 손님 + 가게 단계 보너스. 최대는 가게 단계의 max_guests.
## 메뉴를 고르기 전에 정하므로, 고른 메뉴 수 대신 낼 수 있는 최대 메뉴 수로 센다.
func get_todays_guest_count() -> int:
	var dishes: int = mini(unlocked_recipe_ids.size(), get_menu_slots())
	var level: ShopLevel = get_shop_level()
	var bonus: int = level.extra_guests if level != null else 0
	var max_guests: int = level.max_guests if level != null else DEFAULT_MAX_GUESTS
	return clampi(dishes + GameData.get_menu_settings().extra_guests_over_menu + bonus, 1, max_guests)


## 특별한 점심 날(SpecialLunch)이면 그 주인 손님(host)이 맨 앞, 아니면 약속한 손님이 맨 앞. 다음은 오늘 사연 막이 새로 열리는 손님 (잠들 때 "내일은… 무슨 일이 있는 것 같아요"로 알린 손님),
## 나머지는 이번 계절 손님을 섞어서 채운다 (손님이 모자랄 때만 같은 손님이 또 온다).
func _choose_todays_guests() -> void:
	todays_guests_day = current_day
	todays_guest_ids.clear()
	var count: int = get_todays_guest_count()
	var special: SpecialLunch = GameData.get_special_lunch(current_day)
	if special != null and GameData.get_guest(special.host_id) != null:
		todays_guest_ids.append(special.host_id)
	if has_promise_on(current_day) and GameData.get_guest(promise_guest_id) != null and promise_guest_id not in todays_guest_ids:
		todays_guest_ids.append(promise_guest_id)
	var story_guests: Array[AnimalGuest] = GameData.get_season_guests().filter(func(guest: AnimalGuest) -> bool:
			var chapter: GuestStoryChapter = get_next_story_chapter(guest)
			return chapter != null and chapter.open_day == current_day)
	story_guests.shuffle()
	for guest: AnimalGuest in story_guests:
		if todays_guest_ids.size() < count and guest.id not in todays_guest_ids:
			todays_guest_ids.append(guest.id)
	var pool: Array[AnimalGuest] = []
	while todays_guest_ids.size() < count:
		if pool.is_empty():
			pool = GameData.get_season_guests()
			if pool.is_empty():
				return
			pool.shuffle()
		var guest: AnimalGuest = pool.pop_front()
		if guest.id not in todays_guest_ids or pool.is_empty():
			todays_guest_ids.append(guest.id)


## 지금 계절에 사연이 있는 손님들의 사연을 모두 끝까지 봤는지 (사연이 하나도 없으면 false)
func are_season_stories_finished() -> bool:
	var has_story: bool = false
	for guest: AnimalGuest in GameData.get_all_guests():
		if guest.story_chapters.any(func(chapter: GuestStoryChapter) -> bool:
				return chapter != null and chapter.season == current_season):
			has_story = true
			if not guest.has_finished_story(current_season, seen_story_chapter_ids):
				return false
	return has_story


func see_story_chapter(chapter_id: StringName) -> void:
	if chapter_id not in seen_story_chapter_ids:
		seen_story_chapter_ids.append(chapter_id)


# --- 레시피 ---

## 오늘의 메뉴 칸 수: 되찾은 레시피(모든 계절)가 늘수록 는다 (MenuSettings)
func get_menu_slots() -> int:
	return GameData.get_menu_settings().get_max_dishes(unlocked_recipe_ids.size())


func unlock_recipe(recipe_id: StringName) -> void:
	if is_recipe_unlocked(recipe_id):
		return
	unlocked_recipe_ids.append(recipe_id)
	recipe_unlocked.emit(recipe_id)


## 계절 마무리 날(SeasonEnding.last_day)부터는 저녁에 평상 대신 계절 마무리(봄 잔치 등)가 열린다.
## 노트를 다 모았는지와는 상관없다. 마무리가 없는 계절(만드는 중)은 끝나지 않는다.
func is_season_end_day() -> bool:
	var ending: SeasonEnding = GameData.get_season_ending()
	return ending != null and current_day >= ending.last_day


## 지금 계절을 마치고 다음 계절 1일째로 넘어간다. 재료·레시피·단골·가게 단계·기념품·텃밭은 그대로 이어진다.
## 다음 계절 데이터가 없으면 아무것도 안 하고 false.
func start_next_season() -> bool:
	var season: SeasonData = GameData.get_current_season()
	var next: SeasonData = GameData.get_season(season.next_season) if season != null else null
	if next == null or next.id == current_season:
		return false
	if current_season == Season.Id.SPRING:
		is_spring_completed = true
	current_season = next.id
	current_day = STARTING_DAY
	todays_served_guests.clear()
	todays_market_trades.clear()
	clear_promise()
	todays_guest_ids.clear()
	todays_guests_day = 0
	has_visited_market_today = false
	is_feast_prep_announced = false
	feast_prep_delivered.clear()
	has_opened_feast_prep_today = false
	is_raining_today = GameData.get_rain_settings().will_rain(current_day, false)
	day_changed.emit(current_day)
	return true


func is_recipe_unlocked(recipe_id: StringName) -> bool:
	return recipe_id in unlocked_recipe_ids


# --- 할머니 비법 ---

func is_secret_learned(recipe_id: StringName) -> bool:
	return recipe_id in learned_secret_ids


func learn_secret(recipe_id: StringName) -> void:
	if recipe_id not in learned_secret_ids:
		learned_secret_ids.append(recipe_id)


# --- 번진 할머니 노트 퍼즐 ---

func is_note_puzzle_solved(recipe_id: StringName) -> bool:
	return recipe_id in solved_note_puzzle_ids


func solve_note_puzzle(recipe_id: StringName) -> void:
	if recipe_id not in solved_note_puzzle_ids:
		solved_note_puzzle_ids.append(recipe_id)


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
	_give_shop_tier_rewards(after)
	return after if after > before else -1


## 아직 보상을 안 준 가게 단계마다 밭 칸을 늘린다 (한 번에 두 단계가 올라도 둘 다 준다).
func _give_shop_tier_rewards(up_to_tier: int) -> void:
	for tier: int in range(rewarded_shop_tier + 1, up_to_tier + 1):
		var level: ShopLevel = GameData.get_reputation_settings().get_shop_level(tier)
		if level != null and not level.bonus_plot_place_id.is_empty():
			for i: int in level.bonus_plot_count:
				add_plot(level.bonus_plot_place_id)
	rewarded_shop_tier = maxi(rewarded_shop_tier, up_to_tier)


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
		notebook_changed.emit()


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


# --- 잠긴 밭 ---

## 밭에 갈 수 있는지. unlock_ingredient 가 없는 밭은 처음부터 열려 있다.
func is_place_unlocked(place_id: StringName) -> bool:
	var place: GardenPlace = GameData.get_garden_place(place_id)
	return place == null or place.unlock_ingredient == null or place_id in unlocked_place_ids


func _unlock_place(place_id: StringName, should_notify: bool) -> void:
	if place_id in unlocked_place_ids:
		return
	unlocked_place_ids.append(place_id)
	if should_notify:
		newly_unlocked_place_ids.append(place_id)


## 이 재료로 열리는 밭이 있으면 연다 (다음 텃밭에서 알려 준다).
func _unlock_places_by_ingredient(ingredient_id: StringName) -> void:
	for place: GardenPlace in GameData.get_all_garden_places():
		if place.unlock_ingredient != null and place.unlock_ingredient.id == ingredient_id:
			_unlock_place(place.id, true)


## 예전 세이브: 이미 그 재료를 가졌거나 그 밭에 뭔가 심어 두었으면 조용히 연다.
func _unlock_places_from_state() -> void:
	for place: GardenPlace in GameData.get_all_garden_places():
		if place.unlock_ingredient == null or place.id in unlocked_place_ids:
			continue
		var has_planted: bool = plot_crop_ids.get(place.id, []).any(
				func(crop_id: Variant) -> bool: return StringName(crop_id) != EMPTY_PLOT)
		if get_ingredient_count(place.unlock_ingredient.id) > 0 or has_planted:
			_unlock_place(place.id, false)


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
	rewarded_shop_tier = 0
	inventory.clear()
	unlocked_recipe_ids.clear()
	guest_story_progress.clear()
	seen_story_chapter_ids.clear()
	seen_duo_talk_ids.clear()
	used_basket_note_ids.clear()
	clear_promise()
	todays_guest_ids.clear()
	todays_guests_day = 0
	todays_served_guests.clear()
	plot_crop_ids.clear()
	plot_days_left.clear()
	met_guest_ids.clear()
	seen_guest_ids.clear()
	menu_recipe_ids.clear()
	learned_secret_ids.clear()
	solved_note_puzzle_ids.clear()
	grandma_taste_recipe_ids.clear()
	guest_affection.clear()
	known_taste_guest_ids.clear()
	notebook_viewed_keys.clear()
	pending_reward_tiers.clear()
	keepsake_ids.clear()
	extra_plots.clear()
	unlocked_place_ids.clear()
	newly_unlocked_place_ids.clear()
	porch_met_guest_ids.clear()
	growth_shown_day.clear()
	current_season = Season.Id.SPRING
	is_spring_completed = false
	basket_guest_ids.clear()
	has_met_merchant = false
	is_raining_today = false
	seen_memory_ids.clear()
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
	is_raining_today = GameData.get_rain_settings().will_rain(current_day, false)
	var setup: StartingSetup = GameData.get_starting_setup()
	if setup == null:
		return
	for ingredient: Ingredient in setup.starting_ingredients:
		add_ingredient(ingredient.id)
	for recipe: Recipe in setup.starting_recipes:
		unlock_recipe(recipe.id)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_BACKUP_PATH)


## 세이브 파일을 불러오지 않고 내용만 읽는다. 타이틀 화면에서 "N일째"를 보여 줄 때 쓴다. 못 읽으면 빈 Dictionary.
## 세이브가 상했으면 백업의 내용을 읽는다 (load_game 이 이어 할 것과 같게).
func read_save_summary() -> Dictionary:
	return _read_usable_save()


func delete_save() -> void:
	for path: String in [SAVE_PATH, SAVE_TEMP_PATH, SAVE_BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## 안전하게 저장한다: 임시 파일에 먼저 쓰고 다시 읽어 확인한 뒤, 지금 세이브를 백업으로 옮기고 임시 파일을 세이브로 바꾼다.
## 저장하다 꺼져도 세이브나 백업 중 하나는 멀쩡하게 남는다.
func save_game() -> bool:
	var file: FileAccess = FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("세이브 실패: %s" % error_string(FileAccess.get_open_error()))
		return false
	var is_written: bool = file.store_string(JSON.stringify(_to_save_data(), "\t"))
	file.close()
	if not is_written or not _is_usable_save(_parse_save(SAVE_TEMP_PATH)):
		push_error("세이브 실패: 임시 파일을 다시 읽을 수 없습니다 (%s)" % SAVE_TEMP_PATH)
		return false
	if _is_usable_save(_parse_save(SAVE_PATH)):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(SAVE_BACKUP_PATH))
	var error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_TEMP_PATH),
			ProjectSettings.globalize_path(SAVE_PATH))
	if error != OK:
		push_error("세이브 실패: %s" % error_string(error))
		return false
	return true


func load_game() -> bool:
	var data: Dictionary = _read_usable_save()
	if data.is_empty():
		push_error("세이브 파일과 백업을 모두 읽을 수 없습니다: %s" % SAVE_PATH)
		return false
	_from_save_data(data)
	is_game_started = true
	if rewarded_shop_tier < 0:
		rewarded_shop_tier = OLD_FINAL_SHOP_TIER if reputation >= OLD_FINAL_SHOP_TIER_REPUTATION \
				else mini(get_shop_tier(), OLD_FINAL_SHOP_TIER - 1)
	# 소문 기준이 낮아져 이미 넘은 단계가 있으면, 빠진 단계 보상(밭 칸)을 지금 준다.
	_give_shop_tier_rewards(get_shop_tier())
	# 예전 세이브: 봄을 마치고 타이틀로 돌아갔던 세이브는 여름이 생겼으니 여름 1일째부터 이어 간다.
	# 봄 잔치에서 데모가 끝나는 동안(봄 마무리 데이터의 is_demo_end)은 봄 완료 그대로 둔다.
	if is_spring_completed and current_season == Season.Id.SPRING and not GameData.is_demo_end_season(current_season):
		start_next_season()
	return true


## 쓸 수 있는 세이브 내용: 세이브가 멀쩡하면 그것, 상했으면 백업, 둘 다 안 되면 빈 Dictionary.
func _read_usable_save() -> Dictionary:
	for path: String in [SAVE_PATH, SAVE_BACKUP_PATH]:
		var data: Variant = _parse_save(path)
		if _is_usable_save(data):
			if path == SAVE_BACKUP_PATH:
				push_warning("세이브가 상해서 백업으로 이어 합니다: %s" % SAVE_BACKUP_PATH)
			return data
	return {}


## 파일을 JSON 으로 읽는다. 없거나 비었거나 읽을 수 없으면 null.
func _parse_save(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var text: String = FileAccess.get_file_as_string(path)
	if text.strip_edges().is_empty():
		return null
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data


## 불러와도 되는 세이브인지: Dictionary 이고, 들어 있는 값들이 저마다 맞는 모양인지 (없는 값은 괜찮다, 기본값을 쓴다).
func _is_usable_save(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var save: Dictionary = data
	if not save.has("current_day"):
		return false
	for key: String in SAVE_DICTIONARY_KEYS:
		if save.has(key) and not save[key] is Dictionary:
			return false
	for key: String in SAVE_ARRAY_KEYS:
		if save.has(key) and not save[key] is Array:
			return false
	for key: String in SAVE_NUMBER_KEYS:
		if save.has(key) and not (save[key] is float or save[key] is int):
			return false
	for key: String in SAVE_BOOL_KEYS:
		if save.has(key) and not save[key] is bool:
			return false
	for key: String in SAVE_STRING_KEYS:
		if save.has(key) and not save[key] is String:
			return false
	# 텃밭: {밭 id: [{"crop": ..., "days_left": ...}, ...]}
	var garden: Dictionary = save.get("garden", {})
	for place_id: Variant in garden:
		if not garden[place_id] is Array:
			return false
		for plot: Variant in garden[place_id]:
			if not plot is Dictionary:
				return false
	return true


func _to_save_data() -> Dictionary:
	# 잠들 때 저장하므로, 내일(이미 넘어간 오늘) 손님을 여기서 정해 같이 저장한다. 불러오기로 손님을 다시 뽑지 못하게.
	get_todays_guest_ids()
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
		"rewarded_shop_tier": rewarded_shop_tier,
		"inventory": inventory_data,
		"unlocked_recipe_ids": recipe_data,
		"guest_story_progress": story_data,
		"garden": _garden_save_data(),
		"met_guest_ids": Array(met_guest_ids).map(func(guest_id: StringName) -> String: return String(guest_id)),
		"seen_guest_ids": Array(seen_guest_ids).map(func(guest_id: StringName) -> String: return String(guest_id)),
		"menu_recipe_ids": Array(menu_recipe_ids).map(func(recipe_id: StringName) -> String: return String(recipe_id)),
		"learned_secret_ids": Array(learned_secret_ids).map(func(recipe_id: StringName) -> String: return String(recipe_id)),
		"solved_note_puzzle_ids": Array(solved_note_puzzle_ids).map(func(recipe_id: StringName) -> String: return String(recipe_id)),
		"grandma_taste_recipe_ids": Array(grandma_taste_recipe_ids).map(func(recipe_id: StringName) -> String: return String(recipe_id)),
		"guest_affection": _string_keys(guest_affection),
		"known_taste_guest_ids": Array(known_taste_guest_ids).map(func(guest_id: StringName) -> String: return String(guest_id)),
		"notebook_viewed_keys": notebook_viewed_keys.duplicate(),
		"pending_reward_tiers": _string_keys(pending_reward_tiers),
		"keepsake_ids": Array(keepsake_ids).map(func(keepsake_id: StringName) -> String: return String(keepsake_id)),
		"extra_plots": _string_keys(extra_plots),
		"unlocked_place_ids": Array(unlocked_place_ids).map(func(place_id: StringName) -> String: return String(place_id)),
		"porch_met_guest_ids": Array(porch_met_guest_ids).map(func(guest_id: StringName) -> String: return String(guest_id)),
		"current_season": current_season,
		"is_spring_completed": is_spring_completed,
		"has_met_merchant": has_met_merchant,
		"is_raining_today": is_raining_today,
		"basket_guest_ids": Array(basket_guest_ids).map(func(guest_id: StringName) -> String: return String(guest_id)),
		"seen_memory_ids": Array(seen_memory_ids).map(func(memory_id: StringName) -> String: return String(memory_id)),
		"seen_story_chapter_ids": Array(seen_story_chapter_ids).map(func(chapter_id: StringName) -> String: return String(chapter_id)),
		"seen_duo_talk_ids": Array(seen_duo_talk_ids).map(func(talk_id: StringName) -> String: return String(talk_id)),
		"used_basket_note_ids": Array(used_basket_note_ids).map(func(chapter_id: StringName) -> String: return String(chapter_id)),
		"promise_guest_id": String(promise_guest_id),
		"promise_recipe_id": String(promise_recipe_id),
		"promise_day": promise_day,
		"todays_guest_ids": Array(todays_guest_ids).map(func(guest_id: StringName) -> String: return String(guest_id)),
		"todays_guests_day": todays_guests_day,
		"is_feast_prep_announced": is_feast_prep_announced,
		"feast_prep_delivered": _string_keys(feast_prep_delivered),
	}


## JSON은 숫자를 소수(float)로, id를 문자열로 돌려주므로 여기서 원래 타입으로 바꾼다.
func _from_save_data(data: Dictionary) -> void:
	new_game()
	current_day = int(data.get("current_day", STARTING_DAY))
	player_name = str(data.get("player_name", ""))
	reputation = int(data.get("reputation", 0))
	# 없으면(2026-10-08 전 세이브) 예전 기준으로 이미 받았을 단계를 계산한다.
	rewarded_shop_tier = int(data.get("rewarded_shop_tier", -1))
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
	for place_id: Variant in data.get("unlocked_place_ids", []):
		unlocked_place_ids.append(StringName(str(place_id)))
	for guest_id: Variant in data.get("porch_met_guest_ids", []):
		porch_met_guest_ids.append(StringName(str(guest_id)))
	# 예전 세이브: 저녁 이야기를 나눈 적 있는 손님은 평상에 와 본 손님으로 친다 (인사를 또 하지 않게).
	if not data.has("porch_met_guest_ids"):
		for guest_id: StringName in guest_story_progress:
			if guest_story_progress[guest_id] > 0 and guest_id not in porch_met_guest_ids:
				porch_met_guest_ids.append(guest_id)
	for guest_id: Variant in data.get("seen_guest_ids", []):
		seen_guest_ids.append(StringName(str(guest_id)))
	var met_data: Array = data.get("met_guest_ids", [])
	for guest_id: Variant in met_data:
		met_guest_ids.append(StringName(str(guest_id)))
	var menu_data: Array = data.get("menu_recipe_ids", [])
	for recipe_id: Variant in menu_data:
		menu_recipe_ids.append(StringName(str(recipe_id)))
	for recipe_id: Variant in data.get("learned_secret_ids", []):
		learned_secret_ids.append(StringName(str(recipe_id)))
	for recipe_id: Variant in data.get("solved_note_puzzle_ids", []):
		solved_note_puzzle_ids.append(StringName(str(recipe_id)))
	for recipe_id: Variant in data.get("grandma_taste_recipe_ids", []):
		grandma_taste_recipe_ids.append(StringName(str(recipe_id)))
	var affection_data: Dictionary = data.get("guest_affection", {})
	for guest_id: String in affection_data:
		guest_affection[StringName(guest_id)] = int(affection_data[guest_id])
	for guest_id: Variant in data.get("known_taste_guest_ids", []):
		known_taste_guest_ids.append(StringName(str(guest_id)))
	for key: Variant in data.get("notebook_viewed_keys", []):
		notebook_viewed_keys.append(str(key))
	var pending_data: Dictionary = data.get("pending_reward_tiers", {})
	for guest_id: String in pending_data:
		pending_reward_tiers[StringName(guest_id)] = Array(pending_data[guest_id]).map(func(tier: Variant) -> int: return int(tier))
	for keepsake_id: Variant in data.get("keepsake_ids", []):
		keepsake_ids.append(StringName(str(keepsake_id)))
	current_season = clampi(int(data.get("current_season", Season.Id.SPRING)), 0, Season.Id.size() - 1) as Season.Id
	is_spring_completed = bool(data.get("is_spring_completed", false))
	has_met_merchant = bool(data.get("has_met_merchant", false))
	is_raining_today = bool(data.get("is_raining_today", false))
	for guest_id: Variant in data.get("basket_guest_ids", []):
		basket_guest_ids.append(StringName(str(guest_id)))
	for memory_id: Variant in data.get("seen_memory_ids", []):
		seen_memory_ids.append(StringName(str(memory_id)))
	for chapter_id: Variant in data.get("seen_story_chapter_ids", []):
		seen_story_chapter_ids.append(StringName(str(chapter_id)))
	for talk_id: Variant in data.get("seen_duo_talk_ids", []):
		seen_duo_talk_ids.append(StringName(str(talk_id)))
	for chapter_id: Variant in data.get("used_basket_note_ids", []):
		used_basket_note_ids.append(StringName(str(chapter_id)))
	promise_guest_id = StringName(str(data.get("promise_guest_id", "")))
	promise_recipe_id = StringName(str(data.get("promise_recipe_id", "")))
	promise_day = int(data.get("promise_day", 0))
	for guest_id: Variant in data.get("todays_guest_ids", []):
		todays_guest_ids.append(StringName(str(guest_id)))
	todays_guests_day = int(data.get("todays_guests_day", 0))
	_unlock_places_from_state()
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
