//
//  AddHabitView.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import SwiftUI

struct AddHabitView: View {
    @ObservedObject var viewModel: AddHabitViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Название")) {
                    TextField("Например: Выпить таблетку", text: $viewModel.name)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                }
                
                Section(header: Text("Тип привычки")) {
                    Picker("Тип", selection: $viewModel.selectedType) {
                        ForEach(HabitType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                // Настройки для полезных привычек
                if viewModel.selectedType == .good {
                    Section(header: Text("Цель")) {
                        Picker("Тип цели", selection: $viewModel.targetType) {
                            ForEach(HabitTargetType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        
                        if viewModel.targetType == .daily {
                            Stepper("Сколько раз в день: \(viewModel.targetValue)", value: $viewModel.targetValue, in: 1...10)
                        } else {
                            Stepper("Сколько раз в неделю: \(viewModel.targetValue)", value: $viewModel.targetValue, in: 1...20)
                        }
                    }
                    
                    Section(header: Text("Начисление XP")) {
                        Toggle("Пропорциональное начисление", isOn: $viewModel.proportionalReward)
                        
                        if viewModel.proportionalReward {
                            Text("Если выполнил меньше цели, получишь пропорционально выполненному (например, 2 из 3 = 2/3 XP)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Все или ничего: если не выполнил цель полностью, не получишь XP")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Настройки для вредных привычек
                if viewModel.selectedType == .bad {
                    Section(header: Text("Лимиты (опционально)")) {
                        Stepper("Минимальный порог за день: \(viewModel.badDailyMinThreshold == 0 ? "Без лимита" : "\(viewModel.badDailyMinThreshold)")", value: $viewModel.badDailyMinThreshold, in: 0...20)
                        
                        Stepper("Минимальный порог за неделю: \(viewModel.badWeeklyMinThreshold == 0 ? "Без лимита" : "\(viewModel.badWeeklyMinThreshold)")", value: $viewModel.badWeeklyMinThreshold, in: 0...50)
                        
                        if viewModel.badDailyMinThreshold > 0 || viewModel.badWeeklyMinThreshold > 0 {
                            Text("Если выполнил меньше порога, ничего не будет вычитаться. Если больше - вычитается за каждое выполнение.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Каждое выполнение будет вычитаться из жизней при подсчете в конце недели.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Значение XP")) {
                    Stepper("XP: \(viewModel.xpValue)", value: $viewModel.xpValue, in: 1...50)
                }
            }
            .navigationTitle("Новая привычка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        do {
                            try viewModel.saveHabit()
                            dismiss()
                        } catch {
                            print("Error saving habit: \(error)")
                        }
                    }
                    .disabled(viewModel.name.isEmpty)
                }
            }
        }
    }
}

