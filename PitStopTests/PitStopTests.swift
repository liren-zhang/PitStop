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

/// Build a bicycle with a known mileage.
private func makeBicycle(mileage: Double = 0) -> Bicycle {
    Bicycle(
        name: "Test Bike",
        brand: "Test",
        drivetrainType: .mechanical,
        brakeType: .discHydraulic,
        currentMileageKm: mileage
    )
}

/// Build a chain component for tests.
private func makeChain(
    installedKm: Double = 0,
    intervalKm: Double? = 2000,
    intervalDays: Int? = nil,
    installedDate: Date = Date()
) -> BikeComponent {
    BikeComponent(
        bicycleId: UUID(),
        name: "Chain",
        category: .chain,
        installedMileageKm: installedKm,
        installedDate: installedDate,
        serviceIntervalKm: intervalKm,
        serviceIntervalDays: intervalDays,
        technicalDifficulty: 2,
        needsSpecialTools: true,
        needsConsumables: true,
        estimatedMinutes: 30,
        isSafetyCritical: false
    )
}

// MARK: - LogInspectionUseCase tests

@MainActor
struct LogInspectionTests {

    let useCase = LogInspectionUseCase()

    /// A chain at 0.75% wear should be flagged as action needed.
    @Test func chainAtPointSevenFivePercent_returnsActionNeeded() throws {
        let chain = makeChain()
        let result = try useCase.execute(component: chain, measuredValue: 0.75)
        #expect(result == .actionNeeded)
    }

    /// A brake pad under 1 mm should be escalated to a shop.
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

    /// A chain wear value above 1.5% is not physically plausible.
    @Test func chainWearAboveMaximum_throwsValueOutOfRange() throws {
        let chain = makeChain()
        #expect(throws: DomainError.self) {
            _ = try useCase.execute(component: chain, measuredValue: 2.0)
        }
    }

    /// A green solid indicator (5) means the electronic battery is fine.
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

// MARK: - AssessServiceOptionUseCase tests

@MainActor
struct AssessServiceOptionTests {

    let useCase = AssessServiceOptionUseCase()

    /// Cleaning a chain should be classified as DIY Simple.
    @Test func cleanChain_returnsDiySimple() throws {
        let chain = BikeComponent(
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
        let level = try useCase.execute(component: chain)
        #expect(level == .diySimple)
    }

    /// Replacing a bottom bracket requires special tools and consumables
    /// most cyclists will not keep at home, so it is shop-recommended.
    @Test func bottomBracketReplacement_returnsShopRecommended() throws {
        let bb = BikeComponent(
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
        let level = try useCase.execute(component: bb)
        #expect(level == .shopRecommended)
    }

    /// A safety-critical task at difficulty 3 or above must be shop-required.
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
}

// MARK: - ScheduleMaintenanceUseCase tests

@MainActor
struct ScheduleMaintenanceTests {

    /// A chain that has not yet reached its interval should not produce a task.
    @Test func chainNotYetDue_returnsNilTask() throws {
        let bicycle = makeBicycle(mileage: 500)
        let chain = makeChain(installedKm: 0, intervalKm: 2000)
        let useCase = ScheduleMaintenanceUseCase()

        let task = try useCase.execute(
            for: chain,
            on: bicycle,
            existingTasks: []
        )
        #expect(task == nil)
    }

    /// A chain that has passed its interval should produce a task.
    @Test func chainDueByMileage_createsTask() throws {
        let bicycle = makeBicycle(mileage: 2500)
        let chain = makeChain(installedKm: 0, intervalKm: 2000)
        let useCase = ScheduleMaintenanceUseCase()

        let task = try useCase.execute(
            for: chain,
            on: bicycle,
            existingTasks: []
        )
        #expect(task != nil)
        #expect(task?.taskType == .inspection)
    }

    /// Scheduling twice for the same component should be rejected.
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
            _ = try useCase.execute(
                for: chain,
                on: bicycle,
                existingTasks: [existing]
            )
        }
    }
}