//
//  HabitsListViewModel.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import SwiftUI

@MainActor
class HabitsListViewModel: ObservableObject {
    @Published var habits: [(habit: HabitModel, isCompleted: Bool, completionCount: Int, weeklyCompletionCount: Int, canEdit: Bool, weeklyCompletionDates: [Date])] = []
    @Published var selectedDate: Date = Date()
    @Published var currentLives: Int = 100
    @Published var isGameOver: Bool = false
    @Published var weekDays: [Date] = []
    @Published var showingAddHabit: Bool = false
    @Published var showingDeleteHabitConfirmation: Bool = false
    @Published var habitToDelete: (id: UUID, name: String)? = nil
    
    private let getHabitsForDayUseCase: GetHabitsForDayUseCaseProtocol
    private let completeHabitUseCase: CompleteHabitUseCaseProtocol
    private let setHabitCompletionCountUseCase: SetHabitCompletionCountUseCaseProtocol
    private let removeHabitCompletionUseCase: RemoveHabitCompletionUseCaseProtocol
    private let deleteHabitCompletionsUseCase: DeleteHabitCompletionsUseCaseProtocol
    private let habitRepository: HabitRepositoryProtocol
    private let gameStateRepository: GameStateRepositoryProtocol
    private let processAllMissedWeeksUseCase: ProcessAllMissedWeeksUseCaseProtocol
    
    nonisolated init(
        getHabitsForDayUseCase: GetHabitsForDayUseCaseProtocol,
        completeHabitUseCase: CompleteHabitUseCaseProtocol,
        setHabitCompletionCountUseCase: SetHabitCompletionCountUseCaseProtocol,
        removeHabitCompletionUseCase: RemoveHabitCompletionUseCaseProtocol,
        deleteHabitCompletionsUseCase: DeleteHabitCompletionsUseCaseProtocol,
        habitRepository: HabitRepositoryProtocol,
        gameStateRepository: GameStateRepositoryProtocol,
        processAllMissedWeeksUseCase: ProcessAllMissedWeeksUseCaseProtocol
    ) {
        self.getHabitsForDayUseCase = getHabitsForDayUseCase
        self.completeHabitUseCase = completeHabitUseCase
        self.setHabitCompletionCountUseCase = setHabitCompletionCountUseCase
        self.removeHabitCompletionUseCase = removeHabitCompletionUseCase
        self.deleteHabitCompletionsUseCase = deleteHabitCompletionsUseCase
        self.habitRepository = habitRepository
        self.gameStateRepository = gameStateRepository
        self.processAllMissedWeeksUseCase = processAllMissedWeeksUseCase
        
        Task { @MainActor in
            self.setupWeekDays()
            self.loadData()
        }
    }
    
    private func setupWeekDays() {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        weekDays = (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
    }
    
    func loadData() {
        updateHabits()
        updateGameState()
        checkAndProcessWeekEnd()
    }
    
    func updateHabits() {
        habits = getHabitsForDayUseCase.execute(date: selectedDate)
    }
    
    func updateGameState() {
        if let gameState = gameStateRepository.getGameState() {
            currentLives = gameState.currentLives
            isGameOver = gameState.isGameOver
        }
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        updateHabits()
    }
    
    func toggleHabit(_ habitId: UUID) {
        do {
            try completeHabitUseCase.execute(habitId: habitId, date: selectedDate)
            updateHabits()
        } catch {
            print("Error toggling habit: \(error)")
        }
    }
    
    func setHabitCompletionCount(_ habitId: UUID, count: Int) {
        do {
            try setHabitCompletionCountUseCase.execute(habitId: habitId, date: selectedDate, targetCount: count)
            updateHabits()
        } catch {
            print("Error setting habit completion count: \(error)")
        }
    }
    
    func removeHabitCompletion(_ habitId: UUID) {
        do {
            try removeHabitCompletionUseCase.execute(habitId: habitId, date: selectedDate)
            updateHabits()
        } catch {
            print("Error removing habit completion: \(error)")
        }
    }
    
    func showDeleteHabitConfirmation(_ habitId: UUID, habitName: String) {
        habitToDelete = (id: habitId, name: habitName)
        showingDeleteHabitConfirmation = true
    }
    
    func deleteHabitCompletions(_ habitId: UUID) {
        do {
            try deleteHabitCompletionsUseCase.execute(habitId: habitId, date: selectedDate)
            updateHabits()
            habitToDelete = nil
        } catch {
            print("Error deleting habit completions: \(error)")
        }
    }
    
    func moveHabit(from source: IndexSet, to destination: Int) {
        var updatedHabits = habits
        updatedHabits.move(fromOffsets: source, toOffset: destination)
        
        // Обновляем порядок в репозитории
        let habitIds = updatedHabits.map { $0.habit.id }
        do {
            try habitRepository.updateHabitOrder(habitIds: habitIds)
            updateHabits()
        } catch {
            print("Error updating habit order: \(error)")
        }
    }
    
    func checkAndProcessWeekEnd() {
        do {
            try processAllMissedWeeksUseCase.execute()
            updateGameState()
        } catch {
            print("Error processing missed weeks: \(error)")
        }
    }
    
    func refresh() {
        loadData()
    }
}

