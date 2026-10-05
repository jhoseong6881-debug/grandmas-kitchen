class_name SpecialLunch
extends Resource
## 계절 후반 점심이 늘 똑같지 않게 하는 "특별한 점심 날" 하나. SeasonData.special_lunches 에 넣는다.
## 그날은 점심 방식 자체가 바뀐다. 전날 밤 "내일은…" 예고와 아침 메뉴판에서 미리 알려 준다.
##
## PICNIC (소풍 도시락 날): 손님이 한 명씩 오는 대신 host 손님이 오늘 손님 모두의 도시락을 한꺼번에 주문한다.
## 도시락마다 그 손님에게 넣을 요리를 내가 고르고 요리한다. 그 손님이 좋아하는 요리면 밥값을 다 받고,
## 도시락이 모두 다른 요리면 "골고루" 덤 소문을 받는다. 도시락을 받은 손님은 저녁 평상에 평소처럼 온다.
## 글에서 {guest} 는 도시락 주인 이름, {particle} 은 그 이름 뒤 "이/가", {names} 는 host 말고 도시락 받을 손님 이름들,
## {count} 는 도시락 수, {name} 은 주인공 이름으로 바뀐다.
##
## BIRTHDAY (손님 생일): host 손님이 첫 손님으로 와서 평소엔 안 시키는 "생일 소원" 요리(get_wish_recipe)를 부탁한다.
## 해 주면 덤 재료(gift_ingredient)와 단골도를 더 받는다. 다른 손님들은 주문 앞에 생일 축하 한마디(guest_lines)를 한다.
## 글에서 {recipe} 는 소원 요리 이름, {recipe_obj} 는 그 뒤에 을/를을 붙인 것, {host} 는 생일 손님 이름으로 바뀐다.

##
## CHEF_CHOICE ("아무거나 맛있는 거" 날): 손님마다 "알아서 맛있는 걸로"(guest_lines) 부탁하고, 낼 요리를 내가 고른다.
## 그 손님이 좋아하는 요리면 밥값을 다 받고 단골도(bonus_affection)가 더 오르고 hit_lines 의 말을 한다.
## 그냥 그런 요리면 평소 대신 시킨 요리처럼 밥값을 조금, 싫어하는 요리면 dislike_lines 의 말 (벌점은 없다). host 는 비워 둔다.

enum Kind { PICNIC, BIRTHDAY, CHEF_CHOICE }

@export var id: StringName
@export var kind: Kind = Kind.PICNIC
## 계절 몇째 날인지
@export var day: int = 8
## 이름 (예: "소풍 도시락 날")
@export var display_name: String = ""
## 주문하러 오는 손님 (오늘 손님 맨 앞에 온다)
@export var host_id: StringName
## 전날 밤 "내일은…" 예고 한 줄
@export var preview_text: String = ""
## 아침 메뉴판 위에 보여 주는 안내
@export_multiline var menu_notice: String = ""
## host 가 들어와서 하는 주문
@export_multiline var intro_line: String = ""
## 도시락 요리 고르는 창 제목
@export var choose_title_format: String = "도시락에 넣을 요리를 골라요"
## 고르는 창에서 그만두기 버튼 대신 쓰는 글 (누르면 손님 수첩을 연다)
@export var notebook_button_text: String = "손님 수첩 보기"
## 도시락을 하나 다 쌌을 때 host 가 하는 말: 그 손님이 좋아하는 요리일 때 / 아닐 때
@export_multiline var favorite_line: String = ""
@export_multiline var other_line: String = ""
## host 자기 도시락일 때 (좋아하는 요리 / 아닐 때)
@export_multiline var self_favorite_line: String = ""
@export_multiline var self_other_line: String = ""
## 재료가 모자라 그 손님 도시락을 못 쌀 때
@export_multiline var skipped_line: String = ""
## 다 싸고 나서 host 의 마지막 말, 모두 다른 요리로 쌌을 때 덧붙이는 말과 덤 소문
@export_multiline var done_line: String = ""
@export_multiline var variety_line: String = ""
@export var variety_reputation: int = 3
## 위로 떠오르는 글
@export var variety_pop_text: String = "♪ 골고루 담았어요!"

@export_group("생일 · 아무거나 날")
## 생일 소원 요리. 아직 못 되찾았으면 생일 손님이 평소 안 시키는 다른 요리로 바꾼다.
@export var wish_recipe: Recipe
## 소원 요리를 낼 수 없을 때 (그 뒤에 평소처럼 주문한다)
@export_multiline var wish_missed_line: String = ""
## 소원 요리를 대접받고
@export_multiline var wish_thanks_line: String = ""
## 생일: 다른 손님이 주문 앞에 하는 말 / 아무거나 날: 손님이 "알아서 해 주세요" 하고 부탁하는 말 (손님 id → 말)
@export var guest_lines: Dictionary[StringName, String] = {}
## 소원 요리를 해 주면 더 받는 재료와 개수, 단골도
@export var gift_ingredient: Ingredient
@export var gift_amount: int = 2
@export var bonus_affection: int = 3
## 아무거나 날: 좋아하는 요리를 냈을 때 / 싫어하는 요리를 냈을 때 손님 말 (손님 id → 말), 비었을 때 기본 말
@export var hit_lines: Dictionary[StringName, String] = {}
@export var dislike_lines: Dictionary[StringName, String] = {}
@export_multiline var default_request_line: String = "오늘은 알아서 맛있는 걸로 주세요!"
@export_multiline var default_hit_line: String = "어떻게 알았어요? 이거 제일 좋아하는 거예요!"
@export_multiline var default_dislike_line: String = "음… 이건 제 입에는 좀 안 맞네요. 그래도 고마워요."
@export var hit_pop_text: String = "♥ 딱 원하던 거!"
## 아무거나 날: 요리하기 버튼 대신 쓰는 글, 고르는 창 위 손님 줄 모양, 오늘 낸 요리 줄 모양
@export var choose_button_text: String = "요리 고르기"
@export var chooser_guest_format: String = " %s"
@export var chooser_served_format: String = "오늘 낸 요리: %s"
@export var birthday_pop_text: String = "♪ 생일 축하해요!"
## 메뉴판에서 소원 요리 줄 옆에 붙는 표시
@export var menu_tag_format: String = "♪ {host} 생일 소원"


## 생일 소원 요리: wish_recipe 를 되찾았으면 그것, 아니면 되찾은 요리 중 생일 손님이 좋아하지도 싫어하지도 않는 첫 요리,
## 그것도 없으면 null. (같은 날에는 늘 같은 요리가 나온다)
func get_wish_recipe() -> Recipe:
	if wish_recipe != null and GameState.is_recipe_unlocked(wish_recipe.id):
		return wish_recipe
	var host: AnimalGuest = GameData.get_guest(host_id)
	for recipe: Recipe in GameData.get_all_recipes():
		if GameState.is_recipe_unlocked(recipe.id) and (host == null
				or (recipe not in host.favorite_recipes and recipe not in host.disliked_recipes)):
			return recipe
	return null


## text 의 {recipe} (소원 요리), {recipe_obj} (소원 요리 + 을/를), {host}, {name} 을 채운다
func fill(text: String) -> String:
	var wish: Recipe = get_wish_recipe()
	var host: AnimalGuest = GameData.get_guest(host_id)
	var wish_name: String = wish.display_name if wish != null else ""
	return text.format({"recipe": wish_name, "recipe_obj": wish_name + Korean.object_particle(wish_name),
			"host": host.display_name if host != null else "", "name": GameState.player_name})
