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
        let repo = HabitRepository(context: context)
        repo.setGameAttemptRepository(gameAttemptRepository)
        return repo
    }()
    
    lazy var lifePointRepository: LifePointRepositoryProtocol = {
        let repo = LifePointRepository(context: context)
        repo.setGameAttemptRepository(gameAttemptRepository)
        return repo
    }()
    
    lazy var gameStateRepository: GameStateRepositoryProtocol = {
        GameStateRepository(context: context)
    }()
    
    lazy var goalRepository: GoalRepositoryProtocol = {
        GoalRepository(context: context)
    }()
    
    lazy var themeRepository: ThemeRepositoryProtocol = {
        ThemeRepository(context: context)
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

    lazy var deleteAllHabitsUseCase: DeleteAllHabitsUseCaseProtocol = {
        DeleteAllHabitsUseCase(habitRepository: habitRepository, goalRepository: goalRepository)
    }()

    lazy var deleteHabitUseCase: DeleteHabitUseCaseProtocol = {
        DeleteHabitUseCase(habitRepository: habitRepository, goalRepository: goalRepository)
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
    
    // ViewModels
    func makeHabitsListViewModel() -> HabitsListViewModel {
        HabitsListViewModel(
            getHabitsForDayUseCase: getHabitsForDayUseCase,
            completeHabitUseCase: completeHabitUseCase,
            setHabitCompletionCountUseCase: setHabitCompletionCountUseCase,
            removeHabitCompletionUseCase: removeHabitCompletionUseCase,
            deleteHabitCompletionsUseCase: deleteHabitCompletionsUseCase,
            deleteAllHabitsUseCase: deleteAllHabitsUseCase,
            deleteHabitUseCase: deleteHabitUseCase,
            habitRepository: habitRepository,
            themeRepository: themeRepository,
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
            gameAttemptRepository: gameAttemptRepository,
            calculateDailyLifePointsUseCase: calculateDailyLifePointsUseCase,
            getWeeklyHabitAnalysisUseCase: getWeeklyHabitAnalysisUseCase,
            processWeekEndUseCase: processWeekEndUseCase,
            processAllMissedWeeksUseCase: processAllMissedWeeksUseCase
        )
    }
    
    func makeAddHabitViewModel(editingHabit: HabitModel? = nil) -> AddHabitViewModel {
        AddHabitViewModel(habitRepository: habitRepository, themeRepository: themeRepository, editingHabit: editingHabit)
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
            getWeeklyHabitAnalysisUseCase: getWeeklyHabitAnalysisUseCase
        )
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

