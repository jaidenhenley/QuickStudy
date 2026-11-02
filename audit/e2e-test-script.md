# QuickStudy end-to-end test script

One simulator, one pass, top to bottom. Every step is executed and recorded as PASS, FAIL, or BLOCKED (with the reason).

## 0. Setup

| Item | Value |
|---|---|
| Simulator | QS-P1 `90A4E5EA-CE24-454B-BE53-86663760BF18` (iPhone 18 Pro, iOS 27.0). No other simulator is booted unless a matrix step says so. |
| Build | `build-for-testing` once with scheme `QuickStudyUITests`, DerivedData `scratchpad/dd-p1`. Every later run uses `test-without-building -only-testing:`. |
| Seeding | `QuickStudyUITests/Scripts/seed.sh <udid> <state>`, `-QSResetInstall`, UserDefaults launch-argument overrides (see `QuickStudyUITests/Support/README.md`) |
| Media | `Scripts/stage-media.sh <udid>` once before section B |
| Log | `xcrun simctl spawn <udid> log stream --style compact --level debug --predicate 'process == "QuickStudy" OR subsystem == "com.henley.jaiden.QuickStudy"'`, running for the whole pass and split per section |
| Evidence | `scratchpad/e2e/run/<step-id>-<short-name>.png`, plus `.txt` (the `app.debugDescription` hierarchy) for any failure |
| Network | Never set `QS_DEV_TOKEN`. Hosted generation is expected to fail in the Simulator; test only that it fails gracefully. |

**On every failure, capture:** a screenshot, the hierarchy dump, the 10 s of log before it, and the exact steps.

**LC = the lifecycle checkpoint.** Run it wherever a step says LC:
1. Press Home with `XCUIDevice.shared.press(.home)`, wait 2 s, then `app.activate()`.
2. Assert the screen is the same one and not blank, and that any half-finished input is still there.
3. Every third LC, also rotate to landscape and back with `XCUIDevice.shared.orientation`. The app supports landscape on iPhone.

---

## WS. White-screen repros (run first)

| ID | Steps | Expected | Look for |
|---|---|---|---|
| WS-1 | Light mode, `-QSResetInstall`, cold launch, wait 8 s, screenshot. Repeat 3×. | The welcome page shows the art, "Notes in. Flashcards out." and "Get Started". | Only the background and page dots (already seen once) |
| WS-2 | If WS-1 is blank: dump the hierarchy. Does `app.buttons["Get Started"]` exist, and is it hittable? Tap at its expected frame, then check whether the page dots move to page 2. | | Dots move: content is present but at opacity 0 (stuck reveal). Nothing happens: content is not rendered (paging TabView). |
| WS-3 | WS-1 in dark mode | Same as WS-1 | |
| WS-4 | WS-1 with Reduce Motion on | Same as WS-1 | Whether the reveal path differs |
| WS-5 | Seed `midDraft`, skip onboarding. Library → Resume draft → (Scan Preview "Review N cards" if shown) → "Save N cards". Record video with `simctl io recordVideo`. | A smooth pop back to Library, and the new set appears | An all-white frame, or a page left blank after the pop |
| WS-6 | WS-5, but Scan Preview → Cancel → Discard | Back to Library with the draft gone | Same as WS-5 |
| WS-7 | Seed `demoData`. Today → Start Session → answer every card until the last one → Submit | The reveal, then Session Complete | A pop back to Today ("All caught up") or a blank page |
| WS-8 | Today → WEAKEST CARD row → answer one card | The quiz continues normally | A blank page, or a pop caused by the `.id` change |
| WS-9 | After WS-7: on Session Complete, check that the streak card, the stats card and "One more session" are visible | All visible | Content stuck at opacity 0 |
| WS-10 | `qs_lastSeenRelease = 1` with a non-sample set present, then launch | What's New appears with its content visible | Background only |

## A. First launch, onboarding, empty states

| ID | Steps | Expected |
|---|---|---|
| A-1 | `freshInstall`. Go through every onboarding page with Continue/Get Started. LC on page 2. | 5 pages. The dots track the current page. Back appears from page 2. |
| A-2 | Swipe between the pages, then use Back | Swipes and Back stay in sync with the dots |
| A-3 | Camera page → "Allow" (accept the system alert), and on another run "Later" | Moves to the next page either way, with no hang |
| A-4 | First-source page: choose each option on separate runs (Scan, Photo, PDF, Paste, Explore) | The cover dismisses and the matching import flow starts. Scan in the Simulator should fail gracefully (no camera). |
| A-5 | If the paywall follows onboarding (`qs_onboardingPaywallPending`) | The paywall presents after the cover is fully dismissed, with no collision |
| A-6 | Empty Today | The "Today · Empty" design. No apology text, no disabled CTA, no Edit button. The trailing toolbar item is a gear. The generations pill is visible. LC. |
| A-7 | Empty Library | The "Library · Empty" design. The empty state names the next action, and the floating create button is visible. LC. |
| A-8 | Relaunch after onboarding | Onboarding does not show again |

