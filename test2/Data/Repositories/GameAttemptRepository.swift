//
//  GameAttemptRepository.swift
//  test2
//
//  Created by Arkadiy on 19.01.2026.
//

import Foundation
import CoreData

protocol GameAttemptRepositoryProtocol {
    func getActiveAttempt() -> GameAttemptModel?
    func getAllAttempts() -> [GameAttemptModel]
    func createAttempt(_ attempt: GameAttemptModel) throws
    func updateAttempt(_ attempt: GameAttemptModel) throws
    func getAttemptById(_ id: UUID) -> GameAttemptModel?
    func deleteAttempt(_ id: UUID) throws
}

class GameAttemptRepository: GameAttemptRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getActiveAttempt() -> GameAttemptModel? {
        let request: NSFetchRequest<GameAttempt> = GameAttempt.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.fetchLimit = 1
        
        do {
            if let attempt = try context.fetch(request).first {
                return mapToModel(attempt)
            }
            return nil
        } catch {
            print("Error fetching active attempt: \(error)")
            return nil
        }
    }
    
    func getAllAttempts() -> [GameAttemptModel] {
        let request: NSFetchRequest<GameAttempt> = GameAttempt.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \GameAttempt.startDate, ascending: false)]
        
        do {
            let attempts = try context.fetch(request)
            return attempts.compactMap { mapToModel($0) }
        } catch {
            print("Error fetching all attempts: \(error)")
            return []
        }
    }
    
    func createAttempt(_ attempt: GameAttemptModel) throws {
        let attemptEntity = GameAttempt(context: context)
        attemptEntity.id = attempt.id
        attemptEntity.startDate = attempt.startDate
        attemptEntity.endDate = attempt.endDate
        attemptEntity.startingLives = Int16(attempt.startingLives)
        attemptEntity.endingLives = attempt.endingLives != nil ? Int16(attempt.endingLives!) : 0
        attemptEntity.isActive = attempt.isActive
        
        try context.save()
    }
    
    func updateAttempt(_ attempt: GameAttemptModel) throws {
        let request: NSFetchRequest<GameAttempt> = GameAttempt.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", attempt.id as CVarArg)
        
        if let attemptEntity = try context.fetch(request).first {
            attemptEntity.endDate = attempt.endDate
            attemptEntity.endingLives = attempt.endingLives != nil ? Int16(attempt.endingLives!) : 0
            attemptEntity.isActive = attempt.isActive
            
            try context.save()
        }
    }
    
    func getAttemptById(_ id: UUID) -> GameAttemptModel? {
        let request: NSFetchRequest<GameAttempt> = GameAttempt.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            if let attempt = try context.fetch(request).first {
                return mapToModel(attempt)
            }
            return nil
        } catch {
            print("Error fetching attempt by id: \(error)")
            return nil
        }
    }
    
    func deleteAttempt(_ id: UUID) throws {
        let request: NSFetchRequest<GameAttempt> = GameAttempt.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let attempts = try context.fetch(request)
            for attempt in attempts {
                context.delete(attempt)
            }
            try context.save()
            print("Deleted attempt with id: \(id)")
        } catch {
            print("Error deleting attempt: \(error)")
            throw error
        }
    }
    
    private func mapToModel(_ entity: GameAttempt) -> GameAttemptModel? {
        guard let id = entity.id,
              let startDate = entity.startDate else {
            return nil
        }
        
        // Если попытка завершена (не активна и есть endDate), endingLives может быть 0
        // Если попытка активна, endingLives должно быть nil
        let endingLives: Int?
        if entity.isActive {
            endingLives = nil // Активная попытка - еще нет конечных жизней
        } else {
            // Завершенная попытка - всегда показываем endingLives, даже если 0
            endingLives = Int(entity.endingLives)
        }
        
        return GameAttemptModel(
            id: id,
            startDate: startDate,
            endDate: entity.endDate,
            startingLives: Int(entity.startingLives),
            endingLives: endingLives,
            isActive: entity.isActive
        )
    }
}
