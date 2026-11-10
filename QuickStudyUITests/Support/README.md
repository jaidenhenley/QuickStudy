# QuickStudyUITests

UI test target for QuickStudy. Tests drive the real app on one shared simulator, **QS-P1 `90A4E5EA-CE24-454B-BE53-86663760BF18`** (iPhone 18 Pro, iOS 27.0). Never boot a second simulator.

The target uses a synchronized folder: add `.swift` files under `QuickStudyUITests/` and they are built; never edit the project file.

## Running

Build once (the first `run.sh` does this when no `.xctestrun` exists), then run with `test-without-building`:

```sh
SP=/private/tmp/claude-502/-Users-jaidenhenley-Desktop-CurrentProjects-QuickStudy/b0f8ee1b-1e98-4337-9132-b6d97ca0a974/scratchpad
UDID=90A4E5EA-CE24-454B-BE53-86663760BF18

# one-off build (only after app or test source changes; run.sh does it when QS_REBUILD=1)
xcodebuild build-for-testing -project QuickStudy.xcodeproj -scheme QuickStudyUITests \
  -destination "id=$UDID" -derivedDataPath $SP/dd-p1

# the exact test-without-building command run.sh issues
TEST_RUNNER_QS_EVIDENCE_DIR=$SP/e2e/run \
xcodebuild test-without-building \
  -xctestrun $SP/dd-p1/Build/Products/QuickStudyUITests_QuickStudyUITests_iphonesimulator27.1-arm64.xctestrun \
  -destination "id=$UDID" -only-testing:QuickStudyUITests/E2EScriptTests/test_WS_5 \
  -collect-test-diagnostics never -resultBundlePath $SP/e2e/p1/result.xcresult

# preferred: seeds, logs the app, records evidence, has a watchdog
QS_EVIDENCE_DIR=$SP/e2e/run QS_EVIDENCE_ROOT=$SP/e2e/p1 \
  QuickStudyUITests/Scripts/run.sh $UDID $SP/dd-p1 QuickStudyUITests/E2EScriptTests/test_WS_5 midDraft
```

`run.sh <udid> <derivedData> <only-testing> [seed-state]` environment:

| Variable | Effect |
|---|---|
| `QS_REBUILD=1` | build-for-testing first |
| `QS_EVIDENCE_DIR` | screenshots, hierarchies and notes go straight into this folder (default: `<out>/evidence`) |
| `QS_EVIDENCE_ROOT` | where the timestamped run folder (`test.log`, `app.log`, `result.xcresult`) is created |
| `QS_RECORD_VIDEO=<name>` | records the whole run to `<evidence>/<name>.mp4` |
| `QS_TEST_TIMEOUT` | watchdog in seconds (default 600). xcodebuild sometimes hangs after a failed UI test |
| `QS_SMOKE_ONLY=<state>` | SmokeTests runs only that seed state |

Never run two `run.sh` at once: they share the simulator. The app log (`app.log`) is `simctl spawn ... log stream` filtered to `process == "QuickStudy"`.

## Helper API

`Support/QSTestCase.swift` (subclass it; `app` is set by `launch`):

- `launch(_ states: SeedState..., extraArguments: [String] = [], environment: [String: String] = [:]) -> XCUIApplication`
- tearDown saves `<test>-FAILED.png` and `.hierarchy.txt` on failure and resets appearance and orientation.

`Support/QSApp.swift`:

- `QSApp.launch(_ states: SeedState..., extraArguments:, environment:)` and `QSApp.launch(states: [SeedState], ...)`: combine each state's launch arguments and environment, then launch.
- `app.relaunchKeepingState()`: terminate and launch again without `-QSResetInstall`, so disk state survives.
- `app.screenshot(named:in:)`, `app.dumpHierarchy(named:in:)`: attach to the result and write `<name>.png` / `<name>.hierarchy.txt` to the evidence directory (`QS_EVIDENCE_DIR`, passed to the runner as `TEST_RUNNER_QS_EVIDENCE_DIR`).
- `app.assertNotBlank(_ name:, in:, timeout:)`: fails when there are fewer than 2 labelled elements or the screenshot is a flat colour; saves screenshot and hierarchy as `<name>-BLANK`.
- `app.element(labelled:)`, `app.button(_:)`, `app.tap(_ label:)`, `app.tapTab(_:)`, `app.waitForAny(_:timeout:)`, `element.waitUntilGone()`.
- Timeouts: `QSApp.uiTimeout` 8 s, `launchTimeout` 20 s, `generationTimeout` 120 s.

