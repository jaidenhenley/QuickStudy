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
                    .accessibilityHidden(true)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .appNumericTransition()
                    .multilineTextAlignment(.leading)
                Spacer()
                if !todayViewModel.isPro {
                    Text("Pro ›")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(todayViewModel.isPro ? Theme.aiAccentText : Color.appSecondary)
            .padding(.horizontal, Spacing.md)
            .background((todayViewModel.isPro ? Color.appAIAccent : Color.appSecondary).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(todayViewModel.isPro)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityHint(todayViewModel.isPro ? "" : "Opens QuickStudy Pro")
    }

    private var label: String {
        if todayViewModel.isManualOnly {
            return "AI generation isn't available on this iPhone"
        }
        if todayViewModel.hasOnlyFreeCloudSet {
            return "1 free cloud set on this iPhone"
        }
        if todayViewModel.isPro {
            let left = todayViewModel.hostedRemaining ?? todayViewModel.hostedLimit
            return "QuickStudy Pro · \(left) of \(todayViewModel.hostedLimit) generations left this month"
        }
        return todayViewModel.canGenerate
            ? "\(todayViewModel.generationsRemaining) of \(todayViewModel.generationsLimit) free generations left this month"
            : "\(todayViewModel.generationsRemaining) of \(todayViewModel.generationsLimit) free generations left · resets \(todayViewModel.generationsResetLabel)"
    }
}
