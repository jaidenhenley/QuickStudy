# 02 — App Store Review Risk Audit

**Branch:** jh/edgeCaseStates (working tree, uncommitted changes included) · **Date:** 2026-09-22
**Scope:** QuickStudy iOS target, plus the `quickstudy-api` contract where the app depends on it. Guideline numbers refer to the current App Store Review Guidelines, including the November 2025 revision that added the third-party AI requirement to 5.1.2(i).

**Corrections to `00-map.md` found while checking it:**
- The app target's `IPHONEOS_DEPLOYMENT_TARGET` is **26.0** (project.pbxproj:362, 399). 26.2 is only the project-level default.
- The hosted engine is chosen for **every** non-Pro user whose free hosted generation is unspent, including devices that have Apple Intelligence. The map describes the routing correctly, but the consequence (ASR-002) is not called out.
- The hosted server runs **third-party models**: Cloudflare Workers AI, `@cf/openai/gpt-oss-120b` with a fallback to `@cf/deepseek-ai/deepseek-v4-flash-0731` (quickstudy-api/wrangler.toml:25-26, 51-52).

---

## Summary

| Severity | Count |
|---|---|
| Blocker | 2 |
| High | 3 |
| Medium | 6 |
| Low | 6 |

---

## Findings

### ASR-001 — The published privacy policy says no data leaves the device, but the app sends user content, purchase receipts and analytics to a server
- **Severity:** Blocker · **Rejection likelihood:** High
- **File:** QuickStudy/Views/Paywall/PaywallView.swift:11, 34 (the URL the app links to); the policy is hosted at https://jaidenhenley.github.io/JaidenHenleyPort/quickstudy-privacy.html (fetched 2026-09-22, HTTP 200, "Last updated: March 2026")
- **What is wrong:** The linked policy says QuickStudy collects nothing, sends content to no server, and has no analytics. The app sends document text, a StoreKit JWS and usage counters to `quickstudy-api-production.jaidenhenley.workers.dev`, and from there to third-party AI models.
- **Evidence:**
  - The policy says: "QuickStudy does not collect, transmit, store, or share any personal data … no analytics or tracking of any kind." It also says content is "never sent to any server or third-party AI service", and "There is no account to close and no server-side data".
  - The app's actual traffic:
    - `HostedCardGenerationEngine.swift:43-44` sends `GenerateRequest(challenge:, text:, transaction:, topic:, count:)` to `/generate`.
    - `AnalyticsRecorder.swift:93-102` posts the metrics snapshot to `/metrics`.
    - The server keeps `attest:{keyId}`, `free:{keyId}` and `quota:{originalTransactionId}:{YYYY-MM}` records in KV (quickstudy-api/README.md, "Storage").
  - Guideline 5.1.1(i) requires the privacy policy to identify what data the app collects, how it collects it, and all uses of that data. It also requires confirmation that any third party that receives user data gives the same protection. Guideline 5.1.2(i) requires disclosure of sharing with third-party AI. The App Privacy label must also match (App Store Connect is in scope for 2.3). A reviewer who compares the policy with the "Sent to QuickStudy's server" copy in the app will find the contradiction.
- **Proposed fix:** Rewrite and republish the policy before submission. It should cover:
  - the hosted generation path: what is sent (document text, optional topic, StoreKit JWS, App Attest key ID and assertion), the processor (Cloudflare Workers AI; models from OpenAI (open-weight) and DeepSeek), retention (text not stored; KV quota and attestation records and how long each is kept), and that Pro and the free first generation use this path
  - the analytics `/metrics` aggregate and how to turn it off
  - the external API mode (this part is already correct)
  - a data-deletion contact
  Update the App Store Connect App Privacy answers to match: User Content (Other User Content), Purchases, Usage Data (Product Interaction, Analytics), and possibly Identifiers (Device ID) for the App Attest key ID.
- **Effort:** S (text) / M (with the label review)

