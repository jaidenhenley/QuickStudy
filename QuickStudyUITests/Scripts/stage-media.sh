#!/bin/bash
# Usage: stage-media.sh <udid>
# Puts Fixtures/Inputs/scanned-page.png into Photos, copies the PDFs and text fixtures into the
# Files app's "On My iPhone" storage, and grants the app photo access so the Photo path opens
# the picker without a prompt. Run once per simulator; safe to repeat (Photos gets a duplicate).
set -euo pipefail

UDID="${1:?usage: stage-media.sh <udid>}"
BUNDLE="com.henley.jaiden.QuickStudy"
HERE="$(cd "$(dirname "$0")" && pwd)"
INPUTS="$HERE/../Fixtures/Inputs"
DATA="$HOME/Library/Developer/CoreSimulator/Devices/$UDID/data"

xcrun simctl addmedia "$UDID" "$INPUTS/scanned-page.png"

LOCAL_STORAGE=""
for meta in "$DATA"/Containers/Shared/AppGroup/*/.com.apple.mobile_container_manager.metadata.plist; do
  if [ "$(plutil -extract MCMMetadataIdentifier raw "$meta" 2>/dev/null)" = "group.com.apple.FileProvider.LocalStorage" ]; then
    LOCAL_STORAGE="$(dirname "$meta")/File Provider Storage"
    break
  fi
done
[ -d "$LOCAL_STORAGE" ] || { echo "On My iPhone storage not found; boot the simulator and open Files once" >&2; exit 1; }

mkdir -p "$LOCAL_STORAGE/QuickStudy Fixtures"
cp "$INPUTS"/small.pdf "$INPUTS"/large.pdf "$INPUTS"/corrupt.pdf \
   "$INPUTS"/notes.txt "$INPUTS"/notes-short.txt "$INPUTS"/empty.txt "$LOCAL_STORAGE/QuickStudy Fixtures/"

xcrun simctl privacy "$UDID" grant photos "$BUNDLE" || echo "photos grant failed (app not installed yet?)" >&2

echo "Photos: scanned-page.png added"
echo "Files > On My iPhone > QuickStudy Fixtures:"
ls -1 "$LOCAL_STORAGE/QuickStudy Fixtures"
