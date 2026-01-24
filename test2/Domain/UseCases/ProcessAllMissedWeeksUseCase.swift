//
//  ProcessAllMissedWeeksUseCase.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation

protocol ProcessAllMissedWeeksUseCaseProtocol {
    func execute() throws
}

class ProcessAllMissedWeeksUseCase: ProcessAllMissedWeeksUseCaseProtocol {
    private let processWeekEndUseCase: ProcessWeekEndUseCaseProtocol
    private let gameStateRepository: GameStateRepositoryProtocol
    private let gameAttemptRepository: GameAttemptRepositoryProtocol
    
    init(
        processWeekEndUseCase: ProcessWeekEndUseCaseProtocol,
        gameStateRepository: GameStateRepositoryProtocol,
        gameAttemptRepository: GameAttemptRepositoryProtocol
    ) {
        self.processWeekEndUseCase = processWeekEndUseCase
        self.gameStateRepository = gameStateRepository
        self.gameAttemptRepository = gameAttemptRepository
    }
    
    func execute() throws {
        let calendar = Calendar.current
        let today = Date()
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        guard let gameState = gameStateRepository.getGameState() else {
            return // Игра не инициализирована
        }
        
        // ВАЖНО: Получаем активную попытку для определения стартовой даты
        guard let activeAttempt = gameAttemptRepository.getActiveAttempt() else {
            return // Нет активной попытки
        }
        
        let attemptStartWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: activeAttempt.startDate))!
        
        var weekStartToProcess: Date
        
        if let lastCalculation = gameState.lastWeekCalculationDate {
            let lastWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastCalculation))!
            
            // Если текущая неделя та же, что и последняя обработанная, ничего не делаем
            if calendar.isDate(currentWeekStart, equalTo: lastWeekStart, toGranularity: .weekOfYear) {
                return
            }
            
            // ВАЖНО: Если последний расчет был ДО начала текущей попытки,
            // начинаем с недели после начала попытки, а не с lastCalculation
            if lastWeekStart < attemptStartWeek {
                weekStartToProcess = calendar.date(byAdding: .weekOfYear, value: 1, to: attemptStartWeek)!
            } else {
                // Начинаем с недели после последней обработанной
                weekStartToProcess = calendar.date(byAdding: .weekOfYear, value: 1, to: lastWeekStart)!
            }
        } else {
            // Если никогда не было расчета, начинаем с недели после начала попытки
            weekStartToProcess = calendar.date(byAdding: .weekOfYear, value: 1, to: attemptStartWeek)!
        }
        
        // ВАЖНО: Не обрабатываем недели которые были ДО начала текущей попытки
        if weekStartToProcess < attemptStartWeek {
            weekStartToProcess = attemptStartWeek
        }
        
        // Обрабатываем все пропущенные недели до текущей (не включая текущую)
        while weekStartToProcess < currentWeekStart {
            try processWeekEndUseCase.execute(weekStartDate: weekStartToProcess)
            weekStartToProcess = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStartToProcess)!
        }
    }
}



