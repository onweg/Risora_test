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
    
    init(gameStateRepository: GameStateRepositoryProtocol) {
        self.gameStateRepository = gameStateRepository
    }
    
    func execute() throws {
        let resetState = GameStateModel(
            currentLives: 100,
            isGameOver: false,
            lastWeekCalculationDate: nil,
            updatedAt: Date()
        )
        try gameStateRepository.saveGameState(resetState)
    }
}



