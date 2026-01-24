//
//  GoalsViewModel.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import SwiftUI

@MainActor
class GoalsViewModel: ObservableObject {
    @Published var goals: [GoalModel] = []
    @Published var showingAddGoal = false
    @Published var showingDeleteGoalConfirmation = false
    @Published var goalToDelete: (id: UUID, title: String)? = nil
    
    private let goalRepository: GoalRepositoryProtocol
    private let habitRepository: HabitRepositoryProtocol
    
    nonisolated init(
        goalRepository: GoalRepositoryProtocol,
        habitRepository: HabitRepositoryProtocol
    ) {
        self.goalRepository = goalRepository
        self.habitRepository = habitRepository
        
        Task { @MainActor in
            self.loadData()
        }
    }
    
    func loadData() {
        // Очищаем устаревшие ссылки на привычки перед загрузкой
        let existingHabitIds = habitRepository.getAllHabits().map { $0.id }
        do {
            try goalRepository.cleanupOrphanedHabitReferences(existingHabitIds: existingHabitIds)
        } catch {
            print("Error cleaning up orphaned habit references: \(error)")
        }
        
        goals = goalRepository.getAllGoals()
        
        // ВСЕГДА обновляем данные для виджета (даже если целей нет - очистим старые данные)
        print("📱 GoalsViewModel: Loading goals, count = \(goals.count)")
        if !goals.isEmpty {
            print("📱 GoalsViewModel: Updating widget with \(goals.count) goals")
            WidgetDataService.shared.updateWidgetWithNextGoal(goals: goals, habitRepository: habitRepository)
        } else {
            print("⚠️ GoalsViewModel: No goals found - widget will show placeholder")
        }
    }
    
    func createGoal(title: String, motivation: String, relatedHabitIds: [UUID]) {
        do {
            let goal = GoalModel(
                title: title,
                motivation: motivation,
                relatedHabitIds: relatedHabitIds
            )
            try goalRepository.createGoal(goal)
            loadData()
            // Обновляем виджет после создания новой цели
            if !goals.isEmpty {
                WidgetDataService.shared.updateWidgetWithNextGoal(goals: goals, habitRepository: habitRepository)
            }
        } catch {
            print("Error creating goal: \(error)")
        }
    }
    
    func updateGoal(_ goal: GoalModel) {
        do {
            try goalRepository.updateGoal(goal)
            loadData()
        } catch {
            print("Error updating goal: \(error)")
        }
    }
    
    func showDeleteGoalConfirmation(_ goalId: UUID, goalTitle: String) {
        goalToDelete = (id: goalId, title: goalTitle)
        showingDeleteGoalConfirmation = true
    }
    
    func deleteGoal(_ goalId: UUID) {
        do {
            try goalRepository.deleteGoal(goalId)
            loadData()
            goalToDelete = nil
        } catch {
            print("Error deleting goal: \(error)")
        }
    }
    
    func moveGoal(from source: IndexSet, to destination: Int) {
        var updatedGoals = goals
        updatedGoals.move(fromOffsets: source, toOffset: destination)
        
        // Обновляем порядок в репозитории
        let goalIds = updatedGoals.map { $0.id }
        do {
            try goalRepository.updateGoalOrder(goalIds: goalIds)
            loadData()
        } catch {
            print("Error updating goal order: \(error)")
        }
    }
    
    func getHabitName(for habitId: UUID) -> String {
        let allHabits = habitRepository.getAllHabits()
        return allHabits.first(where: { $0.id == habitId })?.name ?? "Неизвестная привычка"
    }
    
    func habitExists(_ habitId: UUID) -> Bool {
        let allHabits = habitRepository.getAllHabits()
        return allHabits.contains(where: { $0.id == habitId })
    }
    
    func getAllHabits() -> [HabitModel] {
        return habitRepository.getAllHabits()
    }
    
    func getExistingHabitIds(from habitIds: [UUID]) -> [UUID] {
        return habitIds.filter { habitExists($0) }
    }
    
    func refresh() {
        loadData()
    }
}
