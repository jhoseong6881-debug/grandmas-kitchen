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
@export var disliked_recipes: Array[Recipe] = []
## 밥값으로 내는 재료
@export var payment_ingredients: Array[Ingredient] = []
## 주문할 때 하는 말. {recipe} 자리에 요리 이름이 들어간다.
@export var order_line: String = "{recipe} 주세요!"
## 손님이 하는 말. 한 줄에 대사 하나.
@export_multiline var dialogue_lines: Array[String] = []
