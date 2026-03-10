//
//  DashboardView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/24/26.
//

import SwiftUI
import PhotosUI
import VisionKit
import Combine

// MARK: - Root

struct RootHomeView: View {
    @StateObject private var dashboardViewModel = DashboardViewModel()

    var body: some View {
        DashboardView(viewModel: dashboardViewModel)
    }
}

// MARK: - iPad Optimization

struct IpadHomeScreen: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var studyViewModel: StudyViewModel
    @StateObject var dashboardViewModel: DashboardViewModel

    @State private var showSettings = false
    @State private var showSourcePicker = false
    @State private var showScanCapture = false
    @State private var showScannerUnavailableAlert = false
    @State private var showFileImporter = false
    @State var selectedPhotoItem: PhotosPickerItem? = nil
    @State var navigateToCards = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    private var isScannerSupported: Bool {
#if targetEnvironment(simulator)
        return false
#else
        return VNDocumentCameraViewController.isSupported
#endif
    }

    init(dashboardViewModel: DashboardViewModel) {
        _dashboardViewModel = StateObject(wrappedValue: dashboardViewModel)
    }

    var body: some View {
        HomeIPadContent(
            dashboardViewModel: dashboardViewModel,
            isScannerSupported: isScannerSupported,
            selectedPhotoItem: $selectedPhotoItem,
            onShowSourcePicker: { showSourcePicker = true },
            onScan: {
                startScan()
            },
            onImportPDF: { showFileImporter = true }
        )
        .navigationTitle("QuickStudy")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Capture settings")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showSourcePicker) {
            SourcePickerView()
        }
        .sheet(isPresented: $showScanCapture) {
            DocumentScannerView(
                onComplete: { images in
                    showScanCapture = false
                    Task {
                        await processOCR(images: images)
                    }
                },
                onCancel: {
                    showScanCapture = false
                }
            )
        }
        .alert("Camera Unavailable", isPresented: $showScannerUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Document scanning isn't available in the simulator. Try on a real device.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .navigationDestination(isPresented: $navigateToCards) {
            CardsView()
                .environmentObject(studyViewModel)
                .environmentObject(appState)
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                Task {
                    await processPDF(url: url)
                }
            case .failure:
                break
            }
        }
        .onChange(of: selectedPhotoItem) { _, _ in
            Task {
                await handleSelectedPhoto()
            }
        }
        .onAppear {
            dashboardViewModel.updateFromStudy(studyViewModel)
        }
        .onChange(of: studyViewModel.document) { _, _ in
            dashboardViewModel.updateFromStudy(studyViewModel)
        }
        .onChange(of: studyViewModel.savedSets) { _, _ in
            dashboardViewModel.updateFromStudy(studyViewModel)
        }
    }

    // MARK: - Import helpers

    private func importHelper() -> DocumentImportHelper {
        DocumentImportHelper(
            isHandwritingMode: studyViewModel.isHandwritingMode,
            isUltraHandwritingMode: studyViewModel.isUltraHandwritingMode
        )
    }

    private func startScan() {
        if isScannerSupported {
            showScanCapture = true
        } else {
            showScannerUnavailableAlert = true
        }
    }

    private func processOCR(images: [UIImage]) async {
        do {
            let text = try await importHelper().extractText(from: images)
            guard !text.isEmpty else {
                await MainActor.run {
                    errorMessage = "No text found in the scanned image. Try scanning a different page."
                    showErrorAlert = true
                }
                return
            }
            studyViewModel.currentSourceType = .scan
            await studyViewModel.loadScannedText(rawText: text)
            await MainActor.run {
                navigateToCards = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to process the scan. Please try again."
                showErrorAlert = true
            }
        }
    }

    private func processPDF(url: URL) async {
        do {
            let text = try await importHelper().extractText(from: url)
            guard !text.isEmpty else {
                await MainActor.run {
                    errorMessage = "No text found in the PDF. Try a different document."
                    showErrorAlert = true
                }
                return
            }
            navigateToCards = true
            studyViewModel.currentSourceType = .pdf
            await studyViewModel.loadScannedText(rawText: text)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to import the PDF. Please check the file and try again."
                showErrorAlert = true
            }
        }
    }

    private func handleSelectedPhoto() async {
        guard let selectedPhotoItem else { return }
        self.selectedPhotoItem = nil

        if let data = try? await selectedPhotoItem.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            do {
                let text = try await importHelper().extractText(from: [image])
                guard !text.isEmpty else {
                    await MainActor.run {
                        errorMessage = "No text found in the photo. Try a different image."
                        showErrorAlert = true
                    }
                    return
                }
                navigateToCards = true
                studyViewModel.currentSourceType = .photo
                await studyViewModel.loadScannedText(rawText: text)
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to process the photo. Please try again."
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - iPhone Home
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var studyViewModel: StudyViewModel
    @StateObject private var dashboardViewModel: DashboardViewModel

    @State private var showSettings = false
    @State private var showSourcePicker = false
    @State private var showScanCapture = false
    @State private var showScannerUnavailableAlert = false
    @State var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showFileImporter = false
    @State var navigateToCards = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var isScannerSupported: Bool {
#if targetEnvironment(simulator)
        return false
#else
        return VNDocumentCameraViewController.isSupported
#endif
    }

    init(viewModel: DashboardViewModel) {
        _dashboardViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
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
        .navigationTitle("QuickStudy")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Capture settings")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showSourcePicker) {
            SourcePickerView()
        }
        .sheet(isPresented: $showScanCapture) {
            DocumentScannerView(
                onComplete: { images in
                    showScanCapture = false
                    navigateToCards = true
                    Task {
                        await processOCR(images: images)
                    }
                },
                onCancel: {
                    showScanCapture = false
                }
            )
        }
        .alert("Camera Unavailable", isPresented: $showScannerUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Document scanning isn't available in the simulator. Try on a real device.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .background(BackgroundView())
        .navigationDestination(isPresented: $navigateToCards) {
            CardsView()
                .environmentObject(studyViewModel)
                .environmentObject(appState)
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf]) { result in
            switch result {
            case .success(let url):
                Task {
                    await processPDF(url: url)
                }
            case .failure:
                break
            }
        }
        .onChange(of: selectedPhotoItem) { _, _ in
            Task {
                await handleSelectedPhoto()
            }
        }
        .onAppear {
            dashboardViewModel.updateFromStudy(studyViewModel)
        }
        .onChange(of: studyViewModel.document) { _, _ in
            dashboardViewModel.updateFromStudy(studyViewModel)
        }
        .onChange(of: studyViewModel.savedSets) { _, _ in
            dashboardViewModel.updateFromStudy(studyViewModel)
        }
    }

    // MARK: Sections

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
                            onReplace: {
                                showSourcePicker = true
                            },
                            onNewScan: {
                                startScan()
                            }
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    ContinueSourceCard(
                        source: source,
                        onReplace: {
                            showSourcePicker = true
                        },
                        onNewScan: {
                            startScan()
                        }
                    )
                }
            } else {
                ContinueEmptyState(
                    selectedPhotoItem: $selectedPhotoItem,
                    isScannerSupported: isScannerSupported,
                    onScan: {
                        startScan()
                    },
                    onPDF: { showFileImporter = true }
                )
            }
        }
    }

    private var createRowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create")
                .font(.headline)

            HStack(spacing: 12) {
                Button {
                    startScan()
                } label: {
                    CreateTile(title: "Scan Document", systemImage: "camera.viewfinder")
                }
                .buttonStyle(.plain)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    CreateTile(title: "Import Photo", systemImage: "photo")
                }
                .buttonStyle(.plain)

                Button {
                    showFileImporter = true
                } label: {
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

    private var quickQuizSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Quiz")
                .font(.headline)

            QuickQuizCard()
        }
    }

    // MARK: - Import helpers

    private func importHelper() -> DocumentImportHelper {
        DocumentImportHelper(
            isHandwritingMode: studyViewModel.isHandwritingMode,
            isUltraHandwritingMode: studyViewModel.isUltraHandwritingMode
        )
    }

    private func startScan() {
        if isScannerSupported {
            showScanCapture = true
        } else {
            showScannerUnavailableAlert = true
        }
    }

    private func processOCR(images: [UIImage]) async {
        do {
            let text = try await importHelper().extractText(from: images)
            guard !text.isEmpty else {
                await MainActor.run {
                    errorMessage = "No text found in the scanned image. Try scanning a different page."
                    showErrorAlert = true
                }
                return
            }
            studyViewModel.currentSourceType = .scan
            await studyViewModel.loadScannedText(rawText: text)
            await MainActor.run {
                navigateToCards = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to process the scan. Please try again."
                showErrorAlert = true
            }
        }
    }

    private func processPDF(url: URL) async {
        do {
            let text = try await importHelper().extractText(from: url)
            guard !text.isEmpty else {
                await MainActor.run {
                    errorMessage = "No text found in the PDF. Try a different document."
                    showErrorAlert = true
                }
                return
            }
            navigateToCards = true
            studyViewModel.currentSourceType = .pdf
            await studyViewModel.loadScannedText(rawText: text)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to import the PDF. Please check the file and try again."
                showErrorAlert = true
            }
        }
    }

    private func handleSelectedPhoto() async {
        guard let selectedPhotoItem else { return }
        self.selectedPhotoItem = nil

        if let data = try? await selectedPhotoItem.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            do {
                let text = try await importHelper().extractText(from: [image])
                guard !text.isEmpty else {
                    await MainActor.run {
                        errorMessage = "No text found in the photo. Try a different image."
                        showErrorAlert = true
                    }
                    return
                }
                navigateToCards = true
                studyViewModel.currentSourceType = .photo
                await studyViewModel.loadScannedText(rawText: text)
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to process the photo. Please try again."
                    showErrorAlert = true
                }
            }
        }
    }
}
