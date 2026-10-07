//
//  CoreDataBikeRepository.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation
import CoreData

/// Core Data implementation of `BikeRepository`.
final class CoreDataBikeRepository: BikeRepository {

    private let container: NSPersistentContainer
    private var context: NSManagedObjectContext { container.viewContext }

    init(container: NSPersistentContainer) {
        self.container = container
    }

    // MARK: - Bicycles

    func fetchAllBicycles() throws -> [Bicycle] {
        let request = NSFetchRequest<CDBicycle>(entityName: "CDBicycle")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return try context.fetch(request).map(Self.toDomain)
    }

    func addBicycle(_ bicycle: Bicycle) throws {
        let entity = CDBicycle(context: context)
        Self.apply(bicycle, to: entity)
        try saveIfNeeded()
    }

    func updateBicycle(_ bicycle: Bicycle) throws {
        guard let entity = try findBicycle(id: bicycle.id) else { return }
        Self.apply(bicycle, to: entity)
        try saveIfNeeded()
    }

    func deleteBicycle(id: UUID) throws {
        guard let entity = try findBicycle(id: id) else { return }
        context.delete(entity)
        try saveIfNeeded()
    }

    func updateMileage(forBicycle id: UUID, newMileageKm: Double) throws {
        guard let entity = try findBicycle(id: id) else { return }
        entity.currentMileageKm = newMileageKm
        try saveIfNeeded()
    }

    // MARK: - Components

