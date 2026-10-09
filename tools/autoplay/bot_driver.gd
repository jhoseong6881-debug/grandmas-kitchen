extends Node
## 진짜 화면을 차례로 눌러 가며 봄 한 철을 자동으로 플레이한다. 날마다 있었던 일과 이튿날 예고를 기록한다.
## 시험용 사본에서 오토로드로 붙여 돌린다 (tools/autoplay/run.sh). 진짜 프로젝트에 붙이지 말 것.
## 인자 (++ 뒤): 기록 파일 경로, 시드, 할머니 손맛 확률 (0~1, 비법 있는 단계를 비법대로 해낼 확률)

var log_path: String = ""
var day_log: Dictionary = {}
var lines: Array[String] = []
var _busy: bool = false
var _garden_done_day: int = -1
var _market_done_day: int = -1
var _porch_logged_day: int = -1
var _kitchen_logged_day: int = -1
var _finished: bool = false
var _start_ms: int = 0
var grandma_chance: float = 0.7
## 노트 퍼즐에서 일부러 틀리는 확률 (틀려도 손해가 없는지 보려고)
var puzzle_wrong_chance: float = 0.25

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	log_path = args[0] if args.size() > 0 else "user://bot_log.txt"
	if args.size() > 1:
		seed(int(args[1]))
	if args.size() > 2:
		grandma_chance = float(args[2])
	Engine.time_scale = 16.0
	_start_ms = Time.get_ticks_msec()
	await get_tree().process_frame
	await get_tree().process_frame
	GameState.start_new_game()
	GameState.is_game_started = true
	GameState.player_name = "철수"
	get_tree().change_scene_to_file("res://scenes/garden/garden.tscn")
	var timer: Timer = Timer.new()
	timer.wait_time = 0.12
	timer.ignore_time_scale = true
	timer.timeout.connect(_tick)
	add_child(timer)
	timer.start()

func _log(text: String) -> void:
	lines.append(text)

var _busy_since: int = 0
var _last_scene: String = ""
## 같은 장면·같은 날이 이 시간(ms, 실제 시간)보다 오래 이어지면 멈춘 것으로 보고 기록한 뒤 끝낸다.
const STALL_MS: int = 300000
var _stall_key: String = ""
var _stall_since: int = 0
func _tick() -> void:
	if _finished:
		return
	if _busy:
		if Time.get_ticks_msec() - _busy_since > 4000:
			_log("  (자동 플레이: %s 에서 4초 넘게 멈춰 다시 시도)" % _scene_path())
			_busy = false
		return
	if _scene_path() != _last_scene:
		_last_scene = _scene_path()
		print("[장면] %d일째 %s" % [GameState.current_day, _last_scene])
	if Time.get_ticks_msec() - _start_ms > 2700000:
		_log("!! 시간 초과 (45분) — 멈춘 곳: %s, %d일째" % [_scene_path(), GameState.current_day])
		_finish()
		return
	var stall_key: String = "%s|%d" % [_scene_path(), GameState.current_day]
	if stall_key != _stall_key:
		_stall_key = stall_key
		_stall_since = Time.get_ticks_msec()
	elif Time.get_ticks_msec() - _stall_since > STALL_MS:
		_log("!! 멈춤: %d일째 %s 에서 5분 넘게 그대로 — 보이는 버튼: %s" % [GameState.current_day, _scene_path(), _visible_button_texts()])
		_finish()
		return
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	_busy = true
	_busy_since = Time.get_ticks_msec()
	match scene.scene_file_path:
		"res://scenes/garden/garden.tscn": await _garden(scene)
		"res://scenes/garden/market.tscn": await _market(scene)
		"res://scenes/garden/mushroom_logs.tscn": _press_back(scene)
		"res://scenes/kitchen/kitchen.tscn": await _kitchen(scene)
		"res://scenes/porch/porch.tscn": _porch(scene)
		"res://scenes/porch/spring_feast.tscn": _feast(scene)
		"res://scenes/story/prologue.tscn": _story(scene)
		"res://scenes/ui/title.tscn":
			_log("타이틀로 돌아옴 (%d일째)" % GameState.current_day)
			_finish()
	_busy = false

func _visible_button_texts() -> String:
	var texts: Array[String] = []
	for n: Node in get_tree().root.find_children("*", "BaseButton", true, false):
		if (n as Control).is_visible_in_tree():
			texts.append((n as Button).text.replace("\n", " ") if n is Button and (n as Button).text != "" else String(n.name))
	return ", ".join(texts)


func _scene_path() -> String:
	return get_tree().current_scene.scene_file_path if get_tree().current_scene else "-"

