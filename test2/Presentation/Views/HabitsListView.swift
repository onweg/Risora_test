//
//  HabitsListView.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import SwiftUI

struct HabitsListView: View {
    @StateObject private var viewModel: HabitsListViewModel
    @State private var showingAddHabit = false
    
    init(viewModel: HabitsListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Календарь недели
                WeekCalendarView(
                    weekDays: viewModel.weekDays,
                    selectedDate: viewModel.selectedDate,
                    onDateSelected: { date in
                        viewModel.selectDate(date)
                    }
                )
                
                // Список привычек
                if viewModel.habits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Нет привычек")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Добавьте первую привычку")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.habits, id: \.habit.id) { item in
                            HabitRowView(
                                habit: item.habit,
                                isCompleted: item.isCompleted,
                                completionCount: item.completionCount,
                                weeklyCompletionCount: item.weeklyCompletionCount,
                                weeklyCompletionDates: item.weeklyCompletionDates,
                                canEdit: item.canEdit,
                                selectedDate: viewModel.selectedDate,
                                onToggle: {
                                    viewModel.toggleHabit(item.habit.id)
                                },
                                onSetCount: { count in
                                    viewModel.setHabitCompletionCount(item.habit.id, count: count)
                                },
                                onRemove: {
                                    viewModel.removeHabitCompletion(item.habit.id)
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Swipe для удаления одного выполнения
                                if item.canEdit && (item.completionCount > 0 || item.weeklyCompletionCount > 0) {
                                    Button(role: .destructive) {
                                        viewModel.removeHabitCompletion(item.habit.id)
                                    } label: {
                                        Label("Удалить выполнение", systemImage: "minus.circle")
                                    }
                                }
                                
                                // Swipe для удаления привычки из списка (с сегодня и все будущие)
                                if item.canEdit {
                                    Button(role: .destructive) {
                                        viewModel.showDeleteHabitConfirmation(item.habit.id, habitName: item.habit.name)
                                    } label: {
                                        Label("Удалить привычку", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Жизни: \(viewModel.currentLives)")
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
            }) {
                AddHabitView(
                    viewModel: AddHabitViewModel(
                        habitRepository: HabitRepository(context: PersistenceController.shared.container.viewContext)
                    )
                )
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
        }
    }
}

struct HabitRowView: View {
    let habit: HabitModel
    let isCompleted: Bool
    let completionCount: Int
    let weeklyCompletionCount: Int
    let weeklyCompletionDates: [Date]
    let canEdit: Bool
    let selectedDate: Date
    let onToggle: () -> Void
    let onSetCount: (Int) -> Void
    let onRemove: () -> Void
    
    @State private var showingCountPicker = false
    @State private var showingDeleteOptions = false
    
    private var displayCount: Int {
        if let targetType = habit.targetType, targetType == .weekly {
            return weeklyCompletionCount
        }
        return completionCount
    }
    
    private var displayTarget: Int {
        if let targetType = habit.targetType {
            return targetType == .daily ? habit.dailyTarget : habit.weeklyTarget
        }
        return habit.dailyTarget
    }
    
    private var maxCountForPicker: Int {
        if let targetType = habit.targetType {
            if targetType == .weekly {
                // Для недельных целей ограничиваем максимальное значение целевым значением
                return habit.targetValue > 0 ? habit.targetValue : 20
            } else {
                return max(habit.dailyTarget, 10)
            }
        }
        return max(habit.dailyTarget, 10)
    }
    
    private var isWeeklyTarget: Bool {
        habit.targetType == .weekly
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
    }
    
    private func isDateCompleted(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        return weeklyCompletionDates.contains { calendar.isDate($0, inSameDayAs: dayStart) }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Чекбокс или кнопка для вредных привычек
            if habit.type == .bad {
                // Для вредных привычек показываем количество и кнопку "+"
                HStack(spacing: 8) {
                    if completionCount > 0 {
                        Text("\(completionCount)x")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    Button(action: {
                        if canEdit {
                            onToggle()
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(canEdit ? .red : .gray.opacity(0.3))
                            .font(.title2)
                    }
                    .disabled(!canEdit)
                }
            } else {
                // Для полезных привычек показываем прогресс
                HStack(spacing: 8) {
                    if displayTarget > 0 {
                        Text("\(displayCount)/\(displayTarget)")
                            .font(.headline)
                            .foregroundColor(displayCount >= displayTarget ? .green : .orange)
                            .onTapGesture {
                                if canEdit {
                                    showingCountPicker = true
                                }
                            }
                    }
                    Button(action: {
                        if canEdit {
                            // Проверяем лимит перед добавлением
                            if isWeeklyTarget {
                                if displayCount < displayTarget {
                                    onToggle()
                                }
                            } else {
                                onToggle()
                            }
                        }
                    }) {
                        Image(systemName: (displayTarget > 0 && displayCount >= displayTarget) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(canEdit ? ((displayTarget > 0 && displayCount >= displayTarget) ? .green : .gray) : .gray.opacity(0.3))
                            .font(.title2)
                    }
                    .disabled(!canEdit || (isWeeklyTarget && displayCount >= displayTarget))
                }
            }
            
            // Информация о привычке
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(habit.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(habit.type == .good ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .foregroundColor(habit.type == .good ? .green : .red)
                        .cornerRadius(8)
                    
                    if habit.type == .good {
                        if let targetType = habit.targetType {
                            if targetType == .daily {
                                Text("\(habit.targetValue) раз/день")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(habit.targetValue) раз/неделю")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            // Обратная совместимость
                            Text("\(habit.dailyTarget) раз/день")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("∞ раз/день")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Text("XP: \(habit.xpValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Показываем дни выполнения для недельных задач
                if habit.type == .good && isWeeklyTarget && weeklyCompletionCount > 0 {
                    HStack(spacing: 4) {
                        Text("Выполнено:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        ForEach(weekDays, id: \.self) { day in
                            let isCompleted = isDateCompleted(day)
                            let calendar = Calendar.current
                            let dayNumber = calendar.component(.day, from: day)
                            Text("\(dayNumber)")
                                .font(.caption2)
                                .foregroundColor(isCompleted ? .green : .gray)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(isCompleted ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.top, 2)
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
            .sheet(isPresented: $showingCountPicker) {
                CountPickerView(
                    currentCount: displayCount,
                    maxCount: habit.type == .good ? maxCountForPicker : 20,
                    onSelect: { count in
                        onSetCount(count)
                        showingCountPicker = false
                    }
                )
            }
    }
}

struct CountPickerView: View {
    let currentCount: Int
    let maxCount: Int
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(0...maxCount, id: \.self) { count in
                    Button(action: {
                        onSelect(count)
                    }) {
                        HStack {
                            Text("\(count)")
                                .font(.headline)
                            Spacer()
                            if count == currentCount {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Выберите значение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

