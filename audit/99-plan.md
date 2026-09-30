# 99 — Pre-release fix plan

Sources: `01-accessibility.md` (15), `02-app-store-review.md` (17), `03-hig.md` (6), `04-monetization.md` (23), `05-ux-flow.md` (40). 101 raw findings collapse into 68 merged items below.
Branch `jh/edgeCaseStates`, audited with the uncommitted working tree included.

## Corrections to the brief and to `00-map.md`

- The yearly plan is **$39.99** in `QuickStudy.storekit`. CLAUDE.md says $29.99 (MON-019). App Store Connect sets the real price.
- `TypeCardsView` is the **manual card editor** and it is wired. It is not a future typed-answer quiz.
- The on-device `sourceChunkLimit` is **1,200**, not nil.
- The free hosted generation is spent on **every** device, including Apple Intelligence ones. That is the root of the top blocker.
- The app target's deployment target is **26.0**.

---

## Decisions (answered 2026-09-22)

| # | Decision | Answer | Effect on the plan |
|---|---|---|---|
| D1 | Free first generation: every device, or only no-model devices? | **Every first-time user's first generation is cloud.** | ASR-002 is fixed with consent (D2), not by restricting routing. The CLAUDE.md privacy rule ("…or the device has no on-device model…") must be updated to match. The on-device fallback (ASR-006) becomes mandatory: declined consent, offline, or a server failure on an AI-capable device drafts on-device instead. Onboarding copy must say that the first set is cloud and later sets are on-device. |
| D2 | Consent step for hosted AI | **Build a consent sheet.** | One-time sheet before the **first** hosted send, for free and Pro users alike. It states what is sent (document text, optional topic), the processor (Cloudflare Workers AI, running OpenAI open-weight and DeepSeek models), that text isn't stored, and a policy link. **Allow** / **Not now**. "Not now" goes on-device, or to Type cards on no-model devices, and never blocks. External API mode gets its own one-time confirmation that names the provider (ASR-008). |
| D3 | iPad | **iPhone only.** | `TARGETED_DEVICE_FAMILY = 1`; iPad orientations removed. HIG-005 and the iPad half of ASR-017 are closed. The app still runs on iPad in iPhone compatibility mode, and App Review may test it there. |
| D4 | Design-system changes for HIG and accessibility | **Approved: whatever the HIG requires.** | B7 adds a Reduce Transparency opaque fallback to `appGlassCard` / `appProminentButtonStyle` and adds darker light-mode colorsets (text-safe teal, danger and success). |
| D5 | UX-012, UX-017, UX-020 | Not answered, so **deferred.** | Backlog. |

## You own these (not code)

| ID | Item | Why it's on you |
|---|---|---|
| ASR-001 | **Rewrite the hosted privacy policy** (the jaidenhenley.github.io page) and redo the App Privacy answers in App Store Connect. Cover hosted generation, Cloudflare Workers AI with the OpenAI and DeepSeek models, `/metrics` analytics, KV retention, and a contact address. | **Blocker. Rejection likelihood High.** The policy currently says nothing leaves the device. |
| ASR-005 | Run `codesign -d --entitlements -` on an exported App Store archive. If it shows `development`, B2 adds a Release-only entitlements file. | Unverified. If it is wrong, Pro and the free generation are dead in review. |
| ASR-011 | Rewrite the App Store description in `APP_STORE_ASSETS_GUIDE.md`. The current draft says "No internet required" and "All data stays on your device", and it does not mention Pro. | Metadata. |
| MON-006 (config) | Enable Billing Grace Period in App Store Connect. The code half is in B1. | — |
| MON-018 / 019 | Decide whether yearly gets a trial, and fix the price in CLAUDE.md. | Pricing. |

---

## Priority order (merged, deduplicated)

Tier 1 is App Store blockers and likely rejections. Tier 2 is accessibility blockers. Tier 3 is everything else, ranked by severity ÷ effort. **Batch** refers to the batches in the next section.

### Tier 1 — App Store

