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
    private let gameAttemptRepository: GameAttemptRepositoryProtocol
    
    init(habitRepository: HabitRepositoryProtocol,
         gameAttemptRepository: GameAttemptRepositoryProtocol) {
        self.habitRepository = habitRepository
        self.gameAttemptRepository = gameAttemptRepository
    }
    
    func execute(date: Date) throws -> Int {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // ВАЖНО: Используем привычки, которые были активны на тот момент (включая удаленные позже)
        let habits = habitRepository.getAllHabitsIncludingDeleted(forDate: dayStart)
        
        // ВАЖНО: Получаем активную попытку и не считаем дни до её начала
        if let activeAttempt = gameAttemptRepository.getActiveAttempt() {
            let attemptStartDate = calendar.startOfDay(for: activeAttempt.startDate)
            if dayStart < attemptStartDate {
                return 0 // День был до начала текущей попытки, не считаем
            }
        }
        
        var totalXPChange = 0
        
        for habit in habits {
            if habit.isTask { continue } // Задачи не участвуют в начислении XP
            
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
            
            // Полезные привычки: начисляем XP за выполнение (без штрафов, график не уходит в минус)
            if habit.type == .good {
                let targetType = habit.targetType ?? .daily
                if targetType == .daily {
                    let completionsForDay = habitRepository.getCompletionCountForDate(habit.id, date: date)
                    let targetValue = habit.targetValue > 0 ? habit.targetValue : 1
                    
                    if completionsForDay > 0 {
                        if completionsForDay >= targetValue {
                            totalXPChange += habit.xpValue
                        } else if habit.proportionalReward {
                            let ratio = Double(completionsForDay) / Double(targetValue)
                            totalXPChange += Int(Double(habit.xpValue) * ratio)
                        }
                    }
                }
            } else {
                // Вредные привычки - считаем выполнения
                
                // ВАЖНО: Если у вредной привычки есть недельный порог (> 0), 
                // то дневные штрафы за неё НЕ СЧИТАЕМ, чтобы не было двойного штрафа.
                // В этом случае все штрафы будут посчитаны один раз в конце недели.
                if habit.weeklyTarget > 0 {
                    continue
                }
                
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

