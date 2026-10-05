//
//  MockBikeRepository.swift
//  PitStopTests
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation
@testable import PitStop

/// In-memory implementation of `BikeRepository` used by unit tests.
///
/// Stores domain structs directly in arrays — no Core Data, no
/// `NSManagedObject`, no disk access. This lets the Use Case tests run
/// in milliseconds and stay completely isolated from the app's real
/// persistence stack.
///
/// The mock also records every call so a test can assert that the use
/// case invoked the repository the expected number of times.
final class MockBikeRepository: BikeRepository {

    // MARK: - Storage
    var bicycles: [Bicycle] = []
    var components: [BikeComponent] = []
    var inspections: [InspectionRecord] = []
    var tasks: [MaintenanceTask] = []

    // MARK: - Call tracking
    private(set) var addInspectionCallCount = 0
    private(set) var addTaskCallCount = 0

    // MARK: - Bicycles
    func fetchAllBicycles() throws -> [Bicycle] { bicycles }

    func addBicycle(_ bicycle: Bicycle) throws { bicycles.append(bicycle) }

    func updateBicycle(_ bicycle: Bicycle) throws {
        if let i = bicycles.firstIndex(where: { $0.id == bicycle.id }) {
            bicycles[i] = bicycle
        }
    }

    func deleteBicycle(id: UUID) throws {
        bicycles.removeAll { $0.id == id }
        components.removeAll { $0.bicycleId == id }
        tasks.removeAll { $0.bicycleId == id }
    }

    func updateMileage(forBicycle id: UUID, newMileageKm: Double) throws {
        if let i = bicycles.firstIndex(where: { $0.id == id }) {
            bicycles[i].currentMileageKm = newMileageKm
        }
    }

    // MARK: - Components
    func fetchComponents(forBicycle bicycleId: UUID) throws -> [BikeComponent] {
        components.filter { $0.bicycleId == bicycleId }
    }

    func addComponent(_ component: BikeComponent) throws {
        components.append(component)
    }

    func updateComponent(_ component: BikeComponent) throws {
        if let i = components.firstIndex(where: { $0.id == component.id }) {
            components[i] = component
        }
    }

    func deleteComponent(id: UUID) throws {
        components.removeAll { $0.id == id }
    }

    // MARK: - Inspections
    func fetchInspections(forComponent componentId: UUID) throws -> [InspectionRecord] {
        inspections.filter { $0.componentId == componentId }
    }

    func addInspection(_ record: InspectionRecord) throws {
        inspections.append(record)
        addInspectionCallCount += 1
    }

    // MARK: - Tasks
    func fetchTasks(forBicycle bicycleId: UUID) throws -> [MaintenanceTask] {
        tasks.filter { $0.bicycleId == bicycleId }
    }

    func addTask(_ task: MaintenanceTask) throws {
        tasks.append(task)
        addTaskCallCount += 1
    }

    func updateTask(_ task: MaintenanceTask) throws {
        if let i = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[i] = task
        }
    }

    func deleteTask(id: UUID) throws {
        tasks.removeAll { $0.id == id }
    }
}