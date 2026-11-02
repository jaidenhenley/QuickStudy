#!/bin/bash
# Usage: seed.sh <udid> <state>
# Terminates QuickStudy, wipes its Documents and UserDefaults, then applies <state> by copying
# app-generated fixture files into the data container and writing defaults with simctl.
# States: clean freshInstall onboardedEmpty demoData midDraft userSet sessions allowanceSpent
#         hostedConsentDeclined freeHostedSpent proActive noAppleIntelligence
# Unlike the launch-argument seeding in SeedState.swift, defaults written here are real values
# the app can overwrite, but they persist until the next seed.sh run. Does not touch the Keychain.
set -euo pipefail

UDID="${1:?usage: seed.sh <udid> <state>}"
STATE="${2:?usage: seed.sh <udid> <state>}"
BUNDLE="com.henley.jaiden.QuickStudy"
HERE="$(cd "$(dirname "$0")" && pwd)"
FIXTURES="$HERE/../Fixtures/State"

# Written into the app container's plist, not the device-level domain: -QSResetInstall only
# clears the container, so device-level values would survive a "fresh install".
defaults_write() { xcrun simctl spawn "$UDID" defaults write "$PREFS" "$@"; }
month_stamp() { echo $(( $(date +%Y) * 12 + 10#$(date +%m) )); }

xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
CONTAINER="$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)"
DOCS="$CONTAINER/Documents"
PREFS="$CONTAINER/Library/Preferences/$BUNDLE"
mkdir -p "$DOCS" "$CONTAINER/Library/Preferences"
find "$DOCS" -mindepth 1 -delete
rm -f "$PREFS.plist"
xcrun simctl spawn "$UDID" defaults delete "$BUNDLE" >/dev/null 2>&1 || true
xcrun simctl privacy "$UDID" reset camera "$BUNDLE" >/dev/null 2>&1 || true
# The allowance count is mirrored into the Keychain and restored from it when defaults are empty.
xcrun simctl keychain "$UDID" reset >/dev/null 2>&1 || echo "keychain reset failed; allowance may carry over" >&2

onboarded() {
  defaults_write qs_hasCompletedOnboarding -bool true
  defaults_write qs_lastSeenRelease -int 999
}
# Fixture basenames are prefixed with their state because the test bundle flattens Fixtures/.
copy_fixture() { cp "$FIXTURES/$1/$1.$2" "$DOCS/$2"; }

case "$STATE" in
  clean|freshInstall) ;;
  onboardedEmpty|noAppleIntelligence|proActive) onboarded ;;
  demoData)
    onboarded
    defaults_write demoModeEnabled -bool true
    copy_fixture demoData SavedSets.json
    ;;
  midDraft)
    onboarded
    copy_fixture midDraft PendingDraft.json
    ;;
  userSet)
    onboarded
    copy_fixture userSet SavedSets.json
    ;;
  sessions)
    onboarded
    defaults_write demoModeEnabled -bool true
    python3 -I "$HERE/shift-dates.py" "$FIXTURES/sessions/sessions.Sessions.json" \
      "$FIXTURES/sessions/sessions.Sessions.json" "$DOCS/Sessions.json" \
      "$FIXTURES/sessions/sessions.SavedSets.json" "$DOCS/SavedSets.json"
    ;;
  allowanceSpent)
    onboarded
    defaults_write qs_aiGenerationsUsed -int 10
    defaults_write qs_aiGenerationsMonth -int "$(month_stamp)"
    ;;
  hostedConsentDeclined)
    onboarded
    defaults_write qs_hostedConsent -string declined
    defaults_write qs_hostedConsentVersion -int 3
    ;;
  freeHostedSpent)
    onboarded
    defaults_write qs_hostedFreeGenerationUsed -bool true
    ;;
  *)
    echo "unknown state: $STATE" >&2
    exit 2
    ;;
esac

echo "seeded $STATE into $CONTAINER"
ls -1 "$DOCS"
