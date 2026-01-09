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
    private let gameStateRepository: GameStateRepositoryProtocol
    private let lifePointRepository: LifePointRepositoryProtocol
    
    init(
        calculateWeeklyLifePointsUseCase: CalculateWeeklyLifePointsUseCaseProtocol,
        gameStateRepository: GameStateRepositoryProtocol,
        lifePointRepository: LifePointRepositoryProtocol
    ) {
        self.calculateWeeklyLifePointsUseCase = calculateWeeklyLifePointsUseCase
        self.gameStateRepository = gameStateRepository
        self.lifePointRepository = lifePointRepository
    }
    
    func execute(weekStartDate: Date) throws {
        // Вычисляем изменение жизненных очков за неделю
        let xpChange = try calculateWeeklyLifePointsUseCase.execute(weekStartDate: weekStartDate)
        
        // Получаем текущее состояние игры
        guard let currentGameState = gameStateRepository.getGameState() else {
            throw NSError(domain: "ProcessWeekEndUseCase", code: 404, userInfo: [NSLocalizedDescriptionKey: "Game state not found"])
        }
        
        // Обновляем жизненные очки
        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        
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

