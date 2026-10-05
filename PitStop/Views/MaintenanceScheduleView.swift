//
//  MaintenanceScheduleView.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import SwiftUI

/// Shows all scheduled maintenance tasks grouped by service level.
///
/// This is the "what should I do next?" screen. Tasks are grouped into
/// four buckets that match how cyclists plan their work: quick wins,
/// home jobs, shop-recommended, and shop-required.
struct MaintenanceScheduleView: View {

    let bicycle: Bicycle
    let tasks: [MaintenanceTask]

    var body: some View {
        List {
            ForEach(ServiceLevel.allCases) { level in
                let filtered = tasks.filter { $0.serviceLevel == level }
                if !filtered.isEmpty {
                    Section {
                        ForEach(filtered) { task in
                            taskRow(task)
                        }
                    } header: {
                        header(for: level, count: filtered.count)
                    }
                }
            }

            if tasks.isEmpty {
                ContentUnavailableView {
                    Label("No Scheduled Tasks", systemImage: "wrench.and.screwdriver")
                } description: {
                    Text("When a component reaches its service interval, the task will appear here.")
                }
            }
        }
        .navigationTitle("Maintenance")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private func header(for level: ServiceLevel, count: Int) -> some View {
        HStack {
            Image(systemName: level.iconName)
                .foregroundStyle(level.color)
            Text(level.displayName)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func taskRow(_ task: MaintenanceTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(task.title)
                    .font(.headline)
                Spacer()
                if task.isOverdue {
                    Text("Overdue")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
            }

            Text(task.serviceLevel.shortDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label(task.dueDate.formatted(date: .abbreviated, time: .omitted),
                      systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if task.isMultiTask {
                    Label("Multi-task", systemImage: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}