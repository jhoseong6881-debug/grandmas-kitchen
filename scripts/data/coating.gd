class_name Coating
extends Resource
## 버무리기 미니게임에서 재료에 묻히는 양념 (예: 꿀, 고추장 양념, 참기름). data/coatings/ 에 .tres 파일로 하나씩 만든다.
## 새 양념이 필요하면 코드 수정 없이 이 파일만 하나 더 만들고, 레시피의 Mix Coating 칸에 넣으면 된다.

## 화면에 보이는 이름 (예: 꿀)
@export var display_name: String = ""
## 조각에 묻었을 때 보이는 색. 그림이 생기기 전 임시로 쓰고, 그림이 생겨도 덧칠 색으로 쓸 수 있다.
@export var color: Color = Color(0.96, 0.74, 0.18)
