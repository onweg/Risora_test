//
//  SetHabitCompletionCountUseCase.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

protocol SetHabitCompletionCountUseCaseProtocol {
    func execute(habitId: UUID, date: Date, targetCount: Int) throws
}

class SetHabitCompletionCountUseCase: SetHabitCompletionCountUseCaseProtocol {
    private let habitRepository: HabitRepositoryProtocol
    private let getHabitsForDayUseCase: GetHabitsForDayUseCaseProtocol
    
    init(habitRepository: HabitRepositoryProtocol, getHabitsForDayUseCase: GetHabitsForDayUseCaseProtocol) {
        self.habitRepository = habitRepository
        self.getHabitsForDayUseCase = getHabitsForDayUseCase
    }
    
    func execute(habitId: UUID, date: Date, targetCount: Int) throws {
        let habitsForDay = getHabitsForDayUseCase.execute(date: date)
        
        guard let habitStatus = habitsForDay.first(where: { $0.habit.id == habitId }) else {
            throw NSError(domain: "SetHabitCompletionCountUseCase", code: 404, userInfo: [NSLocalizedDescriptionKey: "Habit not found"])
        }
        
        guard habitStatus.canEdit else {
            throw NSError(domain: "SetHabitCompletionCountUseCase", code: 403, userInfo: [NSLocalizedDescriptionKey: "Cannot edit past dates"])
        }
        
        // Определяем, нужно ли устанавливать цель на день или на неделю
        let isWeeklyTarget = habitStatus.habit.targetType == .weekly
        let currentCount = isWeeklyTarget ? habitStatus.weeklyCompletionCount : habitStatus.completionCount
        let maxAllowed = isWeeklyTarget ? habitStatus.habit.targetValue : habitStatus.habit.targetValue
        
        // Проверяем лимит для недельных целей
        if isWeeklyTarget && targetCount > maxAllowed && maxAllowed > 0 {
            throw NSError(domain: "SetHabitCompletionCountUseCase", code: 400, userInfo: [NSLocalizedDescriptionKey: "Нельзя превышать лимит в \(maxAllowed) выполнений за неделю"])
        }
        
        if targetCount > currentCount {
            // Нужно добавить выполнений
            let toAdd = targetCount - currentCount
            for _ in 0..<toAdd {
                try habitRepository.completeHabit(habitId, date: date)
            }
        } else if targetCount < currentCount {
            // Нужно удалить выполнений
            let toRemove = currentCount - targetCount
            for _ in 0..<toRemove {
                // Для цели на неделю удаляем последнее выполнение за неделю, а не за день
                if isWeeklyTarget {
                    // Удаляем последнее выполнение за неделю
                    let calendar = Calendar.current
                    let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
                    try habitRepository.removeLastCompletionForWeek(habitId, weekStartDate: weekStart)
                } else {
                    try habitRepository.removeLastCompletion(habitId, date: date)
                }
            }
        }
        // Если targetCount == currentCount, ничего не делаем
    }
}

