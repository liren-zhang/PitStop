//
//  DomainError.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation

/// Errors that can occur across PitStop's business operations.
///
/// Every case describes a situation a real cyclist could encounter.
/// The `errorDescription` uses plain, domain-appropriate language so it
/// can be shown directly in the UI — not only in developer logs.
enum DomainError: LocalizedError {

    // MARK: - Inspection
    /// A recorded value is outside the plausible range for that component.
    case valueOutOfRange(component: String, value: Double, max: Double)
    /// The component the user is trying to inspect no longer exists.
    case componentNotFound(name: String)

    // MARK: - Service assessment
    /// A component is missing data required to assess its service level.
    case incompleteComponentData(component: String)

    // MARK: - Scheduling
    /// The user tried to schedule a task in the past.
    case dateInPast
    /// A task for this component is already pending.
    case duplicateTask(component: String)
    /// The bicycle the user selected no longer exists.
    case bicycleNotFound(name: String)

    var errorDescription: String? {
        switch self {
        case .valueOutOfRange(let component, let value, let max):
            return "The \(component) reading of \(value) is outside the expected range. Please check the measurement again (maximum: \(max))."

        case .componentNotFound(let name):
            return "We couldn't find the \(name) on this bike. It may have been removed."

        case .incompleteComponentData(let component):
            return "The \(component) is missing information needed to assess its service level."

        case .dateInPast:
            return "That date has already passed. Please choose a future date for the reminder."

        case .duplicateTask(let component):
            return "A task for the \(component) is already scheduled. Complete or remove the existing one first."

        case .bicycleNotFound(let name):
            return "The bicycle '\(name)' is no longer in your garage."
        }
    }
}