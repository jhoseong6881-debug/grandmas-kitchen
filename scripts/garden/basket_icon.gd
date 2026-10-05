class_name BasketIcon
extends RefCounted
## 이웃 바구니 아이콘 (원본 32×32). 그림이 없을 때 도트로 그린다: 손잡이 달린 나무 바구니,
## 뭔가 들어 있으면 파란 체크 천을 덮고, 비었으면 천 없이 속이 보인다.

const PIXELS: int = 32
const HANDLE_LIGHT: Color = Color(0.86, 0.6, 0.3)
const HANDLE_DARK: Color = Color(0.72, 0.46, 0.18)
const RIM: Color = Color(0.8, 0.53, 0.24)
const RIM_SHADE: Color = Color(0.6, 0.36, 0.12)
const BODY_LIGHT: Color = Color(0.9, 0.69, 0.4)
const BODY: Color = Color(0.84, 0.6, 0.31)
const BODY_DARK: Color = Color(0.74, 0.47, 0.2)
const INSIDE: Color = Color(0.52, 0.33, 0.15)
const CLOTH: Array[Color] = [Color(0.93, 0.94, 1.0), Color(0.5, 0.54, 0.84), Color(0.8, 0.82, 0.97), Color(0.64, 0.67, 0.9)]


static func draw(is_full: bool) -> Image:
	var image: Image = Image.create(PIXELS, PIXELS, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	# 손잡이 (위 막대와 양옆 기둥)
	image.fill_rect(Rect2i(10, 4, 12, 2), HANDLE_LIGHT)
	image.fill_rect(Rect2i(8, 6, 2, 12), HANDLE_LIGHT)
	image.fill_rect(Rect2i(22, 6, 2, 12), HANDLE_DARK)
	image.fill_rect(Rect2i(9, 5, 1, 1), HANDLE_LIGHT)
	image.fill_rect(Rect2i(22, 5, 1, 1), HANDLE_DARK)
	if is_full:
		# 파란 체크 천 (2칸씩 번갈아)
		for y: int in range(12, 17):
			for x: int in range(2, 30):
				image.set_pixel(x, y, CLOTH[(x / 2 + y / 2) % 2 + (y % 2) * 2])
		image.fill_rect(Rect2i(8, 12, 2, 5), HANDLE_LIGHT)
		image.fill_rect(Rect2i(22, 12, 2, 5), HANDLE_DARK)
	else:
		image.fill_rect(Rect2i(3, 15, 26, 2), INSIDE)
	# 테두리 (손잡이가 꽂힌 자리는 어둡게)
	image.fill_rect(Rect2i(2, 17, 28, 2), RIM)
	image.fill_rect(Rect2i(8, 17, 2, 3), RIM_SHADE)
	image.fill_rect(Rect2i(22, 17, 2, 3), RIM_SHADE)
	# 몸통: 아래로 갈수록 좁아지고, 오른쪽과 아래는 어둡게
	for y: int in range(19, 28):
		var inset: int = (y - 19) / 2 + 1
		for x: int in range(2 + inset, 30 - inset):
			var color: Color = BODY_LIGHT if y < 24 and x < 22 else BODY
			if x >= 30 - inset - 5 or y == 27:
				color = BODY_DARK
			image.set_pixel(x, y, color)
	return image
