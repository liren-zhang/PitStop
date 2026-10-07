//
//  PitStopTests.swift
//  PitStopTests
//
//  Created by Liren Zhang on 2/10/2026.
//

import Testing
import Foundation
@testable import PitStop

// MARK: - Test helpers

private func makeBicycle(
    mileage: Double = 0,
    drivetrain: DrivetrainType = .mechanical,
    brake: BrakeType = .discHydraulic
) -> Bicycle {
    Bicycle(
        name: "Test Bike",
        brand: "Test",
        drivetrainType: drivetrain,
        brakeType: brake,
        currentMileageKm: mileage
    )
}

private func makeChain(
    installedKm: Double = 0,
    intervalKm: Double? = 2000,
    intervalDays: Int? = nil,
    installedDate: Date = Date(),
    difficulty: Int = 2,
    needsTools: Bool = true,
    needsConsumables: Bool = true,
    minutes: Int = 30,
    safetyCritical: Bool = false
) -> BikeComponent {
    BikeComponent(
        bicycleId: UUID(),
        name: "Chain",
        category: .chain,
        installedMileageKm: installedKm,
        installedDate: installedDate,
        serviceIntervalKm: intervalKm,
        serviceIntervalDays: intervalDays,
        technicalDifficulty: difficulty,
        needsSpecialTools: needsTools,
        needsConsumables: needsConsumables,
        estimatedMinutes: minutes,
        isSafetyCritical: safetyCritical
    )
}

// MARK: - LogInspectionUseCase tests

@MainActor
struct LogInspectionTests {

    let useCase = LogInspectionUseCase()

    @Test func chainAtPointSevenFivePercent_returnsActionNeeded() throws {
        let result = try useCase.execute(component: makeChain(), measuredValue: 0.75)
        #expect(result == .actionNeeded)
    }

    @Test func chainFullyWorn_returnsProfessional() throws {
        let result = try useCase.execute(component: makeChain(), measuredValue: 1.0)
        #expect(result == .professional)
    }

    @Test func chainWearAboveMaximum_throwsValueOutOfRange() throws {
        #expect(throws: DomainError.self) {
            _ = try useCase.execute(component: makeChain(), measuredValue: 2.0)
        }
    }

    @Test func brakePadUnderOneMillimetre_returnsProfessional() throws {
        let pad = BikeComponent(
            bicycleId: UUID(),
            name: "Rear Pad",
            category: .brakePad,
            installedMileageKm: 0,
            technicalDifficulty: 2,
            needsSpecialTools: true,
            needsConsumables: true,
            estimatedMinutes: 20,
            isSafetyCritical: true
        )
        let result = try useCase.execute(component: pad, measuredValue: 0.5)
        #expect(result == .professional)
    }

    @Test func batteryGreenSolid_returnsPass() throws {
        let battery = BikeComponent(
            bicycleId: UUID(),
            name: "Groupset Battery",
            category: .battery,
            installedMileageKm: 0,
            technicalDifficulty: 1,
            needsSpecialTools: false,
            needsConsumables: false,
            estimatedMinutes: 5,
            isSafetyCritical: false
        )
        let result = try useCase.execute(component: battery, measuredValue: 5)
        #expect(result == .pass)
    }
}

// MARK: - Interval reset tests

@MainActor
struct IntervalResetTests {

    let useCase = LogInspectionUseCase()

    @Test func passResetsInterval() {
        let bicycle = makeBicycle(mileage: 2500)
        let component = makeChain(installedKm: 0)
        let updated = useCase.updatedComponentAfterInspection(
            component, bicycle: bicycle, result: .pass
        )
        #expect(updated.installedMileageKm == 2500)
    }

    @Test func observeResetsInterval() {
        let bicycle = makeBicycle(mileage: 2500)
        let component = makeChain(installedKm: 0)
        let updated = useCase.updatedComponentAfterInspection(
            component, bicycle: bicycle, result: .observe
        )
        #expect(updated.installedMileageKm == 2500)
    }

    @Test func actionNeededResetsInterval() {
        let bicycle = makeBicycle(mileage: 2500)
        let component = makeChain(installedKm: 0)
        let updated = useCase.updatedComponentAfterInspection(
            component, bicycle: bicycle, result: .actionNeeded
        )
        #expect(updated.installedMileageKm == 2500)
    }

    @Test func professionalDoesNotResetInterval() {
        let bicycle = makeBicycle(mileage: 2500)
        let component = makeChain(installedKm: 0)
        let updated = useCase.updatedComponentAfterInspection(
            component, bicycle: bicycle, result: .professional
        )
        // The original installedMileageKm should be preserved.
        #expect(updated.installedMileageKm == 0)
    }
}

// MARK: - AssessServiceOptionUseCase tests

@MainActor
struct AssessServiceOptionTests {

    let useCase = AssessServiceOptionUseCase()

    @Test func easyJobWithoutMissingTools_returnsDiySimple() throws {
        let component = BikeComponent(
            bicycleId: UUID(),
            name: "Chain Clean",
            category: .chain,
            installedMileageKm: 0,
            technicalDifficulty: 1,
            needsSpecialTools: false,
            needsConsumables: false,
            estimatedMinutes: 15,
            isSafetyCritical: false
        )
        let level = try useCase.execute(component: component)
        #expect(level == .diySimple)
    }

    @Test func missingTools_returnsShopRecommended() throws {
        let component = BikeComponent(
            bicycleId: UUID(),
            name: "Bottom Bracket",
            category: .bottomBracket,
            installedMileageKm: 0,
            technicalDifficulty: 3,
            needsSpecialTools: true,
            needsConsumables: true,
            estimatedMinutes: 60,
            isSafetyCritical: false
        )
        let level = try useCase.execute(component: component)
        #expect(level == .shopRecommended)
    }

