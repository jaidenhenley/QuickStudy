# 05 — UX Flow Audit

Branch `jh/edgeCaseStates`, 2026-09-22. Read-only trace of the code paths. The Final v2 design files were not available, so screens are judged against CLAUDE.md's description of Final v2 and against basic UX practice. All paths are relative to `QuickStudy/`.

I checked the items I relied on in `audit/00-map.md` against the source: tabs, onboarding pages, the paywall trigger, the 10/month allowance, the one free hosted generation, and the engine routing. One correction: the map says `OnDeviceCardGenerationEngine.sourceChunkLimit = nil`. It is actually `1200` (`Models/AI/Engine/OnDeviceCardGenerationEngine.swift:19,23`), and that value drives UX-003.

---

## Flow walkthroughs

### 1. Onboarding (first launch)
1. `ContentView.onAppear` → `startOnboardingIfNeeded()` shows a full-screen cover when `userSetCount == 0` and onboarding is not complete (`Views/Shared/ContentView.swift:72-77,99-108`). Today renders underneath.
2. Welcome: "Notes in.\nFlashcards out." → **Get Started** (`OnboardingWelcomePage.swift:35,46`).
3. How it works: three steps → **Continue** (`OnboardingHowItWorksPage.swift`).
4. AI intro: "Private by default". The text branches on `hasOnDeviceModel`. The footnote always says the first set is drafted in the cloud → **Continue** (`OnboardingAIIntroPage.swift:21-69`).
5. Camera (only if permission is undetermined): "Snap your notes" → **Allow camera access** / **Maybe later** (`OnboardingCameraPage.swift:24-43`).
6. First source: **Try a demo set** ("RECOMMENDED · 90 SECONDS"), or Scan / PDF / Paste (`OnboardingFirstSourcePage.swift:22-58`). Photo is not offered.
7. The cover dismisses → `finishOnboarding()` sets the paywall as pending (if not Pro). Demo → `demoModeEnabled = true`, Today tab. Source → Library tab and `pendingImportSource` (`ContentView.swift:112-124`).
8. Paywall: `onChange(of: userSetCount)` shows `PaywallView(surface: .onboarding)` the moment the first user-made set is saved (`ContentView.swift:87-96`).

### 2. First generation
Entry points:
- **+** → `NewSetSheet`: Scan (primary), then Photo, PDF and Text (`LibraryView.swift:116-124`, `NewSetSheet.swift`).
- Library empty state: PDF, Scan, Text (`LibraryEmptyView.swift:51-64`).
- Onboarding source row.

The steps:
1. `presentPendingSource()` checks `canStartGeneration`. If the quota is spent it opens the paywall. If a draft is pending it shows the "Replace your draft?" alert. Otherwise it opens the scanner, photo picker, file importer or paste sheet (`ImportCoordinator.swift:75-104`).
2. **Scan**: `VNDocumentCameraViewController` in a sheet → `processOCR` (`ImportModifiers.swift:77-85`, `ImportCoordinator.swift:246-269`).
   **Photo**: `photosPicker` → `handleSelectedPhoto` (`ImportCoordinator.swift:301-328`).
   **PDF**: `fileImporter` → `processPDF` (`:271-299`).
   **Paste**: `PasteTextSheet` → **Generate cards** → `processPastedText` (`PasteTextSheet.swift:87-100`, `ImportCoordinator.swift:228-244`).
3. `GeneratingView` runs as a full-screen cover. The header reads "Scanning…", the stage reads "Reading page X of Y" then "Drafting cards", and there is a progress bar and a **Cancel** button (`GeneratingView.swift`).
4. `draftOrFail` → `StudyViewModel.makeDraft` → `DraftStore.set(draft)` → `navigateToReview = true` (`ImportCoordinator.swift:201-226`).
5. If any card has a `lineRange`, `ScanPreviewView` opens first. It walks through every card with its source highlighted, then **Review N cards** (`ImportModifiers.swift:36-57`, `ScanPreviewView.swift`). Otherwise `ReviewDraftsView` opens directly.
6. `ReviewDraftsView`: "Draft cards". Tap to edit, swipe to remove, **Regenerate**, then **Save** in the toolbar (`ReviewDraftsView.swift`).
7. Save inserts the `StudySet`, clears the draft and calls `dismiss()` (`ReviewDraftsView.swift:126-132`). The user lands on the **Library** grid, where the new tile shows "N DUE". For a first set, the onboarding paywall sheet opens immediately.
8. On failure, `ImportErrorView` shows **Edit text / Paste text** and **Try again** (`ImportErrorView.swift`, `ImportFailure.swift`).

