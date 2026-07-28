import Foundation

@main
struct DecodeTest {
    static func main() {
        let jsonPath = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Application Support/StickyTodos/notes.json.bak")
        do {
            let data = try Data(contentsOf: jsonPath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let notes = try decoder.decode([StickyNote].self, from: data)
                print("Successfully decoded \(notes.count) notes.")
            } catch {
                print("DECODE ERROR: \(error)")
            }
        } catch {
            print("Failed to read file: \(error)")
        }
    }
}
