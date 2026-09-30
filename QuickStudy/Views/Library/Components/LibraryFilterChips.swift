//
//  LibraryFilterChips.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct LibraryFilterChips: View {
    @Binding var selection: LibraryViewModel.Filter
    @Namespace private var chipTransition

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer {
                HStack(spacing: 8) {
                    ForEach(LibraryViewModel.Filter.allCases) { filter in
                        Button {
                            selection = filter
                        } label: {
                            Text(filter.label)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(selection == filter ? Color.white : Theme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .glassEffect(
                                    selection == filter ? .regular.tint(Color.appPrimary) : .regular,
                                    in: .capsule
                                )
                                .glassEffectID(filter, in: chipTransition)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .scrollClipDisabled()
        .sensoryFeedback(.selection, trigger: selection)
    }
}