### 3. First study session
1. Today: `todayCardCount > 0` → `SessionCard` ("TODAY'S SESSION", count, "cards · N min", **Start Session**) (`TodayView.swift:54-58`, `SessionCard.swift`).
2. `loadTodaySession()` → push `QuizSessionView(cards: flashcards)` (`SessionCard.swift:35-38,88-91`).
3. Per question: "Session · X of Y", a timer, a segmented bar, the set title, a **Why?** hint, the prompt, choices A–D, then **Submit** (`QuizSessionView.swift:34-168`).
4. Wrong answer: the prompt is replaced by "YOUR ANSWER" (red), "CORRECT" (green), the Why card with the source label, and "We'll surface this one again tomorrow." with **Undo**. Then **Next question** (`QuizSessionView.swift:81-110,143-154`).
5. After the last question the session is recorded → `SessionCompleteView`: "Nicely done", streak, CARDS/CORRECT/ACCURACY, NEEDS REINFORCEMENT, **One more session**, and **Done** at top right (`QuizSessionViewModel.swift:100-112`, `SessionCompleteView.swift`).
6. **Done** pops back to Today.

### 4. Free limit and devices without an on-device model
- **10/10 used**: **+** or the empty-state buttons → `canStartGeneration == false` → `PaywallView(surface: .exhausted)` (`LibraryView.swift:119-121`, `ImportCoordinator.swift:77-81`). `ImportFailure.quotaExhausted` only shows if the allowance runs out between the picker and drafting (`ImportCoordinator.swift:207-211`). The Today pill shows "0 of 10 free generations left · resets {date}" (`AICardsLeftView.swift:45-47`).
- **No Apple Intelligence**:
  1. Onboarding says drafting happens in the cloud.
  2. The first generation is the free hosted one (`StoreController.swift:27`, `AIController.swift:56-62`).
  3. After that, `isManualOnly = true`. The Library swaps the empty state for "ADD CARDS", and **+** opens `TypeCardsView` (`LibraryViewModel.swift:42-45`, `LibraryView.swift:55-57,106-121`).

### 5. Upgrading to Pro
Entry points:
- the Today pill's "Pro ›" (`TodayView.swift:33-35`)
- Settings → **Upgrade to QuickStudy Pro** (`SettingsView.swift:117-119`)
- the truncation notice (`ReviewDraftsView.swift:74-79`)
- the exhausted paywall
- the onboarding paywall

On purchase, `refreshEntitlement()` runs, then `dismiss()` (`PaywallView.swift:40-44`). What changes on screen:
- The Today pill turns teal: "QuickStudy Pro · 150 of 150 generations left this month".
- The paste sheet pill reads "QuickStudy Pro".
- The truncation notice is hidden.
- Settings shows "Active" with **Manage Subscription**.
- The Library leaves manual-only mode.

### Other states
- **Stats, first run**: "No stats yet" shows when there are no cards (`StatsView.swift:19-33`).
- **Library, empty**: "Build your first set" plus three sources and a tip (`LibraryEmptyView.swift`).
- **Crash-recovered draft**: `PendingDraftRow` with **Resume** / **Discard**, shown in the Library only (`LibraryView.swift:40-51`).

### Does Today's single Start Session CTA lead the experience?

| State | What Today shows | Verdict |
|---|---|---|
| Brand-new, zero sets (source path, or skipped/cancelled import) | "All caught up" / "No cards due today. New ones unlock as your review cycle picks back up." No button. No pill (`showsGenerationsPill` is false). Only the gear. | **Fails.** Dead end with a misleading message (UX-001). |
| Brand-new, demo path | 9 demo cards due, SessionCard, a seeded WEAKEST CARD ("Missed 3 times — drill"), and SUGGESTED | The CTA leads, but seeded history and a live generation offer compete with it (UX-006, UX-032). |
| Sets, nothing due | "All caught up" + **Practice anyway** + UP NEXT rows | The CTA is reasonable, but it quizzes the entire library (UX-019). |
| Due cards | Pill → date/streak → SessionCard → WEAKEST CARD (looks tappable, is not) → SUGGESTED | Start Session leads visually. Secondary rows add a fake affordance and a costly one-tap generation (UX-013, UX-006). |
| Just saved a first set | The user is in the Library, not Today, with no prompt to study (UX-020). | The CTA is never reached from the create flow. |

---

## Findings

### UX-001
- **Severity:** High
- **File:** `Views/Today/TodayView.swift:54-56`, `Views/Today/Components/TodayEmptyView.swift:45-64`
- **Problem:** A user with zero sets sees "All caught up" with no action, and nowhere to go except the gear.
- **Evidence:** `if todayViewModel.todayCardCount == 0 { TodayEmptyView() }`. The empty view shows `"All caught up"` and `"No cards due today. New ones unlock as your review cycle picks back up."`. **Practice anyway** only appears when `hasReviewableCards`. CLAUDE.md: "Empty states describe the next action; they never apologize".
- **Fix:** Add a separate zero-sets state when `savedSets.isEmpty`. It should name the next action, for example a create CTA that sets `appState.selectedTab = .library` and opens the New Set sheet. Keep "All caught up" for users who have sets but nothing due.
- **Effort:** S

