//
//  AppEnvironment.swift
//  PitStop
//
//  Created by Liren Zhang on 2/10/2026.
//

import Foundation
import CoreData

/// The single place where the app's dependencies are constructed and
/// held. Views read the repository from here rather than building their
/// own, so the same Core Data stack is shared across the entire app.
///
/// This is deliberately a simple singleton. If the app later needs
/// multiple environments (for previews or tests), this can be extended.
final class AppEnvironment {

    static let shared = AppEnvironment()

    /// The Core Data container for the main app.
    let container: NSPersistentContainer

    /// The repository that every ViewModel talks to.
    let repository: BikeRepository

    private init() {
        // 1. Build the container
        container = NSPersistentContainer(name: "PitStopModel")

        // 2. Point the store at the App Group container so the extensions
        //    could read it if needed. Falls back to the default location
        //    if the App Group is not configured.
        if let sharedURL = AppGroup.containerURL {
            let storeURL = sharedURL.appendingPathComponent("PitStop.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            container.persistentStoreDescriptions = [description]
        }

        // 3. Load the store
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production, this would surface a user-friendly error
                // screen. For the MVP we log and continue.
                print("Core Data store failed to load: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        // 4. Build the repository
        repository = CoreDataBikeRepository(container: container)
    }
}