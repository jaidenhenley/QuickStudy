//
//  SessionCard.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import SwiftUI

struct SessionCard: View {
    @Environment(DashboardViewModel.self) var viewModel
    @Environment(AppState.self) var appState


    var body: some View {
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
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.appSecondary)
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
        .background(.appPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
