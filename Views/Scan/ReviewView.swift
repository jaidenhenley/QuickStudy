//
//  ReviewView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/28/26.
//

import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var viewModel: StudyViewModel
    @EnvironmentObject var appState: AppState

    let document: StudyDocument

    @State private var removeHeadersFooters = false
    @State private var navigateToCards = false

    var body: some View {
        List {
            Section("Detected Sections") {
                let sections = detectedSections(from: document.lines)
                if sections.isEmpty {
                    Text("No sections detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sections, id: \.self) { section in
                        Text(section)
                    }
                }
            }

            Section("Review") {
                Toggle("Remove headers/footers", isOn: $removeHeadersFooters)
                    .onChange(of: removeHeadersFooters) { _, _ in
                        applyHeaderFooterFilter()
                    }
            }

            Section("Detected Text") {
                Text(documentPreviewText)
                    .font(.body)
                    .lineSpacing(4)
            }

            if viewModel.lastRawText != viewModel.lastCorrectedText,
               !viewModel.lastCorrectedText.isEmpty {
                Section("Corrections Preview") {
                    Text(viewModel.lastCorrectedText)
                        .font(.body)
                        .lineSpacing(4)
                }
            }

            Section {
                Button("Generate Flashcards") {
                    viewModel.generateCards()
                    navigateToCards = true
                }
                .appProminentButtonStyle(tint: Theme.aiAccent)
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .background(BackgroundView())
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToCards) {
            CardsView()
                .environmentObject(viewModel)
                .environmentObject(appState)
        }
    }

    private var documentPreviewText: String {
        guard let current = viewModel.currentDocument else {
            return document.paragraphText
        }
        return current.paragraphText
    }

    private func detectedSections(from lines: [String]) -> [String] {
        let trimmed = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let paragraphs = trimmed.split(omittingEmptySubsequences: true) { $0.isEmpty }
        let headers = paragraphs.compactMap { $0.first }.filter { !$0.isEmpty }
        return Array(headers.prefix(4))
    }

    private func applyHeaderFooterFilter() {
        guard var current = viewModel.currentDocument else { return }
        if removeHeadersFooters {
            let lines = current.lines
            let counts = Dictionary(grouping: lines) { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .mapValues { $0.count }
            let filtered = lines.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                let wordCount = trimmed.split(whereSeparator: { $0.isWhitespace }).count
                let isRepeat = (counts[trimmed] ?? 0) >= 2
                return !(isRepeat && wordCount <= 3)
            }
            current.lines = filtered
            viewModel.document = current
        } else {
            viewModel.document = document
        }
        viewModel.saveCurrentSet()
    }
}
