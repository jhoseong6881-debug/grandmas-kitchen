# 그림 할 일 목록

지금은 단색 사각형이나 원으로 임시 표시하고 있는 곳들. 그림이 완성되면 파일만 교체한다.

**픽셀 배율: 3배 (2026-10-04, 디자이너님과 결정).** 그리는 판 640×360. 아래 표의 크기는 화면 크기이고, 디자이너님은 1/3 크기로 그린다
(디자이너용 원본 크기 목록: docs/discord/art-list.md). 게임은 기본 텍스처 필터 Nearest 로 또렷하게 키운다. 그림이 들어올 때 칸 크기를 3의 배수로 맞춘다.

| 위치 (씬/노드) | 필요한 그림 | 크기 | 상태 |
|---|---|---|---|
| data/ingredients/carrot.tres (icon) | 당근 아이콘 | 미정 | 할 일 |
| data/recipes/carrot_kimbop.tres (finished_image) | 할머니표 당근 김밥 완성 그림 | 미정 | 할 일 |
| scenes/kitchen/kitchen.tscn (Background) | 부엌 배경 | 1920x1080 | 할 일 |
| scenes/kitchen/kitchen.tscn (Counter) | 조리대 | 1920x300 | 할 일 |
| data/guests/rabbit.tres (portrait) | 토끼 손님 (기본 표정) | 360x480 (원본 120x160) | 할 일 |
| scenes/kitchen/guest_spot.tscn (SpeechBubble) | 말풍선 | 가변 (늘어나는 9칸 그림) | 할 일 |
| scenes/kitchen/minigames/chop_minigame.tscn (Board) | 도마 | 900x500 | 할 일 |
| scenes/kitchen/minigames/chop_minigame.tscn (Ingredient, Slices) | 썰기 전 재료 / 썬 조각 (재료마다) | 420x160 / 24x120 | 할 일 |
| scenes/kitchen/minigames/chop_minigame.tscn (Knife, TargetZone) | 칼 / 썰 자리 표시 | 10x300 / 50x240 | 할 일 |
| scenes/kitchen/minigames/chop_minigame.tscn (PerfectStamp) | 완벽 도장 (지금은 금색 글자) | 900x200 | 선택 |
| scenes/kitchen/minigames/plate_minigame.tscn (Bowl) | 그릇 | 400x480 | 할 일 |
| scenes/kitchen/minigames/plate_minigame.tscn (Fill) | 그릇에 차오르는 음식 (레시피마다) | 340x420 | 할 일 |
| scenes/kitchen/minigames/plate_minigame.tscn (BowlDotTemplate) | 완성한 그릇 표시 | 40x40 | 선택 |
| scenes/kitchen/minigames/stir_fry_minigame.tscn (Pan, Handle) | 팬 | 520x70 + 손잡이 | 할 일 |
| scenes/kitchen/minigames/stir_fry_minigame.tscn (Flame) | 불꽃 | 340x60 | 할 일 |
| scenes/kitchen/minigames/stir_fry_minigame.tscn (FoodTemplate) | 볶는 재료 조각 (재료마다) | 36x36 | 할 일 |
| scenes/kitchen/minigames/pan_fry_minigame.tscn (Pan, Handle) | 위에서 본 프라이팬 | 520x520 + 손잡이 | 할 일 |
| scenes/kitchen/minigames/pan_fry_minigame.tscn (Jeon) | 전 (흰 그림, 익는 색은 코드가 입힘. 레시피마다 다르면 좋음) | 320x320 | 할 일 |
| scenes/kitchen/minigames/pan_fry_minigame.tscn (Plate, DoneTemplate) | 접시 / 접시 위 작은 전 | 340x120 / 64x64 | 선택 |
| scenes/kitchen/minigames/pan_fry_minigame.tscn (DonenessBar) | 익힘 막대 | 600x32 | 선택 |
| scenes/kitchen/minigames/roll_minigame.tscn (Pan, Handle) | 위에서 본 네모난 계란말이 팬 | 800x400 + 손잡이 | 할 일 |
| scenes/kitchen/minigames/roll_minigame.tscn (Sheet) | 팬에 펴진 계란물 | 늘어나는 띠 (높이 312) | 할 일 |
| scenes/kitchen/minigames/roll_minigame.tscn (Roll) | 말린 계란 (겹마다 두꺼워짐) | 36~144 x 336 | 할 일 |
| scenes/kitchen/minigames/rice_minigame.tscn (Bowl, Water) | 쌀 씻는 바가지 / 물 (물 색은 코드가 입힘) | 480x480 / 420x420 | 할 일 |
| scenes/kitchen/minigames/rice_minigame.tscn (RiceTemplate, Hand) | 쌀알 / 씻는 손 | 8x18 / 64x64 | 할 일 |
| scenes/kitchen/minigames/rice_minigame.tscn (Pot, Lid, Flame) | 가마솥 / 솥뚜껑 / 아궁이 불 | 420x270 / 480x44 / 260x80 | 할 일 |
| scenes/kitchen/minigames/mix_minigame.tscn (Bowl) | 넓은 버무리기 그릇 | 960x440 | 할 일 |
| scenes/kitchen/minigames/mix_minigame.tscn (Spatula) | 나무 주걱 (위에서 본 모습) | 36x380 | 할 일 |
| scenes/kitchen/minigames/mix_minigame.tscn (PieceTemplate/Coat) | 양념 묻은 반짝임 (조각은 재료 아이콘을 그대로 씀, 양념 색은 data/coatings/) | 56x56 | 선택 |
| scenes/kitchen/minigames/simmer_minigame.tscn (Pot, Sauce) | 위에서 본 냄비 / 조림 국물 (국물 색은 data/coatings/) | 520x520 / 460x460 | 할 일 |
| scenes/kitchen/minigames/simmer_minigame.tscn (Spoon) | 나무 숟가락 | 240x44 | 할 일 |
| scenes/kitchen/minigames/simmer_minigame.tscn (TargetRing, BeatRing) | 박자 원 (금색 / 하얀색) | 140x140 | 선택 |
| data/ingredients/egg.tres (icon) | 계란 아이콘 | 미정 | 할 일 |
| data/ingredients/acorn.tres (icon) | 도토리 아이콘 | 미정 | 할 일 |
| data/recipes/acorn_jelly_muchim.tres (finished_image) | 도토리묵 무침 완성 그림 | 미정 | 할 일 |
| data/recipes/carrot_egg_stir_fry.tres (finished_image) | 당근 계란 볶음 완성 그림 | 미정 | 할 일 |
| data/guests/hen.tres (portrait) | 암탉 손님 (기본 표정) | 360x480 (원본 120x160) | 할 일 |
| data/guests/squirrel.tres (portrait) | 다람쥐 손님 (기본 표정) | 360x480 (원본 120x160) | 할 일 |
| scenes/porch/porch.tscn (Sky, Sunset, Ground) | 저녁 마당 배경 (노을, 마당) | 1920x1080 | 할 일 |
| scenes/porch/porch.tscn (Pyeongsang) | 평상 | 1200x120 | 할 일 |
| scenes/porch/porch.tscn (NoteCard) | 할머니 레시피 노트 종이 | 720x360 | 할 일 |
| data/recipes/carrot_acorn_jeon.tres (finished_image) | 할머니표 당근 도토리전 완성 그림 | 미정 | 할 일 |
| scenes/garden/garden.tscn (Sky, Sun, Ground) | 아침 텃밭 배경 | 1920x1080 | 할 일 |
| scenes/garden/garden.tscn (텃밭 칸 버튼) | 텃밭 칸 (다 자람 / 자라는 중, 작물마다) | 260x240 | 할 일 |
| scenes/garden/garden.tscn (BasketButton) | 이웃 바구니 (찬 것 / 빈 것) | 300x180 | 할 일 |
| scenes/ui/title.tscn (Background, GameTitle) | 타이틀 배경 / 제목 로고 | 1920x1080 | 할 일 |
| data/ingredients/honey.tres (icon) | 꿀 아이콘 | 미정 | 할 일 |
| data/ingredients/mushroom.tres (icon) | 버섯 아이콘 | 미정 | 할 일 |
| data/guests/bear.tres (portrait) | 곰 손님 (기본 표정) | 360x480 (원본 120x160) | 할 일 |
| data/guests/hedgehog.tres (portrait) | 고슴도치 손님 (기본 표정) | 360x480 (원본 120x160) | 할 일 |
| data/recipes/forest_mushroom_stir_fry.tres (finished_image) | 숲속 버섯 볶음 완성 그림 | 미정 | 할 일 |
| data/recipes/honey_carrot_jorim.tres (finished_image) | 꿀 당근 조림 완성 그림 | 미정 | 할 일 |
| data/recipes/acorn_honey_gangjeong.tres (finished_image) | 도토리 꿀강정 완성 그림 | 미정 | 할 일 |
| data/recipes/mushroom_egg_jeon.tres (finished_image) | 버섯 계란전 완성 그림 | 미정 | 할 일 |
| data/recipes/honey_egg_roll.tres (finished_image) | 꿀 계란말이 완성 그림 | 미정 | 할 일 |
| data/recipes/acorn_jelly_mushroom_bap.tres (finished_image) | 버섯 도토리묵밥 완성 그림 | 미정 | 할 일 |
| scenes/ui/guest_notebook.tscn (Book) | 손님 수첩 종이 (+ 손님 얼굴 작은 그림) | 1440x840 | 할 일 |
| scenes/porch/spring_feast.tscn (Sky, Lanterns, Ground, Pyeongsang) | 봄 잔치 밤 배경 (등불, 잔칫상 차린 평상) | 1920x1080 | 할 일 |
| scenes/porch/spring_feast.tscn (손님 그림) | 잔치에 앉은 손님 다섯 (앉은 모습) | 180x240 | 할 일 |
| scenes/porch/spring_feast.tscn (Letter, NoteCard) | 할머니 편지지 / 완성된 노트 | 1240x820 | 할 일 |
| scenes/porch/spring_feast.tscn (Teaser) | 여름 예고 그림 | 1920x1080 | 선택 |
| scenes/ui/pause_menu.tscn (Box) | 일시 정지 메뉴 판 | 840x660 | 선택 |
| scenes/garden/menu_board.tscn (Board) | 오늘의 메뉴 칠판 | 1560x960 | 할 일 |
| scenes/garden/mushroom_logs.tscn (ForestShade, TreeLeft, TreeRight, Ground) | 버섯 원목이 있는 숲 그늘 배경 | 1920x1080 | 할 일 |
| scenes/garden/mushroom_logs.tscn (PlotRow 버튼) | 버섯 원목 (빈 원목 / 자라는 중 / 다 자람) | 260x240 | 할 일 |
| scenes/garden/plant_picker.tscn (Board) | "무엇을 심을까요?" 나무 판 | 1120x520 | 선택 |
| data/story/prologue.tres (각 장 Background Image) | 프롤로그 배경 8장: 밤 지하철, 아침 전화, 여름 평상 회상, 소포와 빈 공책, 편지, 시골 버스, 숲속 밥집, 문틈의 토끼 | 1920x1080 | 할 일 |
| data/story/memories.tres (각 회상의 Background Image) | 할머니 회상 배경 3장: 여름 부엌 도마 앞의 할머니와 어린 나, 초겨울 밤 도시락 싸는 할머니 (+ 봄날 문 앞 꿀단지), 추석 시골 정류장의 은박지 김밥 | 1920x1080 | 할 일 |
| scenes/story/prologue.tscn (Paper) | 할머니 편지지 | 1000x900 | 선택 |
| data/keepsakes/*.tres (Icon) | 할머니 기념품 5개: 꽃무늬 손수건, 계란 바구니, 도토리 팽이, 꿀단지, 버섯 바구니 | 128x128 | 할 일 |
| scenes/kitchen/minigames/mince_minigame.tscn (Board, Knife) | 다지기 도마 / 큰 식칼 | 900x440 / 140x200 | 할 일 |
| scenes/kitchen/minigames/mince_minigame.tscn (Pile 조각) | 다져지는 재료 (단계마다 작아짐, 재료 색은 코드가 입힘) | 큰 조각 150x110 | 선택 |
| scenes/kitchen/shop_decor.tscn (Sign) | 가게 간판 (동네 밥집부터, 이름 글씨는 코드가 씀) | 400x72 | 할 일 |
| scenes/kitchen/shop_decor.tscn (Lanterns) | 처마 등불 2개 (소문난 할매식당) | 48x60 | 할 일 |
| scenes/kitchen/shop_decor.gd (평상) | 손님 평상 (단계마다 3~5개) | 110x40 | 할 일 |
| scenes/kitchen/shop_decor.tscn (Shelf, Plank) | 기념품 선반 | 560x170 | 선택 |
| scenes/ui/sleep_transition.tscn (Moon) | 잠드는 장면의 달 (지금은 노란 동그라미) | 160x160 | 할 일 |
| scenes/ui/sleep_transition.tscn (Sky) | 잠드는 장면 밤하늘 배경 (별, 지붕 실루엣 등. 아침으로 밝아지는 건 코드가 함) | 1920x1080 | 선택 |
| scenes/ui/sleep_transition.tscn (SaveIcon) | 저장 아이콘 (저장 중에 빙글빙글 돈다. 예: 할머니 레시피 공책) | 48x48 | 할 일 |
| scenes/garden/market.tscn (Merchant) | 너구리 상인 (넉살 좋은 떠돌이 장사꾼) | 220x260 | 할 일 |
| scenes/garden/market.tscn (Stall, StallRoof) | 장터 가판과 차양 | 460x200 / 500x60 | 할 일 |
| scenes/garden/market.tscn (Sky, Ground) | 숲속 장터 배경 | 1920x1080 | 선택 |
| scenes/ui/sunset_transition.tscn (SkyTop, SkyGlow, Sun, Hill) | 해 지는 장면: 노을 하늘, 지는 해, 산 실루엣 (해가 내려가는 건 코드가 함) | 1920x1080 / 해 180x180 | 할 일 |
| scenes/kitchen/guest_spot.gd (걸어 들어오기) | 손님 걷는 모습 (선택: 걸음마다 바뀌는 2장, 지금은 통통 튀기만 함) | 360x480 | 선택 |
| scenes/kitchen/kitchen_door.tscn (Frame, Outside, Leaf) | 부엌 뒷벽의 가게 문: 문틀 / 문 밖 풍경(문이 열리면 보임) / 문짝(창 달린 나무문, 왼쪽 경첩으로 접히며 열림). 손님이 이 문으로 드나든다 | 문 200x260 (원본 약 67x87) | 할 일 |
| data/guests/*.tres (raincoat_portrait) | 봄비 오는 날 우비 입은 손님 다섯 (암탉, 곰, 토끼, 다람쥐, 고슴도치). 지금은 노란 우비 도형(raincoat_shape.gd)을 씌움 | 360x480 (원본 120x160) | 할 일 |
| data/guests/*.tres (expression_portraits) | 손님 표정 그림: happy(웃음), surprised(놀람), sad(시무룩). 다섯 손님 × 3장. 없으면 기본 그림 (임시 도형일 땐 "(웃음)" 같은 글자) | 360x480 (원본 120x160) | 할 일 |
| scripts/ui/rain_overlay.gd | 빗줄기 (지금은 선으로 그림. 그림으로 바꾸려면 빗방울 한 줄 그림) | 4x40 | 선택 |
| scenes/garden/garden.tscn (Sky) | 비 오는 날 흐린 하늘 (지금은 맑은 하늘에 푸른빛만 덮음) | 1920x560 | 선택 |
| data/crops/carrot_crop.tres (Growth Textures) | 당근이 자라는 단계 그림 (막 심음 → 새싹 → 자람 → 다 자람, 3~4장. 마지막 장 = 거둘 때) | 칸 폭 x 칸 높이-90 (지금 260x150) | 할 일 |
| data/crops/mushroom_crop.tres (Growth Textures) | 원목 버섯이 자라는 단계 그림 (작은 버섯 1개 → 2개 → 3개 다 자람) | 260x150 | 할 일 |
| data/places/*.tres (Ground Color) | 칸 아래 땅 그림 (흙 / 원목). 지금은 단색 띠 | 260x34 | 선택 |
