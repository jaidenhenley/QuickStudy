//
//  SuggestedSetRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import SwiftUI

struct SuggestedSetRow: View {
    @Environment(StudyViewModel.self) var studyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            if studyViewModel.savedSets.isEmpty {
                Text("Scan or import a document to generate cards.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(studyViewModel.savedSets.prefix(3)) { set in
                    NavigationLink {
                        StudySetDetailView(set: set)
                    } label: {
                        SuggestedSetLabel(set: set)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Suggested Row

struct SuggestedSetLabel: View {
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
