class_name Crop
extends Resource
## 텃밭 작물 하나의 정보. data/crops/ 에 .tres 파일로 하나씩 만든다.
## 씨 뿌리기나 물 주기는 없다. 다 자라면 아침에 거두고, 거둔 뒤 regrow_days 일이 지나면 다시 자란다.

## 거두면 들어오는 재료와 개수
@export var ingredient: Ingredient
@export var harvest_amount: int = 1
## 거둔 뒤 다시 다 자라기까지 걸리는 날 수
@export var regrow_days: int = 2