| Merged item | Source IDs | Sev | Eff | Batch |
|---|---|---|---|---|
| Privacy policy and label contradict hosted traffic | ASR-001 | Blocker | S/M | **you** |
| First generation goes to the hosted third-party AI with no consent. Keep the free cloud first generation for everyone (D1) and gate every first hosted send on a one-time consent sheet (D2). | ASR-002, MON-003 | Blocker | M | B1 → B4 |
| Hosted first-run failure or declined consent has no on-device fallback; errors retry forever | ASR-006, UX-026 | **High** (raised by D1) | S | B1 |
| Onboarding and camera privacy copy is false ("never leave it", "Works offline", "never uploaded") | ASR-003, UX-010 | High | S | B2 |
| Pro sold as "without a monthly cap" and shown with ∞, but capped at 150 | ASR-004, MON-004, UX-004 | High | S | B2 |
| False truncation upsell ("Only the first 1,200 characters were used") | MON-001, UX-003 | High | S | B1 |
| App Attest entitlement is `development` | ASR-005 | High? | S | you → B2 |
| Analytics on by default, wrong manifest purpose; manifest declares photos and file timestamps it doesn't use; no export-compliance key; photo string | ASR-007, ASR-017 | Medium | S | B2 |
| External API mode sends text to OpenAI or Anthropic with no disclosure | ASR-008 | Medium | S | B2 |
| Privacy policy reachable only from the paywall | ASR-009 | Medium | S | B2 |
| Manual Type cards promised but unreachable on AI devices | ASR-010, UX-007, MON-005 | Medium | S | B3 (+ copy in B2) |
| No-model devices dead-end after the free generation: told to buy a new iPhone, see "10 of 10 left", suggestion row fails | MON-002, UX-005, ASR-012 | High | M | B3 |
| Apple Intelligence off or downloading: the error's only actions repeat the failure; discovered only after capture | ASR-013, UX-027 | Low/Med | S | B2 (copy), B4 (pre-check) |
| Simulator copy in a shipping alert | ASR-014, UX-038 | Low | S | B4 |
| "three" sample sets, but there are four | ASR-015, UX-033 | Low | S | B2 |
| Leftover simulator screenshot in the asset catalog | ASR-016 | Low | S | B2 |
| "iPhone" copy in an iPad build | ASR-017 (part) | Low | S | B2 (moot if D3) |

### Tier 2 — Accessibility blockers and highs

| Merged item | Source IDs | Sev | Eff | Batch |
|---|---|---|---|---|
| Quiz choice selected state invisible to VoiceOver | A11Y-001 | Blocker | S | B5 |
| Correct/wrong result not announced; no focus move | A11Y-002, A11Y-010 (quiz) | Blocker | M | B5 |
| Draft edit and remove unreachable with VoiceOver (tap gesture + swipe only) | A11Y-003, HIG-004, A11Y-010 (review) | Blocker | M | B6 |
| Source pills, Why?, streak dots and stat tiles unlabeled | A11Y-004 | High | M | B5, B6, B8 |
| No Reduce Motion handling | A11Y-006 | High | S | B5, B3 |
| No Reduce Transparency on glass | A11Y-007 | High | M | B7 (D4) |
| Light-mode contrast fails: teal 2.24, danger 2.75, success 1.85 | A11Y-011 | High | M | B7 (D4) |

### Tier 3 — Everything else (severity ÷ effort)

