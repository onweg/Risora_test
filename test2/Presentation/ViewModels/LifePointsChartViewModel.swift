//
//  LifePointsChartViewModel.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import SwiftUI

@MainActor
class LifePointsChartViewModel: ObservableObject {
    /// Одна точка графика: дата (ось X) и кумулятивные очки на конец этого дня (ось Y).
    struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let points: Int
    }
    
    @Published var lifePoints: [LifePointModel] = []
    @Published var chartData: [ChartPoint] = []
    @Published var lastWeekReport: WeeklyReportModel? = nil

    /// Текущее значение — кумулятивные очки на последнюю дату.
    var currentValue: Int { chartData.last?.points ?? 0 }
    
    private let lifePointRepository: LifePointRepositoryProtocol
    private let gameStateRepository: GameStateRepositoryProtocol
    private let habitRepository: HabitRepositoryProtocol
    private let goalRepository: GoalRepositoryProtocol
    private let gameAttemptRepository: GameAttemptRepositoryProtocol
    private let calculateDailyLifePointsUseCase: CalculateDailyLifePointsUseCaseProtocol
    private let getWeeklyHabitAnalysisUseCase: GetWeeklyHabitAnalysisUseCaseProtocol
    private let processWeekEndUseCase: ProcessWeekEndUseCaseProtocol
    private let processAllMissedWeeksUseCase: ProcessAllMissedWeeksUseCaseProtocol

    nonisolated init(
        lifePointRepository: LifePointRepositoryProtocol,
        gameStateRepository: GameStateRepositoryProtocol,
        habitRepository: HabitRepositoryProtocol,
        goalRepository: GoalRepositoryProtocol,
        gameAttemptRepository: GameAttemptRepositoryProtocol,
        calculateDailyLifePointsUseCase: CalculateDailyLifePointsUseCaseProtocol,
        getWeeklyHabitAnalysisUseCase: GetWeeklyHabitAnalysisUseCaseProtocol,
        processWeekEndUseCase: ProcessWeekEndUseCaseProtocol,
        processAllMissedWeeksUseCase: ProcessAllMissedWeeksUseCaseProtocol
    ) {
        self.lifePointRepository = lifePointRepository
        self.gameStateRepository = gameStateRepository
        self.habitRepository = habitRepository
        self.goalRepository = goalRepository
        self.gameAttemptRepository = gameAttemptRepository
        self.calculateDailyLifePointsUseCase = calculateDailyLifePointsUseCase
        self.getWeeklyHabitAnalysisUseCase = getWeeklyHabitAnalysisUseCase
        self.processWeekEndUseCase = processWeekEndUseCase
        self.processAllMissedWeeksUseCase = processAllMissedWeeksUseCase
        
        Task { @MainActor in
            self.loadData()
        }
    }
    
    func loadData() {
        // Если нет активной попытки — создаём (график «одна жизнь с 0»)
        if gameAttemptRepository.getActiveAttempt() == nil {
            let calendar = Calendar.current
            let today = Date()
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
            let attempt = GameAttemptModel(
                id: UUID(),
                startDate: weekStart,
                endDate: nil,
                startingLives: 0,
                endingLives: nil,
                isActive: true
            )
            try? gameAttemptRepository.createAttempt(attempt)
        }
        
        do {
            try processAllMissedWeeksUseCase.execute()
        } catch {
            print("Error processing missed weeks in ChartViewModel: \(error)")
        }
        
        lifePoints = lifePointRepository.getAllLifePoints()
        
        prepareChartData()
        
        // Загружаем анализ за последнюю полностью завершенную неделю
        if let lastWeek = lifePoints.last {
            lastWeekReport = getWeeklyHabitAnalysisUseCase.execute(weekStartDate: lastWeek.weekStartDate)
        } else {
            lastWeekReport = nil
        }
    }
    
    private func prepareChartData() {
        guard let activeAttempt = gameAttemptRepository.getActiveAttempt() else {
            chartData = []
            return
        }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: activeAttempt.startDate)
        let today = calendar.startOfDay(for: Date())
        
        var data: [ChartPoint] = []
        var cumulative = 0
        var day = startDate
        
        while day <= today {
            if let xp = try? calculateDailyLifePointsUseCase.execute(date: day) {
                cumulative += xp
            }
            data.append(ChartPoint(date: day, points: max(0, cumulative)))
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        }
        
        chartData = data
    }
    
    func refresh() {
        loadData()
    }
}

