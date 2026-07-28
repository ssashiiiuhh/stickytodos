import Foundation
import UserNotifications

struct NotificationManager {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("StickyTodos: Notification permission error - \(error)")
            }
        }
    }

    static func scheduleNotification(for item: TodoItem, noteTitle: String) {
        guard let dueDate = item.dueDate, !item.isCompleted else { return }
        guard dueDate > Date() else { return } // Only schedule future dates

        let content = UNMutableNotificationContent()
        content.title = "Task Due: \(noteTitle)"
        content.body = item.text
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("StickyTodos: Error scheduling notification - \(error)")
            }
        }
    }

    static func cancelNotification(for itemID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [itemID.uuidString])
    }

    /// Schedules a morning summary of all pending tasks to keep the user engaged.
    static func scheduleDailyDigest(tasks: [(note: StickyNote, item: TodoItem)]) {
        let identifier = "daily_digest"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        guard !tasks.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Good Morning! ☀️"
        content.body = "You have \(tasks.count) tasks waiting for you on your board today."
        content.sound = .default
        
        // Schedule for 9:00 AM daily
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
