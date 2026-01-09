//
//  CheckGameOverUseCase.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

protocol CheckGameOverUseCaseProtocol {
    func execute() -> Bool
}

class CheckGameOverUseCase: CheckGameOverUseCaseProtocol {
    private let gameStateRepository: GameStateRepositoryProtocol
    
    init(gameStateRepository: GameStateRepositoryProtocol) {
        self.gameStateRepository = gameStateRepository
    }
    
    func execute() -> Bool {
        guard let gameState = gameStateRepository.getGameState() else {
            return false
        }
        return gameState.isGameOver || gameState.currentLives <= 0
    }
}



