//
//  InspectionGuideView.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import SwiftUI

/// Explains how to inspect a specific component, then lets the user
/// record the result.
///
/// The guide adapts to the component's category: a chain uses a wear
/// checker, a brake pad needs a calliper, an electronic groupset uses
/// the battery indicator lights.
struct InspectionGuideView: View {

    let component: BikeComponent
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
            return "Use a chain wear indicator (chain checker). Drop the tool into a link and try to push it fully in. The percentage shown on the tool is the stretch value."
        case .brakePad:
            return "Remove the wheel and shine a light onto the brake calliper. Measure the thickness of the friction material (not the metal backing plate) with a calliper or a ruler."
        case .brakeRotor:
            return "Measure the rotor thickness at the thinnest point with a digital calliper. Avoid the braking track wear markers."
        case .battery:
            return "Press the junction box button on the groupset and read the LED indicator. Green solid = full, green flashing = 75%, yellow solid = 50%, yellow flashing = 25%, red solid = low, red flashing = very low."
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
            return "Above 3 mm = new. 2–3 mm = fine. 1–2 mm = plan a replacement. Under 1 mm = replace now (safety)."
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
        return "If the part is fine, tap Log Inspection to record the reading. If it needs work, the app will suggest the appropriate service level — DIY or shop — based on the difficulty, tools, and time required."
    }
}