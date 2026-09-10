//
//  TimerIndicator.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct TimerIndicator: View {
    let duration: TimeInterval
    @State private var progress: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: duration), value: progress)
        }
        .onAppear {
            progress = 1.0
        }
    }
}
