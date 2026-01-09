//
//  test2App.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import SwiftUI

@main
struct test2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
