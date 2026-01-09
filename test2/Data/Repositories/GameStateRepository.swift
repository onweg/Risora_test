//
//  GameStateRepository.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import CoreData

protocol GameStateRepositoryProtocol {
    func getGameState() -> GameStateModel?
    func saveGameState(_ gameState: GameStateModel) throws
    func initializeGameState() throws
}

class GameStateRepository: GameStateRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getGameState() -> GameStateModel? {
        let request: NSFetchRequest<GameState> = GameState.fetchRequest()
        request.fetchLimit = 1
        
        do {
            if let state = try context.fetch(request).first,
               let id = state.id {
                return GameStateModel(
                    currentLives: Int(state.currentLives),
                    isGameOver: state.isGameOver,
                    lastWeekCalculationDate: state.lastWeekCalculationDate,
                    updatedAt: state.updatedAt ?? Date()
                )
            }
            return nil
        } catch {
            print("Error fetching game state: \(error)")
            return nil
        }
    }
    
    func saveGameState(_ gameState: GameStateModel) throws {
        let request: NSFetchRequest<GameState> = GameState.fetchRequest()
        request.fetchLimit = 1
        
        let state: GameState
        if let existing = try context.fetch(request).first {
            state = existing
        } else {
            state = GameState(context: context)
            state.id = UUID()
        }
        
        state.currentLives = Int16(gameState.currentLives)
        state.isGameOver = gameState.isGameOver
        state.lastWeekCalculationDate = gameState.lastWeekCalculationDate
        state.updatedAt = gameState.updatedAt
        
        try context.save()
    }
    
    func initializeGameState() throws {
        if getGameState() == nil {
            let initialState = GameStateModel(
                currentLives: 100,
                isGameOver: false,
                lastWeekCalculationDate: nil,
                updatedAt: Date()
            )
            try saveGameState(initialState)
        }
    }
}



