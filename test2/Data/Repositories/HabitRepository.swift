//
//  HabitRepository.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import CoreData

protocol HabitRepositoryProtocol {
    func getAllHabits() -> [HabitModel] // Только активные (не удаленные до сегодня)
    func getAllHabitsIncludingDeleted(forDate: Date) -> [HabitModel] // Все привычки для конкретной даты (включая удаленные позже)
    func createHabit(_ habit: HabitModel) throws
    func deleteHabit(_ id: UUID) throws
    func getCompletionsForWeek(weekStartDate: Date) -> [UUID: [Date]]
    func getCompletionCountForWeek(habitId: UUID, weekStartDate: Date) -> Int
    func getDailyCompletionsForWeek(habitId: UUID, weekStartDate: Date) -> [Date: Int] // Дата -> количество выполнений
    func getCompletionsForDate(_ date: Date) -> [UUID]
    func completeHabit(_ habitId: UUID, date: Date) throws
    func uncompleteHabit(_ habitId: UUID, date: Date) throws
    func removeLastCompletion(_ habitId: UUID, date: Date) throws
    func removeLastCompletionForWeek(_ habitId: UUID, weekStartDate: Date) throws
    func isHabitCompleted(_ habitId: UUID, date: Date) -> Bool
    func getCompletionCountForDate(_ habitId: UUID, date: Date) -> Int
    func getCompletionDatesForWeek(habitId: UUID, weekStartDate: Date) -> [Date] // Возвращает даты выполнения за неделю
    func markHabitAsDeletedFromDate(_ habitId: UUID, fromDate: Date) throws // Помечает привычку как удаленную с определенной даты
    func getHabitDeletedFromDate(habitId: UUID) -> Date? // Возвращает дату удаления привычки (если есть)
    func updateHabitOrder(habitIds: [UUID]) throws // Обновляет порядок привычек
    func getAllHabitsRaw() -> [HabitModel] // Возвращает ВООБЩЕ ВСЕ привычки из базы
    func hardDeleteHabit(_ habitId: UUID) throws // Удаляет запись навсегда из базы
}

