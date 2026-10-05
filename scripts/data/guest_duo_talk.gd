class_name GuestDuoTalk
extends Resource
## 저녁 평상에서 손님 둘이 나누는 대화 하나 (커피 토크처럼, 주인공은 옆에서 듣는다). DuoTalkBook 안에 넣는다.
## 그날 첫 저녁 손님이 guest_ids 중 하나이고, 다른 손님도 그날 점심에 대접했으면 그 손님이 옆에 와 앉아 대화한다.
## 한 번 본 대화는 다시 하지 않는다. 하룻저녁에 하나까지.

## 세이브 파일에 저장되는 고유 이름표 (예: duo_bear_rabbit_bandage)
@export var id: StringName = &""
@export var season: Season.Id = Season.Id.SPRING
## 이 날부터 나올 수 있다
@export var open_day: int = 2
## 대화하는 두 손님 id
@export var guest_ids: Array[StringName] = []
## 이 사연 막(GuestStoryChapter id)을 다 본 뒤에만 나온다 (사연 사이에 끼우려고)
@export var requires_seen_chapters: Array[StringName] = []
## 이 사연 막 중 하나라도 보면 더는 나오지 않는다 (사연과 앞뒤가 안 맞지 않게)
@export var ends_after_chapters: Array[StringName] = []
## 차례대로 나누는 말
@export var lines: Array[DuoLine] = []


## 지금 이 대화를 할 수 있는지. first_id: 그날 첫 저녁 손님, served_ids: 그날 대접한 손님들
func is_ready(season_now: Season.Id, day: int, first_id: StringName, served_ids: Array[StringName],
		seen_chapter_ids: Array[StringName]) -> bool:
	if season_now != season or day < open_day or guest_ids.size() != 2 or lines.is_empty():
		return false
	if first_id not in guest_ids or get_partner_id(first_id) not in served_ids:
		return false
	if requires_seen_chapters.any(func(chapter_id: StringName) -> bool: return chapter_id not in seen_chapter_ids):
		return false
	return not ends_after_chapters.any(func(chapter_id: StringName) -> bool: return chapter_id in seen_chapter_ids)


## 두 손님 중 guest_id 가 아닌 손님
func get_partner_id(guest_id: StringName) -> StringName:
	return guest_ids[1] if guest_ids[0] == guest_id else guest_ids[0]