## B. Create

Run `stage-media.sh` first. Unless a step says otherwise, the state is `onboardedEmpty`.

| ID | Steps | Expected |
|---|---|---|
| B-1 | Library → floating create button | A half-sheet over the dimmed Library. The primary row reads "Scan with camera · Fastest · recommended", with Photo, PDF and Text tiles below it. Note copy differences from the design. LC. |
| B-2 | Scan with camera | The Simulator has no camera, so expect a graceful error or an unavailable message, never a crash. Mark device-only. |
| B-3 | Photo → pick `scanned-page.png` | OCR → Generating → Review drafts. Record which engine ran. |
| B-4 | PDF → `small.pdf` | Generating ("Reading page x of y" or similar) → drafts with page-aware source pills. LC during Generating. |
| B-5 | Text → paste `notes.txt` (`simctl pbcopy` and the paste-permission alert) | Word count and source line, predicted chips, the allowance counter, and the "On this iPhone · no upload · works offline" footer. Generate. |
| B-6 | Text → `notes-short.txt` | Either generates a few cards or explains it's too short. No crash. |
| B-7 | Text → empty or whitespace only | The Generate button is disabled, or a clear message appears. No generation call. |
| B-8 | PDF → `large.pdf` (300+ pages) | Progress, then a clear size or length message or a truncated result. No hang over 120 s, no memory crash. |
| B-9 | PDF → `corrupt.pdf` | ImportErrorView with recovery tips. No blank screen, no crash. |
| B-10 | Relaunch with `QS_SIMULATE_NO_APPLE_INTELLIGENCE=1` and generate from text | Routes to the no-model path (Type cards or hosted consent). Never blocks with nothing on screen. |
| B-11 | `allowanceSpent` → generate | A clear allowance message, with the Pro route to the paywall |
| B-12 | `hostedConsentDeclined` + no Apple Intelligence → generate | Drafts on-device, or goes to Type cards. Never sends to the network. |
| B-13 | No Apple Intelligence, consent not yet asked → generate | HostedConsentSheet appears. The copy mentions Anthropic Claude and 30-day deletion, and never says "not stored". Decline → on-device or Type cards. Accept → the hosted call fails in the Simulator (no App Attest), and that failure is shown to the user. |
| B-14 | Cancel during Generating (if a cancel exists), then background the app during Generating | Returns cleanly. After foregrounding, the result or an error appears and nothing is stuck. |
| B-15 | TypeCards: create 2 cards by hand and save | The set is saved and appears in Library |

## C. Review drafts

| ID | Steps | Expected |
|---|---|---|
| C-1 | Seed `midDraft` → Library shows a pending draft row → Resume | ReviewDraftsView. The header names the source document, every card has a source pill (`p.N ¶N`), and the CTA reads "Save N cards". |
| C-2 | Tap a card → edit the front and back → done | The edit sticks. No layout jump. LC while editing (the text must survive). |
| C-3 | Swipe left on a card → remove | The card is gone and the CTA count drops by one |
| C-4 | Remove every card | The CTA disables or explains. No crash, and no 0-card set gets saved. |
| C-5 | Tap a source pill | Shows the source excerpt or Scan Preview for that paragraph |
| C-6 | Make an edit and a removal, then `app.terminate()` and relaunch | The draft survives, edits included. Library still shows the draft row. |
| C-7 | Save | Pops to Library (see WS-5). The new set shows the right card count, not "0 cards". |
| C-8 | Discard a draft (from the row or Scan Preview) | A confirmation, then the draft is gone. Relaunch confirms it. |

## D. Quiz

