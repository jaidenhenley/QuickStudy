//
//  SavedSetsView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/29/26.
//

import SwiftUI

struct SavedSetsView: View {
    @EnvironmentObject var viewModel: StudyViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showRenameSheet = false
    @State private var renameText = ""
    @State private var renamingSetID: UUID? = nil
    @State private var showDeleteAlert = false
    @State private var deletingSet: StudySet? = nil
    @State private var searchText = ""
    @State private var sortOption: SortOption = .recent
    @State private var selectedSetID: UUID? = nil
    @State private var navigateToCards = false
    @State private var navigateToQuiz = false

    var body: some View {
        if horizontalSizeClass == .compact {
            compactContent
        } else {
            ipadContent
        }
    }

    private var compactContent: some View {
        List {
            if viewModel.currentDocument != nil && viewModel.activeSetID == nil {
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("You have unsaved cards")
                                .font(.headline)
                            Text("Save your current work as a new set.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Save Set") {
                            viewModel.saveCurrentSet()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Saved Sets") {
                if viewModel.savedSets.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.savedSets.sorted { $0.updatedAt > $1.updatedAt }) { set in
                        NavigationLink {
                            StudySetDetailView(set: set)
                                .environmentObject(viewModel)
                                .environmentObject(appState)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(set.title)
                                    .font(.headline)
                                Text("\(set.cards.count) cards • \(set.document.lines.count) lines")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(sourceLabel(for: set.sourceType)) • Updated \(formattedDate(set.updatedAt))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deletingSet = set
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                beginRename(for: set)
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .background(BackgroundView())
        .navigationTitle("Saved Sets")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showRenameSheet) {
            renameSetSheet
        }
        .alert("Delete Set", isPresented: $showDeleteAlert, presenting: deletingSet) { set in
            Button("Delete", role: .destructive) {
                viewModel.deleteSet(set)
                deletingSet = nil
            }
            Button("Cancel", role: .cancel) {
                deletingSet = nil
            }
        } message: { set in
            Text("Delete \"\(set.title)\"? This cannot be undone.")
        }
    }

    private var ipadContent: some View {
        GeometryReader { proxy in
            let m = LayoutMetrics(availableWidth: proxy.size.width)
            HStack(alignment: .top, spacing: m.spacing) {
                VStack(alignment: .leading, spacing: m.spacing) {
                    HStack {
                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 220)
                    }

                    List {
                        if filteredSets.isEmpty {
                            emptyState
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(filteredSets) { set in
                                Button {
                                    selectedSetID = set.id
                                    appState.splitVisibility = .detailOnly
                                } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(set.title)
                                                .font(.headline)
                                                .foregroundStyle(Theme.textPrimary)
                                            Text("\(set.cards.count) cards • \(set.document.lines.count) lines")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Text("Updated \(formattedDate(set.updatedAt))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .contextMenu {
                                    Button {
                                        beginRename(for: set)
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        deletingSet = set
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $searchText, placement: .toolbar, prompt: "Search sets")
                    .frame(width: m.leftColumnWidth)
                    .appGlassCard(cornerRadius: 16)
                }
                .frame(width: m.leftColumnWidth, alignment: .topLeading)

                if !m.isStacked {
                    VStack(alignment: .leading, spacing: m.spacing) {
                        Text("Set Preview")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Group {
                            if let selectedSet {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(selectedSet.title)
                                        .font(.title3)
                                        .fontWeight(.semibold)

                                    Text("\(selectedSet.cards.count) cards • Updated \(formattedDate(selectedSet.updatedAt))")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(selectedSet.cards.prefix(5)) { card in
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(card.question)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                Text(card.answer)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        if selectedSet.cards.isEmpty {
                                            Text("No cards yet.")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    HStack(spacing: 12) {
                                        Button("Start Quiz") {
                                            viewModel.loadSet(selectedSet)
                                            navigateToQuiz = true
                                        }
                                        .appProminentButtonStyle(tint: Theme.primary)

                                        Button("Study Cards") {
                                            viewModel.loadSet(selectedSet)
                                            navigateToCards = true
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            } else {
                                Text("Select a set to preview.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appGlassCard(cornerRadius: 16)
                        .navigationDestination(isPresented: $navigateToCards) {
                            CardsView()
                                .environmentObject(viewModel)
                                .environmentObject(appState)
                        }
                        .navigationDestination(isPresented: $navigateToQuiz) {
                            QuizView()
                                .environmentObject(viewModel)
                                .environmentObject(appState)
                        }
                    }
                    .frame(width: m.rightColumnWidth, alignment: .topLeading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding()
        .background(BackgroundView())
        .sheet(isPresented: $showRenameSheet) {
            renameSetSheet
        }
        .alert("Delete Set", isPresented: $showDeleteAlert, presenting: deletingSet) { set in
            Button("Delete", role: .destructive) {
                viewModel.deleteSet(set)
                deletingSet = nil
            }
            Button("Cancel", role: .cancel) {
                deletingSet = nil
            }
        } message: { set in
            Text("Delete \"\(set.title)\"? This cannot be undone.")
        }
    }

    private var filteredSets: [StudySet] {
        let base = viewModel.savedSets
        let searched = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? base
            : base.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        switch sortOption {
        case .recent:
            return searched.sorted { $0.updatedAt > $1.updatedAt }
        case .name:
            return searched.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    private var selectedSet: StudySet? {
        guard let selectedSetID else { return filteredSets.first }
        return filteredSets.first { $0.id == selectedSetID }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No saved sets yet")
                .font(.headline)
            Text("Scan or import a document to create your first set.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func beginRename(for set: StudySet) {
        renamingSetID = set.id
        renameText = set.title
        showRenameSheet = true
    }

    private var renameSetSheet: some View {
        NavigationStack {
            Form {
                Section("Set name") {
                    TextField("Title", text: $renameText)
                }
            }
            .navigationTitle("Rename Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showRenameSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let id = renamingSetID {
                            viewModel.renameSet(id: id, title: renameText)
                        }
                        showRenameSheet = false
                    }
                    .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func sourceLabel(for type: StudySourceType) -> String {
        switch type {
        case .scan:
            return "Scan"
        case .photo:
            return "Photo"
        case .pdf:
            return "PDF"
        case .demo:
            return "Demo"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        Self.savedSetDateFormatter.string(from: date)
    }

    private static let savedSetDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
private enum SortOption: CaseIterable {
    case recent
    case name

    var label: String {
        switch self {
        case .recent:
            return "Recent"
        case .name:
            return "Name"
        }
    }
}

