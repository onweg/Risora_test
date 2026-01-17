//
//  CalculateWeeklyLifePointsUseCase.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

protocol CalculateWeeklyLifePointsUseCaseProtocol {
    func execute(weekStartDate: Date) throws -> Int
}

class CalculateWeeklyLifePointsUseCase: CalculateWeeklyLifePointsUseCaseProtocol {
    private let habitRepository: HabitRepositoryProtocol
    private let gameStateRepository: GameStateRepositoryProtocol
    
    init(habitRepository: HabitRepositoryProtocol, gameStateRepository: GameStateRepositoryProtocol) {
        self.habitRepository = habitRepository
        self.gameStateRepository = gameStateRepository
    }
    
    func execute(weekStartDate: Date) throws -> Int {
        let habits = habitRepository.getAllHabits()
        let calendar = Calendar.current
        
        var totalXPChange = 0
        
        for habit in habits {
            if habit.type == .good {
                // Полезная привычка
                let dailyCompletions = habitRepository.getDailyCompletionsForWeek(habitId: habit.id, weekStartDate: weekStartDate)
                var totalCompletions = 0
                
                // Определяем период, когда привычка была активна в этой неделе
                let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate)!
                let habitCreatedDate = calendar.startOfDay(for: habit.createdAt)
                
                // Начало периода: максимум из начала недели и даты создания привычки
                let activeStartDate = max(weekStartDate, habitCreatedDate)
                
                // Конец периода: минимум из конца недели и даты удаления (если есть)
                var activeEndDate = weekEndDate
                if let deletedFromDate = habitRepository.getHabitDeletedFromDate(habitId: habit.id) {
                    let deletedDate = calendar.startOfDay(for: deletedFromDate)
                    if deletedDate <= weekEndDate {
                        activeEndDate = calendar.date(byAdding: .day, value: -1, to: deletedDate) ?? weekEndDate
                    }
                }
                
                // Считаем количество дней, когда привычка была активна
                let activeDaysCount = max(0, calendar.dateComponents([.day], from: activeStartDate, to: activeEndDate).day ?? 0) + 1
                
                // Считаем только недельные цели (дневные считаются каждый день отдельно)
                if let targetType = habit.targetType, targetType == .weekly {
                    // Определяем ожидаемое количество выполнений за неделю
                    let totalExpected = habit.targetValue
                    
                    // Считаем все выполнения за неделю (только за активные дни)
                    for dayOffset in 0..<7 {
                        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }
                        let dayStart = calendar.startOfDay(for: day)
                        
                        // Пропускаем дни, когда привычка еще не существовала или уже была удалена
                        if dayStart < activeStartDate || dayStart > activeEndDate {
                            continue
                        }
                        
                        let completionsForDay = dailyCompletions[dayStart] ?? 0
                        totalCompletions += completionsForDay
                    }
                    
                    if totalCompletions == 0 && totalExpected > 0 {
                        // Штраф за 0 выполнений за неделю: 2 * xpValue этой привычки
                        totalXPChange -= habit.xpValue * 2
                    } else if totalCompletions > 0 && totalExpected > 0 {
                        if totalCompletions >= totalExpected {
                            // Достигнута цель → получаем полную награду
                            totalXPChange += habit.xpValue
                        } else {
                            // Есть выполнения, но не достигнута цель
                            if habit.proportionalReward {
                                // Процентное: получаем пропорционально от общей награды
                                let ratio = Double(totalCompletions) / Double(totalExpected)
                                let xpEarned = Int(Double(habit.xpValue) * ratio)
                                totalXPChange += xpEarned
                            }
                            // Если "все или ничего" → ничего не получаем
                        }
                    }
                }
                // Дневные цели пропускаем - они считаются каждый день отдельно
            } else {
                // Вредная привычка
                let dailyCompletions = habitRepository.getDailyCompletionsForWeek(habitId: habit.id, weekStartDate: weekStartDate)
                
                // Определяем период, когда привычка была активна в этой неделе
                let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate)!
                let habitCreatedDate = calendar.startOfDay(for: habit.createdAt)
                
                // Начало периода: максимум из начала недели и даты создания привычки
                let activeStartDate = max(weekStartDate, habitCreatedDate)
                
                // Конец периода: минимум из конца недели и даты удаления (если есть)
                var activeEndDate = weekEndDate
                if let deletedFromDate = habitRepository.getHabitDeletedFromDate(habitId: habit.id) {
                    let deletedDate = calendar.startOfDay(for: deletedFromDate)
                    if deletedDate <= weekEndDate {
                        activeEndDate = calendar.date(byAdding: .day, value: -1, to: deletedDate) ?? weekEndDate
                    }
                }
                
                // Считаем выполнения только за активные дни
                var totalCompletions = 0
                for dayOffset in 0..<7 {
                    guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }
                    let dayStart = calendar.startOfDay(for: day)
                    
                    if dayStart >= activeStartDate && dayStart <= activeEndDate {
                        let completionsForDay = dailyCompletions[dayStart] ?? 0
                        totalCompletions += completionsForDay
                    }
                }
                
                // Логика штрафа: вычитаем только то, что ПРЕВЫШАЕТ порог
                let threshold = habit.weeklyTarget
                if totalCompletions > threshold {
                    let excess = totalCompletions - threshold
                    totalXPChange -= habit.xpValue * excess
                }
            }
        }
        
        return totalXPChange
    }
}