### ASR-002 — User content goes to the hosted third-party AI on the first generation without explicit consent, including on devices that could generate on-device
- **Severity:** Blocker · **Rejection likelihood:** High
- **Files:**
  - QuickStudy/Models/Store/StoreController.swift:27
  - QuickStudy/Models/AI/Engine/AIController.swift:21-24, 56-62
  - QuickStudy/Views/Onboarding/Components/OnboardingAIIntroPage.swift:69
  - QuickStudy/Views/Shared/ContentView.swift:100-105
- **What is wrong:** A non-Pro user is sent to the hosted engine whenever the free hosted generation is unspent, whatever the device can do. No opt-in is ever collected. The only disclosure is a passive footnote in onboarding, a caption on the paste sheet, and nothing at all in the scan, photo and PDF flows. Upgrading users skip onboarding entirely.
- **Evidence:**
  ```swift
  // StoreController.swift:27
  var willUseHostedGeneration: Bool { transactionJWS != nil || !freeHostedGenerationUsed }
  // AIController.swift:22-24
  case .onDevice:
      if let hosted = hostedEngine(settings: settings, store: store) { return hosted }
      return OnDeviceCardGenerationEngine(progress: progress)
  ```
  - The mode is literally `.onDevice`, which is the default (AISettings.swift:44), yet the first scan's text goes to Cloudflare Workers AI (gpt-oss-120b or DeepSeek).
  - Onboarding's disclosure is a footnote under a "Continue" button with no decline option (OnboardingAIIntroPage.swift:69-81). It says "our best model" and names neither the third party nor the recipient.
  - `ContentView.swift:102-104` marks onboarding complete, without showing it, for anyone upgrading with saved sets. `freeHostedGenerationUsed` is still false for them, so their next scan is uploaded with no notice whatsoever.
  - For scan, photo and PDF there is no disclosure before the send. `GeneratingView.swift:94-96` only changes its detail text after the request has started.
  - This also breaks the project's own rule (CLAUDE.md, Privacy): hosted is allowed "only … when StoreController says the user is Pro or the device has no on-device model".
  - Guideline 5.1.2(i): "You must clearly disclose where personal data will be shared with third parties, including with third-party AI, and obtain explicit permission before doing so." Guideline 5.1.1(i) also applies. Scanned notes routinely contain names, grades and other personal data.
- **Proposed fix:**
  - (a) Limit the free hosted generation to devices where `AICapability.state` is `.unsupportedDevice`, as CLAUDE.md specifies, so AI-capable devices always draft on-device unless the user is Pro.
  - (b) Before the first hosted request of any kind (free or Pro), show a one-time consent sheet. It should name what is sent, the processor ("Cloudflare Workers AI, running models from OpenAI and DeepSeek"), that the text isn't stored, and a link to the policy. It needs "Allow" and "Not now" buttons. Persist the answer and gate `hostedEngine(...)` on it. "Not now" on a no-model device routes to Type cards.
  - (c) Show the same consent before the first Pro generation after purchase, or include the consent in the paywall flow before purchase, with its own acknowledgement.
- **Effort:** M

### ASR-003 — On-screen privacy claims are false on the path the app actually takes
- **Severity:** High · **Rejection likelihood:** Medium
- **Files:**
  - QuickStudy/Views/Onboarding/Components/OnboardingAIIntroPage.swift:21, 39-48, 69
  - QuickStudy/Views/Onboarding/Components/OnboardingCameraPage.swift:27
- **What is wrong:** On an Apple Intelligence device, one onboarding page makes contradictory claims, and the camera page promises content is never uploaded, although the text read from those photos is uploaded on the first generation.
- **Evidence:**
  - The same page says "Private by default", then "Your free generations run on-device and never leave it." and "Works offline" (lines 21, 42, 47). Then: "Your first set is drafted in the cloud with our best model…" (line 69).
  - The camera page says: "Photos are read on this iPhone and never uploaded." (line 27). The OCR text of those photos is uploaded by `HostedCardGenerationEngine` on the first generation.
  - Guideline 2.3.1 (misleading functionality) and 5.1.1(i) (accurate disclosure) apply.
- **Proposed fix:**
  - If ASR-002(a) is adopted, the on-device branch becomes true and only line 69 needs to be limited to the no-model branch.
  - Otherwise, remove "never leave it" and "Works offline" from the first-generation context.
  - Change the camera line so it no longer promises text never leaves the device.
