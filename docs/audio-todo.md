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
| sfx/chop_carrot_1~3.wav | 당근 썰기 (Ingredient.chop_sound) | ElevenLabs (효과음 AI) | Starter → 상업적 이용 가능 (약관 기준, 출시 전 다시 확인) | 2026-10-04 |
| sfx/chop_mushroom_1~3.wav | 버섯 썰기 | ElevenLabs | Starter | 2026-10-04 |
| sfx/chop_kimbap_1~3.wav | 김밥 썰기 (CookStep.hit_sound) | ElevenLabs | Starter | 2026-10-04 |
| sfx/chop_jelly_1~3.wav | 도토리묵 썰기 | ElevenLabs | Starter | 2026-10-04 |
| sfx/chop_omelette_1~3.wav | 계란말이 썰기 | ElevenLabs | Starter | 2026-10-04 |

| sfx/sizzle_1~4.wav | 볶기에서 재료를 받을 때 (hit_stir_fry) | Freesound "Frying vegetables.wav" by BeeProductive — https://freesound.org/s/382287/ | **CC0** (출처 표시 없이 상업적 이용 가능) | 2026-10-04 |

| sfx/pan_flip_1~3.wav | 전을 뒤집을 때 (hit_pan_fry) | Freesound "Adding Bacon To Frying Pan" by Bon_Vivant_Pictures — https://freesound.org/s/440830/ | **CC0** | 2026-10-04 |

| sfx/rice_wash_1~4.wav | 쌀을 씻을 때 (hit_cook_rice) | Freesound "Water-Swishing-in-Kitchen-Sink.wav" by Joma86 — https://freesound.org/s/595794/ | **CC0** | 2026-10-04 |

| sfx/simmer_bubble_1~4.wav | 조리기에서 저을 때 (hit_simmer) | Freesound "simmering-sauce.aif" by alienistcog — https://freesound.org/s/124584/ | **CC0** | 2026-10-04 |

| sfx/harvest_pull_1~4.wav | 텃밭·원목에서 거둘 때 (harvest) | Freesound "Plants or ferns - Manipulation & Hit" by Vrymaa — https://freesound.org/s/770112/ | **CC0** | 2026-10-04 |

| sfx/plant_soil_1~5.wav | 빈 칸에 심을 때 (plant) | Freesound "Planting Sounds.wav" by wobesound — https://freesound.org/s/488393/ | **CC0** | 2026-10-04 |

| sfx/item_pop_1.wav | 재료 받기: 밥값, 이웃 바구니, 장터 거래, 잔치 바구니 (receive) | Freesound "Item or Material Pickup Pop 1 of 3" by el_boss — https://freesound.org/s/665183/ | **CC0** | 2026-10-04 |
| sfx/item_pop_2.wav | 〃 | Freesound "Item or Material Pickup Pop 2 of 3" by el_boss — https://freesound.org/s/665182/ | **CC0** | 2026-10-04 |
| sfx/item_pop_3.wav | 〃 | Freesound "Item or Material Pickup Pop 3 of 3" by el_boss — https://freesound.org/s/665181/ | **CC0** | 2026-10-04 |

