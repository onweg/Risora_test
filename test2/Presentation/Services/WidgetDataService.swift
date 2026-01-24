//
//  WidgetDataService.swift
//  test2
//
//  Created by Arkadiy on 19.01.2026.
//

import Foundation

// Структура для передачи данных в виджет
// Должна быть одинаковой в основном приложении и виджете
struct WidgetGoalData: Codable {
    let goalId: String
    let title: String
    let motivation: String
    let habitNames: [String]
    let lastUpdateDate: Date
}

class WidgetDataService {
    static let shared = WidgetDataService()
    
    private let appGroupIdentifier = "group.com.risora.widget"
    private let widgetDataKey = "widgetGoalData"
    
    private init() {}
    
    // Сохраняет данные текущей цели для виджета
    func saveWidgetData(goal: GoalModel, habitNames: [String]) {
        print("💾 Attempting to save widget data...")
        print("   App Group ID: \(appGroupIdentifier)")
        print("   Goal: \(goal.title)")
        
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ CRITICAL: Failed to create UserDefaults with app group: \(appGroupIdentifier)")
            print("⚠️ SOLUTION: Check that App Group '\(appGroupIdentifier)' is configured in:")
            print("   1. Main app target → Signing & Capabilities → App Groups")
            print("   2. RisoraWidget target → Signing & Capabilities → App Groups")
            print("   Both must have the SAME App Group ID: \(appGroupIdentifier)")
            return
        }
        
        print("✅ UserDefaults created successfully with App Group")
        
        let widgetData = WidgetGoalData(
            goalId: goal.id.uuidString,
            title: goal.title,
            motivation: goal.motivation,
            habitNames: habitNames,
            lastUpdateDate: Date()
        )
        
        do {
            let encoded = try JSONEncoder().encode(widgetData)
            userDefaults.set(encoded, forKey: widgetDataKey)
            userDefaults.synchronize()
            
            // Проверяем что данные действительно сохранились
            if let savedData = userDefaults.data(forKey: widgetDataKey) {
                print("✅ Widget data saved and verified successfully:")
                print("   - Goal: \(widgetData.title)")
                print("   - Motivation: \(widgetData.motivation)")
                print("   - Habits: \(widgetData.habitNames.joined(separator: ", "))")
                print("   - App Group: \(appGroupIdentifier)")
                print("   - Data size: \(savedData.count) bytes")
            } else {
                print("❌ CRITICAL: Data was set but cannot be read back!")
                print("   This means App Group is not working correctly")
            }
        } catch {
            print("❌ Failed to encode widget data: \(error)")
        }
    }
    
    // Получает данные цели для виджета (используется виджетом)
    static func loadWidgetData() -> WidgetGoalData? {
        guard let userDefaults = UserDefaults(suiteName: "group.com.risora.widget") else {
            return nil
        }
        
        guard let data = userDefaults.data(forKey: "widgetGoalData"),
              let widgetData = try? JSONDecoder().decode(WidgetGoalData.self, from: data) else {
            return nil
        }
        
        return widgetData
    }
    
    // Выбирает следующую цель для виджета (ротация раз в 3 дня)
    func updateWidgetWithNextGoal(goals: [GoalModel], habitRepository: HabitRepositoryProtocol) {
        guard !goals.isEmpty else {
            print("⚠️ No goals available for widget")
            return
        }
        
        // Получаем индекс текущей цели или выбираем случайную
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ Cannot access App Group UserDefaults")
            return
        }
        
        let lastGoalIdKey = "widgetLastGoalId"
        let lastUpdateDateKey = "widgetLastUpdateDate"
        
        let lastGoalId = userDefaults.string(forKey: lastGoalIdKey)
        let lastUpdateDate = userDefaults.object(forKey: lastUpdateDateKey) as? Date
        
        // Проверяем, есть ли уже сохраненные данные для виджета
        let hasExistingData = WidgetDataService.loadWidgetData() != nil
        
        var selectedGoal: GoalModel
        var selectedIndex = 0
        
        // Если данных нет вообще (первый запуск) - сразу выбираем первую цель
        if !hasExistingData || lastUpdateDate == nil {
            print("📱 First time widget setup - selecting first goal")
            selectedGoal = goals[0]
            selectedIndex = 0
            // Сохраняем время обновления
            userDefaults.set(Date(), forKey: lastUpdateDateKey)
            userDefaults.set(selectedGoal.id.uuidString, forKey: lastGoalIdKey)
        } else {
            // Проверяем, прошло ли 3 дня
            let daysSinceUpdate = Calendar.current.dateComponents([.day], from: lastUpdateDate!, to: Date()).day ?? 0
            
            if daysSinceUpdate >= 3 {
                // Время менять цель - выбираем следующую или первую
                print("🔄 3 days passed - rotating to next goal")
                if let lastId = lastGoalId,
                   let lastIndex = goals.firstIndex(where: { $0.id.uuidString == lastId }) {
                    selectedIndex = (lastIndex + 1) % goals.count
                } else {
                    // Выбираем первую если последняя не найдена
                    selectedIndex = 0
                }
                
                selectedGoal = goals[selectedIndex]
                
                // Сохраняем время обновления
                userDefaults.set(Date(), forKey: lastUpdateDateKey)
                userDefaults.set(selectedGoal.id.uuidString, forKey: lastGoalIdKey)
            } else {
                // Используем текущую цель или первую если её нет
                print("⏳ Less than 3 days - keeping current goal")
                if let lastId = lastGoalId,
                   let goal = goals.first(where: { $0.id.uuidString == lastId }) {
                    selectedGoal = goal
                } else {
                    selectedGoal = goals[0]
                }
            }
        }
        
        // Получаем названия привычек для этой цели
        let habitNames = selectedGoal.relatedHabitIds.compactMap { habitId in
            let allHabits = habitRepository.getAllHabits()
            return allHabits.first(where: { $0.id == habitId })?.name
        }
        
        // Сохраняем данные для виджета
        saveWidgetData(goal: selectedGoal, habitNames: habitNames)
    }
}
