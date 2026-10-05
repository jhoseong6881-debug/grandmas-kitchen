class_name DayPreview
extends RefCounted
## 그날 있을 일을 몇 줄로 모은다. 잠드는 장면의 "내일은…"과 타이틀의 이어 하기 요약에서 쓴다.
## 지어낸 말이 아니라 실제로 그날 일어날 일만 모은다: 특별한 점심 날, 손님과의 약속, 계절 잔치, 사연이 열리는 손님, 장날, 다 자라는 작물.
## 아무 일도 없으면 빈 목록 (억지로 채우지 않는다).

const FEAST_FORMAT: String = "%s 날이에요!"
const STORY_FORMAT: String = "%s에게 무슨 일이 있는 것 같아요"
const MARKET_TEXT: String = "숲속 장터가 열려요"
const CROP_FORMAT: String = "%s %d칸이 다 자라요"
const CROPS_READY_FORMAT: String = "거둘 %s %d칸"
const PROMISE_FORMAT: String = "%s의 약속 주문: %s"
const LINE_SEPARATOR: String = "  ·  "


## day 날에 있을 일 (많아야 max_lines 줄, 중요한 것부터).
## for_tomorrow: 잠들기 전에 내일을 미리 볼 때 true (아직 날짜를 넘기기 전이라 작물은 "하루 남은 칸"을 센다).
## false 면 그날 아침 기준 (이어 하기 요약).
static func get_lines(day: int, for_tomorrow: bool, max_lines: int = 3) -> Array[String]:
	var lines: Array[String] = []
	# 특별한 점심 날 (예: 소풍 도시락 날)
	var special: SpecialLunch = GameData.get_special_lunch(day)
	if special != null and not special.preview_text.is_empty():
		lines.append(special.preview_text)
	var promise_line: String = _promise_line(day)
	if not promise_line.is_empty():
		lines.append(promise_line)
	var ending: SeasonEnding = GameData.get_season_ending()
	if ending != null and ending.last_day == day:
		lines.append(FEAST_FORMAT % GameData.get_current_season().ending_name)
	for guest: AnimalGuest in GameData.get_season_guests():
		var chapter: GuestStoryChapter = guest.get_next_story_chapter(GameState.current_season, day,
				GameState.seen_story_chapter_ids)
		# 그날 새로 열리는 막만 (열려 있는데 아직 못 본 막을 매일 되풀이해 알리지 않게). 아직 못 만난 손님 이름은 밝히지 않는다.
		if chapter != null and chapter.open_day == day and GameState.has_seen_guest(guest.id):
			lines.append(STORY_FORMAT % guest.display_name)
	if GameData.get_market_settings().is_market_day(day):
		lines.append(MARKET_TEXT)
	lines.append_array(_crop_lines(for_tomorrow))
	return lines.slice(0, max_lines)


## 한 줄로 이어 붙인 것
static func get_text(day: int, for_tomorrow: bool, max_lines: int = 3) -> String:
	return LINE_SEPARATOR.join(get_lines(day, for_tomorrow, max_lines))


static func _promise_line(day: int) -> String:
	if not GameState.has_promise_on(day):
		return ""
	var guest: AnimalGuest = GameData.get_guest(GameState.promise_guest_id)
	var recipe: Recipe = GameData.get_recipe(GameState.promise_recipe_id)
	if guest == null or recipe == null:
		return ""
	return PROMISE_FORMAT % [guest.display_name, recipe.display_name]


## 작물 이름마다 칸 수. 내일: 하루 남은 칸 (내일 다 자람). 오늘: 다 자라서 거둘 수 있는 칸.
static func _crop_lines(for_tomorrow: bool) -> Array[String]:
	var counts: Dictionary[String, int] = {}
	for place_id: StringName in GameState.plot_crop_ids:
		var crop_ids: Array = GameState.plot_crop_ids[place_id]
		var days_left: Array = GameState.plot_days_left.get(place_id, [])
		for i: int in crop_ids.size():
			if crop_ids[i] == GameState.EMPTY_PLOT or i >= days_left.size():
				continue
			if int(days_left[i]) != (1 if for_tomorrow else 0):
				continue
			var crop: Crop = GameData.get_crop(crop_ids[i])
			if crop != null and crop.ingredient != null:
				var crop_name: String = crop.ingredient.display_name
				counts[crop_name] = counts.get(crop_name, 0) + 1
	var lines: Array[String] = []
	for crop_name: String in counts:
		lines.append((CROP_FORMAT if for_tomorrow else CROPS_READY_FORMAT) % [crop_name, counts[crop_name]])
	return lines
