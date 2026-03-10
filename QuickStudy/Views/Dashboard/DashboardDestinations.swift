//
//  DashboardDestinations.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/28/26.
//

import SwiftUI

// MARK: - Placeholder destinations

struct ReviewGenerateView: View {
    var body: some View {
        Text("Review & Generate")
            .navigationTitle("Review")
    }
}

struct ScanCaptureView: View {
    var body: some View {
        Text("Scan Capture")
            .navigationTitle("Scan")
    }
}

struct PhotoImportView: View {
    var body: some View {
        Text("Photo Import")
            .navigationTitle("Import Photo")
    }
}

struct PDFImportView: View {
    var body: some View {
        Text("PDF Import")
            .navigationTitle("Import PDF")
    }
}

struct StudySetDetailView: View {
    @EnvironmentObject var viewModel: StudyViewModel
    @EnvironmentObject var appState: AppState
    let set: StudySet

    var body: some View {
        CardsView()
            .onAppear {
                viewModel.loadSet(set)
                appState.setDetailViewAppeared = Date()
            }
    }
}

struct SourcePickerView: View {
    var body: some View {
        Text("Pick a source")
            .navigationTitle("Replace Source")
    }
}
