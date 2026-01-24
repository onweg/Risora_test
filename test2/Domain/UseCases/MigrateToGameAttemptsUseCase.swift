//
//  MigrateToGameAttemptsUseCase.swift
//  test2
//
//  Created by Arkadiy on 19.01.2026.
//

import Foundation
import CoreData

protocol MigrateToGameAttemptsUseCaseProtocol {
    func execute() throws
}

class MigrateToGameAttemptsUseCase: MigrateToGameAttemptsUseCaseProtocol {
    private let context: NSManagedObjectContext
    private let gameAttemptRepository: GameAttemptRepositoryProtocol
    private let gameStateRepository: GameStateRepositoryProtocol
    
    init(context: NSManagedObjectContext,
         gameAttemptRepository: GameAttemptRepositoryProtocol,
         gameStateRepository: GameStateRepositoryProtocol) {
        self.context = context
        self.gameAttemptRepository = gameAttemptRepository
        self.gameStateRepository = gameStateRepository
    }
    
    func execute() throws {
        // Проверяем, есть ли уже активная попытка
        if gameAttemptRepository.getActiveAttempt() != nil {
            print("Migration already done, active attempt exists")
            return
        }
        
        // Проверяем, есть ли старые данные для миграции
        let hasOldData = try checkForOldData()
        
        if hasOldData {
            print("Migrating old data to new GameAttempt structure...")
            try migrateOldData()
        } else {
            print("No old data found, creating initial attempt...")
            try createInitialAttempt()
        }
    }
    
    private func checkForOldData() throws -> Bool {
        // Проверяем наличие старых completions или lifePoints без gameAttempt
        let completionRequest: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        completionRequest.predicate = NSPredicate(format: "gameAttempt == nil")
        completionRequest.fetchLimit = 1
        
        let lifePointRequest: NSFetchRequest<LifePoint> = LifePoint.fetchRequest()
        lifePointRequest.predicate = NSPredicate(format: "gameAttempt == nil")
        lifePointRequest.fetchLimit = 1
        
        let hasCompletions = try context.fetch(completionRequest).count > 0
        let hasLifePoints = try context.fetch(lifePointRequest).count > 0
        
        return hasCompletions || hasLifePoints
    }
    
    private func migrateOldData() throws {
        // Находим самую раннюю дату из completions и lifePoints
        let earliestDate = try findEarliestDate()
        
        // Получаем текущее состояние игры
        let gameState = gameStateRepository.getGameState()
        let currentLives = gameState?.currentLives ?? 100
        let isGameOver = gameState?.isGameOver ?? false
        
        if isGameOver {
            // Если игра окончена, создаем завершенную попытку для старых данных
            let completedAttempt = GameAttemptModel(
                id: UUID(),
                startDate: earliestDate ?? Date(),
                endDate: Date(),
                startingLives: 100,
                endingLives: currentLives,
                isActive: false
            )
            
            try gameAttemptRepository.createAttempt(completedAttempt)
            
            // Связываем все существующие данные с завершенной попыткой
            try linkCompletionsToAttempt(attemptId: completedAttempt.id)
            try linkLifePointsToAttempt(attemptId: completedAttempt.id)
            
            // Создаем новую активную попытку для продолжения игры
            let newAttempt = GameAttemptModel(
                id: UUID(),
                startDate: Date(),
                endDate: nil,
                startingLives: 100,
                endingLives: nil,
                isActive: true
            )
            
            try gameAttemptRepository.createAttempt(newAttempt)
            
            // Сбрасываем состояние игры
            let resetState = GameStateModel(
                currentLives: 100,
                isGameOver: false,
                lastWeekCalculationDate: nil,
                updatedAt: Date()
            )
            try gameStateRepository.saveGameState(resetState)
            
            print("Migration completed: old attempt saved, new attempt created with 100 lives")
        } else {
            // Если игра активна, создаем активную попытку для существующих данных
            let attempt = GameAttemptModel(
                id: UUID(),
                startDate: earliestDate ?? Date(),
                endDate: nil,
                startingLives: 100,
                endingLives: nil,
                isActive: true
            )
            
            try gameAttemptRepository.createAttempt(attempt)
            
            // Связываем все существующие completions с этой попыткой
            try linkCompletionsToAttempt(attemptId: attempt.id)
            
            // Связываем все существующие lifePoints с этой попыткой
            try linkLifePointsToAttempt(attemptId: attempt.id)
            
            print("Migration completed successfully")
        }
    }
    
