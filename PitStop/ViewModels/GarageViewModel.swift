//
//  GarageViewModel.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation
import Combine

/// ViewModel for the garage screen (the app's home screen).
@MainActor
final class GarageViewModel: ObservableObject {

    // MARK: - Published state
    @Published var bicycles: [Bicycle] = []
    @Published var dueTaskCounts: [UUID: Int] = [:]
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let repository: BikeRepository
    private let scheduleUseCase: ScheduleMaintenanceUseCase
    private let assessUseCase: AssessServiceOptionUseCase

    init(
        repository: BikeRepository,
        scheduleUseCase: ScheduleMaintenanceUseCase = ScheduleMaintenanceUseCase(),
        assessUseCase: AssessServiceOptionUseCase = AssessServiceOptionUseCase()
    ) {
        self.repository = repository
        self.scheduleUseCase = scheduleUseCase
        self.assessUseCase = assessUseCase
    }

    // MARK: - Loading

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

            // Publish the current state so the widget can read it.
            publishWidgetSnapshot(for: bikes)

        } catch {
            errorMessage = "Unable to load your garage. Please try again."
        }
    }

    // MARK: - Mutations

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

    func updateMileage(for bicycle: Bicycle, newMileageKm: Double) {
        do {
            try repository.updateMileage(forBicycle: bicycle.id, newMileageKm: newMileageKm)
            load()
        } catch {
            errorMessage = "Could not update the mileage. Please try again."
        }
    }

    func deleteBicycle(_ bicycle: Bicycle) {
        do {
            try repository.deleteBicycle(id: bicycle.id)
            load()
        } catch {
            errorMessage = "Could not delete the bicycle. Please try again."
        }
    }

    func dueCount(for bicycle: Bicycle) -> Int {
        dueTaskCounts[bicycle.id] ?? 0
    }

    // MARK: - Widget snapshot

    /// Build a lightweight snapshot of the current state and write it
    /// into the App Group container. Called every time `load()` finishes,
    /// so the widget always reflects the latest data.
    private func publishWidgetSnapshot(for bikes: [Bicycle]) {
        var snapshots: [SharedDataManager.BicycleSnapshot] = []

        for bike in bikes {
            let components = (try? repository.fetchComponents(forBicycle: bike.id)) ?? []

            // Components that are due or overdue.
            let dueComponents = components.filter {
                scheduleUseCase.isDue(component: $0, on: bike)
            }

            // Most urgent service level among the due components.
            var mostUrgent: ServiceLevel?
            for c in dueComponents {
                if let level = try? assessUseCase.execute(component: c) {
                    if mostUrgent == nil || level.priority > mostUrgent!.priority {
                        mostUrgent = level
                    }
                }
            }

            snapshots.append(SharedDataManager.BicycleSnapshot(
                id: bike.id,
                name: bike.name,
                dueCount: dueComponents.count,
                nextTaskTitle: dueComponents.first?.name,
                nextTaskDue: Date(),
                mostUrgentLevel: mostUrgent
            ))
        }

        SharedDataManager().writeSnapshot(snapshots)
    }
}