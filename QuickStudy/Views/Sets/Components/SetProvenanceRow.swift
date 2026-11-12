//
//  SetProvenanceRow.swift
//  QuickStudy
//

import SwiftUI

struct SetProvenanceRow: View {
    let sourceType: StudySourceType
    let provenance: GenerationProvenance?

    @ScaledMetric(relativeTo: .headline) private var tileSize = 40

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(provenance?.engine == .cloud ? Color.appAIAccent : Color.appPrimary)
                .frame(width: tileSize, height: tileSize)
                .background(
                    (provenance?.engine == .cloud ? Color.appAIAccent : Color.appPrimary).opacity(0.12),
                    in: RoundedRectangle(cornerRadius: AppRadius.sm)
                )
                .accessibilityHidden(true)

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
        .accessibilityElement(children: .combine)
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
            case .privateCloud: return "lock.icloud"
            case nil: return "sparkles"
            }
        }
    }

    private var title: String {
        switch sourceType {
        case .manual: return String(localized: "Cards you typed")
        case .demo: return String(localized: "Sample set")
        default:
            switch provenance?.engine {
            case .cloud: return String(localized: "Drafted in the cloud")
            case .externalAPI: return String(localized: "Drafted with your API key")
            case .onDevice: return String(localized: "Drafted on this iPhone")
            case .privateCloud: return String(localized: "Drafted with Private Cloud Compute")
            case nil: return String(localized: "Drafted by AI")
            }
        }
    }

    private var detail: String {
        let origin: String
        switch sourceType {
        case .scan: origin = String(localized: "From a scan")
        case .photo: origin = String(localized: "From a photo")
        case .pdf: origin = String(localized: "From a PDF")
        case .paste: origin = String(localized: "From pasted text")
        case .manual: return String(localized: "Written by hand, no AI involved")
        case .demo: return String(localized: "Included with QuickStudy")
        }
        guard let provenance else { return String(localized: "\(origin) · saved before engines were recorded") }
        switch provenance.engine {
        case .cloud: return String(localized: "\(origin) · QuickStudy server")
        case .externalAPI, .onDevice, .privateCloud: let model = provenance.model ?? String(localized: "unknown model")
            return String(localized: "\(origin) · \(model)")
        }
    }
}
