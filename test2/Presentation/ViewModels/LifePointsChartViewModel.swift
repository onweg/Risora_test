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
    struct ChartPoint: Identifiable {
        let id = UUID()
        let weekIndex: Int
        let lives: Int
        let date: Date
    }
    
    @Published var lifePoints: [LifePointModel] = []
    @Published var chartData: [ChartPoint] = []
    @Published var currentLives: Int = 100
    @Published var lastWeekReport: WeeklyReportModel? = nil
    
    private let lifePointRepository: LifePointRepositoryProtocol
    private let gameStateRepository: GameStateRepositoryProtocol
    private let habitRepository: HabitRepositoryProtocol
    private let goalRepository: GoalRepositoryProtocol
    private let gameAttemptRepository: GameAttemptRepositoryProtocol
    private let getWeeklyHabitAnalysisUseCase: GetWeeklyHabitAnalysisUseCaseProtocol
    private let processWeekEndUseCase: ProcessWeekEndUseCaseProtocol
    private let processAllMissedWeeksUseCase: ProcessAllMissedWeeksUseCaseProtocol
    
    nonisolated init(
        lifePointRepository: LifePointRepositoryProtocol,
        gameStateRepository: GameStateRepositoryProtocol,
        habitRepository: HabitRepositoryProtocol,
        goalRepository: GoalRepositoryProtocol,
        gameAttemptRepository: GameAttemptRepositoryProtocol,
        getWeeklyHabitAnalysisUseCase: GetWeeklyHabitAnalysisUseCaseProtocol,
        processWeekEndUseCase: ProcessWeekEndUseCaseProtocol,
        processAllMissedWeeksUseCase: ProcessAllMissedWeeksUseCaseProtocol
    ) {
        self.lifePointRepository = lifePointRepository
        self.gameStateRepository = gameStateRepository
        self.habitRepository = habitRepository
        self.goalRepository = goalRepository
        self.gameAttemptRepository = gameAttemptRepository
        self.getWeeklyHabitAnalysisUseCase = getWeeklyHabitAnalysisUseCase
        self.processWeekEndUseCase = processWeekEndUseCase
        self.processAllMissedWeeksUseCase = processAllMissedWeeksUseCase
        
        Task { @MainActor in
            self.loadData()
        }
    }
    
    func loadData() {
        // Сначала обрабатываем все пропущенные недели, чтобы данные были актуальны
        do {
            try processAllMissedWeeksUseCase.execute()
        } catch {
            print("Error processing missed weeks in ChartViewModel: \(error)")
        }
        
        lifePoints = lifePointRepository.getAllLifePoints()
        
        if let gameState = gameStateRepository.getGameState() {
            currentLives = gameState.currentLives
        }
        
        // Формируем данные для графика (кумулятивные жизни)
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
        
        var data: [ChartPoint] = []
        var cumulativeLives = activeAttempt.startingLives
        
        // Точка 0: начало попытки
        data.append(ChartPoint(
            weekIndex: 0,
            lives: cumulativeLives,
            date: activeAttempt.startDate
        ))
        
        // Последующие точки: результаты каждой недели
        for (index, point) in lifePoints.enumerated() {
            cumulativeLives += point.value
            data.append(ChartPoint(
                weekIndex: index + 1,
                lives: max(0, cumulativeLives),
                date: point.date
            ))
        }
        
        chartData = data
    }
    
    func refresh() {
        loadData()
    }
}

