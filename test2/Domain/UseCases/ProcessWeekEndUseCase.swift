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
    
    init(
        calculateWeeklyLifePointsUseCase: CalculateWeeklyLifePointsUseCaseProtocol,
        calculateDailyLifePointsUseCase: CalculateDailyLifePointsUseCaseProtocol,
        gameStateRepository: GameStateRepositoryProtocol,
        lifePointRepository: LifePointRepositoryProtocol
    ) {
        self.calculateWeeklyLifePointsUseCase = calculateWeeklyLifePointsUseCase
        self.calculateDailyLifePointsUseCase = calculateDailyLifePointsUseCase
        self.gameStateRepository = gameStateRepository
        self.lifePointRepository = lifePointRepository
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
        
        // Создаем новое состояние игры с обновленными значениями
        let updatedGameState = GameStateModel(
            currentLives: max(0, currentGameState.currentLives + xpChange),
            isGameOver: currentGameState.isGameOver,
            lastWeekCalculationDate: weekEndDate,
            updatedAt: Date()
        )
        
        // Сохраняем состояние игры
        try gameStateRepository.saveGameState(updatedGameState)
    }
}