- **Effort:** S

### ASR-004 — Purchase-related copy overstates Pro: "without a monthly cap" and an infinity icon on a 150/month limit
- **Severity:** High · **Rejection likelihood:** Medium
- **Files:**
  - QuickStudy/Models/Import/ImportFailure.swift:98
  - QuickStudy/Views/Paywall/Components/PaywallHeaderView.swift:23
- **What is wrong:** The quota-exhausted screen tells users Pro has no monthly cap, and the paywall puts an `infinity` symbol next to a capped allowance. Pro is limited to 150 hosted generations a month, enforced by the server (`quota_exhausted` 429).
- **Evidence:**
  ```swift
  "QuickStudy Pro generates without a monthly cap, on any iPhone."                                    // ImportFailure.swift:98
  PaywallFeatureRow(symbol: "infinity", text: "\(ProProduct.hostedMonthlyLimit) generations a month") // PaywallHeaderView.swift:23
  ```
  Guideline 3.1.2(a), 3.1.2 marketing, and 2.3.1: subscription marketing must describe clearly what the user gets. Claiming "no cap" on an upsell path is a common reason for rejection.
- **Proposed fix:** Change the tip to "QuickStudy Pro adds 150 cloud generations a month, on any iPhone." Swap `infinity` for a neutral symbol such as `sparkles` or `number`.
- **Effort:** S

### ASR-005 — The App Attest entitlement is `development` and the production Worker accepts only production attestations (needs verification)
- **Severity:** High · **Rejection likelihood:** Medium (depends on the verification below)
- **Files:**
  - QuickStudy/QuickStudy.entitlements:5-6
  - quickstudy-api/src/register.ts:16-17
- **What is wrong:** If the App Store build attests against the development App Attest environment, every `/attest/register` call to production fails with "Attestation environment is not accepted here." Pro and the free hosted generation would then fail for App Review.
- **Evidence:**
  ```xml
  <key>com.apple.developer.devicecheck.appattest-environment</key><string>development</string>
  ```
  ```ts
  return env.ENVIRONMENT === "production" ? ["production"] : ["development", "production"];
  ```
  I am not certain whether App Store and TestFlight distribution overrides this entitlement to `production`, so this is not asserted as a defect. The consequence if it doesn't is a non-functional paid feature: Guideline 2.1 (completeness) and 3.1.1 (the purchase must unlock working functionality).
- **Proposed fix:** Export an App Store archive and run `codesign -d --entitlements - QuickStudy.app` to confirm the value, then run one hosted generation from a TestFlight build against production. If it reads `development`, set the entitlement to `production` for the Release configuration, using a Release-only entitlements file.
- **Effort:** S

### ASR-006 — The first-run hosted generation has no fallback: offline or on attestation failure, an AI-capable device cannot make its first set
- **Severity:** Medium · **Rejection likelihood:** Medium
- **File:** QuickStudy/State/StudyViewModel.swift:231-251
- **What is wrong:** Only `CardGenerationError.notSubscribed` falls back to on-device. A network error, attestation failure, `hostedUnavailable` or `quota_exhausted` on the free first generation ends in an error screen, even when the on-device model is ready.
- **Evidence:**
  ```swift
  } catch CardGenerationError.notSubscribed {
      if !store.isPro { store.markFreeHostedGenerationUsed() }
      do { return try await draft(...) } ...
  } catch {
      generationErrorMessage = Self.message(for: error)   // no fallback
  ```
  - A reviewer who tests first-run with no network (or during a Worker outage) on an Apple Intelligence device sees "Something went wrong" right after onboarding promised "Works offline".
  - Retry repeats the hosted attempt, because `freeHostedGenerationUsed` never flips.
  - Guideline 2.1 (crashes/bugs in review) and 4.2 (minimum functionality on first run).
- **Proposed fix:** For non-Pro users, when a hosted attempt fails for any reason other than user input (for example, anything except `hostedInputTooLarge`) and `OnDeviceModelAvailability.isAvailable`, retry on `OnDeviceCardGenerationEngine`. ASR-002(a) makes this moot for AI-capable devices.
- **Effort:** S

