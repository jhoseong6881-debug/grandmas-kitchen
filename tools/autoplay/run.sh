#!/bin/zsh
# 봄 한 철 자동 플레이. 진짜 프로젝트를 시험용 사본으로 복사하고, 사본의 저장 폴더를 바꾼 뒤 봇을 오토로드로 붙여 돌린다.
# 진짜 세이브(Godot/app_userdata/grandmas-kitchen)는 건드리지 않는다.
#
# 쓰는 법 (프로젝트 루트에서):
#   tools/autoplay/run.sh bot [판 수] [할머니 손맛 확률]   화면을 직접 눌러 끝까지 (기본 4판, 0.7)
#   tools/autoplay/run.sh pad [판 수]                      게임패드 입력만으로 끝까지 (기본 1판)
# 기록은 $AUTOPLAY_DIR/logs/ 에 남는다 (기본 /tmp/grandmas-kitchen-autoplay).
set -e
MODE=${1:-bot}
RUNS=${2:-$([[ $MODE == pad ]] && echo 1 || echo 4)}
CHANCE=${3:-0.7}
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
WORK=${AUTOPLAY_DIR:-/tmp/grandmas-kitchen-autoplay}
COPY=$WORK/copy
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
TEST_DIR_NAME="Godot/app_userdata/gk-autoplay-test"

case $MODE in
	bot) DRIVER=bot_driver.gd ;;
	pad) DRIVER=pad_driver.gd ;;
	*) echo "bot 또는 pad 를 적어 주세요"; exit 1 ;;
esac

mkdir -p "$WORK/logs" "$COPY"
# .godot 는 읽어서 복사만 한다 (가져오기 시간을 줄이려고). build·audio_source 는 필요 없다.
rsync -a --delete --exclude build --exclude audio_source --exclude .git --exclude autoplay "$ROOT/" "$COPY/"
mkdir -p "$COPY/autoplay"
cp "$ROOT/tools/autoplay/"*.gd "$COPY/autoplay/"

# 사본의 저장 폴더를 시험용으로 바꾸고, 봇을 오토로드 맨 끝에 붙인다.
sed -i '' -e "s|^config/custom_user_dir_name=.*|config/custom_user_dir_name=\"$TEST_DIR_NAME\"|" "$COPY/project.godot"
if ! grep -q "^config/custom_user_dir_name=\"$TEST_DIR_NAME\"" "$COPY/project.godot"; then
	echo "!! 사본의 저장 폴더를 바꾸지 못해 멈춥니다 (진짜 세이브를 지키려고)"; exit 1
fi
python3 - "$COPY/project.godot" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
line = 'AutoplayDriver="*res://autoplay/driver.gd"\n'
s = re.sub(r'(\[autoload\]\n\n(?:[^\[\n].*\n)*)', lambda m: m.group(1).rstrip("\n") + "\n" + line + "\n", s, count=1)
open(p, "w", encoding="utf-8").write(s)
PY
cp "$COPY/autoplay/$DRIVER" "$COPY/autoplay/driver.gd"
grep -q 'AutoplayDriver=' "$COPY/project.godot" || { echo "!! 오토로드를 붙이지 못했습니다"; exit 1; }

"$GODOT" --headless --path "$COPY" --import > "$WORK/logs/import.log" 2>&1 || true
# 봇 스크립트에 문법 오류가 있으면 봇 없이 게임만 끝없이 켜져 있게 되므로 먼저 검사한다 (오토로드 이름을 모르는 오류는 여기선 정상이라 문법 오류만 본다).
if "$GODOT" --headless --path "$COPY" --check-only --script "res://autoplay/driver.gd" 2>&1 | grep "Parse Error"; then
	echo "!! 봇 스크립트 문법 오류 — 멈춥니다"; exit 1
fi

STAMP=$(date +%m%d_%H%M)
for i in $(seq 1 $RUNS); do
	LOG="$WORK/logs/${MODE}_${STAMP}_$i.txt"
	echo "== $MODE $i/$RUNS (시드 $i) → $LOG"
	# 한 판이 50분을 넘으면 끊는다 (봇의 45분 시간 초과 기록이 먼저 남는다).
	perl -e 'alarm shift; exec @ARGV' 3000 "$GODOT" --headless --path "$COPY" ++ "$LOG" "$i" "$CHANCE" > "$WORK/logs/${MODE}_${STAMP}_${i}_out.txt" 2>&1 || true
	grep -E "SCRIPT ERROR|^ERROR" "$WORK/logs/${MODE}_${STAMP}_${i}_out.txt" | sort | uniq -c | head -10 || true
	[[ -f $LOG ]] && grep -E "^!!|  !!|끝까지 감|타이틀로 돌아옴|여름 1일째|시간 초과" "$LOG" | head -20 || echo "!! 기록 파일이 없음 (봇이 끝까지 못 감)"
done
