# AI 시안 프롬프트 (SpriteCook · 픽셀랩)

**시안 전용 (2026-10-08 결정).** 여기서 만든 그림은 디자이너님께 보여 줄 참고용이고, 게임(assets/, data/)에는 넣지 않는다.
디스코드에 올릴 때는 "참고용 AI 시안"이라고 밝힌다. 프롬프트는 AI가 영어를 더 잘 알아들어서 영어로 썼고, 바로 아래에 한국어 뜻을 적었다.

기준 그림: 디자이너님 토끼 `assets/art/characters/rabbit/rabbit_default.png` (360×480, 2026-10-09 새 그림 · 웃음 rabbit_happy.png · 놀람 rabbit_surprised.png)
- 픽셀 그림이 아니라 **매끈한 선 + 단색 칠** 일러스트. 명암은 부드러운 그림자 한 단계 정도, 가장자리는 흐림 없이 또렷하게
- 동물 귀(길게 선 토끼 귀)와 작은 동물 코·입을 가진 **사람에 가까운 얼굴과 손**, 털색과 같은 곱슬머리를 땋아 내림
- 머리가 보이는 키의 1/3쯤, 머리부터 허리 아래까지 (아래는 그림 끝에서 잘림), 고개를 살짝 기울이고 플레이어를 바라봄 — 부엌 조리대 너머로 마주 보고 이야기하는 1인칭 화면
- 진한 밤색 테두리(굵기 고르게), 작고 까만 눈에 작은 하이라이트, 동그란 분홍 볼, 차분하고 살짝 바랜 따뜻한 색 (회갈색·연분홍·짙은 초록·바랜 빨강)
- 표정 그림에는 놀람 표시 같은 작은 만화 기호(주황 꼬불선)를 머리 옆에 얹기도 함
- 사연이 담긴 소품: 손 붕대(1막 사연), 두 손에 쥔 할머니의 빨간 꽃무늬 손수건, 레이스 달린 당근 주머니 초록 앞치마

## SpriteCook 설정

| 칸 | 넣을 것 |
|---|---|
| 모드 | 픽셀이 아닌 일반 그림(일러스트) 모드가 있으면 그것, 없으면 Pixel Art 로 만들고 그림체 차이는 감안해서 본다 |
| 배경 | Transparent (투명) |
| 크기 | 손님 360×480 (고를 수 없으면 가장 큰 크기로 만들고 가로:세로 3:4 로 맞춘다) · 잔치에 앉은 모습 180×240 · 너구리 72×88 |
| 테마 | 아래 "공통 그림체"를 테마로 한 번 만들어 두고, 다섯 손님 모두 같은 테마로 |

⚠️ 디자이너님 토끼 그림을 SpriteCook에 "참고 그림(Use as Reference)"으로 올리면 그림체가 가장 잘 맞지만,
디자이너님 작품을 AI 서비스에 올리는 일이라 **디자이너님께 먼저 여쭤본 뒤에만** 한다. 허락 전에는 글 프롬프트만 쓴다.

## 공통 그림체 (테마)

```
Cozy, gentle 2D character illustration for a healing cooking game set in a quiet Korean countryside forest village.
Clean, even dark-brown lineart, never pure black. Soft flat colors with one gentle shadow tone, crisp hard edges, no gradients.
Muted, slightly faded warm palette: greyish taupe, dusty pink, deep sage green, faded red, with small orange accents.
Animal villager drawn with a gentle human-like face and hands, keeping animal ears, a tiny animal nose and mouth,
and fur-colored hair. Head about one third of the visible height. Small dark eyes with a tiny white highlight,
simple brows, round pink blush cheeks, a soft shy expression. Transparent background.
```
뜻: 조용한 한국 시골 숲마을의 힐링 요리 게임 캐릭터 일러스트. 고른 굵기의 진한 밤색 선(검정 아님). 단색 칠에 부드러운 그림자 한 단계, 가장자리 또렷, 그라데이션 없음.
차분하고 살짝 바랜 따뜻한 색: 회갈색·연분홍·짙은 연초록·바랜 빨강, 주황은 포인트로만. 사람에 가까운 얼굴과 손에 동물 귀·작은 동물 코와 입·털색 머리카락.
머리는 보이는 키의 1/3쯤. 작고 까만 눈에 작은 하이라이트, 단순한 눈썹, 동그란 분홍 볼, 수줍고 순한 표정. 배경 투명.

