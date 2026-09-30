# 04 — Monetization Audit

Branch `jh/edgeCaseStates`, 2026-09-22. Read-only audit of the QuickStudy app and `~/Desktop/CurrentProjects/quickstudy-api`, covering the monetization model the code actually implements.

**Corrections to `00-map.md`:**
- The yearly price is **$39.99**, not the $29.99 in CLAUDE.md (`QuickStudy.storekit:48`). The map has this right; CLAUDE.md is wrong.
- `TypeCardsView` is the manual two-field card editor. It is not a "future typed-answer quiz".
- On-device `sourceChunkLimit` is **1200**, not nil (`OnDeviceCardGenerationEngine.swift:19,23`).
- The free hosted generation goes to **every** device, not only devices without an on-device model (`StoreController.swift:27`, `AIController.swift:57`).

Severity counts: **Blocker 0 · High 4 · Medium 8 · Low 11**

---

## Findings

### MON-001 — High — The truncation upsell says content was dropped when it wasn't
- **File:** `Views/Review/Components/TruncationNoticeRow.swift:20,24`; `State/StudyViewModel.swift:266`; `Models/AI/Engine/OnDeviceCardGenerationEngine.swift:74-90`
- **What is wrong:** Almost every on-device draft longer than 1,200 characters shows "Only the first 1,200 characters were used · Generate from the whole document with Pro ›". But the on-device engine drafts from every chunk of the document.
- **Evidence:**
  ```swift
  // StudyViewModel.swift:266
  lastGenerationWasTruncated = engine.sourceChunkLimit.map { text.count > $0 } ?? false
  // OnDeviceCardGenerationEngine.swift
  let chunks = SentenceIndexer.chunks(of: sentences, maxLength: Self.chunkLength)
  for chunk in chunks { allCards += try await cards(for: chunk) ... }
  ```
  So `wasTruncated` means "was chunked", not "was cut". The notice drives users to the paywall (`ReviewDraftsView.swift:74-75`, surface `.truncation`) with a false statement. That is an App Review Guideline 2.3.1 / 3.1.2 risk: misleading claims used to sell a subscription.
- **Proposed fix:** Choose one:
  - Delete the notice and the `.truncation` surface.
  - Or, if hosted single-pass output is really better than chunked output, reword it to something true and back it with a design string. The current copy is not in Final v2.

  Rename `wasTruncated` / `sourceChunkLimit` semantics so "chunked" and "cut" can't be confused again.
- **Effort:** S

### MON-002 — High — Devices without Apple Intelligence (Pro's core buyers) are told to buy a new iPhone
- **File:**
  - `Views/Library/Components/AddCardsSection.swift:51`
  - `Views/Library/LibraryView.swift:116-124`
  - `Views/Library/LibraryViewModel.swift:44`
  - `Views/Today/TodayViewModel.swift:83-85`
  - `Views/Today/Components/AICardsLeftView.swift:45-47`
- **What is wrong:** Once the one free hosted generation is spent, the Library says AI "needs an iPhone with Apple Intelligence (iPhone 15 Pro or later)". The create button opens Type Cards instead of the paywall. The Today pill claims "10 of 10 free generations left" that this device cannot use.
- **Evidence:**
  - Pro's only product description is "Cloud generation on any iPhone." (`QuickStudy.storekit:34`), and the paywall's feature list includes "Works on every iPhone" (`PaywallHeaderView.swift:21`).
  - For this segment, `isManualOnly = noLocalModel && !store.isPro && store.freeHostedGenerationUsed`, so `FloatingCreateButton` → `showTypeCards = true`. No paywall is presented.
  - `generationsRemaining` comes from `GenerationAllowance`. That counter is never decremented for hosted generations, so the pill reads 10/10.
  - `canGenerate` stays true, so the `SUGGESTED` row still shows on Today (`TodayView.swift:69`). Tapping it fails with `deviceNotEligible` (QS-601).
