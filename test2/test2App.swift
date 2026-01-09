//
//  test2App.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import SwiftUI
import UIKit

@main
struct test2App: App {
    let persistenceController = PersistenceController.shared
    private let dependencyContainer: DependencyContainer

    init() {
        let context = persistenceController.container.viewContext
        dependencyContainer = DependencyContainer(context: context)
        
        // Инициализируем состояние игры при первом запуске
        do {
            try dependencyContainer.gameStateRepository.initializeGameState()
        } catch {
            print("Error initializing game state: \(error)")
        }
        
        // Настраиваем автоматическое сохранение при переходе в фон
        let controller = persistenceController
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            let context = controller.container.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                    print("Context saved successfully")
                } catch {
                    let nsError = error as NSError
                    print("Error saving context: \(nsError), \(nsError.userInfo)")
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            let context = controller.container.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                    print("Context saved successfully")
                } catch {
                    let nsError = error as NSError
                    print("Error saving context: \(nsError), \(nsError.userInfo)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView(container: dependencyContainer)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
