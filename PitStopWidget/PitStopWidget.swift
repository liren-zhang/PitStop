//
//  PitStopWidget.swift
//  PitStopWidget
//
//  Created by Liren Zhang on 7/10/2026.
//

import WidgetKit
import SwiftUI

/// The PitStop widget.
///
/// Supports two families:
/// - `.systemSmall` — shows the count of due tasks for the most urgent bike.
/// - `.systemMedium` — shows up to two bikes and their due counts.
///
/// The widget never opens the Core Data store. It reads the lightweight
/// JSON snapshot that the main app writes into the App Group container.
struct PitStopWidget: Widget {

    let kind = "PitStopWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PitStopWidgetProvider()) { entry in
            PitStopWidgetView(entry: entry)
        }
        .configurationDisplayName("PitStop")
        .description("See which bike needs attention before your next ride.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget view

/// Renders the widget content for the two supported families.
struct PitStopWidgetView: View {

    @Environment(\.widgetFamily) private var family
    let entry: PitStopWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: Small

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundStyle(.tint)
                Spacer()
            }
            Spacer()
            Text("\(totalDue)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
            Text(totalDue == 1 ? "task due" : "tasks due")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    // MARK: Medium

    private var mediumView: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundStyle(.tint)
                Spacer()
                Text("\(totalDue)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(totalDue == 1 ? "task due" : "tasks due")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                if topBicycles.isEmpty {
                    Text("No bikes yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(topBicycles, id: \.id) { bike in
                        bikeRow(bike)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    // MARK: Row

    private func bikeRow(_ bike: SharedDataManager.BicycleSnapshot) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(levelColor(bike.mostUrgentLevel))
                .frame(width: 8, height: 8)
            Text(bike.name)
                .font(.caption)
                .lineLimit(1)
            Spacer()
            Text("\(bike.dueCount)")
                .font(.caption.bold())
        }
    }

    // MARK: Helpers

    private var totalDue: Int {
        entry.bicycles.reduce(0) { $0 + $1.dueCount }
    }

    private var topBicycles: [SharedDataManager.BicycleSnapshot] {
        entry.bicycles
            .sorted { $0.dueCount > $1.dueCount }
            .prefix(2)
            .map { $0 }
    }

    private func levelColor(_ level: ServiceLevel?) -> Color {
        switch level {
        case .shopRequired:     return .red
        case .shopRecommended:  return .orange
        case .diyWithTools:     return .blue
        case .diySimple, nil:   return .green
        }
    }
}
