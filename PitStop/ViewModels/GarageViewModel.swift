//
//  GarageViewModel.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation
import Combine

/// ViewModel for the garage screen (the app's home screen).
///
/// Owns the list of bicycles and, for each bike, the count of tasks that
/// are due. This lets the garage show at a glance which bike needs
/// attention today.
@MainActor
final class GarageViewModel: ObservableObject {

    // MARK: - Published state
    @Published var bicycles: [Bicycle] = []
    @Published var dueTaskCounts: [UUID: Int] = [:]   // 每辆车的待办数量
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let repository: BikeRepository
    private let scheduleUseCase: ScheduleMaintenanceUseCase

    init(
        repository: BikeRepository,
        scheduleUseCase: ScheduleMaintenanceUseCase = ScheduleMaintenanceUseCase()
    ) {
        self.repository = repository
        self.scheduleUseCase = scheduleUseCase
    }

    // MARK: - Loading

    /// Load all bicycles and compute the number of due tasks for each.
    func load() {
        errorMessage = nil
        do {
            let bikes = try repository.fetchAllBicycles()
            bicycles = bikes
            var counts: [UUID: Int] = [:]
            for bike in bikes {
                let components = try repository.fetchComponents(forBicycle: bike.id)
                let dueCount = components.filter {
                    scheduleUseCase.isDue(component: $0, on: bike)
                }.count
                counts[bike.id] = dueCount
            }
            dueTaskCounts = counts
        } catch {
            errorMessage = "Unable to load your garage. Please try again."
        }
    }

    // MARK: - Mutations

    /// Add a new bicycle.
    func addBicycle(
        name: String,
        brand: String,
        drivetrainType: DrivetrainType,
        brakeType: BrakeType,
        currentMileageKm: Double
    ) {
        let bicycle = Bicycle(
            name: name,
            brand: brand,
            drivetrainType: drivetrainType,
            brakeType: brakeType,
            currentMileageKm: currentMileageKm
        )
        do {
            try repository.addBicycle(bicycle)
            load()
        } catch {
            errorMessage = "Could not save the new bicycle. Please try again."
        }
    }

    /// Update the mileage for a bicycle and refresh the due counts.
    func updateMileage(for bicycle: Bicycle, newMileageKm: Double) {
        do {
            try repository.updateMileage(forBicycle: bicycle.id, newMileageKm: newMileageKm)
            load()
        } catch {
            errorMessage = "Could not update the mileage. Please try again."
        }
    }

    /// Delete a bicycle and everything attached to it.
    func deleteBicycle(_ bicycle: Bicycle) {
        do {
            try repository.deleteBicycle(id: bicycle.id)
            load()
        } catch {
            errorMessage = "Could not delete the bicycle. Please try again."
        }
    }

    /// Number of due tasks for a specific bike.
    func dueCount(for bicycle: Bicycle) -> Int {
        dueTaskCounts[bicycle.id] ?? 0
    }
}