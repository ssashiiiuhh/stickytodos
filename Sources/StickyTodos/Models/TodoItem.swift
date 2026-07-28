import Foundation

/// A single to-do task within a sticky note.
struct TodoItem: Identifiable, Codable, Equatable {
    enum RecurrenceRule: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    var id: UUID
    var text: String
    var isCompleted: Bool
    var isArchived: Bool
    var blockedBy: UUID?
    var createdAt: Date
    var dueDate: Date?
    var recurrence: RecurrenceRule?

    init(id: UUID = UUID(), text: String, isCompleted: Bool = false, isArchived: Bool = false, blockedBy: UUID? = nil, createdAt: Date = Date(), dueDate: Date? = nil, recurrence: RecurrenceRule? = nil) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.isArchived = isArchived
        self.blockedBy = blockedBy
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.recurrence = recurrence
    }
    
    // Custom Decodable to handle legacy data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        blockedBy = try container.decodeIfPresent(UUID.self, forKey: .blockedBy)
        recurrence = try container.decodeIfPresent(RecurrenceRule.self, forKey: .recurrence)
    }
}