## 피할 것 (네거티브 칸이 있으면)

```
text, letters, logo, watermark, pure black outlines, realistic shading, photo, 3D render, pixel art, dithering,
heavy gradients, glossy anime shading, oversized sparkly eyes, chibi proportions, neon colors, saturated colors,
cold blue palette, glowing effects, sparkle background, weapons, scary or angry face, full-body tiny figure
```
뜻: 글자·로고, 새까만 테두리, 사실적인 명암, 사진·3D 느낌, 픽셀 그림·점무늬, 짙은 그라데이션, 번쩍이는 애니메 명암, 지나치게 큰 반짝 눈, 머리 큰 꼬마 비율, 형광색·쨍한 색·차가운 파란색, 반짝이 배경, 무기, 무섭거나 화난 얼굴, 너무 작게 서 있는 전신.

## 손님 공통 구도

```
Character portrait, 360x480 pixels, upper body from the head down to the hips, cropped at the bottom edge,
facing the viewer at a slight three-quarter angle, as if talking to the player across a kitchen counter.
Same framing and head size as the rabbit villager in the same set (rabbit ears, braided curly hair, green apron).
```
뜻: 360×480, 머리부터 엉덩이까지(아래는 잘림), 살짝 비스듬히 플레이어를 보며 조리대 너머로 이야기하는 모습. 같은 세트의 토끼와 구도·머리 크기를 맞춘다.

각 손님 프롬프트는 **공통 구도 + 아래 손님 글**을 이어 붙여서 넣는다.

---

## 🐔 암탉

```
A plump, cheerful hen auntie who wakes the whole village at dawn and loves to chat.
Creamy white feathers with warm beige shading, a small bright red comb and wattle, orange beak slightly open
as if in the middle of chatting, lively round eyes. Wears a small apron with a tiny flower print.
One wing holds a woven basket of brown eggs half covered with a checkered cloth,
the other wing is raised in a friendly wave. Warm, talkative, motherly mood.
```
- **왜 이렇게:** 새벽마다 마을을 깨우는 수다쟁이, 할머니의 아침 수다 친구 → 부리를 살짝 벌린 "말하는 중" 표정과 손 인사.
- **계란 바구니:** 밥값(계란)이자 할머니께 받아 쓰다 주인공에게 물려주는 선물.
- **꽃무늬 앞치마:** 마을 아주머니 느낌. 봄에 알을 품고 병아리를 키우는 엄마라는 사연과도 맞아요.

## 🐿️ 다람쥐

```
A small, timid squirrel who speaks in short, shy words but whose eyes sparkle whenever acorns come up.
Reddish chestnut fur, cream belly and muzzle, tufted ears, and a huge fluffy tail curling up behind one shoulder,
half hiding behind it. Hugs one shiny acorn to the chest with both paws.
Wears a tiny moss-green neckerchief and a small cloth pouch bulging with acorns at the hip.
Shoulders slightly hunched, small shy smile, a bright sparkle highlight in the big eyes.
```
- **왜 이렇게:** 겁이 많아 말이 짧다 → 움츠린 어깨, 꼬리 뒤에 반쯤 숨는 자세. 도토리 얘기엔 눈이 반짝 → 눈에 반짝 하이라이트.
- **도토리 주머니:** 밥값(도토리), 뒷산 도토리나무를 제일 잘 안다는 설정.
- **이끼색 목수건:** 사연(할머니 도토리 자리에서 돋은 새싹, "할머니 나무")의 초록과 이어져요.
- 다람쥐는 몸이 작지만 같은 360×480 칸을 써서, 큰 꼬리로 칸을 채우게 했어요.

