//
//  ReinforcementRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct ReinforcementRow: View {
    let item: QuizSessionViewModel.Reinforcement

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text("Missed \(item.missed) · review tomorrow")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
    }
}
