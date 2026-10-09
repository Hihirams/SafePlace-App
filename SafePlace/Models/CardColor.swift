import SwiftUI

enum CardColor: String, CaseIterable, Identifiable {
    case pink, teal, lavender, peach, ochre, mint, coral, cream

    var id: String { rawValue }

    var fill: Color {
        switch self {
        case .pink: return SafeDesign.pink
        case .teal: return SafeDesign.teal
        case .lavender: return SafeDesign.lavender
        case .peach: return SafeDesign.peach
        case .ochre: return SafeDesign.ochre
        case .mint: return SafeDesign.mint
        case .coral: return SafeDesign.coral
        case .cream: return SafeDesign.cream
        }
    }

    /// Foreground text color — chosen for AA contrast on each card fill.
    var foreground: Color {
        switch self {
        case .teal:
            return .white
        default:
            return SafeDesign.ink
        }
    }

    /// Accent used for secondary text on the card (mood, date).
    var accent: Color {
        switch self {
        case .teal:
            return .white.opacity(0.95)
        default:
            return SafeDesign.ink.opacity(0.9)
        }
    }
}