### UX-002
- **Severity:** High
- **File:** `Views/Import/ImportModifiers.swift:98-100`, `Views/Import/ImportCoordinator.swift:234-243,247-264`
- **Problem:** **Cancel** on the Generating screen hides the cover, but generation keeps running. The user is later pushed into Review without warning, and the generation is still counted.
- **Evidence:** `GeneratingView(stage:) { coordinator.showGenerating = false }`. The unstored `Task { await coordinator.processPastedText(...) }` keeps running, and `draftOrFail` then sets `navigateToReview = true`. `makeDraft` records the allowance (`StudyViewModel.swift:274`).
- **Fix:** Keep the generation `Task` in the coordinator. Cancel it from `onCancel`, and check `Task.isCancelled` before `draftStore.set` and navigation. Do not record the allowance on a cancelled run.
- **Effort:** M

### UX-003
- **Severity:** High
- **File:** `Views/Review/Components/TruncationNoticeRow.swift:20,24`, `State/StudyViewModel.swift:266`, `Models/AI/Engine/OnDeviceCardGenerationEngine.swift:77-91`
- **Problem:** Any on-device draft over 1,200 characters shows "Only the first 1,200 characters were used" and a Pro upsell. The engine actually drafts the whole document in chunks.
- **Evidence:** `lastGenerationWasTruncated = engine.sourceChunkLimit.map { text.count > $0 }`, but `generateCards` loops `for chunk in chunks { allCards += try await cards(for: chunk) }`. So the claim and its upsell are false: a misleading pre-purchase statement.
- **Fix:** Remove the notice. Or only set `wasTruncated` if an engine really drops text. If kept, reword it truthfully (for example, drafted in sections on this iPhone).
- **Effort:** S

### UX-004
- **Severity:** High
- **File:** `Models/Import/ImportFailure.swift:98`, `Views/Paywall/Components/PaywallHeaderView.swift:23`
- **Problem:** Pro is sold as having no cap in one place and a 150/month cap in another.
- **Evidence:** The quota tip reads `"QuickStudy Pro generates without a monthly cap, on any iPhone."`. The paywall row uses `symbol: "infinity"` with the text `"\(ProProduct.hostedMonthlyLimit) generations a month"` (150).
- **Fix:** Use "150 generations a month" in the quota tip. Replace the `infinity` symbol with a neutral one.
- **Effort:** S

### UX-005
- **Severity:** High
- **File:** `Views/Library/Components/AddCardsSection.swift:51`, `Views/Today/TodayViewModel.swift:84-85`, `Views/Today/Components/AICardsLeftView.swift:45-47`
- **Problem:** Devices without Apple Intelligence are told AI generation is impossible, while Today says they have 10 free generations left.
- **Evidence:**
  - AddCardsSection: `"AI card generation needs an iPhone with Apple Intelligence (iPhone 15 Pro or later)."` This contradicts Pro's "Works on every iPhone".
  - `canGenerate = isPro || !GenerationAllowance.isExhausted` ignores device capability.
  - The hosted engine never records against the allowance, so the pill reads `"10 of 10 free generations left this month"` for good.
  - `PasteTextSheet.swift:40` shows the same count.
- **Fix:**
  - Build `canGenerate` and the pill from the same capability as `LibraryViewModel.isManualOnly`.
  - On manual-only devices, show the pill as "Generate on any iPhone with Pro ›".
  - Reword AddCardsSection to offer Pro.
- **Effort:** M

### UX-006
- **Severity:** High
- **File:** `Views/Today/TodayViewModel.swift:123`, `Views/Today/Components/SuggestionRow.swift:35,46-48`, `Models/AI/Engine/AIController.swift:23,57`
- **Problem:** The SUGGESTED row labels generation "on-device" even when it goes to QuickStudy's server. For a new demo user, one tap on "Yes" also uses up the one free hosted generation on 3 demo cards.
- **Evidence:**
  - `engineLabel: mode == .onDevice ? "on-device" : "API"`.
  - `makeGenerator` returns `HostedCardGenerationEngine` whenever `store.willUseHostedGeneration`, which covers Pro users and anyone whose free generation is unspent.
  - The onboarding demo set has due cards with `missCount` (`DemoData.swift:37`), so the row appears on day one.
  - Cards are appended without review (`StudyViewModel.swift:330`).
- **Fix:**
  - Build the label from `store.willUseHostedGeneration` ("cloud · not stored").
  - Hide the suggestion for demo sets and while the free hosted generation is unspent.
  - Route the new cards through `ReviewDraftsView`.
- **Effort:** M