| sfx/loop_sizzle.wav | 볶는 동안 계속 깔리는 지글지글 (loop_stir_fry) | Freesound 382287 (위 sizzle 과 같은 원본) | **CC0** | 2026-10-04 |
| sfx/loop_rice_boil.wav | 밥 짓기 불 조절 동안 깔리는 보글보글 (loop_cook_rice) | Freesound 124584 (위 simmer_bubble 과 같은 원본) | **CC0** | 2026-10-04 |
| sfx/kalimba_ready.wav, kalimba_go.wav | 미니게임 "준비~" / "시작!" (ready, go) | Freesound "Kalimba (C-note)" by foochie_foochie — https://freesound.org/s/331047/ | **CC0** | 2026-10-04 |
| sfx/happy_beeps_perfect.wav | 미니게임 "완벽!" (perfect) | Freesound "Achievement Happy Beeps Jingle" by CogFireStudios — https://freesound.org/s/619838/ | **CC0** | 2026-10-04 |
| sfx/phone_buzz.wav, phone_buzz_2.wav | 잠드는 장면 휴대폰 진동 (phone_buzz, 번갈아 나옴) | Freesound "iPhone Vibrate on Wood Table" by steeltowngaming — https://freesound.org/s/537738/ | **CC0** | 2026-10-07 |
| sfx/dish_slide.wav, dish_slide_2.wav, dish_slide_3.wav | 대접할 때 접시가 조리대 위를 드윽 미끄러지는 소리 (dish_slide, 셋 중 하나) | Freesound "Plate Sliding on Counter.wav" by PVM — https://freesound.org/s/585634/ | **CC0** | 2026-10-07 |
| sfx/zone_secret.wav, zone_request.wav | 미니게임에서 할머니 비법 자리(주황) / 손님 부탁 자리(파랑)에 딱 맞혔을 때 "띠링" (zone_secret, zone_request) | Freesound 331047 (위 kalimba 와 같은 원본)의 음 높이를 바꾼 두 음 | **CC0** | 2026-10-07 |
| sfx/rain_light_loop.wav | 봄비 오는 날 낮 내내 깔리는 빗소리 (rain) | Freesound "Rain light 2 (rural)" by jmbphilmes — https://freesound.org/s/200273/ | **CC0** | 2026-10-04 |
| sfx/mix_toss_1~5.wav | 버무리기에서 맞힐 때 (hit_mix) | Freesound "Potato salad" by 14G_Panska_Kaminkova_A — https://freesound.org/s/419992/ | **CC0** | 2026-10-04 |
| sfx/porch_crickets_loop.wav | 저녁 평상 내내 작게 깔리는 풀벌레 소리 (porch_night) | Freesound "Night Crickets Back Porch.aiff" by hdfreema — https://freesound.org/s/333221/ | **CC0** | 2026-10-07 |
| sfx/guest_sad.wav | 먹을 게 없어 손님이 아쉬워하며 돌아갈 때 "띵~동" 내려가는 두 음 (guest_sad) | Freesound 331047 (위 kalimba 와 같은 원본)의 음 높이를 바꾼 두 음. 벌칙 느낌이 안 나게 작고 부드럽게 | **CC0** | 2026-10-07 |
| sfx/morning_birds.wav | 맑은 날 아침 텃밭에 그날 처음 나왔을 때 새소리 한 번 (morning_birds) | Freesound "Birds In Spring (Scotland)" by BurghRecords — https://freesound.org/s/463903/ | **CC0** | 2026-10-07 |

- mix_toss 조각은 원본(8.5초, audio_source/potato_salad.wav)에서 촉촉하게 섞는 0.53·2.75·3.40·4.78·5.32초 부분을 0.35~0.55초씩 자른 것.
  숟가락이 그릇에 부딪힌 듯한 큰 소리(2.50·4.40초)는 뺐다.
- loop_sizzle 은 원본 0.5~7.5초, loop_rice_boil 은 원본 53~60초를 6초 길이로 자르고, 끝 1초를 처음과 겹쳐 되풀이해도 이음매가 안 들리게 한 것.
- kalimba_ready 는 칼림바 "도" 한 음을 1초로 줄인 것, kalimba_go 는 같은 음을 다섯 음 올린 "솔"(0.9초).
- happy_beeps_perfect 는 징글(3.5초) 중 소리가 나는 앞 2.5초만 쓰고 끝을 부드럽게 줄인 것. (나무 실로폰 가락은 들어 보고 뺐다)
- phone_buzz 두 개는 원본 미리 듣기 파일(9.9초, audio_source/phone_vibrate_wood.mp3 → .wav)에서 0.6초짜리 진동 "부르르"가 나는 0.98초·8.78초부터 0.68초씩 자른 것.
  긴 진동(1초 넘는 것)과 아주 짧은 진동은 뺐다. 말풍선마다 한 번씩 나서 짧은 것을 골랐다.
