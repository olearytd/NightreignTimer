//
//  NightreignTimerApp.swift
//  NightreignTimer
//
//  Created by Tim OLeary on 6/24/25.
//

import SwiftUI
import CoreData

@main
struct NightreignTimerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            SetupView()
                .environment(\.managedObjectContext,
                             persistenceController.container.viewContext)
        }
    }
}
