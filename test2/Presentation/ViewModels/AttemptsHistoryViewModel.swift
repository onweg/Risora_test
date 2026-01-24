//
//  AttemptsHistoryViewModel.swift
//  test2
//
//  Created by Arkadiy on 19.01.2026.
//

import Foundation
import Combine

class AttemptsHistoryViewModel: ObservableObject {
    @Published var attempts: [GameAttemptModel] = []
    @Published var selectedAttempt: GameAttemptModel?
    @Published var selectedAttemptLifePoints: [LifePointModel] = []
    @Published var showForceResetAlert = false
    @Published var forceResetMessage = ""
    
    private let gameAttemptRepository: GameAttemptRepositoryProtocol
    private let lifePointRepository: LifePointRepositoryProtocol
    private let forceResetUseCase: ForceResetCurrentAttemptUseCaseProtocol
    private let deleteGameAttemptUseCase: DeleteGameAttemptUseCaseProtocol
    
    init(gameAttemptRepository: GameAttemptRepositoryProtocol,
         lifePointRepository: LifePointRepositoryProtocol,
         forceResetUseCase: ForceResetCurrentAttemptUseCaseProtocol,
         deleteGameAttemptUseCase: DeleteGameAttemptUseCaseProtocol) {
        self.gameAttemptRepository = gameAttemptRepository
        self.lifePointRepository = lifePointRepository
        self.forceResetUseCase = forceResetUseCase
        self.deleteGameAttemptUseCase = deleteGameAttemptUseCase
    }
    
    func loadAttempts() {
        attempts = gameAttemptRepository.getAllAttempts()
    }
    
    func loadLifePoints(for attempt: GameAttemptModel) {
        selectedAttempt = attempt
        selectedAttemptLifePoints = lifePointRepository.getLifePointsForAttempt(attempt.id)
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
    
    func forceResetCurrentAttempt() {
        do {
            try forceResetUseCase.execute()
            forceResetMessage = "Жизни восстановлены! Перезапустите приложение."
            showForceResetAlert = true
        } catch {
            forceResetMessage = "Ошибка: \(error.localizedDescription)"
            showForceResetAlert = true
        }
    }
    
    func deleteGarbageAttempts() {
        do {
            // Удаляем попытки, которые начались и закончились 19 января
            let calendar = Calendar.current
            var dateComponents = DateComponents()
            dateComponents.year = 2026
            dateComponents.month = 1
            dateComponents.day = 19
            let january19 = calendar.date(from: dateComponents) ?? Date()
            
            let deletedCount = try deleteGameAttemptUseCase.deleteAttemptsStartedAndEndedOnSameDay(date: january19)
            
            // Перезагружаем список попыток
            loadAttempts()
            
            forceResetMessage = "Удалено мусорных сессий: \(deletedCount)"
            showForceResetAlert = true
        } catch {
            forceResetMessage = "Ошибка при удалении: \(error.localizedDescription)"
            showForceResetAlert = true
        }
    }
}