## 🐻 곰

```
A big, gentle, easygoing brown bear who has just woken up from hibernation and is always hungry.
Warm brown fur, cream muzzle, sleepy half-closed kind eyes, a messy tuft of bed-head fur on top of the head.
A wide body that fills the frame; the ears may nearly touch the top edge.
Wears faded mustard overalls with a small wood shaving and a tiny hammer peeking out of the front pocket.
Holds a round clay honey jar with a drip of golden honey in one paw, the other paw resting on his round tummy.
```
- **왜 이렇게:** 겨울잠에서 막 깬 느긋한 곰 → 졸린 반쯤 감은 눈, 머리 위 부스스한 털. 늘 배고프다 → 배에 얹은 손.
- **꿀단지:** 밥값(꿀)이자 할머니께 물려받은 선물 "꿀 한 병에 반찬 한 접시".
- **주머니 속 작은 망치와 대팻밥:** 2막 사연(몰래 할머니 평상을 고치고 있었다)의 숨은 힌트. 처음엔 아무도 눈치 못 채는 정도로 작게.
- 다섯 중 가장 커서, 칸을 넓게 채우게 했어요.

## 🦔 고슴도치

```
A small, reserved hedgehog who looks gruff but is meticulous and kind, and knows every mushroom spot on the forest floor.
Round body, dark chocolate-brown spines with light tan tips, a soft cream face and belly, small serious eyes
with slightly lowered brows, a tiny pink nose, and a faint blush that hints at hidden warmth.
Neat and tidy look with a small dark-green vest.
Carries a woven mushroom basket with a few brown and cream mushrooms;
a pair of old, worn leather gloves is tucked into the basket handle.
```
- **왜 이렇게:** 가시 때문에 무뚝뚝해 보이지만 다정하다 → 진지한 눈과 내린 눈썹, 그래도 살짝 볼 붉힘.
- **단정한 조끼:** "꼼꼼하다"는 성격을 옷으로.
- **버섯 바구니:** 밥값(버섯), 할머니와 같이 쓰던 바구니(선물).
- **낡은 가죽 장갑:** 3막 사연(할머니가 악수할 때 끼던 장갑, 마지막에 맨손 악수)의 상징. 바구니 손잡이에 살짝 끼워 둔 정도로.

## 🦝 너구리 상인 (72×88)

```
Full-body character sprite, 72x88 pixels, standing, facing the viewer at a slight three-quarter angle.
A friendly, easygoing traveling merchant raccoon who sets up a small forest market every five days.
Grey-brown fur, dark eye mask, a striped bushy tail, a wide confident grin with one eye winking.
Wears a wide straw hat and a patched travel vest, and carries a large wooden backpack frame
stacked with cloth-wrapped bundles, a small cooking pot and a little lantern.
```
- **왜 이렇게:** 닷새마다 장을 펴는 넉살 좋은 떠돌이 장사꾼 → 윙크하는 웃음, 짐을 잔뜩 진 큰 나무 등짐.
- **밀짚모자, 기운 조끼:** 오래 떠돌아다닌 느낌. 할머니와도 오래 거래한 사이예요.
- 장터 화면에서는 작게 나와서(72×88) 머리부터 발끝까지 전신이에요.

---

## 픽셀랩(PixelLab)에서 쓸 때 — 한 칸에 다 넣는 짧은 판

