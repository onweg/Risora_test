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
    
    private let container: DependencyContainer
    @State private var selectedTab: Int = 0
    
    init(container: DependencyContainer) {
        self.container = container
        _habitsListViewModel = StateObject(wrappedValue: container.makeHabitsListViewModel())
        _chartViewModel = StateObject(wrappedValue: container.makeLifePointsChartViewModel())
        _goalsViewModel = StateObject(wrappedValue: container.makeGoalsViewModel())
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HabitsListView(viewModel: habitsListViewModel, container: container)
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
        }
        .onAppear {
            NotificationService.shared.rescheduleHabitReminders(habits: container.habitRepository.getAllHabitsRaw())
            habitsListViewModel.onHabitToggled = {
                chartViewModel.refresh()
            }
        }
    }
}

