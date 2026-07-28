import SwiftUI

enum BoardBackground: String, CaseIterable, Identifiable {
    case glass = "Liquid Glass"
    case corkboard = "Corkboard"
    case whiteboard = "Whiteboard"
    case grid = "Blueprint Grid"
    case custom = "Custom Image..."
    
    var id: String { rawValue }
}
