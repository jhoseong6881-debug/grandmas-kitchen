#!/bin/zsh
# 빠른 검사 (1~2분): 시험용 사본을 만들어 스크립트·장면·데이터 파일이 모두 열리는지 본다.
# 진짜 프로젝트의 .godot/ 와 진짜 세이브는 건드리지 않는다 (사본의 저장 폴더를 gk-check-test 로 바꾼다).
#
# 쓰는 법 (프로젝트 루트에서):  tools/check/run.sh [시나리오 이름 ...]
#   시나리오 이름을 주면 불러오기 검사 뒤에 tools/check/scenarios/<이름>.gd 를 사본에 오토로드로 붙여 하나씩 돌린다.
# 기록은 $CHECK_DIR/ 에 남는다 (기본 /tmp/grandmas-kitchen-check).
set -e
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
WORK=${CHECK_DIR:-/tmp/grandmas-kitchen-check}
COPY=$WORK/copy
GODOT=${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}
TEST_DIR_NAME="Godot/app_userdata/gk-check-test"

mkdir -p "$COPY"
rsync -a --delete --exclude build --exclude audio_source --exclude .git --exclude .claude --exclude tools "$ROOT/" "$COPY/"
sed -i '' -e "s|^config/custom_user_dir_name=.*|config/custom_user_dir_name=\"$TEST_DIR_NAME\"|" "$COPY/project.godot"
if ! grep -q "^config/custom_user_dir_name=\"$TEST_DIR_NAME\"" "$COPY/project.godot"; then
	echo "!! 사본의 저장 폴더를 바꾸지 못해 멈춥니다 (진짜 세이브를 지키려고)"; exit 1
fi

"$GODOT" --headless --path "$COPY" --import > "$WORK/import.log" 2>&1 || true
set +e
"$GODOT" --headless --path "$COPY" --script "$ROOT/tools/check/load_all.gd" > "$WORK/check.log" 2>&1
CODE=$?
set -e
# 오류 줄만 모아 보여 준다 (같은 줄은 한 번만).
grep -E "SCRIPT ERROR|Parse Error|^ERROR|^ +at: " "$WORK/import.log" "$WORK/check.log" | sort | uniq -c | head -30 || true
grep -E "^!!|확인, 못 연 것|검사 통과" "$WORK/check.log" || echo "!! 검사 결과 줄이 없음 (기록: $WORK/check.log)"
[[ $CODE != 0 ]] && exit $CODE

# 시나리오 시험: 한 번에 하나씩 오토로드로 붙여 게임을 켜고, 스크립트가 끝 코드(실패 수)로 끝낸다.
for NAME in "$@"; do
	SRC="$ROOT/tools/check/scenarios/$NAME.gd"
	[[ -f $SRC ]] || { echo "!! 시나리오 없음: $NAME"; exit 1; }
	cp "$SRC" "$COPY/scenario_test.gd"
	cp "$COPY/project.godot" "$WORK/project.godot.orig"
	# 오토로드 맨 끝에 시험 스크립트를 붙인다 (GameState 등이 먼저 준비되게). 자동 플레이 도구와 같은 방법.
	python3 - "$COPY/project.godot" <<'PY2'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
line = 'ScenarioTest="*res://scenario_test.gd"\n'
s = re.sub(r'(\[autoload\]\n\n(?:[^\[\n].*\n)*)', lambda m: m.group(1).rstrip("\n") + "\n" + line + "\n", s, count=1)
open(p, "w", encoding="utf-8").write(s)
PY2
	grep -q 'ScenarioTest=' "$COPY/project.godot" || { echo "!! 시험 오토로드를 붙이지 못했습니다"; exit 1; }
	set +e
	perl -e 'alarm shift; exec @ARGV' 300 "$GODOT" --headless --path "$COPY" > "$WORK/scenario_$NAME.log" 2>&1
	SCODE=$?
	set -e
	mv "$WORK/project.godot.orig" "$COPY/project.godot"
	rm -f "$COPY/scenario_test.gd"
	echo "== 시나리오 $NAME"
	grep -E "^!!|SCRIPT ERROR|시험 끝" "$WORK/scenario_$NAME.log" || echo "!! 시험 결과 줄이 없음 (기록: $WORK/scenario_$NAME.log)"
	[[ $SCODE != 0 ]] && CODE=$SCODE
done
exit $CODE
