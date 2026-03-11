//
//  QuizView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/2/26.
//

import SwiftUI

struct QuizView: View {
    enum LaunchMode {
        case standard
        case quick
    }

    @EnvironmentObject var viewModel: StudyViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let launchMode: LaunchMode

    @State private var selectedSetID: UUID? = nil
    @State private var isQuizActive = false
    @State private var questionCount: QuestionCount = .all
    @State private var shuffleQuestions = true
    @State private var preparedQuestions: [QuizQuestion] = []

    init(mode: LaunchMode = .standard) {
        self.launchMode = mode
    }

    var body: some View {
        let content = Group {
            if horizontalSizeClass == .compact {
                compactContent
            } else {
                ipadContent
            }
        }

        Group {
            if appState.isQuickQuizEntry {
                content.toolbar(removing: .sidebarToggle)
            } else {
                content
            }
        }
        .onAppear {
            appState.quizViewAppeared = Date()
        }
        .onDisappear {
            appState.isQuickQuizEntry = false
        }
    }

    private var compactContent: some View {
        VStack(spacing: 16) {
            if isQuizActive {
                QuizQuestionView(providedQuestions: preparedQuestions)
            } else if viewModel.savedSets.isEmpty {
                emptyState
            } else {
                startScreen
            }
        }
        .padding(.top, 8)
        .background(BackgroundView())
        .onAppear {
            if selectedSetID == nil {
                selectedSetID = viewModel.activeSetID ?? viewModel.savedSets.first?.id
            }
            if let selectedSetID, let set = viewModel.savedSets.first(where: { $0.id == selectedSetID }) {
                viewModel.loadSet(set)
            }
            applyLaunchMode()
        }
        .onChange(of: selectedSetID) { newValue, _ in
            guard let newValue,
                  let set = viewModel.savedSets.first(where: { $0.id == newValue }) else { return }
            viewModel.loadSet(set)
        }
        .onChange(of: viewModel.flashcards) { _, _ in
            if viewModel.quizQuestions.isEmpty {
                isQuizActive = false
            }
        }
    }

