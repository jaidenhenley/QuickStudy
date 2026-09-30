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
            .contentTransition(.numericText())
            .appAnimation(Motion.snappy, value: now)
            .onReceive(ticker) { now = $0 }
    }
}
