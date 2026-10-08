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
## 밥 짓기: 씻는 수, 버무리기: 조각 수, 조리기: 젓는 수, 다지기: 곱게 되는 단계 수). 0 이면 미니게임 기본값.
@export var count: int = 0
## 빠르기 배율. 1 = 보통, 1.3 = 30% 빠르게, 0.8 = 느긋하게.
## 썰기는 손으로 직접 써는 미니게임이라 빠르기를 쓰지 않는다.
@export var speed: float = 1.0
## 그림이 아직 없을 때 재료 대신 쓰는 임시 색 (예: 김밥은 김 색). 투명(알파 0)이면 재료 색을 쓴다.
@export var placeholder_color: Color = Color(0, 0, 0, 0)
## 이 단계에서 맞힐 때 나는 소리 (data/sounds/ 의 id). 재료가 아닌 것(김밥, 도토리묵 등)을 썰 때 쓴다.
## 비우면 재료의 썰기 소리(Ingredient.chop_sound) → 미니게임 기본 소리 순서로 고른다.
@export var hit_sound: StringName = &""
## 할머니 비법 자리: 금색 칸(맞는 구간) 안에서 비법 자리가 시작하고 끝나는 곳 (0 ~ 1).
## 이 단계의 모든 동작을 이 자리에서 해내면 "할머니 손맛"이 된다. 끝이 시작보다 크지 않으면 비법이 없는 단계.
## 0 과 1 이 가리키는 쪽: 썰기 = 하얀 칸(고른 두께로 썰 자리) 왼쪽 → 오른쪽, 볶기 = 받는 자리 팬 한가운데 → 가장자리,
## 담기 = 금색 띠 아래 → 위, 부치기 = 막 금색이 됐을 때 → 짙은 금색, 말기 = 붓는 자리 말린 계란 바로 옆 → 팬 끝,
## 밥 짓기(씻기) = 누른 자리 뽀얀 자리 왼쪽 가장자리 → 한가운데(0.5) → 오른쪽, 버무리기 = 문지른 주걱이 조각 왼쪽 가장자리 → 한가운데(0.5) → 오른쪽 가장자리, 조리기 = 젓는 빠르기 느긋하게 → 빠르게,
## 다지기 = 알맞은 빠르기 중 느린 쪽 → 빠른 쪽.
@export_range(0.0, 1.0) var secret_start: float = 0.0
@export_range(0.0, 1.0) var secret_end: float = 0.0


func has_secret() -> bool:
	return secret_end > secret_start


func is_in_secret(position: float) -> bool:
	return has_secret() and position >= secret_start and position <= secret_end
