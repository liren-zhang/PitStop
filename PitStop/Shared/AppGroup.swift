//
//  AppGroup.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation

/// Central definition of the App Group shared between the main app, the
/// widget extension, and the notification extension.
///
/// Every target that needs to share data must use the same identifier.
/// If the identifier changes here, it must also be updated in each
/// target's Signing & Capabilities tab.
enum AppGroup {

    /// The shared container identifier.
    static let identifier = "group.com.liren.PitStop"

    /// The URL of the shared container, or `nil` if the App Group is not
    /// correctly configured (which usually means a signing problem).
    static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        )
    }

    /// Keys used for values stored in `UserDefaults(suiteName:)`.
    enum Keys {
        /// JSON-encoded snapshot of bicycles and their due counts, written
        /// by the main app and read by the widget.
        static let widgetSnapshot = "widget_snapshot"
        /// Timestamp of the last widget refresh, used to avoid redundant
        /// writes when nothing changed.
        static let widgetLastRefresh = "widget_last_refresh"
    }
}