//
//  AICardsLeftView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/11/26.
//

import SwiftUI

struct AICardsLeftView: View {
    @Environment(TodayViewModel.self) var todayViewModel
    let onUpgrade: () -> Void

    var body: some View {
        Button(action: onUpgrade) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                if !todayViewModel.isPro {
                    Text("Pro ›")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(todayViewModel.isPro ? .appAIAccent : .appSecondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background((todayViewModel.isPro ? Color.appAIAccent : Color.appSecondary).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        }
        .buttonStyle(.plain)
        .disabled(todayViewModel.isPro)
    }

    private var label: String {
        if todayViewModel.isPro {
            let left = todayViewModel.hostedRemaining ?? todayViewModel.hostedLimit
            return "QuickStudy Pro · \(left) of \(todayViewModel.hostedLimit) generations left this month"
        }
        return todayViewModel.canGenerate
            ? "\(todayViewModel.generationsRemaining) of \(todayViewModel.generationsLimit) free generations left this month"
            : "\(todayViewModel.generationsRemaining) of \(todayViewModel.generationsLimit) free generations left · resets \(todayViewModel.generationsResetLabel)"
    }
}
