//
//  AddHabitViewModel.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import SwiftUI

/// Номера дней недели: 1 = вс, 2 = пн, ... 7 = сб (Calendar.component(.weekday))
private let allWeekdays = Set(1...7)

@MainActor
class AddHabitViewModel: ObservableObject {
    @Published var name: String = ""
    /// false = привычка (начисляется XP), true = задача (XP не начисляется).
    @Published var isTask: Bool = false
    @Published var xpValue: Int = 10
    
    // Дни недели (по умолчанию все). Включённые дни = привычка активна.
    @Published var activeWeekdays: Set<Int> = allWeekdays
    
    // Даты начала и окончания
    @Published var startDate: Date = Date()
    @Published var useStartDate: Bool = false // если false — считаем началом дату создания
    @Published var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @Published var noEndDate: Bool = true // по умолчанию без срока
    
    // Тема/сфера
    @Published var selectedThemeId: UUID?
    
    // Окно времени выполнения (с — по), по умолчанию включено (обязательное поле)
    @Published var allowedTimeWindowEnabled: Bool = true
    @Published var allowedStartTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var allowedEndTime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    
    // Напоминание
    @Published var notificationEnabled: Bool = false
    @Published var notificationTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    
    private let habitRepository: HabitRepositoryProtocol
    private let themeRepository: ThemeRepositoryProtocol
    private var editingHabitId: UUID?
    private var editingCreatedAt: Date?
    private var editingSortOrder: Int = 0
    private let editingHabit: HabitModel?

    var themes: [ThemeModel] { themeRepository.getAllThemes() }
    var isEditing: Bool { editingHabitId != nil }
    
    /// Можно ли сохранить привычку: заполнены все обязательные поля (кроме напоминания).
    var canSave: Bool {
        let nameOK = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let daysOK = !activeWeekdays.isEmpty
        let themeOK = selectedThemeId != nil && !themes.isEmpty
        let timeWindowOK = allowedTimeWindowEnabled
        return nameOK && daysOK && themeOK && timeWindowOK
    }
    
    func addTheme(name: String, colorHex: String? = nil) throws {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        try themeRepository.createTheme(ThemeModel(name: name, colorHex: colorHex))
        objectWillChange.send()
    }

    func updateTheme(id: UUID, name: String, colorHex: String?) throws {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let existing = themeRepository.getAllThemes().first(where: { $0.id == id })
        let sortOrder = existing?.sortOrder ?? 0
        try themeRepository.updateTheme(ThemeModel(id: id, name: name, colorHex: colorHex, sortOrder: sortOrder))
        objectWillChange.send()
    }

    func deleteTheme(id: UUID) throws {
        try themeRepository.deleteTheme(id: id)
        if selectedThemeId == id { selectedThemeId = nil }
        objectWillChange.send()
    }
    
    nonisolated init(habitRepository: HabitRepositoryProtocol, themeRepository: ThemeRepositoryProtocol, editingHabit: HabitModel? = nil) {
        self.habitRepository = habitRepository
        self.themeRepository = themeRepository
        self.editingHabit = editingHabit
        self.editingHabitId = editingHabit?.id
        self.editingCreatedAt = editingHabit?.createdAt
        self.editingSortOrder = editingHabit?.sortOrder ?? 0
    }

    /// Вызвать из view (например в .onAppear), чтобы подставить данные редактируемой привычки в форму.
    func loadFormFromEditingHabit() {
        guard let h = editingHabit else { return }
        name = h.name
        isTask = h.isTask
        xpValue = h.xpValue
        activeWeekdays = h.activeWeekdays.isEmpty ? allWeekdays : h.activeWeekdays
        useStartDate = h.startDate != nil
        startDate = h.startDate ?? Date()
        noEndDate = h.endDate == nil
        endDate = h.endDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        selectedThemeId = h.themeId
        allowedTimeWindowEnabled = h.hasAllowedTimeWindow
        if let sh = h.allowedStartHour, let sm = h.allowedStartMinute {
            allowedStartTime = Calendar.current.date(from: DateComponents(hour: sh, minute: sm)) ?? allowedStartTime
        }
        if let eh = h.allowedEndHour, let em = h.allowedEndMinute {
            allowedEndTime = Calendar.current.date(from: DateComponents(hour: eh, minute: em)) ?? allowedEndTime
        }
        notificationEnabled = h.hasNotification
        if let nh = h.notificationHour, let nm = h.notificationMinute {
            notificationTime = Calendar.current.date(from: DateComponents(hour: nh, minute: nm)) ?? notificationTime
        }
    }
    
    func toggleWeekday(_ weekday: Int) {
        guard (1...7).contains(weekday) else { return }
        if activeWeekdays.contains(weekday) {
            if activeWeekdays.count > 1 {
                activeWeekdays.remove(weekday)
            }
        } else {
            activeWeekdays.insert(weekday)
        }
    }
    
    func saveHabit() throws {
        let calendar = Calendar.current
        let effectiveStart: Date? = useStartDate ? calendar.startOfDay(for: startDate) : nil
        let effectiveEnd: Date? = noEndDate ? nil : calendar.startOfDay(for: endDate)
        let (notifHour, notifMin): (Int?, Int?) = notificationEnabled
            ? (calendar.component(.hour, from: notificationTime), calendar.component(.minute, from: notificationTime))
            : (nil, nil)
        let (startH, startM, endH, endM): (Int?, Int?, Int?, Int?) = allowedTimeWindowEnabled
            ? (calendar.component(.hour, from: allowedStartTime), calendar.component(.minute, from: allowedStartTime),
               calendar.component(.hour, from: allowedEndTime), calendar.component(.minute, from: allowedEndTime))
            : (nil, nil, nil, nil)
        // Привычка «создаётся» с выбранной даты начала — тогда она и появится в списке с этого дня
        let createdAt = effectiveStart ?? Date()
        
        let habitId = editingHabitId ?? UUID()
        let habitCreatedAt = editingCreatedAt ?? createdAt
        let habit = HabitModel(
            id: habitId,
            name: name,
            type: .good,
            frequency: nil,
            frequencyCount: 0,
            xpValue: isTask ? 0 : xpValue,
            isTask: isTask,
            createdAt: habitCreatedAt,
            targetType: .daily,
            targetValue: 1,
            dailyTarget: 1,
            weeklyTarget: 0,
            proportionalReward: false,
            sortOrder: editingHabitId != nil ? editingSortOrder : 0,
            activeWeekdays: activeWeekdays.isEmpty ? allWeekdays : activeWeekdays,
            startDate: effectiveStart,
            endDate: effectiveEnd,
            themeId: selectedThemeId,
            notificationHour: notifHour,
            notificationMinute: notifMin,
            allowedStartHour: startH,
            allowedStartMinute: startM,
            allowedEndHour: endH,
            allowedEndMinute: endM
        )
        if editingHabitId != nil {
            try habitRepository.updateHabit(habit)
        } else {
            try habitRepository.createHabit(habit)
        }
        NotificationService.shared.rescheduleHabitReminders(habits: habitRepository.getAllHabitsRaw())
    }
}

