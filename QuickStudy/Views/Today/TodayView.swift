//
//  TodayView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 4/30/26.
//

import SwiftUI

struct TodayView: View {
    @Environment(StudyViewModel.self) var studyViewModel
    @Environment(AppState.self) var appState
    @Environment(TodayViewModel.self) var todayViewModel
    @Environment(SessionStore.self) var sessionStore
    @Environment(AISettings.self) var aiSettings
    @Environment(NetworkMonitor.self) var networkMonitor
    @Environment(StoreController.self) var store
    @Environment(AnalyticsRecorder.self) var analytics
    @Environment(DraftStore.self) var draftStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showSettings = false
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Today")
                    .font(.system(size: 40, weight: .bold))

                if !networkMonitor.isOnline && (aiSettings.mode == .externalAPI || store.willUseHostedGeneration) {
                    OfflineBanner(
                        canSwitchToOnDevice: aiSettings.mode == .externalAPI && !store.willUseHostedGeneration,
                        onOpenSettings: { showSettings = true }
                    )
                }

                if todayViewModel.showsGenerationsPill {
                    AICardsLeftView { showPaywall = true }
                }

                if let draft = draftStore.pending {
                    RecoveredDraftRow(draft: draft) { appState.selectedTab = .library }
                }

                let dateLayout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
                    : AnyLayout(HStackLayout())

                dateLayout {
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !dynamicTypeSize.isAccessibilitySize {
                        Spacer()
                    }
                    if todayViewModel.streakCount > 0 {
                        NavigationLink {
                            StreakView()
                        } label: {
                            Label {
                                Text("\(todayViewModel.streakCount) day streak")
                            } icon: {
                                Image(systemName: "flame.fill")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.appStreak)
                        }
                    }
                }

                if todayViewModel.todayCardCount == 0 {
                    TodayEmptyView()
                } else {
                    SessionCard()

                    if let weakest = todayViewModel.weakestCard {
                        Text("WEAKEST CARD")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .padding(.top, Spacing.sm)

                        if let weakestSet = studyViewModel.savedSets.first(where: { $0.id == weakest.setID }) {
                            NavigationLink {
                                QuizSessionView(cards: weakestSet.cards)
                                    .environment(studyViewModel)
                            } label: {
                                WeakestCardRow(weakest: weakest)
                            }
                            .buttonStyle(.plain)
                        } else {
                            WeakestCardRow(weakest: weakest)
                        }
                    }

                    if studyViewModel.canGenerateSuggestions, let suggestion = todayViewModel.suggestion {
                        Text("SUGGESTED")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .padding(.top, Spacing.sm)
                        SuggestionRow(suggestion: suggestion)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xl)
        }
        .background(BackgroundView())
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showPaywall) { PaywallView(surface: .pill) }
        .onAppear { refreshToday() }
        .onChange(of: studyViewModel.savedSets) { _, _ in refreshToday() }
        .onChange(of: store.isPro) { _, _ in refreshToday() }
        .onChange(of: store.hostedRemaining) { _, _ in refreshToday() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func refreshToday() {
        todayViewModel.updateFromStudy(studyViewModel, sessions: sessionStore, store: store)
        analytics.record(.generationsUsed(bucket: todayViewModel.generationsUsedBucket))
        if !todayViewModel.canGenerate { analytics.record(.allowanceExhausted) }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMM d"
        return f.string(from: Date()).uppercased()
    }
}
