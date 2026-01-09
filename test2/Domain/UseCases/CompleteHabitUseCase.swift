//
//  CompleteHabitUseCase.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

protocol CompleteHabitUseCaseProtocol {
    func execute(habitId: UUID, date: Date) throws
}

class CompleteHabitUseCase: CompleteHabitUseCaseProtocol {
    private let habitRepository: HabitRepositoryProtocol
    private let getHabitsForDayUseCase: GetHabitsForDayUseCaseProtocol
    
    init(habitRepository: HabitRepositoryProtocol, getHabitsForDayUseCase: GetHabitsForDayUseCaseProtocol) {
        self.habitRepository = habitRepository
        self.getHabitsForDayUseCase = getHabitsForDayUseCase
    }
    
    func execute(habitId: UUID, date: Date) throws {
        let habitsForDay = getHabitsForDayUseCase.execute(date: date)
        
        guard let habitStatus = habitsForDay.first(where: { $0.habit.id == habitId }) else {
            throw NSError(domain: "CompleteHabitUseCase", code: 404, userInfo: [NSLocalizedDescriptionKey: "Habit not found"])
        }
        
        guard habitStatus.canEdit else {
            throw NSError(domain: "CompleteHabitUseCase", code: 403, userInfo: [NSLocalizedDescriptionKey: "Cannot edit past dates"])
        }
        
        // Для всех привычек при обычном нажатии только добавляем выполнение
        // Счетчик только растет
        try habitRepository.completeHabit(habitId, date: date)
    }
}

