---
name: release-build
description: 숲속의 할매식당 테스트 빌드 배포 — 사용자가 "빌드 만들어 줘/새 버전 내 줘"라고 할 때, 그리고 빌드 뒤 구글 드라이브 링크를 줬을 때 쓴다. 깨끗한 사본에서 Windows 내보내기 → zip → 빈 폴더에서 빌드 검사 → 패치노트·게임 파일 안내 정리·커밋 → (링크를 받으면) 디스코드에 올리기. Use when asked to make a test build/release, or when the user pastes the Drive link for a build.
---

# 빌드 배포 순서

사용자가 빌드를 부탁할 때만 만든다. 배포 방식(git push, 내보내기 설정)은 바꾸지 않는다.

## 0. 준비 확인

- `git status --short` 가 깨끗한지 본다. 커밋 안 된 게임 변경이 있으면 멈추고 사용자에게 묻는다 (빌드는 커밋된 HEAD 로 만든다).
- 마지막 게임 변경 뒤에 봇 검증을 했는지 본다. 안 했으면 verify-game 스킬로 먼저 검증한다.
- 버전: `grep -n "^# " docs/discord/patch-notes.md | tail -3` 으로 마지막 버전을 보고 0.7.x 의 x 를 하나 올린다 (0.8 로 부르지 않는다).

## 1. 문서 정리 (빌드 전에, 빌드에 들어가지 않는 docs 만)

1. `docs/discord/patch-notes.md` 맨 아래 `# 🔧 만드는 중 (빌드 전)` 칸을 `# <이모지> 0.7.x` + `-# <M월 D일>` 로 바꾸고, 끝에 `-# ✅ <실제로 한 검증> · 0.6~0.7.<x-1> 세이브는 그대로 이어져요` 줄을 단다 (실제로 한 검증만 적는다).
   - 메시지 하나는 2000자 이하. 넘으면 `(1/2)`, `(2/2)` 로 `---` 를 사이에 두고 나눈다.
   - 다음 빌드용 `# 🔧 만드는 중 (빌드 전)` 칸을 맨 아래에 새로 만든다.
2. `docs/discord/game-file-post.md` 의 버전 줄(`# 🎮 테스트 0.7.x · Windows`)과 세이브 이어 하기 줄(`0.6~0.7.<x-1>`)을 고친다. `(여기에 드라이브 링크)` 자리는 그대로 둔다.
3. 글자 수 확인과 txt 저장:
   ```bash
   python3 docs/discord/post_patchnote.py --version 0.7.x --dry-run
   python3 docs/discord/post_patchnote.py --version 0.7.x --save-txt
   ```
4. 커밋·푸시: `0.7.x 빌드 준비: ...` (Co-Authored-By 줄 포함).

## 2. 깨끗한 사본에서 내보내기

project.godot 은 **그대로** 둔다 (게임 이름 "숲속의 할매식당", 저장 폴더 grandmas-kitchen 고정). 이 사본에서는 세이브를 쓰거나 지우는 스크립트를 돌리지 않는다 — 가져오기·내보내기·읽기 검사만.

```bash
V=0.7.x
W=$(mktemp -d /tmp/gk-release-$V.XXXX)
G=/Applications/Godot.app/Contents/MacOS/Godot
mkdir -p $W/copy && git archive HEAD | tar -x -C $W/copy
cp assets/fonts/KyoboHandwriting/*.ttf $W/copy/assets/fonts/KyoboHandwriting/
$G --headless --path $W/copy --import > $W/import.log 2>&1
mkdir -p $W/copy/build/windows
$G --headless --path $W/copy --export-release "Windows Desktop" $W/copy/build/windows/GrannysKitchen.exe > $W/export.log 2>&1
grep -E "ERROR" $W/export.log | sort | uniq -c | head
(cd $W/copy/build/windows && zip -q -X "$W/숲속의 할매식당 테스트 $V.zip" GrannysKitchen.exe)
```
- 임시 폴더는 매번 mktemp 로 새로 만든다 (변수 경로에 rm -rf 를 쓰면 안전 검사에 막힌다).
- **교보 손글씨 .ttf 는 저장소에 없어서(.gitignore, 공개 저장소라 재배포 금지) git archive 에 빠진다. 위 cp 줄을 빼먹으면 제목·잔치 편지 글꼴이 깨진 빌드가 된다.**
- export.log 에 `ERROR` 줄이 하나라도 있으면 멈추고 원인을 본다 (글꼴이 빠지면 `KyoboHandwriting ... fontdata` 오류가 나온다).
- zip 안에는 GrannysKitchen.exe 하나만 든다 (pck 가 exe 안에 들어 있다, embed_pck). 0.7.13 기준 약 74~77MB.
- 3번 검사가 통과한 뒤에 `cp "$W/숲속의 할매식당 테스트 $V.zip" build/` 로 저장소의 build/(.gitignore)에 둔다.
- 맥판은 사용자가 원할 때만: `--export-release "macOS" $W/copy/build/macos/GrannysKitchen.app` → `ditto -c -k --keepParent`. 받은 사람에게 "그래도 열기" 안내가 필요하다.

## 3. 빌드 검사 — 반드시 project.godot 이 없는 빈 폴더에서

프로젝트 폴더 안에서 돌리면 빌드에 빠진 파일도 폴더에서 읽혀 "있음"으로 나온다.
```bash
mkdir -p $W/check/unzip $W/check/empty
(cd $W/check/unzip && unzip -q -o "$W/숲속의 할매식당 테스트 $V.zip")
(cd $W/check/empty && $G --headless --main-pack $W/check/unzip/GrannysKitchen.exe --script "$PWD/tools/check/load_all.gd")
```
`검사 통과` 가 나와야 한다. 파일 수는 사본 검사(tools/check/run.sh)보다 조금 적을 수 있다 (scenes/debug·scripts/debug 는 빌드에서 뺀다).
(2026-10-09 시험: 글꼴을 뺀 빌드는 export.log 오류 + 이 검사 실패로 잡혔고, 글꼴을 넣은 빌드는 통과했다.)

## 4. 사용자에게 넘기기

zip 위치(`build/숲속의 할매식당 테스트 0.7.x.zip`)와 크기를 알려 주고, 구글 드라이브에 올려 링크를 달라고 한다.

## 5. 링크를 받으면 — 묻지 않고 바로 (사용자가 정한 규칙)

1. 링크가 열리는지 확인한다 (내장 브라우저로 열어 보거나 `curl -sI <링크> | head -1`).
2. 📝패치노트에 버전 글을 올린다:
   ```bash
   python3 docs/discord/post_patchnote.py --version 0.7.x
   ```
3. 🎮게임-파일 안내 글은 **하나만 고쳐 쓴다** (새로 올리거나 지우지 않는다):
   ```bash
   python3 docs/discord/post_gamefile.py <드라이브 링크>
   ```
4. post_gamefile.py 가 바꾼 txt 가 있으면 커밋·푸시한다.

웹후크 주소는 스크립트가 알아서 읽는다. 주소를 화면에 찍거나 파일·메모리에 적지 않는다. 디스코드 메시지는 지우지 않는다.

## 보고 (한국어)

버전, zip 크기, 빌드 검사 결과(숫자), 올린 디스코드 글, 직접 확인하지 못한 것(실제 Windows·스팀덱에서 켜 보기는 사용자 몫)을 짧게 적는다.
