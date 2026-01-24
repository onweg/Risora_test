//
//  GoalsView.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import SwiftUI

struct GoalsView: View {
    @StateObject private var viewModel: GoalsViewModel
    @State private var showingAddGoal = false
    
    init(viewModel: GoalsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.goals.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "target")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("Нет целей")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Добавьте первую цель, чтобы напомнить себе,\nзачем вы делаете все эти привычки")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(viewModel.goals) { goal in
                                GoalRowView(
                                    goal: goal,
                                    existingHabitIds: viewModel.getExistingHabitIds(from: goal.relatedHabitIds),
                                    onGetHabitName: { habitId in
                                        viewModel.getHabitName(for: habitId)
                                    }
                                )
                            }
                            .onMove(perform: viewModel.moveGoal)
                            .onDelete { indexSet in
                                if let firstIndex = indexSet.first {
                                    let goal = viewModel.goals[firstIndex]
                                    viewModel.showDeleteGoalConfirmation(goal.id, goalTitle: goal.title)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
            }
            .navigationTitle("Мои цели")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddGoal = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddGoal, onDismiss: {
            viewModel.refresh()
        }) {
            AddGoalView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadData()
        }
        .alert("Удалить цель?", isPresented: $viewModel.showingDeleteGoalConfirmation) {
            Button("Отмена", role: .cancel) {
                viewModel.goalToDelete = nil
            }
            Button("Удалить", role: .destructive) {
                if let goalId = viewModel.goalToDelete?.id {
                    viewModel.deleteGoal(goalId)
                }
            }
        } message: {
            if let goalTitle = viewModel.goalToDelete?.title {
                Text("Вы уверены, что хотите удалить цель \"\(goalTitle)\"?")
            }
        }
    }
}

struct GoalRowView: View {
    let goal: GoalModel
    let existingHabitIds: [UUID]
    let onGetHabitName: (UUID) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text(goal.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(goal.motivation)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.leading, 32)
            
            if !existingHabitIds.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Связанные привычки:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                    
                    ForEach(existingHabitIds, id: \.self) { habitId in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text(onGetHabitName(habitId))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 40)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddGoalView: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var motivation: String = ""
    @State private var selectedHabitIds: Set<UUID> = []
    
    private var allHabits: [HabitModel] {
        return viewModel.getAllHabits()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Название цели")) {
                    TextField("Например: Красивое тело", text: $title)
                }
                
                Section(header: Text("Мотивация")) {
                    TextEditor(text: $motivation)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if motivation.isEmpty {
                                    VStack {
                                        HStack {
                                            Text("Например: Потому что у меня есть привычка тренировок")
                                                .foregroundColor(.secondary)
                                                .padding(.top, 8)
                                                .padding(.leading, 4)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                }
                            },
                            alignment: .topLeading
                        )
                }
                
                Section(header: Text("Связанные привычки (опционально)")) {
                    if allHabits.isEmpty {
                        Text("Нет доступных привычек")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(allHabits) { habit in
                            HStack {
                                Button(action: {
                                    if selectedHabitIds.contains(habit.id) {
                                        selectedHabitIds.remove(habit.id)
                                    } else {
                                        selectedHabitIds.insert(habit.id)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: selectedHabitIds.contains(habit.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedHabitIds.contains(habit.id) ? .green : .gray)
                                        Text(habit.name)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Новая цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        if !title.isEmpty && !motivation.isEmpty {
                            viewModel.createGoal(
                                title: title,
                                motivation: motivation,
                                relatedHabitIds: Array(selectedHabitIds)
                            )
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || motivation.isEmpty)
                }
            }
        }
    }
}
