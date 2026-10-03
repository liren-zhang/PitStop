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