### UX-007
- **Severity:** High
- **File:** `Models/Import/ImportFailure.swift:97`, `Views/Onboarding/Components/OnboardingAIIntroPage.swift:52`, `Views/Library/LibraryView.swift:106-124`
- **Problem:** Users are sent to "type cards by hand from the Library", but typed cards are only reachable on manual-only devices.
- **Evidence:** The quota tip reads `"Type cards by hand from the Library in the meantime."` and onboarding says `"Manual cards and every study mode are always unlimited."`. However, `TypeCardsView` opens only `if libraryViewModel.isManualOnly`. For AI-capable users at 10/10, **+** opens the paywall. The app also has only one study mode (MC).
- **Fix:** Expose **Type cards** to every user, in NewSetSheet and when the allowance is exhausted. Drop "every study mode".
- **Effort:** S

### UX-008
- **Severity:** High
- **File:** `Views/Import/ImportModifiers.swift:36-57`, `Views/Review/ReviewDraftsView.swift:126-132`, `Views/Library/LibraryView.swift:40-42`
- **Problem:** In the Scan Preview path, Save can leave `navigateToReview` stuck at `true`. This risks an empty pushed screen, hides `PendingDraftRow`, and can block the next push to Review. Needs verification on a device.
- **Evidence:**
  - `save()` calls `draftStore.set(nil); dismiss()`. `dismiss()` pops only the inner `previewConfirmed` destination.
  - The outer destination body is `if let draft = draftStore.pending { ... }`, which is now empty.
  - `navigateToReview` is only set to false in `onCancel` (grep: `ImportModifiers.swift:44`).
  - The next `draftOrFail` sets `navigateToReview = true` again, which is a no-op when it is already true.
- **Fix:** Pass an `onSaved` closure from the coordinator. It should reset `previewConfirmed` and `navigateToReview` together, then clear the draft.
- **Effort:** S

### UX-009
- **Severity:** High
- **File:** `Views/Quiz/QuizSessionView.swift:102`, `Views/Quiz/Components/ReinforcementRow.swift:20`, `Models/Scheduling/ReviewSchedule.swift:15,27-29`
- **Problem:** A wrong answer promises the card comes back "tomorrow", but box 0/1 cards are due again today. Right after the first session, Today still shows them as due.
- **Evidence:** `"We'll surface this one again tomorrow."` and `"Missed \(item.missed) · review tomorrow"`. However, `demote` is `max(box - 2, 0)` and `intervalDays[0] == 0`, so `newDueDate` is today. Every card in a new set starts in box 0.
- **Fix:** Pick one. Either make a missed card due tomorrow (interval ≥ 1 after a miss), or make the copy match the schedule ("You'll see this again later today").
- **Effort:** S

### UX-010
- **Severity:** High
- **File:** `Views/Onboarding/Components/OnboardingAIIntroPage.swift:42,47,69`, `Views/Onboarding/Components/OnboardingCameraPage.swift:27`
- **Problem:** Onboarding makes conflicting privacy promises on the same screen and the one after it.
- **Evidence:**
  - Rows: `"Your free generations run on-device and never leave it."` and `"Works offline"`.
  - Footnote on the same page: `"Your first set is drafted in the cloud with our best model"`.
  - Camera page: `"Photos are read on this iPhone and never uploaded."` But the text from the first scan is sent to the server (`StoreController.swift:27`), and a first generation made offline fails.
- **Fix:** State it once, in order: "Your first set is drafted in the cloud (not stored). After that, generation runs on this iPhone and works offline." Remove "never uploaded" from the camera page, or reword it to "your photos stay on this iPhone; only the text is sent for your first set".
- **Effort:** S

### UX-011
- **Severity:** Medium
- **File:** `Views/Review/ScanPreviewView.swift:22,72`, `Views/Import/ImportModifiers.swift:42-45`
- **Problem:** **Cancel** on Scan Preview deletes the draft immediately, with no confirmation. It is also the only way out, because the back button is hidden.
- **Evidence:** `onCancel: { draftStore.set(nil); coordinator.navigateToReview = false }` and `.navigationBarBackButtonHidden()`. `PendingDraftRow` asks before the same discard: "This used one of your free generations."
- **Fix:** Add the same confirmation alert. Alternatively, make Cancel keep the draft (it reappears as `PendingDraftRow`) and offer Discard separately.
- **Effort:** S

### UX-012
- **Severity:** Medium
- **File:** `Views/Import/ImportModifiers.swift:38-57`, `Views/Review/ScanPreviewView.swift:45-66`
- **Problem:** Every source goes through two full card walkthroughs, Scan Preview and then Review, before Save. For paste, the preview also shows "1 page".
- **Evidence:** The preview shows `if draft.cards.contains(where: { $0.source?.lineRange != nil })`, regardless of source type. Each card is paged one by one before **Review N cards**.
- **Fix:** Show the preview only for `.scan`/`.photo`/`.pdf`. Or move the source highlight into Review (tap a source pill to show the excerpt) and cut the preview step.
- **Effort:** M