func _finish() -> void:
	_finished = true
	var f: FileAccess = FileAccess.open(log_path, FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	get_tree().quit()

# --- 아침 텃밭 ---
func _garden(g: Node) -> void:
	if GameState.current_season != Season.Id.SPRING:
		_log("여름 1일째 아침 도착 → 끝")
		_finish()
		return
	var day: int = GameState.current_day
	if _garden_done_day != day:
		# 열린 창 닫기
		for child: Node in g.find_children("*", "", true, false):
			if child.has_method("close") and child is Control and (child as Control).visible and child.name != "GuestNotebook":
				child.close()
		# 바구니
		var basket: Button = g._basket_button
		var before: Dictionary = GameState.inventory.duplicate()
		if not basket.disabled:
			basket.pressed.emit()
			await get_tree().create_timer(0.3, true, false, true).timeout
			for child: Node in g.find_children("*", "", true, false):
				if child is BasketNote and (child as Control).visible:
					child.close()
		var got: Array[String] = []
		for id: StringName in GameState.inventory:
			var diff: int = GameState.inventory[id] - before.get(id, 0)
			if diff > 0: got.append("%s+%d" % [id, diff])
		# 밭: 다 자란 칸 거두고 빈 칸 심기
		var harvested: int = 0
		for place: GardenPlace in GameData.get_all_garden_places():
			if not GameState.is_place_unlocked(place.id): continue
			for i: int in GameState.get_plot_count(place.id):
				if GameState.is_plot_ripe(place.id, i):
					GameState.harvest_plot(place.id, i); harvested += 1
				if GameState.get_plot_crop(place.id, i) == null:
					for crop: Crop in place.crops:
						if GameState.can_plant(crop):
							GameState.plant_plot(place.id, i, crop); break
		# 잔치 준비 바구니
		var ending: SeasonEnding = GameData.get_season_ending()
		var delivered: int = 0
		if ending != null and ending.feast_prep != null and GameState.is_feast_prep_announced:
			for item: FeastItem in ending.feast_prep.items:
				delivered += GameState.deliver_to_feast(item, 1)
		day_log[day] = {"basket": got, "harvest": harvested, "feast_deliver": delivered}
		_garden_done_day = day
	# 장날 (아침 일 다음, 메뉴판 전에 한 번)
	if GameData.get_market_settings().is_market_day(day) and _market_done_day != day and g._market_button.visible:
		_market_done_day = day
		g._market_button.pressed.emit()
		# 장면이 실제로 장터로 바뀔 때까지 기다린다 (바뀌기 전에 텃밭을 한 번 더 처리하지 않게)
		for i: int in 120:
			await get_tree().process_frame
			if get_tree().current_scene != null and get_tree().current_scene.scene_file_path.ends_with("market.tscn"):
				break
		return
	if true:
		# 메뉴판
		g._menu_board.open()
		await get_tree().process_frame
		var board: MenuBoard = g._menu_board
		var ids: Array[StringName] = board._selected_ids.filter(func(id: StringName) -> bool:
				return GameState.has_ingredients(GameData.get_recipe(id).get_ingredient_counts()))
		if ids.is_empty():
			for r: Recipe in GameData.get_all_recipes():
				if GameState.is_recipe_unlocked(r.id) and GameState.has_ingredients(r.get_ingredient_counts()):
					ids.append(r.id); break
		if ids.is_empty():
			ids = board._selected_ids.duplicate()
			_log("  %d일 메뉴: 만들 수 있는 요리가 하나도 없음!" % day)
		board._selected_ids = ids
		day_log[day]["menu"] = ids.map(func(id: StringName) -> String: return GameData.get_recipe(id).display_name)
		day_log[day]["guests"] = GameState.get_todays_guest_ids().duplicate()
		board._on_start_button_pressed()

func _market(m: Node) -> void:
	await get_tree().create_timer(0.3, true, false, true).timeout
	if not is_instance_valid(m):
		_log("  (장터 화면이 기다리는 사이 바뀜: 지금 %s)" % _scene_path())
		return
	var done: Array[String] = []
	var trades: Array = m._trades if "_trades" in m else []
	for i: int in trades.size():
		var t: MarketTrade = trades[i]
		var have: int = GameState.get_ingredient_count(t.give_ingredient.id)
		if have >= t.give_amount + 3:
			m._on_trade_pressed(i)
			done.append("%s×%d→%s" % [t.give_ingredient.display_name, t.give_amount, t.get_ingredient.display_name])
	day_log[GameState.current_day]["market"] = done
	m._on_back_button_pressed()

func _press_back(s: Node) -> void:
	if "_back_button" in s: s._back_button.pressed.emit()

# --- 점심 ---
func _kitchen(k: Node) -> void:
	var day: int = GameState.current_day
	var d: Dictionary = day_log.get(day, {})
	if _kitchen_logged_day != day:
		_kitchen_logged_day = day
		d["served"] = 0; d["home"] = 0; d["boxes"] = []; d["birthday"] = ""
		d["puzzles"] = []; d["grandma"] = 0; d["garnish"] = []
		day_log[day] = d
	# 열려 있는 고르는 창
	if k._lunchbox_picker.visible:
		var owner: AnimalGuest = k.current_guest if k._is_chef_day else k._todays_guests[k._guests_served]
		var recipes: Array = k._lunchbox_picker._recipes
		var pick: int = -1
		var want_favorite: bool = not k._is_chef_day or randf() < 0.6
		for i: int in recipes.size():
			if GameState.has_ingredients(recipes[i].get_ingredient_counts()):
				if pick < 0: pick = i
				if want_favorite and recipes[i] in owner.favorite_recipes and recipes[i].id not in k._picnic_dishes:
					pick = i
		k._lunchbox_picker._close(pick)
		d["boxes"].append("%s:%s%s" % [owner.display_name, recipes[pick].display_name, "♥" if recipes[pick] in owner.favorite_recipes else ""])
		return
	# 번진 할머니 노트: 가끔 일부러 틀리고, 다 채우면 요리 시작
	var board: NotePuzzleBoard = k._note_puzzle_board
	if board.visible:
		if board._start_button.visible:
			d["puzzles"].append("%s(틀림 %d)" % [k.current_order.display_name, board._wrong_count])
			board._on_start_pressed()
			return
		if board._solved_count >= board._puzzle_lines.size():
			return
		var line: NotePuzzleLine = board._puzzle_lines[board._solved_count]
		var wrong: bool = randf() < puzzle_wrong_chance
		if line.kind == NotePuzzleLine.Kind.ORDER:
			var want: Ingredient = line.order_answer[board._order_filled]
			var pick_card: Ingredient = want
			if wrong:
				var others: Array[Ingredient] = line.get_order_cards().filter(func(c: Ingredient) -> bool: return c != want)
				if not others.is_empty():
					pick_card = others.pick_random()
			for b: Button in board._row_buttons():
				if b.text == pick_card.display_name:
					board._on_card_pressed(pick_card, b)
					return
			_log("  !! 노트 퍼즐(%s): 카드 '%s' 버튼을 못 찾음" % [k.current_order.display_name, pick_card.display_name])
			board._on_card_pressed(want, board._row_buttons()[0])
		else:
			board._on_choice_pressed(randi() % line.choices.size() if wrong else line.answer_index)
		return
	for mg: Minigame in k._minigames.values():
		if mg.visible and mg._is_playing:
			# 손으로 하는 동작은 건너뛰고 결과만 정한다: 세 번 해냈고, 비법·부탁 자리는 확률로.
			var grandma: bool = randf() < grandma_chance
			mg._hit_count = 3
			mg._secret_hit_count = 3 if grandma else 0
			mg._request_hit_count = 3 if randf() < 0.5 else 0
			if grandma and mg._step != null and mg._step.has_secret():
				d["grandma"] += 1
			mg._complete("완성")
			return
	# "완성~!" 장면: 손님 입맛 고명이 있으면 60% 로 그걸, 아니면 "그대로 내기" (없으면 쓸 수 있는 첫 병)
	var showcase: DishShowcase = k._dish_showcase
	if showcase.visible:
		if not showcase._is_open or showcase._is_sprinkling:
			return
		var garnish: Garnish = showcase._plain_garnish
		for shaker: GarnishShaker in showcase._shakers:
			if shaker.is_available and shaker.garnish == k.current_guest.favorite_garnish and randf() < 0.6:
				garnish = shaker.garnish
		if garnish == null:
			for shaker: GarnishShaker in showcase._shakers:
				if shaker.is_available:
					garnish = shaker.garnish; break
		if garnish == null:
			_log("  !! 완성 장면: 고를 수 있는 고명이 하나도 없음 (%s)" % k.current_order.display_name)
			return
		if not garnish.serve_as_is:
			d["garnish"].append("%s:%s%s" % [k.current_guest.display_name, garnish.display_name,
					"♥" if garnish == k.current_guest.favorite_garnish else ""])
		showcase._finish(garnish)
		return
	if k._result_board.visible:
		if k._result_board._continue_button.visible:
			k._result_board._continue_button.pressed.emit()
		else:
			k._result_board._finish_reveal()
		return
	if k._cook_button.visible and not k._cook_button.disabled:
		if k._is_birthday_order: d["birthday"] = "소원 요리 %s 주문" % k.current_order.display_name
		k._cook_button.pressed.emit(); return
	if k._serve_button.visible:
		k._serve_button.pressed.emit(); return
	if k._next_guest_button.visible:
		if k.current_order == null and k.current_guest != null and not k._is_picnic:
			d["home"] += 1
		k._next_guest_button.pressed.emit(); return
	if k._evening_button.visible:
		d["served"] = k._report.guests.size()
		d["lunch_rep"] = k._report.reputation
		d["status"] = k._cook_status_label.get_parsed_text()
		k._evening_button.pressed.emit(); return

# --- 저녁 ---
func _porch(p: Node) -> void:
	var day: int = GameState.current_day
	if p._reply_box.visible and p._reply_box.get_child_count() > 0:
		var buttons: Array = p._reply_box.get_children().filter(func(b: Node) -> bool: return b is Button and b.visible)
		if not buttons.is_empty():
			buttons.pick_random().pressed.emit()
		return
	if p._note_card.visible and p._note_card.has_method("close"):
		pass
	if p._next_button.visible and not p._next_button.disabled:
		if p._beats.is_empty():
			if _porch_logged_day != day:
				_porch_logged_day = day
				var d: Dictionary = day_log.get(day, {})
				d["evening_met"] = p._met_tonight_ids.duplicate()
				d["preview"] = DayPreview.get_lines(day + 1, true)
				day_log[day] = d
				_write_day(day)
		p._next_button.pressed.emit()

func _feast(f: Node) -> void:
	if f._next_button.visible and not f._next_button.disabled:
		f._next_button.pressed.emit()

func _story(s: Node) -> void:
	if s.has_method("_advance"):
		s._advance()

var _prev: Dictionary = {}
func _write_day(day: int) -> void:
	var d: Dictionary = day_log.get(day, {})
	var now: Dictionary = {"notes": GameState.count_found_notes(), "chapters": GameState.seen_story_chapter_ids.size(),
		"duos": GameState.seen_duo_talk_ids.size(), "memories": GameState.seen_memory_ids.size(), "secrets": GameState.learned_secret_ids.size(),
		"keepsakes": GameState.keepsake_ids.size(), "tier": GameState.get_shop_tier(), "rep": GameState.reputation, "slots": GameState.get_menu_slots()}
	var news: Array[String] = []
	for key: String in ["notes", "chapters", "duos", "secrets", "keepsakes", "tier", "slots"]:
		var diff: int = now[key] - _prev.get(key, 0)
		if diff > 0: news.append("%s+%d" % [{"notes":"노트","chapters":"사연막","duos":"둘대화","secrets":"비법","keepsakes":"기념품","tier":"가게단계","slots":"메뉴칸"}[key], diff])
	_prev = now
	var special: SpecialLunch = GameData.get_special_lunch(day)
	_log("── %d일째 %s%s" % [day, ("[" + special.display_name + "] ") if special else "", "(비)" if GameState.is_raining_today else ""])
	_log("  손님: %s / 대접 %s, 돌아감 %s / 바구니 %s / 장터 %s" % [", ".join(d.get("guests", []).map(func(i: StringName) -> String: return GameData.get_guest(i).display_name)),
		d.get("served", "?"), d.get("home", 0), d.get("basket", []), d.get("market", "-")])
	if not d.get("boxes", []).is_empty(): _log("  도시락: %s" % ", ".join(d["boxes"]))
	if not d.get("puzzles", []).is_empty(): _log("  노트 퍼즐: %s" % ", ".join(d["puzzles"]))
	if not d.get("garnish", []).is_empty(): _log("  고명: %s" % ", ".join(d["garnish"]))
	_log("  할머니 손맛 단계: %d" % d.get("grandma", 0))
	if d.get("birthday", "") != "": _log("  생일: %s" % d["birthday"])
	_log("  새로 생긴 것: %s / 저녁에 온 손님 %d명" % [", ".join(news) if not news.is_empty() else "없음", d.get("evening_met", []).size()])
	_log("  내일은…: %s" % (" · ".join(d.get("preview", [])) if not d.get("preview", []).is_empty() else "(예고 없음)"))
	var inv: Array[String] = []
	for id: StringName in GameState.inventory:
		inv.append("%s%d" % [GameData.get_ingredient(id).display_name, GameState.inventory[id]])
	_log("  재료: %s / 소문 %d, 가게 %d단계, 노트 %d" % [" ".join(inv), now.rep, now.tier, now.notes])
	var f: FileAccess = FileAccess.open(log_path, FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
