class_name Credits
extends Resource
## 처음 화면 "만든 사람들" 창에 보여 줄 글. data/credits.tres 에 하나 만든다.
## 위에는 body(만든 사람, 글꼴·소리·음악 출처)를, 그 아래에는 license_files 의 라이선스 원문과
## (켜 두면) Godot 엔진과 엔진에 들어 있는 다른 프로그램들의 저작권 표시를 붙여 보여 준다.
## 글꼴 라이선스(OFL)는 게임과 함께 저작권 표시·라이선스 글을 넣으라고 하므로 빼지 않는다.

## 창 제목
@export var title: String = "만든 사람들"
## 만든 사람과 출처 (여러 줄)
@export_multiline var body: String = ""
## 라이선스 원문 앞에 붙는 제목
@export var license_title: String = "라이선스 원문"
## 함께 보여 줄 라이선스 원문 파일 (.txt). 내보내기 설정의 include_filter 에도 넣어야 빌드에서 읽힌다.
@export var license_files: PackedStringArray = []
## Godot 엔진과 엔진에 들어 있는 다른 프로그램들의 저작권 표시를 붙일지
@export var show_engine_license: bool = true
## Godot 엔진 저작권 표시 앞에 붙는 제목
@export var engine_license_title: String = "Godot Engine"
## 닫기 버튼 글자
@export var close_text: String = "닫기"
