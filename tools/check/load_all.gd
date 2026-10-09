extends SceneTree
## 빠른 검사: 게임의 스크립트·장면·데이터 파일을 모두 불러와 보고, 못 여는 파일을 적는다. 게임을 실행하지는 않는다.
## 프로젝트 사본에서:  godot --headless --path <사본> --script <이 파일의 절대 경로>
## 빌드 확인(빈 폴더에서): godot --headless --main-pack <pck 또는 exe> --script <이 파일의 절대 경로>
## 다 열리면 "검사 통과", 아니면 "!! 못 엶" 줄과 함께 끝 코드 1.

## 글꼴도 본다: 교보 손글씨 .ttf 는 저장소에 없어서(.gitignore) 빌드 사본에 빠지기 쉽다.
const FOLDERS: Array[String] = ["res://scripts", "res://scenes", "res://data", "res://assets/fonts"]
## 빌드의 .gdc(미리 바꿔 둔 스크립트)는 "이름.gd.remap" 으로 열리므로 따로 세지 않는다.
const LOADABLE: Array[String] = ["gd", "tscn", "scn", "tres", "res", "ttf", "otf"]

var _checked: Dictionary[String, bool] = {}
var _failed: PackedStringArray = []


func _initialize() -> void:
	for folder: String in FOLDERS:
		_check_folder(folder)
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene.is_empty() or not ResourceLoader.exists(main_scene):
		_failed.append("첫 장면을 찾을 수 없음: %s" % main_scene)
	for line: String in _failed:
		print("!! 못 엶: ", line)
	print("파일 %d개 확인, 못 연 것 %d개" % [_checked.size(), _failed.size()])
	if _failed.is_empty():
		print("검사 통과")
	quit(0 if _failed.is_empty() else 1)


func _check_folder(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		_failed.append("폴더를 열 수 없음: %s" % path)
		return
	for sub: String in dir.get_directories():
		_check_folder(path.path_join(sub))
	for file: String in dir.get_files():
		# 빌드(pck)에서는 장면·스크립트가 "이름.remap", 글꼴이 "이름.import" 로만 보인다. 원래 이름으로 불러야 한다.
		# 프로젝트에서 .import 만 있고 글꼴 파일이 없으면 원래 이름으로 열다가 실패해서 잡힌다.
		var name: String = file.trim_suffix(".remap").trim_suffix(".import")
		if name.get_extension() not in LOADABLE:
			continue
		_check_file(path.path_join(name))


func _check_file(path: String) -> void:
	# 빌드에서는 같은 파일이 원래 이름과 .remap 두 가지로 보여서 한 번만 연다.
	if _checked.has(path):
		return
	_checked[path] = true
	var resource: Resource = ResourceLoader.load(path)
	if resource == null:
		_failed.append(path)
	elif resource is GDScript and not (resource as GDScript).can_instantiate():
		_failed.append("%s (스크립트 오류)" % path)
