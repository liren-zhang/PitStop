//
//  GarageView.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import SwiftUI

/// The app's home screen.
///
/// Lists every bicycle in the user's garage and shows a badge when a bike
/// has components that need attention. Tapping a bike opens its detail
/// screen. A toolbar button lets the user add a new bicycle.
struct GarageView: View {

    @StateObject private var viewModel: GarageViewModel
    @State private var showingAddBike = false

    init(repository: BikeRepository) {
        _viewModel = StateObject(
            wrappedValue: GarageViewModel(repository: repository)
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.bicycles.isEmpty {
                    emptyState
                } else {
                    bicycleList
                }
            }
            .navigationTitle("Garage")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddBike = true
                    } label: {
                        Label("Add Bicycle", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBike) {
                AddBicycleSheet { name, brand, drivetrain, brake, mileage in
                    viewModel.addBicycle(
                        name: name,
                        brand: brand,
                        drivetrainType: drivetrain,
                        brakeType: brake,
                        currentMileageKm: mileage
                    )
                }
            }
            .onAppear { viewModel.load() }
            .alert(
                "Something went wrong",
                isPresented: .constant(viewModel.errorMessage != nil),
                presenting: viewModel.errorMessage
            ) { _ in
                Button("OK") { viewModel.errorMessage = nil }
            } message: { message in
                Text(message)
            }
        }
    }

    // MARK: - Subviews

    private var bicycleList: some View {
        List {
            ForEach(viewModel.bicycles) { bicycle in
                NavigationLink {
                    BikeDetailView(
                        bicycle: bicycle,
                        repository: viewModelRepository
                    )
                } label: {
                    bicycleRow(bicycle)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteBicycle(viewModel.bicycles[index])
                }
            }
        }
    }

    private func bicycleRow(_ bicycle: Bicycle) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bicycle")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(bicycle.name)
                    .font(.headline)
                Text(bicycle.brand)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(Int(bicycle.currentMileageKm)) km")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            let count = viewModel.dueCount(for: bicycle)
            if count > 0 {
                Text("\(count)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red, in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Bicycles Yet", systemImage: "bicycle")
        } description: {
            Text("Add your first bicycle to start tracking maintenance.")
        } actions: {
            Button("Add Bicycle") {
                showingAddBike = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    /// The repository needs to be passed into the detail view too.
    private var viewModelRepository: BikeRepository {
        // The repository is captured inside the ViewModel at init time.
        // For navigation we expose it via the factory method below.
        (viewModel as Any) as? BikeRepository ?? AppEnvironment.shared.repository
    }
}

// MARK: - Add Bicycle Sheet

/// A simple form for adding a new bicycle.
struct AddBicycleSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var drivetrainType: DrivetrainType = .mechanical
    @State private var brakeType: BrakeType = .discHydraulic
    @State private var mileageText = ""

    let onSave: (String, String, DrivetrainType, BrakeType, Double) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Bicycle") {
                    TextField("Name (e.g. Commuter)", text: $name)
                    TextField("Brand (e.g. Giant)", text: $brand)
                }

                Section("Drivetrain") {
                    Picker("Type", selection: $drivetrainType) {
                        Text("Mechanical").tag(DrivetrainType.mechanical)
                        Text("Electronic").tag(DrivetrainType.electronic)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Brakes") {
                    Picker("Type", selection: $brakeType) {
                        Text("Hydraulic Disc").tag(BrakeType.discHydraulic)
                        Text("Mechanical Disc").tag(BrakeType.discMechanical)
                        Text("Rim").tag(BrakeType.rim)
                    }
                }

                Section("Current Mileage") {
                    HStack {
                        TextField("0", text: $mileageText)
                            .keyboardType(.decimalPad)
                        Text("km")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add Bicycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            name,
                            brand,
                            drivetrainType,
                            brakeType,
                            Double(mileageText) ?? 0
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty || brand.isEmpty)
                }
            }
        }
    }
}