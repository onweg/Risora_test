//
//  DeleteHabitUseCase.swift
//  test2
//

import Foundation

protocol DeleteHabitUseCaseProtocol {
    func execute(habitId: UUID) throws
}

/// Удаляет привычку/задачу навсегда из базы и убирает из целей.
class DeleteHabitUseCase: DeleteHabitUseCaseProtocol {
    private let habitRepository: HabitRepositoryProtocol
    private let goalRepository: GoalRepositoryProtocol

    init(habitRepository: HabitRepositoryProtocol, goalRepository: GoalRepositoryProtocol) {
        self.habitRepository = habitRepository
        self.goalRepository = goalRepository
    }

    func execute(habitId: UUID) throws {
        try? goalRepository.removeHabitFromGoals(habitId)
        try habitRepository.hardDeleteHabit(habitId)
    }
}
