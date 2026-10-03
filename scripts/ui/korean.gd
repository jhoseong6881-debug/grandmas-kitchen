class_name Korean
extends RefCounted
## 한국어 도우미: 낱말 끝 받침에 맞춰 조사를 고르고, 띄어쓰기 자리에서 줄을 바꾼다.


## 받침이 있으면 "이", 없으면 "가" (예: 암탉이, 토끼가)
static func subject_particle(word: String) -> String:
	return "이" if has_final_consonant(word) else "가"


## 받침이 있으면 "을", 없으면 "를" (예: 당근을, 버섯을)
static func object_particle(word: String) -> String:
	return "을" if has_final_consonant(word) else "를"


## 받침이 있으면 "과", 없으면 "와" (예: 곰과, 토끼와)
static func with_particle(word: String) -> String:
	return "과" if has_final_consonant(word) else "와"


## 마지막 글자가 받침 있는 한글인지
static func has_final_consonant(word: String) -> bool:
	if word.is_empty():
		return false
	var code: int = word.unicode_at(word.length() - 1)
	var is_hangul: bool = code >= 0xAC00 and code <= 0xD7A3
	return is_hangul and (code - 0xAC00) % 28 != 0


## 띄어쓰기 자리에서만 줄을 바꿔 max_width 안에 들어가게 한다. (Godot 자동 줄바꿈은 한글을 글자 중간에서도 자른다)
## 이미 있는 줄바꿈("\n")은 그대로 두고, 한 낱말이 max_width 보다 길면 그 낱말은 그대로 한 줄에 둔다.
static func wrap_by_spaces(text: String, font: Font, font_size: int, max_width: float) -> String:
	var lines: PackedStringArray = []
	for paragraph: String in text.split("\n"):
		var line: String = ""
		for word: String in paragraph.split(" "):
			var candidate: String = word if line.is_empty() else line + " " + word
			if not line.is_empty() and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
				lines.append(line)
				line = word
			else:
				line = candidate
		lines.append(line)
	return "\n".join(lines)
