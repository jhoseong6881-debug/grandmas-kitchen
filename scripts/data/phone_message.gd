class_name PhoneMessage
extends Resource
## 잠드는 장면에서 휴대폰으로 오는 문자 한 묶음 (주인공 이야기: 도시로 돌아갈까). PhoneBook 안에 넣는다.
## 그 계절 night 째 날 밤, 잠들기 전에 휴대폰이 울리고 말풍선이 하나씩 뜬다. {name} 은 주인공 이름.

## 내가 보낸 말풍선은 이 글자로 시작한다 (오른쪽에 뜨고, 이 글자는 빼고 보여 준다)
const MY_PREFIX: String = "나:"

## 어느 계절 몇째 날 밤에 오는지
@export var season: Season.Id = Season.Id.SPRING
@export var night: int = 4
## 휴대폰 맨 위에 보이는 보낸 사람 (예: 엄마, 팀 단톡방)
@export var sender: String = ""
## 말풍선 (차례대로 뜬다). "나:" 로 시작하면 내가 보낸 말풍선.
@export_multiline var messages: Array[String] = []
## 답장 칸에 썼다가 지우는 글 (비워 두면 안 쓴다)
@export var draft_text: String = ""
## 휴대폰을 내려놓은 뒤 꿈 한 줄 대신 보여 주는 글 (비워 두면 꿈 한 줄)
@export var after_text: String = ""