- dish_slide 세 개는 원본 미리 듣기 파일(12.6초, audio_source/plate_slide_counter.mp3 → .wav)의 미끄러짐 여덟 번 중, 시작이 "탁" 하고 세게 부딪히지 않고
  부드러운 5.52·8.67·10.22초부터 0.73~0.88초씩 자른 것. 시작이 찌그러질 만큼 큰(최고 0dB) 세 번은 뺐다.
- zone_secret 은 칼림바 "도"를 네 반음·아홉 반음 올린 "미→라", zone_request 는 일곱·열두 반음 올린 "솔→도"를 0.09초 간격으로 겹친 것 (0.6초).
  guest_sad 는 두 반음 올린 "레"에서 세 반음 내린 "라"로 0.24초 뒤 내려가는 것 (1.2초). 음 높이는 원본을 빠르게·느리게 읽어서 바꿨다.
- 새 소리 다섯 가지는 바꾸기 전 임시 소리와 소리 나는 부분의 평균 크기를 같게 맞춰서, 소리 데이터의 Volume Db 는 그대로 두었다.
- porch_crickets_loop 는 원본 미리 듣기 파일(3분 40초, audio_source/night_crickets_porch.mp3 → .wav, 아주 작게 녹음됨)의 60~92초를 22dB 키우고,
  끝 2초를 처음과 겹쳐 30초가 이음매 없이 되풀이되게 한 것. 평균 -30dB로 빗소리(-22dB)보다 작다. 원본 전체가 고르고 갑자기 커지는 잡음이 없다.
- morning_birds 는 원본 미리 듣기 파일(2분 28초, audio_source/birds_in_spring.mp3 → .wav)에서 새가 활발한 25~30.5초를 잘라 최고점 -6dB로 맞추고,
  앞 0.3초·뒤 1.5초를 서서히 키우고 줄인 것. 뒤에 강물 소리가 낮게 깔려 있다.
- 두 소리는 Freesound 원본(로그인 필요) 대신 로그인 없이 받는 고음질 미리 듣기 mp3(128kbps)에서 만들었다. 더 좋은 음질이 필요하면 원본을 받아 같은 구간을 다시 자르면 된다.
- rain_light_loop 는 원본(95초, audio_source/rain_light.wav, 아주 작게 녹음됨)의 34~66초를 30초로 자르고 끝 2초를 처음과 겹쳐 되풀이해도 이음매가 안 들리게 한 것. 소리를 36배 키웠다.
- item_pop 은 0.07초짜리 게임용 "뽁" 소리 세 가지를 그대로 쓴다 (번갈아 나온다).
- plant_soil 조각은 원본(4.8초, audio_source/planting_seeds.wav)에 1초 간격으로 들어 있는 심기 소리 다섯 개를 0.35초씩 나눈 것.
- harvest_pull 조각은 원본(24.7초, audio_source/pull_plant.wav)에서 풀이 바스락하는 13.8·17.2·19.6·22.5초부터 0.6초씩 자른 것.
  유난히 크고 둔탁한 11.96초(흙을 터는 쿵 소리)는 뺐다.
- simmer_bubble 조각은 원본(1분 43초, audio_source/simmering_pot.aiff → .wav)에서 걸쭉한 거품이 터지는 15.4·18.2·84.1·97.2초부터
  0.5초씩 자른 것. 소리가 날카로운 78.6·89.3초(숟가락이 냄비에 부딪힌 듯한 소리)는 뺐다.
- rice_wash 조각은 원본(40.4초, audio_source/rice_washing.wav)에서 물을 휘젓는 4.0·18.5·31.6·33.1초부터 0.6초씩 자른 것.
  Freesound 에 쌀 씻는 녹음이 거의 없어서 부엌 싱크대 물 휘젓기 소리로 대신했다.
- pan_flip 조각은 원본(55.5초, audio_source/pancake_flip.wav)에서 뒤집는 "착" 소리가 나는 14.0·27.2·32.6초부터 0.9초씩 자른 것.
- sizzle 조각은 원본(1분 6초)에서 툭 튀는 소리(주걱이 팬에 부딪힘) 없이 지글지글 고르게 이어지는 14.3·35.0·6.0·10.3초 부분을 잘라
  모노 16비트로 만든 것. 서로 다르게 들리게 1 짧고 바삭한 "칙"(0.45초), 2 보통 "치익"(0.7초), 3 긴 "치이이익"(0.95초), 4 부드러운 "쏴아"(0.8초)로 다듬었다.
  원본은 `audio_source/`(Godot 와 Git 에서 빠짐)에 있어서 다른 부분을 다시 잘라 쓸 수 있다.
