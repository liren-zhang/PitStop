//
//  ScheduleMaintenanceUseCase.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation

/// Business operation: decide whether a component is due for inspection,
/// and schedule a task if so.
///
/// A component is due when **either** of its service intervals has been
/// reached:
/// - Mileage: `currentMileage - installedMileage >= serviceIntervalKm`
/// - Time: `now - installedDate >= serviceIntervalDays`
///
/// Whichever comes first triggers the reminder. Mileage is recorded by
/// the user — the app never guesses how much they ride.
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

    /// Check whether a component has reached either service interval.
    ///
    /// - Parameters:
    ///   - component: The component to check.
    ///   - bicycle: The bicycle it belongs to (used for the current mileage).
    /// - Returns: `true` if either interval has been reached or exceeded.
    func isDue(component: BikeComponent, on bicycle: Bicycle) -> Bool {
        let kmDue = isMileageDue(component: component, bicycle: bicycle)
        let timeDue = isTimeDue(component: component)
        return kmDue || timeDue
    }

    /// Schedule an inspection for a component if it is due.
    ///
    /// - Parameters:
    ///   - component: The component to schedule.
    ///   - bicycle: The bicycle it belongs to.
    ///   - existingTasks: All currently scheduled tasks (to prevent duplicates).
    /// - Returns: A new `MaintenanceTask`, or `nil` if the component is not
    ///   yet due.
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

        // 2. Only schedule if actually due
        guard isDue(component: component, on: bicycle) else {
            return nil
        }

        // 3. Determine service level
        let level = try assessUseCase.execute(component: component)

        // 4. Build the task (due immediately since the interval has passed)
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

    // MARK: - Private

    /// Check the mileage-based interval.
    private func isMileageDue(component: BikeComponent, bicycle: Bicycle) -> Bool {
        guard let interval = component.serviceIntervalKm else { return false }
        let sinceInstall = bicycle.currentMileageKm - component.installedMileageKm
        return sinceInstall >= interval
    }

    /// Check the time-based interval.
    private func isTimeDue(component: BikeComponent) -> Bool {
        guard let days = component.serviceIntervalDays else { return false }
        guard let dueDate = calendar.date(
            byAdding: .day,
            value: days,
            to: component.installedDate
        ) else { return false }
        return Date() >= dueDate
    }
}