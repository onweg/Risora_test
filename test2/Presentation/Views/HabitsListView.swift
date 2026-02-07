//
//  HabitsListView.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import SwiftUI

struct HabitsListView: View {
    @StateObject private var viewModel: HabitsListViewModel
    private let container: DependencyContainer
    @State private var showingAddHabit = false
    @State private var showingEditHabit = false
    @State private var habitToEdit: HabitModel?

    init(viewModel: HabitsListViewModel, container: DependencyContainer) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.container = container
    }

    var body: some View {
        NavigationView {
            HabitsCalendarView(
                viewModel: viewModel,
                onEditHabit: {
                    habitToEdit = $0
                    showingEditHabit = true
                },
                onDeleteHabit: { id, name in
                    viewModel.showHardDeleteHabitConfirmation(habitId: id, habitName: name)
                }
            )
            .navigationTitle("Привычки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddHabit = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit, onDismiss: {
                viewModel.refresh()
                NotificationService.shared.rescheduleHabitReminders(habits: container.habitRepository.getAllHabitsRaw())
            }) {
                AddHabitView(viewModel: container.makeAddHabitViewModel())
            }
            .sheet(isPresented: $showingEditHabit, onDismiss: {
                viewModel.refresh()
                habitToEdit = nil
                NotificationService.shared.rescheduleHabitReminders(habits: container.habitRepository.getAllHabitsRaw())
            }) {
                if let habit = habitToEdit {
                    AddHabitView(viewModel: container.makeAddHabitViewModel(editingHabit: habit))
                }
            }
            .onAppear {
                viewModel.loadData()
            }
            .alert("Удалить привычку?", isPresented: $viewModel.showingDeleteHabitConfirmation) {
                Button("Отмена", role: .cancel) {
                    viewModel.habitToDelete = nil
                }
                Button("Удалить", role: .destructive) {
                    if let habitId = viewModel.habitToDelete?.id {
                        viewModel.deleteHabitCompletions(habitId)
                    }
                }
            } message: {
                if let habitName = viewModel.habitToDelete?.name {
                    Text("Вы уверены, что хотите удалить привычку \"\(habitName)\" из списка? Она будет удалена с сегодняшнего дня и все будущие дни. Прошлые дни останутся для просмотра.")
                }
            }
            .alert("Нельзя отметить", isPresented: $viewModel.showingFutureDayAlert) {
                Button("Понятно", role: .cancel) {
                    viewModel.showingFutureDayAlert = false
                }
            } message: {
                Text("Отметить не получится, так как это будущий день. Выполнять привычки и задачи можно только за сегодня или прошлые дни. Отменять выполнение в прошлом можно.")
            }
            .alert("Удалить привычку навсегда?", isPresented: Binding(
                get: { viewModel.habitToHardDelete != nil },
                set: { if !$0 { viewModel.habitToHardDelete = nil } }
            )) {
                Button("Отмена", role: .cancel) {
                    viewModel.habitToHardDelete = nil
                }
                Button("Удалить", role: .destructive) {
                    if let id = viewModel.habitToHardDelete?.id {
                        viewModel.deleteHabit(habitId: id)
                    }
                }
            } message: {
                if let name = viewModel.habitToHardDelete?.name {
                    Text("Привычка «\(name)» будет удалена безвозвратно вместе со всеми выполнениями.")
                }
            }
        }
    }
}

struct HabitRowView: View {
    let habit: HabitModel
    let themeName: String?
    let isCompleted: Bool
    let completionCount: Int
    let weeklyCompletionCount: Int
    let weeklyCompletionDates: [Date]
    let canEdit: Bool
    let selectedDate: Date
    let onToggle: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Чекбокс или кнопка для вредных привычек
            if habit.type == .bad {
                // Для вредных привычек показываем количество и иконку "+"
                HStack(spacing: 8) {
                    if completionCount > 0 {
                        Text("\(completionCount)x")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(canEdit ? .red : .gray.opacity(0.3))
                        .font(.title2)
                }
            } else {
                // Для полезных привычек — только иконка выполнен/не выполнен
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(canEdit ? (isCompleted ? .green : .gray) : .gray.opacity(0.3))
                    .font(.title2)
            }
            
            // Информация о привычке
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    if !habit.isTask {
                        Text("XP: \(habit.xpValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let theme = themeName, !theme.isEmpty {
                        Text(theme)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                    if let timeWindow = habit.allowedTimeWindowString {
                        Text(timeWindow)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if !canEdit {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray.opacity(0.5))
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .opacity(canEdit ? 1.0 : 0.6)
        .contentShape(Rectangle())
        .onTapGesture {
            if canEdit {
                onToggle()
            }
        }
    }
}

