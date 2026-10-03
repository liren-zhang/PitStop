//
//  Bicycle.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation

/// The type of drivetrain on a bicycle.
enum DrivetrainType: String, Codable, CaseIterable {
    case mechanical   // 机械变速
    case electronic   // 电变（Di2 / AXS）
}

/// The type of braking system on a bicycle.
enum BrakeType: String, Codable, CaseIterable {
    case discHydraulic  // 油压碟刹
    case discMechanical // 机械碟刹
    case rim            // 圈刹
}

/// A bicycle owned by the user.
///
/// This is the root domain entity. Every component and every maintenance
/// task belongs to exactly one bicycle.
struct Bicycle: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String                // 例如 "通勤车" / "公路车"
    var brand: String               // 例如 "Giant"
    var drivetrainType: DrivetrainType
    var brakeType: BrakeType
    var currentMileageKm: Double    // 累计里程（公里）
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        drivetrainType: DrivetrainType,
        brakeType: BrakeType,
        currentMileageKm: Double = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.drivetrainType = drivetrainType
        self.brakeType = brakeType
        self.currentMileageKm = currentMileageKm
        self.createdAt = createdAt
    }
}