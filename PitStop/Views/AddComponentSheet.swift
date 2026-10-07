//
//  AddComponentSheet.swift
//  PitStop
//
//  Created by Liren Zhang on 7/10/2026.
//

import SwiftUI

/// A form for adding a new component to a bicycle.
///
/// Also used in "replace" mode: when an `initialComponent` is passed in,
/// the form is prefilled with that component's values and the title
/// changes to "Replace Component".
struct AddComponentSheet: View {

    @Environment(\.dismiss) private var dismiss

    let bicycle: Bicycle
    let initialComponent: BikeComponent?

    @State private var name: String
    @State private var category: ComponentCategory
    @State private var installedKmText: String
    @State private var intervalKmText: String
    @State private var intervalDaysText: String
    @State private var technicalDifficulty: Int
    @State private var needsSpecialTools: Bool
    @State private var needsConsumables: Bool
    @State private var estimatedMinutes: Int
    @State private var isSafetyCritical: Bool

    /// Callback with all values filled in.
    let onSave: (
        String, ComponentCategory, Double, Double?, Int?,
        Int, Bool, Bool, Int, Bool
    ) -> Void

    init(
        bicycle: Bicycle,
        initialComponent: BikeComponent? = nil,
        onSave: @escaping (
            String, ComponentCategory, Double, Double?, Int?,
            Int, Bool, Bool, Int, Bool
        ) -> Void
    ) {
        self.bicycle = bicycle
        self.initialComponent = initialComponent
        self.onSave = onSave

        _name = State(initialValue: initialComponent?.name ?? "")
        _category = State(initialValue: initialComponent?.category ?? .chain)
        _installedKmText = State(initialValue: initialComponent
            .map { String(Int($0.installedMileageKm)) } ?? "")
        _intervalKmText = State(initialValue: initialComponent?
            .serviceIntervalKm.map { String(Int($0)) } ?? "")
        _intervalDaysText = State(initialValue: initialComponent?
            .serviceIntervalDays.map { String($0) } ?? "")
        _technicalDifficulty = State(initialValue: initialComponent?.technicalDifficulty ?? 2)
        _needsSpecialTools = State(initialValue: initialComponent?.needsSpecialTools ?? false)
        _needsConsumables = State(initialValue: initialComponent?.needsConsumables ?? false)
        _estimatedMinutes = State(initialValue: initialComponent?.estimatedMinutes ?? 15)
        _isSafetyCritical = State(initialValue: initialComponent?.isSafetyCritical ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Basic info
                Section("Component") {
                    TextField("Name (e.g. Shimano CN-M8100)", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(availableCategories, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }

                // MARK: Installation
                Section("Installation") {
                    HStack {
                        Text("Installed at")
                        Spacer()
                        TextField("0", text: $installedKmText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("km").foregroundStyle(.secondary)
                    }
                }

                // MARK: Intervals
                Section {
                    HStack {
                        Text("Every")
                        Spacer()
                        TextField("optional", text: $intervalKmText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("km").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Every")
                        Spacer()
                        TextField("optional", text: $intervalDaysText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("days").foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Service Interval")
                } footer: {
                    Text("Fill in at least one. Whichever is reached first triggers the reminder.")
                }

                // MARK: Subjective assessment
                Section {
                    Stepper(
                        "Difficulty: \(difficultyLabelFor(technicalDifficulty))",
                        value: $technicalDifficulty,
                        in: 1...5
                    )

                    Toggle("I don't have the tools", isOn: $needsSpecialTools)
                    Toggle("I don't have the consumables", isOn: $needsConsumables)

                    Stepper(
                        "Estimated time: \(estimatedMinutes) min",
                        value: $estimatedMinutes,
                        in: 5...240, step: 5
                    )

                    Toggle("Safety critical", isOn: $isSafetyCritical)
                } header: {
                    Text("About This Job")
                } footer: {
                    Text("These answers decide whether the app recommends you do the work at home, or take it to a shop.")
                }

                // MARK: Notice window
                Section {
                    Text("You'll be reminded 100 km or 7 days before the interval.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(initialComponent == nil ? "Add Component" : "Replace Component")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(initialComponent == nil ? "Save" : "Replace") {
                        onSave(
                            name,
                            category,
                            Double(installedKmText) ?? 0,
                            Double(intervalKmText),
                            Int(intervalDaysText),
                            technicalDifficulty,
                            needsSpecialTools,
                            needsConsumables,
                            estimatedMinutes,
                            isSafetyCritical
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty
                              || (intervalKmText.isEmpty && intervalDaysText.isEmpty))
                }
            }
        }
    }

    // MARK: - Helpers

    /// Only the categories that make sense for this bicycle.
    private var availableCategories: [ComponentCategory] {
        ComponentCategory.allCases.filter { $0.isAvailable(for: bicycle) }
    }

    /// User-facing difficulty label for the current rating.
    private func difficultyLabelFor(_ value: Int) -> String {
        switch value {
        case 1: return "Anyone can do it"
        case 2: return "Confident"
        case 3: return "Careful"
        case 4: return "Need guidance"
        default: return "Not capable"
        }
    }
}

#Preview {
    AddComponentSheet(bicycle: Bicycle(
        name: "Test",
        brand: "Test",
        drivetrainType: .mechanical,
        brakeType: .discHydraulic
    )) { _, _, _, _, _, _, _, _, _, _ in }
}
