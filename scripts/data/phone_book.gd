class_name PhoneBook
extends Resource
## 잠드는 장면에서 오는 휴대폰 문자 목록. data/story/phone_messages.tres 에 있다.
## 문자를 더하거나 고치려면 에디터에서 phone_messages.tres 를 열어 Messages 칸을 바꾸면 된다.

@export var messages: Array[PhoneMessage] = []


## 그 계절 night 째 날 밤에 올 문자. 없으면 null.
func get_message(season: Season.Id, night: int) -> PhoneMessage:
	for message: PhoneMessage in messages:
		if message != null and message.season == season and message.night == night:
			return message
	return null
