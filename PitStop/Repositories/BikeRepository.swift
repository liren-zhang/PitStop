//
//  BikeRepository.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation

/// Abstraction over PitStop's data storage.
///
/// Every part of the app that needs bicycle data — ViewModels, Use Cases,
/// unit tests — talks to this protocol. The concrete implementation
/// (Core Data, or a mock in tests) is injected at construction time.
///
/// This lets the use case layer be tested without starting a real Core
/// Data stack, which is a requirement of this assessment.
protocol BikeRepository {

    // MARK: - Bicycles
    func fetchAllBicycles() throws -> [Bicycle]
    func addBicycle(_ bicycle: Bicycle) throws
    func updateBicycle(_ bicycle: Bicycle) throws
    func deleteBicycle(id: UUID) throws
    func updateMileage(forBicycle id: UUID, newMileageKm: Double) throws

    // MARK: - Components
    func fetchComponents(forBicycle bicycleId: UUID) throws -> [BikeComponent]
    func addComponent(_ component: BikeComponent) throws
    func updateComponent(_ component: BikeComponent) throws
    func deleteComponent(id: UUID) throws

    // MARK: - Inspections
    func fetchInspections(forComponent componentId: UUID) throws -> [InspectionRecord]
    func addInspection(_ record: InspectionRecord) throws

    // MARK: - Maintenance tasks
    func fetchTasks(forBicycle bicycleId: UUID) throws -> [MaintenanceTask]
    func addTask(_ task: MaintenanceTask) throws
    func updateTask(_ task: MaintenanceTask) throws
    func deleteTask(id: UUID) throws
}