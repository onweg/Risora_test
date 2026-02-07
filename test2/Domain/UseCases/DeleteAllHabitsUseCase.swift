//
//  DeleteAllHabitsUseCase.swift
//  test2
//

import Foundation

protocol DeleteAllHabitsUseCaseProtocol {
    func execute() throws
}

class DeleteAllHabitsUseCase: DeleteAllHabitsUseCaseProtocol {
    private let habitRepository: HabitRepositoryProtocol
    private let goalRepository: GoalRepositoryProtocol

    init(habitRepository: HabitRepositoryProtocol, goalRepository: GoalRepositoryProtocol) {
        self.habitRepository = habitRepository
        self.goalRepository = goalRepository
    }

    func execute() throws {
        let habits = habitRepository.getAllHabitsRaw()
        for habit in habits {
            try? goalRepository.removeHabitFromGoals(habit.id)
        }
        try habitRepository.deleteAllHabits()
    }
}
