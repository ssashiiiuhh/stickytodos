import Foundation

/// A utility to extract dates from natural language text.
struct DateParser {
    
    /// Parses the provided string for natural language dates.
    /// Returns a tuple containing the cleaned string (with the date text removed) and the parsed Date, if any.
    static func extractDate(from text: String) -> (cleanText: String, date: Date?) {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            
            guard let match = matches.first, let date = match.date else {
                return (text, nil)
            }
            
            // Extract the matched date string to remove it from the original text
            if let swiftRange = Range(match.range, in: text) {
                var cleanText = text
                cleanText.removeSubrange(swiftRange)
                
                // Clean up leading/trailing prepositions or whitespace like "at", "on", "by"
                let wordsToRemove = [" at ", " on ", " by ", " due "]
                for word in wordsToRemove {
                    if cleanText.hasSuffix(word.trimmingCharacters(in: .whitespaces)) {
                        cleanText = cleanText.replacingOccurrences(of: word.trimmingCharacters(in: .whitespaces), with: "")
                    }
                    cleanText = cleanText.replacingOccurrences(of: word, with: " ")
                }
                
                return (cleanText.trimmingCharacters(in: .whitespacesAndNewlines), date)
            }
            
            return (text, date)
        } catch {
            print("Failed to create NSDataDetector: \(error)")
            return (text, nil)
        }
    }
}
