//
//  AttemptsHistoryViewModel.swift
//  test2
//
//  Created by Arkadiy on 19.01.2026.
//

import Foundation
import Combine

class AttemptsHistoryViewModel: ObservableObject {
    struct ChartPoint: Identifiable {
        let id = UUID()
        let weekIndex: Int
        let lives: Int
        let date: Date
    }
    
    @Published var attempts: [GameAttemptModel] = []
    @Published var selectedAttempt: GameAttemptModel?
    @Published var selectedAttemptChartData: [ChartPoint] = []
    @Published var lastWeekReport: WeeklyReportModel? = nil
    
    private let gameAttemptRepository: GameAttemptRepositoryProtocol
    private let lifePointRepository: LifePointRepositoryProtocol
    private let getWeeklyHabitAnalysisUseCase: GetWeeklyHabitAnalysisUseCaseProtocol
    
    init(gameAttemptRepository: GameAttemptRepositoryProtocol,
         lifePointRepository: LifePointRepositoryProtocol,
         getWeeklyHabitAnalysisUseCase: GetWeeklyHabitAnalysisUseCaseProtocol) {
        self.gameAttemptRepository = gameAttemptRepository
        self.lifePointRepository = lifePointRepository
        self.getWeeklyHabitAnalysisUseCase = getWeeklyHabitAnalysisUseCase
    }
    
    func loadAttempts() {
        attempts = gameAttemptRepository.getAllAttempts()
    }
    
    func loadLifePoints(for attempt: GameAttemptModel) {
        selectedAttempt = attempt
        let lifePoints = lifePointRepository.getLifePointsForAttempt(attempt.id)
        
        var data: [ChartPoint] = []
        var cumulativeLives = attempt.startingLives
        
        // Точка 0: начало попытки
        data.append(ChartPoint(
            weekIndex: 0,
            lives: cumulativeLives,
            date: attempt.startDate
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
        
        selectedAttemptChartData = data
        
        // Загружаем анализ за последнюю неделю этой попытки
        if let lastPoint = lifePoints.last {
            lastWeekReport = getWeeklyHabitAnalysisUseCase.execute(weekStartDate: lastPoint.weekStartDate)
        } else {
            lastWeekReport = nil
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
    
    func attemptDuration(_ attempt: GameAttemptModel) -> String {
        let endDate = attempt.endDate ?? Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour], from: attempt.startDate, to: endDate)
        
        if let days = components.day, days > 0 {
            return "\(days) дн."
        } else if let hours = components.hour {
            return "\(hours) ч."
        }
        return "< 1 ч."
    }
    
    func attemptStatusText(_ attempt: GameAttemptModel) -> String {
        if attempt.isActive {
            return "Активная"
        } else {
            return "Завершена"
        }
    }
    
    func attemptStatusColor(_ attempt: GameAttemptModel) -> String {
        if attempt.isActive {
            return "blue"
        } else if let endingLives = attempt.endingLives, endingLives > 0 {
            return "green"
        }
        return "red"
    }
}
