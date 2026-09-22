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

    @State private var showSettings = false
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Today")
                    .font(.system(size: 40, weight: .bold))

                if !networkMonitor.isOnline && aiSettings.mode == .externalAPI {
                    OfflineBanner { showSettings = true }
                }

                if todayViewModel.showsGenerationsPill {
                    AICardsLeftView { showPaywall = true }
                }

                HStack {
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if todayViewModel.streakCount > 0 {
                        NavigationLink {
                            StreakView()
                        } label: {
                            Text("🔥 \(todayViewModel.streakCount) day streak")
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
                        WeakestCardRow(weakest: weakest)
                    }

                    if todayViewModel.canGenerate, let suggestion = todayViewModel.suggestion {
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