- 썰기 소리(chop_*)는 ElevenLabs mp3 의 크기가 조각마다 20dB 넘게 달라서, 모두 같은 크기(가장 큰 부분 -16dB, 최고점 -1dB 이하)로 맞춘 wav 로 바꿨다. 원본 mp3 는 audio_source/chop_mp3/ 에 있다.
- 썰기 소리 고르는 순서: 요리 단계의 Hit Sound → 재료의 Chop Sound → 썰기 기본 소리(hit_chop, Kenney).
- ElevenLabs 무료 요금제로 만든 소리는 상업적으로 쓸 수 없다.

## 그대로 써도 괜찮은 것
| id | 언제 |
|---|---|
| click | 모든 버튼 (저절로 남) |
| hit | 미니게임에 따로 정한 소리가 없을 때 쓰는 공통 소리 |
| hit_chop | 썰기 (칼질) |
| hit_mince | 다지기 (탁탁) |
| hit_plate | 담기 |
| hit_roll | 말기 (천 소리) |
| miss | 빗나감 (작고 부드럽게, 벌칙 느낌이 안 나게) |
| done, grandma_taste | 미니게임 완성 / 할머니 손맛 |
| guest_arrive | 손님이 올 때 (문 여는 소리) |
| serve | 대접할 때 (접시 내려놓기) |
| pop, tier_up | 손님 위로 뜨는 글 / 단골 단계가 오를 때 |
| book | 손님 수첩 펼치기 |
| note_page, secret, gift | 평상: 레시피 노트 / 할머니 비법 / 단골 선물 |
| special_day | 특별한 점심 날(소풍, 생일, 아무거나)에 부엌이 열릴 때 (Kenney jingles_PIZZI04) |
| door_close | 가게 문이 다 닫힐 때 작은 "툭" (Kenney impactSoft_medium 세 개 번갈아) |
| miss (메뉴판) | 메뉴판에서 장사를 시작할 수 없을 때 (재료 부족, 아무것도 안 고름). 장터의 "재료 부족"과 같은 소리 |
| result_line, shop_up | 장사 결과판 줄이 나올 때 / 가게 이름이 바뀔 때 |

## 미니게임마다 맞히는 소리
미니게임은 맞힐 때 `hit_` + 미니게임 종류 소리를 찾는다 (chop, stir_fry, plate, pan_fry, roll, cook_rice, mix, simmer, mince).
새 미니게임을 만들면 `data/sounds/hit_<종류>.tres` 만 추가하면 된다. 없으면 `hit` 소리를 쓴다.

## 미니게임 동안 계속 깔리는 소리
미니게임은 하는 동안 `loop_` + 미니게임 종류 소리를 되풀이해서 깐다 (없으면 안 깐다). 지금은 둘:
- loop_stir_fry: 볶기 "시작!"부터 완성까지 지글지글
- loop_cook_rice: 밥 짓기 ② 불 조절 동안 보글보글. 불이 셀수록 커진다 (rice_minigame 의 Boil Quiet Db / Boil Loud Db)
새로 깔고 싶으면 `data/sounds/loop_<종류>.tres` 만 추가하면 된다. 일시 정지하면 같이 멈춘다.

봄비 오는 날에는 낮 장면(텃밭, 버섯 원목, 장터, 부엌) 내내 빗소리 `rain` 이 배경음악 아래에 깔리고, 해 지는 장면에서 서서히 꺼진다.
소리 크기는 `data/sounds/rain.tres` 의 Volume Db (지금 -8).

