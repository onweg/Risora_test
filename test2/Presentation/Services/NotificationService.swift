//
//  NotificationService.swift
//  test2
//
//  Created by Arkadiy on 09.01.2026.
//

import Foundation
import UserNotifications

class NotificationService {
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
    
    private init() {}
    
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
        
        // Удаляем предыдущие уведомления
        center.removeAllPendingNotificationRequests()
        
        // Создаем уведомление на каждый день в 23:50
        let content = UNMutableNotificationContent()
        content.title = "Проверь привычки!"
        content.body = getRandomPhrase()
        content.sound = .default
        content.badge = 1
        
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
                content.badge = 1
                
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
}

