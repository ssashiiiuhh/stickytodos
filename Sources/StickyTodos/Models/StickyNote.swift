import Foundation

/// A sticky note containing a title and a list of to-do items.
struct StickyNote: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var color: NoteColor
    var items: [TodoItem]
    var createdAt: Date
    /// Slight random rotation in degrees for organic visual feel (±3°).
    var rotation: Double
    /// Absolute position on the freeform corkboard. If nil, it will be placed randomly.
    var position: CGPoint?
    var isArchived: Bool
    var workspace: String

    init(
        id: UUID = UUID(),
        title: String = "New Note",
        color: NoteColor = .yellow,
        items: [TodoItem] = [],
        createdAt: Date = Date(),
        rotation: Double? = nil,
        position: CGPoint? = nil,
        isArchived: Bool = false,
        workspace: String = "Default"
    ) {
        self.id = id
        self.title = title
        self.color = color
        self.items = items
        self.createdAt = createdAt
        self.rotation = rotation ?? Double.random(in: -3...3)
        self.position = position
        self.isArchived = isArchived
        self.workspace = workspace
    }

    // MARK: - Custom Decoding to handle legacy data
    
    enum CodingKeys: String, CodingKey {
        case id, title, color, items, createdAt, rotation, position, isArchived, workspace
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        color = try container.decode(NoteColor.self, forKey: .color)
        items = try container.decode([TodoItem].self, forKey: .items)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        rotation = try container.decode(Double.self, forKey: .rotation)
        position = try container.decodeIfPresent(CGPoint.self, forKey: .position)
        // Default isArchived to false if it's missing in the JSON
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        // Default workspace to "Default" if it's missing in the JSON
        workspace = try container.decodeIfPresent(String.self, forKey: .workspace) ?? "Default"
    }

    /// Number of completed items.
    var completedCount: Int {
        items.filter(\.isCompleted).count
    }

    /// Total number of items.
    var totalCount: Int {
        items.count
    }

    /// Incomplete items only.
    var incompleteItems: [TodoItem] {
        items.filter { !$0.isCompleted }
    }

    /// Progress from 0.0 to 1.0.
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
}
