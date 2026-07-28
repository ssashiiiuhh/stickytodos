import Foundation
import EventKit
import SwiftUI

/// Manages synchronization between StickyTodos tasks and Apple Reminders.
@Observable
final class RemindersManager {
    static let shared = RemindersManager()
    
    private let store = EKEventStore()
    private let listName = "StickyTodos"
    
    var isAuthorized: Bool = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .authorized, .fullAccess:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToReminders { granted, error in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    completion(granted)
                }
            }
        } else {
            store.requestAccess(to: .reminder) { granted, error in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    completion(granted)
                }
            }
        }
    }
    
    private func getOrCreateStickyTodosList() -> EKCalendar? {
        // Try to find an existing list
        let calendars = store.calendars(for: .reminder)
        if let existingList = calendars.first(where: { $0.title == listName }) {
            return existingList
        }
        
        // Create a new list if none exists
        let newList = EKCalendar(for: .reminder, eventStore: store)
        newList.title = listName
        
        // Find default source (iCloud or Local)
        let sources = store.sources
        newList.source = sources.first(where: { $0.sourceType == .calDAV && $0.title == "iCloud" }) 
                         ?? store.defaultCalendarForNewReminders()?.source 
                         ?? sources.first
        
        do {
            try store.saveCalendar(newList, commit: true)
            return newList
        } catch {
            print("Failed to create StickyTodos Reminders list: \(error)")
            return nil
        }
    }
    
    /// Adds or updates a reminder corresponding to a StickyTodo item.
    /// Uses the item's UUID as an external identifier in the notes field to link them.
    func syncTask(item: TodoItem, noteTitle: String) {
        guard isAuthorized, let calendar = getOrCreateStickyTodosList() else { return }
        
        let identifierString = "sticky-todo-id: \(item.id.uuidString)"
        
        // Search for existing reminder
        let predicate = store.predicateForReminders(in: [calendar])
        store.fetchReminders(matching: predicate) { reminders in
            let existingReminder = reminders?.first(where: { $0.notes?.contains(identifierString) == true })
            
            let reminder = existingReminder ?? EKReminder(eventStore: self.store)
            reminder.calendar = calendar
            reminder.title = "[\(noteTitle)] \(item.text)"
            reminder.isCompleted = item.isCompleted
            
            if existingReminder == nil {
                // Only set notes on creation so we don't overwrite user notes
                reminder.notes = identifierString
            }
            
            if let dueDate = item.dueDate {
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
                reminder.dueDateComponents = components
                reminder.alarms = [EKAlarm(absoluteDate: dueDate)]
            } else {
                reminder.dueDateComponents = nil
                reminder.alarms = nil
            }
            
            do {
                try self.store.save(reminder, commit: true)
            } catch {
                print("Failed to save reminder: \(error)")
            }
        }
    }
    
    /// Deletes a corresponding reminder if it exists.
    func deleteSyncTask(itemID: UUID) {
        guard isAuthorized, let calendar = getOrCreateStickyTodosList() else { return }
        
        let identifierString = "sticky-todo-id: \(itemID.uuidString)"
        let predicate = store.predicateForReminders(in: [calendar])
        
        store.fetchReminders(matching: predicate) { reminders in
            if let existingReminder = reminders?.first(where: { $0.notes?.contains(identifierString) == true }) {
                do {
                    try self.store.remove(existingReminder, commit: true)
                } catch {
                    print("Failed to delete reminder: \(error)")
                }
            }
        }
    }
}
