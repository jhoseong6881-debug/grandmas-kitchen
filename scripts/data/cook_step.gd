class_name CookStep
extends Resource
## 레시피의 요리 단계 하나 (예: "당근 채썰기 12번, 빠르게"). Recipe 의 cook_steps 에 차례대로 넣는다.
## 비워 둔 칸은 미니게임의 기본값을 쓴다.

## 어떤 미니게임으로 할지
@export var type: Recipe.MinigameType = Recipe.MinigameType.CHOP
## 이 단계에서 다루는 재료. 제목과, 그림이 없을 때 재료 색에 쓴다.
@export var ingredient: Ingredient
## 제목에 쓰는 이름 (예: "김밥", "도토리묵"). 비워 두면 재료 이름, 재료도 없으면 레시피에서 정한 이름.
@export var subject_name: String = ""
## 제목에 쓰는 동작 (예: "채썰기", "다지기"). 비워 두면 미니게임 기본 이름 (썰기, 볶기 …).
@export var action_name: String = ""
## 몇 번 하는지 (썰기: 써는 수, 볶기: 토스 수, 담기: 그릇 수, 부치기: 전 장수, 말기: 겹 수,
## 밥 짓기: 씻는 수, 버무리기: 조각 수, 조리기: 젓는 수). 0 이면 미니게임 기본값.
@export var count: int = 0
## 빠르기 배율. 1 = 보통, 1.3 = 30% 빠르게, 0.8 = 느긋하게.
@export var speed: float = 1.0
## 그림이 아직 없을 때 재료 대신 쓰는 임시 색 (예: 김밥은 김 색). 투명(알파 0)이면 재료 색을 쓴다.
@export var placeholder_color: Color = Color(0, 0, 0, 0)
