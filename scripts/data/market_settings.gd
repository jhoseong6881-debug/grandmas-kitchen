class_name MarketSettings
extends Resource
## 숲속 장터 설정: 언제 열리는지, 장날마다 몇 가지 거래가 나오는지, 너구리 상인의 대사, 거래 목록.
## data/market/market_settings.tres 에 있다. 장터 장면(market.gd)과 텃밭의 장터 버튼이 읽는다.

## 첫 장날과 장날 간격 (예: 5, 5 → 5일, 10일, 15일째)
@export var first_day: int = 5
@export var interval_days: int = 5
## 장날마다 나오는 거래 수와, 같은 거래를 하루에 할 수 있는 횟수
@export var trades_per_day: int = 4
@export var daily_limit_per_trade: int = 3
## 상인 이름과 대사. {name} 은 주인공 이름으로 바뀐다.
@export var merchant_name: String = "너구리 상인"
## 처음 만났을 때 (줄을 이어 붙여 한꺼번에 보여 준다)
@export_multiline var first_meeting_lines: Array[String] = []
## 장날 인사 (장날마다 돌아가며 하나)
@export_multiline var greeting_lines: Array[String] = []
## 바꾸고 나서 (돌아가며 하나)
@export_multiline var trade_done_lines: Array[String] = []
@export_multiline var short_line: String = ""
@export_multiline var sold_out_line: String = ""
@export_multiline var farewell_line: String = ""
## 거래 목록. 장날마다 이 중 trades_per_day 개가 나온다.
@export var trades: Array[MarketTrade] = []


func is_market_day(day: int) -> bool:
	return interval_days > 0 and day >= first_day and (day - first_day) % interval_days == 0


## 몇 번째 장날인지 (첫 장날 = 0). 인사 대사를 돌릴 때 쓴다.
func get_market_index(day: int) -> int:
	return (day - first_day) / interval_days if interval_days > 0 else 0


## 그날의 거래. 같은 날에는 언제 열어도 같은 거래가 나오도록 날짜로 섞는다.
func get_todays_trades(day: int) -> Array[MarketTrade]:
	var shuffled: Array[MarketTrade] = trades.duplicate()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(day)
	for i: int in range(shuffled.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: MarketTrade = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = temp
	return shuffled.slice(0, trades_per_day)


func pick_line(lines: Array[String], index: int) -> String:
	return lines[posmod(index, lines.size())] if not lines.is_empty() else ""
