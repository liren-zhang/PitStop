//
//  ContentView.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import SwiftUI

/// Root view of the app.
///
/// Shows the garage as the first screen. The repository is read from the
/// App Environment so that every screen below uses the same Core Data
/// stack.
struct ContentView: View {
    var body: some View {
        GarageView(repository: AppEnvironment.shared.repository)
    }
}

#Preview {
    ContentView()
}