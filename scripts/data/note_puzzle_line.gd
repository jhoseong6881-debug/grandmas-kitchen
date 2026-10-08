class_name NotePuzzleLine
extends Resource
## 번진 할머니 노트(NotePuzzle)의 한 줄. 깨끗한 줄이거나, 번진 칸이 있어서 채워야 하는 줄이다.

## 줄 종류. .tres 에는 번호로 저장되니, 새 종류는 맨 뒤에만 붙인다.
## TEXT: 깨끗하게 읽히는 줄, CHOOSE_WORD: 번진 낱말 하나를 보기에서 고른다, ORDER: 넣는 순서 (2단계에서 만든다)
enum Kind { TEXT, CHOOSE_WORD, ORDER }

## 번진 칸 자리를 표시하는 글
const BLANK_MARK: String = "{blank}"

@export var kind: Kind = Kind.TEXT
## 노트에 적힌 글. 번진 칸 자리에 {blank} 를 쓴다 (예: "불은 {blank}로, 천천히 익힌다")
@export var text: String = ""
## 고를 보기 (CHOOSE_WORD). 정답도 이 안에 넣는다.
@export var choices: Array[String] = []
## 정답 보기 번호 (choices 에서 몇 번째인지, 0부터)
@export var answer_index: int = 0
## 틀린 보기를 골랐을 때 떠오르는 한 줄. 비워 두면 퍼즐 창의 기본 문구를 쓴다.
@export var wrong_line: String = ""


## 번진 칸이 있어서 채워야 하는 줄인지
func is_puzzle() -> bool:
	return kind != Kind.TEXT


## 정답 낱말 (보기 번호가 틀렸으면 빈 글)
func get_answer() -> String:
	return choices[answer_index] if answer_index >= 0 and answer_index < choices.size() else ""