풀벌레 소리 `porch_night` 는 해 질 녘 장면에서 2.5초 동안 서서히 커지며 깔리기 시작해(kitchen 의 Evening Sound Fade In) 저녁 평상 내내 이어지고(크기 -6),
평상을 떠나면 1.5초 동안 서서히 꺼진다 (porch 의 Night Sound Fade). 계절 잔치로 가는 날의 해 질 녘에는 깔지 않는다. 처음 화면으로 나가면 꺼진다.
맑은 날 아침 텃밭에 그날 처음 나오면 새소리 `morning_birds` 가 한 번 난다(크기 -8). 장터·버섯 원목에서 돌아올 때는 다시 나지 않는다.
빗소리, 풀벌레, 새소리는 모두 "Weather" 버스로 보내서 설정 창의 **자연 소리** 막대로 함께 조절한다.

### 소리가 비어 있던 순간 (2026-10-07 점검)
2026-10-07 점검에서 찾은 빈 곳 7개(저녁 평상, 해 질 녘, 아침, 특별한 날, 손님이 그냥 돌아갈 때, 메뉴판 막힘, 문 닫힘)를 모두 채웠다.

## 배경음악
봄 낮·저녁 장면(텃밭, 버섯 원목, 부엌, 평상)은 날마다 곡이 바뀐다: data/music/spring_daily_music.tres 의 Tracks 를 1일째부터 차례로, 하루 동안은 한 곡. 곡을 더하려면 Tracks 칸에 넣기만 하면 된다.
봄비 오는 날 낮 장면은 봄비 곡(spring_rain.mp3), 비가 그친 저녁 평상은 그날 곡. 장터와 봄 잔치는 언제나 각자 곡.
장면마다 인스펙터의 **Music** 칸에 곡을 넣는다 (타이틀, 프롤로그, 텃밭, 버섯 원목, 장터, 부엌, 평상, 봄 잔치).
비어 있으면 앞 장면 음악이 서서히 꺼진다. 같은 곡이면 끊기지 않고 이어진다. 곡은 끝나면 처음부터 다시 튼다.
파일은 `assets/audio/music/` 에 영어 이름으로 넣는다.

### 음악 출처 기록 (출시 전에 권리를 꼭 다시 확인)
| 파일 | 쓰는 곳 | 만든 곳 | 요금제 / 권리 | 만든 날 | 프롬프트 |
|---|---|---|---|---|---|
| spring_theme.mp3 | 봄 곡 1 (1·4·7·10·13일째) | Suno AI | Pro 구독 중 생성 → 상업적 이용 가능 (Suno 약관 기준, 출시 전 다시 확인) | 2026-10-03 | (직접 적기) |
| spring_theme2.mp3 | 봄 곡 2 (2·5·8·11·14일째). 원래 이름 Lunchtime Kitchen | Suno AI (v6) | Pro | 2026-10-04 | japanese anime slice of life soundtrack, bright spring lunchtime in a cozy little countryside kitchen, busy but relaxed cooking, bouncy ukulele and light piano, playful clarinet and bassoon melody, soft pizzicato strings, gentle shaker and light hand percussion, fresh warm and cheerful, bright major key, 108 BPM, loopable video game background music / 제외: vocals, singing, EDM, rock, heavy drums, sad, melancholic, minor key, dramatic |
| spring_theme3.mp3 | 봄 곡 3 (3·6·9·12·15일째). 원래 이름 Morning Garden | Suno AI (v6) | Pro | 2026-10-04 | japanese anime slice of life soundtrack, fresh breezy spring morning in a countryside vegetable garden, sunlight and gentle wind, light acoustic guitar and bright piano, airy flute-like recorder melody, soft pizzicato strings, birdsong mood, clean and refreshing, hopeful and cheerful, bright major key, 100 BPM, loopable video game background music / 제외: vocals, singing, drums, EDM, rock, sad, melancholic, minor key, dramatic |
| spring_rain.mp3 | 봄비 오는 날 낮 (텃밭, 버섯 원목, 부엌). data/weather/rain_settings.tres 의 Rain Music. 원래 이름 Spring Rain Day | Suno AI (v6) | Pro | 2026-10-04 | japanese anime slice of life soundtrack, cozy rainy spring day inside a warm countryside kitchen, soft gentle piano and warm nylon guitar, light pizzicato strings like raindrops, soft clarinet melody, calm comforting and peaceful, quietly happy, warm and snug, gentle dynamics, bright major key, 84 BPM, loopable video game background music / 제외: vocals, singing, rain sound effects, thunder, drums, EDM, rock, sad, melancholic, minor key, dramatic, dark |
| forest_market.mp3 | 숲속 장터 (장날) | Suno AI (v6) | Pro | 2026-10-04 | cozy acoustic folk instrumental, cheerful bustling village market, bouncy ukulele and pizzicato strings, playful clarinet melody, light woodblock and shaker, warm accordion, lighthearted and friendly, diatonic major key, 110 BPM, loopable video game background music / 제외: vocals, singing, EDM, heavy drums, electric guitar, sad, dark |
| spring_feast_night.mp3 | 봄 잔치 (15일째 저녁) | Suno AI (v6) | Pro | 2026-10-04 | japanese anime slice of life soundtrack, warm and joyful evening celebration, friends smiling around a table in a cozy countryside garden as warm lights come on, light acoustic guitar strumming and bright piano, playful pizzicato strings, cheerful clarinet melody, soft shaker and gentle hand percussion, relaxed and happy, calm but festive, bright major key, 88 BPM, loopable video game background music / 제외: vocals, singing, sad, melancholic, wistful, nostalgic, minor key, dramatic, loud drums, EDM, rock |

