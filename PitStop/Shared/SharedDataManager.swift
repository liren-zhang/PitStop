//
//  SharedDataManager.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation
import WidgetKit

/// Bridges the main app and its extensions through the App Group.
///
/// The main app writes a lightweight JSON snapshot of the data the
/// widget needs. The widget reads that snapshot without needing to open
/// the Core Data store (which would be slow and may not be available in
/// the extension's memory budget).
///
/// Whenever the underlying data changes, call `writeSnapshot(_:)` — it
/// also triggers a widget reload automatically.
struct SharedDataManager {

    // MARK: - Snapshot type

    /// A simplified view of a bicycle, sized to fit comfortably in
    /// `UserDefaults`. Only the fields the widget actually displays.
    struct BicycleSnapshot: Codable {
        let id: UUID
        let name: String
        let dueCount: Int
        let nextTaskTitle: String?
        let nextTaskDue: Date?
        let mostUrgentLevel: ServiceLevel?
    }

    // MARK: - Access

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroup.identifier)
    }

    // MARK: - Writing (main app)

    /// Serialise the current snapshots and store them in the shared
    /// container. Also tells WidgetKit to refresh.
    func writeSnapshot(_ snapshots: [BicycleSnapshot]) {
        guard let defaults = defaults else { return }
        if let data = try? JSONEncoder().encode(snapshots) {
            defaults.set(data, forKey: AppGroup.Keys.widgetSnapshot)
            defaults.set(Date(), forKey: AppGroup.Keys.widgetLastRefresh)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: - Reading (extensions)

    /// Load the most recent snapshot written by the main app.
    /// Returns an empty array if nothing has been written yet.
    func readSnapshot() -> [BicycleSnapshot] {
        guard let defaults = defaults,
              let data = defaults.data(forKey: AppGroup.Keys.widgetSnapshot),
              let snapshots = try? JSONDecoder().decode([BicycleSnapshot].self, from: data)
        else {
            return []
        }
        return snapshots
    }
}