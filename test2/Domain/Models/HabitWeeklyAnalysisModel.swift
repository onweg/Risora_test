//
//  HabitWeeklyAnalysisModel.swift
//  test2
//

import Foundation

struct HabitWeeklyAnalysisModel: Identifiable {
    let id: UUID
    let habitName: String
    let habitType: HabitType
    let totalImpact: Int // Общее влияние на жизни (+/-)
    let details: [DayAnalysis] // Детали по дням
    let weeklyTargetImpact: Int? // Влияние за выполнение/провал недельной цели (если есть)
    
    struct DayAnalysis: Identifiable {
        let id = UUID()
        let date: Date
        let completions: Int
        let target: Int
        let impact: Int // Влияние за этот день
    }
}

struct WeeklyReportModel {
    let weekStartDate: Date
    let totalXPChange: Int
    let analyses: [HabitWeeklyAnalysisModel]
}
