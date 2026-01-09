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
                
                // Определяем ожидаемое количество выполнений за неделю
                let totalExpected: Int
                if let targetType = habit.targetType {
                    switch targetType {
                    case .daily:
                        // Цель на день: targetValue раз в день * 7 дней
                        totalExpected = habit.targetValue * 7
                    case .weekly:
                        // Цель на неделю: targetValue раз за всю неделю
                        totalExpected = habit.targetValue
                    }
                } else {
                    // Обратная совместимость: используем dailyTarget если targetType не указан
                    totalExpected = habit.dailyTarget > 0 ? habit.dailyTarget * 7 : 0
                }
                
                // Считаем все выполнения за неделю
                for dayOffset in 0..<7 {
                    guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }
                    let dayStart = calendar.startOfDay(for: day)
                    let completionsForDay = dailyCompletions[dayStart] ?? 0
                    totalCompletions += completionsForDay
                }
                
                if habit.proportionalReward {
                    // Пропорциональное начисление
                    if totalCompletions > 0 && totalExpected > 0 {
                        let ratio = Double(totalCompletions) / Double(totalExpected)
                        let xpEarned = Int(Double(habit.xpValue * totalExpected) * ratio)
                        totalXPChange += xpEarned
                    }
                    // Если ничего не сделано, ничего не начисляем
                } else {
                    // Все или ничего
                    if totalCompletions >= totalExpected && totalExpected > 0 {
                        totalXPChange += habit.xpValue * totalExpected
                    } else if totalExpected > 0 {
                        // Не выполнил - штраф за невыполненное
                        let missed = totalExpected - totalCompletions
                        totalXPChange -= habit.xpValue * missed
                    }
                }
            } else {
                // Вредная привычка
                let dailyCompletions = habitRepository.getDailyCompletionsForWeek(habitId: habit.id, weekStartDate: weekStartDate)
                let totalCompletions = habitRepository.getCompletionCountForWeek(habitId: habit.id, weekStartDate: weekStartDate)
                
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

