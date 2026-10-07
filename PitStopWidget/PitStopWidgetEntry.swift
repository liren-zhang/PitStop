//
//  PitStopWidgetEntry.swift
//  PitStop
//
//  Created by Liren Zhang on 7/10/2026.
//

import Foundation
import WidgetKit

/// A single timeline entry for the PitStop widget.
struct PitStopWidgetEntry: TimelineEntry {
    let date: Date
    let bicycles: [SharedDataManager.BicycleSnapshot]
}

/// Provides the timeline of entries that the widget displays.
struct PitStopWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> PitStopWidgetEntry {
        PitStopWidgetEntry(
            date: Date(),
            bicycles: [
                .init(
                    id: UUID(),
                    name: "Commuter",
                    dueCount: 2,
                    nextTaskTitle: "Chain inspection",
                    nextTaskDue: Date(),
                    mostUrgentLevel: .diyWithTools
                )
            ]
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (PitStopWidgetEntry) -> Void
    ) {
        let entry = PitStopWidgetEntry(
            date: Date(),
            bicycles: SharedDataManager().readSnapshot()
        )
        completion(entry)
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<PitStopWidgetEntry>) -> Void
    ) {
        let snapshots = SharedDataManager().readSnapshot()
        let entry = PitStopWidgetEntry(date: Date(), bicycles: snapshots)

        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }
}
