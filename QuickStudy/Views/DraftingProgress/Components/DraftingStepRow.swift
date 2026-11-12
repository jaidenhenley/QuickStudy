//
//  DraftingStepRow.swift
//  QuickStudy
//

import SwiftUI

struct DraftingStepRow: View {
    let step: DraftingReport.Step
    let isLast: Bool

    @ScaledMetric(relativeTo: .body) private var markerSize = 24.0

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(spacing: Spacing.xs) {
                Group {
                    switch step.state {
                    case .done:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.success)
                    case .active:
                        ProgressView()
                            .controlSize(.small)
                            .tint(Theme.primary)
                    case .pending:
                        Image(systemName: "circle")
                            .foregroundStyle(.tertiary)
                    }
                }
                .font(.title3)
                .frame(width: markerSize, height: markerSize)

                if !isLast {
                    Capsule()
                        .fill(step.state == .done ? Theme.success : Theme.track)
                        .frame(width: 2)
                        .frame(minHeight: Spacing.base, maxHeight: .infinity)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.body)
                    .fontWeight(step.state == .active ? .semibold : .regular)
                    .foregroundStyle(step.state == .pending ? .secondary : .primary)
                if let detail = step.detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
            .padding(.top, 2)
            .padding(.bottom, isLast ? 0 : Spacing.base)

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(step.title)
        .accessibilityValue([stateLabel, step.detail].compactMap(\.self).joined(separator: ", "))
    }

    private var stateLabel: String {
        switch step.state {
        case .done: String(localized: "Done")
        case .active: String(localized: "In progress")
        case .pending: String(localized: "Not started")
        }
    }
}
