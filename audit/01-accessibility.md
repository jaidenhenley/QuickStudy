# QuickStudy — Accessibility Audit

Branch: `jh/edgeCaseStates`. Scope: VoiceOver, Dynamic Type, color contrast (WCAG AA), Reduce Motion / Reduce Transparency, Differentiate Without Color, tap targets, focus order.

Codebase-wide check: `grep -rn "accessibility\|dynamicTypeSize\|reduceMotion\|reduceTransparency" QuickStudy --include="*.swift"` returns hits in only **3** view files (`SetTile`, `FloatingCreateButton`, `SourceOptionButton`, `TypeCardRow`). Every other custom control in the app — including all of quiz, review, streak, and stats — has zero accessibility modifiers. That baseline drives most findings below.

---

## Findings

### A11Y-001 — Quiz choice selection is invisible to VoiceOver
**Severity:** Blocker
**File:** `QuickStudy/Views/Quiz/Components/QuizChoiceRow.swift:16-37`, called from `QuickStudy/Views/Quiz/QuizSessionView.swift:125-134`

The selected-answer state (`isSelected`) is conveyed only by fill color and font weight. The row is a plain `Button` with no `.accessibilityAddTraits(.isSelected)` and no value/label describing "selected" or "answer A". A VoiceOver user has no way to tell which choice is currently chosen before tapping Submit.

Evidence:
```swift
Button(action: action) {
    HStack(spacing: Spacing.md) {
        Text(letter)...
        Text(text)...
    }
    .appGlassCard(cornerRadius: AppRadius.lg, tint: isSelected ? Color.appPrimary.opacity(0.35) : nil)
}
.buttonStyle(.plain)
```
No `.accessibilityElement`, no `.accessibilityLabel`, no `.accessibilityAddTraits(isSelected ? .isSelected : [])`.

**Fix:** Add `.accessibilityElement(children: .ignore)`, `.accessibilityLabel("Option \(letter): \(text)")`, and `.accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)` (or use `Button` + `.accessibilityAddTraits(.isSelected)` conditionally — verify the exact selected-trait behavior on a device, since `.isSelected` on a `Button` trait is not officially documented as producing a "selected" announcement outside of `List`/segmented contexts).
**Effort:** S

---

### A11Y-002 — Correct/wrong result has no VoiceOver announcement or grouping
**Severity:** Blocker
**File:** `QuickStudy/Views/Quiz/QuizSessionView.swift:81-110`, `QuickStudy/Views/Quiz/Components/ResultCard.swift`

After Submit, the phase changes to `.revealed`, and `ResultCard` views appear showing "YOUR ANSWER" / "CORRECT" with color (red/green) and a symbol. There is no `UIAccessibility.post(notification: .announcement, ...)` and no `.accessibilityFocus` to move VoiceOver focus onto the result — a screen-reader user submits and hears nothing change; they have to manually swipe-explore to discover the outcome. `ResultCard` itself has no `.accessibilityElement(children: .combine)`, so its label/value/symbol are read as three separate stops on every visit.

Evidence: `ResultCard.swift:16-34` has no accessibility modifiers at all; `QuizSessionView.swift` has no `@AccessibilityFocusState` anywhere in the file (confirmed by the codebase-wide grep above).

**Fix:** Add `@AccessibilityFocusState private var resultFocused: Bool` in `QuizSessionView`, set it true when `phase` becomes `.revealed`, and give the container a combined accessibility element with a label like "Correct" / "Incorrect. Correct answer: …". Group `ResultCard` with `.accessibilityElement(children: .combine)`.
**Effort:** M

---

### A11Y-003 — Swipe-to-remove in draft review has no VoiceOver-accessible alternative action
**Severity:** Blocker
**File:** `QuickStudy/Views/Review/ReviewDraftsView.swift:81-92`

Card removal is exposed only via `.swipeActions(edge: .trailing)`. `swipeActions` does add a VoiceOver custom action automatically in most cases, but the row itself (`DraftCardRow`) has no accessibility label — it exposes `question`, `answer`, the source pill, and the edit/checkmark icon as four separate unlabeled elements, so a VoiceOver user has no coherent "card" element to attach the swipe action's context to, and the pencil/checkmark icon (line 46-48 of `DraftCardRow.swift`) is announced only as "Image" with no state description ("editing" vs "not editing").

