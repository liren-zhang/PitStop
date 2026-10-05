//
//  ScheduleMaintenanceUseCase.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation

/// The current service status of a component.
///
/// Used by the ViewModel to decide:
/// - whether to show the component as "ok", "coming up", or "due"
/// - whether to schedule a task
/// - whether to fire a notification, and what to say
enum ServiceStatus: Equatable {
    /// Still within the interval, no action needed yet.
    case ok

    /// Approaching the service interval. Show a soft reminder.
    /// Either value may be nil if the component does not have that interval.
    case upcoming(daysLeft: Int?, kmLeft: Double?)

    /// The interval has been reached. Schedule the task.
    case due

    /// The interval was passed some time ago. Highlight in the UI.
    case overdue(daysPast: Int, kmPast: Double)
}

/// Business operation: determine the service status of a component and,
/// when the interval is reached, schedule a maintenance task.
///
/// A component has two independent intervals:
/// - Mileage: `currentMileage - installedMileage`
/// - Time: `today - installedDate`
///
/// Whichever comes first determines the status. Mileage is recorded
/// manually by the user; the app never guesses daily distance.
///
/// A component enters the "upcoming" window when either interval is
/// within its advance-notice threshold (`advanceNoticeKm` /
/// `advanceNoticeDays`). This lets the user check the component at their
/// convenience before the interval is actually reached.
struct ScheduleMaintenanceUseCase {

    private let assessUseCase: AssessServiceOptionUseCase
    private let calendar: Calendar

    init(
        assessUseCase: AssessServiceOptionUseCase = AssessServiceOptionUseCase(),
        calendar: Calendar = .current
    ) {
        self.assessUseCase = assessUseCase
        self.calendar = calendar
    }

    // MARK: - Status

    /// Return the current service status of a component.
    func status(for component: BikeComponent, on bicycle: Bicycle) -> ServiceStatus {

        // Mileage side
        let kmSinceInstall = bicycle.currentMileageKm - component.installedMileageKm
        let kmLeft: Double? = component.serviceIntervalKm.map { $0 - kmSinceInstall }

        // Time side
        let daysLeft: Int? = component.serviceIntervalDays.flatMap { days in
            guard let dueDate = calendar.date(
                byAdding: .day, value: days, to: component.installedDate
            ) else { return nil }
            return calendar.dateComponents([.day], from: Date(), to: dueDate).day
        }

        // 1. Overdue — either interval has been passed
        if let k = kmLeft, k < 0 {
            return .overdue(daysPast: max(0, -(daysLeft ?? 0)), kmPast: -k)
        }
        if let d = daysLeft, d < 0 {
            return .overdue(daysPast: -d, kmPast: max(0, -(kmLeft ?? 0)))
        }

        // 2. Due — either interval reached exactly
        if let k = kmLeft, k <= 0 { return .due }
        if let d = daysLeft, d <= 0 { return .due }

        // 3. Upcoming — within the advance-notice window
        let kmUpcoming = kmLeft.map { $0 <= component.advanceNoticeKm } ?? false
        let daysUpcoming = daysLeft.map { $0 <= component.advanceNoticeDays } ?? false
        if kmUpcoming || daysUpcoming {
            return .upcoming(daysLeft: daysLeft, kmLeft: kmLeft)
        }

        // 4. Everything else
        return .ok
    }

    /// Convenience: is the component currently due or overdue?
    func isDue(component: BikeComponent, on bicycle: Bicycle) -> Bool {
        let s = status(for: component, on: bicycle)
        return s == .due || isOverdue(s)
    }

    private func isOverdue(_ status: ServiceStatus) -> Bool {
        if case .overdue = status { return true }
        return false
    }

    // MARK: - Scheduling

    /// Schedule an inspection task if the component is due.
    ///
    /// - Returns: A new task, or `nil` if the component is still in the
    ///   `ok` or `upcoming` window.
    /// - Throws: `DomainError.duplicateTask` if a task already exists.
    func execute(
        for component: BikeComponent,
        on bicycle: Bicycle,
        existingTasks: [MaintenanceTask]
    ) throws -> MaintenanceTask? {

        // 1. Reject duplicates
        let alreadyScheduled = existingTasks.contains {
            $0.componentId == component.id && $0.completedDate == nil
        }
        if alreadyScheduled {
            throw DomainError.duplicateTask(component: component.name)
        }

        // 2. Only schedule when actually due or overdue
        guard isDue(component: component, on: bicycle) else {
            return nil
        }

        // 3. Determine service level
        let level = try assessUseCase.execute(component: component)

        // 4. Build the task
        return MaintenanceTask(
            bicycleId: bicycle.id,
            componentId: component.id,
            title: "\(component.name) inspection",
            taskType: .inspection,
            serviceLevel: level,
            isMultiTask: false,
            dueDate: Date()
        )
    }
}