`Support/Lifecycle.swift`: `app.lifecycleCheckpoint(_ id:, in:, rotate:)` is the script's LC (Home, 2 s, activate, same labels, not blank; `rotate: true` adds a landscape round trip). `app.labelSnapshot()` returns the visible labels.

`E2EHelpers.swift`: `shot(id, name)`, `dump(id, name)`, `note(id, text)` (appends to `<id>-notes.txt`), `button(beginningWith:)`, `text(containing:)`, `tapButton(beginningWith:)`, `watchFrames(id, name, seconds:)` (screenshots back to back; flat frames count as white-screen flashes), `advanceOnboarding()`.

`Support/SystemAlerts.swift`: `SystemAlerts.handle(.allow | .deny, timeout:)` taps the springboard alert button; `installSystemAlertMonitor(_:)` is installed by `QSTestCase.setUp`. A monitor only fires on the next interaction, so call `handle` right after the tap that triggers a known alert.

`Support/PageDots.swift`: `PageDots.activeDotCenter(in:)` finds the active onboarding page dot by colour (the dots are not in the accessibility tree).

`Support/StoreKitTesting.swift`: `StoreKitTesting.purchase(.monthly)`, `startSession()`, `stopSession()`. See StoreKit below.

## Seed states

`SeedState` (launch arguments and environment, applied by `launch`) and `Scripts/seed.sh <udid> <state>` (files and persisted defaults, run **before** the test) are two routes to the same state. Use one or both.

| State | `launch(...)` | `seed.sh` | Notes |
|---|---|---|---|
| `freshInstall` | `-QSResetInstall` | `clean` / `freshInstall` | Debug-only reset of Keychain, UserDefaults and Documents on every launch. Do not relaunch the app object with it if state must survive: use `relaunchKeepingState()`. Shows onboarding. |
| `onboardedEmpty` | `-qs_hasCompletedOnboarding YES -qs_lastSeenRelease 999` | `onboardedEmpty` | Empty Today and Library. |
| `demoData` | onboarded + `-demoModeEnabled YES` | `demoData` | The app seeds its own Photosynthesis sample (10 cards, 5 due) and writes `SavedSets.json`. |
| `midDraft` | onboarded | `midDraft` (needed) | File-backed: `PendingDraft.json` is a real draft ("The Water Cycle", 6 cards, drafted on-device by Apple Intelligence). |
| `userSet` | onboarded | `userSet` (needed) | File-backed: one saved non-sample set, 6 cards, from saving the midDraft. |
| (none; launch `userSet`) | onboarded | `userSetDraft` | `seed.sh` only: the `userSet` set plus a ready 6-card draft (`userSetDraft.PendingDraft.json`) whose cards have their own IDs, for Save · Add to Existing (`test_E_5`). The midDraft's cards share IDs with the saved set, and adding a card a set already holds is a no-op. |
| `proActive` | onboarded + a StoreKit purchase made by the runner before launch | `proActive` (onboarded only) | Needs `StoreKitTesting`. The purchase outlives the run: see StoreKit. |
| `allowanceSpent` | onboarded + `-qs_aiGenerationsUsed 10 -qs_aiGenerationsMonth <year*12+month>` | `allowanceSpent` | |
| `hostedConsentDeclined` | onboarded + `-qs_hostedConsent declined -qs_hostedConsentVersion 3` | `hostedConsentDeclined` | |
| `freeHostedSpent` | onboarded + `-qs_hostedFreeGenerationUsed YES` | `freeHostedSpent` | |
| `noAppleIntelligence` | onboarded + env `QS_SIMULATE_NO_APPLE_INTELLIGENCE=1` | `noAppleIntelligence` is onboarded only | The env var is read from the app's launch environment; set it with `launch(.noAppleIntelligence)` or `environment:`. |
| `sessions` | n/a | `sessions` | `seed.sh` only: demo set plus a real recorded session (5 answers). Dates are shifted so the newest session is today (`Scripts/shift-dates.py`). |

States combine: `launch(.onboardedEmpty, .noAppleIntelligence)`. A bare `launch()` with no state gives an install the app treats as upgraded-or-fresh depending on what is on disk.