- **Proposed fix:**
  - In manual-only mode, make the create button and `AddCardsSection` offer Pro ("Generate with QuickStudy Pro ›" → `PaywallView(surface: .exhausted)` or a new surface), keeping Type cards as the secondary action.
  - Replace the "needs an iPhone with Apple Intelligence" line with copy that names Pro.
  - Make `TodayViewModel` report 0 generations remaining and `canGenerate = false` when `LibraryViewModel`'s manual-only condition holds, so the pill and the suggestion match reality.
  - New copy has no Final v2 source; flag it for the user.
- **Effort:** S

### MON-003 — High — The first generation always goes to the server and has no offline fallback, even on Apple Intelligence devices
- **File:** `Models/Store/StoreController.swift:27`; `Models/AI/Engine/AIController.swift:23,56-62`; `State/StudyViewModel.swift:231-251`
- **What is wrong:** `willUseHostedGeneration` is true for every new install. So the first set on an Apple Intelligence iPhone is sent to the Worker. Offline, that request fails with QS-504, and neither the retry nor any fallback ever uses the on-device model.
- **Evidence:**
  - Code: `var willUseHostedGeneration: Bool { transactionJWS != nil || !freeHostedGenerationUsed }`. `NetworkMonitor` is never consulted. `generateCards` only catches `.notSubscribed`; `networkError`, `hostedUnavailable` and `deviceAttestationFailed` fall straight to the error screen.
  - The onboarding page that makes this promise (`OnboardingAIIntroPage.swift:44-47`) also says "Works offline — Generate and study on the plane".
  - CLAUDE.md (Privacy & Credentials) says to send user content to the Pro server only when "the user is Pro or the device has no on-device model and its one free hosted generation is unspent". The current routing contradicts that project rule. The onboarding footnote (`:69`) discloses cloud drafting, but the scan, PDF and photo paths show no per-generation notice; only the paste sheet does.
- **Proposed fix:** Choose one:
  - (a) Follow CLAUDE.md: gate the free hosted generation on `AICapability.state == .unsupportedDevice`.
  - (b) Keep the "best first impression" strategy, update CLAUDE.md, skip hosted when `NetworkMonitor` reports offline, and on hosted transport or attestation failure (`networkError`, `hostedUnavailable`, `deviceAttestationFailed`, `attestationUnavailable`) retry on-device when the model is available.

  Either way it is a routing decision in `AIController`. Cross-reference the privacy audit.
- **Effort:** S

### MON-004 — High — Pro is advertised as unlimited, but it is capped at 150 a month
- **File:** `Models/Import/ImportFailure.swift:98`; `Views/Paywall/Components/PaywallHeaderView.swift:23`
- **What is wrong:** The quota-exhausted screen says "QuickStudy Pro generates without a monthly cap". The paywall pairs an `infinity` symbol with "150 generations a month". The server enforces 150 (`quota.ts:36`, `PRO_MONTHLY_LIMIT = "150"`).
- **Evidence:**
  ```swift
  "QuickStudy Pro generates without a monthly cap, on any iPhone."
  PaywallFeatureRow(symbol: "infinity", text: "\(ProProduct.hostedMonthlyLimit) generations a month")
  ```
  Guideline 3.1.2(a) requires clear description of what the subscriber gets, and 2.3.1 prohibits misleading marketing. A capped subscriber hitting 429 with "Monthly Pro generations are used up." after being told "without a monthly cap" is a refund and review-rejection risk.
- **Proposed fix:** Change the tip to "QuickStudy Pro includes 150 generations a month, on any iPhone." and swap the `infinity` symbol for a non-unlimited glyph (e.g. `sparkles`).
- **Effort:** S

### MON-005 — Medium — Manual cards are promised as always free, but AI-capable users can't reach them
- **File:** `Views/Library/LibraryView.swift:106-124`; `Models/Import/ImportFailure.swift:97`; `Views/Onboarding/Components/OnboardingAIIntroPage.swift:51-52`
- **What is wrong:** `TypeCardsView` is reachable only when `isManualOnly` is true. At 0 free generations, an Apple Intelligence user's create button opens only the paywall. Yet onboarding promises "Manual cards and every study mode are always unlimited", and the exhausted screen says "Type cards by hand from the Library in the meantime."
- **Evidence:** `showTypeCards = true` appears only under `if libraryViewModel.isManualOnly` (`LibraryView.swift:106-108, 117-118`). `isManualOnly` requires `noLocalModel`.
- **Proposed fix:** When `!coordinator.canStartGeneration`, show `AddCardsSection` (or a Type cards row on the paywall or exhausted screen) as well as the paywall, so the free promise is reachable and the paywall doesn't read as a hard wall.
- **Effort:** S

