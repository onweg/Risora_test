//
//  NotificationService.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import UserNotifications
import UIKit

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    private let notificationPhrases = [
        "Проверь свои привычки! Не забудь перед сном отметить все что сделал",
        "Эй, ты там еще живой? Проверь свои привычки перед сном!",
        "Не ложись спать! Сначала проверь, все ли привычки выполнены!",
        "Стоп-стоп-стоп! А привычки? Проверь перед сном, а то завтра будет грустно",
        "Последний шанс! Проверь свои привычки, пока не уснул!",
        "Не забудь перед сном проверить все привычки! Иначе завтра будете грустные баллы",
        "Эй, соня! Проверь привычки, пока не поздно!",
        "23:50 - время чекапа привычек! Не забудь отметить все что сделал!",
        "Перед сном - проверь привычки! Это важно для твоего прогресса!",
        "Финальный чек-ин! Проверь все привычки перед сном!",
        "Не забудь перед сном - проверь свои привычки! А то завтра пожалеешь",
        "Проверка перед сном обязательна! Не забудь отметить все привычки!",
        "Стоп! А привычки? Проверь их перед сном, чтобы не потерять баллы!",
        "Последняя проверка на сегодня! Убедись, что все привычки отмечены!",
        "Не ложись спать без проверки привычек! Это займет всего минуту!",
        "Время чекапа! Проверь свои привычки, пока не поздно!",
        "Перед сном - проверь привычки! Это важно! Не забудь!",
        "Финальная проверка дня! Отметь все свои привычки!",
        "Не забудь проверить привычки перед сном! Иначе завтра будет стыдно",
        "Сон может подождать! Сначала проверь все привычки!"
    ]
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    /// Показывать уведомления баннером и со звуком, когда приложение открыто (на переднем плане).
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
                self.scheduleDailyNotification()
            } else if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func scheduleDailyNotification() {
        let center = UNUserNotificationCenter.current()
        
        // Удаляем только общее напоминание (не трогаем habit-reminder-*)
        center.removePendingNotificationRequests(withIdentifiers: ["daily-habit-reminder"])
        
        // Создаем уведомление на каждый день в 23:50
        let content = UNMutableNotificationContent()
        content.title = "Проверь привычки!"
        content.body = getRandomPhrase()
        content.sound = .default
        // Не устанавливаем badge, чтобы не создавать красный кружок на иконке
        // Если нужен badge, его лучше очищать при открытии приложения
        
        // Устанавливаем время: 23:50 каждый день
        var dateComponents = DateComponents()
        dateComponents.hour = 23
        dateComponents.minute = 50
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily-habit-reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Daily notification scheduled for 23:50")
            }
        }
    }
    
    func updateNotificationContent() {
        // Обновляем содержимое уведомления с новой случайной фразой
        let center = UNUserNotificationCenter.current()
        
        center.getPendingNotificationRequests { requests in
            if let existingRequest = requests.first(where: { $0.identifier == "daily-habit-reminder" }),
               let trigger = existingRequest.trigger as? UNCalendarNotificationTrigger {
                
                // Удаляем старое уведомление
                center.removePendingNotificationRequests(withIdentifiers: ["daily-habit-reminder"])
                
                // Создаем новое с обновленной фразой
                let content = UNMutableNotificationContent()
                content.title = "Проверь привычки!"
                content.body = self.getRandomPhrase()
                content.sound = .default
                // Не устанавливаем badge, чтобы не создавать красный кружок на иконке
                // Если нужен badge, его лучше очищать при открытии приложения
                
                let request = UNNotificationRequest(
                    identifier: "daily-habit-reminder",
                    content: content,
                    trigger: trigger
                )
                
                center.add(request) { error in
                    if let error = error {
                        print("Error updating notification: \(error)")
                    } else {
                        print("Notification updated with new phrase")
                    }
                }
            } else {
                // Если уведомление не найдено, создаем новое
                self.scheduleDailyNotification()
            }
        }
    }
    
    private func getRandomPhrase() -> String {
        return notificationPhrases.randomElement() ?? "Проверь свои привычки перед сном! 🌙"
    }
    
    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }
    
    /// Текущий статус разрешения уведомлений (для показа в UI).
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus)
        }
    }
    
    /// Запланировать тестовое уведомление через 5 секунд. completion вызывается на главном потоке с сообщением для пользователя.
    func scheduleTestNotification(completion: @escaping (String) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .denied:
                    completion("Уведомления запрещены. Откройте Настройки → приложение → Уведомления и включите разрешение.")
                    return
                case .notDetermined:
                    self.requestAuthorization()
                    completion("Сначала разрешите уведомления во всплывшем запросе, затем нажмите тест снова.")
                    return
                case .authorized, .provisional, .ephemeral:
                    break
                @unknown default:
                    completion("Неизвестный статус уведомлений.")
                    return
                }
                
                let content = UNMutableNotificationContent()
                content.title = "Тест уведомлений"
                content.body = "Если вы видите это — уведомления работают! ✅"
                content.sound = .default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: "test-notification-\(UUID().uuidString)", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion("Ошибка: \(error.localizedDescription)")
                        } else {
                            completion("Через 5 секунд придёт тестовое уведомление. Сверните приложение или заблокируйте экран и подождите. Если не пришло — проверьте режим «Не беспокоить» и Фокус.")
                        }
                    }
                }
            }
        }
    }
    
    /// Открывает настройки приложения (раздел «Уведомления»). Вызвать, если уведомления не приходят.
    func openAppNotificationSettings() {
        DispatchQueue.main.async {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func clearBadge() {
        // Очищаем badge на иконке приложения
        // Используем главный поток для обновления UI
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
            print("Badge cleared successfully")
        }
    }
    
    /// Планирует напоминания для привычек с заданным временем. Уведомление приходит только в те дни недели, когда привычка/задача активна (например, только в среду в 19:00, а не каждый день).
    func rescheduleHabitReminders(habits: [HabitModel]) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let toRemove = requests.filter { $0.identifier.hasPrefix("habit-reminder-") }.map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: toRemove)
            
            for habit in habits {
                guard habit.hasNotification, let h = habit.notificationHour, let m = habit.notificationMinute else { continue }
                let weekdays = habit.activeWeekdays.isEmpty ? Set(1...7) : habit.activeWeekdays
                let content = UNMutableNotificationContent()
                content.title = habit.isTask ? "Задача: \(habit.name)" : "Привычка: \(habit.name)"
                content.body = "Напоминание в \(String(format: "%d:%02d", h, m))"
                content.sound = .default
                
                for weekday in weekdays {
                    var dateComponents = DateComponents()
                    dateComponents.weekday = weekday
                    dateComponents.hour = h
                    dateComponents.minute = m
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let request = UNNotificationRequest(
                        identifier: "habit-reminder-\(habit.id.uuidString)-\(weekday)",
                        content: content,
                        trigger: trigger
                    )
                    center.add(request) { error in
                        if let error = error {
                            print("Error scheduling habit reminder \(habit.name) weekday \(weekday): \(error)")
                        }
                    }
                }
            }
        }
    }
}

