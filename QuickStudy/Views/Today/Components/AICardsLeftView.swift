//
//  AICardsLeftView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/11/26.
//

import SwiftUI

struct AICardsLeftView: View {
    @Environment(TodayViewModel.self) var todayViewModel

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "sparkles")
                .font(.caption)
            Text("\(todayViewModel.generationsRemaining) of \(todayViewModel.generationsLimit) free generations left this month")
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(.appSecondary)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
    }
}
