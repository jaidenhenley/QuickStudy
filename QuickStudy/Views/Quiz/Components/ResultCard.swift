//
//  ResultCard.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct ResultCard: View {
    let label: String
    let text: String
    let tint: Color
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(0.5)
                    .foregroundStyle(tint)
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg, tint: tint.opacity(0.18))
    }
}
