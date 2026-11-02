//
//  ElapsedTimerText.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/23/26.
//

import Combine
import SwiftUI

struct ElapsedTimerText: View {
    let label: (Date) -> String

    @State private var now = Date()
    @State private var ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(label(now))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .appNumericTransition()
            .appAnimation(Motion.snappy, value: now)
            .onReceive(ticker) { now = $0 }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Elapsed time")
            .accessibilityValue(spokenValue)
            .accessibilityAddTraits(.updatesFrequently)
    }

    // The label is "m:ss"; spoken as a duration so VoiceOver does not read the colon.
    private var spokenValue: String {
        let parts = label(now).split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return label(now) }
        return Duration.seconds(parts[0] * 60 + parts[1])
            .formatted(.units(allowed: [.minutes, .seconds], width: .wide))
    }
}
