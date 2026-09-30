# QuickStudy iOS App — Codebase Audit Map

**Branch:** jh/edgeCaseStates  
**Build:** iOS 26.2 (deployment target), single target QuickStudy + QuickStudy.Tests  
**Date:** 2026-09-22

---

## 1. Targets & Build

### QuickStudy (Main)
- **Bundle ID:** `com.henley.jaiden.QuickStudy`
- **Deployment Target:** 26.2
- **Device Families:** iPhone + iPad
- **Orientations (iPhone):** Portrait, Landscape Left, Landscape Right
- **Orientations (iPad):** Portrait, Portrait Upside Down, Landscape Left, Landscape Right
- **Info.plist:** Generated (`GENERATE_INFOPLIST_FILE = YES`)

### Generated Info.plist Keys
- `LSApplicationCategoryType`: `public.app-category.education`
- `NSCameraUsageDescription`: `"We use the camera to scan documents for studying."`
- `NSPhotoLibraryUsageDescription`: `"We use photos to let the user be able to import study notes to make flashcards."`
- `UIApplicationSceneManifest_Generation`: YES
- `UIApplicationSupportsIndirectInputEvents`: YES
- `UILaunchScreen_Generation`: YES

### QuickStudy.Tests
- **Bundle ID:** `com.henley.jaiden.QuickStudy.Tests`
- **Deployment Target:** 26.0

### Localization
- Development region: `en`
- Known regions: English only (no xcstrings or .strings files)

---

## 2. Entitlements & Privacy

### QuickStudy.entitlements
```xml
com.apple.developer.devicecheck.appattest-environment: development
```

### PrivacyInfo.xcprivacy Summary
- **NSPrivacyTracking:** false
- **Collected Data Types:** OtherUserContent, PurchaseHistory, PhotoVideo, ProductInteraction (all for AppFunctionality, not linked, not tracking)
- **Required-Reason APIs:**
  - `FileTimestamp` (reason C617.1)
  - `UserDefaults` (reason CA92.1)

### StoreKit Products (QuickStudy.storekit)
**Group:** QuickStudy Pro

| Product ID | Display Name | Price | Recurrence | Trial | Family Sharing |
|---|---|---|---|---|---|
| `com.henley.jaiden.QuickStudy.pro.monthly` | Pro Monthly | $4.99 | P1M | 1 week free | No |
| `com.henley.jaiden.QuickStudy.pro.yearly` | Pro Yearly | $39.99 | P1Y | None | No |

**Description:** "Cloud generation on any iPhone."  
**Pro limits:** 150 hosted generations/month (ProProduct.swift:13)

---

## 3. File Inventory

