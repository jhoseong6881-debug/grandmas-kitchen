class_name NotebookButton
extends Button
## 손님 수첩 버튼 (텃밭, 부엌, 평상 왼쪽 위). 책 아이콘(원본 32×32, 화면 3배 = 96×96) 옆에 "손님 수첩" 글자.
## 아이콘 그림은 scenes/ui/notebook_button.tscn 의 Book Icon 칸에 넣으면 세 화면이 모두 바뀐다.
## 그림이 없으면 펼친 책 모양 임시 그림을 코드로 그린다.

const PLACEHOLDER_PIXELS: int = 32

## 책 아이콘 그림 (원본 32×32, 배경 투명). 비워 두면 임시 그림.
@export var book_icon: Texture2D
## 화면에서 키우는 배수 (도트 그림 3배 규칙)
@export var icon_scale: int = 3
## 임시 그림 색: 표지, 종이, 종이 줄, 테두리
@export var cover_color: Color = Color(0.55, 0.3, 0.17)
@export var page_color: Color = Color(0.98, 0.93, 0.8)
@export var page_line_color: Color = Color(0.84, 0.72, 0.53)
@export var outline_color: Color = Color(0.27, 0.13, 0.08)


func _ready() -> void:
	var image: Image = book_icon.get_image() if book_icon != null else _draw_placeholder()
	image = image.duplicate()
	image.resize(image.get_width() * icon_scale, image.get_height() * icon_scale, Image.INTERPOLATE_NEAREST)
	icon = ImageTexture.create_from_image(image)


## 펼친 책 모양 (밤색 표지 위에 크림색 두 쪽, 가운데 책등, 쪽마다 줄 몇 개)
func _draw_placeholder() -> Image:
	var size: int = PLACEHOLDER_PIXELS
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(1, 7, 30, 20), outline_color)
	image.fill_rect(Rect2i(2, 8, 28, 18), cover_color)
	for page_x: int in [3, 17]:
		image.fill_rect(Rect2i(page_x - 1, 5, 14, 19), outline_color)
		image.fill_rect(Rect2i(page_x, 6, 12, 17), page_color)
		for line_y: int in range(9, 21, 3):
			image.fill_rect(Rect2i(page_x + 2, line_y, 8, 1), page_line_color)
	image.fill_rect(Rect2i(15, 5, 2, 21), outline_color)
	return image
