// migrate.swift - run once to push local notes.json → Firestore
// Usage: swift migrate.swift  (from the StickyTodos project dir)
import Foundation

let jsonURL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Application Support/StickyTodos/notes.json")

guard let data = try? Data(contentsOf: jsonURL) else {
    print("❌ Could not read notes.json"); exit(1)
}
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
let notes = try! JSONDecoder().decode([[String: Any]].self, from: data)
print("Loaded \(notes.count) notes — this approach won't work directly.")
print("Using Python approach instead...")
