//
//  LogInspectionView.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import SwiftUI

/// Screen for recording a single inspection result.
///
/// The user enters a numeric reading (where relevant) and optional notes.
/// A live preview shows the result immediately, using the same rules the
/// app will apply when saving.
struct LogInspectionView: View {

    @StateObject private var viewModel: InspectionViewModel
    @Environment(\.dismiss) private var dismiss

    init(component: BikeComponent, repository: BikeRepository) {
        _viewModel = StateObject(
            wrappedValue: InspectionViewModel(
                component: component,
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

            // MARK: Measurement
            Section {
                if viewModel.hasNumericInput {
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
                }
                Text(viewModel.measurementHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Measurement")
            }

            // MARK: Live preview
            if let preview = viewModel.previewResult {
                Section("Preview") {
                    HStack(spacing: 12) {
                        Image(systemName: iconFor(preview))
                            .foregroundStyle(colorFor(preview))
                        VStack(alignment: .leading) {
                            Text(titleFor(preview))
                                .font(.headline)
                            Text(descriptionFor(preview))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
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
                .disabled(viewModel.recordedValueText.isEmpty &&
                          viewModel.component.category != .other)
            }
        }
        .navigationTitle("Log Inspection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadHistory() }
    }

    // MARK: - Subviews

    private func historyRow(_ record: InspectionRecord) -> some View {
        HStack {
            Image(systemName: iconFor(record.result))
                .foregroundStyle(colorFor(record.result))
            VStack(alignment: .leading) {
                Text(titleFor(record.result))
                    .font(.subheadline)
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
        case .pass:         return "Pass"
        case .observe:      return "Observe"
        case .actionNeeded: return "Action needed"
        case .professional: return "Visit a shop"
        }
    }

    private func descriptionFor(_ result: InspectionResult) -> String {
        switch result {
        case .pass:
            return "Everything looks fine. No action needed."
        case .observe:
            return "Still usable, but check again soon."
        case .actionNeeded:
            return "Plan a replacement or service in the near future."
        case .professional:
            return "We recommend a professional mechanic for this."
        }
    }
}