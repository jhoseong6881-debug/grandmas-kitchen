class_name Ingredient
extends Resource
## 재료 하나의 정보. data/ingredients/ 에 .tres 파일로 하나씩 만든다.

## 세이브 파일에 저장되는 고유 이름표. 영어 소문자로 짓고 한 번 정하면 바꾸지 않는다. (예: carrot)
@export var id: StringName = &""
## 화면에 보이는 이름 (예: 당근)
@export var display_name: String = ""
## 그림이 없을 때 만드는 임시 사각형 아이콘의 크기(픽셀). 화면에서는 늘려서 보여 준다.
const PLACEHOLDER_ICON_PIXELS: int = 12

## 재료 그림. 비워 두면 placeholder_color 색의 임시 사각형으로 표시한다.
@export var icon: Texture2D
## 손질한 조각 그림: 조리기 냄비와 버무리기 그릇 안에 보이는 모습 (예: 깍둑 썬 당근). 비워 두면 통째 아이콘 대신
## placeholder_color 색의 임시 사각형을 쓴다 (통당근이 냄비에 들어가 보이지 않게).
@export var cut_icon: Texture2D
## 그림이 아직 없을 때 쓰는 임시 색. 재료마다 다르게 정해 두면 그림 없이도 구분된다.
@export var placeholder_color: Color = Color(0.85, 0.55, 0.3)
@export_multiline var description: String = ""
## 썰기 미니게임에서 이 재료를 썰 때 나는 소리 (data/sounds/ 의 id). 비우면 썰기 기본 소리.
@export var chop_sound: StringName = &""

## 그림이 없을 때 쓰는 임시 사각형 (처음 쓸 때 한 번 만들어 둔다)
var _placeholder_texture: Texture2D


## 아이콘으로 쓸 그림. 그림이 있으면 그 그림, 없으면 임시 색 사각형.
func get_icon_texture() -> Texture2D:
	if icon != null:
		return icon
	return _get_placeholder_texture()


## 냄비·그릇 안 조각으로 쓸 그림. 손질한 조각 그림이 있으면 그것, 없으면 임시 색 사각형 (통째 아이콘은 쓰지 않는다).
func get_piece_texture() -> Texture2D:
	if cut_icon != null:
		return cut_icon
	return _get_placeholder_texture()


func _get_placeholder_texture() -> Texture2D:
	if _placeholder_texture == null:
		var image: Image = Image.create(PLACEHOLDER_ICON_PIXELS, PLACEHOLDER_ICON_PIXELS, false, Image.FORMAT_RGBA8)
		image.fill(placeholder_color)
		_placeholder_texture = ImageTexture.create_from_image(image)
	return _placeholder_texture
