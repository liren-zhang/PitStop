//
//  BikeComponent.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation

/// The category a component belongs to.
enum ComponentCategory: String, Codable, CaseIterable {
    case chain          // 链条
    case cassette       // 飞轮
    case chainring      // 牙盘
    case brakePad       // 刹车片 / 来令片
    case brakeRotor     // 碟片
    case tyre           // 轮胎
    case gearCable      // 变速线
    case brakeCable     // 刹车线
    case battery        // 电变电池
    case bottomBracket  // 中轴
    case hubBearing     // 花鼓轴承
    case other

    /// 该类别是否需要检查
    var displayName: String {
        switch self {
        case .chain:         return "Chain"
        case .cassette:      return "Cassette"
        case .chainring:     return "Chainring"
        case .brakePad:      return "Brake Pad"
        case .brakeRotor:    return "Brake Rotor"
        case .tyre:          return "Tyre"
        case .gearCable:     return "Gear Cable"
        case .brakeCable:    return "Brake Cable"
        case .battery:       return "Battery"
        case .bottomBracket: return "Bottom Bracket"
        case .hubBearing:    return "Hub Bearing"
        case .other:         return "Other"
        }
    }
}

/// A single component installed on a bicycle.
///
/// Each component tracks its own service interval, difficulty rating, and
/// the flags used by `AssessServiceOptionUseCase` to determine the correct
/// `ServiceLevel` for a task.
struct BikeComponent: Identifiable, Codable, Equatable {
    let id: UUID
    var bicycleId: UUID             // 所属自行车
    var name: String                // 用户自定义名称，例如 "原厂链条"
    var category: ComponentCategory

    // MARK: - Mileage & interval
    var installedMileageKm: Double  // 安装时的里程
    var serviceIntervalKm: Double?  // 建议检查间隔（km）
    var serviceIntervalDays: Int?   // 建议检查间隔（天）

    // MARK: - Service-level classification
    var technicalDifficulty: Int    // 1–5
    var needsSpecialTools: Bool
    var needsConsumables: Bool
    var estimatedMinutes: Int
    var isSafetyCritical: Bool

    init(
        id: UUID = UUID(),
        bicycleId: UUID,
        name: String,
        category: ComponentCategory,
        installedMileageKm: Double,
        serviceIntervalKm: Double? = nil,
        serviceIntervalDays: Int? = nil,
        technicalDifficulty: Int,
        needsSpecialTools: Bool,
        needsConsumables: Bool,
        estimatedMinutes: Int,
        isSafetyCritical: Bool
    ) {
        self.id = id
        self.bicycleId = bicycleId
        self.name = name
        self.category = category
        self.installedMileageKm = installedMileageKm
        self.serviceIntervalKm = serviceIntervalKm
        self.serviceIntervalDays = serviceIntervalDays
        self.technicalDifficulty = technicalDifficulty
        self.needsSpecialTools = needsSpecialTools
        self.needsConsumables = needsConsumables
        self.estimatedMinutes = estimatedMinutes
        self.isSafetyCritical = isSafetyCritical
    }
}