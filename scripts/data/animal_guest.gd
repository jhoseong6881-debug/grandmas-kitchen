class_name AnimalGuest
extends Resource
## 동물 손님 하나의 정보. data/guests/ 에 .tres 파일로 하나씩 만든다.

## 세이브 파일에 저장되는 고유 이름표. 영어 소문자로 짓고 한 번 정하면 바꾸지 않는다. (예: rabbit)
@export var id: StringName = &""
## 화면에 보이는 이름 (예: 토끼 할멈)
@export var display_name: String = ""
## 표정 이름. 대사에 맞춰 손님 자리(GuestSpot)가 이 표정 그림으로 바꿔 보여 준다.
const EXPRESSION_DEFAULT: StringName = &""
const EXPRESSION_HAPPY: StringName = &"happy"
const EXPRESSION_SURPRISED: StringName = &"surprised"
const EXPRESSION_SAD: StringName = &"sad"

## 그림이 없을 때 만드는 임시 사각형 아이콘의 크기(픽셀). 화면에서는 늘려서 보여 준다.
const PLACEHOLDER_ICON_PIXELS: int = 12

## 작은 얼굴 아이콘 (원본 16×16). 장사 결과판 손님 줄에 이름 옆에 나온다. 비워 두면 icon_placeholder_color 색의 임시 사각형.
@export var icon: Texture2D
@export var icon_placeholder_color: Color = Color(0.86, 0.84, 0.8)
## 손님 그림 (기본 표정, 360×480, 화면에 그대로). 비워 두면 임시 도형으로 표시한다.
@export var portrait: Texture2D
## 표정 그림: happy(웃음), surprised(놀람), sad(시무룩) 를 이름으로 넣는다. 없는 표정은 기본 그림을 쓴다.
@export var expression_portraits: Dictionary[StringName, Texture2D] = {}
## 봄비 오는 날 우비를 입은 그림. 비워 두면 임시 그림일 때만 우비 도형을 씌우고, 진짜 그림이 있으면 평소 모습.
@export var raincoat_portrait: Texture2D
## 봄 잔치에서 평상에 앉은 모습 (원본 60×80 · 화면 180×240). 비워 두면 손님 그림(portrait)을, 그것도 없으면 임시 사각형.
@export var feast_portrait: Texture2D
@export_multiline var personality: String = ""
@export var favorite_recipes: Array[Recipe] = []
## 싫어하는 요리. 좋아하는 요리를 못 만드는 날 대신 주문할 때도 이 요리는 절대 주문하지 않는다.
@export var disliked_recipes: Array[Recipe] = []
## 밥값으로 내는 재료
@export var payment_ingredients: Array[Ingredient] = []
## 주문할 때 하는 말. {recipe} 자리에 요리 이름이 들어간다.
@export var order_line: String = "{recipe} 주세요!"
## 좋아하는 요리를 못 만드는 날, 싫어하지 않는 다른 요리를 대신 주문할 때 하는 말. {recipe} 자리에 요리 이름이 들어간다.
@export var fallback_order_line: String = "음… 오늘은 그냥 {recipe}, 그거 주세요."
## 오늘의 메뉴에 먹을 수 있는 요리가 하나도 없어서 그냥 돌아갈 때 하는 말. 비워 두면 부엌의 기본 문장을 쓴다.
@export var no_dish_line: String = ""
## 좋아하는 요리가 오늘 이미 나가서, 메뉴의 다른 요리가 궁금해 시킬 때 하는 말. 비워 두면 부엌의 기본 문장을 쓴다.
@export var curious_order_line: String = ""
## 봄비 오는 날 따뜻한 요리(RainSettings.warm_recipes)를 시킬 때 하는 말. 비워 두면 평소 주문 말을 쓴다.
@export var rain_order_line: String = ""
## 반말하는 손님인지. 켜면 오늘의 부탁을 반말 문장(GuestRequest.casual_line)으로 말한다.
@export var speaks_casually: bool = false
## 오늘의 부탁대로 못 해 줬을 때 하는 말. 비워 두면 부엌의 기본 문장을 쓴다.
@export var request_missed_line: String = ""
## 할머니 손맛으로 대접받았을 때 하는 말. 그 요리의 비법을 알려 준 손님은 레시피의 grandma_taste_line 을 쓰고,
## 다른 손님은 이 말을 쓴다 ({name} 은 주인공 이름). 비워 두면 레시피의 말을 쓴다.
@export var grandma_taste_line: String = ""
## ※ 새 손님을 만들 때는 아래 세 줄을 꼭 함께 쓴다 (처음 만남이 갑작스럽지 않게, 고명을 고를 단서가 있게).
## 처음 점심에 왔을 때의 주문: 할머니 밥집 단골이었다는 걸 자기 방식으로 알리고, 손주를 반가워한 뒤 {recipe} 를 시킨다.
@export var first_order_line: String = ""
## 입맛 힌트: 입맛(favorite_garnish)을 알기 전까지 주문 뒤에 붙고, 고명 고르는 창 위에도 다시 보인다.
@export var taste_hint_line: String = ""
## 처음 저녁 평상에 왔을 때, 걸어 들어와 앉은 뒤 하는 인사 (그다음 평소 이야기가 이어진다). {name} 은 주인공 이름.
@export_multiline var porch_greeting_line: String = ""
## 이웃 바구니 쪽지 (평소). 저녁 평상에 왔던 다음 날 아침, 바구니 재료와 함께 이 중 하나를 남긴다 (날마다 돌아가며).
## {ingredient} 는 두고 간 재료 이름, {name} 은 주인공 이름. 사연 막 다음 날에는 그 막의 쪽지(GuestStoryChapter.basket_note)를 먼저 남긴다.
@export_multiline var basket_notes: Array[String] = []
## 단골의 약속 주문 (RegularSettings.promise_*). {recipe} 는 요리 이름.
## 저녁 평상에서 묻는 말 / 받아 줬을 때 / 거절했을 때 / 다음 날 점심에 와서 주문하는 말 / 약속대로 대접받았을 때 / 메뉴에 없어서 못 먹을 때
@export_multiline var promise_ask_line: String = ""
@export_multiline var promise_accept_line: String = ""
@export_multiline var promise_decline_line: String = ""
@export_multiline var promise_order_line: String = ""
@export_multiline var promise_kept_line: String = ""
@export_multiline var promise_missed_line: String = ""
## 대접받고 하는 말 (지금은 쓰지 않는다. 미니게임에 빗나감이 없어져 perfect_line 이 기본 인사가 됐다)
@export var thanks_line: String = "잘 먹었어요!"
## 대접받았을 때 하는 기본 감사 인사 (예전에는 한 번도 안 틀렸을 때만 했다)
@export var perfect_line: String = "와, 정말 맛있어요!"
## 저녁 평상 대화. 찾아올 때마다 하나씩 순서대로 나누고, 다 나누면 처음부터 다시.
@export var evening_talks: Array[EveningTalk] = []
## 계절 동안 이어지는 사연. 막 순서대로 넣는다 (GuestStoryChapter). 열린 막이 있으면 저녁 평상에서 평소 이야기 대신 한다.
@export var story_chapters: Array[GuestStoryChapter] = []
## 저녁 평상에서 돌려주는 할머니 레시피 노트 페이지. 찾아올 때마다 아직 안 돌려준 첫 페이지를 준다.
@export var note_recipes: Array[Recipe] = []
## 계절 마무리 잔치에서 하는 인사
@export var feast_line: String = "잔치, 정말 즐거워요!"
## 이 계절 사연(story_chapters)을 끝까지 봤을 때 잔치에서 하는 인사. 비워 두면 feast_line. {name} 은 주인공 이름.
@export_multiline var story_feast_line: String = ""
## 레시피 노트를 건넬 때 하는 말. {recipe} 자리에 요리 이름이 들어간다.
@export var note_line: String = "이거, 할머니가 주셨던 레시피예요. 「{recipe}」 돌려드릴게요."
## 좋아하는 마무리 고명 (data/garnishes/). 이걸 올려 대접하면 단골도가 더 오른다.
@export var favorite_garnish: Garnish
## 입맛에 안 맞는 고명을 올렸을 때 하는 말 (무엇을 좋아하는지 힌트가 되게)
@export_multiline var taste_miss_line: String = ""
## 입맛에 맞는 고명을 올렸을 때 하는 말
@export_multiline var taste_match_line: String = ""
## 단골 단계가 오를 때 받는 보상 (첫 칸 = 이웃, 둘째 = 단골, 셋째 = 식구)
@export var regular_rewards: Array[RegularReward] = []