    private var ipadContent: some View {
        Group {
            if isQuizActive {
                QuizQuestionView(providedQuestions: preparedQuestions)
            } else if viewModel.savedSets.isEmpty {
                emptyState
            } else {
                GeometryReader { proxy in
                    let m = LayoutMetrics(availableWidth: proxy.size.width)
                    let setupContent = VStack(alignment: .leading, spacing: m.spacing) {
                        Text("Quiz Setup")
                            .font(.title2)
                            .fontWeight(.semibold)
                        if #available(iOS 16.0, *) {
                            setupForm
                                .appGlassCard(cornerRadius: 16)
                                .scrollDisabled(true)
                        } else {
                            setupForm
                                .appGlassCard(cornerRadius: 16)
                        }
                    }

                    let previewContent = VStack(alignment: .leading, spacing: m.spacing) {
                        Text("Quiz Preview")
                            .font(.title2)
                            .fontWeight(.semibold)

                        quizPreviewCard
                    }

                    ScrollView {
                        Group {
                            if m.isStacked {
                                VStack(alignment: .leading, spacing: m.spacing) {
                                    setupContent
                                    previewContent
                                }
                            } else {
                                HStack(alignment: .top, spacing: m.spacing) {
                                    setupContent
                                        .frame(width: m.leftColumnWidth, alignment: .topLeading)
                                    previewContent
                                        .frame(width: m.rightColumnWidth, alignment: .topLeading)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(m.padding)
                    }
                }
                .background(BackgroundView())
            }
        }
        .onAppear {
            if selectedSetID == nil {
                selectedSetID = viewModel.activeSetID ?? viewModel.savedSets.first?.id
            }
            if let selectedSetID, let set = viewModel.savedSets.first(where: { $0.id == selectedSetID }) {
                viewModel.loadSet(set)
            }
            applyLaunchMode()
        }
        .onChange(of: selectedSetID) { newValue, _ in
            guard let newValue,
                  let set = viewModel.savedSets.first(where: { $0.id == newValue }) else { return }
            viewModel.loadSet(set)
        }
        .onChange(of: viewModel.flashcards) { _, _ in
            if viewModel.quizQuestions.isEmpty {
                isQuizActive = false
            }
        }
    }

    private var startScreen: some View {
        Form {
            quizSetupForm

            Section {
                Button("Start Quiz") {
                    prepareQuestions()
                    isQuizActive = true
                }
                .appProminentButtonStyle(tint: Theme.primary)
                .disabled(viewModel.quizQuestions.isEmpty)
            } footer: {
                if viewModel.quizQuestions.isEmpty {
                    Text("Approve at least one card in this set to start.")
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var setupForm: some View {
            VStack(spacing: 12) {
                HStack {
                    Text("Set")
                        .font(.body)
                    Spacer()
                    Picker("Set", selection: $selectedSetID) {
                        ForEach(viewModel.savedSets) { set in
                            Text(set.title)
                                .tag(Optional(set.id))
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                Divider()

                HStack {
                    Text("Question Count")
                        .font(.body)
                    Spacer()
                    Picker("Question Count", selection: $questionCount) {
                        ForEach(QuestionCount.allCases, id: \.self) { option in
                            Text(option.label)
                                .tag(option)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                Divider()

                HStack {
                    Text("Shuffle")
                        .font(.body)
                    Spacer()
                    Toggle("", isOn: $shuffleQuestions)
                        .labelsHidden()
                }
            }
            .padding([.bottom, .horizontal], 16)
        }

    @ViewBuilder
    private var quizSetupForm: some View {
        setupForm
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No sets yet")
                .font(.title2).bold()
            Text("Scan or import a document to create your first set.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Scan Document") {
                appState.selectedTab = .scan
            }
            .appProminentButtonStyle(tint: Theme.primary)
        }
        .padding(.horizontal)
    }

    private var quizPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedSetTitle)
                .font(.title3)
                .fontWeight(.semibold)

            Text("Multiple Choice • \(questionCountLabel)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Sample Question")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if let question = sampleQuestion {
                    Text(question.prompt)
                        .font(.subheadline)
                    Text(question.choices.first ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Select a set and approve cards to preview.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Start Quiz") {
                prepareQuestions()
                isQuizActive = true
            }
            .appProminentButtonStyle(tint: Theme.primary)
            .disabled(viewModel.quizQuestions.isEmpty)
        }
        .padding()
        .appGlassCard(cornerRadius: 16)
    }

    private var selectedSetTitle: String {
        guard let selectedSetID,
              let set = viewModel.savedSets.first(where: { $0.id == selectedSetID }) else {
            return "Quiz Preview"
        }
        return set.title
    }

    private var questionCountValue: Int {
        switch questionCount {
        case .ten:
            return 10
        case .twenty:
            return 20
        case .all:
            return max(1, viewModel.quizQuestions.count)
        }
    }

    private var questionCountLabel: String {
        switch questionCount {
        case .ten:
            return "10 questions"
        case .twenty:
            return "20 questions"
        case .all:
            return "\(questionCountValue) questions"
        }
    }

    private var sampleQuestion: QuizQuestion? {
        if let first = preparedQuestions.first {
            return first
        }
        return viewModel.quizQuestions.first
    }

    private func prepareQuestions() {
        var questions = viewModel.quizQuestions
        if shuffleQuestions {
            questions.shuffle()
        }
        switch questionCount {
        case .ten:
            preparedQuestions = Array(questions.prefix(10))
        case .twenty:
            preparedQuestions = Array(questions.prefix(20))
        case .all:
            preparedQuestions = questions
        }
    }

    private func applyLaunchMode() {
        switch launchMode {
        case .standard:
            break
        case .quick:
            questionCount = .ten
            shuffleQuestions = true
        }
    }

    enum QuestionCount: String, CaseIterable {
        case ten
        case twenty
        case all

        var label: String {
            switch self {
            case .ten:
                return "10"
            case .twenty:
                return "20"
            case .all:
                return "All"
            }
        }
    }
}
