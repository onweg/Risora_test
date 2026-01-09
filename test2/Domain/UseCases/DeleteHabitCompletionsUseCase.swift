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
    
    init(habitRepository: HabitRepositoryProtocol) {
        self.habitRepository = habitRepository
    }
    
    func execute(habitId: UUID, date: Date) throws {
        // Помечаем привычку как удаленную с этой даты
        try habitRepository.markHabitAsDeletedFromDate(habitId, fromDate: date)
    }
}

