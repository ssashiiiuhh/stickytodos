import SwiftUI
import Observation
import NaturalLanguage

/// Central state manager for all sticky notes.
/// Uses the Swift Observation framework (@Observable) for high-performance UI updates.
/// Persists data to a local JSON file via Persistence.swift.
@Observation.Observable
final class NotesViewModel {

    // MARK: - State

    /// The list of all notes.
    var notes: [StickyNote] = [] {
        didSet {
            updateCache()
            scheduleSave()
        }
    }

    // MARK: - Workspaces
    var selectedWorkspace: String {
        get { UserDefaults.standard.string(forKey: "selectedWorkspace") ?? "Default" }
        set {
            UserDefaults.standard.set(newValue, forKey: "selectedWorkspace")
            updateCache()
        }
    }

    var availableWorkspaces: [String] {
        var ws = Set(notes.map { $0.workspace })
        ws.insert("Default")
        return Array(ws).sorted()
    }

    /// Caching expensive computations (like filtering all tasks) prevents UI stutters
    /// in high-density views like the Menu Bar Widget.
    private(set) var cachedTotalIncompleteCount: Int = 0
    private(set) var cachedAllIncompleteTasks: [(note: StickyNote, item: TodoItem)] = []

    /// Remembers the last note a task was added to (for Quick Add memory).
    var lastAddedNoteID: UUID?

    /// Controls the "new note" sheet.
    var isAddingNote: Bool = false

    /// Controls the note-editor sheet (edit color/title).
    var editingNote: StickyNote? = nil

    /// User preference to sync tasks to Apple Reminders
    var syncToReminders: Bool {
        get { UserDefaults.standard.bool(forKey: "syncToReminders") }
        set {
            UserDefaults.standard.set(newValue, forKey: "syncToReminders")
            if newValue { RemindersManager.shared.requestAccess { _ in } }
        }
    }

    // MARK: - Private
    @ObservationIgnored private var saveTimer: Timer?
    @ObservationIgnored private var digestDebounceTimer: Timer?

    // MARK: - Init

    init() {
        notes = Persistence.load()
        updateCache()
    }

    deinit {
        saveTimer?.invalidate()
        digestDebounceTimer?.invalidate()
        // Flush any pending save immediately on teardown
        Persistence.saveNotes(notes)
    }

    // MARK: - Persistence

