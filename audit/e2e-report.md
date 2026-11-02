# QuickStudy E2E report: 2026-10-20

The run used one simulator, QS-P1 (iPhone 18 Pro, iOS 27.0). Matrix devices (SE 3rd gen, 18 Pro Max, iPad Pro 13) were booted one at a time and then deleted. The test script is in `audit/e2e-test-script.md`. Evidence is in the session scratchpad under `e2e/run/`, `e2e/ws/` and `f0/`. Raw findings are in `e2e/raw-findings.md`. No app source was changed.

## 1. White screen

### Most likely: the empty launch screen (confirmed)
Every cold launch shows a flat white frame for 1.3–2.1 s (flat black in dark mode), then the content fades in over 0.5 s. This was seen on every device in light and dark, in Debug and Release, and on the first launch after an erase.

**Repro:** in light mode, run `xcrun simctl terminate <udid> com.henley.jaiden.QuickStudy`, then `xcrun simctl launch <udid> com.henley.jaiden.QuickStudy`, and record with `simctl io recordVideo`.

**Root cause:** `project.pbxproj:429` (Debug) and `:466` (Release) set `INFOPLIST_KEY_UILaunchScreen_Generation = YES` and nothing else, so the generated `UILaunchScreen` is empty and the system draws `systemBackground`. Startup code is not the cause: `ContentView` init takes under 0.2 s, and Settings.app takes about 2.2 s on the same simulator.

**Proposed fix (not applied).** Give the launch screen the `AppBackground` colour; that colorset already exists with light and dark variants. The simplest way is in Xcode: Target → Info → Launch Screen → Background color = `AppBackground`. Done by hand, it looks like this:

```xml
<!-- QuickStudy/Info.plist (new; merged with the generated Info.plist) -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>UILaunchScreen</key>
	<dict>
		<key>UIColorName</key>
		<string>AppBackground</string>
	</dict>
</dict>
</plist>
```

`project.pbxproj` changes, for both app configs:
- Set `INFOPLIST_FILE = QuickStudy/Info.plist`.
- Drop `INFOPLIST_KEY_UILaunchScreen_Generation`.
- Add a `PBXFileSystemSynchronizedBuildFileExceptionSet` on the `QuickStudy` synchronized group that excludes `Info.plist` and `QuickStudy.storekit` from the app target. Excluding `Info.plist` avoids "Multiple commands produce Info.plist"; excluding `QuickStudy.storekit` also fixes F22.

### Second: onboarding showing background and page dots only (seen once in about 14 attempts)
- **What was seen:** on a just-booted simulator, `simctl launch -QSResetInstall` showed only `BackgroundView` and `PageDots` at 8 s (`e2e/ws/01-cold-reset-light/shot.png`).
- **Why the page was empty:** the art, the title and Get Started are all gated by `appStagedReveal(_, shown: appeared)` at `OnboardingWelcomePage.swift:39,55,68`, using `Motion.swift:38-49`. So the screenshot is the reveal's first frame, with everything at opacity 0.
- **Not caused by your uncommitted changes:** HEAD has the same reveals.
- **Likely mechanism (moderate-low confidence):** a main-thread stall from a first-use Metal shader compile on a cold cache. In the log, the main thread compiled a shader and then went silent for about 5 s. The good runs show no such gap. XCUITest can't catch this, because opacity 0 still counts as hittable.
- **Defensive fix:** don't gate the heading or the only CTA of a launch-critical screen on the reveal; keep the reveal on the decorative art only. The same pattern gates the primary CTA in `ImportErrorView.swift:129`, `WhatsNewView.swift:52/60`, `SessionCompleteView.swift:106` and `OnboardingCameraPage.swift:66`.

```swift
// QuickStudy/Views/Onboarding/Components/OnboardingWelcomePage.swift (changes only)
                    VStack(spacing: Spacing.md) {
                        // …title and subtitle unchanged…
                    }
                    // .appStagedReveal(1, shown: appeared)   // REMOVED
            // …
            Button(action: onContinue) { Text("Get Started").frame(maxWidth: .infinity) }
                .appProminentButtonStyle(tint: Theme.primary)
                .controlSize(.large)
            // .appStagedReveal(2, shown: appeared)           // REMOVED
```

### Other candidates (static only, not reproduced)
- **(a) Draft Save or Discard pop.** `ImportModifiers.swift:36-58` has `if let draft` with no else, and `ReviewDraftsView.swift:272-273` clears the draft before `dismiss()`. The runtime check found 0 white frames in 28.
- **(b) Session card swapped out mid-quiz.** `SessionCard.swift:102-105` owns the session destination inside a conditional at `TodayView.swift:81-84`. It did not pop at runtime. Fix: hoist the destination to `TodayView`.
- **(c) Stacked presentations on `ContentView.swift:93-133`.** These can't produce a white screen. See F40.

## 2. Findings by severity

**BLOCKER:** none confirmed.

### HIGH