### MON-006 — Medium — Subscribers lose Pro during Billing Grace Period on both the client and the server
- **File:** `Models/Store/StoreController.swift:48`; `quickstudy-api/src/entitlement.ts:81`
- **What is wrong:** Both sides treat `expirationDate <= now` as not entitled. During Billing Grace Period the latest transaction's expiration has already passed but Apple still considers the subscriber entitled. The app drops them to free, and the server returns `not_subscribed`.
- **Evidence:**
  ```swift
  if let expiration = transaction.expirationDate, expiration <= Date() { continue }
  ```
  ```ts
  if (!payload.expiresDate || payload.expiresDate <= Date.now()) throw new EntitlementError("Subscription has expired.");
  ```
  Per Apple's `Transaction.currentEntitlements` docs, auto-renewable subscriptions in the subscribed **or in-billing-grace-period** state are returned, so the extra client filter is what removes grace-period users. I could not verify whether Billing Grace Period is enabled in App Store Connect.
- **Proposed fix:**
  - Client: drop the redundant expiration filter, or read `Product.SubscriptionInfo.status(for:)` and treat `.inGracePeriod` as Pro.
  - Server: also accept the signed `JWSRenewalInfo` (send `status.renewalInfo.jwsRepresentation`) and honor `gracePeriodExpiresDate`, or query the App Store Server API subscription status.
  - Enable Billing Grace Period in App Store Connect; Apple recommends it for recovering involuntary churn.
- **Effort:** M

### MON-007 — Medium — Pro status goes stale after expiry or restore, and Pro refusals show raw certificate errors
- **File:**
  - `Views/Shared/ContentView.swift:68-71`
  - `Views/Paywall/PaywallView.swift:30,38-56`
  - `State/StudyViewModel.swift:233-240`
  - `quickstudy-api/src/generate.ts:86`
- **What is wrong:** `refreshEntitlement()` runs once at launch, after an in-app purchase completion, and when a `Transaction.updates` event arrives. It does not run on foreground and not after the paywall's Restore button.
  - An expired or cancelled subscriber keeps a local `isPro == true`, including the Settings "Active" row and the teal pill, until relaunch.
  - A Pro user's `notSubscribed` refusal retries the same hosted engine with the same stale JWS. The server's detail string is then shown verbatim.
- **Evidence:**
  - `if !store.isPro { store.markFreeHostedGenerationUsed() }` is followed by an identical `draft(...)` retry, with no `refreshEntitlement()`.
  - The server builds `EntitlementError(message, userFacing = false)` precisely because messages like "Transaction certificate chain does not verify." aren't user copy. But `generate.ts:86` sends `entitlement.message` regardless, and `CardGenerationError.notSubscribed(let message)` displays it.
  - Expiry creates no new transaction, so `Transaction.updates` does not fire for it.
  - I'm not certain whether `SubscriptionStoreView`'s restore emits on `Transaction.updates`; nothing else refreshes after it.
- **Proposed fix:**
  - Add `.subscriptionStatusTask(for: <groupID>) { _ in await store.refreshEntitlement() }` at the root. It is iOS 17+ and I believe it re-fires on status changes; verify the signature. Also refresh on `scenePhase == .active`.
  - On `.notSubscribed` while `isPro`, call `await store.refreshEntitlement()` first, then retry: on-device if Pro is gone, otherwise surface a resubscribe CTA.
  - On the server, return a fixed user-facing message unless `entitlement.userFacing`.
- **Effort:** S

