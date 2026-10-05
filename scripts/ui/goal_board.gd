class_name GoalBoard
extends PanelContainer
## 목표판. 아침 텃밭과 점심 부엌 왼쪽에 늘 떠 있으면서 "다음에 무엇이 있는지"를 보여 준다:
## 오늘 약속, 이번 계절 할머니 노트 수 (다 모으면 한 줄 더), 다음 가게 단계까지 남은 소문, 다음 장날,
## 잔치 준비 (장보기 목록을 받은 뒤), 계절 잔치까지 남은 날.
## GameState 의 시그널(노트, 소문, 날짜, 잔치 준비)을 듣고 스스로 다시 쓴다. 누를 수 없는 판이라 입력은 지나간다.
## 모양: 나무 틀 안 크림색 종이에 적어 둔 느낌. board_texture(9칸으로 늘어나는 그림)가 있으면 그 그림, 없으면 도트로 그린 임시 판.

const TITLE_FORMAT: String = "%s 목표"
const NOTES_FORMAT: String = "할머니 노트  %d / %d"
const NOTES_DONE_FORMAT: String = "올%s 노트를 다 모았어요!"
const SHOP_FORMAT: String = "%s까지 소문 %d"
const SHOP_MAX_FORMAT: String = "%s!"
const MARKET_TODAY_TEXT: String = "오늘은 장날!"
const PROMISE_FORMAT: String = "★ 오늘 약속: %s · %s"
const MARKET_FORMAT: String = "장날까지 %d일"
const FEAST_TODAY_FORMAT: String = "오늘 저녁 %s!"
const FEAST_FORMAT: String = "%s까지 %d일"
## 계절 마무리가 아직 없는 계절에서 다음 장날을 찾아볼 날 수
const MARKET_LOOKAHEAD_DAYS: int = 15
const FEAST_PREP_FORMAT: String = "잔치 준비  %d / %d"
const FEAST_PREP_DONE_TEXT: String = "잔치 준비 끝! 상다리가 휘어지겠어요"

## 판 그림 (원본, 배경 투명). 가장자리 board_margin 칸은 그대로 두고 가운데만 늘어난다 (9칸 늘이기). 비워 두면 임시 판.
@export var board_texture: Texture2D
@export var board_margin: int = 9
## 글자 크기 (버튼으로 열어 크게 볼 때는 36). 픽셀 글꼴이라 12의 배수로.
@export var font_size: int = 24
## 도트 그림을 화면에서 키우는 배수
@export var pixel_scale: int = 3
## 임시 판 색: 바깥 테두리, 나무, 나무 밝은 쪽, 나무 어두운 쪽, 종이, 종이 가장자리
@export var outline_color: Color = Color(0.3, 0.15, 0.07)
@export var wood_color: Color = Color(0.78, 0.45, 0.22)
@export var wood_light_color: Color = Color(0.88, 0.58, 0.3)
@export var wood_dark_color: Color = Color(0.6, 0.32, 0.15)
@export var paper_color: Color = Color(0.98, 0.84, 0.6)
@export var paper_edge_color: Color = Color(0.93, 0.73, 0.47)

@onready var _title_label: Label = %Title
@onready var _notes_label: Label = %NotesLabel
## 오늘 점심 단골과의 약속 주문 (있을 때만)
@onready var _promise_label: Label = %PromiseLabel
@onready var _holder_label: Label = %HolderLabel
@onready var _shop_label: Label = %ShopLabel
@onready var _market_label: Label = %MarketLabel
@onready var _feast_label: Label = %FeastLabel
@onready var _feast_prep_label: Label = %FeastPrepLabel


func _ready() -> void:
	_apply_board_style()
	for label: Node in find_children("*", "Label", true, false):
		(label as Label).add_theme_font_size_override("font_size", font_size)
	GameState.recipe_unlocked.connect(_refresh.unbind(1))
	GameState.reputation_changed.connect(_refresh.unbind(1))
	GameState.day_changed.connect(_refresh.unbind(1))
	GameState.feast_prep_changed.connect(_refresh)
	var season: SeasonData = GameData.get_current_season()
	_title_label.text = TITLE_FORMAT % (season.display_name if season != null else "")
	_refresh()


## 판 모양을 입힌다: 그림(또는 임시 도트 그림)을 pixel_scale 배로 또렷하게 키워 9칸으로 늘인다.
func _apply_board_style() -> void:
	var image: Image = board_texture.get_image().duplicate() if board_texture != null else _draw_placeholder_board()
	if image.is_compressed():
		image.decompress()
	image.resize(image.get_width() * pixel_scale, image.get_height() * pixel_scale, Image.INTERPOLATE_NEAREST)
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(image)
	var margin: float = board_margin * pixel_scale
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	add_theme_stylebox_override("panel", style)


## 임시 판 (원본 26×26): 진한 바깥 테두리 → 나무 틀(위는 밝게, 아래·오른쪽은 어둡게, 나뭇결 점) → 안쪽 진한 줄 → 종이
func _draw_placeholder_board() -> Image:
	var size: int = board_margin * 2 + 8
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(outline_color)
	var frame: int = board_margin - 3
	for y: int in range(1, size - 1):
		for x: int in range(1, size - 1):
			var color: Color = wood_color
			if y <= 2:
				color = wood_light_color
			elif y >= size - 3 or x >= size - 3:
				color = wood_dark_color
			# 나뭇결: 가로로 드문드문 어두운 점
			if (x * 7 + y * 13) % 11 == 0 and y > 2 and y < size - 3:
				color = wood_dark_color
			image.set_pixel(x, y, color)
	image.fill_rect(Rect2i(frame, frame, size - frame * 2, size - frame * 2), wood_dark_color.darkened(0.3))
	image.fill_rect(Rect2i(frame + 1, frame + 1, size - frame * 2 - 2, size - frame * 2 - 2), paper_edge_color)
	image.fill_rect(Rect2i(frame + 3, frame + 3, size - frame * 2 - 6, size - frame * 2 - 6), paper_color)
	return image


func _refresh() -> void:
	_refresh_promise()
	_refresh_notes()
	_refresh_shop()
	_refresh_market_and_feast()


func _refresh_promise() -> void:
	var guest: AnimalGuest = GameData.get_guest(GameState.promise_guest_id)
	var recipe: Recipe = GameData.get_recipe(GameState.promise_recipe_id)
	_promise_label.visible = GameState.has_promise_on(GameState.current_day) and guest != null and recipe != null
	if _promise_label.visible:
		_promise_label.text = PROMISE_FORMAT % [guest.display_name, recipe.display_name]


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
	# 노트가 없는 계절(만드는 중)에는 노트 줄을 숨긴다.
	_notes_label.visible = total > 0
	# 누가 노트를 가졌는지는 알려 주지 않는다 (손님 수첩과 저녁 이야기로 알아 가게). 다 모았을 때만 한 줄.
	var season: SeasonData = GameData.get_current_season()
	_holder_label.text = NOTES_DONE_FORMAT % (season.display_name if season != null else "")
	_holder_label.visible = total > 0 and found >= total


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
	var last_day: int = ending.last_day if ending != null else day + MARKET_LOOKAHEAD_DAYS
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
	var ending_name: String = GameData.get_current_season().ending_name if GameData.get_current_season() != null else ""
	_feast_label.text = FEAST_TODAY_FORMAT % ending_name if day >= last_day else FEAST_FORMAT % [ending_name, last_day - day]