Caveats:

- **Launch arguments shadow writes.** `-key value` lands in UserDefaults' argument domain: the app reads that value for the whole launch even after it writes a different one. So with `onboardedEmpty` the app cannot flip `qs_hasCompletedOnboarding`; with `demoData` the Settings "Show Sample Set" toggle appears stuck on; with `hostedConsentDeclined` accepting consent in the UI has no visible effect until relaunch; with `allowanceSpent` a generation cannot change the count. When a test needs the app to change a flag, seed with `seed.sh` (persisted, app can overwrite) and launch with no state, or pass only `extraArguments` for the flags that must stay fixed.
- **`seed.sh` writes into the app container's plist**, because `-QSResetInstall` only clears the container: values written to the device-level domain survive a "fresh install". It also resets the simulator Keychain (the allowance count is mirrored there and restored from it) and resets the camera permission (so onboarding's camera page appears). It does not reset photo access.
- **Order matters.** `seed.sh` first, then the test. A launch with `freshInstall` wipes Documents, so it removes any file seed.
- Seeded Documents persist between tests. A seeded draft stays on Today and Library for later tests until the next `seed.sh`. The SmokeTests states after `midDraft` therefore all show the draft row.
- **Seed once per import test, not once per class.** A test that drafts, saves or discards leaves the next one a different Library, and a leftover draft makes the next tap on + raise `Replace your draft?`. Run each B/C/E-5/WS test with its own `run.sh ... <seed>` (B: `onboardedEmpty`, C/WS-5/WS-6/E-5b/F-2/F-4/M: `midDraft`, E-5: `userSetDraft`, A-4/A-5: `clean`).
- Fixture dates are absolute. Due dates in `demoData`/`userSet` fall in the past after the day they were captured, which only makes cards due sooner.
- Fixture basenames must be unique across `Fixtures/`: the test bundle flattens the folder and a duplicate fails the build ("Multiple commands produce"). State files are therefore named `<state>.<File>.json`.
- Do not add `.swift` files outside real test code under `QuickStudyUITests/`; everything in the folder is compiled or copied. `Scripts/make-fixtures.swiftscript` has a non-`.swift` extension for that reason.

### Appearance, Reduce Motion, orientation

- Appearance: `XCUIDevice.shared.appearance = .dark`. Orientation: `XCUIDevice.shared.orientation`. `QSTestCase.tearDown` resets both.
- Reduce Motion: no XCUITest API. Set it from the host before the run, then confirm in the test with `UIAccessibility.isReduceMotionEnabled` (the runner sees it, so `test_WS_4` verifies the setting took):
  `xcrun simctl spawn $UDID defaults write com.apple.Accessibility ReduceMotionEnabled -bool true` (and `-bool false` to undo).

## StoreKit

