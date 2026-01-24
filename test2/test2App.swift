//
//  test2App.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import SwiftUI
import UIKit
import UserNotifications

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
        
        // Выполняем миграцию данных к системе попыток
        do {
            try dependencyContainer.migrateToGameAttemptsUseCase.execute()
        } catch {
            print("Error migrating to game attempts: \(error)")
        }
        
        // Настраиваем уведомления
        NotificationService.shared.requestAuthorization()
        
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
        
        // Очищаем badge когда приложение возвращается на передний план
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            NotificationService.shared.clearBadge()
        }
        
        // Очищаем badge при первом запуске
        NotificationService.shared.clearBadge()
    }
    
    private func updateWidgetData() {
        // Принудительно обновляем данные для виджета при запуске
        print("📱 App launch: Checking goals for widget...")
        let goals = dependencyContainer.goalRepository.getAllGoals()
        print("📱 App launch: Found \(goals.count) goals")
        
        if !goals.isEmpty {
            print("📱 App launch: Updating widget data...")
            WidgetDataService.shared.updateWidgetWithNextGoal(
                goals: goals,
                habitRepository: dependencyContainer.habitRepository
            )
            print("✅ App launch: Widget data update completed")
        } else {
            print("⚠️ App launch: No goals found - widget will show placeholder")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView(container: dependencyContainer)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // Очищаем badge при открытии приложения (дополнительная проверка)
                    NotificationService.shared.clearBadge()
                    
                    // Обновляем содержимое уведомления при каждом запуске приложения
                    // чтобы каждый раз была новая случайная фраза
                    NotificationService.shared.updateNotificationContent()
                    
                    // Обновляем данные для виджета при запуске приложения
                    updateWidgetData()
                }
        }
    }
}
