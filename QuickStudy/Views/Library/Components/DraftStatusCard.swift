//
//  DraftStatusCard.swift
//  QuickStudy
//

import SwiftUI

struct DraftStatusCard: View {
    let content: LibraryViewModel.StatusCard
    let onOpenProgress: () -> Void
    let onReview: () -> Void
    let onDiscard: () -> Void
    let onClose: () -> Void
    let onRecover: (ImportFailure.Recovery) -> Void

    @State private var showDiscardAlert = false
    @State private var showCancelAlert = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var iconSize = 28.0

    var body: some View {
        let stacksVertically = dynamicTypeSize.isAccessibilitySize

        Group {
            switch content {
            case .drafting(let status):
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        // At accessibility sizes the icon column squeezes the title to a word per line.
                        if !stacksVertically {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundStyle(Theme.aiAccentText)
                                .frame(width: iconSize)
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(status.title)
                                .font(.headline)
                            Text(status.detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint("Shows drafting progress")
                        .accessibilityAction(.default, onOpenProgress)
                        Spacer(minLength: 0)
                        DraftStatusCloseButton(label: "Cancel drafting") { showCancelAlert = true }
                    }
                    if let fraction = status.fraction {
                        ProgressView(value: fraction)
                            .tint(Theme.primary)
                            .accessibilityHidden(true)
                    } else {
                        ProgressView()
                            .progressViewStyle(.linear)
                            .tint(Theme.primary)
                            .accessibilityHidden(true)
                    }
                }
                // The close button's own tap wins over this one, so the X still cancels.
                .contentShape(.rect)
                .onTapGesture(perform: onOpenProgress)
                .alert("Cancel Drafting?", isPresented: $showCancelAlert) {
                    Button("Cancel Drafting", role: .destructive, action: onClose)
                    Button("Keep Drafting", role: .cancel) {}
                } message: {
                    Text(LibraryViewModel.cancelDraftingMessage)
                }

            case .ready(let draft):
                let layout = stacksVertically
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.md))
                    : AnyLayout(HStackLayout(spacing: Spacing.md))
                layout {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        if !stacksVertically {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.success)
                                .frame(width: iconSize)
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LibraryViewModel.readyTitle(for: draft))
                                .font(.headline)
                            Text(LibraryViewModel.readyDetail(for: draft))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    if !stacksVertically { Spacer(minLength: 0) }
                    Button(action: onReview) {
                        Text("Review")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, Spacing.xs)
                    }
                    .appProminentButtonStyle(tint: Theme.primaryFill)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                    // Compact capsule to match the card; the hit area still reaches 44 pt.
                    .contentShape(Capsule().inset(by: -8))
                }
                .contextMenu {
                    Button(role: .destructive) { showDiscardAlert = true } label: {
                        Label("Discard Draft", systemImage: "trash")
                    }
                }
                .accessibilityAction(named: "Discard Draft") { showDiscardAlert = true }
                .alert("Discard Draft?", isPresented: $showDiscardAlert) {
                    Button("Discard Draft", role: .destructive, action: onDiscard)
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text(draft.discardWarning)
                }

            case .failed(let failure):
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        if !stacksVertically {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.danger)
                                .frame(width: iconSize)
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(failure.title)
                                .font(.headline)
                            Text(failure.message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        Spacer(minLength: 0)
                        DraftStatusCloseButton(label: "Dismiss", action: onClose)
                    }
                    if let recovery = failure.recoveries.first {
                        Button { onRecover(recovery) } label: {
                            Text(LibraryViewModel.label(for: recovery, in: failure))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.primary)
                                .padding(.horizontal, Spacing.base)
                                .frame(minHeight: 44)
                                .background(Theme.primary.opacity(0.12), in: .capsule)
                                .contentShape(.capsule)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appGlassCard(cornerRadius: AppRadius.xl)
        .onChange(of: content.kind) { _, _ in showCancelAlert = false }
    }
}
