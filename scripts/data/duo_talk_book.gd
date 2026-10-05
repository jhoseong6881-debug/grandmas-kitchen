class_name DuoTalkBook
extends Resource
## 저녁 평상에서 손님 둘이 나누는 대화 목록. data/story/porch_duos.tres 에 있다.
## 대화를 더하거나 고치려면 에디터에서 porch_duos.tres 를 열어 Talks 칸을 바꾸면 된다.
## 앞에 있는 대화가 먼저 나온다. 사연 사이에만 나오는 대화(기간이 짧은 것)를 앞에 둔다.

@export var talks: Array[GuestDuoTalk] = []


## 오늘 저녁 할 대화 (목록 앞쪽부터, 아직 안 본 것 중 조건이 맞는 첫 대화). 없으면 null.
func get_ready(season: Season.Id, day: int, first_id: StringName, served_ids: Array[StringName],
		seen_talk_ids: Array[StringName], seen_chapter_ids: Array[StringName]) -> GuestDuoTalk:
	for talk: GuestDuoTalk in talks:
		if talk != null and talk.id not in seen_talk_ids \
				and talk.is_ready(season, day, first_id, served_ids, seen_chapter_ids):
			return talk
	return null