### ASR-007 — Analytics are on by default, sent to the server, declared with the wrong purpose, and absent from the policy
- **Severity:** Medium · **Rejection likelihood:** Medium
- **Files:**
  - QuickStudy/Models/Analytics/AnalyticsRecorder.swift:34
  - QuickStudy/PrivacyInfo.xcprivacy:48-57
- **What is wrong:** `isEnabled` defaults to `true`, so funnel counters are posted with App Attest signing from first launch without a prompt. The manifest declares Product Interaction for `AppFunctionality` rather than `Analytics`.
- **Evidence:**
  ```swift
  isEnabled = defaults.object(forKey: Self.enabledKey) as? Bool ?? true
  ```
  ```xml
  <string>NSPrivacyCollectedDataTypeProductInteraction</string> … <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
  ```
  - The counters include paywall shown/dismissed, days since install, and whether the device has an on-device model. The request is authenticated with a per-device App Attest key ID in the `X-Key-Id` header, so the server can see which device a report came from, even though it stores aggregates only.
  - Guidelines 5.1.1(i) and 5.1.2(i) apply, as does App Privacy label accuracy (the Usage Data → Analytics purpose). The policy says "no analytics" (ASR-001).
- **Proposed fix:** Change the manifest purpose to `NSPrivacyCollectedDataTypePurposeAnalytics`, keeping AppFunctionality if you also claim it. Declare Usage Data › Product Interaction › Analytics in App Store Connect and cover it in the policy. Opt-in is not strictly required for non-tracking aggregate analytics, but defaulting to off, or asking once in onboarding, removes the risk.
- **Effort:** S

### ASR-008 — External API mode sends document text to OpenAI or Anthropic without an explicit permission step
- **Severity:** Medium · **Rejection likelihood:** Low
- **File:** QuickStudy/Views/Settings/SettingsView.swift:83-104
- **What is wrong:** Switching "AI Source" to External API and choosing a provider sends every later generation to `api.openai.com` or `api.anthropic.com`. No in-app disclosure or consent names that recipient.
- **Evidence:** The picker, `SecureField("API Key")` and the endpoint fields have no footer. The paste sheet's privacy line is hidden entirely when `mode != .onDevice` (PasteTextSheet.swift:104), so nothing tells the user where the text goes. Guideline 5.1.2(i) (third-party AI, explicit permission). The user supplying their own key makes intent obvious, which is why likelihood is Low.
- **Proposed fix:** Add a Section footer, plus a one-time confirmation when switching to External API. For example: "Your notes will be sent to OpenAI (or Anthropic) using your key, under that provider's privacy policy." Show "Sent to <provider> with your key" on the paste sheet and in `GeneratingView`.
- **Effort:** S

### ASR-009 — The privacy policy can only be reached from inside the paywall
- **Severity:** Medium · **Rejection likelihood:** Low
- **File:** QuickStudy/Views/Settings/SettingsView.swift:136-161
- **What is wrong:** Settings has a Privacy section (the analytics toggle) and an About section, but no privacy policy link. The only in-app route is the `SubscriptionStoreView` policy button.
- **Evidence:** No `Link(`, `openURL` or `privacyPolicyURL` reference exists outside PaywallView.swift (grep). Guideline 5.1.1(i): the policy link must be "easily accessible" within the app.
- **Proposed fix:** Add a `Link("Privacy Policy", destination: privacyPolicyURL)` row to Settings › About, or to the Privacy section. Move the URL constant somewhere shared.
- **Effort:** S

### ASR-010 — The quota-exhausted screen points to a Type cards feature that AI-capable devices cannot reach
- **Severity:** Medium · **Rejection likelihood:** Low
- **Files:**
  - QuickStudy/Models/Import/ImportFailure.swift:97
  - QuickStudy/Views/Library/LibraryView.swift:106-124
  - QuickStudy/Views/Library/LibraryViewModel.swift:43-44
