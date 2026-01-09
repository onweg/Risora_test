//
//  MainView.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import SwiftUI

struct MainView: View {
    @StateObject private var habitsListViewModel: HabitsListViewModel
    @StateObject private var chartViewModel: LifePointsChartViewModel
    
    private let checkGameOverUseCase: CheckGameOverUseCaseProtocol
    private let resetGameUseCase: ResetGameUseCaseProtocol
    @State private var isGameOver: Bool = false
    @State private var selectedTab: Int = 0
    
    init(container: DependencyContainer) {
        _habitsListViewModel = StateObject(wrappedValue: container.makeHabitsListViewModel())
        _chartViewModel = StateObject(wrappedValue: container.makeLifePointsChartViewModel())
        self.checkGameOverUseCase = container.checkGameOverUseCase
        self.resetGameUseCase = container.resetGameUseCase
    }
    
    var body: some View {
        Group {
            if isGameOver {
                GameOverView(chartViewModel: chartViewModel) {
                    resetGame()
                }
            } else {
                TabView(selection: $selectedTab) {
                    HabitsListView(viewModel: habitsListViewModel)
                        .tabItem {
                            Label("Привычки", systemImage: "list.bullet")
                        }
                        .tag(0)
                    
                    LifePointsChartView(viewModel: chartViewModel)
                        .tabItem {
                            Label("График", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(1)
                }
            }
        }
        .onAppear {
            checkGameOver()
        }
        .onChange(of: habitsListViewModel.isGameOver) { newValue in
            isGameOver = newValue
        }
    }
    
    private func checkGameOver() {
        isGameOver = checkGameOverUseCase.execute()
    }
    
    private func resetGame() {
        do {
            try resetGameUseCase.execute()
            isGameOver = false
            habitsListViewModel.loadData()
            chartViewModel.loadData()
        } catch {
            print("Error resetting game: \(error)")
        }
    }
}

