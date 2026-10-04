class_name MemoryBook
extends Resource
## 할머니 회상 장면 목록. data/story/memories.tres 에 있다.
## 노트를 되찾은 날 밤 잠들 때, 아직 안 본 회상 중 노트 수가 찬 첫 번째 것을 보여 준다 (하룻밤에 하나).

@export var memories: Array[GrandmaMemory] = []
## 회상이 있는 밤, 잠드는 장면에서 꿈 한 줄 대신 보여 주는 글
@export var dream_text: String = "…잠결에, 오래된 기억 하나가 떠올랐다."


## 지금 보여 줄 회상. 없으면 null.
## found_notes: 이번 계절에 되찾은 노트 수, seen_ids: 이미 본 회상 id
func get_next(season: Season.Id, found_notes: int, seen_ids: Array[StringName]) -> GrandmaMemory:
	for memory: GrandmaMemory in memories:
		if memory != null and memory.story != null and memory.season == season \
				and found_notes >= memory.notes_needed and memory.id not in seen_ids:
			return memory
	return null
