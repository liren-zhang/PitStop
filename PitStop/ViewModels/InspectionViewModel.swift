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
/// Collects the user's measurement for a specific component, calls the
/// business rules in `LogInspectionUseCase`, and persists the resulting
/// `InspectionRecord`. Also exposes the inspection history of the
/// component so the user can see how the value has changed over time.
@MainActor
final class InspectionViewModel: ObservableObject {

    // MARK: - Published state
    @Published var recordedValueText: String = ""
    @Published var notes: String = ""
    @Published var previewResult: InspectionResult?
    @Published var history: [InspectionRecord] = []
    @Published var errorMessage: String?

    // MARK: - Context
    let component: BikeComponent

    // MARK: - Dependencies
    private let repository: BikeRepository
    private let logUseCase: LogInspectionUseCase

    init(
        component: BikeComponent,
        repository: BikeRepository,
        logUseCase: LogInspectionUseCase = LogInspectionUseCase()
    ) {
        self.component = component
        self.repository = repository
        self.logUseCase = logUseCase
    }

    // MARK: - Loading

    /// Load the previous inspection records for this component.
    func loadHistory() {
        do {
            history = try repository.fetchInspections(forComponent: component.id)
        } catch {
            errorMessage = "Unable to load inspection history."
        }
    }

    // MARK: - Live preview

    /// Called as the user types. Runs the use case to show a live result
    /// preview before saving.
    func updatePreview() {
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

    /// Persist the inspection record.
    /// - Returns: `true` on success, `false` if the input was invalid.
    func save() -> Bool {
        let value = Double(recordedValueText)
        do {
            let result = try logUseCase.execute(
                component: component,
                measuredValue: value
            )
            let record = InspectionRecord(
                componentId: component.id,
                recordedValue: value,
                result: result,
                notes: notes
            )
            try repository.addInspection(record)
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

    /// Clear the form after a successful save.
    func resetForm() {
        recordedValueText = ""
        notes = ""
        previewResult = nil
        errorMessage = nil
    }

    // MARK: - Derived data

    /// Human-readable guidance for the current component's measurement.
    /// Displayed under the input field so the user knows what to enter.
    var measurementHint: String {
        switch component.category {
        case .chain:
            return "Enter chain wear percentage (e.g. 0.75). Use a chain checker tool."
        case .brakePad:
            return "Enter pad thickness in mm (e.g. 2.5). Measure the friction material."
        case .brakeRotor:
            return "Enter rotor thickness in mm (e.g. 1.8). Measure at the thinnest point."
        case .battery:
            return "Enter battery indicator (5 = green solid, 4 = green flashing, 3 = yellow solid, 2 = yellow flashing, 1 = red solid, 0 = red flashing)."
        case .tyre:
            return "Optional. Enter tread depth in mm, or leave blank for visual check."
        default:
            return "Optional. Enter a numeric reading, or leave blank for a visual check."
        }
    }

    /// Whether the input field should be visible at all.
    /// Some categories are purely visual inspections.
    var hasNumericInput: Bool {
        switch component.category {
        case .chain, .brakePad, .brakeRotor, .battery:
            return true
        default:
            return true   // still allow, but optional
        }
    }
}