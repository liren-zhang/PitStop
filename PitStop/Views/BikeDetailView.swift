//
//  BikeDetailView.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import SwiftUI

/// Shows a single bicycle: its mileage, its components with service
/// status badges, and any scheduled maintenance tasks.
struct BikeDetailView: View {

    @StateObject private var viewModel: BikeDetailViewModel
    @State private var showingAddComponent = false
    @State private var componentToReplace: BikeComponent?
    @State private var showingAddRide = false
    @State private var showingMileageEditor = false
    @State private var addRideText = ""
    @State private var newMileageText = ""
    @State private var selectedComponent: BikeComponent?

    init(bicycle: Bicycle, repository: BikeRepository) {
        _viewModel = StateObject(
            wrappedValue: BikeDetailViewModel(
                bicycle: bicycle,
                repository: repository
            )
        )
    }

    var body: some View {
        List {

            // MARK: Mileage
            Section {
                HStack {
                    Text("Current Mileage")
                    Spacer()
                    Text("\(Int(viewModel.bicycle.currentMileageKm)) km")
                        .foregroundStyle(.secondary)
                }

                Button {
                    addRideText = ""
                    showingAddRide = true
                } label: {
                    Label("Add Ride", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                Button {
                    newMileageText = String(Int(viewModel.bicycle.currentMileageKm))
                    showingMileageEditor = true
                } label: {
                    Label("Edit Mileage", systemImage: "pencil")
                        .font(.caption)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            }

            // MARK: Components
            Section("Components") {
                if viewModel.components.isEmpty {
                    Text("No components yet. Add the parts you want to track.")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                } else {
                    ForEach(viewModel.components) { item in
                        Button {
                            selectedComponent = item.component
                        } label: {
                            componentRow(item)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteComponent(item.component)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                componentToReplace = item.component
                            } label: {
                                Label("Replace", systemImage: "arrow.2.squarepath")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }

            // MARK: Scheduled tasks
            if !viewModel.tasks.isEmpty {
                Section("Scheduled Tasks") {
                    ForEach(viewModel.tasks) { task in
                        taskRow(task)
                    }
                }
            }
        }
        .navigationTitle(viewModel.bicycle.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddComponent = true
                } label: {
                    Label("Add Component", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddComponent) {
            AddComponentSheet(bicycle: viewModel.bicycle) {
                name, category, installedKm, intervalKm, intervalDays,
                difficulty, needsTools, needsConsumables, minutes, safety in
                viewModel.addComponent(
                    name: name,
                    category: category,
                    installedMileageKm: installedKm,
                    serviceIntervalKm: intervalKm,
                    serviceIntervalDays: intervalDays,
                    technicalDifficulty: difficulty,
                    needsSpecialTools: needsTools,
                    needsConsumables: needsConsumables,
                    estimatedMinutes: minutes,
                    isSafetyCritical: safety
                )
            }
        }
        .sheet(item: $componentToReplace) { old in
            AddComponentSheet(bicycle: viewModel.bicycle, initialComponent: old) {
                name, category, _, intervalKm, intervalDays,
                difficulty, needsTools, needsConsumables, minutes, safety in
                viewModel.replaceComponent(
                    old,
                    withName: name,
                    category: category,
                    installedMileageKm: viewModel.bicycle.currentMileageKm,
                    serviceIntervalKm: intervalKm,
                    serviceIntervalDays: intervalDays,
                    technicalDifficulty: difficulty,
                    needsSpecialTools: needsTools,
                    needsConsumables: needsConsumables,
                    estimatedMinutes: minutes,
                    isSafetyCritical: safety
                )
            }
        }
        .sheet(item: $selectedComponent) { component in
            InspectionDestination(
                component: component,
                bicycle: viewModel.bicycle,
                repository: AppEnvironment.shared.repository
            )
        }
        .alert("Add Ride", isPresented: $showingAddRide) {
            TextField("Distance (km)", text: $addRideText)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                if let value = Double(addRideText) {
                    viewModel.addRide(value)
                }
            }
        } message: {
            Text("How far did you ride today?")
        }
        .alert("Edit Mileage", isPresented: $showingMileageEditor) {
            TextField("New total (km)", text: $newMileageText)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let value = Double(newMileageText) {
                    viewModel.updateMileage(value)
                }
            }
        } message: {
            Text("Use this only to correct the total. For daily rides, use Add Ride instead.")
        }
        .onAppear { viewModel.load() }
    }

    // MARK: - Rows

    private func componentRow(_ item: ComponentWithStatus) -> some View {
        HStack(spacing: 12) {
            statusIcon(for: item.status)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.component.name)
                    .font(.headline)
                Text(item.component.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(statusText(for: item.status))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let level = viewModel.serviceLevel(for: item.component) {
                Image(systemName: level.iconName)
                    .foregroundStyle(level.color)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private func taskRow(_ task: MaintenanceTask) -> some View {
        HStack(spacing: 12) {
            Image(systemName: task.serviceLevel.iconName)
                .foregroundStyle(task.serviceLevel.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                Text(task.dueDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if task.isOverdue {
                Text("Overdue")
                    .font(.caption2.bold())
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Helpers

    private func statusIcon(for status: ServiceStatus) -> some View {
        Group {
            switch status {
            case .ok:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .upcoming:
                Image(systemName: "clock.fill")
                    .foregroundStyle(.yellow)
            case .due:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
            case .overdue:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        .frame(width: 24)
    }

    private func statusText(for status: ServiceStatus) -> String {
        switch status {
        case .ok:
            return "All good"
        case .upcoming(let days, let km):
            var parts: [String] = []
            if let d = days { parts.append("\(d) d") }
            if let k = km { parts.append("\(Int(k)) km") }
            return parts.isEmpty ? "Coming up" : "Due in " + parts.joined(separator: " / ")
        case .due:
            return "Due now"
        case .overdue(let days, let km):
            return "Overdue by \(days) d / \(Int(km)) km"
        }
    }
}

// MARK: - Sheet destination wrapper

private struct InspectionDestination: View {
    let component: BikeComponent
    let bicycle: Bicycle
    let repository: BikeRepository

    var body: some View {
        NavigationStack {
            InspectionGuideView(
                component: component,
                bicycle: bicycle,
                repository: repository
            )
        }
    }
}
