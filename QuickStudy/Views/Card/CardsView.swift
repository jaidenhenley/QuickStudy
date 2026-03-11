//
//  CardsView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/7/26.
//

import SwiftUI

struct CardsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: StudyViewModel
    @EnvironmentObject var appState: AppState
    @State private var navigateToStudy = false
    @State private var navigateToQuiz = false
    @State private var isDocumentExpanded = false

    var body: some View {
        GeometryReader { proxy in
            let m = LayoutMetrics(availableWidth: proxy.size.width)
            Group {
                if let doc = viewModel.currentDocument {
                    content(for: doc, metrics: m)
                } else {
                    emptyState
                }
            }
        }
        .navigationTitle("Cards")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Generation Error", isPresented: Binding(
            get: { viewModel.generationErrorMessage != nil },
            set: { isPresented in
                if !isPresented { viewModel.generationErrorMessage = nil }
            }
        ), presenting: viewModel.generationErrorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView()
                .environmentObject(viewModel)
                .environmentObject(appState)
        }
        .navigationDestination(isPresented: $navigateToQuiz) {
            QuizView()
                .environmentObject(viewModel)
                .environmentObject(appState)
        }
        .background(BackgroundView())
        .onChange(of: viewModel.flashcards) { _, _ in
            viewModel.saveCurrentSet()
        }
        .onChange(of: viewModel.document) { _, _ in
            viewModel.saveCurrentSet()
        }
        .onDisappear {
            viewModel.saveCurrentSet()
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No document loaded")
                .font(.headline)
            Text("Go back and scan or import a document to generate flashcards.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Go Back") { dismiss() }
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    func content(for doc: StudyDocument, metrics: LayoutMetrics) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: metrics.spacing) {
                    // Document text
                    VStack(alignment: .leading, spacing: 10) {
                        Text(doc.title)
                            .font(.headline)

                    if !isDocumentExpanded {
                        Text(paragraphPreview(for: doc, lineCount: 10))
                            .font(.body)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    DisclosureGroup(
                        isExpanded: $isDocumentExpanded,
                        content: {
                            Text(doc.paragraphText)
                                .font(.body)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        },
                        label: {
                            Text(isDocumentExpanded ? "Hide scanned text" : "Show full text")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    )
                }
                .padding(.vertical, 4)

                // Actions
                HStack {
                    Button(action: { navigateToStudy = true }) {
                        Label("Study", systemImage: "book.fill")
                    }
                    .appProminentButtonStyle(tint: Theme.primary)

                    Spacer()

                    Button(action: {
                        viewModel.saveCurrentSet()
                        if viewModel.activeSetID == nil,
                           let matchingSet = viewModel.savedSets.first(where: { $0.document == doc }) {
                            viewModel.activeSetID = matchingSet.id
                        }
                        navigateToQuiz = true
                    }) {
                        Label("Open Quiz", systemImage: "play.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.flashcards.contains(where: { $0.approved }))
                }

                // Flashcards list
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.flashcards.isEmpty {
                        Text("No cards yet. Tap Generate Cards.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.flashcards) { card in
                            CardRowView(
                                card: binding(for: card),
                                deleteCard: { deleteCard(card) }
                            )
                            .padding(.vertical, 6)
                        }
                    }
                }
                .id("flashcards")
            }
            .padding(metrics.padding)
            .onChange(of: appState.scrollToFlashcards) { _, shouldScroll in
                if shouldScroll {
                    withAnimation {
                        proxy.scrollTo("flashcards", anchor: .top)
                    }
                    // Reset the flag
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        appState.scrollToFlashcards = false
                    }
                }
            }
        }
        }
        .overlay {
            if viewModel.isGenerating {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                    ProgressView("Generating flashcards...")
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    func deleteCard(_ card: StudyCard) {
        if let idx = viewModel.flashcards.firstIndex(of: card) {
            viewModel.flashcards.remove(at: idx)
        }
    }
    
    private func binding(for card: StudyCard) -> Binding<StudyCard> {
        Binding(
            get: {
                viewModel.flashcards.first(where: { $0.id == card.id }) ?? card
            },
            set: { updated in
                if let index = viewModel.flashcards.firstIndex(where: { $0.id == updated.id }) {
                    viewModel.flashcards[index] = updated
                }
            }
        )
    }

    func paragraphPreview(for doc: StudyDocument, lineCount: Int) -> String {
        let previewLines = doc.lines.prefix(lineCount)
        let previewDoc = StudyDocument(title: doc.title, lines: Array(previewLines))
        return previewDoc.paragraphText
    }
}
