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

    @Test func serverMessageIsShownVerbatim() {
        let error = HostedAPI.error(code: "not_subscribed", message: "Free generation already used.")
        #expect(error.errorDescription == "Free generation already used.")
    }

    @Test func hostedEngineNeverSpendsTheOnDeviceAllowance() {
        let engine = HostedCardGenerationEngine(api: HostedAPI(baseURL: HostedAPI.production), transaction: nil) { _ in }
        #expect(engine.countsAgainstAllowance == false)
    }

    @Test func productIdentifiersMatchTheServerContract() {
        #expect(ProProduct.identifiers == [
            "com.henley.jaiden.QuickStudy.pro.monthly",
            "com.henley.jaiden.QuickStudy.pro.yearly",
        ])
    }
}