Evidence:
```swift
// DraftCardRow.swift
Image(systemName: isEditing ? "checkmark" : "pencil")
    .font(.footnote)
    .foregroundStyle(.secondary)
```
No accessibility label/trait; the row's `.onTapGesture` (not a `Button`) is not exposed to VoiceOver as an activatable element at all — `onTapGesture` on a plain `VStack` does not get an accessibility "Button" trait or double-tap activation the way a `Button` does.

**Fix:** Replace `.onTapGesture` with a `Button(action:)` wrapping the card, or add `.accessibilityAddTraits(.isButton)` plus an explicit `.accessibilityAction`. Group the row with `.accessibilityElement(children: .combine)` and add `.accessibilityLabel("\(card.question). \(card.answer)")` plus `.accessibilityHint(isEditing ? "Editing" : "Double tap to edit")`. Add an explicit `.accessibilityAction(named: "Remove") { draft.remove(card.id) }` at the `ForEach` level so removal doesn't depend solely on the swipe gesture.
**Effort:** M

---

### A11Y-004 — Source pills, "Why?" hint button, and streak/stat controls are unlabeled
**Severity:** High
**Files:**
- `QuickStudy/Views/Review/Components/DraftCardRow.swift:32-44` (source pill)
- `QuickStudy/Views/Quiz/QuizSessionView.swift:59-70` ("Why?" button)
- `QuickStudy/Views/Quiz/Components/WhySourceCard.swift:28-35` (source link row)
- `QuickStudy/Views/Streak/Components/StreakDayDot.swift:14-31` (week strip dots)
- `QuickStudy/Views/Stats/Components/StatTile.swift`, `StatSetRow.swift`

None of these carry any `.accessibilityLabel`/`.accessibilityValue`. Concretely:
- The source pill (`Image(systemName: "link")` + `Text(source.shortLabel)`) reads as two elements: "Link" (image) then "p.3 ¶2" (text) — the abbreviation "p.3 ¶2" is also not expanded for VoiceOver, so it is announced letter/symbol-ish rather than "page 3, paragraph 2".
- `StreakDayDot` conveys "studied / frozen / missed / today / future" purely through fill color + an optional SF Symbol, with the weekday letter as the only text. VoiceOver reads "M" with no state ("studied", "missed", etc.).
- `StatTile`/`StatSetRow` split value and label into two `Text` views with no combining, so VoiceOver reads "72" then "cards · 5 min" as separate stops without context.

**Fix:** Add `.accessibilityElement(children: .combine)` + a synthesized `.accessibilityLabel` to each (e.g., `StreakDayDot`: `"\(fullWeekdayName): \(state.accessibilityDescription)"`; source pill: `.accessibilityLabel("Source: page \(page), paragraph \(paragraph)")`). Give `WhySourceCard`'s "Why" button an explicit `.accessibilityLabel("Why this answer, source page \(page)")` since "Why?" alone loses the source context once read out of visual position.
**Effort:** M

---

### A11Y-005 — Decorative images and icon-only affordances not hidden or labeled
**Severity:** Medium
**Files:** `QuickStudy/Views/Today/Components/TodayEmptyView.swift:19-43` (composite illustration of circles), `QuickStudy/Views/Library/Components/LibraryEmptyView.swift:15-39` (dashed-card illustration), `QuickStudy/Views/Quiz/QuizSessionView.swift:64` (`Image(systemName: "link")` next to "Why?"), `QuickStudy/Views/Quiz/Components/ResultCard.swift:18-19` (status symbol)

The multi-`Circle()`/`Image(systemName:)` illustrations in `TodayEmptyView` and `LibraryEmptyView` are purely decorative but are not marked `.accessibilityHidden(true)`, so VoiceOver will stop on each shape (6 in `TodayEmptyView` alone) with no label, reading "Image" repeatedly before ever reaching "All caught up". Status/decoration icons paired with adjacent text (the link glyph before "Why?", the checkmark/x-circle glyph in `ResultCard`) are likewise not hidden, duplicating the announcement already carried by the text/label.

