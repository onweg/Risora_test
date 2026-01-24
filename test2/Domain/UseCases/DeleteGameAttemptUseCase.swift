//
//  DeleteGameAttemptUseCase.swift
//  test2
//
//  Created by Arkadiy on 19.01.2026.
//

import Foundation

protocol DeleteGameAttemptUseCaseProtocol {
    func deleteAttempt(_ attemptId: UUID) throws
    func deleteAttemptsStartedAndEndedOnSameDay(date: Date) throws -> Int // Возвращает количество удаленных
}

class DeleteGameAttemptUseCase: DeleteGameAttemptUseCaseProtocol {
    private let gameAttemptRepository: GameAttemptRepositoryProtocol
    
    init(gameAttemptRepository: GameAttemptRepositoryProtocol) {
        self.gameAttemptRepository = gameAttemptRepository
    }
    
    func deleteAttempt(_ attemptId: UUID) throws {
        try gameAttemptRepository.deleteAttempt(attemptId)
    }
    
    func deleteAttemptsStartedAndEndedOnSameDay(date: Date) throws -> Int {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        // Получаем все попытки
        let allAttempts = gameAttemptRepository.getAllAttempts()
        
        var deletedCount = 0
        
        for attempt in allAttempts {
            // Пропускаем активные попытки
            if attempt.isActive {
                continue
            }
            
            // Проверяем что попытка началась и закончилась в один день (19 января)
            guard let endDate = attempt.endDate else {
                continue
            }
            
            let startDay = calendar.startOfDay(for: attempt.startDate)
            let endDay = calendar.startOfDay(for: endDate)
            
            // Если началась и закончилась в один день И это 19 января
            if startDay == endDay && startDay == targetDate {
                try gameAttemptRepository.deleteAttempt(attempt.id)
                deletedCount += 1
            }
        }
        
        return deletedCount
    }
}
