---
name: verify-game
description: 숲속의 할매식당 검증 — 코드·장면·데이터를 바꾼 뒤 커밋 전에, 또는 사용자가 "확인해 줘/검증해 줘/봇 돌려 줘"라고 할 때 쓴다. 빠른 불러오기 검사(수 초) → 바꾼 곳에 맞는 자동 플레이(bot/pad)·그림 검사 → 결과 요약. Use after changing game code/scenes/data, before committing, or when asked to verify/playtest.
---

# 게임 검증 순서

진짜 프로젝트 폴더에서 Godot 을 직접 켜지 않는다 (.godot/ 가 바뀐다). 아래 도구는 모두 시험용 사본을 만들고, 사본의 저장 폴더를 바꿔서 진짜 세이브를 지킨다.

## 1. 빠른 검사 — 항상

```bash
tools/check/run.sh
```
- 수 초 걸린다. 스크립트·장면·데이터(.tres) 파일이 모두 열리는지 본다. 마지막 줄이 `검사 통과` 이고 끝 코드가 0이면 통과.
- `!! 못 엶:` 줄과 그 위의 `SCRIPT ERROR` / `Parse Error` 줄이 원인이다. 기록은 /tmp/grandmas-kitchen-check/check.log.
- 잡는 것: 문법 오류, 타입 오류, 클래스(NotePuzzleBoard 등) 함수·변수 이름 틀림, 깨진 장면·리소스 경로.
- **못 잡는 것**: 오토로드(GameState·GameData·Sound) 함수 이름 틀림, 실행해야 드러나는 오류. 이런 건 2번의 봇으로 확인한다.
- 실패하면 고치고 다시 돌린다. 통과하기 전에는 2번으로 가지 않는다.

### 1-1. 시나리오 시험 (특정 상황을 직접 만들어 보는 시험, 1분 안쪽)

```bash
tools/check/run.sh menu_note_suggest
```
- `tools/check/scenarios/<이름>.gd` 를 사본에 오토로드로 붙여 돌린다. 끝 코드 = 실패 수, `!! 실패` 줄이 무엇이 틀렸는지.
- 봇이 하지 않는 행동(메뉴에서 요리 빼기, 뒤로 나가기, 옛 세이브 불러오기)을 확인할 때 새 시나리오를 만든다. 형식은 menu_note_suggest.gd 를 따른다 (`_ready` 에서 몇 프레임 기다린 뒤 시험, `check(조건, 설명)`, 끝에 `get_tree().quit(fails)`).
- 지금 있는 것: `menu_note_suggest` — 메뉴판이 번진 노트 요리를 권할 때 플레이어가 직접 뺀 것은 다시 안 넣는지 (menu_board.gd·GameState 메뉴/퍼즐 쪽을 바꾸면 돌린다).
  `chop_target` — 썰기는 하얀 칸 안에서만 썰리고 칸 밖은 톡 치기만 하는지, 칸 안에서 다 썰면 끝나는지 (chop_minigame 을 바꾸면 돌린다).
  `rice_water` — 밥 짓기 물 맞추기: 넘치면 따라 내고 다시, 모자라면 기다림, 알맞으면 불 조절로 (rice_minigame 을 바꾸면 돌린다).
  `rice_fire` — 밥 짓기 불 조절(가마솥 3단 불): 센불 → 뚜껑 두 번 들썩 → 중불 → 약불 뜸, 안 맞는 불은 진행만 멈춤.
  `logs_tip` — 버섯 원목이 열린 뒤 첫 아침에 토끼 원목 안내가 한 번만, 텃밭 첫 안내와 겹치지 않고 나오는지 (garden.gd·처음 안내를 바꾸면 돌린다).
  `village_visit` — 아침 마을 길: 2일째 열림, 못 만난 손님 집 "?", 하루 한 집, 선물 단골도, 방문 횟수 세이브·옛 세이브 (village.gd·마을 길 데이터를 바꾸면 돌린다).
  시나리오는 끝 코드가 0 이어도 게임 쪽 `SCRIPT ERROR` 는 못 센다 → `grep SCRIPT /tmp/grandmas-kitchen-check/scenario_<이름>.log` 도 본다.

## 2. 바꾼 곳에 맞는 검사

| 바꾼 것 | 돌릴 것 |
|---|---|
| 글자·색·주석만 | 1번으로 충분 |
| 하루 흐름·부엌·텃밭·평상·장터·GameState·세이브·레시피·손님 데이터 | `tools/autoplay/run.sh bot 1` (비교가 필요하면 `bot 3`) |
| 미니게임·입력·포커스·메뉴 이동 | `tools/autoplay/run.sh pad 1` |
| 그림 파일·그림 연결 | `python3 tools/check_art.py` |

- 봇 한 판은 약 35~40분이다. **Bash 의 run_in_background 로 돌리고**, 기다리는 동안 sleep 으로 확인하지 않는다 (끝나면 알림이 온다).
- 시드는 판 번호(1, 2, 3…)라서 같은 판 수로 다시 돌리면 고치기 전과 비교할 수 있다. 비교할 숫자(예: 노트 퍼즐 개수)는 고치기 전 결과를 먼저 적어 둔다.
- 미니게임을 바꿨으면 `tools/autoplay/pad_driver.gd` 의 `_drive()` 에서 그 미니게임 칸도 같이 맞춘다 (미니게임 안의 변수 이름을 직접 읽는다).
- 봇 기록: /tmp/grandmas-kitchen-autoplay/logs/ 의 `bot_<날짜>_<판>.txt` (봇이 남긴 하루별 요약)와 `_out.txt` (Godot 출력).

## 3. 결과 읽기

```bash
grep -E "^!!|  !!|끝까지 감|시간 초과|노트 퍼즐" /tmp/grandmas-kitchen-autoplay/logs/bot_<날짜>_1.txt | head -40
grep -E "SCRIPT ERROR|^ERROR" /tmp/grandmas-kitchen-autoplay/logs/bot_<날짜>_1_out.txt | sort | uniq -c
```
- `끝까지 감` 이 있으면 봄 15일을 끝까지 갔다. `!!` 줄은 봇이 찾은 문제다.
- `ERROR: 1 resources still in use at exit` 는 게임을 끌 때 나오는 일반 경고라 문제가 아니다.
- 긴 기록을 통째로 읽지 말고 grep·tail 로 필요한 줄만 본다.

## 4. 보고 (한국어)

CLAUDE.md 의 "작업 완료 후" 형식으로 짧게 적는다.
- 실제로 돌린 검사와 결과 (숫자 그대로. 돌리지 않은 것을 "통과"라고 쓰지 않는다)
- 직접 실행하지 못한 것: 화면 배치·글자 넘침·색은 봇이 보지 못한다 → 사용자가 Godot 에서 F5 로 볼 곳을 순서대로 알려 준다
- 검증이 통과하면 기억 노트의 규칙대로 커밋·푸시하고 짧은 패치노트를 올린다 (`python3 docs/discord/post_patchnote.py --file <글>`). 실패했거나 덜 확인된 것은 올리지 않고 그 사실을 알린다.
