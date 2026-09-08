//
//  TodayEmptyView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct TodayEmptyView: View {
    @Environment(TodayViewModel.self) var todayViewModel
    @Environment(StudyViewModel.self) var studyViewModel

    @State private var navigateToPractice = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.15))
                        .frame(width: 108, height: 108)
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 76, height: 76)
                    Image(systemName: "checkmark")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Circle()
                        .fill(Theme.success)
                        .frame(width: 11, height: 11)
                        .offset(x: 46, y: -42)
                    Circle()
                        .fill(Color.appSecondary)
                        .frame(width: 8, height: 8)
                        .offset(x: 54, y: 8)
                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                        .offset(x: -48, y: 32)
                }

                Text("All caught up")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("No cards due today. New ones unlock as your review cycle picks back up.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if todayViewModel.hasReviewableCards {
                    Button {
                        studyViewModel.loadTodaySession()
                        navigateToPractice = true
                    } label: {
                        Text("Practice anyway")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md)
                            .background(Color.appPrimary)
                            .clipShape(Capsule())
                            .shadow(color: Color.appPrimary.opacity(0.35), radius: 10, y: 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))

            if !todayViewModel.upNext.isEmpty {
                Text("UP NEXT")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(1)

                ForEach(todayViewModel.upNext) { entry in
                    if let set = studyViewModel.savedSets.first(where: { $0.id == entry.id }) {
                        NavigationLink {
                            StudySetDetailView(set: set)
                        } label: {
                            UpNextRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToPractice) {
            FlashcardPracticeView(cards: studyViewModel.savedSets.flatMap(\.reviewableCards))
        }
    }
}