## 그림이 없을 때 쓰는 임시 사각형 (처음 쓸 때 한 번 만들어 둔다)
var _placeholder_icon: Texture2D


## 아이콘으로 쓸 그림. 그림이 있으면 그 그림, 없으면 임시 색 사각형.
func get_icon_texture() -> Texture2D:
	if icon != null:
		return icon
	if _placeholder_icon == null:
		var image: Image = Image.create(PLACEHOLDER_ICON_PIXELS, PLACEHOLDER_ICON_PIXELS, false, Image.FORMAT_RGBA8)
		image.fill(icon_placeholder_color)
		_placeholder_icon = ImageTexture.create_from_image(image)
	return _placeholder_icon


## 단골 단계 tier(1 = 이웃)의 보상. 없으면 null.
func get_regular_reward(tier: int) -> RegularReward:
	var index: int = tier - 1
	return regular_rewards[index] if index >= 0 and index < regular_rewards.size() else null


## 지금 할 사연 막: 이 계절 막 중 아직 안 본 첫 막이 day 에 열렸으면 그 막, 아니면 null (앞 막을 봐야 다음 막).
func get_next_story_chapter(season: Season.Id, day: int, seen_ids: Array[StringName]) -> GuestStoryChapter:
	for chapter: GuestStoryChapter in story_chapters:
		if chapter == null or chapter.season != season or chapter.id in seen_ids:
			continue
		return chapter if day >= chapter.open_day else null
	return null


