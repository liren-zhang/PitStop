//
//  InspectionViewModel.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation
import Combine

/// ViewModel for the log-inspection screen.
///
/// Supports two inspection modes, decided by the component's category
/// and the bicycle's configuration:
///
/// - **Objective measurement** — the user enters a value (chain wear,
///   pad thickness, rotor thickness, battery indicator), and
///   `LogInspectionUseCase` decides the result.
/// - **Subjective check** — the user picks the result directly
///   (pass / observe / actionNeeded / professional).
///
/// After a successful save, the component's service interval is reset
/// unless the result was `professional` (see `InspectionResult.resetsInterval`).
@MainActor
final class InspectionViewModel: ObservableObject {

    // MARK: - Published state
    @Published var recordedValueText: String = ""
    @Published var notes: String = ""
    @Published var previewResult: InspectionResult?
    @Published var selectedResult: InspectionResult = .pass
    @Published var history: [InspectionRecord] = []
    @Published var errorMessage: String?

    // MARK: - Context
    let component: BikeComponent
    let bicycle: Bicycle

    // MARK: - Dependencies
    private let repository: BikeRepository
    private let logUseCase: LogInspectionUseCase

    init(
        component: BikeComponent,
        bicycle: Bicycle,
        repository: BikeRepository,
        logUseCase: LogInspectionUseCase = LogInspectionUseCase()
    ) {
        self.component = component
        self.bicycle = bicycle
        self.repository = repository
        self.logUseCase = logUseCase
    }

    // MARK: - Mode

    /// How this component should be inspected on this bicycle.
    var inspectionMethod: InspectionMethod {
        component.category.inspectionMethod(for: bicycle)
    }

    var isMeasurementMode: Bool {
        inspectionMethod == .measurement
    }

    // MARK: - Loading

    func loadHistory() {
        do {
            history = try repository.fetchInspections(forComponent: component.id)
        } catch {
            errorMessage = "Unable to load inspection history."
        }
    }

    // MARK: - Live preview (measurement mode only)

    func updatePreview() {
        guard isMeasurementMode else { return }
        errorMessage = nil
        let value = Double(recordedValueText)
        do {
            previewResult = try logUseCase.execute(
                component: component,
                measuredValue: value
            )
        } catch let error as DomainError {
            previewResult = nil
            errorMessage = error.errorDescription
        } catch {
            previewResult = nil
            errorMessage = "Could not evaluate the reading."
        }
    }

    // MARK: - Saving

    /// Persist the inspection record and, if the result allows it,
    /// reset the component's service interval.
    /// - Returns: `true` on success, `false` if the input was invalid.
    func save() -> Bool {
        do {
            let result: InspectionResult
            let value: Double?

            if isMeasurementMode {
                let typedValue = Double(recordedValueText)
                result = try logUseCase.execute(
                    component: component,
                    measuredValue: typedValue
                )
                value = typedValue
            } else {
                result = selectedResult
                value = nil
            }

            let record = InspectionRecord(
                componentId: component.id,
                recordedValue: value,
                result: result,
                notes: notes
            )
            try repository.addInspection(record)

            // Reset the interval if the result allows it.
            let updated = logUseCase.updatedComponentAfterInspection(
                component,
                bicycle: bicycle,
                result: result
            )
            try repository.updateComponent(updated)

            loadHistory()
            return true
        } catch let error as DomainError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = "Could not save the inspection. Please try again."
            return false
        }
    }

    func resetForm() {
        recordedValueText = ""
        notes = ""
        previewResult = nil
        selectedResult = .pass
        errorMessage = nil
    }

    // MARK: - Derived data

    /// Human-readable guidance for the current component's measurement.
    var measurementHint: String {
        switch component.category {
        case .chain:
            return "Use a chain checker. It will show one of: new, under 0.5%, 0.5%, 0.75%, or 1.0%."
        case .brakePad:
            return "Enter pad thickness in mm (measure the friction material, not the backing plate)."
        case .brakeRotor:
            return "Enter rotor thickness in mm (measure at the thinnest point)."
        case .battery:
            return "Enter the indicator: 5 = green solid, 4 = green flashing, 3 = yellow solid, 2 = yellow flashing, 1 = red solid, 0 = red flashing."
        default:
            return "Enter a numeric reading."
        }
    }
}
