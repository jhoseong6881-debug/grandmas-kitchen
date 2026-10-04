class_name GrandmaMemory
extends Resource
## 할머니 회상 장면 하나. 그 계절 레시피 노트를 notes_needed 장 되찾은 날 밤, 잠들 때 한 번 보여 준다.
## 프롤로그와 같은 화면으로 보여 준다 (story 의 장 제목, 배경, 한 줄씩 넘기는 글). MemoryBook 안에 차례대로 넣는다.

## 세이브 파일에 저장되는 고유 이름표 (본 회상을 다시 보여 주지 않으려고)
@export var id: StringName = &""
## 이 계절 노트를 몇 장 되찾으면 보여 줄지
@export var season: Season.Id = Season.Id.SPRING
@export var notes_needed: int = 3
## 보여 줄 이야기 (보통 장 하나)
@export var story: Story