### MON-008 — Medium — Pro users can't use the on-device model, so Pro is worse than free offline, at the cap, and on large documents
- **File:** `Models/AI/Engine/AIController.swift:23,57`; `Models/AI/Engine/HostedCardGenerationEngine.swift:21`; `quickstudy-api/src/generate.ts:80,87`
- **What is wrong:** When `isPro`, every generation is hosted. With no network, after 150 generations (429), or with input over 40,000 characters (413), the Pro user gets an error. The same iPhone on the free tier would have drafted on-device, and the paywall promises "Whole documents, not chunks".
- **Evidence:**
  - `hostedEngine` returns non-nil whenever `transactionJWS != nil`, and there is no fallback path.
  - Hosted `sourceChunkLimit = nil`, so the client neither splits nor warns before sending. The server returns `input_too_large` "Text must be under 40000 characters."
  - A multi-page PDF easily exceeds 40,000 characters.
- **Proposed fix:**
  - When the device has the model, fall back to on-device on `networkError`, `hostedQuotaExhausted` and `hostedUnavailable`.
  - For `hostedInputTooLarge`, split the text client-side into ≤40k segments. That spends N hosted generations, so decide how to count them. Alternatively, raise `MAX_INPUT_CHARS` and chunk on the server.
  - Consider whether Pro users should be able to choose on-device for privacy.
- **Effort:** M

### MON-009 — Medium — The free hosted generation is tracked per App Attest key, not per device, so each reinstall grants another
- **File:** `quickstudy-api/src/quota.ts:6-8,29,41`; `Models/AI/Engine/AppAttestClient.swift:17-22,31-36`
- **What is wrong:** The server records `free:{keyId}`. App Attest keys don't survive a reinstall (the client's own comment says so). The client then deletes the stale key ID and registers a fresh one, which the server treats as a brand-new free user. The `StoreController.swift:56-58` comment ("The server is the authority ... after a reinstall, say") is therefore wrong.
- **Evidence:**
  ```swift
  // Keychain outlives a reinstall but the Secure Enclave key it names does not ...
  try KeychainManager.delete(account: .appAttestKeyID)
  let fresh = try await registeredKeyID(using: api)
  ```
  The `unregistered_key` path (`HostedCardGenerationEngine.swift:35-37`) also re-keys.
  - **Cost:** about 0.25¢ per generation (per the server README).
  - **Impact:** a no-model device can reinstall repeatedly to get Pro's only feature for free. Reinstalling wipes `SavedSets.json`, which limits how often people will do it.
- **Proposed fix:**
  - Use DeviceCheck: the client sends `DCDevice.current.generateToken()` with `/generate`, and the server queries and updates the per-device two bits through Apple's DeviceCheck API. Those bits persist across reinstall; this is the use case they exist for.
  - This needs a DeviceCheck .p8 key on the server.
  - Keep `free:{keyId}` as a fast path.
- **Effort:** M

### MON-010 — Medium — Changing the device clock or reinstalling resets the monthly free allowance
- **File:** `Models/AI/GenerationAllowance.swift:24-27,33-36,43-46`
- **What is wrong:** `used` returns 0 whenever the stored month stamp differs from `Date()`'s month, in either direction. Setting the clock to any other month and back therefore resets the count. The counter lives in `UserDefaults`, so a reinstall clears it too.
- **Evidence:** `guard defaults.integer(forKey: monthKey) == monthStamp(for: now) else { return 0 }`
  - **Cost:** nothing; on-device generations cost the developer nothing.
  - **Impact:** conversion only.