### UX-013
- **Severity:** Medium
- **File:** `Views/Today/TodayView.swift:66`, `Views/Today/Components/WeakestCardRow.swift:30,37`
- **Problem:** The WEAKEST CARD row has a chevron and says "drill", but tapping it does nothing.
- **Evidence:** `WeakestCardRow(weakest: weakest)` is not wrapped in a Button or NavigationLink. It shows `"Missed \(n) times — drill"` and `Image(systemName: "chevron.right")`.
- **Fix:** Make it open a one-card (or weak-cards) `QuizSessionView`. Otherwise remove the chevron and "— drill".
- **Effort:** S

### UX-014
- **Severity:** Medium
- **File:** `Views/Quiz/QuizSessionView.swift:81-135`
- **Problem:** After Submit, the question disappears, so the wrong-answer screen shows two answers with no question.
- **Evidence:** `Text(question.prompt)` is only in the `else` branch of `if case let .revealed(correct) = phase`.
- **Fix:** Keep the prompt, compact, above the ResultCards in the revealed state.
- **Effort:** S

### UX-015
- **Severity:** Medium
- **File:** `Views/Quiz/QuizSessionView.swift:59-79`
- **Problem:** **Why?** is available before answering and shows the source excerpt, which usually contains the answer.
- **Evidence:** `if quizSessionViewModel.showsHint, let excerpt = question.source?.excerpt { Text(excerpt) }` can be toggled during `.answering`. The excerpt is the matched source lines (`CardSourceLocator.swift:33`).
- **Fix:** Before submit, show only the location (`source.shortLabel`) as the pill, and keep the excerpt for the revealed state. If a hint is wanted, make it a separate, weaker hint.
- **Effort:** S

### UX-016
- **Severity:** Medium
- **File:** `Views/Quiz/QuizSessionViewModel.swift:81-112`, `Views/Quiz/QuizSessionView.swift:177-183`
- **Problem:** Leaving a session midway with Back keeps the box changes but discards the session, so it never counts toward the streak. There is no warning.
- **Evidence:** `submit` calls `study.recordAnswer` for each answer. `sessions.record(session)` only runs in `advance` after the last question. The view shows the default back button.
- **Fix:** Record the partial session when the view disappears if there are any results, or confirm before leaving.
- **Effort:** S

### UX-017
- **Severity:** Medium
- **File:** `Views/Quiz/QuizSessionView.swift:186-188`, `Views/Quiz/SessionCompleteView.swift:76-77`
- **Problem:** **One more session** repeats the same cards using box values captured at the start. The user can push a new card from box 0 to "Mastered" in minutes.
- **Evidence:** `start()` calls `sessionQuestions(for: cards)` with the `let cards` from navigation. `promote` adds 1 per correct answer, with no same-day guard. `boxBefore` comes from the stale array, so Undo restores the wrong box.
- **Fix:** Rebuild the next session from what is currently due (`loadTodaySession`). Offer "Practice again" only as a practice mode that does not reschedule.
- **Effort:** M

### UX-018
- **Severity:** Medium
- **File:** `Views/Library/LibraryView.swift:119-121`, `Views/Import/ImportCoordinator.swift:77-81`
- **Problem:** At 10/10, **+** opens the generic Pro paywall with no explanation that the free generations are used up, or when they reset.
- **Evidence:** `else if !coordinator.canStartGeneration { coordinator.presentPaywall() }`. `PaywallHeaderView` has no quota or reset copy. The explanatory `quotaExhausted` screen ("They reset on …") is only reachable in a race.
- **Fix:** Show the `quotaExhausted` screen first, with an "Upgrade" recovery and a "Type cards" recovery. Or pass the reset date into the paywall header for `surface == .exhausted`.
- **Effort:** S

### UX-019
- **Severity:** Medium
- **File:** `Views/Today/Components/TodayEmptyView.swift:54-58,89-91`
- **Problem:** **Practice anyway** quizzes every card in the library, with no cap, and every answer reschedules not-yet-due cards.
- **Evidence:** `QuizSessionView(cards: studyViewModel.savedSets.flatMap(\.cards))`. `loadTodaySession()` is called but its result is not used here.
- **Fix:** Cap it (for example, the 10–20 cards due soonest) and label the count. Consider practice that does not reschedule.
- **Effort:** S

### UX-020
- **Severity:** Medium
- **File:** `Views/Review/ReviewDraftsView.swift:126-132`
- **Problem:** After saving, the user is back in the Library with no prompt to study. The core loop (create → study) breaks at its most motivated moment.
- **Evidence:** `save()` inserts, then `dismiss()`. There is no navigation to Today or a quiz. For first sets the paywall sheet then covers the screen.
- **Fix:** After Save, offer "Study N cards now" (push `QuizSessionView(cards: set.cards)`) or switch to Today. Show the onboarding paywall after that first session, not on Save.
- **Effort:** M