**Fix:** `.accessibilityHidden(true)` on the decorative `ZStack` contents in both empty-state views; `.accessibilityHidden(true)` on symbol images that sit beside descriptive text and add nothing not already in the label.
**Effort:** S

---

### A11Y-006 — No Reduce Motion handling anywhere in the app
**Severity:** High
**Files:** `QuickStudy/Views/Quiz/QuizSessionView.swift:179` (`.animation(.default, value: quizSessionViewModel.phase)`), `QuickStudy/Views/Today/Components/SessionCard.swift:48-49,74` (`withAnimation` + `.transition(.opacity)`), `QuickStudy/Views/Quiz/QuizSessionView.swift:61` (`withAnimation` on hint toggle)

`@Environment(\.accessibilityReduceMotion)` does not appear anywhere in the codebase (confirmed by the grep). Every `withAnimation`/`.animation`/`.transition` call in the app runs unconditionally, including the phase-change animation on the quiz result reveal and the session-card breakdown disclosure. This is not a crash-level bug, but it is an unmet WCAG 2.3.3 (AAA, but Apple HIG treats Reduce Motion as a hard platform expectation) / Apple HIG requirement: none of these are large parallax/zoom effects, so severity is High rather than Blocker, but it is a real, verifiable gap, not speculative.

**Fix:** Read `@Environment(\.accessibilityReduceMotion) private var reduceMotion` in `QuizSessionView` and `SessionCard`, and pass `reduceMotion ? nil : .default` (or `.easeInOut(duration: 0)`) to the animation calls.
**Effort:** S

---

### A11Y-007 — No Reduce Transparency handling on any glass surface
**Severity:** High
**File:** `QuickStudy/Views/DesignSystem/Theme.swift:16-24` (`appGlassCard`, `appProminentButtonStyle`) and every call site (~30 files)

`appGlassCard` and `appProminentButtonStyle` always call `.glassEffect(...)` / `.buttonStyle(.glassProminent)` regardless of `UIAccessibility.isReduceTransparencyEnabled` / `@Environment(\.accessibilityReduceTransparency)`. Per CLAUDE.md, "the app is Liquid Glass" is load-bearing for nearly every card, row, tile, chip, and button in the app, so with Reduce Transparency on, every one of those surfaces still renders as translucent glass instead of falling back to an opaque fill — this is the single highest-leverage fix in the app because it's centralized in one helper, but currently unhandled.

Evidence:
```swift
func appGlassCard(cornerRadius: CGFloat = 16, tint: Color? = nil) -> some View {
    if let tint {
        self.glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
    } else {
        self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}
```
No branch checks reduce-transparency.

**Fix:** Add `@Environment(\.accessibilityReduceTransparency)` at each call site is impractical given ~30 call sites; instead make `appGlassCard`/`appProminentButtonStyle` read the environment via a wrapping `ViewModifier` struct (not a free function, since environment values require a `View`/`ViewModifier` context) and substitute an opaque `Theme.surface` (or `tint.opacity(0.9)` fill) background when reduce-transparency is on, per Apple's own SwiftUI `glassEffect` guidance that recommends checking this environment key.
**Effort:** M (one shared modifier, but touches the design-system contract described in CLAUDE.md — flag for design sign-off before implementing broadly)

---

### A11Y-008 — Mastery/DUE/correct-wrong states rely on color alone in several spots
**Severity:** Medium
**Files:** `QuickStudy/Views/Library/Components/SetTile.swift:16-25,44-52`, `QuickStudy/Views/Quiz/Components/SessionProgressBar.swift:14-30`, `QuickStudy/Views/Streak/Components/StreakDayDot.swift`

