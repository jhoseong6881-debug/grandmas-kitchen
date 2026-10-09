#!/bin/zsh
# 빠른 검사 (1~2분): 시험용 사본을 만들어 스크립트·장면·데이터 파일이 모두 열리는지 본다.
# 진짜 프로젝트의 .godot/ 와 진짜 세이브는 건드리지 않는다 (사본의 저장 폴더를 gk-check-test 로 바꾼다).
#
# 쓰는 법 (프로젝트 루트에서):  tools/check/run.sh
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
exit $CODE
