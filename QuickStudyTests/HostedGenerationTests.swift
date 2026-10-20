//
//  HostedGenerationTests.swift
//  QuickStudyTests
//

import Foundation
import Testing
@testable import QuickStudy

struct HostedGenerationTests {
    @Test func serverErrorCodesMapToDistinctCases() {
        let cases: [(String, String)] = [
            ("unauthorized", "QS-702"),
            ("not_subscribed", "QS-703"),
            ("quota_exhausted", "QS-729"),
            ("input_too_large", "QS-713"),
            ("model_unavailable", "QS-753"),
            ("something_new", "QS-753"),
        ]
        for (code, expected) in cases {
            #expect(HostedAPI.error(code: code, message: "m").code == expected)
        }
    }

    @MainActor
    @Test func aSpentFreeGenerationIsItsOwnCaseForFreeUsers() {
        let spent = CardGenerationError.freeHostedGenerationUsed
        #expect(spent.code == "QS-708")
        #expect(spent.errorDescription?.contains("Pro subscription") == false)
        #expect(AIController.spendsFreeHostedGeneration(spent))
        #expect(AIController.fallsBackOnDevice(after: spent, isPro: false))
    }

    @Test func verificationFailuresNeverShowServerText() {
        let internals = "x5c certificate chain does not verify"
        for code in ["unauthorized", "not_subscribed", "model_unavailable", "input_too_large"] {
            #expect(HostedAPI.error(code: code, message: internals).errorDescription != internals)
        }
    }

    @Test func quotaMessageIsShownVerbatim() {
        let error = HostedAPI.error(code: "quota_exhausted", message: "Monthly Pro generations are used up.")
        #expect(error.errorDescription == "Monthly Pro generations are used up.")
    }

    @Test func hostedEngineNeverSpendsTheOnDeviceAllowance() {
        let engine = HostedCardGenerationEngine(api: HostedAPI(baseURL: HostedAPI.production), transaction: nil) { _ in }
        #expect(engine.countsAgainstAllowance == false)
    }

    @Test func bringYourOwnKeyNeverSpendsTheAllowance() {
        let engine = APICardGenerationEngine(endpoint: HostedAPI.production, model: "m", apiKey: "k")
        #expect(engine.countsAgainstAllowance == false)
    }

    @MainActor
    @Test func freeUsersFallBackOnAnythingButOversizedInput() {
        #expect(AIController.fallsBackOnDevice(after: CardGenerationError.hostedUnavailable("m"), isPro: false))
        #expect(AIController.fallsBackOnDevice(after: CardGenerationError.attestationUnavailable, isPro: false))
        #expect(AIController.fallsBackOnDevice(after: CardGenerationError.networkError("m"), isPro: false))
        #expect(!AIController.fallsBackOnDevice(after: CardGenerationError.hostedInputTooLarge("m"), isPro: false))
        #expect(!AIController.fallsBackOnDevice(after: CancellationError(), isPro: false))
    }

    @MainActor
    @Test func proFallsBackOnlyWhenTheServerCannotServeThem() {
        #expect(AIController.fallsBackOnDevice(after: CardGenerationError.networkError("m"), isPro: true))
        #expect(AIController.fallsBackOnDevice(after: CardGenerationError.hostedQuotaExhausted("m"), isPro: true))
        #expect(AIController.fallsBackOnDevice(after: CardGenerationError.hostedInputTooLarge("m"), isPro: true))
        #expect(!AIController.fallsBackOnDevice(after: CardGenerationError.hostedUnavailable("m"), isPro: true))
    }

    @MainActor
    @Test func privateCloudFailuresAlwaysMoveOnUnlessCancelled() {
        for isPro in [false, true] {
            #expect(AIController.movesOn(after: CardGenerationError.privateCloudQuotaReached(resetsAt: nil), from: .privateCloud, isPro: isPro))
            #expect(AIController.movesOn(after: CardGenerationError.guardrailViolation, from: .privateCloud, isPro: isPro))
            #expect(!AIController.movesOn(after: CancellationError(), from: .privateCloud, isPro: isPro))
        }
    }

    @MainActor
    @Test func serverHandsOffByTheFallbackRules() {
        #expect(AIController.movesOn(after: CardGenerationError.hostedQuotaExhausted("m"), from: .cloud, isPro: true))
        #expect(!AIController.movesOn(after: CardGenerationError.hostedUnavailable("m"), from: .cloud, isPro: true))
        #expect(!AIController.movesOn(after: CardGenerationError.networkError("m"), from: .onDevice, isPro: false))
        #expect(!AIController.movesOn(after: CardGenerationError.networkError("m"), from: .externalAPI, isPro: false))
    }

    @Test func proSendsOnlyMidLengthDocumentsToTheServerFirst() {
        let serverLimit = HostedCardGenerationEngine.maxInputLength
        #expect(AIController.privateCloudTakes(sourceLength: serverLimit, isPro: false))
        #expect(AIController.privateCloudTakes(sourceLength: AIController.proPrivateCloudLimit, isPro: true))
        #expect(!AIController.privateCloudTakes(sourceLength: AIController.proPrivateCloudLimit + 1, isPro: true))
        #expect(!AIController.privateCloudTakes(sourceLength: serverLimit, isPro: true))
        #expect(AIController.privateCloudTakes(sourceLength: serverLimit + 1, isPro: true))
    }

    @MainActor
    @Test func consentRoundTripsAndResets() {
        let suiteName = "HostedGenerationTests.consent.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(HostedConsent.storedDecision(defaults: defaults) == nil)
        HostedConsent.record(.declined, defaults: defaults)
        #expect(HostedConsent.storedDecision(defaults: defaults) == .declined)
        HostedConsent.reset(defaults: defaults)
        #expect(HostedConsent.storedDecision(defaults: defaults) == nil)
    }

    @MainActor
    @Test func grantsGivenBeforePrivateCloudAreAskedAgain() {
        let suiteName = "HostedGenerationTests.legacyConsent.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("granted", forKey: "qs_hostedConsent")
        #expect(HostedConsent.storedDecision(defaults: defaults) == nil)
        defaults.set("declined", forKey: "qs_hostedConsent")
        #expect(HostedConsent.storedDecision(defaults: defaults) == .declined)
        HostedConsent.record(.granted, defaults: defaults)
        #expect(HostedConsent.storedDecision(defaults: defaults) == .granted)
    }

    @Test func productIdentifiersMatchTheServerContract() {
        #expect(ProProduct.identifiers == [
            "com.henley.jaiden.QuickStudy.pro.monthly",
            "com.henley.jaiden.QuickStudy.pro.yearly",
        ])
    }
}