- `SetTile`'s "N DUE" badge and "Mastered" label are both accompanied by text (not color-only), so those two are fine (see Verified section) — but the **progress bar tint** (`Color.appPrimary` vs `Theme.success`) on the same tile carries mastery state with no text change at the exact moment it crosses into "mastered" for a viewer who only sees the small tinted bar without reading the label below it. This is Low/borderline; the label text right below it is the actual carrier of meaning so I count this pattern as passing overall, noting it only for completeness.
- `SessionProgressBar` (segmented per-question bar) encodes correct/wrong/current/upcoming **purely by fill color** (`Theme.success` / `Theme.danger` / `Color.appPrimary` / gray) with no shape, symbol, or accessibility value — a color-blind or VoiceOver user gets no way to know how many questions they got right by looking at/querying the bar. It also has no accessibility representation at all (not even hidden), so VoiceOver reads N unlabeled "Capsule" shapes.
- `StreakDayDot` differentiates "studied" vs "frozen" vs "today" primarily by fill hue (`.appStreak` vs `.appSecondary` vs `.appPrimary`, all at the same 0.18 opacity) with symbols only for studied/frozen — "today" and "missed"/"future" are color-only distinctions (same lack of a symbol, differing only in tint and opacity level).

**Fix:** Give `SessionProgressBar` segments a per-state accessibility value/label (or hide the whole bar and rely on `positionLabel`/state announcements elsewhere) and consider a subtle shape or symbol difference for the "current" segment. Add a distinguishing symbol or outline to the "today" state dot in `StreakDayDot`.
**Effort:** M

---

### A11Y-009 — Small tap targets under 44×44pt
**Severity:** Medium
**Files:**
- `QuickStudy/Views/Quiz/Components/QuizChoiceRow.swift:23` — the A/B/C/D letter circle is `26×26`, but it's inside the full-row `Button`, so the effective hit target is the whole row (fine). No violation there.
- `QuickStudy/Views/TypeCards/Components/TypeCardRow.swift:24-30` — "minus.circle" remove button uses `.font(.footnote)` with no explicit frame; the rendered glyph + default button hit box is well under 44×44 (a `.footnote` SF Symbol is roughly 13–15pt, and `.buttonStyle(.plain)` does not pad it to a minimum hit area).
- `QuickStudy/Views/Review/Components/DraftCardRow.swift:46-48` — the pencil/checkmark toggle icon has no frame and sits inside an `.onTapGesture` applied to the whole card, so its own hit box doesn't matter, but see A11Y-003 for why the gesture type itself is a problem.
- `QuickStudy/Views/Import/Components/ErrorRecoveryTipRow.swift` — not a tap target (informational row), no issue.
- `QuickStudy/Views/Today/TodayView.swift:93-97` — the gear/settings toolbar button has no explicit frame, but toolbar items get system-managed minimum touch targets, so this is not flagged.

**Fix:** Give `TypeCardRow`'s remove button an explicit `.frame(width: 44, height: 44)` (with `.contentShape(Rectangle())` so the visual glyph can stay small while the hit area meets 44pt).
**Effort:** S

---

### A11Y-010 — Focus order / focus movement not managed across Review, Quiz, and Session Complete
**Severity:** High
**Files:** `QuickStudy/Views/Review/ReviewDraftsView.swift`, `QuickStudy/Views/Quiz/QuizSessionView.swift`, `QuickStudy/Views/Quiz/SessionCompleteView.swift`

None of these three flows use `@AccessibilityFocusState` (confirmed by the codebase-wide grep — zero occurrences in the entire target). Concretely:
- In `ReviewDraftsView`, tapping a `DraftCardRow` swaps `Text` for `TextField`s in place (line 16-22 of `DraftCardRow.swift`), but VoiceOver focus is not moved to the newly-revealed `TextField("Question", ...)`, so a screen-reader user has to re-discover the field manually after every edit-toggle.
- In `QuizSessionView`, advancing to the next question (`quizSessionViewModel.advance`) scrolls a `ScrollView` whose content `.id(question.cardID)` changes, but nothing moves VoiceOR focus back to the top of the new question — a VoiceOver user continues from wherever they were located in the old question's now-replaced content, which is unpredictable.
- `SessionCompleteView` appears with no focus assignment to its "Nicely done" heading; VoiceOver lands wherever the system defaults (typically the first focusable element, which here is the "Done" button — auditorily and instructions-wise leading with the exit control rather than the result reads adversely against expectations, but this is inference rather than a hard rule, so kept at High rather than Blocker for this sub-point alone).

