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

    /// Foreground text color — dark cards get light text, light cards get ink.
    var foreground: Color {
        switch self {
        case .pink, .teal:
            return .white
        case .lavender, .peach, .ochre, .mint, .coral, .cream:
            return SafeDesign.ink
        }
    }

    /// A softer version used for accents on light cards.
    var accent: Color {
        switch self {
        case .pink, .teal: return .white.opacity(0.85)
        default: return SafeDesign.ink.opacity(0.55)
        }
    }
}