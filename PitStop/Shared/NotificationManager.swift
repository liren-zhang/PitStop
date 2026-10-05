//
//  NotificationManager.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation
import UserNotifications

/// Thin wrapper around `UNUserNotificationCenter`.
///
/// Handles permission requests and schedules local notifications for
/// components that have entered the "upcoming" or "due" window.
final class NotificationManager {

    static let shared = NotificationManager()

    /// The notification category used to route notifications to the
    /// custom content extension.
    static let maintenanceCategory = "PITSTOP_MAINTENANCE_DUE"

    private init() {
        registerCategory()
    }

    // MARK: - Setup

    /// Ask the user for permission to send notifications.
    func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Register the custom notification category so iOS can display it
    /// with the content extension's custom UI.
    private func registerCategory() {
        let category = UNNotificationCategory(
            identifier: Self.maintenanceCategory,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current()
            .setNotificationCategories([category])
    }

    // MARK: - Scheduling

    /// Schedule a reminder for a component that is coming up or due.
    ///
    /// - Parameters:
    ///   - componentName: The component the user should look at.
    ///   - message: A short description written in domain language.
    ///   - triggerDate: When the notification should fire.
    func scheduleReminder(
        componentName: String,
        message: String,
        at triggerDate: Date
    ) {
        let content = UNMutableNotificationContent()
        content.title = "\(componentName) needs attention"
        content.body = message
        content.categoryIdentifier = Self.maintenanceCategory
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: comps,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}