**Fix:** Add `@AccessibilityFocusState` bindings: focus the question `TextField` in `DraftCardRow` on entering edit mode; focus a hidden/heading element at the top of the question card in `QuizSessionView` on `advance()`; focus the "Nicely done" heading in `SessionCompleteView` on appear via `.accessibilityFocused(...)` + `.onAppear`.
**Effort:** M

---

### A11Y-011 — Color contrast: computed ratios

Method: WCAG relative luminance from each colorset's sRGB components (`L = 0.2126·R + 0.7152·G + 0.0722·B` on linearized channels, `lin(c) = c/12.92` if `c ≤ 0.04045` else `((c+0.055)/1.055)^2.4`), contrast `= (L₁+0.05)/(L₂+0.05)`. Source components taken directly from each `Contents.json` in `QuickStudy/Assets.xcassets/`.

| Pair | Light ratio | Dark ratio | AA needed | Result |
|---|---|---|---|---|
| `AppTextPrimary` on `AppBackground` | ~15.97:1 | ~15.86:1 | 4.5:1 (body) | Pass, wide margin |
| White on `AppPrimary` (e.g. `QuizChoiceRow` selected letter circle, `.appProminentButtonStyle` white label) | ~5.82:1 | computed with dark AppPrimary (0.447,0.435,0.976): ~4.9:1 | 4.5:1 | Pass (both modes), but dark-mode margin is thin (~4.9:1) for anything below ~14pt if weight is regular rather than semibold/bold — everywhere it's used it is bold/headline, so acceptable |
| `.appAIAccent` text on `AppBackground` (teal used for "Sent to QuickStudy's server", Pro-pill label) | teal L≈0.372 vs bg L≈0.889 → **~2.24:1** | teal dark (0.176,0.831,0.749) L≈0.489 vs bg dark L≈0.0035 → **~7.5:1** | 4.5:1 (normal), 3:1 (large/caption bold counts as "large text" only at ≥14pt bold or ≥18pt regular) | **Fail in light mode.** `.appAIAccent` is used at `.caption`/`.footnote` weight in `AICardsLeftView.swift:19-20`, `PasteTextSheet.swift:438-443`, `TruncationNoticeRow.swift:24-27` — none of these qualify as "large text", so 2.24:1 fails AA's 4.5:1 minimum for normal text in light mode by a wide margin. |
| `Theme.danger` text/icon on `AppBackground` (light: 1.0,0.176,0.333) | L≈0.297 vs bg 0.889 → **~2.75:1** | dark danger (1.0,0.216,0.373) L≈0.318 vs bg dark 0.0035 → **~5.66:1** | 3:1 (icon/graphic), 4.5:1 (text) | **Marginal/Fail in light mode** for text use (`Theme.danger` is used for the "×N" miss-count label text in `WeakestCardRow.swift:22` and `StatsView.swift:87`, both `.caption`/bold ~12-13pt — below the "large text" threshold), passing only the 3:1 non-text-UI-component minimum, not the 4.5:1 text minimum |
| `Theme.success` text on `AppBackground` (light: 0.204,0.773,0.349) | L≈0.469 vs bg 0.889 → **~1.85:1** | dark success (0.188,0.820,0.369) L≈0.485 vs bg dark 0.0035 → **~7.72:1** | 4.5:1 | **Fail in light mode.** Used as text color for "Mastered" (`SetTile.swift:47`, `StatSetRow.swift:25`) and stat tint (`StatTile` tint). ~1.85:1 is a severe failure — green-on-off-white body/caption text is close to unreadable for low-vision users in light mode. |

