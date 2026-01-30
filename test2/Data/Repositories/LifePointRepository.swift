//
//  LifePointRepository.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import CoreData

protocol LifePointRepositoryProtocol {
    func getAllLifePoints() -> [LifePointModel]
    func saveLifePoint(_ lifePoint: LifePointModel) throws
    func getLifePointForWeek(weekStartDate: Date) -> LifePointModel?
    func setGameAttemptRepository(_ repository: GameAttemptRepositoryProtocol)
    func getLifePointsForAttempt(_ attemptId: UUID) -> [LifePointModel]
}

class LifePointRepository: LifePointRepositoryProtocol {
    private let context: NSManagedObjectContext
    private var gameAttemptRepository: GameAttemptRepositoryProtocol?
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func setGameAttemptRepository(_ repository: GameAttemptRepositoryProtocol) {
        self.gameAttemptRepository = repository
    }
    
    func getAllLifePoints() -> [LifePointModel] {
        let request: NSFetchRequest<LifePoint> = LifePoint.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LifePoint.date, ascending: true)]
        
        // Фильтруем по активной попытке
        if let activeAttempt = gameAttemptRepository?.getActiveAttempt() {
            request.predicate = NSPredicate(format: "gameAttempt.id == %@", activeAttempt.id as CVarArg)
        }
        
        do {
            let lifePoints = try context.fetch(request)
            return lifePoints.compactMap { lp in
                guard let id = lp.id,
                      let date = lp.date,
                      let weekStartDate = lp.weekStartDate else { return nil }
                
                return LifePointModel(
                    id: id,
                    date: date,
                    value: Int(lp.value),
                    weekStartDate: weekStartDate
                )
            }
        } catch {
            print("Error fetching life points: \(error)")
            return []
        }
    }
    
    func getLifePointsForAttempt(_ attemptId: UUID) -> [LifePointModel] {
        let request: NSFetchRequest<LifePoint> = LifePoint.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LifePoint.date, ascending: true)]
        request.predicate = NSPredicate(format: "gameAttempt.id == %@", attemptId as CVarArg)
        
        do {
            let lifePoints = try context.fetch(request)
            return lifePoints.compactMap { lp in
                guard let id = lp.id,
                      let date = lp.date,
                      let weekStartDate = lp.weekStartDate else { return nil }
                
                return LifePointModel(
                    id: id,
                    date: date,
                    value: Int(lp.value),
                    weekStartDate: weekStartDate
                )
            }
        } catch {
            print("Error fetching life points for attempt: \(error)")
            return []
        }
    }
    
    func saveLifePoint(_ lifePoint: LifePointModel) throws {
        // Проверяем, существует ли уже запись для этой недели
        if let existing = getLifePointForWeek(weekStartDate: lifePoint.weekStartDate) {
            let request: NSFetchRequest<LifePoint> = LifePoint.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", existing.id as CVarArg)
            
            if let lp = try context.fetch(request).first {
                lp.value = Int16(lifePoint.value)
                lp.date = lifePoint.date
            }
        } else {
            let lifePointEntity = LifePoint(context: context)
            lifePointEntity.id = lifePoint.id
            lifePointEntity.date = lifePoint.date
            lifePointEntity.value = Int16(lifePoint.value)
            lifePointEntity.weekStartDate = lifePoint.weekStartDate
            
            // Связываем с активной попыткой
            if let activeAttempt = gameAttemptRepository?.getActiveAttempt() {
                let request: NSFetchRequest<GameAttempt> = GameAttempt.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", activeAttempt.id as CVarArg)
                if let attemptEntity = try? context.fetch(request).first {
                    lifePointEntity.gameAttempt = attemptEntity
                }
            }
        }
        
        try context.save()
    }
    
    func getLifePointForWeek(weekStartDate: Date) -> LifePointModel? {
        let request: NSFetchRequest<LifePoint> = LifePoint.fetchRequest()
        
        // Фильтруем по активной попытке
        if let activeAttempt = gameAttemptRepository?.getActiveAttempt() {
            request.predicate = NSPredicate(
                format: "weekStartDate == %@ AND gameAttempt.id == %@",
                weekStartDate as NSDate,
                activeAttempt.id as CVarArg
            )
        } else {
        request.predicate = NSPredicate(format: "weekStartDate == %@", weekStartDate as NSDate)
        }
        
        do {
            if let lp = try context.fetch(request).first,
               let id = lp.id,
               let date = lp.date,
               let weekStart = lp.weekStartDate {
                return LifePointModel(
                    id: id,
                    date: date,
                    value: Int(lp.value),
                    weekStartDate: weekStart
                )
            }
            return nil
        } catch {
            print("Error fetching life point: \(error)")
            return nil
        }
    }
}


