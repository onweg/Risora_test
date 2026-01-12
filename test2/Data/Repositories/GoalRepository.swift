//
//  GoalRepository.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import CoreData

protocol GoalRepositoryProtocol {
    func getAllGoals() -> [GoalModel]
    func createGoal(_ goal: GoalModel) throws
    func updateGoal(_ goal: GoalModel) throws
    func deleteGoal(_ id: UUID) throws
    func updateGoalOrder(goalIds: [UUID]) throws
    func removeHabitFromGoals(_ habitId: UUID) throws // Удаляет связь с привычкой из всех целей
    func cleanupOrphanedHabitReferences(existingHabitIds: [UUID]) throws // Очищает ссылки на несуществующие привычки
}

class GoalRepository: GoalRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getAllGoals() -> [GoalModel] {
        let request: NSFetchRequest<Goal> = Goal.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Goal.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Goal.createdAt, ascending: true)
        ]
        
        do {
            let goals = try context.fetch(request)
            return goals.compactMap { goal in
                GoalModel(
                    id: goal.id ?? UUID(),
                    title: goal.title ?? "",
                    motivation: goal.motivation ?? "",
                    relatedHabitIds: parseHabitIds(from: goal.relatedHabitIds),
                    createdAt: goal.createdAt ?? Date(),
                    sortOrder: Int(goal.sortOrder)
                )
            }
        } catch {
            print("Error fetching goals: \(error)")
            return []
        }
    }
    
    func createGoal(_ goal: GoalModel) throws {
        // Определяем максимальный sortOrder для новой цели
        let request: NSFetchRequest<Goal> = Goal.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Goal.sortOrder, ascending: false)]
        request.fetchLimit = 1
        
        var maxSortOrder = 0
        if let lastGoal = try? context.fetch(request).first {
            maxSortOrder = Int(lastGoal.sortOrder)
        }
        
        let goalEntity = Goal(context: context)
        goalEntity.id = goal.id
        goalEntity.title = goal.title
        goalEntity.motivation = goal.motivation
        goalEntity.relatedHabitIds = formatHabitIds(goal.relatedHabitIds)
        goalEntity.createdAt = goal.createdAt
        goalEntity.sortOrder = Int32(maxSortOrder + 1)
        
        try context.save()
    }
    
    func updateGoal(_ goal: GoalModel) throws {
        let request: NSFetchRequest<Goal> = Goal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", goal.id as CVarArg)
        
        guard let goalEntity = try context.fetch(request).first else {
            throw NSError(domain: "GoalRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Goal not found"])
        }
        
        goalEntity.title = goal.title
        goalEntity.motivation = goal.motivation
        goalEntity.relatedHabitIds = formatHabitIds(goal.relatedHabitIds)
        goalEntity.sortOrder = Int32(goal.sortOrder)
        
        try context.save()
    }
    
    func deleteGoal(_ id: UUID) throws {
        let request: NSFetchRequest<Goal> = Goal.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let goal = try context.fetch(request).first {
            context.delete(goal)
            try context.save()
        }
    }
    
    func updateGoalOrder(goalIds: [UUID]) throws {
        // Обновляем sortOrder для всех целей согласно новому порядку
        for (index, goalId) in goalIds.enumerated() {
            let request: NSFetchRequest<Goal> = Goal.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", goalId as CVarArg)
            
            if let goal = try context.fetch(request).first {
                goal.sortOrder = Int32(index)
            }
        }
        
        try context.save()
    }
    
    func removeHabitFromGoals(_ habitId: UUID) throws {
        // Находим все цели, которые связаны с этой привычкой
        let request: NSFetchRequest<Goal> = Goal.fetchRequest()
        let goals = try context.fetch(request)
        
        var hasChanges = false
        
        for goal in goals {
            let habitIds = parseHabitIds(from: goal.relatedHabitIds)
            if habitIds.contains(habitId) {
                // Удаляем ID привычки из списка
                let updatedHabitIds = habitIds.filter { $0 != habitId }
                goal.relatedHabitIds = formatHabitIds(updatedHabitIds)
                hasChanges = true
            }
        }
        
        if hasChanges {
            try context.save()
        }
    }
    
    func cleanupOrphanedHabitReferences(existingHabitIds: [UUID]) throws {
        // Очищаем ссылки на несуществующие привычки из всех целей
        let request: NSFetchRequest<Goal> = Goal.fetchRequest()
        let goals = try context.fetch(request)
        let existingIdsSet = Set(existingHabitIds)
        
        var hasChanges = false
        
        for goal in goals {
            let habitIds = parseHabitIds(from: goal.relatedHabitIds)
            let validHabitIds = habitIds.filter { existingIdsSet.contains($0) }
            
            if validHabitIds.count != habitIds.count {
                // Есть несуществующие привычки, обновляем список
                goal.relatedHabitIds = formatHabitIds(validHabitIds)
                hasChanges = true
            }
        }
        
        if hasChanges {
            try context.save()
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseHabitIds(from string: String?) -> [UUID] {
        guard let string = string, !string.isEmpty else { return [] }
        return string.components(separatedBy: ",")
            .compactMap { UUID(uuidString: $0.trimmingCharacters(in: .whitespaces)) }
    }
    
    private func formatHabitIds(_ ids: [UUID]) -> String {
        ids.map { $0.uuidString }.joined(separator: ",")
    }
}
