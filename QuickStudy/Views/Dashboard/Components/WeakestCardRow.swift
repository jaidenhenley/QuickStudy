//
//  WeakestCardRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import SwiftUI

struct WeakestCardRow: View {
    let weakest: WeakestCardInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WEAKEST CARD")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(1)

            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemPink).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Text("\(weakest.missCount)×")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.pink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(weakest.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text("Missed \(weakest.missCount) \(weakest.missCount == 1 ? "time" : "times") — drill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
