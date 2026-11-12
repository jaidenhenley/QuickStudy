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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let stacksVertically = dynamicTypeSize.isAccessibilitySize
        let layout = stacksVertically
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(spacing: Spacing.xs))
        let accent = todayViewModel.isPro ? Theme.aiAccentText : Color.appSecondary

        Button(action: onUpgrade) {
            layout {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(accent)
                        .accessibilityHidden(true)
                    Text(label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(todayViewModel.isPro ? Theme.textPrimary : Color.appSecondary)
                        .appNumericTransition()
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !stacksVertically { Spacer(minLength: 0) }
                if !todayViewModel.isPro {
                    Text("Pro ›")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(accent)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, Spacing.md)
            .background((todayViewModel.isPro ? Color.appAIAccent : Color.appSecondary).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(todayViewModel.isPro)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityHint(todayViewModel.isPro ? Text(verbatim: "") : Text("Opens QuickStudy Pro"))
    }

    private var label: String {
        if todayViewModel.isManualOnly {
            return String(localized: "AI generation isn't available on this iPhone")
        }
        if todayViewModel.hasOnlyFreeCloudSet {
            return String(localized: "1 free cloud set on this iPhone")
        }
        if todayViewModel.isPro {
            let left = todayViewModel.hostedRemaining ?? todayViewModel.hostedLimit
            return String(localized: "QuickStudy Pro · \(left) of \(todayViewModel.hostedLimit) generations left this month")
        }
        return todayViewModel.canGenerate
            ? String(localized: "\(todayViewModel.generationsRemaining) of \(todayViewModel.generationsLimit) free generations left this month")
            : String(localized: "\(todayViewModel.generationsRemaining) of \(todayViewModel.generationsLimit) free generations left · resets \(todayViewModel.generationsResetLabel)")
    }
}
