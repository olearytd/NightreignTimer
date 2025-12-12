//
//  Persistence.swift
//  NightreignTimer
//
//  Created by Tim OLeary on 7/10/25.
//

import CoreData
import CloudKit

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer
    private var remoteChangeObserver: NSObjectProtocol?

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "NightreignTimer")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        let storeDescription = container.persistentStoreDescriptions.first!
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.toleary.NightreignTimer"
        )
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error: \(error), \(error.userInfo)")
            }
        }
#if DEBUG
        // Initialize CloudKit schema in development builds (do not ship to production)
        do {
            try container.initializeCloudKitSchema(options: [])
        } catch {
            // Safe to ignore in debug
        }
#endif
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Listen for remote change notifications and gently refresh the UI context
        remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let ctx = self.container.viewContext
            ctx.perform {
                // Ensure the context is at the latest generation and nudge objects
                try? ctx.setQueryGenerationFrom(.current)
                ctx.refreshAllObjects()
            }
        }
    }

    deinit {
        if let token = remoteChangeObserver {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