| ID | Steps | Expected |
|---|---|---|
| D-1 | `demoData` → Today → Start Session | "Session · 1 of N", elapsed timer, segmented progress, category label, "Why?" pill, hint button, Submit |
| D-2 | Select an option | Tinted fill. Comparing frames before and after shows no reflow. |
| D-3 | Correct answer → Submit | Correct state → Next |
| D-4 | Wrong answer → Submit | Red and green side by side, a Why with the source excerpt and document/page, and "We'll surface this one again tomorrow · Undo" |
| D-5 | Tap Undo | The answer is reverted. The box is unchanged. |
| D-6 | Tap the Why? pill before answering | The source excerpt sheet. Dismiss returns to the same question. |
| D-7 | Hint | A hint appears and does not reveal the answer outright |
| D-8 | LC mid-question, then kill and relaunch mid-session | The session resumes or ends cleanly. Answers already given are persisted. |
| D-9 | Finish the session | Session Complete with trophy, elapsed time, streak delta, cards/correct/accuracy, NEEDS REINFORCEMENT (if any were wrong), "One more session" |
| D-10 | One more session | A new session starts with the right count, or there's a clear empty message if nothing is due |
| D-11 | Leave the quiz early (Back or Close) | A confirmation or a clean exit. Today's counts are consistent afterwards. |

## E. Library, set detail, streaks, settings, paywall, consent

| ID | Steps | Expected |
|---|---|---|
| E-1 | `sessions` seed → Library | Tiles show mastery and due badges. The filter chips and search work. LC. |
| E-2 | Search for nonsense | An empty-result state, not a blank screen |
| E-3 | Open a set → StudySetDetailView | Cards list, Study button, and sources where available |
| E-4 | Delete a set (swipe or menu) | A confirmation, then it's removed. Today updates. Relaunch confirms it. |
| E-5 | Add cards to an existing set (AddCardsSection) | The import flow appends to that set |
| E-6 | Streak view from Today | Week strip, longest-streak comparison, freezes. Copy promises no notifications. |
| E-7 | Stats view | Renders with data and with no data |
| E-8 | Settings (gear) | All rows work. AI mode, endpoint and API key go through the Keychain (the key is never shown in plain text after saving). The sample-sets toggle adds or removes demo data. |
| E-9 | Generations pill → "Pro ›" | The paywall opens. Products load (StoreKit test config) or a clear failure shows. The header and feature rows are visible. |
| E-10 | Buy monthly using local StoreKit testing | Becomes Pro. The pill turns teal with the hosted count. |
| E-11 | Restore purchases | Completes with feedback. No hang. |
| E-12 | Consent: Settings → hosted consent revoke/grant (if exposed) | The state changes and is reflected on the next generation |
| E-13 | What's New (from Settings or a version bump) | Content visible, dismisses cleanly |

## F. Lifecycle (on top of the inline LC checkpoints)

| ID | Steps | Expected |
|---|---|---|
| F-1 | Memory warning on Today, a mid-quiz question and Review drafts (Simulator → Debug → Simulate Memory Warning through `osascript`, or `notifyutil -p com.apple.system.lowmemory`; record which worked) | No crash. Screen intact. |
| F-2 | Force quit from Library, Quiz, Review, Paywall and Generating, then relaunch | Relaunch lands on a sensible screen with state intact. No blank screen. Every relaunch gets WS-style blank detection. |
| F-3 | Change the appearance while the app is backgrounded, then foreground | Re-renders in the new mode. No white flashes, no unreadable text. |
| F-4 | Landscape on Today, Library, Quiz, Review and Session Complete | Usable layout: nothing clipped off-screen, no overlapping controls |

## M. Matrix: core path only, run as a script

**Core path:** launch → Today → Library → New Set sheet → (`midDraft`) Review drafts → (`demoData`) first quiz question → wrong answer → Session Complete → Settings → Paywall. Screenshot each screen. Check for clipping, overlap, unreadable contrast, missing glass or background, and content at opacity 0.

| ID | Config | How |
|---|---|---|
| M-1 | Dark | `xcrun simctl ui <udid> appearance dark` |
| M-2 | AX5 Dynamic Type | `xcrun simctl ui <udid> content_size accessibility-extra-extra-extra-large` |
| M-3 | Reduce Motion | Simulator accessibility setting (`defaults write com.apple.Accessibility ReduceMotionEnabled`, then respring), or a launch argument if available |
| M-4 | Reduce Transparency | Same mechanism, `EnhancedBackgroundContrastEnabled` |
| M-5 | iPhone SE (3rd gen) | Shut down QS-P1, create and boot one SE device if the runtime supports it, otherwise iPhone 16e/17e. Light, default text. |
| M-6 | iPhone 18 Pro Max | Same pattern, one device at a time |
| M-7 | iPad Pro 13-inch | The app is iPhone-only, so it runs in compatibility mode. Check that it launches and isn't letterboxed blank. |

Reset each setting after its pass. Delete any extra simulator when done.

## Untestable in the Simulator (device list)

- Camera scan (`VNDocumentCameraViewController`)
- Private Cloud Compute
- App Attest, and therefore the hosted Pro generation end to end
- Real App Store sandbox purchases
- On-device Foundation Models performance on real hardware
- Haptics
