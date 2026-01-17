//
//  CalculateDailyLifePointsUseCase.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

protocol CalculateDailyLifePointsUseCaseProtocol {
    func execute(date: Date) throws -> Int
}

class CalculateDailyLifePointsUseCase: CalculateDailyLifePointsUseCaseProtocol {
    private let habitRepository: HabitRepositoryProtocol
    
    init(habitRepository: HabitRepositoryProtocol) {
        self.habitRepository = habitRepository
    }
    
    func execute(date: Date) throws -> Int {
        let habits = habitRepository.getAllHabits()
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        var totalXPChange = 0
        
        for habit in habits {
            // Пропускаем привычки, которые еще не были созданы или уже удалены
            let habitCreatedDate = calendar.startOfDay(for: habit.createdAt)
            if dayStart < habitCreatedDate {
                continue // Привычка еще не существовала
            }
            
            if let deletedFromDate = habitRepository.getHabitDeletedFromDate(habitId: habit.id) {
                let deletedDate = calendar.startOfDay(for: deletedFromDate)
                if dayStart >= deletedDate {
                    continue // Привычка уже была удалена
                }
            }
            
            // Считаем только дневные цели (недельные считаются в конце недели)
            if habit.type == .good {
                if let targetType = habit.targetType, targetType == .daily {
                    let completionsForDay = habitRepository.getCompletionCountForDate(habit.id, date: date)
                    let targetValue = habit.targetValue
                    
                    if completionsForDay == 0 && targetValue > 0 {
                        // Штраф за 0 выполнений: 2 * xpValue этой привычки
                        totalXPChange -= habit.xpValue * 2
                    } else if completionsForDay > 0 && targetValue > 0 {
                        if completionsForDay >= targetValue {
                            // Достигнута цель (3/3) → получаю xpValue
                            totalXPChange += habit.xpValue
                        } else {
                            // Есть выполнения, но не достигнута цель (1/3, 2/3)
                            if habit.proportionalReward {
                                // Процентное: получаю пропорционально (1/3 = xpValue/3, 2/3 = 2*xpValue/3)
                                let ratio = Double(completionsForDay) / Double(targetValue)
                                let xpEarned = Int(Double(habit.xpValue) * ratio)
                                totalXPChange += xpEarned
                            }
                            // Если "все или ничего" → ничего не получаю
                        }
                    }
                }
            } else {
                // Вредные привычки - считаем выполнения
                let completionsForDay = habitRepository.getCompletionCountForDate(habit.id, date: date)
                let threshold = habit.dailyTarget // Порог допустимых ошибок в день
                
                if completionsForDay > threshold {
                    // Штрафуем только за превышение порога
                    let excess = completionsForDay - threshold
                    totalXPChange -= habit.xpValue * excess
                }
            }
        }
        
        return totalXPChange
    }
}

