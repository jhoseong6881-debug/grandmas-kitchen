# 소리 목록 (나중에 바꿀 소리)

효과음은 `data/sounds/` 의 `.tres` 파일 하나가 소리 하나다. 코드에서는 `Sound.play(&"id")` 로 부른다.
소리를 바꾸려면: 파일시스템에서 `data/sounds/<id>.tres` 더블클릭 → 인스펙터 **Streams** 칸의 파일을 바꾼다.
소리 크기는 **Volume Db**, 매번 높낮이를 조금씩 바꾸는 정도는 **Pitch Variation** 에서 정한다.
`.ogg` 파일을 파일시스템에서 클릭하면 인스펙터에서 미리 들어 볼 수 있다.

지금 소리는 모두 Kenney(kenney.nl)의 무료 소리 묶음(CC0: 출처 표시 없이 상업적으로도 써도 됨)에서 골랐다.
파일은 `assets/audio/sfx/kenney/`, 이용 조건은 같은 폴더의 `License.txt`.

## 직접 만든 효과음 (출처 기록, 출시 전에 권리를 꼭 다시 확인)
| 파일 | 쓰는 곳 | 만든 곳 | 요금제 / 권리 | 만든 날 |
|---|---|---|---|---|
| sfx/chop_carrot_1~3.mp3 | 당근 썰기 (Ingredient.chop_sound) | ElevenLabs (효과음 AI) | Starter → 상업적 이용 가능 (약관 기준, 출시 전 다시 확인) | 2026-10-04 |
| sfx/chop_mushroom_1~3.mp3 | 버섯 썰기 | ElevenLabs | Starter | 2026-10-04 |
| sfx/chop_kimbap_1~3.mp3 | 김밥 썰기 (CookStep.hit_sound) | ElevenLabs | Starter | 2026-10-04 |
| sfx/chop_jelly_1~3.mp3 | 도토리묵 썰기 | ElevenLabs | Starter | 2026-10-04 |
| sfx/chop_omelette_1~3.mp3 | 계란말이 썰기 | ElevenLabs | Starter | 2026-10-04 |

| sfx/sizzle_1~4.wav | 볶기에서 재료를 받을 때 (hit_stir_fry) | Freesound "Frying vegetables.wav" by BeeProductive — https://freesound.org/s/382287/ | **CC0** (출처 표시 없이 상업적 이용 가능) | 2026-10-04 |

| sfx/pan_flip_1~3.wav | 전을 뒤집을 때 (hit_pan_fry) | Freesound "Adding Bacon To Frying Pan" by Bon_Vivant_Pictures — https://freesound.org/s/440830/ | **CC0** | 2026-10-04 |

| sfx/rice_wash_1~4.wav | 쌀을 씻을 때 (hit_cook_rice) | Freesound "Water-Swishing-in-Kitchen-Sink.wav" by Joma86 — https://freesound.org/s/595794/ | **CC0** | 2026-10-04 |

- rice_wash 조각은 원본(40.4초, audio_source/rice_washing.wav)에서 물을 휘젓는 4.0·23.2·31.6·34.6초부터 0.6초씩 자른 것.
  Freesound 에 쌀 씻는 녹음이 거의 없어서 부엌 싱크대 물 휘젓기 소리로 대신했다.
- pan_flip 조각은 원본(55.5초, audio_source/pancake_flip.wav)에서 뒤집는 "착" 소리가 나는 14.0·27.2·32.6초부터 0.9초씩 자른 것.
- sizzle 조각은 원본(1분 6초)에서 툭 튀는 소리(주걱이 팬에 부딪힘) 없이 지글지글 고르게 이어지는 14.3·35.0·6.0·10.3초 부분을 잘라
  모노 16비트로 만든 것. 서로 다르게 들리게 1 짧고 바삭한 "칙"(0.45초), 2 보통 "치익"(0.7초), 3 긴 "치이이익"(0.95초), 4 부드러운 "쏴아"(0.8초)로 다듬었다.
  원본은 `audio_source/`(Godot 와 Git 에서 빠짐)에 있어서 다른 부분을 다시 잘라 쓸 수 있다.
