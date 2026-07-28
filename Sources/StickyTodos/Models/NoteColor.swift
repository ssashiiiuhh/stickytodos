import SwiftUI

/// The 6 sticky note color options — warm, pastel tones that feel like real sticky notes.
enum NoteColor: String, Codable, CaseIterable, Identifiable {
    case yellow
    case pink
    case green
    case blue
    case purple
    case orange

    var id: String { rawValue }

    /// The primary background fill for the sticky note.
    var color: Color {
        switch self {
        case .yellow: return Color(red: 1.0, green: 0.95, blue: 0.6)
        case .pink:   return Color(red: 1.0, green: 0.75, blue: 0.8)
        case .green:  return Color(red: 0.7, green: 0.94, blue: 0.7)
        case .blue:   return Color(red: 0.7, green: 0.85, blue: 1.0)
        case .purple: return Color(red: 0.85, green: 0.75, blue: 1.0)
        case .orange: return Color(red: 1.0, green: 0.82, blue: 0.55)
        }
    }

    /// A slightly darker shade for the header / accent strip.
    var headerColor: Color {
        switch self {
        case .yellow: return Color(red: 0.95, green: 0.88, blue: 0.35)
        case .pink:   return Color(red: 0.95, green: 0.55, blue: 0.65)
        case .green:  return Color(red: 0.45, green: 0.82, blue: 0.45)
        case .blue:   return Color(red: 0.45, green: 0.7, blue: 0.95)
        case .purple: return Color(red: 0.7, green: 0.55, blue: 0.95)
        case .orange: return Color(red: 0.95, green: 0.65, blue: 0.3)
        }
    }

    /// Text color that contrasts well against the pastel background.
    var textColor: Color {
        switch self {
        case .yellow: return Color(red: 0.35, green: 0.3, blue: 0.05)
        case .pink:   return Color(red: 0.45, green: 0.1, blue: 0.2)
        case .green:  return Color(red: 0.1, green: 0.35, blue: 0.1)
        case .blue:   return Color(red: 0.1, green: 0.2, blue: 0.45)
        case .purple: return Color(red: 0.3, green: 0.15, blue: 0.5)
        case .orange: return Color(red: 0.45, green: 0.25, blue: 0.0)
        }
    }

    /// Sidebar indicator dot color (slightly more saturated).
    var dotColor: Color {
        headerColor
    }

    /// Human-readable display name.
    var displayName: String {
        rawValue.capitalized
    }

    /// SF Symbol name for a colored circle preview.
    static var defaultColor: NoteColor { .yellow }
}