- The scheme `QuickStudyUITests` carries `StoreKitConfigurationFileReference` for `QuickStudy/QuickStudy.storekit` in the Test and Run actions.
- **Reliable route: `SKTestSession` in the runner.** `StoreKitTesting.purchase(.monthly)` then launch: the app sees the entitlement (Pro pill "QuickStudy Pro · 150 of 150 generations left this month"). `launch(.proActive)` does this.
- The purchase **persists on the simulator after the run**, including for launches from `simctl`. Always end with `StoreKitTesting.stopSession()` (QSTestCase.tearDown does) or run `-only-testing:QuickStudyUITests/StoreKitResetTests`.
- **Without any runner session**, the paywall still loads both products with prices (`StoreKitSchemeTests`, run after a simulator reboot and after deleting the simulator's persisted Octane configuration), so StoreKit data is available to UI tests run through the scheme's xctestrun. The `.xctestrun` file carries no explicit StoreKit key, and `QuickStudy.storekit` is also copied into the app bundle, so the source of that data (scheme config or the sandbox catalogue) is not proven. Use `SKTestSession` when a test must buy, clear or fail a transaction.
- Never purchase against the real App Store sandbox.

## Pasteboard and permissions

- `xcrun simctl pbcopy <udid> < file` did **not** populate the simulator pasteboard on this setup (`pbpaste` returns nothing), and the paste editor offered only AutoFill on long-press. Type text instead: `app.textViews.firstMatch.tap(); typeText(...)` (the 255-character `notes-short.txt` types in seconds; the 2.5 kB `notes.txt` will be much slower).
- The paste sheet submits from its toolbar checkmark (`Draft Cards`), so the keyboard never covers it. Query it as `app.navigationBars["Paste Text"].buttons["Draft Cards"]` (`draftCardsButton`).
- If a paste-permission alert appears, `SystemAlerts.handle(.allow)` ("Allow Paste").
- Camera: onboarding's camera page shows only while camera access is undetermined (`seed.sh` resets it). The tap on "Allow camera access" raises a system alert: `SystemAlerts.handle(.allow)`.
- Photos: `stage-media.sh` grants access.

## Media staging

`Scripts/stage-media.sh <udid>` adds `scanned-page.png` to Photos (`simctl addmedia`), copies `small.pdf`, `large.pdf`, `corrupt.pdf` and the text fixtures into Files > On My iPhone > `QuickStudy Fixtures` (the `group.com.apple.FileProvider.LocalStorage` container's `File Provider Storage`), and grants photo access to the app. `Scripts/make-fixtures.sh` regenerates the PDFs and PNG.

| Fixture (`Fixtures/Inputs/`) | |
|---|---|
| `notes.txt` | about 400 words on the water cycle |
| `notes-short.txt` | 37 words on mitochondria |
| `empty.txt` | zero bytes |
| `small.pdf` | 3 pages of text |
| `large.pdf` | 320 pages (about 350 kB of text) |
| `corrupt.pdf` | truncated and garbage-padded; PDFKit cannot open it |
| `scanned-page.png` | 1700x2200 noisy, slightly rotated page of text |

The runner can also read fixtures from the test bundle or from `QSApp.fixturesDirectory`.

## Which AI engine runs in the simulator

On-device Foundation Models ("Apple Intelligence", provenance `engine: onDevice`) via the Mac's Apple Intelligence. A 140-word paste takes about 35 s to draft 6 cards. With no hosted consent recorded, nothing leaves the machine. Private Cloud Compute and the hosted server are consent-gated; never grant consent in tests (tap `Not Now`, never `Allow`). `noAppleIntelligence` forces the no-model path, where `Not Now` opens Type cards.

Consent is asked **after** the source is picked and read, and only when the draft would otherwise leave the iPhone (no decision recorded yet and the plan includes Private Cloud Compute or the server). It can therefore appear after the paste checkmark, after a photo is OCR'd, or after Choose Pages. `awaitGenerationOutcome` and `waitForDrafting` decline it whenever it shows up.

## Import flow helpers (`E2EHelpersBC.swift`, `E2EHelpersFM.swift`)

- `openLibrary()`, `createButton` (the floating +, label `New Set`), `openNewSetSheet(id)`, `chooseSource(id, label: Source.photo | .pdf | .paste)`.
- `typeIntoPasteSheet`, `draftCardsButton`, `tapDraftCards(id)`.
- `declineConsentIfAsked(id)`: taps `Not Now`.
- Status card: `isDrafting` (the `Cancel drafting` button exists), `draftingCard` (label `Drafting <title>, <detail>`), `cancelDraftingButton`, `readyCard` (label contains ` is ready`), `reviewCardButton` (`Review`), `failureCard(title)`, `dismissFailureButton` (`Dismiss`).
- `waitForDrafting(id)`, `awaitGenerationOutcome(id) -> (.ready | .failure(title) | .timedOut, seconds)`, `startShortGeneration(id)`.
- `tapReviewCard(id)` / `openDraftReview(id)`: Review Cards sheet. `reviewCardsNavBar`, `saveCardsButton`, `deleteCard(row)` (swipe; taps `Delete` if the swipe did not complete).
- `openSaveSheet(id, cards:)`, `saveSheetNavBar(cards:)`, `confirmSave(cards:)`, `saveDraftAsNewSet(id)` (any count), `addToExistingSegment`.
- `openDiscardAlert(id)`: long-press the ready card, `Discard Draft`, returns the `Discard Draft?` alert.
- `pickFile(id, named:)` taps the Files picker by position; `pickFirstPhoto(id)` taps the first PHPicker tile.

## Accessibility labels and gaps

The app has very few `accessibilityIdentifier`s: find elements by label. SwiftUI duplicates a control's label on a Button and its inner StaticText, so `app.buttons[...]` is the unambiguous query. Page dots, the quiz option letter badges and the floating tab bar glass are not addressable. The Today and Library screens keep the underlying screen in the tree while a cover or sheet is open.

Labels seen (exact strings):

- **Tab bar**: `Today`, `Library`, `Stats` (buttons in `Tab Bar`).
- **Onboarding**: `Get Started`, `Back` (disabled on page 1), `Continue`, `How it works`, `Private by default`, `Snap your notes`, `Allow camera access`, `Maybe later`, `Let's make your first set`, rows `Try a demo set`, `Scan a page`, `Drop in a PDF`, `Paste text`.
- **Today**: `Settings` (gear), `Today`, date `Tuesday, October 20`, pill `10 of 10 free generations left this month` / `QuickStudy Pro · N of 150 generations left this month` / `0 of 10 free generations left · resets November 1` with `Pro ›`, `TODAY'S SESSION`, `5 cards, 2 minutes`, `Start Session`, `What's in this?`, `WEAKEST CARD`, row `What is chlorophyll?, Missed 2 times · Drill`, `SUGGESTED`, `Yes, generate cards`. Empty: `Build your first set`, `Go to Library`; with a draft: a button `Resume <title>, 6 cards drafted · not yet saved` that switches to Library (it does not open Review Cards). The generations pill is hidden in the brand-new empty state (`TodayViewModel.showsGenerationsPill`).
- **Library**: nav title `Library`, `Search sets`, filter chips `All`, `Due`, `In progress`, `Mastered`, set tile `The Water Cycle. The water cycle, 6 cards, 6 due, 0% complete`, floating button `New Set` (the only way into import). Empty state: `Build your first set`, `Tap + to scan, import or paste your first notes.`, tip `Works best with 1 to 10 pages of notes.` (no source tiles).
- **Library status card** (top of Library, never blocks it; one at a time, drafting over failed over ready). Each card's text is one combined element `<title>, <detail>`:
  - Drafting: `Drafting <title>` with `Reading page N of M`, `Drafting cards`, `Drafting cards · N of M` or `Drafting cards · about N seconds left`; button `Cancel drafting`. Titles: `Drafting <PDF file name>`, `Drafting Photo`, `Drafting Scan`, or a title suggested from pasted text.
  - Ready: `<draft title> is ready` with `6 cards drafted` (`… from N pages` for multi-page); button `Review`. Long-press the card for a context menu `Discard Draft`, which raises alert `Discard Draft?` (`Discard Draft`, `Cancel`; message `The 6 drafted cards will be deleted. This used one of your free generations.`).
  - Failed: `Something went wrong`, `We couldn't read this`, `We couldn't open this PDF` (`It may be damaged or password protected.`), `On-device AI isn't ready`, `Free generations used`; button `Dismiss` and one recovery: `Try Again`, `Edit Text` / `Paste Text`, or `Type Cards`. `Try Again` on a PDF reopens the Files picker.
  - Tapping + while drafting or with a ready draft raises `Replace your draft?` (`Replace`, `Cancel`) with `QuickStudy is still drafting <title>. Starting a new set will cancel it.` or `You have a draft from <title> waiting. Starting a new set will discard it.`
- **New Set sheet** (medium sheet over Library): nav title `New Set`, `Close`, rows `Choose Photo, From your photo library`, `Choose PDF, From Files`, `Paste Text, From Notes, Safari or any app`, footer `Works best with 1 to 10 pages of notes.` The `Scan Document, Fastest · recommended` row is hidden on the simulator (no document camera). Onboarding's `Scan a page` still reaches the alert `Camera Unavailable` / `Document scanning isn't available on this device. Import a photo or PDF instead.` with `OK`.
- **Paste Text sheet**: nav title `Paste Text`, `Close`, toolbar checkmark `Draft Cards` (disabled while empty or whitespace), editor `Paste your notes here` (`app.textViews.firstMatch`), summary `140 words · about 12 cards`, engine chip `On this iPhone` / `Private Cloud Compute` / `QuickStudy Cloud` / `Your AI endpoint`. No free-generations counter.
- **Choose Pages** (PDFs over 10 pages): nav title `Choose Pages`, `Close` (cancels the import), `large · 320 pages`, `Tap pages to choose up to 10.`, cells `Page N` with value `Selected` / `Not selected`, summary `Pages 1 to 10 selected` / `10 pages selected` (non-contiguous) / `No pages selected`, estimate `10 pages · about 1 minute on this iPhone`, button `Draft 10 Pages`, cap note `You can choose up to 10 pages.` for 2.5 s after an 11th tap.
- **Cloud consent sheet** (after the source is read, only when the draft would leave the iPhone): `Draft in the Cloud?` (or `Draft This Set in the Cloud?` without an on-device model), copy naming Anthropic's Claude and 30-day deletion, `Privacy Policy`, `Allow`, `Not Now`. Tests must tap `Not Now`.
- **Settings** (gear on Today; a sheet): `Settings`, `AI + Input`, switches `Handwriting Mode`, `Spell Check`, `AI Source, On-Device`, `Pro` / `Upgrade to QuickStudy Pro`, `Sample Content` / switch `Show Sample Set`, `Privacy` / switch `Share anonymous usage`, `Data` / `Delete All Study Sets`, `About` / `Version, 2.0 (1)`, `What's New`, `Privacy Policy` (a link). There is no hosted-consent control in Settings.
- **Paywall** (`Pro ›` pill, Settings, or after the first set): `QuickStudy Pro`, `Pro Monthly` (`1 week free, then $4.99/month`), `Pro Yearly` (`$39.99/year`), `Accept Offer`, `Restore Subscription`, close `X`.
- **Review Cards** (sheet from the status card's `Review`): nav title `Review Cards`, `Close` (keeps the draft), toolbar checkmark `Save Cards` (disabled with no complete cards or while regenerating), header `6 cards from Pasted Notes, Tap a card to edit. Swipe left to delete.` (`, pages 1 to 10` for chosen PDF pages), card rows (Button label `<question>. <answer>`), per-card pill `Source` or `Source, page N`, swipe action and context menu `Delete`, `Undo` for 5 s after a delete, `Regenerate` below the cards (with edits: dialog `Replace 6 cards?` / `Your edits will be lost.` / `Replace` / `Cancel`; while running a `Regenerating` spinner). Editing a row shows text fields labelled `Question` and `Answer` and a `Done` button. With every card deleted: `No cards left`, `Undo the last removal, or discard this draft.`, `Undo`, `Discard` (alert `Discard Draft?`).
- **Card Source** (from a row's Source pill): nav title `Source` or `Source · Page N`, `Close`, the passage with the card's lines highlighted, toggle `Show Full Page` / `Show Passage`.
- **Save sheet** (from `Save Cards`): nav title `Save 6 Cards` / `Save 1 Card`, `Close`, toolbar checkmark `Save`, segmented control `New Set` / `Add to Existing`. New Set: `NAME`, text field `Name` (value is the suggested title), `Clear Name`, `Suggested from your notes. You can rename it anytime.` Add to Existing: rows `<title>, N cards` (selected trait on the chosen one, first preselected) and `6 cards will be added to <title>.` With no sets of the user's own (none, or only sample sets) `Add to Existing` is disabled and `You have no sets of your own to add these cards to yet.` shows.
- **Quiz**: `BackButton`, `Session, question 1 of 5`, `Elapsed time` (value), `Session progress` (value), `Why this answer, source From Photosynthesis, page 1`, option buttons `Option A, <text>` .. `Option D, <text>`, `Submit` (disabled until an option is chosen), `Next question`, reveal labels `Correct` / `Why` / `Source: ...`.
- **Session Complete**: `Session complete`, `Done`, `1 day streak`, `CARDS`, `CORRECT`, `ACCURACY`, `NEEDS REINFORCEMENT`, `One more session` (below the fold at rest).
- **What's New**: `VERSION 2.0`, `What's New`, `See QuickStudy Pro`, `Continue`.

Timing: after `launch` the app shows a white launch screen for about 2 s before the first view renders (Debug build); `launch` returns once the app is idle so tests rarely see it. `simctl launch` followed by screenshots shows it.

Fast quiz tip: tap an option, wait for `Submit` to be enabled, then tap it; tapping too soon after `Next question` races the question transition.

## Evidence

Everything under `QS_EVIDENCE_DIR`: `<ID>-<name>.png`, `.hierarchy.txt`, `<ID>-notes.txt`, `.mp4`. Failures add `<test>-FAILED.png`, `<ID>-LC-BLANK.png` and so on. Never log or commit user content from a real device; fixtures are original text.