## 이 계절 사연을 끝까지 봤는지 (사연이 없으면 false)
func has_finished_story(season: Season.Id, seen_ids: Array[StringName]) -> bool:
	var chapters: Array[GuestStoryChapter] = story_chapters.filter(
			func(chapter: GuestStoryChapter) -> bool: return chapter != null and chapter.season == season)
	return not chapters.is_empty() and chapters.all(
			func(chapter: GuestStoryChapter) -> bool: return chapter.id in seen_ids)


## 계절 잔치 인사: 이 계절 사연을 끝까지 봤으면 story_feast_line, 아니면 feast_line
func get_feast_line(season: Season.Id, seen_ids: Array[StringName]) -> String:
	if not story_feast_line.is_empty() and has_finished_story(season, seen_ids):
		return story_feast_line
	return feast_line


## 이 표정의 그림. 우비를 입었으면 우비 그림, 그 표정 그림이 없으면 기본 그림. 둘 다 없으면 null (임시 도형).
## 잔치에 앉은 모습: 잔치용 그림이 있으면 그것, 없으면 손님 그림 (둘 다 없으면 null).
func get_feast_portrait() -> Texture2D:
	return feast_portrait if feast_portrait != null else portrait


func get_portrait(expression: StringName = EXPRESSION_DEFAULT, in_raincoat: bool = false) -> Texture2D:
	if in_raincoat and raincoat_portrait != null:
		return raincoat_portrait
	return expression_portraits.get(expression, portrait)
