import SwiftUI
import UIKit

/// SafePlace design system — warm "clay" palette adapted from the web version.
/// Fully adaptive: every semantic color resolves for light and dark automatically.
enum SafeDesign {

    // MARK: - Dynamic color helpers
    private static func dyn(_ light: String, _ dark: String) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }

    private static func dynWhiteInk(_ lightAlpha: CGFloat, _ darkAlpha: CGFloat) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: darkAlpha)
                : UIColor(white: 0.09, alpha: lightAlpha)
        })
    }

    // MARK: - Surfaces
    static let canvas = dyn("FFFaf0", "12100C")            // warm off-white canvas
    static let surfaceSoft = dyn("FAF5E8", "1A1712")       // subtle grouping
    static let surfaceCard = dyn("F5F0E0", "221E17")       // card surface
    static let surfaceStrong = dyn("EBE6D6", "2A251C")     // pressed / raised
    static let hairline = dynWhiteInk(0.08, 0.10)

    // MARK: - Ink (text)
    static let ink = dyn("0A0A0A", "F0ECE3")
    static let inkSecondary = dyn("3A3A3A", "C9C3B6")
    static let muted = dynWhiteInk(0.42, 0.42)

    // MARK: - Brand (clay accent)
    static let primary = dyn("0A0A0A", "F0ECE3")
    static let onPrimary = dyn("FFFFFF", "0A0A0A")

    // MARK: - Brand card colors (fixed, from the web design)
    static let pink = Color(hex: "FF4D8B")
    static let teal = Color(hex: "1A3A3A")
    static let lavender = Color(hex: "B8A4ED")
    static let peach = Color(hex: "FFB084")
    static let ochre = Color(hex: "E8B94A")
    static let mint = Color(hex: "A4D4C5")
    static let coral = Color(hex: "FF6B5A")
    static let cream = Color(hex: "F5F0E0")

    // MARK: - Mood colors
    static let moodBright = Color(hex: "E8B94A")
    static let moodCalm = Color(hex: "A4D4C5")
    static let moodHopeful = Color(hex: "B8A4ED")
    static let moodMixed = Color(hex: "FFB084")
    static let moodHeavy = Color(hex: "9A9A9A")

    // MARK: - Functional
    static let success = Color(hex: "22C55E")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")

    // MARK: - Typography (SF, rounded for figures) — mobile-native scale.
    // Display sizes are modest so they fit comfortably on any iPhone; they
    // scale with Dynamic Type up to a cap applied at the root view.
    static let heroFont = Font.system(size: 32, weight: .bold, design: .rounded)
    static let displayFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let largeTitle = Font.system(size: 26, weight: .bold)
    static let title = Font.system(size: 20, weight: .bold)
    static let headline = Font.system(size: 16, weight: .semibold)
    static let body = Font.system(size: 15, weight: .medium)
    static let caption = Font.system(size: 13, weight: .medium)
    static let micro = Font.system(size: 11, weight: .medium)
    static let tabLabel = Font.system(size: 9.5, weight: .semibold)

    // MARK: - Spacing (multiples of 4)
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48

    // MARK: - Corner radii
    static let radiusXS: CGFloat = 6
    static let radiusS: CGFloat = 8
    static let radiusM: CGFloat = 12
    static let radiusL: CGFloat = 16
    static let radiusXL: CGFloat = 24
    static let radiusPill: CGFloat = 100

    // MARK: - Motion
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.78)
    static let springSnappy = Animation.spring(response: 0.28, dampingFraction: 0.82)
    static let springBouncy = Animation.spring(response: 0.42, dampingFraction: 0.68)
    static let easeOut = Animation.easeOut(duration: 0.25)
}

// MARK: - Adaptive layout (size-class aware)

enum SafeLayout {
    /// Cap content width on large screens so lines don't get uncomfortably long.
    static let contentMaxWidth: CGFloat = 720

    /// Number of flexible grid columns for a given available width.
    /// Narrow iPhones get a single column, standard phones two, iPads more.
    static func columns(forWidth width: CGFloat) -> [GridItem] {
        let count: Int
        switch width {
        case ..<380: count = 1
        case ..<640: count = 2
        case ..<960: count = 3
        default:     count = 4
        }
        return Array(repeating: GridItem(.flexible(), spacing: 14), count: count)
    }

    /// Horizontal page padding tuned to the size classes.
    static func pageInset(_ horizontal: UserInterfaceSizeClass?, _ vertical: UserInterfaceSizeClass?) -> CGFloat {
        if horizontal == .regular { return 28 }
        return vertical == .compact ? 16 : 20
    }

    /// Bottom padding above the floating glass tab bar.
    static func tabBarClearance(_ horizontal: UserInterfaceSizeClass?) -> CGFloat {
        horizontal == .regular ? 96 : 110
    }
}

extension View {
    /// Keeps a scroll column centered and capped on large screens.
    func pageColumn(_ horizontal: UserInterfaceSizeClass?, _ vertical: UserInterfaceSizeClass?) -> some View {
        frame(maxWidth: SafeLayout.contentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, SafeLayout.pageInset(horizontal, vertical))
    }
}

private struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

extension View {
    /// Captures the width of the view it is attached to (via its background).
    func readingWidth(_ binding: Binding<CGFloat>) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(key: WidthPreferenceKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(WidthPreferenceKey.self) { binding.wrappedValue = $0 }
    }
}