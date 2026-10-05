//
//  PitStopApp.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import SwiftUI

/// Application entry point.
///
/// The app's real work starts in `ContentView`, which shows the garage.
/// The App Environment singleton is touched here so the Core Data stack
/// is ready before any View tries to read from it.
@main
struct PitStopApp: App {

    init() {
        // Force the environment to initialise at launch.
        _ = AppEnvironment.shared
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}