**Caveats stated explicitly, per instructions:**
1. `AppBackground`'s light variant is declared in **`display-p3`**, not `srgb`; the luminance math above treats its component numbers as if they were sRGB (the standard WCAG assumption), which is a reasonable approximation since P3 and sRGB primaries are close in the neutral off-white region used here, but it is an approximation, not an exact conversion.
2. `AppSecondary.colorset`'s **light** variant is declared in `color-space: "extended-linear-srgb"`, while its own dark variant and every other colorset in the project use `"srgb"`. This is an asset-catalog anomaly, not something I can verify by static read alone — if the color space tag is intentional, the stored component numbers (0x13/0x0F/0xC7, i.e. ~0.075/0.059/0.780) are *already linear light values*, which would render as a noticeably lighter/desaturated color than the same hex digits would under standard sRGB gamma encoding. I could not run the simulator to confirm the actual on-screen color, so I am flagging this as a build-verification item rather than asserting a specific contrast failure.
3. Apple's `.glassEffect()` blending algorithm (used for every `appGlassCard`/`appProminentButtonStyle` surface) is not publicly documented with an exact alpha/blend formula, so none of the ratios above account for the translucent glass background actually behind this text in the shipped UI — every ratio in the table is computed against the flat `AppBackground`/`AppSurface` color, which is the closest documented approximation but is very likely **more favorable** than the real, glass-composited background (glass surfaces typically lighten/lower contrast further in light mode by blending in blurred content). This means the light-mode failures above are floors, not worst cases.

**Fix:** Darken `AppAIAccent`, `AppDanger`, and `AppSuccess` for light-mode **text** use, or restrict them to large/bold text and non-text UI (badges, icons, progress fill) where the 3:1 threshold applies, and introduce separate "on-light-surface" text variants if the current hues must stay as brand/semantic colors for fills. At minimum, re-verify `AppSecondary`'s color-space declaration against design intent.
**Effort:** M (color changes) / S (verify AppSecondary color space)

---

### A11Y-012 — Fixed-size fonts: none found outside the permitted display numerals
No violations of the "fixed `.font(.system(size:))` outside display numerals" rule were found. All four occurrences (`TodayView.swift:27` "Today" large title, `StreakView.swift:34` streak-day count, `SessionCard.swift:28` session card count, `PaywallHeaderView.swift:12` decorative SF Symbol icon, not text) match either the CLAUDE.md-permitted display-numeral/large-title exception or are icon glyphs rather than Dynamic-Type-bearing text. Confirmed via `grep -rn "font(.system(size" QuickStudy`. No finding logged.

---

### A11Y-013 — `lineLimit(1)` truncation risk at large accessibility sizes
**Severity:** Medium
**Files:** `QuickStudy/Views/Review/ReviewDraftsView.swift:37` (draft title), `QuickStudy/Views/Library/Components/PendingDraftRow.swift:34` (draft title), `QuickStudy/Views/Today/Components/SuggestionRow.swift:38` (source title), `QuickStudy/Views/Today/Components/WeakestCardRow.swift:29`, `UpNextRow.swift:19`, `StatSetRow.swift:19` (all `.lineLimit(1)` on primary-content titles, not secondary metadata)

Each of these truncates the row's *primary* identifying text (a set/document title, not a decorative label) to a single line unconditionally. At AX5 Dynamic Type sizes, a title that would otherwise wrap to 2-3 lines is cut to a handful of characters plus ellipsis, and VoiceOver's spoken value still reads the full underlying string (so VoiceOver users are unaffected), but **sighted users relying on large text** lose the ability to distinguish between similarly-prefixed set/document titles. This is a "may truncate at accessibility sizes" pattern, not a crash or unreadable-value bug — logged as Medium because it's a real, code-verified constraint (`lineLimit(1)` is present and unconditional in every cited file) rather than a guess.

**Fix:** Use `.lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)` (reading `@Environment(\.dynamicTypeSize)`) or drop the limit and let `fixedSize(horizontal: false, vertical: true)` (already used elsewhere, e.g. `SetTile.swift:32`) handle wrapping within a bounded-height row.
**Effort:** S per file

---

### A11Y-014 — Fixed-height rows/frames that can clip wrapped text at large Dynamic Type sizes
**Severity:** Medium
**Files:** `QuickStudy/Views/Review/ScanPreviewView.swift:68` (`.frame(height: 228)` on the paging `TabView` holding `DraftedCardPreview`/`DraftedDeckSummary`), `QuickStudy/Views/Today/Components/AICardsLeftView.swift` letter circles / `QuickStudy/Views/Library/Components/SourceOptionButton` (fixed `44×44`/`36×36` icon frames are fine since they hold only an icon, not scaling text)

