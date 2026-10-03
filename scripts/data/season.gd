class_name Season
extends RefCounted
## 계절. 레시피 노트는 계절마다 따로 있어서, 그 계절에만 손님에게서 돌려받을 수 있다 (Recipe.note_season).
## 지금은 봄만 있다. 계절이 늘면 SeasonEnding 도 계절마다 하나씩 만든다.

enum Id { SPRING, SUMMER, AUTUMN, WINTER }
