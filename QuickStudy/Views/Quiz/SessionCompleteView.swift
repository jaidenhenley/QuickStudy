//
//  SessionCompleteView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct SessionCompleteView: View {
    let summary: QuizSessionViewModel.Summary
    let onAgain: () -> Void
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.base) {
                HStack {
                    Spacer()
                    Button("Done", action: onDone)
                }

                Image(systemName: "trophy")
                    .font(.largeTitle)
                    .foregroundStyle(Color.appPrimary)
                    .padding(.top, Spacing.lg)

                Text("Nicely done")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Session complete · \(summary.elapsedLabel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(summary.streak) day streak")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if let delta = summary.cardsVsYesterday, delta > 0 {
                            Text("You beat yesterday by \(delta) cards")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.lg)

                HStack(spacing: 0) {
                    SessionStatCell(value: "\(summary.cardCount)", label: "CARDS")
                    SessionStatCell(value: "\(summary.correctCount)", label: "CORRECT")
                    SessionStatCell(value: "\(Int((summary.accuracy * 100).rounded()))%", label: "ACCURACY")
                }
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.lg)

                if !summary.reinforcement.isEmpty {
                    Text("NEEDS REINFORCEMENT")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .tracking(1)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, Spacing.sm)

                    ForEach(summary.reinforcement) { item in
                        ReinforcementRow(item: item)
                    }
                }

                Button(action: onAgain) {
                    Text("One more session")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .appProminentButtonStyle(tint: Theme.primary)
                .padding(.top, Spacing.base)
            }
            .padding(Spacing.lg)
        }
        .background(BackgroundView())
        .navigationBarBackButtonHidden()
    }
}
