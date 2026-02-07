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
    @Published var showingDeleteAllHabitsConfirmation: Bool = false
    @Published var habitToHardDelete: (id: UUID, name: String)? = nil
    @Published var showingFutureDayAlert: Bool = false

    private let getHabitsForDayUseCase: GetHabitsForDayUseCaseProtocol
    private let completeHabitUseCase: CompleteHabitUseCaseProtocol
    private let setHabitCompletionCountUseCase: SetHabitCompletionCountUseCaseProtocol
    private let removeHabitCompletionUseCase: RemoveHabitCompletionUseCaseProtocol
    private let deleteHabitCompletionsUseCase: DeleteHabitCompletionsUseCaseProtocol
    private let deleteAllHabitsUseCase: DeleteAllHabitsUseCaseProtocol
    private let deleteHabitUseCase: DeleteHabitUseCaseProtocol
    private let habitRepository: HabitRepositoryProtocol
    private let themeRepository: ThemeRepositoryProtocol
    private let gameStateRepository: GameStateRepositoryProtocol
    private let processAllMissedWeeksUseCase: ProcessAllMissedWeeksUseCaseProtocol
    
    nonisolated init(
        getHabitsForDayUseCase: GetHabitsForDayUseCaseProtocol,
        completeHabitUseCase: CompleteHabitUseCaseProtocol,
        setHabitCompletionCountUseCase: SetHabitCompletionCountUseCaseProtocol,
        removeHabitCompletionUseCase: RemoveHabitCompletionUseCaseProtocol,
        deleteHabitCompletionsUseCase: DeleteHabitCompletionsUseCaseProtocol,
        deleteAllHabitsUseCase: DeleteAllHabitsUseCaseProtocol,
        deleteHabitUseCase: DeleteHabitUseCaseProtocol,
        habitRepository: HabitRepositoryProtocol,
        themeRepository: ThemeRepositoryProtocol,
        gameStateRepository: GameStateRepositoryProtocol,
        processAllMissedWeeksUseCase: ProcessAllMissedWeeksUseCaseProtocol
    ) {
        self.getHabitsForDayUseCase = getHabitsForDayUseCase
        self.completeHabitUseCase = completeHabitUseCase
        self.setHabitCompletionCountUseCase = setHabitCompletionCountUseCase
        self.removeHabitCompletionUseCase = removeHabitCompletionUseCase
        self.deleteHabitCompletionsUseCase = deleteHabitCompletionsUseCase
        self.deleteAllHabitsUseCase = deleteAllHabitsUseCase
        self.deleteHabitUseCase = deleteHabitUseCase
        self.habitRepository = habitRepository
        self.themeRepository = themeRepository
        self.gameStateRepository = gameStateRepository
        self.processAllMissedWeeksUseCase = processAllMissedWeeksUseCase
        
        Task { @MainActor in
            self.updateWeekDaysFromSelection()
            self.loadData()
        }
    }
    
    /// Строит weekDays по выбранной дате (неделя, в которой лежит selectedDate).
    private func updateWeekDaysFromSelection() {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
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
    
    /// Привычки и задачи на указанную дату (для календарного вида по дням).
    func habitsForDate(_ date: Date) -> [(habit: HabitModel, isCompleted: Bool, completionCount: Int, weeklyCompletionCount: Int, canEdit: Bool, weeklyCompletionDates: [Date])] {
        getHabitsForDayUseCase.execute(date: date)
    }
    
    func updateGameState() {
        if let gameState = gameStateRepository.getGameState() {
            currentLives = gameState.currentLives
            isGameOver = gameState.isGameOver
        }
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        updateWeekDaysFromSelection()
        updateHabits()
    }
    
    func goToPreviousWeek() {
        let calendar = Calendar.current
        selectedDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
        updateWeekDaysFromSelection()
        updateHabits()
    }
    
    func goToNextWeek() {
        let calendar = Calendar.current
        selectedDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate
        updateWeekDaysFromSelection()
        updateHabits()
    }
    
    func toggleHabit(_ habitId: UUID) {
        toggleHabit(habitId, date: selectedDate)
    }
    
    /// Вызывается после каждого выполнения/снятия выполнения привычки (чтобы обновить график).
    var onHabitToggled: (() -> Void)?

    func toggleHabit(_ habitId: UUID, date: Date) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let dateStart = calendar.startOfDay(for: date)

        let items = getHabitsForDayUseCase.execute(date: date)
        guard let item = items.first(where: { $0.habit.id == habitId }) else { return }

        // Пытаемся отметить как выполненное в будущий день — запрещаем
        if !item.isCompleted && dateStart > todayStart {
            showingFutureDayAlert = true
            return
        }

        do {
            if item.isCompleted {
                try habitRepository.uncompleteHabit(habitId, date: date)
            } else {
                try completeHabitUseCase.execute(habitId: habitId, date: date)
            }
            loadData()
            onHabitToggled?()
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

    func showDeleteAllHabitsConfirmation() {
        showingDeleteAllHabitsConfirmation = true
    }

    func deleteAllHabits() {
        do {
            try deleteAllHabitsUseCase.execute()
            showingDeleteAllHabitsConfirmation = false
            loadData()
        } catch {
            print("Delete all habits error: \(error)")
        }
    }

    func showHardDeleteHabitConfirmation(habitId: UUID, habitName: String) {
        habitToHardDelete = (id: habitId, name: habitName)
    }

    func deleteHabit(habitId: UUID) {
        do {
            try deleteHabitUseCase.execute(habitId: habitId)
            habitToHardDelete = nil
            loadData()
        } catch {
            print("Delete habit error: \(error)")
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
    
    func themeName(for themeId: UUID?) -> String? {
        guard let id = themeId else { return nil }
        return themeRepository.getAllThemes().first(where: { $0.id == id })?.name
    }

    /// Цвет темы для фона блока на таймлайне. nil если у темы нет цвета.
    func themeColor(for themeId: UUID?) -> Color? {
        guard let id = themeId else { return nil }
        guard let hex = themeRepository.getAllThemes().first(where: { $0.id == id })?.colorHex else { return nil }
        return Color(hex: hex)
    }
    
    func debugPrintHabits() {
        let allHabits = habitRepository.getAllHabits()
        print("\n--- 📝 ВСЕ ПРИВЫЧКИ В БАЗЕ ---")
        if allHabits.isEmpty {
            print("База пуста")
        }
        for habit in allHabits {
            let deletedDate = habitRepository.getHabitDeletedFromDate(habitId: habit.id)
            let status = deletedDate != nil ? "❌ УДАЛЕНА с \(deletedDate!)" : "✅ АКТИВНА"
            print("""
            ID: \(habit.id)
            Название: [\(habit.name)]
            Тип: \(habit.type.displayName)
            Статус: \(status)
            XP: \(habit.xpValue)
            Цель: \(habit.targetValue)
            Лимит ДЕНЬ: \(habit.dailyTarget)
            Лимит НЕДЕЛЯ: \(habit.weeklyTarget)
            Создана: \(habit.createdAt)
            ----------------------------
            """)
        }
        print("--- КОНЕЦ СПИСКА ---\n")
    }
}

