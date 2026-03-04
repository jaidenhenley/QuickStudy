//
//  HomeIPadContent.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/28/26.
//

import SwiftUI
import PhotosUI

struct HomeIPadContent: View {
    @EnvironmentObject var studyViewModel: StudyViewModel

    @ObservedObject var dashboardViewModel: DashboardViewModel
    let isScannerSupported: Bool
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let onShowSourcePicker: () -> Void
    let onScan: () -> Void
    let onImportPDF: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let m = LayoutMetrics(availableWidth: proxy.size.width)
            let leftColumn = VStack(alignment: .leading, spacing: m.spacing) {
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
                                    onReplace: onShowSourcePicker,
                                    onNewScan: onScan
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            ContinueSourceCard(
                                source: source,
                                onReplace: onShowSourcePicker,
                                onNewScan: onScan
                            )
                        }
                    } else {
                        ContinueEmptyState(
                            selectedPhotoItem: $selectedPhotoItem,
                            isScannerSupported: isScannerSupported,
                            onScan: onScan,
                            onPDF: onImportPDF
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Create")
                        .font(.headline)

                    HStack(spacing: 12) {
                        Button {
                            onScan()
                        } label: {
                            CreateTile(title: "Scan Document", systemImage: "camera.viewfinder")
                        }
                        .buttonStyle(.plain)

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            CreateTile(title: "Import Photo", systemImage: "photo")
                        }
                        .buttonStyle(.plain)

                        Button {
                            onImportPDF()
                        } label: {
                            CreateTile(title: "Import PDF", systemImage: "doc")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            let rightColumn = VStack(alignment: .leading, spacing: m.spacing) {
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

                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Quiz")
                        .font(.headline)

                    QuickQuizCard()
                }
            }

            ScrollView {
                Group {
                    if m.isStacked {
                        VStack(alignment: .leading, spacing: m.spacing) {
                            leftColumn
                            rightColumn
                        }
                    } else {
                        HStack(alignment: .top, spacing: m.spacing) {
                            leftColumn
                                .frame(width: m.leftColumnWidth, alignment: .topLeading)
                            rightColumn
                                .frame(minWidth: 320, maxWidth: .infinity, alignment: .topLeading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, m.padding)
                .padding(.bottom, m.padding)
            }
        }
        .background(BackgroundView())
    }
}