`ScanPreviewView`'s fixed `height: 228` wraps card preview content whose question/answer text (`DraftedCardPreview.swift:27-34`) has no line limit and uses `.fixedSize(horizontal: false, vertical: true)` — at AX5 sizes a longer question+answer pair will exceed 228pt and be clipped by the `TabView`'s fixed frame, since `TabView(.page)` does not grow to fit content; it clips.

**Fix:** Replace the fixed `height: 228` with a size that adapts to Dynamic Type (e.g., compute via `@ScaledMetric`, or switch the paging container to a non-fixed-height layout when `dynamicTypeSize.isAccessibilitySize`).
**Effort:** M

---

### A11Y-015 — HStacks that do not reflow to VStack at accessibility sizes
**Severity:** Medium
**Files:** `QuickStudy/Views/Today/TodayView.swift:37-52` (date + streak link row), `QuickStudy/Views/Quiz/QuizSessionView.swift:35-43` (position label + elapsed timer), `QuickStudy/Views/Review/ReviewDraftsView.swift:60-66` (header `HStack` with two `Text`s and a `Spacer`), `QuickStudy/Views/Today/Components/OfflineBanner.swift:13-34`

None of these use `ViewThatFits` or a `dynamicTypeSize`-gated `AnyLayout`/conditional `VStack`. Each packs two or more independently-scaling `Text` elements plus a `Spacer` into a fixed `HStack`; at AX5, this reliably produces either truncation (several already have `.lineLimit(1)`, compounding A11Y-013) or squeezed/overlapping layout since `HStack` does not wrap.

**Fix:** Wrap each in `ViewThatFits(in: .horizontal) { HStack {...}; VStack(alignment: .leading) {...} }`, or gate on `@Environment(\.dynamicTypeSize) var dynamicTypeSize` and switch container axis when `dynamicTypeSize.isAccessibilitySize`.
**Effort:** M (repeated pattern across ~4-6 files)

---

### A11Y-016 — Session-complete streak-emoji text is not localizable/accessible as an icon
**Severity:** Low
**File:** `QuickStudy/Views/Today/TodayView.swift:46` — `Text("🔥 \(todayViewModel.streakCount) day streak")`

The flame is baked into the string as an emoji character rather than an `Image(systemName: "flame.fill")` + text label (contrast with `SessionCompleteView.swift:37` and `StreakView.swift:27`, which correctly use `Image(systemName: "flame.fill")`). VoiceOver will read the emoji as "fire" ahead of the count, producing "fire 5 day streak" — inconsistent with the rest of the app and not decoratively hideable the way an `Image` would be.
**Fix:** Replace with the same `Image(systemName: "flame.fill").foregroundStyle(.appStreak)` + `Text("\(count) day streak")` pattern used elsewhere, with the image marked `.accessibilityHidden(true)`.
**Effort:** S

---

## Verified

- `SetTile` (`Views/Library/Components/SetTile.swift:57-58`) correctly groups its content with `.accessibilityElement(children: .combine)` and supplies a synthesized label.
- `FloatingCreateButton` has an explicit `.accessibilityLabel("New set")` and constrains `dynamicTypeSize` so the circular FAB doesn't break layout at AX sizes.
- `SourceOptionButton` supplies a combined `.accessibilityLabel` for its icon+title+subtitle stack.
- `TypeCardRow`'s remove button has an `.accessibilityLabel("Remove card \(index)")` (though its tap target is still small — see A11Y-009).
- The `DUE` badge and `Mastered` label on `SetTile` are both accompanied by visible text, not color alone — passes Differentiate Without Color for that specific control.
- No fixed `.font(.system(size:))` usage was found outside display numerals / non-text icon glyphs (see A11Y-012).
- `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` are present in the generated `Info.plist` (per `audit/00-map.md`), satisfying the App Store / accessibility-adjacent requirement that capture entry points have usage strings before shipping — out of strict a11y scope but verified in passing since it's part of the same import flow reviewed here.
- `ImportErrorView` uses `@ScaledMetric(relativeTo: .largeTitle)` for its icon diameter (`ImportErrorView.swift:14`), correctly scaling with Dynamic Type rather than a hardcoded frame.

---

**Severity counts:** Blocker 3, High 4, Medium 6, Low 2 (15 numbered findings; A11Y-012 logged as a clean check, not counted).