- **Proposed fix:**
  - Store a high-water month stamp and treat `now < storedStamp` as the stored month, so going back never resets.
  - Persist `{used, month}` in Keychain via `KeychainManager` with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`; it survives reinstall and stays off iCloud Keychain.
  - A forward clock jump can't be detected offline. If needed, stamp the month from the Worker's `/attest/challenge` issued-at time when online.
  - Don't build more than this; the allowance protects conversion, not cost.
- **Effort:** S

### MON-011 — Medium — The server checks the transaction certificate chain but not Apple's certificate OIDs
- **File:** `quickstudy-api/src/entitlement.ts:32-44`
- **What is wrong:** `verifyChain` pins Apple Root CA - G3 and checks the signatures. It does not check the leaf for the App Store receipt-signing OID `1.2.840.113635.100.6.11.1` or the intermediate for `1.2.840.113635.100.6.2.1`. Any ES256 leaf that chains to Root G3 through any Apple intermediate would pass.
- **Evidence:** Apple's `app-store-server-library` `SignedDataVerifier` checks both OIDs, and optionally OCSP, in addition to the chain. I did not verify whether a third party can obtain an EC leaf private key under a Root-G3 intermediate (Apple lists WWDR G6 under Root G3). Treat this as defense-in-depth, not a confirmed exploit.
- **Proposed fix:**
  - Assert the two extension OIDs are present with `@peculiar/x509` `getExtension(oid)`.
  - Check `leaf.notBefore <= signedDate <= leaf.notAfter`.
  - Or port the checks from Apple's Node library.
- **Effort:** S

### MON-012 — Low — The server trusts the transaction snapshot the client sends, so a refund made after signing isn't seen
- **File:** `quickstudy-api/src/entitlement.ts:80-81`; `quickstudy-api/src/quota.ts:20-28`
- **What is wrong:** The server accepts any JWS whose embedded `expiresDate` is in the future. It has no revocation source of its own, so a refunded yearly subscription whose pre-refund JWS is replayed stays Pro until the original expiry.
- **Evidence:** No App Store Server Notifications endpoint exists (`routes.ts`), and no App Store Server API call is made. Exploiting this requires a hooked client to replay the old JWS past App Attest, for example on a jailbroken device. The quota is still capped at 150 a month per `originalTransactionId`.
- **Proposed fix:** Add a `/asn` route for App Store Server Notifications V2 (REFUND, REVOKE, EXPIRED). Write `revoked:{originalTransactionId}` to KV and check it in `resolveEntitlement`.
- **Effort:** M

### MON-013 — Medium — The paywall shows the same copy on every surface, and there is no warning before the last free generation
- **File:**
  - `Views/Paywall/PaywallView.swift:14,25-27`
  - `Views/Paywall/Components/PaywallHeaderView.swift`
  - `Views/Import/ImportCoordinator.swift:77-81`
  - `Views/Library/Components/NewSetSheet.swift`
- **What is wrong:**
  - `surface` is used only for analytics. The `.exhausted` paywall (opened straight from the create button at 0) never says why it appeared or when the allowance resets.
  - Nothing warns at 1 generation left.
  - The remaining count appears only in the Today pill and the paste sheet; the scan, photo and PDF paths never show it.
- **Evidence:** `presentPendingSource` → `presentPaywall()` with no message. `ImportFailure.quotaExhausted` (which does name the reset date) is reached only on the `draftOrFail` path, not from the create button. `AICardsLeftView` is hidden entirely until one generation is used or cards exist (`TodayViewModel.swift:85`).
- **Proposed fix:**
  - Pass the surface into `PaywallHeaderView` and add a one-line context row per surface, e.g. `.exhausted` → "You've used all 10 free generations · resets October 1". This is new copy with no Final v2 source; confirm with the user.
  - Show "Last free generation this month" on `GeneratingView`/`NewSetSheet` when `remaining == 1`.
- **Effort:** S

### MON-014 — Low — Bring-your-own-key generations count against the free allowance and send users to a paywall that doesn't apply
- **File:** `Models/AI/Engine/APICardGenerationEngine.swift:11`; `Views/Import/ImportCoordinator.swift:106-108`; `Views/Settings/SettingsView.swift:124`
- **What is wrong:**
  - A user paying their own OpenAI/Anthropic bill is capped at 10 a month and pushed to a Pro purchase that has no effect in `externalAPI` mode.
  - A Pro user in `externalAPI` mode is told "Cards are generated on QuickStudy's server" when they aren't.
- **Evidence:**
  - `APICardGenerationEngine.countsAgainstAllowance = true`.
  - `canStartGeneration` ignores the mode.
  - `AIController.makeGenerator` returns `APICardGenerationEngine` for `.externalAPI`, even when the user is Pro.
- **Proposed fix:**
  - Either set `countsAgainstAllowance = false` for the API engine and skip the allowance gate in `externalAPI` mode, or make BYOK explicitly Pro-only. That is a product decision; ask.
  - Make the Settings Pro footer conditional on `aiSettings.mode == .onDevice`.
- **Effort:** S

### MON-015 — Low — The Pro pill shows the full quota after every relaunch
- **File:** `Models/Store/StoreController.swift:17`; `Views/Today/Components/AICardsLeftView.swift:42`
- **What is wrong:** `hostedRemaining` exists only in memory, so after relaunch the pill reads "150 of 150 generations left this month" until the next hosted generation.
- **Evidence:** `let left = todayViewModel.hostedRemaining ?? todayViewModel.hostedLimit`
- **Proposed fix:** Persist `{remaining, monthStamp}` in `UserDefaults` (not secret). Or return `remaining` from a cheap signed call, or show "QuickStudy Pro" with no count until it's known.
- **Effort:** S

### MON-016 — Low — Some transactions are never explicitly finished
- **File:** `Views/Paywall/PaywallView.swift:38-46`; `Models/Store/StoreController.swift:31-33`
- **What is wrong:**
  - The purchase completion handler ignores the `VerificationResult` and never calls `finish()`.
  - Unverified transactions from `Transaction.updates` are never finished, so they are re-emitted on every launch.
- **Evidence:** In `case .success(.success):` the associated value is discarded. I am **not certain** whether `SubscriptionStoreView` finishes verified transactions itself when `onInAppPurchaseCompletion` is supplied. `Transaction.updates` does not deliver transactions returned directly from a purchase, so if the view doesn't finish it, the transaction stays unfinished until the next launch's replay.
- **Proposed fix:** Bind `case .success(.success(let verification))`, then `if case .verified(let t) = verification { await t.finish() }`. In the updates loop, finish unverified transactions too, after logging a code (not the content).
- **Effort:** S

### MON-017 — Low — Two `StoreController` instances run `Transaction.updates` listeners
- **File:** `State/StudyViewModel.swift:29`; `Views/Shared/ContentView.swift:19,74`
- **What is wrong:** `StudyViewModel` builds its own `StoreController()`, which starts a second listener. It is replaced in `onAppear`, so any generation routed before then uses an entitlement-less store.
- **Evidence:** `var store: StoreController = StoreController()` and `viewModel.store = store` in `.onAppear`.
- **Proposed fix:** Inject the store through `StudyViewModel.init(store:)`, or make it optional or required instead of defaulting.
- **Effort:** S

### MON-018 — Low — Both plans share one service level, and only monthly has a trial
- **File:** `QuickStudy/QuickStudy.storekit:24-31,50`
- **What is wrong:**
  - Both plans are `groupNumber: 1`. Monthly → yearly is therefore a crossgrade, which takes effect at the next renewal, rather than an immediate upgrade.
  - Only monthly has a free trial, which pushes trial-seekers toward the lower-value plan.
- **Evidence:** `"groupNumber": 1` on both products. `introductoryOffer` exists only on `pro.monthly`.
- **Proposed fix:** In App Store Connect, rank yearly at level 1 and monthly at level 2, and mirror that in `.storekit`. Consider moving or adding the 1-week trial on yearly (see Pro opportunities).
- **Effort:** S (config)

### MON-019 — Low — CLAUDE.md lists a different yearly price than the StoreKit file
- **File:** `CLAUDE.md` ("$29.99/yr"); `QuickStudy/QuickStudy.storekit:48` (`"39.99"`)
- **What is wrong:** The two sources disagree on the yearly price. App Store Connect decides the real price and was not checked.
- **Proposed fix:** Confirm the App Store Connect price, then correct whichever file is wrong.
- **Effort:** S

### MON-020 — Low — Production accepts Sandbox subscriptions with the full Pro quota
- **File:** `quickstudy-api/src/entitlement.ts:77-79`; README Environments table
- **What is wrong:** Production accepts Sandbox subscriptions with the full 150-per-month quota. TestFlight subscriptions are free and auto-renew, so any public TestFlight tester gets production hosted generation at no cost.
- **Evidence:** "StoreKit env accepted — Sandbox + Production (App Review uses Sandbox)". The `environment` value is returned but never used in quota.
- **Proposed fix:** Keep accepting Sandbox for App Review, but apply a small separate quota (e.g. `PRO_SANDBOX_MONTHLY_LIMIT = 20`) when `entitlement.environment === "Sandbox"`.
- **Effort:** S

### MON-021 — Low — Analytics never records a completed purchase
- **File:** `Models/Analytics/AnalyticsEvent.swift:19`; `quickstudy-api/src/metrics.ts:23`
- **What is wrong:** Only `purchaseInitiated` is recorded, so the funnel can't separate cancellations and failures from conversions.
- **Proposed fix:** Add a `purchaseCompleted` count, recorded where `PaywallView` confirms `store.isPro`, and add it to the server's allowed fields.
- **Effort:** S

### MON-022 — Low — The one free hosted generation can be spent on a small suggestion top-up
- **File:** `State/StudyViewModel.swift:306-332`; `Views/Today/TodayView.swift:69`
- **What is wrong:** `generateSuggestedCards` routes through `AIController`. A user who chose demo sets in onboarding can spend their one free hosted generation, meant as the "best first impression", on a small topic top-up for a demo set.
- **Evidence:**
  - `hostedEngine` doesn't distinguish the call type.
  - There is no `.notSubscribed` recovery in `generateSuggestedCards`, unlike `generateCards`.
  - Separately, Regenerate on a hosted draft (`ReviewDraftsView.swift:137`) falls to on-device and fails on no-model devices.
- **Proposed fix:** Reserve the free hosted generation for `makeDraft` by passing an `allowFreeHosted` flag to `makeGenerator`. Mirror the `.notSubscribed` handling in `generateSuggestedCards`.
- **Effort:** S

### MON-023 — Low — The server's quota check isn't atomic, so concurrent requests can exceed a limit
- **File:** `quickstudy-api/src/generate.ts:85-87,102`; `quickstudy-api/src/quota.ts:29,39-47`
- **What is wrong:** The free flag and the Pro counter are read before the 5–20 s model call and written after it. Concurrent requests from one key therefore both pass (up to 10 per minute by rate limit), and KV read-modify-write isn't atomic.
- **Proposed fix:** Write a `free:{keyId}` = "pending" reservation before calling the model (clear it on failure). Or move the counters into a Durable Object if Pro volume grows.
- **Effort:** S

---

## Pro opportunities

Ranked by expected revenue impact relative to build cost. Every item builds on code that already exists.

| Rank | Opportunity | Grounding in code | Impact | Cost |
|---|---|---|---|---|
| 1 | Sell Pro to devices without Apple Intelligence where they currently dead-end (MON-002) | `isManualOnly` branch, `AddCardsSection`, the pill; Pro's whole pitch is "any iPhone" | High: this is the segment with no free alternative | S |
| 2 | Put the paywall's context and the reset date on the exhausted and pre-exhaustion surfaces (MON-013) | `PaywallSurface` already exists and is plumbed; `GenerationAllowance.resetDate()` exists | High: this is the highest-intent moment | S |
| 3 | Yearly trial plus ranking yearly above monthly (MON-018) | `.storekit` config only | Medium–High: shifts mix to higher LTV | S |
| 4 | Keep Pro useful offline and at the cap by falling back to on-device (MON-008) | `OnDeviceCardGenerationEngine` already exists; routing is in one place | Medium: retention and churn | M |
| 5 | Honor Billing Grace Period (MON-006) | `refreshEntitlement`, `verifyTransaction` | Medium: recovers involuntary churn | M |
| 6 | Pro handles large documents by chunking hosted input over 40k (MON-008) | `SentenceIndexer.chunks` exists; server has `MAX_INPUT_CHARS` | Medium: makes "Whole documents" true for PDFs | M |
| 7 | Offer codes and win-back | `.offerCodeRedemption(isPresented:)` (iOS 16+) in Settings; `codeOffers: []` is empty today | Low–Medium: education channels (teachers, clubs) | S |
| 8 | Make weakest-topic drills ("SUGGESTED" → `generateSuggestedCards`) a Pro highlight | Feature exists and currently spends the free allowance | Low–Medium | S |
| 9 | Family Sharing | `familyShareable: false`; code doesn't check `ownershipType`, so no code change needed. Enabling it in App Store Connect is **irreversible** | Low–Medium (students and families) | S |
| 10 | Typed answers with semantic grading, as a Pro feature | CLAUDE.md: `AnswerGrading`/`AnswerGrader` were built and removed; deferred | Medium | L |

Undersold today: the paywall never mentions the generated `Why` explanations or source-linked cards. Both come from the same hosted call (`HostedCard.explanation`, `sourceExcerpt`) and are real quality differences users see in the quiz.

---

## Verified

- **Allowance timing:** `GenerationAllowance.recordGeneration()` runs only after `CardGenerator.generateAI` returns (`StudyViewModel.swift:273-274`).
  - Failed or thrown generations are not charged.
  - Killing the app mid-generation doesn't charge.
  - Regenerate passes `countsAgainstAllowance: false` and re-rolls the same `draft.document`, so it can't pull in new content.
- **Hosted generations and the allowance:** hosted generations don't touch `GenerationAllowance` (`HostedCardGenerationEngine.countsAgainstAllowance = false`), as CLAUDE.md says.
- **Generation gate:** `canStartGeneration` is checked both before the source picker (`presentPendingSource`) and again before drafting (`draftOrFail`), so a pending onboarding source can't bypass it.
- **Server metering:** the server consumes quota only after the model succeeds (`generate.ts:100-102`). A lost response after a free hosted success is reconciled by `.notSubscribed` → `markFreeHostedGenerationUsed()` → on-device retry.
- **Pro quota scope:** Pro quota is keyed by `originalTransactionId` per UTC month, so sharing a JWS across devices is still capped at 150 in total.
- **Server JWS checks:**
  - root pinned to Apple Root CA G3
  - intermediate and leaf signatures verified
  - ES256 signature verified over `header.payload`
  - `bundleId`, `productId` allow-list and `environment` checked
  - `revocationDate` and `expiresDate` checked
- **Client entitlement:**
  - `Transaction.updates` listener starts in `StoreController.init` and is held for the app's lifetime by root `@State`.
  - Verified update transactions are finished.
  - `currentEntitlements` is read at launch (`ContentView.swift:69`) and after each update.
  - Unverified results are skipped; `revocationDate` is honored, so refunds propagate via `Transaction.updates`.
- **Upgrades:** both products are in one subscription group, so `currentEntitlements` yields one latest transaction and `isUpgraded` doesn't need special handling.
- **Paywall mechanics:**
  - Restore button visible (`.storeButton(.visible, for: .restorePurchases)`).
  - Terms and Privacy policy destinations set.
  - Pending (Ask to Buy) and failure results surfaced.
  - Manage Subscription sheet available to Pro users in Settings.
- **Paywall placement:**
  - Onboarding paywall is deferred until the first user-created set, and skipped for Pro.
  - The pill's `Pro ›` opens the paywall and is disabled for Pro (approved deviation).
  - Settings has "Upgrade to QuickStudy Pro".
- **Config consistency:**
  - Product IDs in `ProProduct`, `.storekit`, and the Worker's `PRO_PRODUCT_IDS` match exactly.
  - `ProProduct.hostedMonthlyLimit = 150` matches `PRO_MONTHLY_LIMIT = "150"` on both Worker environments.
  - `.storekit` prices: monthly $4.99 with a 1-week free trial (P1W, `paymentMode: free`); yearly $39.99 with no trial.
  - Family sharing is off in `.storekit` and the code doesn't depend on it.
- **App Attest on the server:**
  - Assertions are verified against the stored SPKI.
  - `rpIdHash` is checked against `TEAMID.bundleId`.
  - The counter is monotonic (replay rejected).
  - The HMAC challenge expires after 5 minutes.
  - The dev-token bypass works only when `ENVIRONMENT === "dev"`, and `npm run deploy` targets `--env production`.
- **App Attest entitlement:** it is `development` in `QuickStudy.entitlements`. As I understand Apple's documentation, TestFlight and App Store builds ignore this entitlement and use production. Verify on the first TestFlight build that `/attest/register` succeeds against the production Worker, which accepts production only.
