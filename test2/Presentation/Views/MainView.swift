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
    @StateObject private var goalsViewModel: GoalsViewModel
    @StateObject private var attemptsHistoryViewModel: AttemptsHistoryViewModel
    
    private let checkGameOverUseCase: CheckGameOverUseCaseProtocol
    @State private var isGameOver: Bool = false
    @State private var selectedTab: Int = 0
    
    init(container: DependencyContainer) {
        _habitsListViewModel = StateObject(wrappedValue: container.makeHabitsListViewModel())
        _chartViewModel = StateObject(wrappedValue: container.makeLifePointsChartViewModel())
        _goalsViewModel = StateObject(wrappedValue: container.makeGoalsViewModel())
        _attemptsHistoryViewModel = StateObject(wrappedValue: container.makeAttemptsHistoryViewModel())
        self.checkGameOverUseCase = container.checkGameOverUseCase
    }
    
    var body: some View {
        Group {
            if isGameOver {
                GameOverView(chartViewModel: chartViewModel)
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
                    
                    GoalsView(viewModel: goalsViewModel)
                        .tabItem {
                            Label("Цели", systemImage: "target")
                        }
                        .tag(2)
                    
                    AttemptsHistoryView(viewModel: attemptsHistoryViewModel)
                        .tabItem {
                            Label("Попытки", systemImage: "clock.arrow.circlepath")
                        }
                        .tag(3)
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
}