- 썰기 소리 고르는 순서: 요리 단계의 Hit Sound → 재료의 Chop Sound → 썰기 기본 소리(hit_chop, Kenney).
- ElevenLabs 무료 요금제로 만든 소리는 상업적으로 쓸 수 없다.

## ⚠ 진짜 요리 소리로 바꾸면 좋은 것 (Kenney 에 요리 소리가 없어 비슷한 소리로 채움)
| id | 언제 | 지금 소리 | 바꾸고 싶은 소리 |
|---|---|---|---|
| hit_mix | 버무리기 | 풀 스치는 소리 | 양념 버무리는 촉촉한 소리 |
| hit_simmer | 조리기에서 저을 때 | 숟가락이 냄비에 닿는 소리 | 보글보글 끓는 소리 |
| harvest | 텃밭에서 거둘 때 | 묵직한 퍽 | 흙에서 쑥 뽑는 소리 |
| plant | 씨앗 심을 때 | 카펫 발소리 | 흙 토닥이는 소리 |
| receive | 밥값 재료, 이웃 바구니 | 가죽 주머니 소리 | 바구니에 담는 소리 |

## 그대로 써도 괜찮은 것
| id | 언제 |
|---|---|
| click | 모든 버튼 (저절로 남) |
| ready, go | 미니게임 "준비~", "시작!" |
| hit | 미니게임에 따로 정한 소리가 없을 때 쓰는 공통 소리 |
| hit_chop | 썰기 (칼질) |
| hit_mince | 다지기 (탁탁) |
| hit_plate | 담기 |
| hit_roll | 말기 (천 소리) |
| miss | 빗나감 (작고 부드럽게, 벌칙 느낌이 안 나게) |
| done, perfect, grandma_taste | 미니게임 완성 / 완벽 / 할머니 손맛 |
| guest_arrive | 손님이 올 때 (문 여는 소리) |
| serve | 대접할 때 (접시 내려놓기) |
| pop, tier_up | 손님 위로 뜨는 글 / 단골 단계가 오를 때 |
| book | 손님 수첩 펼치기 |
| note_page, secret, gift | 평상: 레시피 노트 / 할머니 비법 / 단골 선물 |
| result_line, shop_up | 장사 결과판 줄이 나올 때 / 가게 이름이 바뀔 때 |

## 미니게임마다 맞히는 소리
미니게임은 맞힐 때 `hit_` + 미니게임 종류 소리를 찾는다 (chop, stir_fry, plate, pan_fry, roll, cook_rice, mix, simmer, mince).
새 미니게임을 만들면 `data/sounds/hit_<종류>.tres` 만 추가하면 된다. 없으면 `hit` 소리를 쓴다.

## 배경음악
장면마다 인스펙터의 **Music** 칸에 곡을 넣는다 (타이틀, 프롤로그, 텃밭, 버섯 원목, 장터, 부엌, 평상, 봄 잔치).
비어 있으면 앞 장면 음악이 서서히 꺼진다. 같은 곡이면 끊기지 않고 이어진다. 곡은 끝나면 처음부터 다시 튼다.
파일은 `assets/audio/music/` 에 영어 이름으로 넣는다.

### 음악 출처 기록 (출시 전에 권리를 꼭 다시 확인)
| 파일 | 쓰는 곳 | 만든 곳 | 요금제 / 권리 | 만든 날 | 프롬프트 |
|---|---|---|---|---|---|
| title_spring.mp3 | 타이틀 | Suno AI | Pro 구독 중 생성 → 상업적 이용 가능 (Suno 약관 기준, 출시 전 다시 확인) | 2026-10-03 | (직접 적기) |

- Suno 무료 요금제로 만든 곡은 상업적으로 쓸 수 없고, 나중에 유료로 바꿔도 소급되지 않는다.
- 스팀 등록 때 "AI로 만든 콘텐츠"(배경음악)를 밝힌다.

### 아직 없는 곡
아침 텃밭, 점심 부엌 (2~3곡 돌려 틀기 예정), 저녁 평상, 프롤로그, 장터, 봄 잔치
