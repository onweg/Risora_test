//
//  RemoveHabitCompletionUseCase.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

protocol RemoveHabitCompletionUseCaseProtocol {
    func execute(habitId: UUID, date: Date) throws
}

class RemoveHabitCompletionUseCase: RemoveHabitCompletionUseCaseProtocol {
    private let habitRepository: HabitRepositoryProtocol
    private let getHabitsForDayUseCase: GetHabitsForDayUseCaseProtocol
    
    init(habitRepository: HabitRepositoryProtocol, getHabitsForDayUseCase: GetHabitsForDayUseCaseProtocol) {
        self.habitRepository = habitRepository
        self.getHabitsForDayUseCase = getHabitsForDayUseCase
    }
    
    func execute(habitId: UUID, date: Date) throws {
        let habitsForDay = getHabitsForDayUseCase.execute(date: date)
        
        guard let habitStatus = habitsForDay.first(where: { $0.habit.id == habitId }) else {
            throw NSError(domain: "RemoveHabitCompletionUseCase", code: 404, userInfo: [NSLocalizedDescriptionKey: "Habit not found"])
        }
        
        guard habitStatus.canEdit else {
            throw NSError(domain: "RemoveHabitCompletionUseCase", code: 403, userInfo: [NSLocalizedDescriptionKey: "Cannot edit past dates"])
        }
        
        // Определяем, нужно ли удалять выполнение за день или за неделю
        let isWeeklyTarget = habitStatus.habit.targetType == .weekly
        
        if isWeeklyTarget {
            // Для цели на неделю удаляем последнее выполнение за неделю
            let calendar = Calendar.current
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
            try habitRepository.removeLastCompletionForWeek(habitId, weekStartDate: weekStart)
        } else {
            // Для цели на день удаляем последнее выполнение за день
            try habitRepository.removeLastCompletion(habitId, date: date)
        }
    }
}

