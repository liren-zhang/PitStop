//
//  InspectionGuideView.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import SwiftUI

/// Explains how to inspect a specific component, shows the computed
/// service level for the current bicycle, then lets the user record
/// the result.
///
/// The guide adapts to the component's category: a chain uses a wear
/// checker, a brake pad needs a calliper (disc) or a visual check (rim),
/// an electronic groupset uses the battery indicator lights.
struct InspectionGuideView: View {

    let component: BikeComponent
    let bicycle: Bicycle
    let repository: BikeRepository

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(component.name)
                        .font(.title2.bold())
                    Text(component.category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // MARK: Computed service level
                if let level = serviceLevel {
                    serviceLevelCard(level)
                }

                // MARK: What to check
                guideSection(
                    title: "How to check",
                    icon: "magnifyingglass",
                    body: howToText
                )

                // MARK: What the standard is
                guideSection(
                    title: "Standard",
                    icon: "list.bullet.clipboard",
                    body: standardText
                )

                // MARK: What to do next
                guideSection(
                    title: "What to do next",
                    icon: "arrow.right.circle",
                    body: nextStepsText
                )

                // MARK: Log inspection
                NavigationLink {
                    LogInspectionView(
                        component: component,
                        bicycle: bicycle,
                        repository: repository
                    )
                } label: {
                    Label("Log Inspection", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Inspection Guide")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Service level

    /// Compute the service level for this component, or nil if it fails.
    private var serviceLevel: ServiceLevel? {
        try? AssessServiceOptionUseCase().execute(component: component)
    }

    /// A card that shows the computed service level and the reason.
    @ViewBuilder
    private func serviceLevelCard(_ level: ServiceLevel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("This job is", systemImage: level.iconName)
                .font(.headline)
                .foregroundStyle(level.color)

            Text(level.displayName)
                .font(.title3.bold())

            Text(level.shortDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(reasonText(for: level))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(level.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    /// Plain-language explanation of why this level was chosen.
    private func reasonText(for level: ServiceLevel) -> String {
        switch level {
        case .diySimple:
            return "You have what you need, and it's a quick job."
        case .diyWithTools:
            return "You can do this at home with basic tools."
        case .shopRecommended:
            return "Doable at home, but a shop saves time or hassle."
        case .shopRequired:
            return "The difficulty or safety risk makes a shop the safer choice."
        }
    }

    // MARK: - Reusable section

    private func guideSection(title: String, icon: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(body)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Category-specific content

    private var howToText: String {
        switch component.category {
        case .chain:
            return "Use a chain wear indicator (chain checker). It will show one of: new, under 0.5%, 0.5%, 0.75%, or 1.0%."
        case .brakePad:
            switch bicycle.brakeType {
            case .discHydraulic, .discMechanical:
                return "Remove the wheel and shine a light onto the calliper. Measure the thickness of the friction material (not the metal backing plate) with a calliper."
            case .rim:
                return "Look at the wear line on the brake block. If the line is no longer visible, the block is worn out."
            }
        case .brakeRotor:
            return "Measure the rotor thickness at the thinnest point with a digital calliper. Avoid the braking track wear markers."
        case .battery:
            return "Press the junction box button and read the LED indicator. Green solid = full, green flashing = 75%, yellow solid = 50%, yellow flashing = 25%, red solid = low, red flashing = very low."
        case .tyre:
            return "Check the tread depth visually and inspect for cuts, embedded debris, and sidewall damage. Squeeze the tyre to check pressure."
        case .gearCable, .brakeCable:
            return "Check for fraying at the derailleur or brake calliper, and feel for smooth operation through the lever. Look for rust or kinks."
        case .cassette, .chainring:
            return "Inspect the teeth: new teeth are symmetrical. Worn teeth become hooked or shark-toothed. Check for chain suck under load."
        case .bottomBracket, .hubBearing:
            return "Spin the part and feel for roughness or play. Any grinding, wobble, or resistance means service is due."
        case .other:
            return "Inspect visually and compare against the manufacturer's service manual."
        }
    }

    private var standardText: String {
        switch component.category {
        case .chain:
            return "Under 0.5% = fine. 0.5–0.75% = observe. 0.75–1.0% = replace soon. Over 1.0% = replace immediately — the cassette may already be worn."
        case .brakePad:
            switch bicycle.brakeType {
            case .discHydraulic, .discMechanical:
                return "Above 3 mm = new. 2–3 mm = fine. 1–2 mm = plan a replacement. Under 1 mm = replace now (safety)."
            case .rim:
                return "Wear line visible = fine. Wear line partly visible = plan a replacement. Wear line gone = replace now (safety)."
            }
        case .brakeRotor:
            return "Above 1.8 mm = fine. 1.5–1.8 mm = plan a replacement. Under 1.5 mm = replace now (safety)."
        case .battery:
            return "Green = fine. Yellow = plan a charge. Red = charge before your next ride."
        case .tyre:
            return "Tread depth above 1 mm is generally safe on road tyres. Replace if you see the casing, cuts through the tread, or bulges."
        default:
            return "Follow the manufacturer's recommended service interval for this part."
        }
    }

    private var nextStepsText: String {
        return "If the part is fine, tap Log Inspection to record the reading. If it needs work, the result you record will tell you whether to handle it at home or take it to a shop."
    }
}

#Preview {
    NavigationStack {
        InspectionGuideView(
            component: BikeComponent(
                bicycleId: UUID(),
                name: "Chain",
                category: .chain,
                installedMileageKm: 0,
                technicalDifficulty: 2,
                needsSpecialTools: false,
                needsConsumables: false,
                estimatedMinutes: 15,
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
