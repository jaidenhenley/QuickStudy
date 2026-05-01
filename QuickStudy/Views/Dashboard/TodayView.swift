    //
    //  TodayView.swift
    //  QuickStudy
    //
    //  Created by Jaiden Henley on 4/30/26.
    //

    import SwiftUI

    import SwiftUI

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
    @Environment(DashboardViewModel.self) var viewModel

    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles").font(.caption)
                            Text("\(viewModel.aiCardsUsed) of \(viewModel.aiCardsLimit) AI cards used this month")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("Plus >")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.appSecondary)

                        Text("Today")
                            .font(.system(size: 40, weight: .bold))

                        HStack(spacing: 6) {
                            Text(formattedDate)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if viewModel.streakCount > 0 {
                                Text("🔥 \(viewModel.streakCount) day streak")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    Spacer()
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                }

                // MARK: Session Card
                SessionCard()

                // MARK: Weakest Card
                if let weakest = viewModel.weakestCard {
                    WeakestCardRow(weakest: weakest)
                }

                // MARK: Suggested
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
                                SuggestedSetRow()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onAppear { viewModel.updateFromStudy(studyViewModel) }
        .onChange(of: studyViewModel.savedSets) { _, _ in viewModel.updateFromStudy(studyViewModel) }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMM d"
        return f.string(from: Date()).uppercased()
    }
}