### UX-021
- **Severity:** Medium
- **File:** `Views/Import/ImportCoordinator.swift:240,264,324`, `Views/Review/ReviewDraftsView.swift:33-41`
- **Problem:** Scan, photo and paste sets are all given generic titles, and Review offers no way to name them.
- **Evidence:** `title: "Pasted Notes"`, `"Scanned Document"`, `"Photo"`. The Review header shows `draft.title` as plain `Text`. Renaming only exists in the Library tile's long-press context menu.
- **Fix:** Make the title editable in Review. Seed it from the first heading line or from `ContentAnalysis`.
- **Effort:** S

### UX-022
- **Severity:** Medium
- **File:** `Models/Study/CardSourceLocator.swift:60-66`, `State/StudyViewModel.swift:487-491`
- **Problem:** Every source pill shows "¶1", so the pill does not help anyone find the source.
- **Evidence:** `paragraphIndex` counts blank lines, but `normalizeOCRLines` drops every empty line (`if !trimmed.isEmpty { rawLines.append(trimmed) }`). Single-page scans and pastes have `pageBreaks == nil`, so the pill is just `"¶1"`.
- **Fix:** Keep paragraph boundaries through normalisation (for example, store paragraph starts next to `pageBreaks`). Otherwise drop the ¶ part and show only the page.
- **Effort:** M

### UX-023
- **Severity:** Medium
- **File:** `Views/Review/Components/DraftCardRow.swift:17-22`, `Views/Review/ReviewDraftsView.swift:101-102`
- **Problem:** A user can clear a card's question or answer inline and still save it. The result is blank quiz questions and blank choices.
- **Evidence:** The `TextField`s bind directly to `card.question`/`card.answer`. Save is only disabled when `draft.cards.isEmpty`.
- **Fix:** Drop or block cards with empty fields on Save, and mark them inline.
- **Effort:** S

### UX-024
- **Severity:** Medium
- **File:** `Views/Review/ReviewDraftsView.swift:46-48,134-144`
- **Problem:** **Regenerate** replaces every card, including the user's edits and removals, with no confirmation and no undo.
- **Evidence:** `Button("Regenerate") { Task { await regenerate() } }` → `draft.cards = cards`.
- **Fix:** Confirm first when the draft has been edited ("Replace N cards? Your edits will be lost.").
- **Effort:** S

### UX-025
- **Severity:** Medium
- **File:** `Views/Today/Components/OfflineBanner.swift:19,23`, `Views/Today/TodayView.swift:29`, `Models/AI/Engine/AIController.swift:22-24`, `Views/Settings/SettingsView.swift:83-86`
- **Problem:** The offline banner only appears in External API mode. It tells users to switch to "On-Device", but Pro users with "On-Device" selected still generate on the server.
- **Evidence:** `if !networkMonitor.isOnline && aiSettings.mode == .externalAPI`. The banner says `"Switch to On-Device in Settings to keep generating"`. But `case .onDevice: if let hosted = hostedEngine(...) { return hosted }`, and the picker option is labelled `"On-Device"`.
- **Fix:**
  - Show the banner whenever `store.willUseHostedGeneration` or the mode is External API.
  - For Pro, fall back to on-device when offline if a model is available, or say generation needs a connection.
  - Relabel the picker for Pro (for example, "QuickStudy Pro (cloud)").
- **Effort:** M

### UX-026
- **Severity:** Medium
- **File:** `State/StudyViewModel.swift:231-251`, `Models/AI/Engine/CardGenerationError.swift:76-81,130`
- **Problem:** Hosted failures (offline, Pro quota of 150 used, server down) end on the generic "Something went wrong" screen with **Try again**, even when retrying cannot work. There is no on-device fallback.
- **Evidence:** Only `catch CardGenerationError.notSubscribed` falls back to on-device. `hostedQuotaExhausted` and `networkError` go to `ImportFailure.generation` (title `"Something went wrong"`, recoveries `[.pasteText, .tryAgain]`).
- **Fix:** When the device has a model, fall back to on-device for `networkError`/`hostedUnavailable`/`hostedQuotaExhausted`, and tell the user. Give `hostedQuotaExhausted` its own failure with the reset date and no Try again.
- **Effort:** M

### UX-027
- **Severity:** Medium
- **File:** `Views/Import/ImportCoordinator.swift:106-108`, `Views/Library/LibraryViewModel.swift:42-45`
- **Problem:** If Apple Intelligence is turned off or still downloading, the user only finds out after capturing, OCR and the wait.
- **Evidence:** `canStartGeneration` only checks the allowance. `refreshCapability` only handles `.unsupportedDevice`, and `.needsSetup` is ignored. The error `"Turn on Apple Intelligence in Settings…"` appears at the end, from `generateCards`.
- **Fix:** Check `AICapability.state` in `presentPendingSource`. For `.needsSetup(message)`, show the message and an "Open Settings" action before capture. Skip this check when the next run is hosted.
- **Effort:** S

