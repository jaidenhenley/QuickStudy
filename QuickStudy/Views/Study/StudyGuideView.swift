//
//  StudyGuideView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/12/26.
//

import SwiftUI


struct StudyView: View {
    @EnvironmentObject var stuViewModel: StudyViewModel
    @EnvironmentObject var appState: AppState
    @State private var navigateToPractice = false

    private var approvedCards: [StudyCard] {
        stuViewModel.flashcards.filter { $0.approved }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Flashcards")
                    .font(.title2).bold()
                    .padding(.horizontal)

                HStack(alignment: .firstTextBaseline) {
                    Text("Included in Practice")
                        .font(.headline)

                    Spacer()

                    Text("\(approvedCards.count) included")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Start Practice") {
                        navigateToPractice = true
                    }
                    .appProminentButtonStyle(tint: Theme.primary)
                    .disabled(approvedCards.isEmpty)
                }
                .padding(.horizontal)

                if approvedCards.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No cards approved yet")
                            .font(.headline)
                        Text("Go back and approve some flashcards to practice with them here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(approvedCards) { card in
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.question)
                                        .font(.headline)
                                    Text(card.answer)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.primary)
                                        .font(.title3)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appGlassCard(cornerRadius: 12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(BackgroundView())
        .navigationTitle(stuViewModel.document?.title ?? "Study GUide")
        .navigationDestination(isPresented: $navigateToPractice) {
            FlashcardPracticeView(cards: approvedCards)
        }
        .onAppear {
            appState.studyViewAppeared = Date()
        }
    }
    
    private func approvedBinding(for card: StudyCard) -> Binding<Bool> {
        Binding(
            get: {
                stuViewModel.flashcards.first(where: { $0.id == card.id })?.approved ?? card.approved
            },
            set: { newValue in
                if let index = stuViewModel.flashcards.firstIndex(where: { $0.id == card.id }) {
                    stuViewModel.flashcards[index].approved = newValue
                }
            }
        )
    }
    
    private func toggleApproval(for card: StudyCard) {
        if let index = stuViewModel.flashcards.firstIndex(where: { $0.id == card.id }) {
            stuViewModel.flashcards[index].approved.toggle()
        }
    }
}
