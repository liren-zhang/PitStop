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
    case actionNeeded   // 建议处理（例如更换链条）
    case professional   // 必须去车店
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
    var recordedValue: Double?     // 例如链条拉伸百分比、刹车片厚度 mm
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

    /// The action the user should take, given whether a shop is needed.
    ///
    /// `actionNeeded` means "deal with this soon, at your convenience".
    /// `professional` means "deal with this now".
    ///
    /// Whether the action is a shop visit or a replacement depends on
    /// the service level, which the caller passes in via `needsShop`.
    func actionText(needsShop: Bool) -> String {
        switch self {
        case .pass:
            return "All good"
        case .observe:
            return "Keep an eye on it"
        case .actionNeeded:
            return needsShop ? "Shop when convenient" : "Replace when convenient"
        case .professional:
            return needsShop ? "Visit shop now" : "Replace now"
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
