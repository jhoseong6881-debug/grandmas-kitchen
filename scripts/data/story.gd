class_name Story
extends Resource
## 여러 장(StoryChapter)으로 된 이야기 하나 (예: 프롤로그). data/story/ 에 .tres 파일로 만든다.

@export var chapters: Array[StoryChapter] = []
## 이름 입력 칸 위에 보이는 글
@export var name_prompt: String = "이름을 알려 주세요"
## 이름 입력 칸에 미리 적혀 있는 이름 (게임패드로 바로 넘어가도 이름이 생기도록)
@export var default_name: String = "봄이"