- **What is wrong:** The tip "Type cards by hand from the Library in the meantime." is shown to every user who runs out of generations. `TypeCardsView` is reachable only when `isManualOnly` is true, which requires a device with no on-device model.
- **Evidence:**
  ```swift
  isManualOnly = noLocalModel && !store.isPro && store.freeHostedGenerationUsed
  ```
  On an Apple Intelligence device with the quota exhausted, `FloatingCreateButton` opens the paywall (LibraryView.swift:119-120) and there is no manual entry point. Guideline 2.1 (a feature that is described but unreachable) and 2.3.1.
- **Proposed fix:** Also show `AddCardsSection` / the Type cards route when `GenerationAllowance.isExhausted && !store.isPro`, or remove the tip.
- **Effort:** S

### ASR-011 — `APP_STORE_ASSETS_GUIDE.md` drafts App Store metadata that is now false
- **Severity:** Medium · **Rejection likelihood:** High if the text is used
- **Files:**
  - APP_STORE_ASSETS_GUIDE.md:99-138 (suggested description)
  - PRIVACY_MANIFEST_SETUP.md:48-65
- **What is wrong:** The suggested description claims "No internet required – all processing happens on your device", "All data stays on your device", "No cloud storage", "Flip-through flashcards" and "Track your progress with approved cards". None of these match the shipped app: the first generation and Pro are hosted, there is no flip mode, and there is no approval step. The manifest guide also documents only Photos/Videos.
- **Evidence:** See the quoted lines in the guide. Guideline 2.3.1 / 2.3.7 (metadata must reflect the app) and 3.1.2 (the subscription must be described in metadata). Pro and its price/term are not mentioned in the description at all.
- **Proposed fix:** Rewrite the description around the real flows, including the Pro subscription (name, term, what it unlocks, the 150/month limit) and the cloud processing disclosure. Refresh PRIVACY_MANIFEST_SETUP.md to match the actual manifest.
- **Effort:** S

### ASR-012 — On a device with no on-device model, the Today screen advertises generation that cannot happen
- **Severity:** Low · **Rejection likelihood:** Low
- **Files:**
  - QuickStudy/Views/Today/Components/AICardsLeftView.swift:45-47
  - QuickStudy/Views/Today/TodayView.swift:68-75
  - QuickStudy/Views/Today/TodayViewModel.swift:84-85
- **What is wrong:** After the one free hosted generation, a no-model device still shows "N of 10 free generations left this month". `canGenerate` stays true, so the SUGGESTED row is still offered, and tapping it ends in "This iPhone doesn't support on-device AI." (QS-601).
- **Evidence:** `canGenerate = isPro || !GenerationAllowance.isExhausted` ignores device capability. `generateSuggestedCards` calls `AIController.makeGenerator`, which returns `OnDeviceCardGenerationEngine`, whose `check()` throws `deviceNotEligible`. Guideline 2.1 (a dead-end path) and 2.3.1.
- **Proposed fix:** Feed `LibraryViewModel.isManualOnly` (or an equivalent capability flag) into `TodayViewModel`. Hide the suggestion and change the pill to point to Pro on those devices.
- **Effort:** S

### ASR-013 — With Apple Intelligence off or still downloading, the error screen's only actions repeat the same failure
- **Severity:** Low · **Rejection likelihood:** Low
- **Files:**
  - QuickStudy/Models/Import/ImportFailure.swift:38-51
  - QuickStudy/Models/AI/Engine/AICapability.swift:36-41
- **What is wrong:** `appleIntelligenceNotEnabled` and `modelNotReady` put the user on `.generation(...)`, which offers only "Edit text" and "Try again". Neither can succeed until the system state changes. These devices are not `isManualOnly`, so Type cards is not offered either.
- **Evidence:** The message is clear ("Turn on Apple Intelligence in Settings…", QS-602). There is no settings route and no alternative path, so this is low risk under Guideline 2.1 / 4.2 and not a crash.
- **Proposed fix:** For QS-602 and QS-603, replace the recoveries with "Type cards instead" and, for QS-603, "Try again later". Optionally check `AICapability.state` before capture so the user doesn't scan pages that cannot be processed.
- **Effort:** S

