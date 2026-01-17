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
    @Published var lifePoints: [LifePointModel] = []
    @Published var currentLives: Int = 100
    @Published var lastWeekReport: WeeklyReportModel? = nil
    
    private let lifePointRepository: LifePointRepositoryProtocol
    private let gameStateRepository: GameStateRepositoryProtocol
    private let habitRepository: HabitRepositoryProtocol
    private let goalRepository: GoalRepositoryProtocol
    private let getWeeklyHabitAnalysisUseCase: GetWeeklyHabitAnalysisUseCaseProtocol
    private let processWeekEndUseCase: ProcessWeekEndUseCaseProtocol
    
    nonisolated init(
        lifePointRepository: LifePointRepositoryProtocol,
        gameStateRepository: GameStateRepositoryProtocol,
        habitRepository: HabitRepositoryProtocol,
        goalRepository: GoalRepositoryProtocol,
        getWeeklyHabitAnalysisUseCase: GetWeeklyHabitAnalysisUseCaseProtocol,
        processWeekEndUseCase: ProcessWeekEndUseCaseProtocol
    ) {
        self.lifePointRepository = lifePointRepository
        self.gameStateRepository = gameStateRepository
        self.habitRepository = habitRepository
        self.goalRepository = goalRepository
        self.getWeeklyHabitAnalysisUseCase = getWeeklyHabitAnalysisUseCase
        self.processWeekEndUseCase = processWeekEndUseCase
        
        Task { @MainActor in
            self.loadData()
        }
    }
    
    func loadData() {
        lifePoints = lifePointRepository.getAllLifePoints()
        
        if let gameState = gameStateRepository.getGameState() {
            currentLives = gameState.currentLives
        }
        
        // Загружаем анализ за последнюю доступную неделю
        if let lastWeek = lifePoints.last {
            lastWeekReport = getWeeklyHabitAnalysisUseCase.execute(weekStartDate: lastWeek.weekStartDate)
        }
    }
    
    func refresh() {
        loadData()
    }
    
    func recalculateLastWeek() {
        guard let lastPoint = lifePoints.last else { return }
        
        // Нам нужно откатить текущие жизни на состояние ДО этого расчета,
        // чтобы повторный вызов processWeekEnd не прибавил очки дважды.
        if let gameState = gameStateRepository.getGameState() {
            let livesBeforeLastCalculation = gameState.currentLives - lastPoint.value
            
            let resetGameState = GameStateModel(
                currentLives: max(0, livesBeforeLastCalculation),
                isGameOver: livesBeforeLastCalculation <= 0,
                lastWeekCalculationDate: gameState.lastWeekCalculationDate,
                updatedAt: Date()
            )
            
            do {
                try gameStateRepository.saveGameState(resetGameState)
                // Теперь запускаем пересчет по новой логике
                try processWeekEndUseCase.execute(weekStartDate: lastPoint.weekStartDate)
                // Перезагружаем данные
                loadData()
                print("Recalculation successful")
            } catch {
                print("Error during recalculation: \(error)")
            }
        }
    }
    
    func deleteAllTrashHabits() {
        let allRaw = habitRepository.getAllHabitsRaw()
        let activeOnMain = habitRepository.getAllHabits()
        let activeIds = Set(activeOnMain.map { $0.id })
        
        let trashHabits = allRaw.filter { !activeIds.contains($0.id) }
        
        print("\n--- 🧹 НАЧИНАЮ КРИТИЧЕСКУЮ ОЧИСТКУ МУСОРА ---")
        for trash in trashHabits {
            do {
                // 1. Убираем из целей
                try goalRepository.removeHabitFromGoals(trash.id)
                // 2. Удаляем саму привычку (и все её выполнения каскадом)
                try habitRepository.hardDeleteHabit(trash.id)
                print("✅ Удалено: [\(trash.name)] (\(trash.id))")
            } catch {
                print("❌ Ошибка удаления [\(trash.name)]: \(error)")
            }
        }
        print("--- 🏁 ОЧИСТКА ЗАВЕРШЕНА ---\n")
        
        // Перезагружаем данные для обновления GUI
        loadData()
    }
    
    func debugPrintWeeklyAnalysis() {
        // 1. ПЕЧАТЬ АНАЛИЗА НЕДЕЛИ
        if let report = lastWeekReport {
            print("\n--- 📊 ДЕТАЛЬНЫЙ ОТЧЕТ ПО ШТРАФАМ И НАЧИСЛЕНИЯМ (С ID) ---")
            print("Период: \(report.weekStartDate.formatted(date: .abbreviated, time: .omitted))")
            print("Итоговое изменение: \(report.totalXPChange >= 0 ? "+" : "")\(report.totalXPChange) XP")
            print("-------------------------------------------")
            
            for analysis in report.analyses {
                print("ID: \(analysis.id)")
                print("ПРИВЫЧКА: [\(analysis.habitName)] (\(analysis.habitType.displayName))")
                
                if let weekly = analysis.weeklyTargetImpact {
                    let label = weekly >= 0 ? "✅ Начислено за цель" : "⚠️ ШТРАФ (недельный)"
                    print("  ↳ \(label): \(weekly) XP")
                }
                
                for day in analysis.details {
                    if day.target > 0 || day.completions > 0 || day.impact != 0 {
                        let label = day.impact >= 0 ? "XP" : "⚠️ ШТРАФ"
                        print("  ↳ \(day.date.formatted(.dateTime.weekday())): \(day.completions)\(day.target > 0 ? "/\(day.target)" : "") → \(day.impact) \(label)")
                    }
                }
                print("  ИТОГ ПО ПРИВЫЧКЕ: \(analysis.totalImpact) XP")
                print("-------------------------------------------")
            }
        } else {
            print("\n--- 📊 АНАЛИЗ ЗА ПРОШЛУЮ НЕДЕЛЮ ОТСУТСТВУЕТ ---")
        }

        // 2. ПЕЧАТЬ РАЗДЕЛЕННОГО СПИСКА БАЗЫ
        let allRaw = habitRepository.getAllHabitsRaw()
        let activeOnMain = habitRepository.getAllHabits()
        let activeIds = Set(activeOnMain.map { $0.id })
        
        print("\n--- 🟢 АКТИВНЫЕ ПРИВЫЧКИ (ВИДИМЫЕ НА ГЛАВНОМ ЭКРАНЕ) ---")
        for h in allRaw where activeIds.contains(h.id) {
            print("ID: \(h.id) | ИМЯ: [\(h.name)] | ТИП: \(h.type.displayName)")
        }
        
        print("\n--- 🔴 МУСОР (НЕВИДИМЫЕ, МОЖНО УДАЛЯТЬ) ---")
        for h in allRaw where !activeIds.contains(h.id) {
            print("ID: \(h.id) | ИМЯ: [\(h.name)] | ТИП: \(h.type.displayName)")
        }
        print("--- КОНЕЦ СПИСКА ---\n")
    }
}

