//
//  ProcessAllMissedWeeksUseCase.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import CoreData

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
        // 0. ПРИНУДИТЕЛЬНАЯ ПРИВЯЗКА ДАННЫХ К ТЕКУЩЕЙ ПОПЫТКЕ (Fix для "сиротских" данных)
        if let activeAttempt = gameAttemptRepository.getActiveAttempt() {
            try linkOrphanedDataToAttempt(activeAttempt.id)
        }

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
            
            // Начинаем с недели после последней обработанной
            weekStartToProcess = calendar.date(byAdding: .weekOfYear, value: 1, to: lastWeekStart)!
        } else {
            // Если никогда не было расчета, начинаем с самой первой недели попытки
            weekStartToProcess = attemptStartWeek
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

    private func linkOrphanedDataToAttempt(_ attemptId: UUID) throws {
        // 1. Ищем LifePoints без привязки к попытке
        let lpRequest: NSFetchRequest<LifePoint> = LifePoint.fetchRequest()
        lpRequest.predicate = NSPredicate(format: "gameAttempt == nil")
        
        // 2. Ищем HabitCompletions без привязки к попытке
        let hcRequest: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        hcRequest.predicate = NSPredicate(format: "gameAttempt == nil")
        
        let attemptRequest: NSFetchRequest<GameAttempt> = GameAttempt.fetchRequest()
        attemptRequest.predicate = NSPredicate(format: "id == %@", attemptId as CVarArg)
        
        let context = (gameStateRepository as? GameStateRepository)?.context // Взлом для доступа к контексту
        guard let ctx = context, let attemptEntity = try ctx.fetch(attemptRequest).first else { return }
        
        let orphanedLPs = try ctx.fetch(lpRequest)
        for lp in orphanedLPs {
            lp.gameAttempt = attemptEntity
        }
        
        let orphanedHCs = try ctx.fetch(hcRequest)
        for hc in orphanedHCs {
            hc.gameAttempt = attemptEntity
        }
        
        if !orphanedLPs.isEmpty || !orphanedHCs.isEmpty {
            try ctx.save()
            print("✅ Linked \(orphanedLPs.count) LifePoints and \(orphanedHCs.count) Completions to attempt \(attemptId)")
        }
    }
}



