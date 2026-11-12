//
//  DraftingProgressSheet.swift
//  QuickStudy
//

import SwiftUI

struct DraftingProgressSheet: View {
    let coordinator: ImportCoordinator
    let progress: GenerationProgress
    let draftStore: DraftStore

    @Environment(\.dismiss) private var dismiss
    @State private var showCancelAlert = false

    var body: some View {
        NavigationStack {
            // Time left is derived from the clock, so the sheet re-renders while a draft runs.
            TimelineView(.animation(minimumInterval: 1, paused: coordinator.stage == .idle)) { context in
                let report = DraftingReport.make(
                    run: coordinator.run,
                    stage: coordinator.stage,
                    status: coordinator.draftingStatus(progress: progress, now: context.date),
                    progress: progress,
                    draft: draftStore.pending,
                    now: context.date
                )

                ScrollView {
                    if let report {
                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            DraftingProgressHeader(report: report)

                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("PROGRESS")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                    .tracking(1)
                                    .accessibilityAddTraits(.isHeader)
                                    .padding(.horizontal, Spacing.base)

                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(report.steps) { step in
                                        DraftingStepRow(step: step, isLast: step.id == report.steps.last?.id)
                                    }
                                }
                                .padding(Spacing.base)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .appGlassCard(cornerRadius: AppRadius.xl)
                            }

                            if let engine = report.engine {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Text(report.phase == .ready ? "WHERE IT RAN" : "WHERE IT'S RUNNING")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                        .tracking(1)
                                        .accessibilityAddTraits(.isHeader)
                                        .padding(.horizontal, Spacing.base)

                                    DraftingEngineRow(engine: engine, sourceSummary: report.sourceSummary)
                                }
                                .appTransition(.opacity)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.base)
                        .padding(.bottom, Spacing.lg)
                        .appAnimation(Motion.standard, value: report.engine)
                        .appAnimation(Motion.standard, value: report.phase)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if let report {
                        Group {
                            switch report.phase {
                            case .drafting:
                                // Glass rather than a tinted fill: the steps scroll beneath the footer.
                                Button(role: .destructive) { showCancelAlert = true } label: {
                                    Text("Cancel Drafting")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Theme.dangerText)
                                        .frame(maxWidth: .infinity, minHeight: 34)
                                }
                                .buttonStyle(.glass)
                                .buttonBorderShape(.capsule)
                            case .ready:
                                Button { coordinator.reviewFromDraftingProgress() } label: {
                                    Text("Review")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity, minHeight: 34)
                                }
                                .appProminentButtonStyle(tint: Theme.primaryFill)
                                .buttonBorderShape(.capsule)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.sm)
                    }
                }
                .navigationTitle(report?.documentTitle ?? "")
            }
            .background(BackgroundView().ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            // A draft that finishes while the question is up would otherwise be "cancelled"
            // after the fact, and kept anyway.
            .onChange(of: coordinator.stage) { _, stage in
                if stage == .idle { showCancelAlert = false }
            }
            .alert("Cancel Drafting?", isPresented: $showCancelAlert) {
                Button("Cancel Drafting", role: .destructive) { coordinator.cancelGeneration() }
                Button("Keep Drafting", role: .cancel) {}
            } message: {
                Text(LibraryViewModel.cancelDraftingMessage)
            }
        }
        .presentationDetents([.large])
    }
}
