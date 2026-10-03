//
//  MaintenanceTask.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation

/// The type of a maintenance task.
enum MaintenanceTaskType: String, Codable {
    case inspection       // 检查（例如链条拉伸检查）
    case service          // 保养（例如链条清洁补油）
    case replacement      // 更换（例如换链条）
}

/// A scheduled maintenance task for a bicycle.
///
/// Tasks can be tied to a specific component or apply to the whole bike
/// (for example, a full "big service" combining several operations).
struct MaintenanceTask: Identifiable, Codable, Equatable {
    let id: UUID
    var bicycleId: UUID
    var componentId: UUID?           // nil 表示整车任务
    var title: String                // 例如 "传动清洁补油"
    var taskType: MaintenanceTaskType
    var serviceLevel: ServiceLevel   // 预计算的服务等级
    var isMultiTask: Bool            // 是否为多任务合并（如大保养）
    var dueDate: Date
    var completedDate: Date?

    init(
        id: UUID = UUID(),
        bicycleId: UUID,
        componentId: UUID? = nil,
        title: String,
        taskType: MaintenanceTaskType,
        serviceLevel: ServiceLevel,
        isMultiTask: Bool = false,
        dueDate: Date,
        completedDate: Date? = nil
    ) {
        self.id = id
        self.bicycleId = bicycleId
        self.componentId = componentId
        self.title = title
        self.taskType = taskType
        self.serviceLevel = serviceLevel
        self.isMultiTask = isMultiTask
        self.dueDate = dueDate
        self.completedDate = completedDate
    }

    /// 是否已过期
    var isOverdue: Bool {
        completedDate == nil && dueDate < Date()
    }
}