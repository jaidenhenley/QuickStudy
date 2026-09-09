//
//  SessionCard.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import SwiftUI

struct SessionCard: View {
    @Environment(TodayViewModel.self) var todayViewModel
    @Environment(StudyViewModel.self) var studyViewModel
    @Environment(AppState.self) var appState

    @State private var navigateToSession = false
    @State private var showBreakdown = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("TODAY'S SESSION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.8))
                .tracking(1)

            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text("\(todayViewModel.todayCardCount)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(.white)
                Text("cards · \(todayViewModel.estimatedMin) min")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Button {
                studyViewModel.loadTodaySession()
                navigateToSession = true
            } label: {
                Text("Start Session")
                    .font(.headline)
                    .foregroundStyle(.appSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }

            Button {
                withAnimation { showBreakdown.toggle() }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text("What's in this?")
                    Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .frame(maxWidth: .infinity)
            }

            if showBreakdown {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(todayViewModel.sessionBreakdown) { entry in
                        HStack {
                            Text(entry.title)
                                .lineLimit(1)
                            Spacer()
                            Text("\(entry.cardCount)")
                        }
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .transition(.opacity)
            }
        }
        .padding()
        .background(
            Color.appPrimary
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 230, height: 230)
                        .offset(x: 70, y: -70)
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .navigationDestination(isPresented: $navigateToSession) {
            QuizView(mode: .todaySession)
                .environment(studyViewModel)
                .environment(appState)
        }
    }
}
