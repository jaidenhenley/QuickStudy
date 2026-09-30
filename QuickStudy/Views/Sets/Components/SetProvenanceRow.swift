//
//  SetProvenanceRow.swift
//  QuickStudy
//

import SwiftUI

struct SetProvenanceRow: View {
    let sourceType: StudySourceType
    let provenance: GenerationProvenance?

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(provenance?.engine == .cloud ? Color.appAIAccent : Color.appPrimary)
                .frame(width: 40, height: 40)
                .background(
                    (provenance?.engine == .cloud ? Color.appAIAccent : Color.appPrimary).opacity(0.12),
                    in: RoundedRectangle(cornerRadius: AppRadius.sm)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .appGlassCard(cornerRadius: AppRadius.lg)
    }

    private var symbol: String {
        switch sourceType {
        case .manual: return "square.and.pencil"
        case .demo: return "sparkles"
        default:
            switch provenance?.engine {
            case .cloud: return "icloud"
            case .externalAPI: return "key"
            case .onDevice: return "iphone"
            case nil: return "sparkles"
            }
        }
    }

    private var title: String {
        switch sourceType {
        case .manual: return "Cards you typed"
        case .demo: return "Sample set"
        default:
            switch provenance?.engine {
            case .cloud: return "Drafted in the cloud"
            case .externalAPI: return "Drafted with your API key"
            case .onDevice: return "Drafted on this iPhone"
            case nil: return "Drafted by AI"
            }
        }
    }

    private var detail: String {
        let origin: String
        switch sourceType {
        case .scan: origin = "From a scan"
        case .photo: origin = "From a photo"
        case .pdf: origin = "From a PDF"
        case .paste: origin = "From pasted text"
        case .manual: return "Written by hand, no AI involved"
        case .demo: return "Included with QuickStudy"
        }
        guard let provenance else { return "\(origin) · saved before engines were recorded" }
        switch provenance.engine {
        case .cloud: return "\(origin) · QuickStudy server"
        case .externalAPI, .onDevice: return "\(origin) · \(provenance.model ?? "unknown model")"
        }
    }
}
