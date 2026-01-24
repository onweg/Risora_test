//
//  DependencyContainer.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import CoreData

class DependencyContainer {
    let context: NSManagedObjectContext
    
    // Repositories
    lazy var habitRepository: HabitRepositoryProtocol = {
        HabitRepository(context: context)
    }()
    
    lazy var lifePointRepository: LifePointRepositoryProtocol = {
        LifePointRepository(context: context)
    }()
    
    lazy var gameStateRepository: GameStateRepositoryProtocol = {
        GameStateRepository(context: context)
    }()
    
    lazy var goalRepository: GoalRepositoryProtocol = {
        GoalRepository(context: context)
    }()
    
    lazy var gameAttemptRepository: GameAttemptRepositoryProtocol = {
        GameAttemptRepository(context: context)
    }()
    
    // UseCases
    lazy var calculateWeeklyLifePointsUseCase: CalculateWeeklyLifePointsUseCaseProtocol = {
        CalculateWeeklyLifePointsUseCase(
            habitRepository: habitRepository,
            gameStateRepository: gameStateRepository,
            gameAttemptRepository: gameAttemptRepository
        )
    }()
    
    lazy var calculateDailyLifePointsUseCase: CalculateDailyLifePointsUseCaseProtocol = {
        CalculateDailyLifePointsUseCase(
            habitRepository: habitRepository,
            gameAttemptRepository: gameAttemptRepository
        )
    }()
    
    lazy var processWeekEndUseCase: ProcessWeekEndUseCaseProtocol = {
        ProcessWeekEndUseCase(
            calculateWeeklyLifePointsUseCase: calculateWeeklyLifePointsUseCase,
            calculateDailyLifePointsUseCase: calculateDailyLifePointsUseCase,
            gameStateRepository: gameStateRepository,
            lifePointRepository: lifePointRepository,
            gameAttemptRepository: gameAttemptRepository
        )
    }()
    
    lazy var getHabitsForDayUseCase: GetHabitsForDayUseCaseProtocol = {
        GetHabitsForDayUseCase(habitRepository: habitRepository)
    }()
    
    lazy var completeHabitUseCase: CompleteHabitUseCaseProtocol = {
        CompleteHabitUseCase(
            habitRepository: habitRepository,
            getHabitsForDayUseCase: getHabitsForDayUseCase
        )
    }()
    
    lazy var setHabitCompletionCountUseCase: SetHabitCompletionCountUseCaseProtocol = {
        SetHabitCompletionCountUseCase(
            habitRepository: habitRepository,
            getHabitsForDayUseCase: getHabitsForDayUseCase
        )
    }()
    
    lazy var removeHabitCompletionUseCase: RemoveHabitCompletionUseCaseProtocol = {
        RemoveHabitCompletionUseCase(
            habitRepository: habitRepository,
            getHabitsForDayUseCase: getHabitsForDayUseCase
        )
    }()
    
    lazy var deleteHabitCompletionsUseCase: DeleteHabitCompletionsUseCaseProtocol = {
        DeleteHabitCompletionsUseCase(habitRepository: habitRepository, goalRepository: goalRepository)
    }()
    
    lazy var checkGameOverUseCase: CheckGameOverUseCaseProtocol = {
        CheckGameOverUseCase(gameStateRepository: gameStateRepository)
    }()
    
    lazy var resetGameUseCase: ResetGameUseCaseProtocol = {
        ResetGameUseCase(
            gameStateRepository: gameStateRepository,
            gameAttemptRepository: gameAttemptRepository,
            lifePointRepository: lifePointRepository
        )
    }()
    
    lazy var getWeeklyHabitAnalysisUseCase: GetWeeklyHabitAnalysisUseCaseProtocol = {
        GetWeeklyHabitAnalysisUseCase(
            habitRepository: habitRepository,
            lifePointRepository: lifePointRepository
        )
    }()
    
    lazy var processAllMissedWeeksUseCase: ProcessAllMissedWeeksUseCaseProtocol = {
        ProcessAllMissedWeeksUseCase(
            processWeekEndUseCase: processWeekEndUseCase,
            gameStateRepository: gameStateRepository,
            gameAttemptRepository: gameAttemptRepository
        )
    }()
    
    lazy var migrateToGameAttemptsUseCase: MigrateToGameAttemptsUseCaseProtocol = {
        MigrateToGameAttemptsUseCase(
            context: context,
            gameAttemptRepository: gameAttemptRepository,
            gameStateRepository: gameStateRepository
        )
    }()
    
    lazy var forceResetCurrentAttemptUseCase: ForceResetCurrentAttemptUseCaseProtocol = {
        ForceResetCurrentAttemptUseCase(
            gameStateRepository: gameStateRepository,
            gameAttemptRepository: gameAttemptRepository
        )
    }()
    
    lazy var deleteGameAttemptUseCase: DeleteGameAttemptUseCaseProtocol = {
        DeleteGameAttemptUseCase(gameAttemptRepository: gameAttemptRepository)
    }()
    
    // ViewModels
    func makeHabitsListViewModel() -> HabitsListViewModel {
        HabitsListViewModel(
            getHabitsForDayUseCase: getHabitsForDayUseCase,
            completeHabitUseCase: completeHabitUseCase,
            setHabitCompletionCountUseCase: setHabitCompletionCountUseCase,
            removeHabitCompletionUseCase: removeHabitCompletionUseCase,
            deleteHabitCompletionsUseCase: deleteHabitCompletionsUseCase,
            habitRepository: habitRepository,
            gameStateRepository: gameStateRepository,
            processAllMissedWeeksUseCase: processAllMissedWeeksUseCase
        )
    }
    
    func makeLifePointsChartViewModel() -> LifePointsChartViewModel {
        LifePointsChartViewModel(
            lifePointRepository: lifePointRepository,
            gameStateRepository: gameStateRepository,
            habitRepository: habitRepository,
            goalRepository: goalRepository,
            getWeeklyHabitAnalysisUseCase: getWeeklyHabitAnalysisUseCase,
            processWeekEndUseCase: processWeekEndUseCase
        )
    }
    
    func makeAddHabitViewModel() -> AddHabitViewModel {
        AddHabitViewModel(habitRepository: habitRepository)
    }
    
    func makeGoalsViewModel() -> GoalsViewModel {
        GoalsViewModel(
            goalRepository: goalRepository,
            habitRepository: habitRepository
        )
    }
    
    func makeAttemptsHistoryViewModel() -> AttemptsHistoryViewModel {
        AttemptsHistoryViewModel(
            gameAttemptRepository: gameAttemptRepository,
            lifePointRepository: lifePointRepository,
            forceResetUseCase: forceResetCurrentAttemptUseCase,
            deleteGameAttemptUseCase: deleteGameAttemptUseCase
        )
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
        
        // Настраиваем связи между репозиториями
        // Нужно вызвать после инициализации lazy свойств
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.habitRepository.setGameAttemptRepository(self.gameAttemptRepository)
            self.lifePointRepository.setGameAttemptRepository(self.gameAttemptRepository)
        }
    }
}