### ASR-014 — A shipping alert refers to the simulator
- **Severity:** Low · **Rejection likelihood:** Low
- **File:** QuickStudy/Views/Import/ImportModifiers.swift:21-25
- **What is wrong:** The only copy for `VNDocumentCameraViewController.isSupported == false` on a real device is "Document scanning isn't available in the simulator. Try on a real device."
- **Evidence:** Guideline 2.3 / 2.1: developer-facing text in a release build.
- **Proposed fix:** Use device-appropriate copy, for example "Document scanning isn't available on this device. Import a photo or PDF instead.", with Photo and PDF actions.
- **Effort:** S

### ASR-015 — Settings says three sample sets; the app installs four
- **Severity:** Low · **Rejection likelihood:** Low
- **Files:**
  - QuickStudy/Views/Settings/SettingsView.swift:133
  - QuickStudy/Models/Demo/DemoData.swift:32, 65, 92, 119
- **What is wrong:** The footer says "Adds three example sets". `DemoData` defines four (HIG, SwiftUI Essentials, SpriteKit, Core Data), and onboarding says "4 sample sets" (OnboardingFirstSourcePage.swift:32).
- **Evidence:** Guideline 2.3 (accuracy).
- **Proposed fix:** Change the footer to "four".
- **Effort:** S

### ASR-016 — A leftover simulator screenshot ships in the asset catalog
- **Severity:** Low · **Rejection likelihood:** Low
- **File:** QuickStudy/Assets.xcassets/simulator_screenshot_CAA87D66-011E-4891-8E7C-87C4C4895460.imageset (75 KB)
- **What is wrong:** An unreferenced simulator screenshot is bundled into the app.
- **Evidence:** A `grep` for the name finds no references outside the xcassets folder. This is a Guideline 2.3 / 2.5 hygiene issue, and the project's no-dead-code rule also covers it.
- **Proposed fix:** Delete the imageset.
- **Effort:** S

### ASR-017 — Export compliance key missing; iPad build carries iPhone-only copy; privacy manifest over-declares
- **Severity:** Low · **Rejection likelihood:** Low
- **Files:**
  - QuickStudy.xcodeproj/project.pbxproj:354-376
  - QuickStudy/PrivacyInfo.xcprivacy:35-45, 62-69
  - QuickStudy/Views/Library/Components/AddCardsSection.swift:51
  - QuickStudy/Models/AI/Engine/CardGenerationError.swift:47
  - QuickStudy/Views/Paywall/Components/PaywallHeaderView.swift:21
- **What is wrong:** Three small submission gaps:
  - **Export compliance:** No `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` is set, so App Store Connect asks the export compliance question on every build. The app uses only HTTPS and CryptoKit SHA-256, which is exempt.
  - **iPad copy:** `TARGETED_DEVICE_FAMILY = "1,2"` ships to iPad, but user-facing copy says "iPhone" throughout. Examples: "AI card generation needs an iPhone with Apple Intelligence (iPhone 15 Pro or later)" and "This iPhone doesn't support on-device AI." iPad screenshots will also be required.
  - **Manifest over-declaration:** The manifest declares Photos/Videos as collected, but images never leave the device; only OCR text does. It also declares FileTimestamp C617.1, but no timestamp API is used (grep for `creationDate`, `modificationDate`, `attributesOfItem`, `resourceValues` finds nothing). `NSPhotoLibraryUsageDescription` ("We use photos to let the user be able to import study notes…") is unnecessary with `PhotosPicker` and is awkwardly worded.
- **Evidence:** Guideline 2.4.1 covers iPad. Apple's manifest documentation says to declare only data that is actually collected. Over-declaring doesn't cause rejection, but it inflates the privacy label.
- **Proposed fix:**
  - Add `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`.
  - Use device-neutral copy ("this device") or `UIDevice.current.model`.
  - Drop the PhotoVideo and FileTimestamp entries.
  - Remove the photo-library string, or reword it to "QuickStudy reads text from photos you pick to make flashcards."
- **Effort:** S

---

## Verified (passed)