### UX-028
- **Severity:** Medium
- **File:** `Views/Scan/ScannerCoordinator.swift:22-24`
- **Problem:** A scanner error closes the camera without any message, which looks exactly like the user cancelling.
- **Evidence:** `didFailWithError error: Error) { Task { @MainActor in self.parent.onCancel() } }`. This breaks the rule "All error states must be handled — no silent failures".
- **Fix:** Add an `onError` path that shows `ImportFailure.processing(message:code:)` with a new code.
- **Effort:** S

### UX-029
- **Severity:** Medium
- **File:** `Views/Import/ImportModifiers.swift:79-82`, `Views/Library/Components/PasteTextSheet.swift:88-90`, `Views/Import/ImportCoordinator.swift:73-74,137-138`
- **Problem:** The Generating cover is presented while the scanner or paste sheet is still closing. The coordinator's own comments say this drops the presentation, which would leave no progress feedback. Needs verification on a device.
- **Evidence:** `onComplete: { images in coordinator.showScanCapture = false; Task { await coordinator.processOCR(...) } }`. `processOCR` sets `showGenerating = true` straight away. The paste sheet calls `dismiss(); onSubmit(pasted)` and then `showGenerating = true`. Compare the coordinator's own comment: "Presenting a sheet while another is dismissing drops the second one".
- **Fix:** Start processing from the sheet's `onDismiss`, the same way the source picker does.
- **Effort:** S

### UX-030
- **Severity:** Low
- **File:** `Views/Import/GeneratingView.swift:21`
- **Problem:** The header says "Scanning…" for PDF and pasted text too.
- **Evidence:** `Text("Scanning…")` is unconditional. Paste enters `.drafting` directly.
- **Fix:** Make the header depend on the source ("Reading PDF…", "Drafting cards"), or just say "Drafting".
- **Effort:** S

### UX-031
- **Severity:** Low
- **File:** `Views/Library/Components/PendingDraftRow.swift:66`
- **Problem:** The discard warning always claims the draft "used one of your free generations", which is wrong for hosted and Pro drafts.
- **Evidence:** `"The \(n) drafted cards will be deleted. This used one of your free generations."`
- **Fix:** Drop the second sentence, or base it on the engine that produced the draft.
- **Effort:** S

### UX-032
- **Severity:** Low
- **File:** `Models/Demo/DemoData.swift:37`, `Views/Today/TodayView.swift:59-67`
- **Problem:** A brand-new demo user sees "WEAKEST CARD · Missed 3 times — drill" before they have ever answered anything.
- **Evidence:** `box: 1, dueInDays: 0, missCount: 3` is seeded as the user's own history.
- **Fix:** Seed demo cards with `missCount: 0`, or exclude `isDemo` sets from weakest-card and suggestion logic.
- **Effort:** S

### UX-033
- **Severity:** Low
- **File:** `Views/Settings/SettingsView.swift:133`, `Views/Onboarding/Components/OnboardingFirstSourcePage.swift:32`
- **Problem:** The copy gives two different counts of sample sets.
- **Evidence:** Settings says `"Adds three example sets…"`. Onboarding says `"4 sample sets — …"`. `DemoData` seeds four.
- **Fix:** Change Settings to "four".
- **Effort:** S

### UX-034
- **Severity:** Low
- **File:** `Views/Library/Components/LibraryEmptyView.swift:51-64`, `Views/Library/Components/NewSetSheet.swift:58-71`, `Views/Onboarding/Components/OnboardingFirstSourcePage.swift:49-57`
- **Problem:** The three create surfaces list different sources in different orders. Photo is missing from the empty state and from onboarding.
- **Evidence:** The empty state is PDF, Scan, Text. NewSetSheet is Scan, then Photo, PDF, Text. Onboarding is Scan, PDF, Paste.
- **Fix:** Match NewSetSheet everywhere (Scan primary; Photo, PDF, Text).
- **Effort:** S

### UX-035
- **Severity:** Low
- **File:** `Views/Stats/StatsView.swift:27`, `Views/Stats/StatsViewModel.swift:36`
- **Problem:** The empty-state copy asks for a finished session, but stats appear as soon as a set is saved.
- **Evidence:** `"Save a set and finish a session to start tracking your progress."` versus `hasData: Bool { scheduledCards > 0 }`.
- **Fix:** Show stats after the first session (use `SessionStore`), or change the copy to "Save a set to start tracking".
- **Effort:** S

### UX-036
- **Severity:** Low
- **File:** `Views/Quiz/SessionCompleteView.swift:28`
- **Problem:** "Nicely done" shows even at 0% accuracy.
- **Evidence:** `Text("Nicely done")` is unconditional.
- **Fix:** Vary the headline by accuracy (for example, "Session complete" below a threshold).
- **Effort:** S

