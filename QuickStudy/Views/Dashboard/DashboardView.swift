//
//  DashboardView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/24/26.
//

import SwiftUI
import PhotosUI
import VisionKit

// MARK: - iPhone

struct DashboardView: View {
    @Environment(AppState.self) var appState
    @Environment(StudyViewModel.self) var studyViewModel
    @Environment(DashboardViewModel.self) var dashboardViewModel

    @State private var showSettings = false
    @State private var coordinator = DashboardCoordinator()

    private var importHelper: DocumentImportHelper {
        DocumentImportHelper(
            isHandwritingMode: studyViewModel.isHandwritingMode,
            isUltraHandwritingMode: studyViewModel.isUltraHandwritingMode
        )
    }

    var body: some View {
        scrollContent
            .navigationTitle("QuickStudy")
            .toolbar { trailingToolbar }
            .background(BackgroundView())
            .sheet(isPresented: $showSettings) {
                SettingsView().environment(studyViewModel)
            }
            .modifier(ImportModifiers(
                coordinator: coordinator,
                studyViewModel: studyViewModel,
                appState: appState,
                importHelper: importHelper
            ))
            .onAppear { dashboardViewModel.updateFromStudy(studyViewModel) }
            .onChange(of: studyViewModel.document) { _, _ in dashboardViewModel.updateFromStudy(studyViewModel) }
            .onChange(of: studyViewModel.savedSets) { _, _ in dashboardViewModel.updateFromStudy(studyViewModel) }
    }

    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
    }

    private var scrollContent: some View {
        GeometryReader { proxy in
            let m = LayoutMetrics(availableWidth: proxy.size.width)
            ScrollView {
                VStack(spacing: m.spacing) {
                    continueCardSection
                    createRowSection
                    recentSetsSection
                    quickQuizSection
                }
                .padding(.horizontal, m.padding)
                .padding(.bottom, m.padding)
            }
        }
    }

    // MARK: - Sections

    private var continueCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Continue")
                .font(.headline)

            if let source = dashboardViewModel.currentSource {
                if let activeSetID = studyViewModel.activeSetID,
                   let activeSet = studyViewModel.savedSets.first(where: { $0.id == activeSetID }) {
                    NavigationLink {
                        StudySetDetailView(set: activeSet)
                    } label: {
                        ContinueSourceCard(
                            source: source,
                            onReplace: { coordinator.showSourcePicker = true },
                            onNewScan: { coordinator.startScan() }
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    ContinueSourceCard(
                        source: source,
                        onReplace: { coordinator.showSourcePicker = true },
                        onNewScan: { coordinator.startScan() }
                    )
                }
            } else {
                ContinueEmptyState(
                    selectedPhotoItem: $coordinator.selectedPhotoItem,
                    isScannerSupported: coordinator.isScannerSupported,
                    onScan: { coordinator.startScan() },
                    onPDF: { coordinator.showFileImporter = true }
                )
            }
        }
    }

    private var createRowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create")
                .font(.headline)

            HStack(spacing: 12) {
                Button { coordinator.startScan() } label: {
                    CreateTile(title: "Scan Document", systemImage: "camera.viewfinder")
                }
                .buttonStyle(.plain)

                PhotosPicker(selection: $coordinator.selectedPhotoItem, matching: .images) {
                    CreateTile(title: "Import Photo", systemImage: "photo")
                }
                .buttonStyle(.plain)

                Button { coordinator.showFileImporter = true } label: {
                    CreateTile(title: "Import PDF", systemImage: "doc")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recentSetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sets")
                .font(.headline)

            if dashboardViewModel.recentSets.isEmpty {
                Text("No recent sets yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(dashboardViewModel.recentSets) { set in
                            NavigationLink {
                                StudySetDetailView(set: set)
                            } label: {
                                StudySetCardView(
                                    set: set,
                                    isPinned: dashboardViewModel.pinnedSetIDs.contains(set.id)
                                )
                                .frame(width: 220, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    dashboardViewModel.togglePin(for: set)
                                } label: {
                                    Label(
                                        dashboardViewModel.pinnedSetIDs.contains(set.id) ? "Unpin" : "Pin",
                                        systemImage: dashboardViewModel.pinnedSetIDs.contains(set.id) ? "pin.slash" : "pin"
                                    )
                                }
                                Button(role: .destructive) {
                                    dashboardViewModel.delete(set: set)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    private var quickQuizSection: some View {
        if !studyViewModel.savedSets.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Quiz")
                    .font(.headline)

                QuickQuizCard()
            }
        }
    }
}

// MARK: - iPad

struct IpadHomeScreen: View {
    @Environment(AppState.self) var appState
    @Environment(StudyViewModel.self) var studyViewModel
    @Environment(DashboardViewModel.self) var dashboardViewModel

    @State private var showSettings = false
    @State private var coordinator = DashboardCoordinator()

    private var importHelper: DocumentImportHelper {
        DocumentImportHelper(
            isHandwritingMode: studyViewModel.isHandwritingMode,
            isUltraHandwritingMode: studyViewModel.isUltraHandwritingMode
        )
    }

    var body: some View {
        HomeIPadContent(
            isScannerSupported: coordinator.isScannerSupported,
            selectedPhotoItem: $coordinator.selectedPhotoItem,
            onShowSourcePicker: { coordinator.showSourcePicker = true },
            onScan: { coordinator.startScan() },
            onImportPDF: { coordinator.showFileImporter = true }
        )
        .navigationTitle("QuickStudy")
        .toolbar { trailingToolbar }
        .sheet(isPresented: $showSettings) {
            SettingsView().environment(studyViewModel)
        }
        .modifier(ImportModifiers(
            coordinator: coordinator,
            studyViewModel: studyViewModel,
            appState: appState,
            importHelper: importHelper
        ))
        .onAppear { dashboardViewModel.updateFromStudy(studyViewModel) }
        .onChange(of: studyViewModel.document) { _, _ in dashboardViewModel.updateFromStudy(studyViewModel) }
        .onChange(of: studyViewModel.savedSets) { _, _ in dashboardViewModel.updateFromStudy(studyViewModel) }
    }

    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
    }
}
