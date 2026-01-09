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
                            // Достигнута цель → получаю xpValue * targetValue
                            totalXPChange += habit.xpValue * totalExpected
                        } else {
                            // Есть выполнения, но не достигнута цель
                            if habit.proportionalReward {
                                // Процентное: получаю пропорционально
                                let ratio = Double(totalCompletions) / Double(totalExpected)
                                let xpEarned = Int(Double(habit.xpValue * totalExpected) * ratio)
                                totalXPChange += xpEarned
                            }
                            // Если "все или ничего" → ничего не получаю
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
                    
                    // Пропускаем дни, когда привычка еще не существовала или уже была удалена
                    if dayStart < activeStartDate || dayStart > activeEndDate {
                        continue
                    }
                    
                    let completionsForDay = dailyCompletions[dayStart] ?? 0
                    totalCompletions += completionsForDay
                }
                
                // Проверяем пороги
                var shouldDeduct = true
                
                // Проверка минимального порога за неделю
                if habit.weeklyTarget > 0 && totalCompletions < habit.weeklyTarget {
                    shouldDeduct = false
                }
                
                // Проверка минимального порога за день
                if habit.dailyTarget > 0 && shouldDeduct {
                    var hasDayBelowThreshold = false
                    for dayOffset in 0..<7 {
                        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }
                        let dayStart = calendar.startOfDay(for: day)
                        
                        // Пропускаем дни, когда привычка еще не существовала или уже была удалена
                        if dayStart < activeStartDate || dayStart > activeEndDate {
                            continue
                        }
                        
                        let completionsForDay = dailyCompletions[dayStart] ?? 0
                        
                        if completionsForDay > 0 && completionsForDay < habit.dailyTarget {
                            hasDayBelowThreshold = true
                            break
                        }
                    }
                    
                    // Если есть день с выполнениями ниже порога, не вычитаем за этот день
                    // Но вычитаем за дни, где превышен порог
                    if hasDayBelowThreshold {
                        // Вычитаем только за дни, где превышен порог
                        var validCompletions = 0
                        for dayOffset in 0..<7 {
                            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }
                            let dayStart = calendar.startOfDay(for: day)
                            
                            // Пропускаем дни, когда привычка еще не существовала или уже была удалена
                            if dayStart < activeStartDate || dayStart > activeEndDate {
                                continue
                            }
                            
                            let completionsForDay = dailyCompletions[dayStart] ?? 0
                            
                            if completionsForDay >= habit.dailyTarget {
                                validCompletions += completionsForDay
                            }
                        }
                        totalXPChange -= habit.xpValue * validCompletions
                        shouldDeduct = false
                    }
                }
                
                // Если все проверки пройдены, вычитаем за все выполнения
                if shouldDeduct {
                    totalXPChange -= habit.xpValue * totalCompletions
                }
            }
        }
        
        return totalXPChange
    }
}

