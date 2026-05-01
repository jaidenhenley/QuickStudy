//
//  TodayView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 4/30/26.
//

import SwiftUI

import SwiftUI

struct TodayView: View {
    @Environment(StudyViewModel.self) var studyViewModel
    @Environment(AppState.self) var appState
    @Environment(DashboardViewModel.self) var viewModel

    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                sessionCard
                if let weakest = viewModel.weakestCard {
                    weakestCardSection(weakest)
                }
                suggestedSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            viewModel.updateFromStudy(studyViewModel)
        }
        .onChange(of: studyViewModel.savedSets) { _, _ in
            viewModel.updateFromStudy(studyViewModel)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // AI usage nudge
                if viewModel.aiCardsUsed >= viewModel.aiCardsLimit {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("\(viewModel.aiCardsUsed) of \(viewModel.aiCardsLimit) AI cards used this month")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("Plus >")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.appSecondary)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("\(viewModel.aiCardsUsed) of \(viewModel.aiCardsLimit) AI cards used this month")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("Plus >")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.appSecondary)
                }

                Text("Today")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if viewModel.streakCount > 0 {
                        Text("🔥 \(viewModel.streakCount) day streak")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.orange)
                    }
                }
            }
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Session Card

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S SESSION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.8))
                .tracking(1)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(viewModel.todayCardCount)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(.white)
                Text("cards · \(viewModel.estimatedMin) min")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Button {
                appState.selectedTab = .savedSets
            } label: {
                Text("Start Session")
                    .font(.headline)
                    .foregroundStyle(Color("#5B5BD6"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                // expand what's in session — future feature
            } label: {
                Text("What's in this? ∨")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color("#5B5BD6"), Color("#7C7CE8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Weakest Card

    private func weakestCardSection(_ weakest: WeakestCardInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WEAKEST CARD")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(1)

            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemPink).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Text("\(weakest.missCount)×")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.pink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(weakest.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text("Missed \(weakest.missCount) \(weakest.missCount == 1 ? "time" : "times") — drill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Suggested

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SUGGESTED")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(1)

            if studyViewModel.savedSets.isEmpty {
                Text("Scan or import a document to generate cards.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(studyViewModel.savedSets.prefix(3)) { set in
                    NavigationLink {
                        StudySetDetailView(set: set)
                    } label: {
                        SuggestedSetRow(set: set)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMM d"
        return f.string(from: Date()).uppercased()
    }
}

// MARK: - Suggested Row

private struct SuggestedSetRow: View {
    let set: StudySet

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("#5B5BD6").opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "book.closed")
                    .foregroundStyle(Color("#5B5BD6"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Generate \(min(set.cards.count + 3, 10)) cards on")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(set.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
