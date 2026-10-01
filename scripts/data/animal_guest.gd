class_name AnimalGuest
extends Resource
## 동물 손님 하나의 정보. data/guests/ 에 .tres 파일로 하나씩 만든다.

## 세이브 파일에 저장되는 고유 이름표. 영어 소문자로 짓고 한 번 정하면 바꾸지 않는다. (예: rabbit)
@export var id: StringName = &""
## 화면에 보이는 이름 (예: 토끼 할멈)
@export var display_name: String = ""
## 손님 그림. 비워 두면 임시 도형으로 표시한다.
@export var portrait: Texture2D
@export_multiline var personality: String = ""
@export var favorite_recipes: Array[Recipe] = []
## 싫어하는 요리. 좋아하는 요리를 못 만드는 날 대신 주문할 때도 이 요리는 절대 주문하지 않는다.
@export var disliked_recipes: Array[Recipe] = []
## 밥값으로 내는 재료
@export var payment_ingredients: Array[Ingredient] = []
## 주문할 때 하는 말. {recipe} 자리에 요리 이름이 들어간다.
@export var order_line: String = "{recipe} 주세요!"
## 좋아하는 요리를 못 만드는 날, 싫어하지 않는 다른 요리를 대신 주문할 때 하는 말. {recipe} 자리에 요리 이름이 들어간다.
@export var fallback_order_line: String = "음… 오늘은 그냥 {recipe}, 그거 주세요."
## 대접받고 하는 말
@export var thanks_line: String = "잘 먹었어요!"
## 미니게임을 한 번도 안 틀리고 대접받았을 때 하는 말
@export var perfect_line: String = "와, 정말 맛있어요!"
## 저녁 평상에서 들려주는 이야기. 저녁마다 한 줄씩 순서대로 들려주고, 다 들려주면 처음부터 다시.
@export_multiline var dialogue_lines: Array[String] = []
## 저녁 평상에서 돌려주는 할머니 레시피 노트 페이지. 찾아올 때마다 아직 안 돌려준 첫 페이지를 준다.
@export var note_recipes: Array[Recipe] = []
## 레시피 노트를 건넬 때 하는 말. {recipe} 자리에 요리 이름이 들어간다.
@export var note_line: String = "이거, 할머니가 주셨던 레시피예요. 「{recipe}」 돌려드릴게요."