class HabitRepository: HabitRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getAllHabits() -> [HabitModel] {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Habit.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Habit.createdAt, ascending: true)
        ]
        
        do {
            let habits = try context.fetch(request)
            let today = Calendar.current.startOfDay(for: Date())
            
            return habits.compactMap { habit in
                // Пропускаем привычки, которые удалены до сегодня
                if let deletedFromDate = habit.deletedFromDate {
                    let deletedDate = Calendar.current.startOfDay(for: deletedFromDate)
                    if deletedDate <= today {
                        return nil // Привычка удалена, не показываем
                    }
                }
                
                return HabitModel(
                    id: habit.id ?? UUID(),
                    name: habit.name ?? "",
                    type: HabitType(rawValue: habit.type ?? "good") ?? .good,
                    frequency: nil, // Deprecated field, not stored in Core Data
                    frequencyCount: 0, // Deprecated field, not stored in Core Data
                    xpValue: Int(habit.xpValue),
                    createdAt: habit.createdAt ?? Date(),
                    targetType: habit.targetType != nil ? HabitTargetType(rawValue: habit.targetType!) : nil,
                    targetValue: Int(habit.targetValue),
                    dailyTarget: Int(habit.dailyTarget),
                    weeklyTarget: Int(habit.weeklyTarget),
                    proportionalReward: habit.proportionalReward,
                    sortOrder: Int(habit.sortOrder)
                )
            }
        } catch {
            print("Error fetching habits: \(error)")
            return []
        }
    }
    
    func getAllHabitsIncludingDeleted(forDate: Date) -> [HabitModel] {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Habit.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Habit.createdAt, ascending: true)
        ]
        
        do {
            let habits = try context.fetch(request)
            let selectedDate = Calendar.current.startOfDay(for: forDate)
            
            return habits.compactMap { habit in
                // Показываем привычку, если она не удалена до выбранной даты
                if let deletedFromDate = habit.deletedFromDate {
                    let deletedDate = Calendar.current.startOfDay(for: deletedFromDate)
                    if deletedDate <= selectedDate {
                        return nil // Привычка удалена до выбранной даты, не показываем
                    }
                }
                
                return HabitModel(
                    id: habit.id ?? UUID(),
                    name: habit.name ?? "",
                    type: HabitType(rawValue: habit.type ?? "good") ?? .good,
                    frequency: nil,
                    frequencyCount: 0,
                    xpValue: Int(habit.xpValue),
                    createdAt: habit.createdAt ?? Date(),
                    targetType: habit.targetType != nil ? HabitTargetType(rawValue: habit.targetType!) : nil,
                    targetValue: Int(habit.targetValue),
                    dailyTarget: Int(habit.dailyTarget),
                    weeklyTarget: Int(habit.weeklyTarget),
                    proportionalReward: habit.proportionalReward,
                    sortOrder: Int(habit.sortOrder)
                )
            }
        } catch {
            print("Error fetching habits: \(error)")
            return []
        }
    }
    
    func createHabit(_ habit: HabitModel) throws {
        // Определяем максимальный sortOrder для новой привычки
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.sortOrder, ascending: false)]
        request.fetchLimit = 1
        
        var maxSortOrder = 0
        if let lastHabit = try? context.fetch(request).first {
            maxSortOrder = Int(lastHabit.sortOrder)
        }
        
        let habitEntity = Habit(context: context)
        habitEntity.id = habit.id
        habitEntity.name = habit.name
        habitEntity.type = habit.type.rawValue
        // frequency and frequencyCount are deprecated and not stored in Core Data
        habitEntity.xpValue = Int16(habit.xpValue)
        habitEntity.createdAt = habit.createdAt
        habitEntity.targetType = habit.targetType?.rawValue
        habitEntity.targetValue = Int16(habit.targetValue)
        habitEntity.dailyTarget = Int16(habit.dailyTarget)
        habitEntity.weeklyTarget = Int16(habit.weeklyTarget)
        habitEntity.proportionalReward = habit.proportionalReward
        habitEntity.sortOrder = Int32(maxSortOrder + 1)
        
        try context.save()
        
        // Привычка создается пустой (0/3, 0/1 и т.д.)
        // Пользователь сам будет отмечать выполнения
    }
    
    func deleteHabit(_ id: UUID) throws {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let habit = try context.fetch(request).first {
            context.delete(habit)
            try context.save()
        }
    }
    
    func getCompletionsForWeek(weekStartDate: Date) -> [UUID: [Date]] {
        let calendar = Calendar.current
        guard let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else {
            return [:]
        }
        
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", weekStartDate as NSDate, weekEndDate as NSDate)
        
        do {
            let completions = try context.fetch(request)
            var result: [UUID: [Date]] = [:]
            
            for completion in completions {
                guard let habitId = completion.habit?.id,
                      let date = completion.date else { continue }
                
                if result[habitId] == nil {
                    result[habitId] = []
                }
                result[habitId]?.append(date)
            }
            
            return result
        } catch {
            print("Error fetching completions: \(error)")
            return [:]
        }
    }
    
    func getCompletionCountForWeek(habitId: UUID, weekStartDate: Date) -> Int {
        let calendar = Calendar.current
        guard let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else {
            return 0
        }
        
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit.id == %@ AND date >= %@ AND date <= %@",
            habitId as CVarArg,
            weekStartDate as NSDate,
            weekEndDate as NSDate
        )
        
        do {
            let completions = try context.fetch(request)
            return completions.count
        } catch {
            print("Error fetching completion count for week: \(error)")
            return 0
        }
    }
    
    func getDailyCompletionsForWeek(habitId: UUID, weekStartDate: Date) -> [Date: Int] {
        let calendar = Calendar.current
        guard let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else {
            return [:]
        }
        
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit.id == %@ AND date >= %@ AND date <= %@",
            habitId as CVarArg,
            weekStartDate as NSDate,
            weekEndDate as NSDate
        )
        
        do {
            let completions = try context.fetch(request)
            var result: [Date: Int] = [:]
            
            for completion in completions {
                guard let date = completion.date else { continue }
                let dayStart = calendar.startOfDay(for: date)
                result[dayStart, default: 0] += 1
            }
            
            return result
        } catch {
            print("Error fetching daily completions: \(error)")
            return [:]
        }
    }
    
    func getCompletionsForDate(_ date: Date) -> [UUID] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let completions = try context.fetch(request)
            return completions.compactMap { $0.habit?.id }
        } catch {
            print("Error fetching completions for date: \(error)")
            return []
        }
    }
    
    func completeHabit(_ habitId: UUID, date: Date) throws {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", habitId as CVarArg)
        
        guard let habit = try context.fetch(request).first else {
            throw NSError(domain: "HabitRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Habit not found"])
        }
        
        let habitType = HabitType(rawValue: habit.type ?? "good") ?? .good
        
        // Для полезных привычек проверяем лимит
        if habitType == .good {
            if let targetType = HabitTargetType(rawValue: habit.targetType ?? "") {
                if targetType == .daily {
                    // Цель на день - проверяем лимит на день
                    let dailyTarget = Int(habit.targetValue)
                    if dailyTarget > 0 {
                        let currentCount = getCompletionCountForDate(habitId, date: date)
                        if currentCount >= dailyTarget {
                            return // Уже достигнут лимит на день
                        }
                    }
                } else if targetType == .weekly {
                    // Цель на неделю - проверяем лимит на неделю
                    let calendar = Calendar.current
                    let weekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
                    let weeklyTarget = Int(habit.targetValue)
                    if weeklyTarget > 0 {
                        let currentWeeklyCount = getCompletionCountForWeek(habitId: habitId, weekStartDate: weekStartDate)
                        if currentWeeklyCount >= weeklyTarget {
                            return // Уже достигнут лимит на неделю
                        }
                    }
                }
            } else {
                // Обратная совместимость: используем dailyTarget
                let dailyTarget = Int(habit.dailyTarget)
                if dailyTarget > 0 {
                    let currentCount = getCompletionCountForDate(habitId, date: date)
                    if currentCount >= dailyTarget {
                        return // Уже достигнут лимит на день
                    }
                }
            }
        }
        
        // Для вредных привычек всегда добавляем новое выполнение (неограниченно)
        let calendar = Calendar.current
        let weekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        
        let completion = HabitCompletion(context: context)
        completion.id = UUID()
        completion.date = calendar.startOfDay(for: date)
        completion.weekStartDate = weekStartDate
        completion.habit = habit
        
        try context.save()
    }
    
    func uncompleteHabit(_ habitId: UUID, date: Date) throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit.id == %@ AND date >= %@ AND date < %@",
            habitId as CVarArg,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        let completions = try context.fetch(request)
        for completion in completions {
            context.delete(completion)
        }
        
        try context.save()
    }
    
    func isHabitCompleted(_ habitId: UUID, date: Date) -> Bool {
        let completedHabits = getCompletionsForDate(date)
        return completedHabits.contains(habitId)
    }
    
    func getCompletionCountForDate(_ habitId: UUID, date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit.id == %@ AND date >= %@ AND date < %@",
            habitId as CVarArg,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            let completions = try context.fetch(request)
            return completions.count
        } catch {
            print("Error fetching completion count: \(error)")
            return 0
        }
    }
    
    func removeLastCompletion(_ habitId: UUID, date: Date) throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit.id == %@ AND date >= %@ AND date < %@",
            habitId as CVarArg,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HabitCompletion.date, ascending: false)]
        request.fetchLimit = 1
        
        let completions = try context.fetch(request)
        if let lastCompletion = completions.first {
            context.delete(lastCompletion)
            try context.save()
        }
    }
    
    func removeLastCompletionForWeek(_ habitId: UUID, weekStartDate: Date) throws {
        let calendar = Calendar.current
        guard let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else {
            return
        }
        
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit.id == %@ AND date >= %@ AND date <= %@",
            habitId as CVarArg,
            weekStartDate as NSDate,
            weekEndDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HabitCompletion.date, ascending: false)]
        request.fetchLimit = 1
        
        let completions = try context.fetch(request)
        if let lastCompletion = completions.first {
            context.delete(lastCompletion)
            try context.save()
        }
    }
    
    func getCompletionDatesForWeek(habitId: UUID, weekStartDate: Date) -> [Date] {
        let calendar = Calendar.current
        guard let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else {
            return []
        }
        
        let request: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        request.predicate = NSPredicate(
            format: "habit.id == %@ AND date >= %@ AND date <= %@",
            habitId as CVarArg,
            weekStartDate as NSDate,
            weekEndDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HabitCompletion.date, ascending: true)]
        
        do {
            let completions = try context.fetch(request)
            return completions.compactMap { $0.date }
        } catch {
            print("Error fetching completion dates for week: \(error)")
            return []
        }
    }
    
    func markHabitAsDeletedFromDate(_ habitId: UUID, fromDate: Date) throws {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", habitId as CVarArg)
        
        guard let habit = try context.fetch(request).first else {
            throw NSError(domain: "HabitRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Habit not found"])
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: fromDate)
        habit.deletedFromDate = startOfDay
        
        // Удаляем все выполнения начиная с этой даты
        let completionRequest: NSFetchRequest<HabitCompletion> = HabitCompletion.fetchRequest()
        completionRequest.predicate = NSPredicate(
            format: "habit.id == %@ AND date >= %@",
            habitId as CVarArg,
            startOfDay as NSDate
        )
        
        let completions = try context.fetch(completionRequest)
        for completion in completions {
            context.delete(completion)
        }
        
        try context.save()
    }
    
    func getHabitDeletedFromDate(habitId: UUID) -> Date? {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", habitId as CVarArg)
        
        do {
            if let habit = try context.fetch(request).first {
                return habit.deletedFromDate
            }
            return nil
        } catch {
            print("Error fetching habit deleted date: \(error)")
            return nil
        }
    }
    
    func updateHabitOrder(habitIds: [UUID]) throws {
        // Обновляем sortOrder для всех привычек согласно новому порядку
        for (index, habitId) in habitIds.enumerated() {
            let request: NSFetchRequest<Habit> = Habit.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", habitId as CVarArg)
            
            if let habit = try context.fetch(request).first {
                habit.sortOrder = Int32(index)
            }
        }
        
        try context.save()
    }
    
    func getAllHabitsRaw() -> [HabitModel] {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        do {
            let habits = try context.fetch(request)
            return habits.map { habit in
                HabitModel(
                    id: habit.id ?? UUID(),
                    name: habit.name ?? "Без названия",
                    type: HabitType(rawValue: habit.type ?? "good") ?? .good,
                    xpValue: Int(habit.xpValue),
                    createdAt: habit.createdAt ?? Date(),
                    targetType: habit.targetType != nil ? HabitTargetType(rawValue: habit.targetType!) : nil,
                    targetValue: Int(habit.targetValue),
                    dailyTarget: Int(habit.dailyTarget),
                    weeklyTarget: Int(habit.weeklyTarget),
                    proportionalReward: habit.proportionalReward,
                    sortOrder: Int(habit.sortOrder)
                )
            }
        } catch {
            print("Error fetching raw habits: \(error)")
            return []
        }
    }
    
    func hardDeleteHabit(_ habitId: UUID) throws {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", habitId as CVarArg)
        
        if let habit = try context.fetch(request).first {
            context.delete(habit)
            try context.save()
            print("Habit \(habitId) hard deleted")
        }
    }
}

