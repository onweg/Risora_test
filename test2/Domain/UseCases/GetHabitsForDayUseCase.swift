//
//  GetHabitsForDayUseCase.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

protocol GetHabitsForDayUseCaseProtocol {
    func execute(date: Date) -> [(habit: HabitModel, isCompleted: Bool, completionCount: Int, weeklyCompletionCount: Int, canEdit: Bool, weeklyCompletionDates: [Date])]
}

class GetHabitsForDayUseCase: GetHabitsForDayUseCaseProtocol {
    private let habitRepository: HabitRepositoryProtocol
    
    init(habitRepository: HabitRepositoryProtocol) {
        self.habitRepository = habitRepository
    }
    
    func execute(date: Date) -> [(habit: HabitModel, isCompleted: Bool, completionCount: Int, weeklyCompletionCount: Int, canEdit: Bool, weeklyCompletionDates: [Date])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDate = calendar.startOfDay(for: date)
        
        let canEdit = calendar.isDate(selectedDate, inSameDayAs: today)
        
        // Получаем начало недели для подсчета прогресса за неделю
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        
        // Для прошлых дат показываем все привычки (включая удаленные позже), для сегодня и будущего - только активные
        let habits: [HabitModel]
        if selectedDate < today {
            habits = habitRepository.getAllHabitsIncludingDeleted(forDate: date)
        } else {
            habits = habitRepository.getAllHabits()
        }
        
        let completedHabitIds = habitRepository.getCompletionsForDate(date)
        
        return habits.compactMap { habit in
            // Для прошлых дат не показываем привычки, которые были созданы после этой даты
            if selectedDate < today {
                let habitCreatedDate = calendar.startOfDay(for: habit.createdAt)
                if habitCreatedDate > selectedDate {
                    return nil // Привычка создана после выбранной даты, не показываем для прошлых дней
                }
            }
            
            let isCompleted = completedHabitIds.contains(habit.id)
            let completionCount = habitRepository.getCompletionCountForDate(habit.id, date: date)
            let weeklyCompletionCount = habitRepository.getCompletionCountForWeek(habitId: habit.id, weekStartDate: weekStart)
            let weeklyCompletionDates = habitRepository.getCompletionDatesForWeek(habitId: habit.id, weekStartDate: weekStart)
            return (habit: habit, isCompleted: isCompleted, completionCount: completionCount, weeklyCompletionCount: weeklyCompletionCount, canEdit: canEdit, weeklyCompletionDates: weeklyCompletionDates)
        }
    }
}

