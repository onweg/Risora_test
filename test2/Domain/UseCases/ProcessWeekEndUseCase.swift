//
//  ProcessWeekEndUseCase.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

protocol ProcessWeekEndUseCaseProtocol {
    func execute(weekStartDate: Date) throws
}

class ProcessWeekEndUseCase: ProcessWeekEndUseCaseProtocol {
    private let calculateWeeklyLifePointsUseCase: CalculateWeeklyLifePointsUseCaseProtocol
    private let calculateDailyLifePointsUseCase: CalculateDailyLifePointsUseCaseProtocol
    private let gameStateRepository: GameStateRepositoryProtocol
    private let lifePointRepository: LifePointRepositoryProtocol
    private let gameAttemptRepository: GameAttemptRepositoryProtocol
    
    init(
        calculateWeeklyLifePointsUseCase: CalculateWeeklyLifePointsUseCaseProtocol,
        calculateDailyLifePointsUseCase: CalculateDailyLifePointsUseCaseProtocol,
        gameStateRepository: GameStateRepositoryProtocol,
        lifePointRepository: LifePointRepositoryProtocol,
        gameAttemptRepository: GameAttemptRepositoryProtocol
    ) {
        self.calculateWeeklyLifePointsUseCase = calculateWeeklyLifePointsUseCase
        self.calculateDailyLifePointsUseCase = calculateDailyLifePointsUseCase
        self.gameStateRepository = gameStateRepository
        self.lifePointRepository = lifePointRepository
        self.gameAttemptRepository = gameAttemptRepository
    }
    
    func execute(weekStartDate: Date) throws {
        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        
        // Сначала обрабатываем дневные привычки за каждый день недели
        var totalDailyXP = 0
        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }
            let dailyXP = try calculateDailyLifePointsUseCase.execute(date: day)
            totalDailyXP += dailyXP
        }
        
        // Затем обрабатываем недельные привычки (в конце недели)
        let weeklyXP = try calculateWeeklyLifePointsUseCase.execute(weekStartDate: weekStartDate)
        
        // Общее изменение за неделю
        let xpChange = totalDailyXP + weeklyXP
        
        // Получаем текущее состояние игры
        guard let currentGameState = gameStateRepository.getGameState() else {
            throw NSError(domain: "ProcessWeekEndUseCase", code: 404, userInfo: [NSLocalizedDescriptionKey: "Game state not found"])
        }
        
        
        // Сохраняем жизненные очки за неделю
        let lifePoint = LifePointModel(
            id: UUID(),
            date: weekEndDate,
            value: xpChange,
            weekStartDate: weekStartDate
        )
        try lifePointRepository.saveLifePoint(lifePoint)
        
        // Вычисляем новое количество жизней
        let newLives = max(0, currentGameState.currentLives + xpChange)
        
        // Проверяем game over: если жизни упали до 0 или ниже
        let isGameOver = newLives <= 0
        
        // Если игра закончилась, завершаем текущую попытку
        if isGameOver {
            if let activeAttempt = gameAttemptRepository.getActiveAttempt() {
                let completedAttempt = GameAttemptModel(
                    id: activeAttempt.id,
                    startDate: activeAttempt.startDate,
                    endDate: weekEndDate,
                    startingLives: activeAttempt.startingLives,
                    endingLives: newLives, // Сохраняем 0 (или отрицательное значение)
                    isActive: false
                )
                try gameAttemptRepository.updateAttempt(completedAttempt)
            }
        }
        
        // Создаем новое состояние игры с обновленными значениями
        let updatedGameState = GameStateModel(
            currentLives: newLives,
            isGameOver: isGameOver,
            lastWeekCalculationDate: weekEndDate,
            updatedAt: Date()
        )
        
        // Сохраняем состояние игры
        try gameStateRepository.saveGameState(updatedGameState)
    }
}

