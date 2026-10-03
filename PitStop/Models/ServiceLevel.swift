//
//  ServiceLevel.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation
import SwiftUI

/// The four service levels used to classify every maintenance task.
///
/// The classification reflects how most cyclists actually decide where to
/// get work done: not only technical difficulty, but also tool cost,
/// consumable cost, time required, and whether multiple tasks are combined.
///
/// - `diySimple`: The cyclist can do it in under 15 minutes with no tools.
/// - `diyWithTools`: Requires basic tools (chain tool, tyre levers, etc.).
/// - `shopRecommended`: Possible to DIY, but most cyclists prefer a shop
///   because of expensive tools, unused consumables, or time cost.
/// - `shopRequired`: Beyond typical home capability (wheel truing, hub
///   bearing replacement).
enum ServiceLevel: String, Codable, CaseIterable, Identifiable {
    case diySimple
    case diyWithTools
    case shopRecommended
    case shopRequired

    var id: String { rawValue }

    /// 显示名称（给用户看）
    var displayName: String {
        switch self {
        case .diySimple:        return "DIY Simple"
        case .diyWithTools:     return "DIY with Tools"
        case .shopRecommended:  return "Shop Recommended"
        case .shopRequired:     return "Shop Required"
        }
    }

    /// 简短描述（UI 提示用）
    var shortDescription: String {
        switch self {
        case .diySimple:
            return "Quick check or clean — no special tools"
        case .diyWithTools:
            return "Doable at home with basic bike tools"
        case .shopRecommended:
            return "Possible to DIY, but a shop saves time and hassle"
        case .shopRequired:
            return "Best handled by a professional mechanic"
        }
    }

    /// 颜色标识（🟢🔵🟡🔴）
    var color: Color {
        switch self {
        case .diySimple:        return .green
        case .diyWithTools:     return .blue
        case .shopRecommended:  return .orange
        case .shopRequired:     return .red
        }
    }

    /// SF Symbol 图标
    var iconName: String {
        switch self {
        case .diySimple:        return "checkmark.circle.fill"
        case .diyWithTools:     return "wrench.and.screwdriver.fill"
        case .shopRecommended:  return "exclamationmark.triangle.fill"
        case .shopRequired:     return "building.2.fill"
        }
    }
}