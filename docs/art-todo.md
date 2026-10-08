# 그림 할 일 목록

지금은 단색 사각형이나 원으로 임시 표시하고 있는 곳들. 그림이 완성되면 파일만 교체한다.

**AI 그림 도구(SpriteCook 등)는 아이디어 시안으로만 쓴다 (2026-10-08 결정).** 디자이너님께 보여 줄 참고용으로만 만들고,
게임(assets/, data/)에는 넣지 않는다. 디스코드에 올릴 때는 "참고용 AI 시안"이라고 밝힌다. 그림이 없는 곳은 지금처럼 임시 도형.

**픽셀 배율: 3배 (2026-10-04, 디자이너님과 결정).** 그리는 판 640×360. 아래 표의 크기는 화면 크기이고, 디자이너님은 1/3 크기로 그린다
(디자이너용 원본 크기 목록: docs/discord/art-list.md). 게임은 기본 텍스처 필터 Nearest 로 또렷하게 키운다. 그림이 들어올 때 칸 크기를 3의 배수로 맞춘다.

**데모에 먼저 필요한 그림 (2026-10-06, 화면에 보이는 시간 순서)** — 자동 플레이로 잰 화면 비율: 부엌 59% · 저녁 평상 26% · 아침 텃밭 12%
1. 남은 손님 넷(암탉·다람쥐·곰·고슴도치) 기본 모습 120x160
2. 부엌 배경 640x360 + 조리대 640x100
3. 재료 아이콘 넷(계란·도토리·꿀·버섯) 16x16
4. 완성 요리 10개 64x64
5. 저녁 평상 3장 (배경 640x360 · 돌담 640x110 · 평상 끝 640x40)
6. 썰기 도구 (도마 · 칼)
7. 아침 텃밭 배경 + 텃밭 칸
그다음: 손님 표정·얼굴 아이콘 → 다른 미니게임 도구 → 화면 소품 → 이야기 그림. 디스코드 🎨그림-목록 첫 글에도 같은 순서.

**그림이 들어오면 검사하기**: 프로젝트 폴더에서 `python3 tools/check_art.py` — 연결된 그림이 규격 크기인지, 표정·우비 그림이 기본 그림과
크기가 같은지(다르면 표정이 바뀔 때 흔들림), 배경이 투명한지, 가져오기 설정(손실 압축·밉맵)이 괜찮은지, 연결 안 된 그림이 있는지 알려 준다.
그림 파일은 읽기만 하고 바꾸지 않는다.

