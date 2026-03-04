//
//  StudyGuideView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/12/26.
//

import SwiftUI

struct StudyView: View {
    @EnvironmentObject var stuViewModel: StudyViewModel
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

                LazyVStack(spacing: 12) {
                    ForEach($stuViewModel.flashcards) { $card in
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
                                Text("Include")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Toggle("", isOn: $card.approved)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            card.approved.toggle()
                        }
                        .appGlassCard(cornerRadius: 12)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(BackgroundView())
        .navigationTitle(stuViewModel.document?.title ?? "Study GUide")
        .navigationDestination(isPresented: $navigateToPractice) {
            FlashcardPracticeView(cards: approvedCards)
        }
    }
}

