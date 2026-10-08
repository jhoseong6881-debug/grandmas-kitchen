class_name NotePuzzle
extends Resource
## 번진 할머니 노트 퍼즐. 레시피(Recipe.note_puzzle)에 하나씩 붙는다.
## 그 요리를 처음 만들 때 미니게임 전에 노트가 펼쳐지고, 번진 칸을 채우면 노트가 깨끗해진다.
## 틀려도 손해는 없다. 푼 퍼즐은 레시피 id 로 저장된다 (GameState.solved_note_puzzle_ids).

## 노트에 적힌 줄을 차례대로 (깨끗한 줄 + 번진 칸이 있는 줄)
@export var lines: Array[NotePuzzleLine] = []
## "추억 떠올리기"로 떠오르는 할머니 말씀 한 줄
@export_multiline var hint: String = ""


## 채워야 하는 줄들 (번진 칸이 있는 줄만, 노트 순서대로)
func get_puzzle_lines() -> Array[NotePuzzleLine]:
	return lines.filter(func(line: NotePuzzleLine) -> bool: return line != null and line.is_puzzle())
