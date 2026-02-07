//
//  AddHabitView.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import SwiftUI

private let weekdayLabels = [1: "Вс", 2: "Пн", 3: "Вт", 4: "Ср", 5: "Чт", 6: "Пт", 7: "Сб"]

struct AddHabitView: View {
    @ObservedObject var viewModel: AddHabitViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showThemesManager = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Тип"), footer: Text("Привычка — за выполнение начисляется XP. Задача — без награды.")) {
                    Picker("Тип", selection: $viewModel.isTask) {
                        Text("Привычка").tag(false)
                        Text("Задача").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Название"), footer: Text("Обязательно.")) {
                    TextField("Например: Выпить таблетку", text: $viewModel.name)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                }
                
                Section(header: Text("Дни недели"), footer: Text("Выберите хотя бы один день. Обязательно.")) {
                    HStack(spacing: 12) {
                        ForEach([1, 2, 3, 4, 5, 6, 7], id: \.self) { day in
                            let isOn = viewModel.activeWeekdays.contains(day)
                            Button(action: { viewModel.toggleWeekday(day) }) {
                                Text(weekdayLabels[day] ?? "?")
                                    .font(.subheadline.weight(.medium))
                                    .frame(width: 36, height: 36)
                                    .background(isOn ? Color.accentColor : Color.gray.opacity(0.2))
                                    .foregroundColor(isOn ? .white : .primary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Период"), footer: Text("Привычка будет отображаться с даты начала и до даты окончания (или без срока). Обязательно задайте при необходимости.")) {
                    Toggle("Задать дату начала", isOn: $viewModel.useStartDate)
                    if viewModel.useStartDate {
                        DatePicker("Начало", selection: $viewModel.startDate, displayedComponents: .date)
                    }
                    Toggle("Без срока (вечно)", isOn: $viewModel.noEndDate)
                    if !viewModel.noEndDate {
                        DatePicker("Конец", selection: $viewModel.endDate, displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Сфера / тема"), footer: Text("Обязательно выберите тему. Если списка нет — нажмите «Управление темами» и создайте тему.")) {
                    Picker("Тема", selection: $viewModel.selectedThemeId) {
                        Text("Выберите тему").tag(nil as UUID?)
                        ForEach(viewModel.themes) { theme in
                            Text(theme.name).tag(theme.id as UUID?)
                        }
                    }
                    .disabled(viewModel.themes.isEmpty)
                    Button("Управление темами") {
                        showThemesManager = true
                    }
                }
                
                Section(header: Text("Время выполнения"), footer: Text("Обязательно укажите, с какого по какое время можно выполнить привычку.")) {
                    Toggle("Ограничить время (обязательно)", isOn: $viewModel.allowedTimeWindowEnabled)
                    if viewModel.allowedTimeWindowEnabled {
                        DatePicker("С", selection: $viewModel.allowedStartTime, displayedComponents: .hourAndMinute)
                        DatePicker("До", selection: $viewModel.allowedEndTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section(header: Text("Напоминание (необязательно)"), footer: Text("В это время придёт уведомление.")) {
                    Toggle("Включить напоминание", isOn: $viewModel.notificationEnabled)
                    if viewModel.notificationEnabled {
                        DatePicker("Время", selection: $viewModel.notificationTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                if !viewModel.isTask {
                    Section(header: Text("Значение XP"), footer: Text("Сколько XP начислять за выполнение привычки.")) {
                        Stepper("XP: \(viewModel.xpValue)", value: $viewModel.xpValue, in: 1...50)
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? (viewModel.isTask ? "Редактировать задачу" : "Редактировать привычку") : (viewModel.isTask ? "Новая задача" : "Новая привычка"))
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
                    .disabled(!viewModel.canSave)
                }
            }
            .sheet(isPresented: $showThemesManager) {
                ThemesManagerView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadFormFromEditingHabit()
            }
        }
    }
}

/// Экран управления темами: список + добавление/редактирование темы с цветом.
struct ThemesManagerView: View {
    @ObservedObject var viewModel: AddHabitViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingThemeForm = false
    @State private var editingTheme: ThemeModel? = nil
    @State private var formThemeName = ""
    @State private var formThemeColor: Color = .blue

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.themes) { theme in
                    HStack(spacing: 12) {
                        if let hex = theme.colorHex, let color = Color(hex: hex) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(color)
                                .frame(width: 28, height: 28)
                        }
                        Text(theme.name)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingTheme = theme
                        formThemeName = theme.name
                        formThemeColor = theme.colorHex.flatMap { Color(hex: $0) } ?? .blue
                        showingThemeForm = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            try? viewModel.deleteTheme(id: theme.id)
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Сферы / темы")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Готово") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingTheme = nil
                        formThemeName = ""
                        formThemeColor = .blue
                        showingThemeForm = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingThemeForm) {
                ThemeFormSheet(
                    name: $formThemeName,
                    color: $formThemeColor,
                    isEditing: editingTheme != nil,
                    onSave: {
                        if let theme = editingTheme {
                            try? viewModel.updateTheme(id: theme.id, name: formThemeName, colorHex: formThemeColor.hexString)
                        } else {
                            try? viewModel.addTheme(name: formThemeName, colorHex: formThemeColor.hexString)
                        }
                        showingThemeForm = false
                    },
                    onCancel: { showingThemeForm = false }
                )
            }
        }
    }
}

/// Лист формы темы: название и цвет (фон для квадратиков на таймлайне).
private struct ThemeFormSheet: View {
    @Binding var name: String
    @Binding var color: Color
    let isEditing: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Название")) {
                    TextField("Например: Работа, Спорт", text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section(header: Text("Цвет (фон в календаре)")) {
                    ColorPicker("Цвет темы", selection: $color, supportsOpacity: false)
                }
            }
            .navigationTitle(isEditing ? "Редактировать тему" : "Новая тема")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        onSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

