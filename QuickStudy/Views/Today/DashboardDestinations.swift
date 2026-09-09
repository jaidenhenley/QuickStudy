//
//  DashboardDestinations.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/28/26.
//

import SwiftUI

struct StudySetDetailView: View {
    @Environment(StudyViewModel.self) var viewModel
    @Environment(AppState.self) var appState
    let set: StudySet

    var body: some View {
        CardsView()
            .onAppear {
                viewModel.loadSet(set)
            }
    }
}

