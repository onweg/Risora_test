//
//  HabitModel.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

struct HabitModel: Identifiable {
    let id: UUID
    let name: String
    let type: HabitType
    let frequency: HabitFrequency? // Устаревшее, оставлено для совместимости
    let frequencyCount: Int // Устаревшее, оставлено для совместимости
    let xpValue: Int
    let createdAt: Date
    let targetType: HabitTargetType? // Для полезных: тип цели (день/неделя)
    let targetValue: Int // Для полезных: значение цели. Для вредных: не используется
    let dailyTarget: Int // Для полезных: сколько раз в день (если targetType = daily). Для вредных: минимальный порог за день (0 = без лимита)
    let weeklyTarget: Int // Для полезных: сколько раз в неделю (если targetType = weekly). Для вредных: минимальный порог за неделю (0 = без лимита)
    let proportionalReward: Bool // Для полезных: пропорциональное начисление XP или все или ничего
    
    init(
        id: UUID = UUID(),
        name: String,
        type: HabitType,
        frequency: HabitFrequency? = nil,
        frequencyCount: Int = 0,
        xpValue: Int,
        createdAt: Date = Date(),
        targetType: HabitTargetType? = nil,
        targetValue: Int = 0,
        dailyTarget: Int = 0,
        weeklyTarget: Int = 0,
        proportionalReward: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.frequency = frequency
        self.frequencyCount = frequencyCount
        self.xpValue = xpValue
        self.createdAt = createdAt
        self.targetType = targetType
        self.targetValue = targetValue
        self.dailyTarget = dailyTarget
        self.weeklyTarget = weeklyTarget
        self.proportionalReward = proportionalReward
    }
}

