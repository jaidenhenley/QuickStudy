//
//  DashboardComponents.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/28/26.
//

import SwiftUI
import PhotosUI

// MARK: - Cards + tiles

struct ContinueSourceCard: View {
    let source: Source
    let onReplace: () -> Void
    let onNewScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(source.title)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(source.progressText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Updated \(relativeDateText(from: source.updatedAt))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .appGlassCard(cornerRadius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(source.title), \(source.progressText)")
    }
}

struct ContinueEmptyState: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let isScannerSupported: Bool
    let onScan: () -> Void
    let onPDF: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No active document")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Scan or import to create a study set.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .appGlassCard(cornerRadius: 16)
    }
}

struct CreateTile: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
            Text(title)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .appGlassCard(cornerRadius: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

struct StudySetCardView: View {
    let set: StudySet
    let isPinned: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(set.title)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 6)
                if isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("\(set.cards.count) cards")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Last studied \(relativeDateText(from: set.updatedAt))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .appGlassCard(cornerRadius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(set.title), \(set.cards.count) cards")
    }
}

struct QuickQuizCard: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Quick Quiz")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()

            NavigationLink {
                QuizView(mode: .quick)
                    .onAppear {
                        appState.isQuickQuizEntry = true
                    }
            } label: {
                Text("Start")
            }
            .appProminentButtonStyle(tint: Theme.primary)
            .accessibilityLabel("Start quick quiz")
            .layoutPriority(1)
            .simultaneousGesture(TapGesture().onEnded {
                appState.isQuickQuizEntry = true
            })
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .appGlassCard(cornerRadius: 16)
    }
}

// MARK: - Helpers

func relativeDateText(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
}
