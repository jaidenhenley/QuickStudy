# QuickStudy — HIG Audit

**Branch:** jh/edgeCaseStates
**Scope:** tab bar, navigation/modality, sheets/detents, system materials, SF Symbols, standard vs. custom controls, Dark Mode, iPad layout, haptics, empty/loading/error states, destructive-action confirmation, alerts vs. inline errors, toolbar placement.
**Note:** Approved deviations from CLAUDE.md (Today's gear icon, teal `Pro ›` pill, no Edit in Today's empty state) are not flagged. Material rules (glass vs. flat, tinted pills) were only flagged where they diverge from an actual bug, not a Final v2 mock.

---

### HIG-001
**Severity:** High
**File:** `QuickStudy/Views/Import/ImportModifiers.swift:77-85`
**What's wrong:** The document scanner (`VNDocumentCameraViewController`, wrapping the system camera) is presented with `.sheet(isPresented:)` instead of `.fullScreenCover`.
**Evidence:**
```swift
.sheet(isPresented: $coordinator.showScanCapture) {
    DocumentScannerView(
        onComplete: { images in ... },
        onCancel: { coordinator.showScanCapture = false }
    )
}
```
A `.sheet` on iPhone renders as a card with a grab handle and standard swipe-to-dismiss enabled, with no `.presentationDetents` or `.interactiveDismissDisabled` set here to compensate. A live camera/multi-page capture is a hardware-driven, immersive task; HIG › Patterns › Modality calls for full-screen presentation for tasks like this so the system doesn't offer an accidental interactive dismissal path mid-capture (the user could swipe away and lose in-progress pages). The system's own document-scanner and camera pickers always present full-screen, so this reads as visually and behaviorally inconsistent with the OS convention it's built on.
**Proposed fix:** Present `DocumentScannerView` with `.fullScreenCover` (matching the two existing `fullScreenCover`s for `GeneratingView` and `ImportErrorView` in the same file), or explicitly disable interactive dismissal on the sheet if `.sheet` must be kept.
**Effort:** S

---

### HIG-002
**Severity:** Medium
**File:** `QuickStudy/Views/Today/TodayView.swift:46`
**What's wrong:** The streak affordance on Today uses a literal emoji glyph instead of the SF Symbol used for the same concept everywhere else in the app.
**Evidence:**
```swift
Text("🔥 \(todayViewModel.streakCount) day streak")
    .font(.subheadline)
    .fontWeight(.semibold)
    .foregroundStyle(.appStreak)
```
`StreakView.swift:27`, `StreakDayDot.swift:35`, and `SessionCompleteView.swift:37` all render the streak icon as `Image(systemName: "flame.fill")`. HIG › Foundations › SF Symbols (icons should use SF Symbols so they inherit weight, scale, and rendering mode consistently with the surrounding text) is violated here, and it's a functional bug, not just inconsistency: emoji glyphs render in their fixed native color and ignore `foregroundStyle`, so `.foregroundStyle(.appStreak)` has no visible effect on the 🔥 character — the intended tint is silently dropped.
**Proposed fix:** Replace the emoji with `Image(systemName: "flame.fill")` sized/aligned like the `Text`, matching `StreakView`'s treatment, so `.appStreak` tinting actually applies.
**Effort:** S

---

### HIG-003
**Severity:** Medium
**File:** `QuickStudy/Views/Streak/StreakView.swift:32-33`
**What's wrong:** The streak-count numeral uses a fixed-size font outside the two exceptions CLAUDE.md documents (the session card count, and a screen's large title).
**Evidence:**
```swift
Text("\(summary.current) \(summary.current == 1 ? "day" : "days")")
    .font(.system(size: 44, weight: .bold))
```
This is a primary piece of content on the Streak screen, not a page title or the Today session-card counter. HIG › Foundations › Typography requires Dynamic Type support so text scales with the user's chosen size; a user with a larger accessibility text size sees every other number on this screen (subtitle, week strip, longest-streak comparison) scale except this one.
**Proposed fix:** Use a semantic style (e.g. `.font(.largeTitle).fontWeight(.bold)`, or `.system(.largeTitle, design: .rounded).bold()`) instead of a fixed point size.
**Effort:** S

---

### HIG-004
**Severity:** Medium
**File:** `QuickStudy/Views/Review/Components/DraftCardRow.swift:53-54`
**What's wrong:** Tap-to-edit on a Review · Drafts row is implemented with `onTapGesture` on a `contentShape(Rectangle())` rather than a `Button`.
**Evidence:**
```swift
.padding(Spacing.base)
.appGlassCard(cornerRadius: AppRadius.lg)
.contentShape(Rectangle())
.onTapGesture { isEditing.toggle() }
```
This row sits in a `List` that also carries `.swipeActions(edge: .trailing)` (`ReviewDraftsView.swift:85`). A `Button` would give the row VoiceOver's `.isButton` trait, a system press/highlight state, and clearer separation between the row's tap target and the trailing swipe-action target. With `onTapGesture`, VoiceOver exposes the element as plain text with a generic activate action and no indication it toggles an edit state — the footer text "Tap to edit" (`ReviewDraftsView.swift:70`) is the only place this is communicated, and it isn't read aloud with the row. HIG › Foundations › Accessibility calls for interactive elements to be recognizable to assistive technologies; this is the Review screen CLAUDE.md marks highest priority, so the gap matters more here than elsewhere.
**Proposed fix:** Wrap the static (non-editing) content in a `Button { isEditing.toggle() }` with `.buttonStyle(.plain)`, keeping the `TextField`s outside the button when `isEditing` is true so editing focus isn't captured by the button's tap.
**Effort:** S

---

