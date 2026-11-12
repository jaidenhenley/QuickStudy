//
//  PageThumbnailCell.swift
//  QuickStudy
//

import SwiftUI

struct PageThumbnailCell: View {
    let pageIndex: Int
    let viewModel: ChoosePagesViewModel
    let action: () -> Void

    @State private var image: UIImage?

    var body: some View {
        let isSelected = viewModel.isSelected(pageIndex)

        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(Theme.surface)
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        ProgressView()
                    }
                }
                .aspectRatio(0.75, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .strokeBorder(isSelected ? Theme.primary : Theme.hairline, lineWidth: isSelected ? 2.5 : 1)
                }
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Theme.onPrimary, Theme.primary)
                            .padding(Spacing.xs)
                    }
                }

                Text("\(pageIndex + 1)")
                    .font(.footnote)
                    .foregroundStyle(isSelected ? Theme.textPrimary : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Page \(pageIndex + 1)")
        .accessibilityValue(isSelected ? Text("Selected") : Text("Not selected"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .task(id: pageIndex) {
            image = await viewModel.thumbnail(at: pageIndex)
        }
    }
}
