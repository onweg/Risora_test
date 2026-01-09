//
//  AddHabitViewModel.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import SwiftUI

@MainActor
class AddHabitViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var selectedType: HabitType = .good
    @Published var xpValue: Int = 10
    
    // Для полезных привычек
    @Published var targetType: HabitTargetType = .daily // Цель на день или на неделю
    @Published var targetValue: Int = 3 // Значение цели
    @Published var proportionalReward: Bool = false // Пропорциональное начисление или все или ничего
    
    // Для вредных привычек
    @Published var badDailyMinThreshold: Int = 0 // Минимальный порог за день (0 = без лимита)
    @Published var badWeeklyMinThreshold: Int = 0 // Минимальный порог за неделю (0 = без лимита)
    
    private let habitRepository: HabitRepositoryProtocol
    
    nonisolated init(habitRepository: HabitRepositoryProtocol) {
        self.habitRepository = habitRepository
    }
    
    func saveHabit() throws {
        let habit: HabitModel
        if selectedType == .good {
            // Полезная привычка
            habit = HabitModel(
                name: name,
                type: selectedType,
                frequency: nil,
                frequencyCount: 0,
                xpValue: xpValue,
                targetType: targetType,
                targetValue: targetValue,
                dailyTarget: targetType == .daily ? targetValue : 0,
                weeklyTarget: targetType == .weekly ? targetValue : 0,
                proportionalReward: proportionalReward
            )
        } else {
            // Вредная привычка
            habit = HabitModel(
                name: name,
                type: selectedType,
                frequency: nil,
                frequencyCount: 0,
                xpValue: xpValue,
                targetType: nil,
                targetValue: 0,
                dailyTarget: badDailyMinThreshold,
                weeklyTarget: badWeeklyMinThreshold,
                proportionalReward: false
            )
        }
        try habitRepository.createHabit(habit)
    }
}

