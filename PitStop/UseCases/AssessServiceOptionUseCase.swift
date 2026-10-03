//
//  AssessServiceOptionUseCase.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation

/// Business operation: decide the correct service level for a maintenance
/// task on a given component.
///
/// This is the core decision logic of PitStop. It reflects how cyclists
/// actually decide where to get work done: most tasks are doable at home,
/// but some are avoided because of tool cost, consumable cost, time, or
/// the fact that several tasks are being combined at once.
struct AssessServiceOptionUseCase {

    /// Assess the service level of a component.
    ///
    /// Rules, applied in order:
    /// 1. Difficulty 4+, or safety-critical with difficulty 3+ → shop required.
    /// 2. Needs special tools, or needs consumables, or estimated time over
    ///    90 minutes, or is part of a multi-task job → shop recommended.
    /// 3. Difficulty 2 or less → DIY simple.
    /// 4. Otherwise → DIY with tools.
    ///
    /// - Parameter component: The component to assess.
    /// - Returns: The `ServiceLevel` the cyclist should plan for.
    /// - Throws: `DomainError.incompleteComponentData` if the difficulty
    ///   value is out of the expected 1–5 range.
    func execute(component: BikeComponent) throws -> ServiceLevel {

        // 1. Validate the difficulty rating
        guard (1...5).contains(component.technicalDifficulty) else {
            throw DomainError.incompleteComponentData(
                component: component.name
            )
        }

        let difficulty = component.technicalDifficulty
        let safetyCritical = component.isSafetyCritical

        // 2. Safety-critical and moderately difficult → shop required
        if difficulty >= 4 || (safetyCritical && difficulty >= 3) {
            return .shopRequired
        }

        // 3. Shop-recommended conditions
        let multiTaskPenalty = component.estimatedMinutes > 90
        if component.needsSpecialTools ||
           component.needsConsumables ||
           multiTaskPenalty {
            return .shopRecommended
        }

        // 4. Easy DIY
        if difficulty <= 2 {
            return .diySimple
        }

        // 5. Everything else
        return .diyWithTools
    }

    /// Combine the service levels of several components into a single level.
    ///
    /// Used for a full "big service" that covers several tasks. The result
    /// is the highest level among all components, because the overall job
    /// cannot be easier than its most demanding task.
    ///
    /// - Parameter components: The components being serviced together.
    /// - Returns: The highest `ServiceLevel` among the inputs.
    func combine(components: [BikeComponent]) throws -> ServiceLevel {
        guard !components.isEmpty else {
            throw DomainError.incompleteComponentData(component: "service")
        }
        var highest = ServiceLevel.diySimple
        for component in components {
            let level = try execute(component: component)
            if level.priority > highest.priority {
                highest = level
            }
        }
        return highest
    }
}

// MARK: - Priority ordering for combination

extension ServiceLevel {
    /// Higher number = more demanding. Used to combine service levels.
    var priority: Int {
        switch self {
        case .diySimple:        return 0
        case .diyWithTools:     return 1
        case .shopRecommended:  return 2
        case .shopRequired:     return 3
        }
    }
}