**F18 / WS-L: white launch screen for 1.3–2.1 s.**
- Location: `project.pbxproj:429,466` ✓
- See section 1.

**F01: some import errors are swallowed.**
- Location: `ImportCoordinator.swift:272-279, 288-292`; `ImportModifiers.swift:127-130`; `DocumentImportHelper.swift:52` ✓
- Repro: pick a corrupt PDF; or on a device without Apple Intelligence, Not now → paste → Generate. You land back on Library with no error. The stale error then appears over a later, unrelated import.
- Mechanism: the module defaults to `MainActor`. `showGenerating = true` and the synchronous failure both happen in the same turn, so the Generating cover never presents and its `onDismiss` never shows `pendingFailure`.
- Fix: track whether the cover actually appeared (`isGeneratingCoverUp`, set by the cover's `onAppear`). If it never appeared, present the failure directly; clear `pendingFailure` on dismiss. Also have a corrupt PDF throw (`DocumentImportHelper.swift:52`), rather than return an empty document that reports as "No text detected".

**F02: Generating stuck on "Reading page N of N", bar frozen at 15%.**
- Location: `ImportCoordinator.swift:414, 441`; `DocumentImportHelper.swift:65` ✓
- Mechanism: the page callback queues `Task { @MainActor in stage = .reading }`. That task runs after `stage = .drafting` and drags the screen back to reading.
- Fix: inside the task, `guard case .reading = self.stage else { return }`.
- Follow-up: PDF extraction runs on the main actor, and `DispatchQueue.global` is used at `DocumentImportHelper.swift:112`.

**F03: "Not now" without Apple Intelligence opens a paste sheet that can't generate.**
- Location: `ImportCoordinator.swift:117-152` ✓
- Expected: Type cards, as both the consent copy and CLAUDE.md promise.
- Fix: in `resumeAfterConsent`, a decline on `.unsupportedDevice` sets `showTypeCards = true`. Refresh the Library entitlement when the consent sheet closes.

**F05: spell check rewrites correct text before generation.**
- Location: `StudyViewModel.swift:209, 448-498` ✓
- Repro: "cristae" becomes "Crest" in the source, the excerpts and the cards. This applies to pasted text and PDF text layers, not just OCR.
- Fix: spell-correct OCR pages only (`!page.candidates.isEmpty`). Ideally, only accept a guess that appears among Vision's candidates.

**F09: "One more session" replays the cards just answered.**
- Location: `QuizSessionView.swift:33, 260-263` ✓
- Mechanism: it replays the same cards while Today says "All caught up", moving each box a second time that day.
- Fix: rebuild the session from `dueCards()`, and hide the button when nothing is due. Hiding it is a deviation from Final v2 and needs your OK.

### MEDIUM
- **F08** Undo moves the due date forward: Today drops from 5 to 4. `StudyViewModel.swift:72-79` ✓. Fix: snapshot the card's scheduling at submit and restore `dueDate`/`lastReviewedAt` on Undo.
- **N1** (static) A saved draft can come back as "Resume". `ReviewDraftsView.swift:171-172, 265-274` (unverified). `save()` mutates `@State` and its `onChange` re-persists the draft. Fix: build the committed set from a local copy.
- **F40** (static) The onboarding paywall can be dropped after the first Type cards set. `TypeCardsView.swift:77-79` + `ContentView.swift:102-106` (unverified). Fix: clear the pending flag in the paywall's `onAppear`.
- **N2** "Delete Everything" leaves the pending draft (with its source text), sessions and streak data behind, and the sample set returns. `SettingsView.swift:220-227` ✓
- **F07** Paste sheet Generate is hidden by the keyboard, and below the fold without it. `PasteTextSheet.swift:64-71, 108-122` ✓
- **F10** No way to withdraw hosted consent. `SettingsView.swift`, `HostedConsent.swift:36` ✓
- **F11** The Why? pill shows the answer before submitting, and there is no hint button. `QuizSessionView.swift:75-102` ✓
- **F13** Session Complete's "One more session" is below the fold and under the tab bar, and "Session complete" appears twice. `SessionCompleteView.swift:38-47, 99-106` ✓
- **F14** The wrong-answer Undo row is hidden under "Next question". `QuizSessionView.swift:147-164, 194-207` ✓
- **F15** The quiz is unusable in landscape: about 103 pt of scroll area, with the tab bar over it. `QuizSessionView.swift:37-61, 194-218` ✓
- **F16** AX5 breaks layouts on Today, Library, the New Set sheet and Scan Preview. `AICardsLeftView`, `PendingDraftRow`, `NewSetSheet:95`, `SourceOptionButton`, `ScanPreviewView` (unverified)
- **F17** At AX5 the quiz header takes more than 55% of the screen, and the answers truncate. `QuizSessionView.swift:38-56`, `QuizChoiceRow` (unverified)

### LOW
| ID | Finding | Location |
|---|---|---|
| F06 | Card estimate shows "~39 cards" against 16 generated (it counts sentences) | `ContentAnalysis.swift:20, 30-35` ✓ |
| F19 | Progress bar VoiceOver value reads "Question 5 of 5" after any answer | `SessionProgressBar.swift:51-53` ✓ |
| F21 | Consent sheet's Privacy Policy link clipped by Allow at the 360 pt detent | `HostedConsentSheet.swift:62` ✓ |
| F22 | `QuickStudy.storekit` is copied into the app bundle | `project.pbxproj`; fixed by the section 1 exception set ✓ |
| F23 | Draft edit fields have no accessibility labels | `DraftCardRow.swift:28,38` |
| F24 | "Save 0 cards" shows with no empty message | `ReviewDraftsView.swift:166, 197-205` ✓ |
| F25 | Single-page sources show "¶1" with no page | `CardSource.swift:18-23` ✓ |
| F26 | Generating nav title doesn't match the headline | `GeneratingView.swift:112-118` ✓ |
| F28 | The sample set reseeds after deletion | `StudyViewModel.swift:547-559, 640-647` ✓ |
| F29 | Streak link stale after leaving a quiz early | `QuizSessionView.swift:255-257`, `TodayView.swift:140-149` ✓ |
| F30 | "No sets match this filter." shows for a search | `LibraryView.swift:68` ✓ |
| F31 | No way to add cards to an existing set | `StudySetDetailView.swift`, `TypeCardsView.swift:77` ✓ |
| F32 | Settings is a plain Form with no `BackgroundView` | `SettingsView.swift:81` ✓ |
| F33 | Show Sample Set toggle reports a stale accessibility value | `StudyViewModel.swift:21-26` ✓ |
| F34 | Pro pill has low contrast | `AICardsLeftView.swift:34-40` |
| F35 | A long correct answer is truncated on reveal | `ResultCard.swift` |
| F36 | iPhone SE shows only options A–B at rest | `QuizSessionView` |
| F37 | Reduce Transparency: disabled Submit looks enabled | `Theme.swift` |
| F38 | Force quit mid-Generating loses the pasted text with no notice | `ImportCoordinator.swift:244-249` ✓ |
| N3 | Spell Check toggle isn't persisted | `StudyViewModel.swift:43` ✓ |
| N4 | `DispatchQueue.global` in OCR, against the CLAUDE.md concurrency rule | `DocumentImportHelper.swift:112` ✓ |

### Design gaps vs Final v2
- **F04** The Review source pill is display-only.
- **F06** "pasted from Notes" and the Definitions chip are missing. The source app isn't exposed by any public API.
- **F11** No hint button.
- **F27** The New Set sheet covers the floating button.
- The tab bar stays visible over the quiz and Session Complete.

### By design / not a bug
- **F12:** answers are lost only on a crash or a foreground SIGKILL. A force quit from the app switcher backgrounds the app first, which flushes.
- **F20:** the pill gating is deliberate.
- **F36, F39:** the paywall is the system `SubscriptionStoreView`.
- **Approved deviations:** the gear, and the pill's paywall/teal behaviour.
- **Not built on purpose:** notifications, theme clustering, typed answers, custom camera.

## 3. Untestable in the Simulator
- Camera scan end to end, including the consent sheet showing before the scanner.
- Private Cloud Compute.
- App Attest and hosted Pro generation (the simulator returns QS-701).
- Real App Store sandbox purchase, renewal and refund.
- On-device model speed on real hardware: 3 pages took 100 s in the simulator, and 320 pages had no upper bound.
- WS0 on a device: the first launch after install, with a cold shader cache.
- Launch-screen duration on a device after the colour fix.
- Real jetsam during a quiz or generation.
- Haptics.
- VoiceOver with real speech; Dynamic Type on physical hardware.

## 4. Test target status
`QuickStudyUITests` target (114 inserted lines in `project.pbxproj`, none deleted) plus the new `QuickStudyUITests.xcscheme`. The existing scheme is untouched.

| Suite | Pass | Fail |
|---|---|---|
| SmokeTests | 10/10 seed states | 0 |
| WS + A (`E2EScriptTests`) | 17 | A-6 (F20, deliberate) |
| B + C (`E2EScriptCreateReviewTests`) | 22 (B-2 device-only) | B-8 (F02), B-9 (F01), B-10 (F01/F03), C-5 (F04) |
| D + E (`E2EScriptQuizLibraryTests`) | 16 | D-1/D-7 (F11), D-5 (F08), D-8 (F12, by design), E-2 (F30), E-4b (F28), E-5 (F31), E-12 (F10) |
| F + M (`E2EScriptLifecycleMatrixTests`) | 14 | F-4 (F13/F15), M-2 AX5 (F16/F17) |

Run tests one at a time through the scratchpad wrappers (`bc.sh`, `de.sh`, `fm.sh`) or `QuickStudyUITests/Scripts/run.sh`. See `QuickStudyUITests/Support/README.md`.
