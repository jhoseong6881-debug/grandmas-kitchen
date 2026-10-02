class_name DreamBook
extends Resource
## 잠드는 장면에서 하룻밤에 한 줄씩 보여 주는 할머니 꿈 문구. data/story/dreams.tres 에 있다.
## 첫날 밤은 첫 줄, 둘째 날 밤은 둘째 줄… 다 보여 주면 처음부터 다시 돈다.
## 줄을 더하거나 고치려면 에디터에서 dreams.tres 를 열어 Lines 칸을 바꾸면 된다. {name} 은 주인공 이름으로 바뀐다.

@export_multiline var lines: Array[String] = []


## night: 몇째 날 밤인지 (1부터). 줄이 하나도 없으면 빈 글.
func get_line(night: int) -> String:
	if lines.is_empty():
		return ""
	return lines[posmod(night - 1, lines.size())]
