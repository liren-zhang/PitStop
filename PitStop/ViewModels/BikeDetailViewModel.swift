//
//  BikeDetailViewModel.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation
import Combine

/// A component paired with its current service status.
struct ComponentWithStatus: Identifiable {
    let id: UUID
    let component: BikeComponent
    let status: ServiceStatus

    init(component: BikeComponent, status: ServiceStatus) {
        self.id = component.id
        self.component = component
        self.status = status
    }
}

/// ViewModel for the bike detail screen.
@MainActor
final class BikeDetailViewModel: ObservableObject {

    // MARK: - Published state
    @Published var components: [ComponentWithStatus] = []
    @Published var tasks: [MaintenanceTask] = []
    @Published var errorMessage: String?

    // MARK: - Context
    var bicycle: Bicycle

    // MARK: - Dependencies
    private let repository: BikeRepository
    private let scheduleUseCase: ScheduleMaintenanceUseCase
    private let assessUseCase: AssessServiceOptionUseCase

    init(
        bicycle: Bicycle,
        repository: BikeRepository,
        scheduleUseCase: ScheduleMaintenanceUseCase = ScheduleMaintenanceUseCase(),
        assessUseCase: AssessServiceOptionUseCase = AssessServiceOptionUseCase()
    ) {
        self.bicycle = bicycle
        self.repository = repository
        self.scheduleUseCase = scheduleUseCase
        self.assessUseCase = assessUseCase
    }

    // MARK: - Loading

    func load() {
        errorMessage = nil
        do {
            let rawComponents = try repository.fetchComponents(forBicycle: bicycle.id)
            components = rawComponents.map { component in
                ComponentWithStatus(
                    component: component,
                    status: scheduleUseCase.status(for: component, on: bicycle)
                )
            }
            tasks = try repository.fetchTasks(forBicycle: bicycle.id)
                .filter { $0.completedDate == nil }
        } catch {
            errorMessage = "Unable to load this bike. Please try again."
        }
    }

    // MARK: - Mutations

    func addComponent(
        name: String,
        category: ComponentCategory,
        installedMileageKm: Double,
        serviceIntervalKm: Double?,
        serviceIntervalDays: Int?,
        technicalDifficulty: Int,
        needsSpecialTools: Bool,
        needsConsumables: Bool,
        estimatedMinutes: Int,
        isSafetyCritical: Bool
    ) {
        let component = BikeComponent(
            bicycleId: bicycle.id,
            name: name,
            category: category,
            installedMileageKm: installedMileageKm,
            serviceIntervalKm: serviceIntervalKm,
            serviceIntervalDays: serviceIntervalDays,
            technicalDifficulty: technicalDifficulty,
            needsSpecialTools: needsSpecialTools,
            needsConsumables: needsConsumables,
            estimatedMinutes: estimatedMinutes,
            isSafetyCritical: isSafetyCritical
        )
        do {
            try repository.addComponent(component)
            load()
        } catch {
            errorMessage = "Could not save the component. Please try again."
        }
    }

    func scheduleInspection(for component: BikeComponent) {
        do {
            if let task = try scheduleUseCase.execute(
                for: component,
                on: bicycle,
                existingTasks: tasks
            ) {
                try repository.addTask(task)
                load()
            }
        } catch let error as DomainError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not schedule the task. Please try again."
        }
    }

    func deleteComponent(_ component: BikeComponent) {
        do {
            try repository.deleteComponent(id: component.id)
            load()
        } catch {
            errorMessage = "Could not delete the component. Please try again."
        }
    }

    /// Add a completed ride to the bicycle's total mileage.
    func addRide(_ distanceKm: Double) {
        guard distanceKm > 0 else { return }
        let newTotal = bicycle.currentMileageKm + distanceKm
        do {
            try repository.updateMileage(forBicycle: bicycle.id, newMileageKm: newTotal)
            bicycle.currentMileageKm = newTotal
            load()
        } catch {
            errorMessage = "Could not record the ride. Please try again."
        }
    }

    /// Update the total mileage directly (used to correct mistakes).
    func updateMileage(_ newMileageKm: Double) {
        do {
            try repository.updateMileage(forBicycle: bicycle.id, newMileageKm: newMileageKm)
            bicycle.currentMileageKm = newMileageKm
            load()
        } catch {
            errorMessage = "Could not update the mileage. Please try again."
        }
    }

    /// Replace a component with a new one in a single step.
    func replaceComponent(
        _ oldComponent: BikeComponent,
        withName name: String,
        category: ComponentCategory,
        installedMileageKm: Double,
        serviceIntervalKm: Double?,
        serviceIntervalDays: Int?,
        technicalDifficulty: Int,
        needsSpecialTools: Bool,
        needsConsumables: Bool,
        estimatedMinutes: Int,
        isSafetyCritical: Bool
    ) {
        do {
            try repository.deleteComponent(id: oldComponent.id)

            let newComponent = BikeComponent(
                bicycleId: bicycle.id,
                name: name,
                category: category,
                installedMileageKm: bicycle.currentMileageKm,
                serviceIntervalKm: serviceIntervalKm,
                serviceIntervalDays: serviceIntervalDays,
                technicalDifficulty: technicalDifficulty,
                needsSpecialTools: needsSpecialTools,
                needsConsumables: needsConsumables,
                estimatedMinutes: estimatedMinutes,
                isSafetyCritical: isSafetyCritical
            )
            try repository.addComponent(newComponent)
            load()
        } catch {
            errorMessage = "Could not replace the component. Please try again."
        }
    }

    // MARK: - Derived data

    func serviceLevel(for component: BikeComponent) -> ServiceLevel? {
        try? assessUseCase.execute(component: component)
    }

    var dueCount: Int {
        components.filter {
            if case .ok = $0.status { return false }
            if case .upcoming = $0.status { return false }
            return true
        }.count
    }
}