    func fetchComponents(forBicycle bicycleId: UUID) throws -> [BikeComponent] {
        let request = NSFetchRequest<CDBikeComponent>(entityName: "CDBikeComponent")
        request.predicate = NSPredicate(format: "bicycleId == %@", bicycleId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return try context.fetch(request).map(Self.toDomain)
    }

    func addComponent(_ component: BikeComponent) throws {
        let entity = CDBikeComponent(context: context)
        Self.apply(component, to: entity)
        try saveIfNeeded()
    }

    func updateComponent(_ component: BikeComponent) throws {
        guard let entity = try findComponent(id: component.id) else { return }
        Self.apply(component, to: entity)
        try saveIfNeeded()
    }

    func deleteComponent(id: UUID) throws {
        guard let entity = try findComponent(id: id) else { return }
        context.delete(entity)
        try saveIfNeeded()
    }

    // MARK: - Inspections

    func fetchInspections(forComponent componentId: UUID) throws -> [InspectionRecord] {
        let request = NSFetchRequest<CDInspectionRecord>(entityName: "CDInspectionRecord")
        request.predicate = NSPredicate(format: "componentId == %@", componentId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return try context.fetch(request).map(Self.toDomain)
    }

    func addInspection(_ record: InspectionRecord) throws {
        let entity = CDInspectionRecord(context: context)
        Self.apply(record, to: entity)
        try saveIfNeeded()
    }

    // MARK: - Maintenance tasks

    func fetchTasks(forBicycle bicycleId: UUID) throws -> [MaintenanceTask] {
        let request = NSFetchRequest<CDMaintenanceTask>(entityName: "CDMaintenanceTask")
        request.predicate = NSPredicate(format: "bicycleId == %@", bicycleId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
        return try context.fetch(request).map(Self.toDomain)
    }

    func addTask(_ task: MaintenanceTask) throws {
        let entity = CDMaintenanceTask(context: context)
        Self.apply(task, to: entity)
        try saveIfNeeded()
    }

    func updateTask(_ task: MaintenanceTask) throws {
        guard let entity = try findTask(id: task.id) else { return }
        Self.apply(task, to: entity)
        try saveIfNeeded()
    }

    func deleteTask(id: UUID) throws {
        guard let entity = try findTask(id: id) else { return }
        context.delete(entity)
        try saveIfNeeded()
    }

    // MARK: - Private helpers

    private func saveIfNeeded() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    private func findBicycle(id: UUID) throws -> CDBicycle? {
        let request = NSFetchRequest<CDBicycle>(entityName: "CDBicycle")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func findComponent(id: UUID) throws -> CDBikeComponent? {
        let request = NSFetchRequest<CDBikeComponent>(entityName: "CDBikeComponent")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func findTask(id: UUID) throws -> CDMaintenanceTask? {
        let request = NSFetchRequest<CDMaintenanceTask>(entityName: "CDMaintenanceTask")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}

// MARK: - Domain ↔ Entity mapping

private extension CoreDataBikeRepository {

    // MARK: Bicycle
    static func toDomain(_ e: CDBicycle) -> Bicycle {
        Bicycle(
            id: e.id ?? UUID(),
            name: e.name ?? "",
            brand: e.brand ?? "",
            drivetrainType: DrivetrainType(rawValue: e.drivetrainType ?? "") ?? .mechanical,
            brakeType: BrakeType(rawValue: e.brakeType ?? "") ?? .rim,
            currentMileageKm: e.currentMileageKm,
            createdAt: e.createdAt ?? Date()
        )
    }

    static func apply(_ d: Bicycle, to e: CDBicycle) {
        e.id = d.id
        e.name = d.name
        e.brand = d.brand
        e.drivetrainType = d.drivetrainType.rawValue
        e.brakeType = d.brakeType.rawValue
        e.currentMileageKm = d.currentMileageKm
        e.createdAt = d.createdAt
    }

    // MARK: BikeComponent
    static func toDomain(_ e: CDBikeComponent) -> BikeComponent {
        BikeComponent(
            id: e.id ?? UUID(),
            bicycleId: e.bicycleId ?? UUID(),
            name: e.name ?? "",
            category: ComponentCategory(rawValue: e.category ?? "") ?? .other,
            installedMileageKm: e.installedMileageKm,
            installedDate: e.installedDate ?? Date(),
            serviceIntervalKm: e.serviceIntervalKm == 0 ? nil : e.serviceIntervalKm,
            serviceIntervalDays: e.serviceIntervalDays == 0 ? nil : Int(e.serviceIntervalDays),
            advanceNoticeKm: e.advanceNoticeKm == 0 ? 100 : e.advanceNoticeKm,
            advanceNoticeDays: e.advanceNoticeDays == 0 ? 7 : Int(e.advanceNoticeDays),
            technicalDifficulty: Int(e.technicalDifficulty),
            needsSpecialTools: e.needsSpecialTools,
            needsConsumables: e.needsConsumables,
            estimatedMinutes: Int(e.estimatedMinutes),
            isSafetyCritical: e.isSafetyCritical
        )
    }

    static func apply(_ d: BikeComponent, to e: CDBikeComponent) {
        e.id = d.id
        e.bicycleId = d.bicycleId
        e.name = d.name
        e.category = d.category.rawValue
        e.installedMileageKm = d.installedMileageKm
        e.installedDate = d.installedDate
        e.serviceIntervalKm = d.serviceIntervalKm ?? 0
        e.serviceIntervalDays = Int32(d.serviceIntervalDays ?? 0)
        e.advanceNoticeKm = d.advanceNoticeKm
        e.advanceNoticeDays = Int32(d.advanceNoticeDays)
        e.technicalDifficulty = Int16(d.technicalDifficulty)
        e.needsSpecialTools = d.needsSpecialTools
        e.needsConsumables = d.needsConsumables
        e.estimatedMinutes = Int16(d.estimatedMinutes)
        e.isSafetyCritical = d.isSafetyCritical
    }

    // MARK: InspectionRecord
    static func toDomain(_ e: CDInspectionRecord) -> InspectionRecord {
        InspectionRecord(
            id: e.id ?? UUID(),
            componentId: e.componentId ?? UUID(),
            date: e.date ?? Date(),
            recordedValue: e.recordedValue == 0 ? nil : e.recordedValue,
            result: InspectionResult(rawValue: e.result ?? "") ?? .pass,
            notes: e.notes ?? ""
        )
    }

    static func apply(_ d: InspectionRecord, to e: CDInspectionRecord) {
        e.id = d.id
        e.componentId = d.componentId
        e.date = d.date
        e.recordedValue = d.recordedValue ?? 0
        e.result = d.result.rawValue
        e.notes = d.notes
    }

    // MARK: MaintenanceTask
    static func toDomain(_ e: CDMaintenanceTask) -> MaintenanceTask {
        MaintenanceTask(
            id: e.id ?? UUID(),
            bicycleId: e.bicycleId ?? UUID(),
            componentId: e.componentId,
            title: e.title ?? "",
            taskType: MaintenanceTaskType(rawValue: e.taskType ?? "") ?? .inspection,
            serviceLevel: ServiceLevel(rawValue: e.serviceLevel ?? "") ?? .diySimple,
            isMultiTask: e.isMultiTask,
            dueDate: e.dueDate ?? Date(),
            completedDate: e.completedDate
        )
    }

    static func apply(_ d: MaintenanceTask, to e: CDMaintenanceTask) {
        e.id = d.id
        e.bicycleId = d.bicycleId
        e.componentId = d.componentId
        e.title = d.title
        e.taskType = d.taskType.rawValue
        e.serviceLevel = d.serviceLevel.rawValue
        e.isMultiTask = d.isMultiTask
        e.dueDate = d.dueDate
        e.completedDate = d.completedDate
    }
}