- Suno 무료 요금제로 만든 곡은 상업적으로 쓸 수 없고, 나중에 유료로 바꿔도 소급되지 않는다.
- 스팀 등록 때 "AI로 만든 콘텐츠"(배경음악)를 밝힌다.

### 아직 없는 곡
타이틀 (직접 만들 예정), 프롤로그. 아래는 2026-10-07에 준비한 Suno 프롬프트 (Instrumental 켜기). 곡을 만들면 영어 이름으로
`assets/audio/music/` 에 넣고 알려 주면 장면의 Music 칸에 연결한다.

**처음 화면 곡** → `title_theme.mp3` (scenes/ui/title.tscn 의 Music)
- 프롬프트: japanese anime slice of life soundtrack, warm and welcoming title screen theme for a cozy cooking game, a small grandmother's kitchen at the edge of a spring forest in soft morning light, gentle acoustic guitar fingerpicking and soft piano, tender clarinet melody, light pizzicato strings, delicate music box sparkles, homey and heartwarming, peaceful and inviting, diatonic major key, 92 BPM, loopable video game background music
- 제외: vocals, singing, drums, EDM, rock, electric guitar, sad, minor key, dramatic, epic, orchestral swell

**프롤로그 곡** → `story_theme.mp3` (scenes/story/prologue.tscn 의 Music). 프롤로그, 밤의 할머니 회상, 계절 시작 이야기에 모두 나온다 (StoryScene 이 같은 장면을 쓴다)
- 바라는 느낌 (2026-10-07 사용자): 감동 쪽으로 너무 가지 않고, 이야기 글에 몰입하는 걸 방해하지 않는 잔잔한 배경. 할머니가 돌아가셨으니 아주 약간의 슬픔.
- 프롬프트: japanese anime slice of life soundtrack, understated background music for reading a quiet story, unobtrusive and restrained, sparse soft piano with light warm strings and a little acoustic guitar, calm and reflective, a faint touch of wistful sadness, gently nostalgic but not sentimental, simple repeating melody that stays in the background, diatonic major key with a few soft minor chords, 72 BPM, loopable video game background music
- 제외: vocals, singing, drums, EDM, rock, electric guitar, sentimental, emotional climax, swelling strings, choir, dramatic, epic, dark, scary, heavy
프롬프트 쓸 때: 동양 전통 악기나 '등불 축제' 같은 말은 넣지 않는다 (중국풍으로 나옴). 제외 칸에도 그런 단어는 넣지 않는다. 장면마다 다른 곡을 원하면 그 장면의 Music 칸만 바꾸면 된다 (점심 부엌 2~3곡 돌려 틀기도 생각 중).