- **Camera usage string:** `NSCameraUsageDescription` is present and specific ("We use the camera to scan documents for studying.", project.pbxproj:355/392). Onboarding shows a pre-permission card only when the status is `.notDetermined`, and "Maybe later" skips it (OnboardingViewModel.swift:48-49, OnboardingCameraPage.swift:43).
- **Photo import:** Uses `PhotosPicker` (ImportModifiers.swift:89-93), which runs out of process and needs no library permission. No `PHPhotoLibrary` authorization is requested.
- **Restore purchases:** Visible on every paywall via `.storeButton(.visible, for: .restorePurchases)` (PaywallView.swift:30). The paywall is reachable from Settings › Upgrade, the Today generations pill, the quota exhausted state, the truncation notice and onboarding.
- **Terms of Use and Privacy Policy:** Set with `.subscriptionStorePolicyDestination(url:for:)` for `.termsOfService` and `.privacyPolicy` (PaywallView.swift:33-34). The Terms link is Apple's standard EULA, which is acceptable if App Store Connect also uses the standard EULA. The privacy URL resolves (HTTP 200); its content fails (ASR-001).
- **Price, term and trial:** Rendered by the system `SubscriptionStoreView` from StoreKit product data, including the 1-week free intro offer on monthly (QuickStudy.storekit). No custom price text in the app can drift from StoreKit.
- **Paywall dismissal:** Every paywall is a `.sheet` with no `interactiveDismissDisabled` (grep), so all are swipe-dismissible. The onboarding paywall appears only after the user's first self-made set, not as a gate before app use (ContentView.swift:87-96). I did not confirm whether `SubscriptionStoreView` draws its own close button by default in a sheet (the code comment at PaywallView.swift:24 claims it does). Swipe-to-dismiss makes this non-blocking either way.
- **Manage subscription:** `.manageSubscriptionsSheet` is offered when Pro is active (SettingsView.swift:116, 165).
- **Transactions:** `Transaction.updates` is observed and verified transactions are finished (StoreController.swift:30-35). Entitlement comes from `currentEntitlements` and excludes revoked and expired transactions.
- **Account deletion (5.1.1(v)):** There are no accounts or sign-in anywhere, so it does not apply. Local "Delete All Study Sets" exists.
- **User-generated content (1.2):** Generated content is private to the device. There is no sharing, publishing, `ShareLink` or social surface (grep), so 1.2 moderation requirements are not triggered.
- **Foundation Models availability:** Every `SystemLanguageModel.Availability` case is handled, including an `.unavailable` catch-all (OnDeviceModelAvailability.swift:16-27). `.deviceNotEligible` maps to a manual Type cards path once the free hosted generation is spent. `.appleIntelligenceNotEnabled`, `.modelNotReady` and `.unsupportedLanguageOrLocale` map to clear user-facing messages with error codes. `prewarm()` is guarded by `isAvailable`. There are no force-unwraps on these paths, and no crash path was found.
- **Debug hooks:** `QS_API_URL` is compiled only under `#if DEBUG`, and `QS_DEV_TOKEN` only under `#if DEBUG && targetEnvironment(simulator)` (HostedAPI.swift:56-71). The scheme's Release configuration has no environment overrides, and the StoreKit config file is referenced by the scheme only for local runs.
- **Code hygiene:** No `print(`, `TODO`, `FIXME`, "lorem", "beta", "coming soon" or `example.com` in the app target (grep).
- **Credentials and tracking:** The API key is stored only in Keychain (AISettings.swift:37-39, KeychainManager). There are no third-party SDKs, `NSPrivacyTracking` is false, and there are no tracking domains.
- **Required-reason APIs:** `UserDefaults` is declared with CA92.1. No disk-space, system-boot-time or active-keyboard APIs are used (grep for `systemUptime`, `mach_absolute_time`, `volumeAvailableCapacity`, `systemFreeSize`, `activeKeyboards`).
- **App Attest capability:** The `com.apple.developer.devicecheck.appattest-environment` entitlement is declared (value questioned in ASR-005). `DCAppAttestService.isSupported` is checked before key generation (AppAttestClient.swift:56).
- **TypeCardsView:** Wired, not dead. It is reachable from `LibraryView` (FloatingCreateButton and AddCardsSection) when `isManualOnly`, and saves a real `StudySet`.
- **Minimum functionality (4.2):** Three live tabs, import (scan, photo, PDF, paste), review, spaced-repetition quiz, session summary, streaks and stats. Demo sets let a reviewer exercise the study loop without generating.
