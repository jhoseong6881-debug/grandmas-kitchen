class_name Season
extends RefCounted
## 계절. 레시피 노트는 계절마다 따로 있어서, 그 계절에만 손님에게서 돌려받을 수 있다 (Recipe.note_season).
## 계절마다 다른 것(손님, 곡, 비, 장터, 마무리)은 data/seasons/ 의 SeasonData 에 있다 (spring.tres, summer.tres).

enum Id { SPRING, SUMMER, AUTUMN, WINTER }
