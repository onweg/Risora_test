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
    /// true = задача (за выполнение не начисляется XP), false = привычка (начисляется XP).
    let isTask: Bool
    let createdAt: Date
    let targetType: HabitTargetType? // Для полезных: тип цели (день/неделя)
    let targetValue: Int // Для полезных: значение цели. Для вредных: не используется
    let dailyTarget: Int // Для полезных: сколько раз в день (если targetType = daily). Для вредных: минимальный порог за день (0 = без лимита)
    let weeklyTarget: Int // Для полезных: сколько раз в неделю (если targetType = weekly). Для вредных: минимальный порог за неделю (0 = без лимита)
    let proportionalReward: Bool // Для полезных: пропорциональное начисление XP или все или ничего
    let sortOrder: Int // Порядок сортировки в списке
    
    /// Дни недели, когда привычка активна (1 = воскресенье, 2 = понедельник, ... 7 = суббота). По умолчанию все 7.
    let activeWeekdays: Set<Int>
    /// Дата начала — привычка показывается с этого дня. nil = с даты создания.
    let startDate: Date?
    /// Дата окончания. nil = без срока (вечно).
    let endDate: Date?
    /// Идентификатор темы/сферы (работа, спорт и т.д.).
    let themeId: UUID?
    /// Час напоминания (0–23). nil или -1 = напоминание выключено.
    let notificationHour: Int?
    /// Минута напоминания (0–59).
    let notificationMinute: Int?
    /// Час начала окна выполнения (0–23). nil = без ограничения.
    let allowedStartHour: Int?
    let allowedStartMinute: Int?
    /// Час окончания окна выполнения (0–23). nil = без ограничения.
    let allowedEndHour: Int?
    let allowedEndMinute: Int?
    
    init(
        id: UUID = UUID(),
        name: String,
        type: HabitType,
        frequency: HabitFrequency? = nil,
        frequencyCount: Int = 0,
        xpValue: Int,
        isTask: Bool = false,
        createdAt: Date = Date(),
        targetType: HabitTargetType? = nil,
        targetValue: Int = 0,
        dailyTarget: Int = 0,
        weeklyTarget: Int = 0,
        proportionalReward: Bool = false,
        sortOrder: Int = 0,
        activeWeekdays: Set<Int> = [1, 2, 3, 4, 5, 6, 7],
        startDate: Date? = nil,
        endDate: Date? = nil,
        themeId: UUID? = nil,
        notificationHour: Int? = nil,
        notificationMinute: Int? = nil,
        allowedStartHour: Int? = nil,
        allowedStartMinute: Int? = nil,
        allowedEndHour: Int? = nil,
        allowedEndMinute: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.frequency = frequency
        self.frequencyCount = frequencyCount
        self.xpValue = xpValue
        self.isTask = isTask
        self.createdAt = createdAt
        self.targetType = targetType
        self.targetValue = targetValue
        self.dailyTarget = dailyTarget
        self.weeklyTarget = weeklyTarget
        self.proportionalReward = proportionalReward
        self.sortOrder = sortOrder
        self.activeWeekdays = activeWeekdays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : activeWeekdays
        self.startDate = startDate
        self.endDate = endDate
        self.themeId = themeId
        self.notificationHour = notificationHour
        self.notificationMinute = notificationMinute
        self.allowedStartHour = allowedStartHour
        self.allowedStartMinute = allowedStartMinute
        self.allowedEndHour = allowedEndHour
        self.allowedEndMinute = allowedEndMinute
    }
    
    /// Задано ли окно времени выполнения (с — по).
    var hasAllowedTimeWindow: Bool {
        guard let sh = allowedStartHour, let sm = allowedStartMinute,
              let eh = allowedEndHour, let em = allowedEndMinute else { return false }
        return (0...23).contains(sh) && (0...59).contains(sm) && (0...23).contains(eh) && (0...59).contains(em)
    }
    
    /// Строка вида "9:00 – 18:00" для отображения окна времени.
    var allowedTimeWindowString: String? {
        guard hasAllowedTimeWindow else { return nil }
        let f = { (h: Int, m: Int) in String(format: "%d:%02d", h, m) }
        return "\(f(allowedStartHour!, allowedStartMinute!)) – \(f(allowedEndHour!, allowedEndMinute!))"
    }
    
    /// Есть ли напоминание (задано время).
    var hasNotification: Bool {
        guard let h = notificationHour, h >= 0, h <= 23 else { return false }
        guard let m = notificationMinute, m >= 0, m <= 59 else { return false }
        return true
    }
}

