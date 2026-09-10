//
//  DashboardDestinations.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/28/26.
//

import SwiftUI

/// Opened from Library tiles and UP NEXT rows. The Final v2 designs do not cover a
/// saved-set detail screen, so this is a minimal reachable destination pending one.
struct StudySetDetailView: View {
    @Environment(StudyViewModel.self) private var viewModel
    @Environment(AppState.self) private var appState

    let set: StudySet

    @State private var navigateToSession = false

    var body: some View {
        List {
            ForEach(set.cards) { card in
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(card.question)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(card.answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let source = card.source {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "link")
                            Text(source.shortLabel)
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.appPrimary)
                    }
                }
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.lg)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(BackgroundView())
        .navigationTitle(set.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Study") {
                    viewModel.loadSet(set)
                    navigateToSession = true
                }
                .disabled(set.cards.isEmpty)
            }
        }
        .navigationDestination(isPresented: $navigateToSession) {
            QuizSessionView(cards: set.cards)
                .environment(viewModel)
        }
    }
}
