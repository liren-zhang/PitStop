//
//  AssessServiceOptionUseCase.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation

/// Business operation: decide whether a component's service can be done
/// at home, or whether it should go to a shop.
///
/// The decision reflects how cyclists actually think about a job:
/// - **Can I do it?** (difficulty rating)
/// - **Do I have what I need?** (tools, consumables)
/// - **Do I have time?** (estimated minutes)
/// - **Is it safe to get wrong?** (safety-critical + difficulty)
///
/// A shop is only recommended or required when one of those four
/// conditions fails. Otherwise the work is classified as a DIY job.
struct AssessServiceOptionUseCase {

    /// Assess the service level of a component.
    ///
    /// Rules, applied in order:
    ///
    /// **Shop required** — the job cannot safely or realistically be
    /// done at home:
    /// - Difficulty 4 or 5 (needs guidance, or not capable), or
    /// - Safety-critical and difficulty 3 or above.
    ///
    /// **Shop recommended** — doable at home, but the effort makes it
    /// more sensible to pay a shop:
    /// - No tools, no consumables, or more than 90 minutes of work.
    ///
    /// **DIY simple** — easy, no special tools, no consumables.
    ///
    /// **DIY with tools** — anything else.
    ///
    /// - Throws: `DomainError.incompleteComponentData` when the difficulty
    ///   value is outside the 1–5 range.
    func execute(component: BikeComponent) throws -> ServiceLevel {

        // 1. Validate the difficulty rating
        guard (1...5).contains(component.technicalDifficulty) else {
            throw DomainError.incompleteComponentData(
                component: component.name
            )
        }

        let difficulty = component.technicalDifficulty

        // 2. Shop required — the job is beyond home capability, or it
        //    is safety-critical and needs care.
        let tooHard = difficulty >= 4
        let safetyRisk = component.isSafetyCritical && difficulty >= 3
        if tooHard || safetyRisk {
            return .shopRequired
        }

        // 3. Shop recommended — the job is doable at home but the effort
        //    or missing items make a shop the better choice.
        let missingItems = component.needsSpecialTools
            || component.needsConsumables
        let tooLong = component.estimatedMinutes > 90
        if missingItems || tooLong {
            return .shopRecommended
        }

        // 4. DIY simple — quick, no tools, no consumables.
        if difficulty <= 2
            && !component.needsSpecialTools
            && !component.needsConsumables {
            return .diySimple
        }

        // 5. Everything else.
        return .diyWithTools
    }

    /// Combine the service levels of several components into a single level.
    ///
    /// Used for a full "big service" that covers several tasks. The result
    /// is the highest level among all components, because the overall job
    /// cannot be easier than its most demanding task.
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
