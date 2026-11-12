//
//  SessionCard.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import SwiftUI

struct SessionCard: View {
    @Environment(TodayViewModel.self) var todayViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let onStart: () -> Void

    @State private var showBreakdown = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("TODAY'S SESSION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.onPrimary)
                .tracking(1)
                .accessibilityAddTraits(.isHeader)

            let countLayout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Spacing.sm))

            countLayout {
                Text("\(todayViewModel.todayCardCount)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(Theme.onPrimary)
                Text("cards · \(todayViewModel.estimatedMin) min")
                    .font(.title3)
                    .foregroundStyle(Theme.onPrimary.opacity(0.9))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(todayViewModel.todayCardCount) cards, \(todayViewModel.estimatedMin) minutes")

            Button(action: onStart) {
                Text("Start Session")
                    .font(.headline)
                    .foregroundStyle(Theme.onLightAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.onPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }

            Button {
                showBreakdown.toggle()
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text("What's in this?")
                    Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .accessibilityHidden(true)
                }
                .font(.subheadline)
                .foregroundStyle(Theme.onPrimary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(.rect)
            }
            .accessibilityValue(showBreakdown ? Text("Expanded") : Text("Collapsed"))

            if showBreakdown {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(todayViewModel.sessionBreakdown) { entry in
                        HStack {
                            Text(entry.title)
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                            Spacer()
                            Text("\(entry.cardCount)")
                        }
                        .font(.footnote)
                        .foregroundStyle(Theme.onPrimary)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(entry.title), \(entry.cardCount) cards")
                    }
                }
                .appTransition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding()
        .background(
            Theme.primaryFill
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Theme.onPrimary.opacity(0.06))
                        .frame(width: 230, height: 230)
                        .offset(x: 70, y: -70)
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .appAnimation(Motion.snappy, value: showBreakdown)
    }
}
