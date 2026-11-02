#!/bin/bash
# Usage: run.sh <udid> <derivedDataPath> <only-testing> [seed-state]
#   only-testing  e.g. QuickStudyUITests/SmokeTests or QuickStudyUITests/SmokeTests/testEverySeedStateLaunchesWithContent
#   seed-state    a Scripts/seed.sh state, applied before the run (files + defaults)
# Builds for testing once (when no .xctestrun exists in <derivedDataPath>), then always runs
# test-without-building. Set QS_REBUILD=1 to force a rebuild after changing app or test sources.
# Env: QS_RECORD_VIDEO=<name> records the whole run to <evidence>/<name>.mp4 with simctl io recordVideo.
#      QS_EVIDENCE_DIR (optional) writes screenshots/hierarchies straight into that directory.
#      QS_EVIDENCE_ROOT (default: <derivedDataPath>/../e2e/run) receives screenshots,
#      hierarchies, the xcresult bundle and the app log, in a timestamped folder.
set -euo pipefail

UDID="${1:?usage: run.sh <udid> <derivedDataPath> <only-testing> [seed-state]}"
DERIVED="${2:?}"
ONLY="${3:?}"
SEED="${4:-}"

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$HERE/../.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
EVIDENCE_ROOT="${QS_EVIDENCE_ROOT:-$(cd "$DERIVED/.." && pwd)/e2e/run}"
OUT="$EVIDENCE_ROOT/$STAMP-$(echo "$ONLY" | tr '/' '_')"
EVIDENCE="${QS_EVIDENCE_DIR:-$OUT/evidence}"
mkdir -p "$OUT" "$EVIDENCE"

cd "$PROJECT_DIR"

XCTESTRUN="$(ls "$DERIVED"/Build/Products/*.xctestrun 2>/dev/null | head -1 || true)"
if [ -z "$XCTESTRUN" ] || [ "${QS_REBUILD:-0}" = "1" ]; then
  xcodebuild build-for-testing -project QuickStudy.xcodeproj -scheme QuickStudyUITests \
    -destination "id=$UDID" -derivedDataPath "$DERIVED" > "$OUT/build.log" 2>&1 \
    || { tail -30 "$OUT/build.log"; echo "build failed: $OUT/build.log" >&2; exit 1; }
  XCTESTRUN="$(ls "$DERIVED"/Build/Products/*.xctestrun | head -1)"
fi

if [ -n "$SEED" ]; then
  "$HERE/seed.sh" "$UDID" "$SEED" > "$OUT/seed.log"
fi

xcrun simctl spawn "$UDID" log stream --style compact --level debug \
  --predicate 'process == "QuickStudy"' > "$OUT/app.log" 2>&1 &
LOG_PID=$!
trap 'kill $LOG_PID 2>/dev/null || true' EXIT

if [ -n "${QS_RECORD_VIDEO:-}" ]; then
  xcrun simctl io "$UDID" recordVideo --codec h264 --force "$EVIDENCE/$QS_RECORD_VIDEO.mp4" > "$OUT/video.log" 2>&1 &
  VIDEO_PID=$!
fi

set +e
TEST_RUNNER_QS_EVIDENCE_DIR="$EVIDENCE" TEST_RUNNER_QS_SEEDED_STATE="$SEED" \
TEST_RUNNER_QS_SMOKE_ONLY="${QS_SMOKE_ONLY:-}" \
xcodebuild test-without-building -xctestrun "$XCTESTRUN" -collect-test-diagnostics never \
  -destination "id=$UDID" -only-testing:"$ONLY" \
  -resultBundlePath "$OUT/result.xcresult" > "$OUT/test.log" 2>&1 &
XCODEBUILD_PID=$!
# xcodebuild occasionally hangs after a failed UI test; QS_TEST_TIMEOUT (seconds) kills it.
( sleep "${QS_TEST_TIMEOUT:-600}"; kill $XCODEBUILD_PID 2>/dev/null ) </dev/null >/dev/null 2>&1 &
WATCHDOG_PID=$!
wait $XCODEBUILD_PID
STATUS=$?
pkill -P $WATCHDOG_PID 2>/dev/null
kill $WATCHDOG_PID 2>/dev/null
set -e

kill $LOG_PID 2>/dev/null || true
grep -E "Test Case .*(passed|failed)|Test Suite .*(passed|failed)|error:|\*\* TEST" "$OUT/test.log" | tail -40 || true
echo "exit status: $STATUS"
echo "output:   $OUT"
echo "evidence: $EVIDENCE"
echo "app log:  $OUT/app.log"
echo "xcresult: $OUT/result.xcresult"
exit $STATUS
