//
//  ImportErrorView.swift
//  QuickStudy
//

import SwiftUI

struct ImportErrorView: View {
    let failure: ImportFailure
    let onDismiss: () -> Void
    let onPasteText: () -> Void
    let onTryAgain: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var iconDiameter: CGFloat = 92

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Spacer()

                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: iconDiameter, height: iconDiameter)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.largeTitle)
                            .foregroundStyle(tint)
                    }

                VStack(spacing: Spacing.md) {
                    Text(failure.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(failure.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let recoveryNote = failure.recoveryNote {
                        Text(recoveryNote)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if let code = failure.code {
                        Text("Error · \(code)")
                            .font(.caption)
                            .monospaced()
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, Spacing.lg)

                if !failure.tips.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(failure.tips.enumerated()), id: \.offset) { index, tip in
                            if index > 0 {
                                Divider()
                                    .padding(.leading, Spacing.lg)
                            }
                            ErrorRecoveryTipRow(text: tip)
                        }
                    }
                    .appGlassCard(cornerRadius: AppRadius.lg)
                }

                Spacer()

                HStack(spacing: Spacing.md) {
                    if failure.recoveries.contains(.pasteText) {
                        Button {
                            onPasteText()
                        } label: {
                            Text("Paste text")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                        }
                        .buttonStyle(.plain)
                        .appGlassCard(cornerRadius: AppRadius.md)
                    }

                    if failure.recoveries.contains(.tryAgain) {
                        Button {
                            onTryAgain()
                        } label: {
                            Text("Try again")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.xs)
                        }
                        .appProminentButtonStyle(tint: Theme.primary)
                    }
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BackgroundView())
            .navigationTitle(failure.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(failure.dismissLabel, action: onDismiss)
                }
            }
        }
    }

    private var tint: Color {
        switch failure.severity {
        case .error:
            return Theme.danger
        case .warning:
            return Theme.warning
        }
    }

    private var symbol: String {
        switch failure.severity {
        case .error:
            return "xmark.circle"
        case .warning:
            return "exclamationmark.circle"
        }
    }
}