| Merged item | Source IDs | Sev | Eff | Batch |
|---|---|---|---|---|
| New user with zero sets sees "All caught up" and no action | UX-001 | High | S | B3 |
| "We'll surface this one again tomorrow", but the card is due again today | UX-009 | High | S | B5 |
| Scan Preview Save leaves `navigateToReview` stuck (verify on device) | UX-008 | High | S | B4 |
| Scanner in `.sheet`; should be `.fullScreenCover` | HIG-001 | High | S | B4 |
| Suggestion row says "on-device" when it is hosted, and burns the free generation on 3 demo cards | UX-006, MON-022 | High | M | B3 |
| Cancel on Generating doesn't cancel; the user is pushed into Review later and still charged | UX-002 | High | M | B4 |
| Pro status stale after expiry or restore; raw certificate error text | MON-007 | Medium | S | B1 |
| Grace period drops Pro (client half) | MON-006 | Medium | M | B1 (+S1) |
| Pro loses on-device: offline, at the cap, and on >40k-character documents | MON-008 | Medium | M | B1 |
| Paywall never says why it appeared or when the limit resets; no last-free warning | MON-013, UX-018 | Medium | S | B2 (+B4 hook) |
| Bring-your-own-key generations count against the allowance and hit the paywall | MON-014, UX-027 | Medium | S | B1 + B4 |
| Scan Preview Cancel deletes the draft with no confirmation | UX-011 | Medium | S | B4 |
| WEAKEST CARD row has a chevron but does nothing | UX-013 | Medium | S | B3 |
| Question disappears after Submit | UX-014 | Medium | S | B5 |
| Why? before answering reveals the answer | UX-015 | Medium | S | B5 |
| Leaving mid-session drops the session record with no warning | UX-016 | Medium | S | B5 |
| Practice anyway quizzes the whole library and reschedules | UX-019 | Medium | S | B3 |
| Generic set titles, and no rename in Review | UX-021 | Medium | S | B4 + B6 |
| Blank cards can be saved | UX-023 | Medium | S | B6 |
| Regenerate wipes edits with no confirmation | UX-024 | Medium | S | B6 |
| Offline banner and Settings "On-Device" label wrong for Pro | UX-025 | Medium | M | B3 + B2 |
| Scanner error swallowed silently | UX-028 | Medium | S | B4 |
| Generating cover may drop while a sheet dismisses (verify) | UX-029 | Medium | S | B4 |
| Colour-only DUE, mastery and progress states | A11Y-008 | Medium | M | B5, B8 |
| Decorative images not hidden | A11Y-005 | Medium | S | B3, B5 |
| `lineLimit(1)` truncates titles at AX sizes | A11Y-013 | Medium | S | B3, B6, B8 |
| Fixed 228pt preview height clips at AX sizes | A11Y-014 | Medium | M | B4 |
| HStacks don't reflow at AX sizes | A11Y-015 | Medium | M | B3, B5, B6 |
| Small tap target on TypeCardRow remove | A11Y-009 | Medium | S | B3 |
| Streak numeral uses a fixed size | HIG-003 | Medium | S | B8 |
| 🔥 emoji instead of `flame.fill` | HIG-002, A11Y-016 | Medium | S | B3 |
| Two `StoreController` instances, two listeners | MON-017 | Low | S | B1 |
| Some transactions never finished | MON-016 | Low | S | B2 |
| Pro pill shows full quota after relaunch | MON-015 | Low | S | B1 |
| Clock change or reinstall resets the 10/month | MON-010 | Medium | S | B1 (Keychain month stamp + count) |
| "Scanning…" header for PDF and paste | UX-030 | Low | S | B4 |
| Discard warning claims it "used one of your free generations" for hosted and Pro drafts | UX-031 | Low | S | B6 |
| WEAKEST CARD "Missed 3 times" on demo data | UX-032 | Low | S | B3 (DemoData read-only → move to B3) |
| Create surfaces list sources differently; Photo missing | UX-034 | Low | S | B3 (empty state) + B2 (onboarding) |
| Stats empty-state copy wrong | UX-035 | Low | S | B8 |
| "Nicely done" at 0% | UX-036 | Low | S | B5 |
| "Save" should be "Save N cards" | UX-037 | Low | S | B6 |
| Recovered draft not surfaced on Today | UX-039 | Low | S | B3 |
| No purchase confirmation | UX-040 | Low | S | B2 |
| Haptics fired without `prepare()` | HIG-006 | Low | S | B5 |
| No purchase analytics event | MON-021 | Low | S | B1 |
| **Deferred** | UX-012, UX-017, UX-020 (D5); UX-022 ¶ always 1 (M, `CardSourceLocator`); HIG-005 iPad grid (if D3 = iPhone-only); MON-009 DeviceCheck per-device free bit (M, needs server) | — | — | backlog |

**Server repo (`quickstudy-api`), batch S1, independent of the app:** MON-006 grace-period acceptance, MON-011 Apple cert OID check, MON-012 refund staleness, MON-020 sandbox in production, MON-023 non-atomic quota. MON-009 when you take it.

---

## Batches (non-overlapping file ownership)

Each batch lists **every file it may touch**. No file appears in two batches. Files not listed are read-only for that batch.

