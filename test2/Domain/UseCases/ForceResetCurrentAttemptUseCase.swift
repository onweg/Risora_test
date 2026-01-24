//
//  ForceResetCurrentAttemptUseCase.swift
//  test2
//
//  Created by Arkadiy on 19.01.2026.
//

import Foundation

protocol ForceResetCurrentAttemptUseCaseProtocol {
    func execute() throws
}

/// UseCase для принудительного сброса текущего состояния
/// Используется когда нужно "починить" неправильное состояние игры
class ForceResetCurrentAttemptUseCase: ForceResetCurrentAttemptUseCaseProtocol {
    private let gameStateRepository: GameStateRepositoryProtocol
    private let gameAttemptRepository: GameAttemptRepositoryProtocol
    
    init(gameStateRepository: GameStateRepositoryProtocol,
         gameAttemptRepository: GameAttemptRepositoryProtocol) {
        self.gameStateRepository = gameStateRepository
        self.gameAttemptRepository = gameAttemptRepository
    }
    
    func execute() throws {
        // Получаем активную попытку
        guard let activeAttempt = gameAttemptRepository.getActiveAttempt() else {
            throw NSError(domain: "ForceReset", code: 404, userInfo: [NSLocalizedDescriptionKey: "No active attempt found"])
        }
        
        // Сбрасываем состояние игры на начальное для этой попытки
        let resetState = GameStateModel(
            currentLives: activeAttempt.startingLives,
            isGameOver: false,
            lastWeekCalculationDate: nil, // ВАЖНО: обнуляем чтобы не считать старые недели
            updatedAt: Date()
        )
        
        try gameStateRepository.saveGameState(resetState)
        
        print("Force reset completed: lives restored to \(activeAttempt.startingLives), lastWeekCalculationDate cleared")
    }
}
