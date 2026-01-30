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

    @State private var activeQuote: QuoteItem? = nil

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
                .onOpenURL { url in
                    print("🔗 Received URL: \(url.absoluteString)")
                    if url.scheme == "risora" {
                        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                            var detectedQuoteText: String? = nil
                            
                            // 1. Пробуем получить индекс
                            if let indexStr = components.queryItems?.first(where: { $0.name == "index" })?.value,
                               let index = Int(indexStr),
                               index >= 0 && index < SharedQuotes.quotes.count {
                                print("📝 Found quote index: \(index)")
                                detectedQuoteText = SharedQuotes.quotes[index]
                            } 
                            // 2. Запасной вариант для текста (старая версия)
                            else if let textParam = components.queryItems?.first(where: { $0.name == "text" })?.value {
                                print("📝 Found quote text from URL")
                                detectedQuoteText = textParam
                            }
                            
                            if let quoteText = detectedQuoteText {
                                print("✅ Setting active quote: \(quoteText.prefix(20))...")
                                self.activeQuote = QuoteItem(text: quoteText)
                            } else {
                                print("⚠️ No quote detected in URL")
                            }
                        }
                    }
                }
                .sheet(item: $activeQuote) { item in
                    QuotePopupView(text: item.text)
                }
        }
    }
}

struct QuoteItem: Identifiable {
    let id = UUID()
    let text: String
}

struct QuotePopupView: View {
    let text: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Фон для всего окна, чтобы точно ничего не сливалось
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Декоративная полоска сверху
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                Spacer()
                
                Image(systemName: "quote.opening")
                    .font(.system(size: 40))
                    .foregroundColor(.blue.opacity(0.5))
                
                ScrollView {
                    Text(text)
                        .font(.system(size: 26, weight: .medium, design: .serif))
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 25)
                        .foregroundColor(colorScheme == .dark ? .white : .black) // Явно задаем цвет
                        .fixedSize(horizontal: false, vertical: true) // Чтобы текст не обрезался
                }
                .frame(maxHeight: 400)
                
                Image(systemName: "quote.closing")
                    .font(.system(size: 40))
                    .foregroundColor(.blue.opacity(0.5))
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Понятно")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden) // Мы сами нарисовали полоску
    }
}