    @Test func notCapable_returnsShopRequired() throws {
        let component = BikeComponent(
            bicycleId: UUID(),
            name: "Wheel Truing",
            category: .other,
            installedMileageKm: 0,
            technicalDifficulty: 5,
            needsSpecialTools: false,
            needsConsumables: false,
            estimatedMinutes: 30,
            isSafetyCritical: false
        )
        let level = try useCase.execute(component: component)
        #expect(level == .shopRequired)
    }

    @Test func safetyCriticalDifficultyThree_returnsShopRequired() throws {
        let rotor = BikeComponent(
            bicycleId: UUID(),
            name: "Rotor",
            category: .brakeRotor,
            installedMileageKm: 0,
            technicalDifficulty: 3,
            needsSpecialTools: true,
            needsConsumables: true,
            estimatedMinutes: 45,
            isSafetyCritical: true
        )
        let level = try useCase.execute(component: rotor)
        #expect(level == .shopRequired)
    }

    @Test func invalidDifficulty_throwsIncompleteData() throws {
        let component = BikeComponent(
            bicycleId: UUID(),
            name: "Broken",
            category: .other,
            installedMileageKm: 0,
            technicalDifficulty: 0,
            needsSpecialTools: false,
            needsConsumables: false,
            estimatedMinutes: 10,
            isSafetyCritical: false
        )
        #expect(throws: DomainError.self) {
            _ = try useCase.execute(component: component)
        }
    }
}

// MARK: - ComponentCategory tests

@MainActor
struct ComponentCategoryTests {

    @Test func gearCableHiddenOnElectronicDrivetrain() {
        let bike = makeBicycle(drivetrain: .electronic)
        #expect(ComponentCategory.gearCable.isAvailable(for: bike) == false)
    }

    @Test func gearCableShownOnMechanicalDrivetrain() {
        let bike = makeBicycle(drivetrain: .mechanical)
        #expect(ComponentCategory.gearCable.isAvailable(for: bike) == true)
    }

    @Test func rotorHiddenOnRimBrake() {
        let bike = makeBicycle(brake: .rim)
        #expect(ComponentCategory.brakeRotor.isAvailable(for: bike) == false)
    }

    @Test func rotorShownOnDiscBrake() {
        let bike = makeBicycle(brake: .discHydraulic)
        #expect(ComponentCategory.brakeRotor.isAvailable(for: bike) == true)
    }

    @Test func brakePadIsMeasurementOnDiscBrake() {
        let bike = makeBicycle(brake: .discHydraulic)
        #expect(ComponentCategory.brakePad.inspectionMethod(for: bike) == .measurement)
    }

    @Test func brakePadIsVisualOnRimBrake() {
        let bike = makeBicycle(brake: .rim)
        #expect(ComponentCategory.brakePad.inspectionMethod(for: bike) == .visual)
    }

    @Test func chainIsAlwaysMeasurement() {
        let bike = makeBicycle()
        #expect(ComponentCategory.chain.inspectionMethod(for: bike) == .measurement)
    }

    @Test func tyreIsAlwaysVisual() {
        let bike = makeBicycle()
        #expect(ComponentCategory.tyre.inspectionMethod(for: bike) == .visual)
    }
}

// MARK: - ScheduleMaintenanceUseCase tests

@MainActor
struct ScheduleMaintenanceTests {

    @Test func chainNotYetDue_returnsNilTask() throws {
        let bicycle = makeBicycle(mileage: 500)
        let chain = makeChain(installedKm: 0, intervalKm: 2000)
        let useCase = ScheduleMaintenanceUseCase()

        let task = try useCase.execute(for: chain, on: bicycle, existingTasks: [])
        #expect(task == nil)
    }

    @Test func chainDueByMileage_createsTask() throws {
        let bicycle = makeBicycle(mileage: 2500)
        let chain = makeChain(installedKm: 0, intervalKm: 2000)
        let useCase = ScheduleMaintenanceUseCase()

        let task = try useCase.execute(for: chain, on: bicycle, existingTasks: [])
        #expect(task != nil)
        #expect(task?.taskType == .inspection)
    }

    @Test func duplicateTask_throwsDuplicateError() throws {
        let bicycle = makeBicycle(mileage: 2500)
        let chain = makeChain(installedKm: 0, intervalKm: 2000)
        let useCase = ScheduleMaintenanceUseCase()

        let existing = MaintenanceTask(
            bicycleId: bicycle.id,
            componentId: chain.id,
            title: "Chain inspection",
            taskType: .inspection,
            serviceLevel: .diyWithTools,
            dueDate: Date()
        )

        #expect(throws: DomainError.self) {
            _ = try useCase.execute(for: chain, on: bicycle, existingTasks: [existing])
        }
    }
}

// MARK: - Action text tests

@MainActor
struct ActionTextTests {

    @Test func actionNeededWithShop_returnsShopWhenConvenient() {
        #expect(InspectionResult.actionNeeded.actionText(needsShop: true)
                == "Shop when convenient")
    }

    @Test func actionNeededWithoutShop_returnsReplaceWhenConvenient() {
        #expect(InspectionResult.actionNeeded.actionText(needsShop: false)
                == "Replace when convenient")
    }

    @Test func professionalWithShop_returnsVisitShopNow() {
        #expect(InspectionResult.professional.actionText(needsShop: true)
                == "Visit shop now")
    }

    @Test func professionalWithoutShop_returnsReplaceNow() {
        #expect(InspectionResult.professional.actionText(needsShop: false)
                == "Replace now")
    }
}