    private func createInitialAttempt() throws {
        // Создаем начальную попытку
        let gameState = gameStateRepository.getGameState()
        let currentLives = gameState?.currentLives ?? 100
        let isGameOver = gameState?.isGameOver ?? false
        
        let attempt = GameAttemptModel(
            id: UUID(),
            startDate: Date(),
            endDate: nil,
            startingLives: currentLives,
            endingLives: nil,
            isActive: true
        )
        
        try gameAttemptRepository.createAttempt(attempt)
        print("Initial attempt created successfully")
    }
    
    private func findEarliestDate() throws -> Date? {
        // Ищем самую раннюю дату среди completions
        let completionRequest: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        completionRequest.sortDescriptors = [NSSortDescriptor(keyPath: \HabitCompletion.date, ascending: true)]
        completionRequest.fetchLimit = 1
        let earliestCompletion = try context.fetch(completionRequest).first?.date
        
        // Ищем самую раннюю дату среди lifePoints
        let lifePointRequest: NSFetchRequest<LifePoint> = LifePoint.fetchRequest()
        lifePointRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LifePoint.date, ascending: true)]
        lifePointRequest.fetchLimit = 1
        let earliestLifePoint = try context.fetch(lifePointRequest).first?.date
        
        // Возвращаем самую раннюю из найденных дат
        if let completion = earliestCompletion, let lifePoint = earliestLifePoint {
            return min(completion, lifePoint)
        }
        return earliestCompletion ?? earliestLifePoint
    }
    
    private func linkCompletionsToAttempt(attemptId: UUID) throws {
        let completionRequest: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        completionRequest.predicate = NSPredicate(format: "gameAttempt == nil")
        
        let completions = try context.fetch(completionRequest)
        
        // Получаем GameAttempt entity
        let attemptRequest: NSFetchRequest<GameAttempt> = GameAttempt.fetchRequest()
        attemptRequest.predicate = NSPredicate(format: "id == %@", attemptId as CVarArg)
        guard let attemptEntity = try context.fetch(attemptRequest).first else {
            throw NSError(domain: "Migration", code: 404, userInfo: [NSLocalizedDescriptionKey: "GameAttempt not found"])
        }
        
        // Связываем все completions с попыткой
        for completion in completions {
            completion.gameAttempt = attemptEntity
        }
        
        try context.save()
        print("Linked \(completions.count) completions to attempt")
    }
    
    private func linkLifePointsToAttempt(attemptId: UUID) throws {
        let lifePointRequest: NSFetchRequest<LifePoint> = LifePoint.fetchRequest()
        lifePointRequest.predicate = NSPredicate(format: "gameAttempt == nil")
        
        let lifePoints = try context.fetch(lifePointRequest)
        
        // Получаем GameAttempt entity
        let attemptRequest: NSFetchRequest<GameAttempt> = GameAttempt.fetchRequest()
        attemptRequest.predicate = NSPredicate(format: "id == %@", attemptId as CVarArg)
        guard let attemptEntity = try context.fetch(attemptRequest).first else {
            throw NSError(domain: "Migration", code: 404, userInfo: [NSLocalizedDescriptionKey: "GameAttempt not found"])
        }
        
        // Связываем все lifePoints с попыткой
        for lifePoint in lifePoints {
            lifePoint.gameAttempt = attemptEntity
        }
        
        try context.save()
        print("Linked \(lifePoints.count) life points to attempt")
    }
}