### Models/AI/Engine/
- `AICapability.swift` — AICapability enum (state checking)
- `AIController.swift` — CardGenerating protocol router (mode: onDevice/externalAPI)
- `AISettings.swift` — @Observable AI preferences (mode, apiFormat, endpoint, modelName; stored in UserDefaults)
- `APICardGenerationEngine.swift` — User-configured API endpoint engine
- `AppAttestClient.swift` — App Attest signing
- `CardGenerating.swift` — Protocol: generateCards, countsAgainstAllowance, sourceChunkLimit, expectedSeconds
- `CardGenerationError.swift` — Error enum
- `HostedAPI.swift` — Production endpoint `https://quickstudy-api-production.jaidenhenley.workers.dev`; App Attest + JWS signing
- `HostedCardGenerationEngine.swift` — Pro/free hosted engine
- `KeychainManager.swift` — Keychain (service: `com.jaidenhenley.quickstudy`; accounts: `external-api-key`, `app-attest-key-id`)
- `OnDeviceCardGenerationEngine.swift` — Foundation Models engine
- `OnDeviceModelAvailability.swift` — SystemLanguageModel.default.availability check (#if canImport(FoundationModels))
- `PromptBuilder.swift` — Prompt construction

### Models/AI/
- `AIFlashcard.swift` — question, answer, explanation, distractors, sourceExcerpt
- `CardGenerator.swift` — generateAI, generateTopicCards
- `ContentAnalysis.swift` — Content analysis
- `DistractorRefiner.swift` — Wrong-answer refinement/backfill
- `GenerationAllowance.swift` — **Free limit: 10/month** (UserDefaults: `qs_aiGenerationsUsed`, `qs_aiGenerationsMonth`)
- `GenerationProgress.swift` — Progress reporting
- `SentenceIndexer.swift` — Index sentences

### Models/Draft/
- `DraftSet.swift` — Generated cards awaiting review
- `DraftStore.swift` — @Observable DraftSet persistence

### Models/Import/
- `ExtractedDocument.swift` — Pages from scan/PDF/paste
- `ImportFailure.swift` — Import error enum

### Models/Network/
- `NetworkMonitor.swift` — Reachability

### Models/Quiz/
- `QuizQuestion.swift` — question, choices, correctIndex, explanation, source, setTitle, boxBefore

### Models/Scheduling/
- `ReviewSchedule.swift` — Spaced repetition scheduling (box → due date)

### Models/Session/
- `StudySession.swift` — Quiz session record
- `SessionStore.swift` — @Observable persisted sessions
- `StreakCalculator.swift` — Derive streaks from session history
- `StreakStore.swift` — Persist freeze usage

### Models/Store/
- `ProProduct.swift` — Product IDs (monthly/yearly); `hostedMonthlyLimit = 150`
- `StoreController.swift` — **@MainActor @Observable:** Transaction.updates listener, currentEntitlements checker, `willUseHostedGeneration` (Pro or free hosted unused), `isPro`, `refreshEntitlement()`, `markFreeHostedGenerationUsed()` (UserDefaults: `qs_hostedFreeGenerationUsed`)

### Models/Study/
- `StudyCard.swift` — question, answer, explanation, distractors, box, dueDate, missCount, source, lastReviewedAt
- `StudySet.swift` — title, document, cards, sourceType, isDemo, updatedAt
- `StudyDocument.swift` — title, lines, pageBreaks
- `CardSource.swift` — document, page, paragraphStart, excerpt
- `CardSourceLocator.swift` — Map card to source
- `StudySourceType.swift` — scan, pdf, paste, demo

### Models/Analytics/
- `AnalyticsEvent.swift` — Event enum
- `AnalyticsRecorder.swift` — @Observable recorder; events sent to (endpoint not hardcoded in audit; verify implementation)
- `MetricsSnapshot.swift` — Metrics

### Models/Demo/
- `DemoData.swift` — Four sample sets (HIG, SwiftUI, SpriteKit, CoreData) with seeded cards

### Models/Store/
See above

### State/
- `AppState.swift` — @Observable: selectedTab (today/library/stats), pendingImportSource
- `StudyViewModel.swift` — **@Observable @MainActor:** savedSets, activeSetID, document, flashcards, isGenerating, demoModeEnabled (@AppStorage), isSpellCheckEnabled, isHandwritingMode. Persistence: Documents/SavedSets.json (JSONEncoder/Decoder, atomic write, ISO8601 dates). Methods: loadSavedSets(), saveSavedSets(), loadTodaySession(), recordAnswer(), sessionQuestions(), makeDraft(), generateCards(), flushPendingChanges() on scenePhase != .active

### Views/DesignSystem/
- `Theme.swift` — Color tokens
- `DesignTokens.swift` — Design constants
- `AppBackgroundView.swift` — Root background

### Views/Today/
- `TodayView.swift` — Today screen
- `TodayViewModel.swift` — Today view model
- **Components:** SessionCard, SuggestionRow, UpNextRow, WeakestCardRow, AICardsLeftView, OfflineBanner, TodayEmptyView

### Views/Library/
- `LibraryView.swift` — Library screen
- `LibraryViewModel.swift` — Library view model
- **Components:** SetTile, LibraryEmptyView, NewSetSheet, PasteTextSheet, FloatingCreateButton, PendingDraftRow, LibraryFilterChips, LibrarySearchField, SourceOptionButton, AddCardsSection

### Views/Import/
- `ImportCoordinator.swift` — Coordinator: presentPastingSheet(), presentFilePicker(), presentCameraView()
- `ImportModifiers.swift` — ViewModifier for import flow
- `ImportErrorView.swift` — Error display
- `GeneratingView.swift` — Generation progress
- **Components:** ErrorRecoveryTipRow

### Views/Review/
- `ReviewDraftsView.swift` — Review/approve generated cards
- `ScanPreviewView.swift` — Preview scanned pages with draft cards
- **Components:** DraftCardRow, DraftedCardPreview, DraftedDeckSummary, SourcePageView, TruncationNoticeRow

### Views/Scan/
- `DocumentScannerView.swift` — System VNDocumentCameraViewController wrapper
- `ScannerCoordinator.swift` — Scan coordinator

### Views/Quiz/
- `QuizSessionView.swift` — Multiple-choice quiz
- `QuizSessionViewModel.swift` — Session state
- `SessionCompleteView.swift` — Session end summary
- **Components:** QuizChoiceRow, SessionProgressBar, SessionStatCell, WhySourceCard, ResultCard, ReinforcementRow

### Views/Onboarding/
- `OnboardingView.swift` — Onboarding flow
- `OnboardingViewModel.swift` — Pages: welcome, howItWorks, aiIntro, [camera], firstSource. UserDefaults: `qs_hasCompletedOnboarding`, `qs_onboardingPaywallPending`
- **Components:** OnboardingWelcomePage, OnboardingHowItWorksPage, OnboardingAIIntroPage, OnboardingCameraPage, OnboardingFirstSourcePage, OnboardingFeatureRow, OnboardingSourceRow, OnboardingStepRow

### Views/Paywall/
- `PaywallView.swift` — SubscriptionStoreView with restore, Terms (https://www.apple.com/legal/internet-services/itunes/dev/stdeula/), Privacy (https://jaidenhenley.github.io/JaidenHenleyPort/quickstudy-privacy.html)
- **Components:** PaywallHeaderView, PaywallFeatureRow

### Views/Settings/
- `SettingsView.swift` — Settings rows:
  - AI + Input: Handwriting Mode, Spell Check, AI Source picker, [if externalAPI: Provider picker, API Key, Endpoint URL, Model Name]
  - Pro: Active/Upgrade toggle, Manage Subscription
  - Sample Content: Show Sample Sets toggle
  - Privacy: Share anonymous usage toggle
  - Data: Delete All Study Sets button
  - About: Version display

### Views/Stats/
- `StatsView.swift` — Stats screen
- `StatsViewModel.swift` — Stats view model
- **Components:** StatSetRow, StatTile

### Views/Streak/
- `StreakView.swift` — Streak display
- **Components:** StreakDayDot

### Views/Sets/
- `StudySetDetailView.swift` — Set detail/cards view

### Views/TypeCards/
- `TypeCardsView.swift` — (Future typed-answer quiz)
- `TypeCardsViewModel.swift`
- **Components:** TypeCardRow

### Views/Shared/
- `ContentView.swift` — Root TabView (Today, Library, Stats); initializes all @State models; listens to scenePhase; Onboarding fullScreenCover with paywall sheet

### Helpers/
- `DocumentImportHelper.swift` — File import helpers

### Root
- `MyApp.swift` — @main App struct → ContentView()

---

## 4. App Structure

### Root App
- **MyApp.swift** → `WindowGroup { ContentView() }`

### Tab Structure (ContentView.swift)
Three tabs, all live and functional:
1. **Today** (`TodayView`) — label: "house"
2. **Library** (`LibraryView`) — label: "books.vertical"
3. **Stats** (`StatsView`) — label: "chart.bar"

### Navigation Containers
- `NavigationStack` per tab
- `TabView` with `@State private var selectedTab` (AppState.Tab)

### Sheets & Modals
- **Onboarding** (fullScreenCover) — `OnboardingView` with paywall sheet after first user set
- **Paywall** (sheet) — `PaywallView` from Settings and onboarding
- **New Set** (half-sheet) — `NewSetSheet` from Library floating button
- **Paste Text** (half-sheet) — `PasteTextSheet` from import flow
- **Manage Subscription** (manageSubscriptionsSheet) — From Settings

### Environment Injection (ContentView.swift)
```
.environment(TodayViewModel)
.environment(DraftStore)
.environment(SessionStore)
.environment(StudyViewModel)
.environment(AppState)
.environment(AISettings)
.environment(NetworkMonitor)
.environment(StoreController)
.environment(AnalyticsRecorder)
```

---

## 5. AI & Generation

### CardGenerating Protocol
- `countsAgainstAllowance: Bool` — does it deduct from monthly free limit
- `sourceChunkLimit: Int?` — max source length per generation
- `expectedSeconds: Double` — UI progress estimate
- `generateCards(from text: String) async throws -> [AIFlashcard]`
- `generateCards(from text: String, topic: String, count: Int) async throws -> [AIFlashcard]`

### Generation Engines

#### AIController.makeGenerator() Logic
1. If `aiSettings.mode == .onDevice`:
   - If Pro or free hosted generation unspent → `HostedCardGenerationEngine`
   - Else → `OnDeviceCardGenerationEngine`
2. If `aiSettings.mode == .externalAPI`:
   - Validates API key in Keychain (CardGenerationError.missingAPIKey)
   - Validates endpoint (CardGenerationError.invalidEndpoint)
   - Returns `APICardGenerationEngine`

#### OnDeviceCardGenerationEngine
- Uses `#if canImport(FoundationModels)` guard
- Checks `SystemLanguageModel.default.availability`
- Errors: `.deviceNotEligible`, `.appleIntelligenceNotEnabled`, `.modelNotReady`
- `countsAgainstAllowance = true`
- `sourceChunkLimit = nil` (reads whole document)
- `expectedSeconds = ~5`

#### APICardGenerationEngine
- User-configured endpoint + API key
- Supports OpenAI (default: `gpt-4.1-mini`) and Anthropic (default: `claude-sonnet-4-20250514`)
- `countsAgainstAllowance = true`

#### HostedCardGenerationEngine
- Endpoint: `https://quickstudy-api-production.jaidenhenley.workers.dev`
- Authentication: App Attest signature (`AppAttestClient`) + StoreKit `jwsRepresentation`
- Server verifies both; app does not decide entitlement
- `countsAgainstAllowance = false` (server controls quota)
- Free one per user (tracked in UserDefaults: `qs_hostedFreeGenerationUsed`)
- Pro limit: 150/month (from server response)

### Free Generation Allowance
- **Limit:** 10 per month
- **Storage:** UserDefaults
  - `qs_aiGenerationsUsed` — count
  - `qs_aiGenerationsMonth` — stamp (year*12 + month)
- **Check:** GenerationAllowance.remaining()
- **Record:** GenerationAllowance.recordGeneration() (increments used, updates month)
- **Reset:** Automatic on month change (timestamp comparison on read)
- **Usage:** Checked by StudyViewModel.draft() before .recordGeneration()

### Foundation Models Availability
- **Guard:** `#if canImport(FoundationModels)`
- **Check:** `SystemLanguageModel.default.availability`
- **Cases:** `.available`, `.unavailable(.deviceNotEligible)`, `.unavailable(.appleIntelligenceNotEnabled)`, `.unavailable(.modelNotReady)`

---

## 6. StoreKit

### StoreController (@MainActor @Observable)
**Transactions & Entitlements:**
- Listener: `Transaction.updates` in init
- Checker: `Transaction.currentEntitlements` in refreshEntitlement()
- Restore: `AppStore.sync()` (via SubscriptionStoreView restore button)
- Finish: Auto-finished transactions from updates

**Properties:**
- `activeTransaction: Transaction?` — verified Pro transaction
- `transactionJWS: String?` — JWS for server signing (sent with every hosted request)
- `hostedRemaining: Int?` — remaining quota from server
- `freeHostedGenerationUsed: Bool` — persisted in UserDefaults: `qs_hostedFreeGenerationUsed`
- `isPro: Bool` → activeTransaction != nil
- `willUseHostedGeneration: Bool` → transactionJWS != nil || !freeHostedGenerationUsed

**Methods:**
- `refreshEntitlement()` — iterates currentEntitlements, validates expiration/revocation
- `markFreeHostedGenerationUsed()` — sets flag after server confirms free generation exhausted
- `recordHostedGeneration(remaining, usedFreeGeneration)` — updates quota after server response

**Paywall:**
- View: `PaywallView(surface: .onboarding | .settings)`
- UI: `SubscriptionStoreView(productIDs: ProProduct.identifiers)`
- Style: `.subscriptionStoreControlStyle(.prominentPicker)`, `.subscriptionStoreButtonLabel(.multiline)`
- Buttons: Restore visible (`.storeButton(.visible, for: .restorePurchases)`)
- Policy links: Terms (Apple standard), Privacy (custom https://jaidenhenley.github.io/JaidenHenleyPort/quickstudy-privacy.html)
- Presented from: ContentView onboarding paywall sheet (after first user set), Settings sheet

---

## 7. Persistence

### Stores (UserDefaults)
| Key | Owner | Purpose |
|---|---|---|
| `demoModeEnabled` | StudyViewModel (@AppStorage) | Show sample sets |
| `aiSettings.mode` | AISettings | Generation mode (onDevice/externalAPI) |
| `aiSettings.apiFormat` | AISettings | API provider (openAI/anthropic) |
| `aiSettings.endpoint` | AISettings | User API endpoint URL |
| `aiSettings.modelName` | AISettings | User-configured model name |
| `qs_aiGenerationsUsed` | GenerationAllowance | Free generations consumed |
| `qs_aiGenerationsMonth` | GenerationAllowance | Month stamp for free allowance |
| `qs_hostedFreeGenerationUsed` | StoreController | Whether free hosted generation was spent |
| `qs_hasCompletedOnboarding` | OnboardingViewModel | Onboarding complete flag |
| `qs_onboardingPaywallPending` | OnboardingViewModel | Paywall should show after first set |

### Keychain
**Service:** `com.jaidenhenley.quickstudy`

| Account | Purpose |
|---|---|
| `external-api-key` | User's configured API key |
| `app-attest-key-id` | App Attest private key ID |

**Access:** KeychainManager.load/saveAPIKey()

### File Persistence
- **SavedSets.json**
  - Location: Documents directory (`FileManager.urls(for: .documentDirectory)`)
  - Format: JSONEncoder/Decoder with `.prettyPrinted`, `.sortedKeys`
  - Dates: ISO8601
  - Write: Atomic
  - Method: StudyViewModel.saveSavedSets() (called on scenePhase != .active, structural edits, demo mode)
  - Codable: StudySet with decodeIfPresent defaults (e.g., isDemo)

---

## 8. Network Endpoints

| Endpoint | Purpose | Auth | Payload |
|---|---|---|---|
| `https://quickstudy-api-production.jaidenhenley.workers.dev/attest/challenge` | Fetch App Attest challenge | None | POST {} |
| `/attest/register` | Register App Attest key | None | POST {keyId, attestation, challenge} |
| `/generate` | Generate cards (Pro/free) | App Attest signature + StoreKit JWS | POST signedBody |
| `/metrics` | Send analytics | App Attest signature + StoreKit JWS | POST signedBody |
| `https://api.openai.com/v1/chat/completions` | OpenAI API (default user config) | User API key | POST |
| `https://api.anthropic.com/v1/messages` | Anthropic API (default user config) | User API key | POST |

**Debug override:** `QS_API_URL` environment variable (DEBUG builds)  
**Simulator bypass:** `QS_DEV_TOKEN` environment variable (DEBUG simulator only)

---

## 9. Required-Reason APIs (PrivacyInfo.xcprivacy)

- **FileTimestamp** (reason C617.1) — file modification checks
- **UserDefaults** (reason CA92.1) — settings persistence

---

## 10. Onboarding

**Pages** (determined in OnboardingViewModel.__init__):
1. Welcome
2. How It Works
3. AI Intro
4. **[Camera permission]** — only if AVCaptureDevice.authorizationStatus(.video) == .notDetermined
5. First Source (choose: demo or import path)

**Outcomes:**
- `.demo` → demoModeEnabled = true, tab = .today
- `.source(importSource)` → tab = .library, appState.pendingImportSource = source

**Paywall timing:**
- Set pending in onboarding if not Pro
- Shown after first user-created set (observes userSetCount in ContentView)

---

## 11. Settings

See Views/Settings/SettingsView.swift (section 3 above).

---

## 12. Debug Artifacts

**No TODOs, FIXMEs, or print statements found in committed code.**

**DemoData usage:**
- QuickStudy/Models/Demo/DemoData.swift — Four sample sets
- QuickStudy/State/StudyViewModel.swift:529–572 — seedDemoSetsIfNeeded()
- QuickStudy/Views/Settings/SettingsView.swift:129 — "Show Sample Sets" toggle
- QuickStudy/Views/Shared/ContentView.swift:117 — Onboarding .demo choice

---

## 13. Surprises vs. Assumptions

| Assumption | Reality |
|---|---|
| 10 free AI generations per month | ✓ Confirmed (GenerationAllowance.monthlyLimit = 10) |
| Three tabs (Today/Library/Stats) | ✓ All three exist and are live |
| Free generation limit stored locally | ✓ UserDefaults (qs_aiGenerationsUsed, qs_aiGenerationsMonth) |
| Pro subscription for hosted generation | ✓ $4.99/mo or $39.99/yr (7-day trial for monthly) |
| Hosted endpoint is Cloudflare Worker | ✓ quickstudy-api-production.jaidenhenley.workers.dev |
| No Notifications entitlement | ✓ None declared (design mentions notifications but not yet implemented) |
| No typed-answer grading | ✓ TypeCardsView exists but not integrated (MC only) |
| Custom camera UI | ✗ Uses system VNDocumentCameraViewController (design specs custom UI) |

---

**Audit completed.** Next auditor: check generated screens vs. Final v2 designs (DesignSync), verify payment flow completeness, and validate error state coverage across all AI engines.
