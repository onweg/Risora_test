//
//  LifePointsChartViewModel.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import SwiftUI

@MainActor
class LifePointsChartViewModel: ObservableObject {
    @Published var lifePoints: [LifePointModel] = []
    @Published var currentLives: Int = 100
    
    private let lifePointRepository: LifePointRepositoryProtocol
    private let gameStateRepository: GameStateRepositoryProtocol
    
    nonisolated init(
        lifePointRepository: LifePointRepositoryProtocol,
        gameStateRepository: GameStateRepositoryProtocol
    ) {
        self.lifePointRepository = lifePointRepository
        self.gameStateRepository = gameStateRepository
        
        Task { @MainActor in
            self.loadData()
        }
    }
    
    func loadData() {
        lifePoints = lifePointRepository.getAllLifePoints()
        
        if let gameState = gameStateRepository.getGameState() {
            currentLives = gameState.currentLives
        }
    }
    
    func refresh() {
        loadData()
    }
}

