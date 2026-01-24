//
//  ResetGameUseCase.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

protocol ResetGameUseCaseProtocol {
    func execute() throws
}

class ResetGameUseCase: ResetGameUseCaseProtocol {
    private let gameStateRepository: GameStateRepositoryProtocol
    private let gameAttemptRepository: GameAttemptRepositoryProtocol
    private let lifePointRepository: LifePointRepositoryProtocol
    
    init(gameStateRepository: GameStateRepositoryProtocol,
         gameAttemptRepository: GameAttemptRepositoryProtocol,
         lifePointRepository: LifePointRepositoryProtocol) {
        self.gameStateRepository = gameStateRepository
        self.gameAttemptRepository = gameAttemptRepository
        self.lifePointRepository = lifePointRepository
    }
    
    func execute() throws {
        // 1. Завершаем текущую попытку (если есть)
        if let activeAttempt = gameAttemptRepository.getActiveAttempt() {
            let currentGameState = gameStateRepository.getGameState()
            let endingLives = currentGameState?.currentLives ?? 0
            
            let completedAttempt = GameAttemptModel(
                id: activeAttempt.id,
                startDate: activeAttempt.startDate,
                endDate: Date(),
                startingLives: activeAttempt.startingLives,
                endingLives: endingLives,
                isActive: false
            )
            try gameAttemptRepository.updateAttempt(completedAttempt)
        }
        
        // 2. Создаем новую попытку
        let newAttempt = GameAttemptModel(
            id: UUID(),
            startDate: Date(),
            endDate: nil,
            startingLives: 100,
            endingLives: nil,
            isActive: true
        )
        try gameAttemptRepository.createAttempt(newAttempt)
        
        // 3. Сбрасываем состояние игры
        let resetState = GameStateModel(
            currentLives: 100,
            isGameOver: false,
            lastWeekCalculationDate: nil,
            updatedAt: Date()
        )
        try gameStateRepository.saveGameState(resetState)
        
        // Примечание: Привычки НЕ удаляются, они остаются те же самые
        // Старые completions остаются связанными со старой попыткой
        // Новые completions будут автоматически связываться с новой активной попыткой
    }
}



