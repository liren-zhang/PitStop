//
//  LogInspectionView.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import SwiftUI

/// Screen for recording a single inspection result.
///
/// Two layouts:
/// - **Measurement mode** — a numeric input with a live preview that
///   uses the same rules the app applies when saving.
/// - **Visual mode** — a picker for the four possible results, since
///   there is no number to measure.
struct LogInspectionView: View {

    @StateObject private var viewModel: InspectionViewModel
    @Environment(\.dismiss) private var dismiss

    init(component: BikeComponent, bicycle: Bicycle, repository: BikeRepository) {
        _viewModel = StateObject(
            wrappedValue: InspectionViewModel(
                component: component,
                bicycle: bicycle,
                repository: repository
            )
        )
    }

    var body: some View {
        Form {
            // MARK: Component info
            Section("Component") {
                LabeledContent("Name", value: viewModel.component.name)
                LabeledContent("Category", value: viewModel.component.category.displayName)
            }

            // MARK: Input (differs by mode)
            if viewModel.isMeasurementMode {
                measurementSection
            } else {
                visualSection
            }

            // MARK: Preview (measurement only)
            if viewModel.isMeasurementMode, let preview = viewModel.previewResult {
                Section("Preview") {
                    resultRow(preview)
                }
            }

            // MARK: Notes
            Section("Notes") {
                TextField("Optional notes", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(2...5)
            }

            // MARK: Error
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            // MARK: History
            if !viewModel.history.isEmpty {
                Section("Recent History") {
                    ForEach(viewModel.history.prefix(5)) { record in
                        historyRow(record)
                    }
                }
            }

            // MARK: Save
            Section {
                Button {
                    if viewModel.save() {
                        dismiss()
                    }
                } label: {
                    Text("Save Inspection")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!canSave)
            }
        }
        .navigationTitle("Log Inspection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadHistory() }
    }

    // MARK: - Sections

    private var measurementSection: some View {
        Section {
            HStack {
                Text("Reading")
                Spacer()
                TextField("0", text: $viewModel.recordedValueText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .onChange(of: viewModel.recordedValueText) {
                        viewModel.updatePreview()
                    }
            }
            Text(viewModel.measurementHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Measurement")
        }
    }

    private var visualSection: some View {
        Section {
            ForEach([InspectionResult.pass, .observe, .actionNeeded, .professional],
                    id: \.self) { result in
                Button {
                    viewModel.selectedResult = result
                } label: {
                    HStack {
                        Image(systemName: iconFor(result))
                            .foregroundStyle(colorFor(result))
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(titleFor(result))
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(subtitleFor(result))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if viewModel.selectedResult == result {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        } header: {
            Text("Result")
        } footer: {
            Text("Pick what you saw during the check.")
        }
    }

    // MARK: - Rows

    private func resultRow(_ result: InspectionResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconFor(result))
                .foregroundStyle(colorFor(result))
            VStack(alignment: .leading) {
                Text(titleFor(result)).font(.headline)
                Text(subtitleFor(result))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func historyRow(_ record: InspectionRecord) -> some View {
        HStack {
            Image(systemName: iconFor(record.result))
                .foregroundStyle(colorFor(record.result))
            VStack(alignment: .leading) {
                Text(titleFor(record.result)).font(.subheadline)
                Text(record.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let value = record.recordedValue {
                Text(String(format: "%.2f", value))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Save gating

    private var canSave: Bool {
        if viewModel.isMeasurementMode {
            return !viewModel.recordedValueText.isEmpty
        }
        return true   // visual mode always has a selected result
    }

    // MARK: - Result formatting

    private func iconFor(_ result: InspectionResult) -> String {
        switch result {
        case .pass:         return "checkmark.circle.fill"
        case .observe:      return "clock.fill"
        case .actionNeeded: return "exclamationmark.circle.fill"
        case .professional: return "building.2.fill"
        }
    }

    private func colorFor(_ result: InspectionResult) -> Color {
        switch result {
        case .pass:         return .green
        case .observe:      return .yellow
        case .actionNeeded: return .orange
        case .professional: return .red
        }
    }

    private func titleFor(_ result: InspectionResult) -> String {
        switch result {
        case .pass:         return "All good"
        case .observe:      return "Keep an eye on it"
        case .actionNeeded: return "Shop when convenient"
        case .professional: return "Visit shop now"
        }
    }

    private func subtitleFor(_ result: InspectionResult) -> String {
        switch result {
        case .pass:
            return "Nothing to do. Next check will start from today."
        case .observe:
            return "Still usable, but check again at the next reminder."
        case .actionNeeded:
            return "Plan the work soon — not urgent yet."
        case .professional:
            return "Deal with this right away. The reminder will stay active."
        }
    }
}

#Preview {
    NavigationStack {
        LogInspectionView(
            component: BikeComponent(
                bicycleId: UUID(),
                name: "Chain",
                category: .chain,
                installedMileageKm: 0,
                technicalDifficulty: 2,
                needsSpecialTools: true,
                needsConsumables: true,
                estimatedMinutes: 30,
                isSafetyCritical: false
            ),
            bicycle: Bicycle(
                name: "Test",
                brand: "Test",
                drivetrainType: .mechanical,
                brakeType: .discHydraulic
            ),
            repository: AppEnvironment.shared.repository
        )
    }
}