픽셀랩 캐릭터 만들기(pixellab.ai/create-character)는 테마 칸이 따로 없고 설명 칸이 하나뿐이다.
그래서 그림체 + 구도 + 손님을 한 줄로 합친 짧은 판을 쓴다. 회색 칸 하나를 통째로 복사해 설명 칸에 붙인다.
- 픽셀랩 그림 크기는 최대 140×140 (등급 1은 80×80) 이라 360×480 을 그대로 못 만든다. 시안이니 가장 큰 정사각형으로 만들고 비율만 본다.
- 필터(깔때기) 버튼에 크기·보는 방향·테두리·명암 설정이 있으면: 보는 방향은 정면(south), 명암은 basic shading, 테두리는 selective outline, 디테일은 medium.

🐔 암탉
```
Cozy soft flat-color illustration, clean dark-brown lineart, muted warm palette, one soft shadow tone, animal villager with a gentle human-like face and hands and animal ears, small dark eyes with a tiny highlight, round pink blush. Upper body, facing viewer. Plump cheerful hen auntie, cream white feathers, small red comb, orange beak open as if chatting, tiny flower-print apron, holding a woven basket of brown eggs with a checkered cloth, other wing waving hello.
```

🐿️ 다람쥐
```
Cozy soft flat-color illustration, clean dark-brown lineart, muted warm palette, one soft shadow tone, animal villager with a gentle human-like face and hands and animal ears, small dark eyes with a tiny highlight, round pink blush. Upper body, facing viewer. Small timid squirrel, chestnut fur, cream belly, huge fluffy tail curling behind shoulder, shyly hugging a shiny acorn with both paws, moss-green neckerchief, little acorn pouch, sparkle in eyes, shy smile.
```

🐻 곰
```
Cozy soft flat-color illustration, clean dark-brown lineart, muted warm palette, one soft shadow tone, animal villager with a gentle human-like face and hands and animal ears, small dark eyes with a tiny highlight, round pink blush. Upper body, facing viewer. Big gentle sleepy brown bear just woken from hibernation, half-closed kind eyes, messy bed-head tuft, faded mustard overalls with a tiny hammer in the pocket, holding a clay honey jar dripping honey, paw on round tummy.
```

🦔 고슴도치
```
Cozy soft flat-color illustration, clean dark-brown lineart, muted warm palette, one soft shadow tone, animal villager with a gentle human-like face and hands and animal ears, small dark eyes with a tiny highlight, round pink blush. Upper body, facing viewer. Small reserved hedgehog, chocolate-brown spines with tan tips, cream face, serious eyes, slightly lowered brows, faint blush, neat dark-green vest, carrying a woven mushroom basket with old leather gloves tucked in the handle.
```

🦝 너구리 상인
```
Cozy soft flat-color illustration, clean dark-brown lineart, muted warm palette, one soft shadow tone, animal villager with a gentle human-like face and hands and animal ears. Full body, standing, facing viewer. Friendly traveling merchant raccoon, grey-brown fur, dark eye mask, striped bushy tail, winking grin, wide straw hat, patched vest, big wooden backpack frame stacked with cloth bundles, a small pot and a lantern.
```

피할 것 칸이 있으면: `text, logo, black outline, realistic, 3D, pixel art, dithering, gradients, chibi, neon, blue palette, scary face`

짧은 판 앞부분 뜻: 포근한 단색 칠 일러스트, 깔끔한 진한 밤색 선, 차분한 따뜻한 색, 부드러운 그림자 한 단계, 사람에 가까운 얼굴과 손에 동물 귀, 작고 까만 눈에 작은 하이라이트, 동그란 분홍 볼.
픽셀랩은 픽셀 그림 전용 도구라 새 그림체(일러스트)와는 결과가 다르게 나온다. 구도·소품·색 느낌만 참고한다.

---

## 만든 뒤에

1. 손님마다 2~3장 만들어 보고, 가장 느낌이 맞는 것을 고른다.
2. 💬그림-피드백에 **"참고용 AI 시안이에요. 게임에는 넣지 않아요"** 라고 적고 올린다.
3. 디자이너님 의견을 듣는다 (색, 옷, 소품, 표정 중 마음에 드는 것만 참고).
4. 게임 파일(assets/, data/)에는 넣지 않는다.
