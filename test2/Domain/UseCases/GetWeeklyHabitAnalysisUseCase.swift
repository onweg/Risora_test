//
//  GetWeeklyHabitAnalysisUseCase.swift
//  test2
//

import Foundation

protocol GetWeeklyHabitAnalysisUseCaseProtocol {
    func execute(weekStartDate: Date) -> WeeklyReportModel?
}

class GetWeeklyHabitAnalysisUseCase: GetWeeklyHabitAnalysisUseCaseProtocol {
    private let habitRepository: HabitRepositoryProtocol
    private let lifePointRepository: LifePointRepositoryProtocol
    
    init(habitRepository: HabitRepositoryProtocol, lifePointRepository: LifePointRepositoryProtocol) {
        self.habitRepository = habitRepository
        self.lifePointRepository = lifePointRepository
    }
    
    func execute(weekStartDate: Date) -> WeeklyReportModel? {
        guard let lifePoint = lifePointRepository.getLifePointForWeek(weekStartDate: weekStartDate) else {
            return nil
        }
        
        let habits = habitRepository.getAllHabitsIncludingDeleted(forDate: weekStartDate)
        let calendar = Calendar.current
        var analyses: [HabitWeeklyAnalysisModel] = []
        
        for habit in habits {
            var dayAnalyses: [HabitWeeklyAnalysisModel.DayAnalysis] = []
            var habitTotalImpact = 0
            var weeklyTargetImpact: Int? = nil
            
            let dailyCompletions = habitRepository.getDailyCompletionsForWeek(habitId: habit.id, weekStartDate: weekStartDate)
            
            let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate)!
            let habitCreatedDate = calendar.startOfDay(for: habit.createdAt)
            let activeStartDate = max(weekStartDate, habitCreatedDate)
            
            var activeEndDate = weekEndDate
            if let deletedFromDate = habitRepository.getHabitDeletedFromDate(habitId: habit.id) {
                let deletedDate = calendar.startOfDay(for: deletedFromDate)
                if deletedDate <= weekEndDate {
                    activeEndDate = calendar.date(byAdding: .day, value: -1, to: deletedDate) ?? weekEndDate
                }
            }
            
            // 1. Дневной анализ (проходим по всем 7 дням)
            for dayOffset in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStartDate) else { continue }
                let dayStart = calendar.startOfDay(for: day)
                
                let completions = dailyCompletions[dayStart] ?? 0
                var impact = 0
                var target = 0
                
                // Считаем только если привычка была активна в этот день
                if dayStart >= activeStartDate && dayStart <= activeEndDate {
                    if habit.type == .good {
                        // Пытаемся найти цель (дневную)
                        if habit.targetType == .daily {
                            target = habit.targetValue
                        } else if habit.dailyTarget > 0 {
                            target = habit.dailyTarget
                        }
                        
                        if target > 0 {
                            if completions == 0 {
                                impact = -habit.xpValue * 2 // Штраф за 0
                            } else if completions >= target {
                                impact = habit.xpValue // Успех
                            } else if habit.proportionalReward {
                                let ratio = Double(completions) / Double(target)
                                impact = Int(Double(habit.xpValue) * ratio)
                            }
                        }
                    } else {
                        // Вредная привычка
                        let threshold = habit.dailyTarget
                        if completions > threshold {
                            impact = -habit.xpValue * (completions - threshold)
                        }
                    }
                }
                
                dayAnalyses.append(HabitWeeklyAnalysisModel.DayAnalysis(
                    date: dayStart,
                    completions: completions,
                    target: target,
                    impact: impact
                ))
                habitTotalImpact += impact
            }
            
            // 2. Недельный анализ
            if habit.type == .good {
                var weeklyTarget = 0
                if habit.targetType == .weekly {
                    weeklyTarget = habit.targetValue
                } else if habit.weeklyTarget > 0 {
                    weeklyTarget = habit.weeklyTarget
                }
                
                if weeklyTarget > 0 {
                    let totalCompletions = dayAnalyses.reduce(0) { $0 + $1.completions }
                    var impact = 0
                    
                    if totalCompletions == 0 {
                        impact = -habit.xpValue * 2
                    } else if totalCompletions >= weeklyTarget {
                        impact = habit.xpValue
                    } else if habit.proportionalReward {
                        let ratio = Double(totalCompletions) / Double(weeklyTarget)
                        impact = Int(Double(habit.xpValue) * ratio)
                    }
                    
                    weeklyTargetImpact = impact
                    habitTotalImpact += impact
                }
            } else if habit.type == .bad && habit.weeklyTarget > 0 {
                let totalCompletions = dayAnalyses.reduce(0) { $0 + $1.completions }
                let threshold = habit.weeklyTarget
                if totalCompletions > threshold {
                    let impact = -habit.xpValue * (totalCompletions - threshold)
                    weeklyTargetImpact = impact
                    habitTotalImpact += impact
                }
            }
            
            // ДОБАВЛЯЕМ ВСЁ. Без условий. Если привычка была в базе на ту неделю - она будет в отчете.
            analyses.append(HabitWeeklyAnalysisModel(
                id: habit.id,
                habitName: habit.name,
                habitType: habit.type,
                totalImpact: habitTotalImpact,
                details: dayAnalyses,
                weeklyTargetImpact: weeklyTargetImpact
            ))
        }
        
        return WeeklyReportModel(
            weekStartDate: weekStartDate,
            totalXPChange: lifePoint.value,
            analyses: analyses.sorted(by: { abs($0.totalImpact) > abs($1.totalImpact) })
        )
    }
}
