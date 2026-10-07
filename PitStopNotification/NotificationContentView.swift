//
//  NotificationContentView.swift
//  PitStop
//
//  Created by Liren Zhang on 7/10/2026.
//

import SwiftUI

/// Data passed from the notification payload into the SwiftUI view.
struct NotificationContentModel {
    let componentName: String
    let standard: String
    let recommendation: String
    let serviceLevel: ServiceLevel?
}

/// The visual layout of a PitStop maintenance notification.
struct NotificationContentView: View {

    let model: NotificationContentModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack(spacing: 8) {
                Image(systemName: model.serviceLevel?.iconName ?? "wrench.and.screwdriver.fill")
                    .foregroundStyle(model.serviceLevel?.color ?? .blue)
                Text(model.componentName)
                    .font(.headline)
            }

            Divider()

            if !model.standard.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Standard")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(model.standard)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !model.recommendation.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recommendation")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(model.recommendation)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NotificationContentView(model: NotificationContentModel(
        componentName: "Chain",
        standard: "Wear under 0.5% = fine. 0.75% = plan a replacement.",
        recommendation: "DIY — check with a chain wear indicator. Takes 2 minutes.",
        serviceLevel: .diySimple
    ))
}