    /// Debounce saves so rapid edits (e.g. typing) don't thrash the disk.
    private func scheduleSave() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self else { return }
            Persistence.saveNotes(self.notes)
        }
    }

    private func updateCache() {
        let activeNotes = notes.filter { !$0.isArchived && $0.workspace == selectedWorkspace }
        cachedTotalIncompleteCount = activeNotes.reduce(0) { $0 + $1.incompleteItems.count }
        cachedAllIncompleteTasks = activeNotes.flatMap { note in
            note.incompleteItems.map { (note: note, item: $0) }
        }

        // Debounce daily digest so it isn't rescheduled on every keystroke.
        digestDebounceTimer?.invalidate()
        digestDebounceTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            NotificationManager.scheduleDailyDigest(tasks: self.cachedAllIncompleteTasks)
        }
    }

    // MARK: - Note CRUD

    func addNote(title: String = "New Note", color: NoteColor = .yellow) -> UUID {
        let id = UUID()
        let boardSize: CGFloat = 3000
        let hash = abs(id.hashValue)
        let dx = CGFloat(hash % 400) - 200
        let dy = CGFloat((hash / 400) % 300) - 150
        let newNote = StickyNote(id: id, title: title, color: color,
                                 position: CGPoint(x: boardSize/2 + dx, y: boardSize/2 + dy),
                                 workspace: selectedWorkspace)
        notes.append(newNote)
        lastAddedNoteID = newNote.id
        return newNote.id
    }

    func autoTidy() {
        let activeNotes = notes.filter { !$0.isArchived && $0.workspace == selectedWorkspace }
            .sorted { $0.createdAt < $1.createdAt }
        guard !activeNotes.isEmpty else { return }

        let boardCenter = CGPoint(x: 1500, y: 1500)
        let noteWidth: CGFloat = 300
        let noteHeight: CGFloat = 350
        let padding: CGFloat = 40
        let columns = max(2, Int(sqrt(Double(activeNotes.count))))
        let totalWidth = CGFloat(columns) * noteWidth + CGFloat(columns - 1) * padding
        let startX = boardCenter.x - totalWidth / 2 + noteWidth / 2
        let startY = boardCenter.y - (CGFloat(activeNotes.count / columns) * noteHeight) / 2

        withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0.5)) {
            for (index, note) in activeNotes.enumerated() {
                if let idx = notes.firstIndex(where: { $0.id == note.id }) {
                    let col = index % columns
                    let row = index / columns
                    notes[idx].position = CGPoint(x: startX + CGFloat(col) * (noteWidth + padding),
                                                  y: startY + CGFloat(row) * (noteHeight + padding))
                    notes[idx].rotation = Double.random(in: -1...1)
                }
            }
        }
    }

    func deleteNote(_ note: StickyNote) {
        notes.removeAll { $0.id == note.id }
        for item in note.items {
            NotificationManager.cancelNotification(for: item.id)
        }
    }

    func updateNoteTitle(_ noteID: UUID, title: String) {
        guard let idx = notes.firstIndex(where: { $0.id == noteID }) else { return }
        notes[idx].title = title
        for item in notes[idx].items {
            NotificationManager.cancelNotification(for: item.id)
            NotificationManager.scheduleNotification(for: item, noteTitle: title)
        }
    }

    func updateNoteColor(_ noteID: UUID, color: NoteColor) {
        guard let idx = notes.firstIndex(where: { $0.id == noteID }) else { return }
        notes[idx].color = color
    }

    func updateNotePosition(_ noteID: UUID, position: CGPoint) {
        guard let idx = notes.firstIndex(where: { $0.id == noteID }) else { return }
        notes[idx].position = position
    }

    func toggleArchiveNote(_ noteID: UUID) {
        guard let idx = notes.firstIndex(where: { $0.id == noteID }) else { return }
        notes[idx].isArchived.toggle()
        if notes[idx].isArchived {
            for item in notes[idx].items {
                NotificationManager.cancelNotification(for: item.id)
            }
        } else {
            for item in notes[idx].items.filter({ !$0.isCompleted }) {
                NotificationManager.scheduleNotification(for: item, noteTitle: notes[idx].title)
            }
        }
    }

    // MARK: - Filtering Logic

    func displayItems(for note: StickyNote, matching searchText: String) -> [TodoItem] {
        // Filter out items blocked by an incomplete predecessor.
        let incompleteIDs = Set(note.incompleteItems.map { $0.id })
        let visibleItems = note.incompleteItems.filter { item in
            guard let blockerID = item.blockedBy else { return true }
            return !incompleteIDs.contains(blockerID)
        }

        if searchText.isEmpty { return visibleItems }

        let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if note.title.lowercased().contains(query) { return visibleItems }

        let embedding = NLEmbedding.sentenceEmbedding(for: .english) ?? NLEmbedding.wordEmbedding(for: .english)

        return visibleItems.filter { item in
            let text = item.text.lowercased()
            if text.contains(query) { return true }
            if let embedding = embedding, embedding.distance(between: query, and: text) < 0.95 {
                return true
            }
            return false
        }
    }

    func activeNotes(matching searchText: String) -> [StickyNote] {
        let active = notes.filter { !$0.isArchived && $0.workspace == selectedWorkspace }
        if searchText.isEmpty { return active.filter { !$0.incompleteItems.isEmpty } }
        return active.filter { !displayItems(for: $0, matching: searchText).isEmpty }
    }

    func archivedNotes() -> [StickyNote] {
        notes.filter { $0.isArchived }
    }

    // MARK: - Todo Item CRUD

    func addItem(to noteID: UUID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let idx = notes.firstIndex(where: { $0.id == noteID }) else { return }

        let (finalTitle, extractedDate) = DateParser.extractDate(from: trimmed)

        let item = TodoItem(text: finalTitle, dueDate: extractedDate)
        notes[idx].items.append(item)
        lastAddedNoteID = noteID
        NotificationManager.scheduleNotification(for: item, noteTitle: notes[idx].title)

        if syncToReminders {
            RemindersManager.shared.syncTask(item: item, noteTitle: notes[idx].title)
        }
    }

    func updateItemDueDate(_ itemID: UUID, in noteID: UUID, date: Date?) {
        guard let nIdx = notes.firstIndex(where: { $0.id == noteID }),
              let iIdx = notes[nIdx].items.firstIndex(where: { $0.id == itemID }) else { return }
        notes[nIdx].items[iIdx].dueDate = date
        NotificationManager.cancelNotification(for: itemID)
        if date != nil {
            NotificationManager.scheduleNotification(for: notes[nIdx].items[iIdx], noteTitle: notes[nIdx].title)
        }
        if syncToReminders {
            RemindersManager.shared.syncTask(item: notes[nIdx].items[iIdx], noteTitle: notes[nIdx].title)
        }
    }

    func toggleItem(_ itemID: UUID, in noteID: UUID) {
        guard let nIdx = notes.firstIndex(where: { $0.id == noteID }),
              let iIdx = notes[nIdx].items.firstIndex(where: { $0.id == itemID }) else { return }
        notes[nIdx].items[iIdx].isCompleted.toggle()
        let isNowCompleted = notes[nIdx].items[iIdx].isCompleted

        if isNowCompleted {
            NotificationManager.cancelNotification(for: itemID)
            if let recurrence = notes[nIdx].items[iIdx].recurrence,
               let oldDueDate = notes[nIdx].items[iIdx].dueDate {
                var dateComponents = DateComponents()
                switch recurrence {
                case .daily:   dateComponents.day = 1
                case .weekly:  dateComponents.day = 7
                case .monthly: dateComponents.month = 1
                }
                if let newDueDate = Calendar.current.date(byAdding: dateComponents, to: oldDueDate) {
                    let nextItem = TodoItem(text: notes[nIdx].items[iIdx].text,
                                           dueDate: newDueDate, recurrence: recurrence)
                    notes[nIdx].items.append(nextItem)
                    NotificationManager.scheduleNotification(for: nextItem, noteTitle: notes[nIdx].title)
                }
            }
        } else {
            NotificationManager.scheduleNotification(for: notes[nIdx].items[iIdx], noteTitle: notes[nIdx].title)
        }

        if syncToReminders {
            RemindersManager.shared.syncTask(item: notes[nIdx].items[iIdx], noteTitle: notes[nIdx].title)
        }
    }

    func deleteItem(_ itemID: UUID, from noteID: UUID) {
        guard let nIdx = notes.firstIndex(where: { $0.id == noteID }),
              let iIdx = notes[nIdx].items.firstIndex(where: { $0.id == itemID }) else { return }
        notes[nIdx].items.remove(at: iIdx)
        NotificationManager.cancelNotification(for: itemID)
        if syncToReminders {
            RemindersManager.shared.deleteSyncTask(itemID: itemID)
        }
    }

    func updateItemText(_ itemID: UUID, in noteID: UUID, text: String) {
        guard let nIdx = notes.firstIndex(where: { $0.id == noteID }),
              let iIdx = notes[nIdx].items.firstIndex(where: { $0.id == itemID }) else { return }
        let (finalTitle, extractedDate) = DateParser.extractDate(from: text)
        notes[nIdx].items[iIdx].text = finalTitle
        if let newDate = extractedDate {
            notes[nIdx].items[iIdx].dueDate = newDate
        }
        NotificationManager.cancelNotification(for: itemID)
        NotificationManager.scheduleNotification(for: notes[nIdx].items[iIdx], noteTitle: notes[nIdx].title)
        if syncToReminders {
            RemindersManager.shared.syncTask(item: notes[nIdx].items[iIdx], noteTitle: notes[nIdx].title)
        }
    }

    func moveItem(from source: IndexSet, to destination: Int, in noteID: UUID) {
        guard let nIdx = notes.firstIndex(where: { $0.id == noteID }) else { return }
        notes[nIdx].items.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Computed

    var allIncompleteTasks: [(note: StickyNote, item: TodoItem)] { cachedAllIncompleteTasks }
    var totalIncompleteCount: Int { cachedTotalIncompleteCount }
}
