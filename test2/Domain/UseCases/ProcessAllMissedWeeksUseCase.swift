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
    
    init(
        processWeekEndUseCase: ProcessWeekEndUseCaseProtocol,
        gameStateRepository: GameStateRepositoryProtocol
    ) {
        self.processWeekEndUseCase = processWeekEndUseCase
        self.gameStateRepository = gameStateRepository
    }
    
    func execute() throws {
        let calendar = Calendar.current
        let today = Date()
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        
        guard let gameState = gameStateRepository.getGameState() else {
            return // Игра не инициализирована
        }
        
        var weekStartToProcess: Date
        
        if let lastCalculation = gameState.lastWeekCalculationDate {
            let lastWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastCalculation))!
            
            // Если текущая неделя та же, что и последняя обработанная, ничего не делаем
            if calendar.isDate(currentWeekStart, equalTo: lastWeekStart, toGranularity: .weekOfYear) {
                return
            }
            
            // Начинаем с недели после последней обработанной
            weekStartToProcess = calendar.date(byAdding: .weekOfYear, value: 1, to: lastWeekStart)!
        } else {
            // Если никогда не было расчета, обрабатываем все недели с момента создания первой привычки
            // Для простоты обрабатываем только текущую неделю минус 1
            weekStartToProcess = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!
        }
        
        // Обрабатываем все пропущенные недели до текущей (не включая текущую)
        while weekStartToProcess < currentWeekStart {
            try processWeekEndUseCase.execute(weekStartDate: weekStartToProcess)
            weekStartToProcess = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStartToProcess)!
        }
    }
}



