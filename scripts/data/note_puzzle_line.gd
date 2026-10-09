class_name NotePuzzleLine
extends Resource
## 번진 할머니 노트(NotePuzzle)의 한 줄. 깨끗한 줄이거나, 번진 칸이 있어서 채워야 하는 줄이다.

## 줄 종류. .tres 에는 번호로 저장되니, 새 종류는 맨 뒤에만 붙인다.
## TEXT: 깨끗하게 읽히는 줄, CHOOSE_WORD: 번진 낱말 하나를 보기에서 고른다, ORDER: 번진 순서대로 재료 카드를 그릇에 하나씩 넣는다
enum Kind { TEXT, CHOOSE_WORD, ORDER }

## 번진 칸 자리를 표시하는 글. 넣는 순서(ORDER) 줄에서는 이 자리에 "기름 → ▒ → ▒" 처럼 순서 칸들이 들어간다.
const BLANK_MARK: String = "{blank}"
## 넣는 순서 칸 사이에 넣는 글
const ORDER_SEPARATOR: String = " → "

@export var kind: Kind = Kind.TEXT
## 노트에 적힌 글. 번진 칸 자리에 {blank} 를 쓴다 (예: "불은 {blank}로, 천천히 익힌다")
@export var text: String = ""
## 고를 보기 (CHOOSE_WORD). 정답도 이 안에 넣는다.
@export var choices: Array[String] = []
## 정답 보기 번호 (choices 에서 몇 번째인지, 0부터)
@export var answer_index: int = 0
## 이 줄을 채울 때 조리대 위에 나오는 질문 (예: "불은 어떻게 하셨을까?"). 비워 두면 퍼즐 창의 기본 문구를 쓴다.
@export var prompt: String = ""
## 틀린 보기를 골랐을 때 (넣는 순서: 순서가 틀렸을 때) 떠오르는 한 줄. 비워 두면 퍼즐 창의 기본 문구를 쓴다.
@export var wrong_line: String = ""

@export_group("넣는 순서 (ORDER)")
## 넣는 재료를 차례대로 (게임 재료나 data/pantry/ 의 부엌 기본양념. 기본양념은 가진 재료가 줄지 않는다)
@export var order_answer: Array[Ingredient] = []
## 앞에서부터 몇 개는 번지지 않아 처음부터 읽힌다 (예: 1 이면 "기름"은 보이고 그다음부터 번짐)
@export var readable_count: int = 0
## 노트에 없는 가짜 카드 (예: 볶음에 꿀)
@export var extra_cards: Array[Ingredient] = []
## 가짜 카드를 골랐을 때 떠오르는 한 줄. 비워 두면 퍼즐 창의 기본 문구를 쓴다.
@export var extra_card_line: String = ""
## 재료를 넣는 그릇 이름 (조리대 안내 글에 쓴다. 예: 팬, 냄비, 그릇)
@export var container_name: String = "팬"


## 번진 칸이 있어서 채워야 하는 줄인지
func is_puzzle() -> bool:
	match kind:
		Kind.CHOOSE_WORD:
			return not choices.is_empty()
		Kind.ORDER:
			# 순서에 빈 칸(재료를 안 넣은 칸)이 있으면 풀 수 없으니 퍼즐로 치지 않는다 (게임이 멈추지 않게).
			return get_readable_count() < order_answer.size() and not order_answer.has(null)
	return false


## 처음부터 읽히는 순서 칸 수 (0 ~ 순서 칸 수)
func get_readable_count() -> int:
	return clampi(readable_count, 0, order_answer.size())


## 넣는 순서에서 골라야 하는 카드: 번진 칸의 재료 + 가짜 카드 (섞기 전)
func get_order_cards() -> Array[Ingredient]:
	var cards: Array[Ingredient] = order_answer.slice(get_readable_count())
	cards.append_array(extra_cards)
	return cards.filter(func(card: Ingredient) -> bool: return card != null)


## 정답 낱말 (보기 번호가 틀렸으면 빈 글)
func get_answer() -> String:
	return choices[answer_index] if answer_index >= 0 and answer_index < choices.size() else ""
