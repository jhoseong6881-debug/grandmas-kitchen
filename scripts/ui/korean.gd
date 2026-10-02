class_name Korean
extends RefCounted
## 한국어 조사를 낱말 끝 받침에 맞춰 고르는 도우미.


## 받침이 있으면 "이", 없으면 "가" (예: 암탉이, 토끼가)
static func subject_particle(word: String) -> String:
	return "이" if has_final_consonant(word) else "가"


## 받침이 있으면 "을", 없으면 "를" (예: 당근을, 버섯을)
static func object_particle(word: String) -> String:
	return "을" if has_final_consonant(word) else "를"


## 마지막 글자가 받침 있는 한글인지
static func has_final_consonant(word: String) -> bool:
	if word.is_empty():
		return false
	var code: int = word.unicode_at(word.length() - 1)
	var is_hangul: bool = code >= 0xAC00 and code <= 0xD7A3
	return is_hangul and (code - 0xAC00) % 28 != 0
