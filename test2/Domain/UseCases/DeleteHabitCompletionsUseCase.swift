//
//  DeleteHabitCompletionsUseCase.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

protocol DeleteHabitCompletionsUseCaseProtocol {
    func execute(habitId: UUID, date: Date) throws // Удаляет привычку из списка начиная с даты
}

class DeleteHabitCompletionsUseCase: DeleteHabitCompletionsUseCaseProtocol {
    private let habitRepository: HabitRepositoryProtocol
    private let goalRepository: GoalRepositoryProtocol
    
    init(habitRepository: HabitRepositoryProtocol, goalRepository: GoalRepositoryProtocol) {
        self.habitRepository = habitRepository
        self.goalRepository = goalRepository
    }
    
    func execute(habitId: UUID, date: Date) throws {
        // Помечаем привычку как удаленную с этой даты
        try habitRepository.markHabitAsDeletedFromDate(habitId, fromDate: date)
        
        // Удаляем связь с привычкой из всех целей
        try goalRepository.removeHabitFromGoals(habitId)
    }
}