### UX-037
- **Severity:** Low
- **File:** `Views/Review/ReviewDraftsView.swift:101`
- **Problem:** The Save button says "Save". CLAUDE.md's Final v2 copy is "Save 12 cards", and `TypeCardsView` already uses "Save N cards".
- **Evidence:** `Button("Save") { save() }` versus `TypeCardsViewModel.saveLabel`, which returns `"Save \(count) cards"`.
- **Fix:** Use "Save \(draft.cards.count) cards" (and "Save 1 card").
- **Effort:** S

### UX-038
- **Severity:** Low
- **File:** `Views/Import/ImportModifiers.swift:24`
- **Problem:** The "scanner unavailable" alert talks about the simulator, even on real devices where `VNDocumentCameraViewController.isSupported` is false.
- **Evidence:** `"Document scanning isn't available in the simulator. Try on a real device."`
- **Fix:** Use device-neutral copy ("This device can't scan documents. Try Photo or PDF instead.") with a Photo action.
- **Effort:** S

### UX-039
- **Severity:** Low
- **File:** `Views/Library/LibraryView.swift:40-51`
- **Problem:** A crash-recovered draft only appears in the Library. Today does not mention it, although Today is the launch tab.
- **Evidence:** `PendingDraftRow` is rendered only in `LibraryView`. `TodayView` does not read `DraftStore`.
- **Fix:** Show a compact "Finish reviewing N drafted cards" row on Today when `draftStore.pending != nil`.
- **Effort:** S

### UX-040
- **Severity:** Low
- **File:** `Views/Paywall/PaywallView.swift:40-44`
- **Problem:** A successful purchase just closes the sheet, with no confirmation of what Pro unlocked.
- **Evidence:** `if store.isPro { dismiss() }`. The only visible change is the pill colour on Today.
- **Fix:** Show a short confirmation ("Pro is active · 150 cloud generations a month") before or after dismissing.
- **Effort:** S

---

## Counts

| Severity | Count |
|---|---|
| Blocker | 0 |
| High | 10 |
| Medium | 19 |
| Low | 11 |

---

## Verified (checks that passed)

- **Drafts are kept by default.** There is no approval gate. Swipe-left Remove is on every draft row (`ReviewDraftsView.swift:85-91`).
- **Crash-recovered drafts come back.** `DraftStore` loads `PendingDraft.json` on init, and `PendingDraftRow` offers Resume or Discard with a confirmation (`DraftStore.swift:27-41`, `PendingDraftRow.swift:62-67`).
- **A new import never silently overwrites a pending draft.** The "Replace your draft?" alert gates it (`ImportCoordinator.swift:84-87`).
- **The paste sheet's privacy footer is correct.** It tracks the engine that will actually run (`PasteTextSheet.swift:104-116`, `StoreController.swift:27`).
- **Generation failures keep the extracted text.** "Edit text" reopens the paste sheet pre-filled, and "Try again" re-drafts without re-capturing (`ImportCoordinator.swift:169-195,212-213`).
- **Error screens show a support code** (`ImportErrorView.swift:48-53`).
- **The paywall is Apple's `SubscriptionStoreView`**, with Restore, Terms and Privacy links, and it handles pending and failed purchases (`PaywallView.swift`).
- **The onboarding paywall is deferred until after the first set.** The pending flag is persisted, so it survives a kill (`ContentView.swift:87-91`, `OnboardingViewModel.swift:30-36`).
- **Onboarding tailors its copy to devices without Apple Intelligence** and never claims on-device drafting there (`OnboardingAIIntroPage.swift:25-31`).
- **Wrong answers show red and green side by side**, with the Why card, the source attribution and a working Undo (`QuizSessionView.swift:81-110`, `QuizSessionViewModel.swift:115-122`).
- **The quiz keeps the counter, progress bar and Submit pinned.** Only the body scrolls, and Submit is disabled until a choice is made (`QuizSessionView.swift:47-50,167`).
- **SessionCompleteView has everything CLAUDE.md lists.** Trophy, elapsed time, streak (with the "You beat yesterday" delta), CARDS/CORRECT/ACCURACY, NEEDS REINFORCEMENT, and "One more session" as the primary action.
- **Settings are reachable from Today's gear**, which is the approved deviation. The Today pill's "Pro ›" opens the paywall, and the pill turns teal for Pro (also approved).
- **No copy promises the unbuilt features** (notifications or reminders, theme clustering, typed answers, custom camera). A grep of `Views/` for notif/remind/theme/typed found no user-facing promises. The `"every study mode"` wording is covered in UX-007.
- **Library has a working empty state and filters.** "Build your first set" appears with no sets, and "No sets match this filter." is shown when a filter excludes everything (`LibraryView.swift:55-69`).
- **The Stats first-run state is present and describes the next action** (copy mismatch aside, UX-035).