### HIG-005
**Severity:** Medium
**File:** `QuickStudy/Views/Library/LibraryView.swift:72-93`
**What's wrong:** The app declares iPad support (`TARGETED_DEVICE_FAMILY = "1,2"`, iPad-specific orientations in `audit/00-map.md` §1) but no layout in the codebase adapts to iPad's regular width class — confirmed by `grep` across `QuickStudy/Views` for `horizontalSizeClass`/`NavigationSplitView`/`UIDevice.current.userInterfaceIdiom`, which returns no matches.
**Evidence:**
```swift
LazyVGrid(
    columns: [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ],
    spacing: Spacing.md
) { ... }
```
The Library grid is hardcoded to exactly two columns regardless of available width. On iPad this stretches two tiles across the full screen width rather than adding columns, and the app-wide `TabView`/`NavigationStack` never offers the sidebar-style navigation iPad users expect at regular width. HIG › Foundations › Layout ("Adaptivity and layout") expects interfaces to respond to the available space rather than assume a phone-width layout everywhere.
**Proposed fix:** Compute grid column count from `horizontalSizeClass` (or available width via `GeometryReader`/adaptive `GridItem(.adaptive(minimum:))`), and evaluate whether Library/Today/Stats should present through `NavigationSplitView` at regular width. If iPad is not actually a target for this release, drop `"2"` from `TARGETED_DEVICE_FAMILY` instead of shipping an unadapted phone layout on iPad.
**Effort:** M

---

### HIG-006
**Severity:** Low
**File:** `QuickStudy/Views/Quiz/QuizSessionView.swift:131,158-160`
**What's wrong:** Haptic feedback generators are constructed and fired in the same expression, with no `prepare()` call ahead of the triggering event.
**Evidence:**
```swift
UISelectionFeedbackGenerator().selectionChanged()
...
UINotificationFeedbackGenerator().notificationOccurred(
    quizSessionViewModel.phase == .revealed(correct: true) ? .success : .error
)
```
HIG › Patterns › Playing Haptics recommends preparing a feedback generator before the event that will trigger it, since the Taptic Engine needs to spin up and an unprepared generator can introduce a perceptible delay between the tap and the haptic. Feedback *type* choice here is otherwise appropriate (selection for choice picking, notification success/error for submit outcome).
**Proposed fix:** Hold a single generator instance per interaction (or per view) and call `.prepare()` when the choice row/submit button becomes interactive, or migrate to SwiftUI's `sensoryFeedback(_:trigger:)` modifier, which handles preparation automatically.
**Effort:** S

---

## Verified

- **Tab bar:** Three tabs (Today/Library/Stats), each with a distinct SF Symbol and short label, all live and reachable; no more than five tabs, no programmatic tab-bar hiding. `ContentView.swift:27-51`.
- **Programmatic tab switching:** Only used from `finishOnboarding()` and `LibraryView.consumePendingSource()` to land the user on the tab their own action implies (e.g. choosing an import source); not used to yank focus mid-task elsewhere.
- **Destructive-action confirmation:** "Delete Set," "Delete All Study Sets," and the draft-replacement flow all confirm through `.alert` with `role: .destructive` before mutating state (`LibraryView.swift:152-158`, `SettingsView.swift:191-198`, `ImportModifiers.swift:26-35`).
- **Swipe actions:** Card removal in Review · Drafts uses the standard `.swipeActions(edge: .trailing)` with a `role: .destructive` `Button`, not a custom drag gesture (`ReviewDraftsView.swift:85-91`).
- **Standard controls:** Menus, toggles, and navigation elsewhere (`LibraryView` context menus, `SettingsView` toggles, `NavigationLink` for set tiles) use system components rather than reimplementations.
- **Colorsets:** Every named colorset in `Assets.xcassets` (`AppPrimary`, `AppSecondary`, `AppAIAccent`, `AppSuccess`, `AppDanger`, `AppWarning`, `AppStreak`, `AppBackground`, `AppSurface`, `AppTextPrimary`, `AccentColor`) declares a dark-mode variant.
- **Error states:** Import failures render through `ImportErrorView`, a full recovery screen (icon, title, message, tips, retry/paste-instead actions) rather than a dead-end alert (`ImportErrorView.swift`).
- **Loading state:** Generation progress uses a real `ProgressView(value:)` bound to computed fraction/elapsed time, with a visible Cancel action, not a bare spinner (`GeneratingView.swift`).
- **Toolbar placement:** Semantic placements used correctly — `.confirmationAction` for Save, `.cancellationAction` for Cancel, `.topBarTrailing` for the Settings gear — no ad hoc leading/trailing overrides.
- **Icon-only controls:** `FloatingCreateButton` supplies `.accessibilityLabel("New set")` and caps `.dynamicTypeSize` so a circular FAB doesn't break layout at largest accessibility sizes.

---

## Summary

**Counts by severity:** High: 1 · Medium: 4 · Low: 1 · Blocker: 0

**Top 5:**
1. HIG-001 (High) — camera capture presented as a dismissible `.sheet` instead of `.fullScreenCover`, risking accidental loss of an in-progress scan.
2. HIG-002 (Medium) — Today's streak row uses an emoji instead of `flame.fill`, silently breaking the intended `.appStreak` tint.
3. HIG-003 (Medium) — StreakView's streak-count numeral uses a fixed point size not covered by the two approved display-numeral exceptions, breaking Dynamic Type.
4. HIG-004 (Medium) — Review · Drafts row uses `onTapGesture` instead of `Button` for tap-to-edit, losing VoiceOver affordance on the highest-priority screen.
5. HIG-005 (Medium) — Library's set grid is hardcoded to two columns with no size-class/iPad adaptation despite the app targeting iPad.
