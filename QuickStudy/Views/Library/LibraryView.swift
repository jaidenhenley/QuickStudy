//
//  LibraryView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import SwiftUI

struct LibraryView: View {
    @Environment(StudyViewModel.self) private var studyViewModel
    @Environment(AppState.self) private var appState

    @State private var coordinator = ImportCoordinator()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if studyViewModel.savedSets.isEmpty {
                LibraryEmptyView(coordinator: coordinator)
            } else {
                List(studyViewModel.savedSets.sorted { $0.updatedAt > $1.updatedAt }) { set in
                    NavigationLink {
                        StudySetDetailView(set: set)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(set.title)
                                .font(.headline)
                            Text("\(set.reviewableCards.count) cards")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
                .safeAreaPadding(.bottom, 88)
            }

            FloatingCreateButton {
                coordinator.showSourcePicker = true
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemBackground))
        .modifier(
            ImportModifiers(
                coordinator: coordinator,
                studyViewModel: studyViewModel,
                appState: appState,
                importHelper: DocumentImportHelper(
                    isHandwritingMode: studyViewModel.isHandwritingMode,
                    isUltraHandwritingMode: studyViewModel.isUltraHandwritingMode
                )
            )
        )
    }
}
