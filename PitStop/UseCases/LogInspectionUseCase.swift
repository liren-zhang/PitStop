//
//  LogInspectionUseCase.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation

/// Business operation: record the result of a component inspection and
/// decide what the result means for the cyclist.
///
/// The rules below are based on manufacturer recommendations and common
/// workshop practice. They are intentionally conservative for safety-
/// critical components (brakes) and more relaxed for others (chain wear
/// is checked at multiple thresholds so the cyclist can plan ahead).
struct LogInspectionUseCase {

    /// Evaluate a measured value for a component and return the result.
    ///
    /// - Parameters:
    ///   - component: The component being inspected.
    ///   - measuredValue: The numeric reading. Meaning depends on category:
    ///     - chain: wear percentage (0.0 – 1.5)
    ///     - brakePad: pad thickness in mm
    ///     - brakeRotor: rotor thickness in mm
    ///     - battery: gear indicator 0–5 (5 = green solid, 0 = red flashing)
    ///     - other: ignored
    /// - Returns: The appropriate `InspectionResult`.
    /// - Throws: `DomainError.valueOutOfRange` if the reading is implausible.
    func execute(
        component: BikeComponent,
        measuredValue: Double?
    ) throws -> InspectionResult {

        switch component.category {

        // MARK: - Chain wear
        // Standard chain wear thresholds used across the industry.
        case .chain:
            guard let value = measuredValue else { return .observe }
            guard value >= 0, value <= 1.5 else {
                throw DomainError.valueOutOfRange(
                    component: "chain wear",
                    value: value,
                    max: 1.5
                )
            }
            if value < 0.5 { return .pass }
            if value < 0.75 { return .observe }
            if value < 1.0 { return .actionNeeded }
            return .professional

        // MARK: - Brake pads
        // Below 1 mm is a safety concern. Above 3 mm is new.
        case .brakePad:
            guard let value = measuredValue else { return .observe }
            guard value >= 0, value <= 10 else {
                throw DomainError.valueOutOfRange(
                    component: "brake pad thickness",
                    value: value,
                    max: 10
                )
            }
            if value < 1.0 { return .professional }
            if value < 2.0 { return .actionNeeded }
            if value < 3.0 { return .observe }
            return .pass

        // MARK: - Brake rotor
        // Rotors below 1.5 mm must be replaced. This is safety-critical.
        case .brakeRotor:
            guard let value = measuredValue else { return .observe }
            guard value >= 0, value <= 5 else {
                throw DomainError.valueOutOfRange(
                    component: "rotor thickness",
                    value: value,
                    max: 5
                )
            }
            if value < 1.5 { return .professional }
            if value < 1.8 { return .actionNeeded }
            return .pass

        // MARK: - Electronic groupset battery
        // Uses gear indication lights rather than a percentage.
        // 5 = green solid, 4 = green flashing, 3 = yellow solid,
        // 2 = yellow flashing, 1 = red solid, 0 = red flashing.
        case .battery:
            guard let value = measuredValue else { return .observe }
            switch Int(value) {
            case 5, 4:  return .pass
            case 3:     return .observe
            case 2:     return .actionNeeded
            default:    return .professional   // red solid or flashing
            }

        // MARK: - Tyres and everything else
        default:
            return .pass
        }
    }
}

// MARK: - Interval reset

extension LogInspectionUseCase {

    /// Return an updated copy of a component with its service interval
    /// reset, if the inspection result allows it.
    ///
    /// `pass`, `observe` and `actionNeeded` all reset the interval —
    /// the check has been done, so the countdown starts again. Only
    /// `professional` leaves the interval running, because the problem
    /// has not yet been resolved and the reminder should stay active.
    ///
    /// - Parameters:
    ///   - component: The component that was just inspected.
    ///   - bicycle: The bicycle it belongs to (provides the current mileage).
    ///   - result: The result returned by `execute`.
    /// - Returns: A copy of the component with updated install date and
    ///   mileage, or the original component if no reset is required.
    func updatedComponentAfterInspection(
        _ component: BikeComponent,
        bicycle: Bicycle,
        result: InspectionResult
    ) -> BikeComponent {
        guard result.resetsInterval else { return component }

        var updated = component
        updated.installedMileageKm = bicycle.currentMileageKm
        updated.installedDate = Date()
        return updated
    }
}
