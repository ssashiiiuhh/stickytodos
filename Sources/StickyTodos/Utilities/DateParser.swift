import Foundation

/// A utility to extract dates from natural language text.
struct DateParser {
    
    /// Parses the provided string for natural language dates.
    /// Returns a tuple containing the cleaned string (with the date text removed) and the parsed Date, if any.
    static func extractDate(from text: String) -> (cleanText: String, date: Date?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (text, nil) }
        
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
            let nsString = trimmed as NSString
            var matches = detector.matches(in: trimmed, options: [], range: NSRange(location: 0, length: nsString.length))
            
            // If full string detection finds no dates, try matching after stripping common prefix prepositions like "due"
            if matches.isEmpty {
                let prepositions = ["due at", "due on", "due by", "due", "at", "on", "by", "for", "in"]
                for prep in prepositions {
                    let prepPattern = "(?i)\\b" + prep + "\\s+"
                    let modifiedText = trimmed.replacingOccurrences(of: prepPattern, with: " ", options: .regularExpression)
                    let modMatches = detector.matches(in: modifiedText, options: [], range: NSRange(location: 0, length: (modifiedText as NSString).length))
                    if let firstDateMatch = modMatches.first(where: { $0.date != nil }) {
                        if let modRange = Range(firstDateMatch.range, in: modifiedText) {
                            let dateSnippet = String(modifiedText[modRange])
                            if let origRange = trimmed.range(of: dateSnippet, options: .caseInsensitive) {
                                let nsRange = NSRange(origRange, in: trimmed)
                                let dummyMatch = NSTextCheckingResult.dateCheckingResult(range: nsRange, date: firstDateMatch.date!)
                                matches = [dummyMatch]
                                break
                            }
                        }
                    }
                }
            }
            
            guard !matches.isEmpty else {
                return (trimmed, nil)
            }
            
            var extractedDate: Date? = nil
            for match in matches {
                if let date = match.date {
                    extractedDate = date
                    break
                }
            }
            
            guard let date = extractedDate else {
                return (trimmed, nil)
            }
            
            var resultString = trimmed
            let sortedMatches = matches.sorted { $0.range.location > $1.range.location }
            
            for match in sortedMatches {
                guard let range = Range(match.range, in: resultString) else { continue }
                
                var startIndex = range.lowerBound
                let leadingSubstring = String(resultString[..<startIndex])
                
                let prepositions = ["due at", "due on", "due by", "due", "at", "on", "by", "for", "in"]
                for prep in prepositions {
                    let prepWithSpace = prep + " "
                    if leadingSubstring.lowercased().hasSuffix(prepWithSpace.lowercased()) {
                        if let prepRange = leadingSubstring.lowercased().range(of: prepWithSpace.lowercased(), options: .backwards) {
                            if prepRange.upperBound == leadingSubstring.endIndex {
                                let distance = leadingSubstring.distance(from: prepRange.lowerBound, to: leadingSubstring.endIndex)
                                startIndex = resultString.index(startIndex, offsetBy: -distance)
                                break
                            }
                        }
                    }
                }
                
                resultString.removeSubrange(startIndex..<range.upperBound)
            }
            
            resultString = cleanExtraSpacesAndPrepositions(resultString)
            
            if resultString.isEmpty {
                return (trimmed, date)
            }
            
            return (resultString, date)
        } catch {
            print("Failed to create NSDataDetector: \(error)")
            return (trimmed, nil)
        }
    }
    
    private static func cleanExtraSpacesAndPrepositions(_ text: String) -> String {
        var cleaned = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let trailingPrepositions = ["due at", "due on", "due by", "due", "at", "on", "by", "for", "in"]
        for prep in trailingPrepositions {
            let lower = cleaned.lowercased()
            if lower == prep {
                return ""
            }
            if lower.hasSuffix(" " + prep) {
                let dropCount = prep.count + 1
                cleaned = String(cleaned.dropLast(dropCount)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        cleaned = cleaned.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",:;")))
        return cleaned
    }
}