| 위치 (씬/노드) | 필요한 그림 | 크기 | 상태 |
|---|---|---|---|
| scenes/ui/title.tscn (StoryButton → Icon) | 처음 화면 오른쪽 아래 "이야기 다시 보기" 아이콘 (만든 사람들 아이콘 왼쪽. 그림이 오면 Icon 칸에 넣고 Text 를 지운다) | 120x120 (원본 40x40) | 할 일 |
| scenes/ui/title.tscn (CreditsButton → Icon) | 처음 화면 오른쪽 아래 "만든 사람들" 아이콘 (그림이 오면 버튼 Icon 칸에 넣고 Text 를 지운다. 지금은 글자만 있는 임시 버튼) | 120x120 (원본 40x40) | 할 일 |
| project.godot (config/icon), 내보내기 아이콘 | 게임 아이콘 (실행 파일·맥 앱·작업 표시줄). 지금은 Godot 기본 아이콘 | 원본 64x64 (256·1024로 정수배) | 할 일 |
| 스팀 상점·라이브러리 (게임 밖) | 헤더·작은·메인·세로 캡슐, 라이브러리 캡슐·히어로·로고 — 크기와 규칙은 docs/steam-store.md | docs/steam-store.md 표 | 출시 준비 |
| data/ingredients/carrot.tres (icon) | 당근 아이콘 — assets/art/ingredients/carrot.png | 원본 16x16 (가진 재료·메뉴판·결과판 32, 밥값 48) | 완료 (2026-10-06) |
| data/ingredients/carrot.tres (cut_icon) | 깍둑 썬 당근 조각 (조리기 냄비·버무리기 그릇 안에 보임. 없으면 당근 색 네모) | 원본 16x16 | 할 일 |
| data/recipes/carrot_kimbop.tres (finished_image) | 할머니표 당근 김밥 완성 그림 | 미정 | 할 일 |
| scenes/kitchen/kitchen.tscn (Background) | 부엌 배경 | 1920x1080 | 할 일 |
| scenes/kitchen/kitchen.tscn (Counter) | 조리대 | 1920x300 | 할 일 |
| data/guests/rabbit.tres (portrait) | 토끼 손님 (기본 표정) — assets/art/characters/rabbit/rabbit_default.png | 360x480 (원본 120x160) | 완료 (2026-10-06) |
| scenes/kitchen/guest_spot.tscn (SpeechBubble) | 말풍선 | 가변 (늘어나는 9칸 그림) | 할 일 |
| scenes/kitchen/minigames/chop_minigame.tscn (Board) | 도마 | 900x500 | 할 일 |
| scenes/kitchen/minigames/chop_minigame.tscn (Ingredient, Slices) | 썰기 전 재료 / 썬 조각 (재료마다) | 420x160 / 24x120 | 할 일 |
| scenes/kitchen/minigames/chop_minigame.tscn (Knife, TargetZone) | 칼 / 썰 자리 표시 (칼은 마우스를 따라 움직이고 위아래로 썬다) | 10x180 / 50x240 | 할 일 |
| scenes/kitchen/minigames/chop_minigame.tscn (PerfectStamp) | 완벽 도장 (지금은 금색 글자) | 900x200 | 선택 |
| scenes/kitchen/minigames/stir_fry_minigame.tscn (Pan, Handle) | 팬 | 520x70 + 손잡이 | 할 일 |
| scenes/kitchen/minigames/stir_fry_minigame.tscn (Flame) | 불꽃 | 340x60 | 할 일 |
| scenes/kitchen/minigames/stir_fry_minigame.tscn (FoodTemplate) | 볶는 재료 조각 (재료마다) | 36x36 | 할 일 |
| scenes/kitchen/minigames/pan_fry_minigame.tscn (Pan, Handle) | 위에서 본 프라이팬 | 520x520 + 손잡이 | 할 일 |
| scenes/kitchen/minigames/pan_fry_minigame.tscn (Jeon) | 전 (흰 그림, 익는 색은 코드가 입힘. 레시피마다 다르면 좋음) | 320x320 | 할 일 |
| scenes/kitchen/minigames/pan_fry_minigame.tscn (Spatula) | 뒤집개 (위에서 본 모습, 마우스를 따라다니다 위로 휙 올려 전을 뒤집는다. 지금은 회색 막대) | 120x27 (원본 40x9 안팎) | 할 일 |
| scenes/kitchen/minigames/pan_fry_minigame.tscn (Batter) | 펴지는 반죽은 코드가 동그라미와 소용돌이 줄로 그린다 (그림 필요 없음, 색만 raw_color·spiral_ring_color 로 조절) | - | 참고 |
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
| scenes/porch/porch.tscn (Backdrop → Picture) | 저녁 배경: 밤하늘(아래는 노을빛), 별, 먼 산과 숲, 담 너머 마을 길. 구도: 평상에 앉은 내 눈높이 (지금은 PorchScenery 임시 도트) | 1920x1080 (원본 640x360) | 할 일 |
| scenes/porch/porch.tscn (Wall → Picture) | 등불 달린 낮은 돌담. 손님이 담 너머에 서서 이야기하고, 담이 손님 아랫몸을 가린다 (점심 조리대처럼). 위쪽은 투명, 담은 아래 약 73칸, 왼쪽에 등불 기둥 | 1920x330 (원본 640x110, 배경 투명) | 할 일 |
| scenes/porch/porch.tscn (Bench → Picture) | 화면 맨 아래 평상 끝 (내가 평상에 앉아 있다는 표시, 나무판) | 1920x120 (원본 640x40) | 할 일 |
| scenes/porch/porch.tscn (NoteCard) | 할머니 레시피 노트 종이 | 720x360 | 할 일 |
| data/recipes/carrot_acorn_jeon.tres (finished_image) | 할머니표 당근 도토리전 완성 그림 | 미정 | 할 일 |
| scenes/garden/garden.tscn (Sky, Sun, Ground) | 아침 텃밭 배경 | 1920x1080 | 할 일 |
| scenes/garden/garden.tscn (텃밭 칸 버튼) | 텃밭 칸 (다 자람 / 자라는 중, 작물마다) | 260x240 | 할 일 |
| scripts/garden/garden.gd (Basket Full Icon / Basket Empty Icon) | 이웃 바구니 아이콘: 체크 천 덮은 것(뭔가 들어 있음) / 천 없이 빈 것. 지금은 BasketIcon 이 그린 도트 바구니 | 96x96 (원본 32x32, 배경 투명) | 할 일 |
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
| data/guests/*.tres (feast_portrait) | 잔치에 앉은 손님 다섯 (앉은 모습). 비워 두면 손님 그림(portrait)을 대신 쓰고, 그것도 없으면 임시 사각형 | 180x240 (원본 60x80) | 할 일 |
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
| data/guests/*.tres (raincoat_portrait) | 봄비 오는 날 우비 입은 손님 다섯 (암탉, 곰, 토끼, 다람쥐, 고슴도치). 지금은 임시 손님 그림에만 노란 우비 도형(raincoat_shape.gd)을 씌움 (진짜 그림이 있으면 우비 그림이 생길 때까지 평소 모습) | 360x480 (원본 120x160) | 할 일 |
| data/guests/*.tres (expression_portraits) | 손님 표정 그림: happy(웃음), surprised(놀람), sad(시무룩). 다섯 손님 × 3장. 없으면 기본 그림 (임시 도형일 땐 "(웃음)" 같은 글자) | 360x480 (원본 120x160) | 할 일 |
| scripts/ui/rain_overlay.gd | 빗줄기 (지금은 선으로 그림. 그림으로 바꾸려면 빗방울 한 줄 그림) | 4x40 | 선택 |
| scenes/garden/garden.tscn (Sky) | 비 오는 날 흐린 하늘 (지금은 맑은 하늘에 푸른빛만 덮음) | 1920x560 | 선택 |
| data/crops/carrot_crop.tres (Growth Textures) | 당근이 자라는 단계 그림 (막 심음 → 새싹 → 자람 → 다 자람, 3~4장. 마지막 장 = 거둘 때) | 칸 폭 x 칸 높이-90 (지금 260x150) | 할 일 |
| data/crops/mushroom_crop.tres (Growth Textures) | 원목 버섯이 자라는 단계 그림 (작은 버섯 1개 → 2개 → 3개 다 자람) | 260x150 | 할 일 |
| data/places/*.tres (Ground Color) | 칸 아래 땅 그림 (흙 / 원목). 지금은 단색 띠 | 260x34 | 선택 |
| scenes/garden/basket_note.tscn (Paper) | 이웃 바구니 쪽지 종이 (지금은 크림색 상자). 귀퉁이 접힌 메모지, 손님마다 다른 종이여도 좋음 | 960x? (글 길이에 따라 늘어남, 9칸 늘이기) | 선택 |
| data/guests/*.tres (Icon) | 손님 작은 얼굴 아이콘 (장사 결과판 손님 줄 이름 옆, 손님 수첩에도 쓸 수 있음). 지금은 손님마다 다른 색 네모 | 48x48 (원본 16x16) | 할 일 |
| scenes/ui/notebook_button.tscn (Book Icon) | 손님 수첩 버튼 책 아이콘 (펼친 책). 텃밭·부엌·평상 왼쪽 위 버튼 세 개가 함께 바뀜. 지금은 코드로 그린 임시 책 | 96x96 (원본 32x32, 배경 투명) | 할 일 |
| scenes/porch/recipe_note_book.tscn (Book Texture) | 저녁 평상에서 레시피 노트를 되찾을 때 뜨는 펼친 할머니 노트 (왼쪽 쪽에 완성 요리 그림, 오른쪽 쪽에 글을 게임이 올림). 지금은 밤색 표지 + 크림색 두 쪽 임시 모양 | 840x480 (원본 280x160, 배경 투명) | 할 일 |
| data/recipes/*.tres (Finished Image) | 완성 요리 그림 (접시 / 국물 요리는 그릇에 담긴 모습). "완성~!" 장면(4배), 대접할 때 미끄러지는 접시(3배), 레시피 노트에 같이 쓴다. 지금은 DishArt 가 재료 색으로 그린 임시 그림 | 원본 64x64 | 할 일 |
| scenes/ui/goal_board.tscn → scripts/ui/goal_board.gd (Board Texture) | 목표판: 나무 틀 안 크림색 종이 (9칸 늘이기, 가장자리 Board Margin 칸 그대로). 지금은 코드로 그린 도트 판 | 원본 약 26x26 이상, 배경 투명 | 할 일 |
| scenes/ui/goal_button.tscn → scripts/ui/goal_button.gd (Board Icon) | 계절 목표 버튼 아이콘: 과녁에 화살 (누르면 목표판이 크게 뜸). 지금은 코드로 그린 도트 과녁 | 96x96 (원본 32x32, 배경 투명) | 할 일 |
| scenes/kitchen/note_puzzle_board.tscn (Paper) | 번진 할머니 노트 퍼즐 창의 노트 종이 (왼쪽, 손글씨 줄을 게임이 올림). 지금은 크림색 상자. 펼친 노트 그림(recipe_note_book)과 맞추면 좋음 | 792x672 | 할 일 |
| scripts/kitchen/note_puzzle_board.gd (번진 자국) | 노트의 번진 잉크 자국 몇 가지 (지금은 보라·주황 단색 띠) | 약 160x48 | 선택 |
| data/pantry/*.tres (Icon) | 노트 퍼즐 재료 카드에 쓰는 부엌 기본양념 아이콘. 지금 쓰는 것: 기름(cooking_oil), 물(water), 도토리가루(acorn_flour), 밀가루(flour). 모두 단색 네모 | 48x48 (원본 16x16) | 할 일 |
| data/garnishes/*.tres (Shaker Image) | 요리 "완성~!" 장면 오른쪽에 세워 두는 고명 병: 깨소금·참기름·꿀·고춧가루 (서 있는 모습, 배경 투명. 병이 기울어져 뿌리므로 위가 입구). 지금은 코드로 그린 뚜껑 + 유리병 + 이름표 | 150x210 (원본 50x70) | 할 일 |
