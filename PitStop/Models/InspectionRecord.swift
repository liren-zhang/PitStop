//
//  InspectionRecord.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation

/// The outcome of a single inspection.
enum InspectionResult: String, Codable {
    case pass           // 正常，无需操作
    case observe        // 观察，下次再检查
    case actionNeeded   // 择时更换
    case professional   // 立即更换
}

/// A recorded inspection of a component.
///
/// The `recordedValue` is optional because some inspections are visual
/// (e.g. "chainring teeth look fine") while others are quantitative
/// (e.g. "chain wear is 0.75%").
struct InspectionRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var componentId: UUID
    var date: Date
    var recordedValue: Double?
    var result: InspectionResult
    var notes: String

    init(
        id: UUID = UUID(),
        componentId: UUID,
        date: Date = Date(),
        recordedValue: Double? = nil,
        result: InspectionResult,
        notes: String = ""
    ) {
        self.id = id
        self.componentId = componentId
        self.date = date
        self.recordedValue = recordedValue
        self.result = result
        self.notes = notes
    }
}

// MARK: - User-facing text

extension InspectionResult {

    /// The action the user should take.
    ///
    /// The wording deliberately avoids mentioning shops or DIY, so the
    /// same record reads well whether the user plans to do the work at
    /// home or take the part in later.
    var actionText: String {
        switch self {
        case .pass:         return "All good"
        case .observe:      return "Keep an eye on it"
        case .actionNeeded: return "Replace when convenient"
        case .professional: return "Replace now"
        }
    }

    /// Whether the component's service interval should be reset after
    /// an inspection with this result.
    ///
    /// `pass`, `observe` and `actionNeeded` all reset the interval,
    /// because the check has been carried out. Only `professional`
    /// leaves the interval running, since the problem has not yet been
    /// resolved.
    var resetsInterval: Bool {
        switch self {
        case .pass, .observe, .actionNeeded:
            return true
        case .professional:
            return false
        }
    }
}
