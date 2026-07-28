import Foundation

/// Handles reading and writing sticky notes to a JSON file in Application Support.
enum Persistence {
    private static let directoryName = "StickyTodos"
    private static let fileName = "notes.json"

    /// The URL for the data file: ~/Library/Application Support/StickyTodos/notes.json
    private static var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent(directoryName)
        return directory.appendingPathComponent(fileName)
    }

    /// Ensures the StickyTodos directory exists inside Application Support.
    private static func ensureDirectory() throws {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent(directoryName)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    /// Saves the current list of notes to the JSON file, with an automatic backup.
    static func saveNotes(_ notes: [StickyNote]) {
        do {
            try ensureDirectory()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(notes)
            
            // Create backup of current file if it exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let backupPath = fileURL.appendingPathExtension("bak")
                try? FileManager.default.removeItem(at: backupPath)
                try? FileManager.default.copyItem(at: fileURL, to: backupPath)
            }
            
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("⚠️ StickyTodos: Failed to save notes — \(error.localizedDescription)")
        }
    }

    /// Load notes from disk.
    /// On corruption the primary file, attempts the automatic `.bak` backup before
    /// returning an empty array, preventing silent data loss.
    static func load() -> [StickyNote] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        func decode(from url: URL) -> [StickyNote]? {
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode([StickyNote].self, from: data)
        }

        // 1. Try the primary file.
        if let notes = decode(from: fileURL) {
            print("✅ StickyTodos: Loaded \(notes.count) notes from \(fileURL.path)")
            for n in notes { print("   - '\(n.title)' workspace='\(n.workspace)' items=\(n.items.count)") }
            return notes
        }

        // 2. Bug fix: Primary file is missing or corrupted — try the backup.
        let backupURL = fileURL.appendingPathExtension("bak")
        if let notes = decode(from: backupURL) {
            print("⚠️ StickyTodos: Primary data file corrupted; restored from backup.")
            return notes
        }

        // 3. First launch or unrecoverable — start fresh.
        print("⚠️ StickyTodos: No notes file found, starting fresh.")
        return []
    }
}
