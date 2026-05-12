//
//  AICardsLeftView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/11/26.
//

import SwiftUI

struct AICardsLeftView: View {
    @Environment(TodayViewModel.self) var todayViewModel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.caption)
            Text("\(todayViewModel.aiCardsUsed) of \(todayViewModel.aiCardsLimit) AI cards used this month")
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
            Button("Plus \(Image(systemName: "chevron.right"))") { /* upgrade action */ }
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(.appSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    AICardsLeftView()
}