| Batch | Model | Owns (files) | Items |
|---|---|---|---|
| **B1 — Hosted routing & store** | sonnet | `Models/Store/StoreController.swift`, `Models/AI/Engine/AIController.swift`, `Models/AI/Engine/APICardGenerationEngine.swift`, `Models/AI/Engine/HostedCardGenerationEngine.swift`, `Models/AI/Engine/CardGenerationError.swift`, `Models/AI/GenerationAllowance.swift`, `Models/Analytics/AnalyticsEvent.swift`, `State/StudyViewModel.swift`, `Views/Review/Components/TruncationNoticeRow.swift`, `Views/Shared/ContentView.swift`, **new** `Models/AI/HostedConsent.swift` (persisted flag only) | consent state + gate on every hosted path (D1/D2), declined → on-device, MON-003, ASR-006/UX-026, MON-001/UX-003, MON-006 (client), MON-007, MON-008, MON-010, MON-014 (engine flag), MON-015, MON-017, MON-021, CardGenerationError iPhone copy |
| **B2 — Copy, paywall, manifest, config** | haiku | `Models/Import/ImportFailure.swift`, `Views/Paywall/PaywallView.swift`, `Views/Paywall/Components/*`, `Views/Onboarding/Components/OnboardingAIIntroPage.swift`, `…/OnboardingCameraPage.swift`, `…/OnboardingFirstSourcePage.swift`, `Views/Settings/SettingsView.swift`, `PrivacyInfo.xcprivacy`, `Models/Analytics/AnalyticsRecorder.swift`, `QuickStudy.entitlements` (+ Release variant if ASR-005), `project.pbxproj` (Info.plist keys, device family only), asset-catalog removal of the simulator screenshot | ASR-003/UX-010 (copy per D1: first set cloud with consent, then on-device), ASR-004/MON-004/UX-004, ASR-007, ASR-008, ASR-009, ASR-010 copy, ASR-013 copy, ASR-015, ASR-016, ASR-017, D3 (device family 1 + drop iPad orientations), MON-013, MON-016, UX-040, UX-034 (onboarding), UX-025 (settings label) |
| **B3 — Today & Library states** | sonnet | `Views/Today/**` (TodayView, TodayViewModel, all Today components), `Views/Library/LibraryView.swift`, `LibraryViewModel.swift`, `Views/Library/Components/AddCardsSection.swift`, `LibraryEmptyView.swift`, `SetTile.swift`, `Views/TypeCards/Components/TypeCardRow.swift`, `Models/Demo/DemoData.swift` | MON-002/UX-005/ASR-012, ASR-010/UX-007/MON-005 (route), UX-001, UX-006/MON-022, UX-013, UX-019, UX-025 (banner), UX-032, UX-034, UX-039, HIG-002/A11Y-016, A11Y-005/006/008/009/013/015 (Today and Library parts) |
| **B4 — Import presentation** | sonnet | `Views/Import/**` (ImportModifiers, ImportCoordinator, GeneratingView, ImportErrorView, components), `Views/Scan/ScannerCoordinator.swift`, `Views/Review/ScanPreviewView.swift`, `Views/Library/Components/PasteTextSheet.swift`, `NewSetSheet.swift`, **new** `Views/Import/Components/HostedConsentSheet.swift` | Consent sheet UI + presentation before the first hosted send and on switching to External API (D2, ASR-008), UX-002, UX-008, UX-011, UX-018 hook, UX-021 default titles, UX-027 pre-capture check, UX-028, UX-029, UX-030, HIG-001, ASR-014/UX-038, MON-014 (coordinator), A11Y-014 |
| **B5 — Quiz session** | sonnet | `Views/Quiz/**` (QuizSessionView, QuizSessionViewModel, SessionCompleteView, all Quiz components) | A11Y-001, A11Y-002, A11Y-004/005/006/008/010/015 (quiz parts), UX-009, UX-014, UX-015, UX-016, UX-036, HIG-006 |
| **B6 — Review drafts** | sonnet | `Views/Review/ReviewDraftsView.swift`, `Views/Review/Components/DraftCardRow.swift` (and other Review components except TruncationNoticeRow), `Views/Library/Components/PendingDraftRow.swift` | A11Y-003/HIG-004, A11Y-004/010/013/015 (review parts), UX-021 (title field), UX-023, UX-024, UX-031, UX-037 |
| **B7 — Design system (D4 approved)** | sonnet | `Views/DesignSystem/Theme.swift`, `DesignTokens.swift`, `Assets.xcassets/*.colorset` | A11Y-007, A11Y-011 |
| **B8 — Streak & Stats** | haiku | `Views/Streak/**`, `Views/Stats/**` | HIG-003, A11Y-004/008/013 (streak and stats parts), UX-035 |
| **S1 — Server** | sonnet | `~/Desktop/CurrentProjects/quickstudy-api/src/**` | MON-006, 011, 012, 020, 023 |

### Dependencies and run order

```
Wave 1:  B1 ─┬─> B4   (B4 presents the consent state B1 defines)
         B2  │
         B5  │
         B6  │
         B8  │
Wave 2:  B3, B4      (B3 reads B1's new capability/routing API for the no-model and "on-device" label logic)
Wave 3:  B7          (touches the modifier every other batch calls, so it goes last)
Any time: S1 (separate repo)
```

**Building.** Your rule is that each batch builds cleanly before the next starts. Parallel agents share one source tree, so one agent's build would compile another's half-finished edits. So wave 1 batches edit in parallel, and **I build once per wave**. If that build fails, I attribute the failure by file ownership and send it back to the batch that owns the file. If you want strict per-batch builds instead, the same batches run one at a time in the order B1, B2, B5, B6, B8, B3, B4, B7.

**Working tree.** B1, B2 and B4 own files that currently carry your uncommitted edits: `StudyViewModel`, `ImportCoordinator`, `ImportFailure`, `ImportErrorView`, `CardGenerationError` and `AppAttestClient`. Commit or stash those first so each batch's diff reviews cleanly.

**Every fix agent gets these instructions:** CLAUDE.md standards; its file list only; no git; stop and ask if unsure of an API signature; report the diff; no comments narrating code.

**CLAUDE.md** needs its Privacy rule updated for D1: hosted use is allowed when the user is Pro, or when the one free hosted generation is unspent **and** the user has consented. That is a doc edit; I'll make it with B1 if you approve.
