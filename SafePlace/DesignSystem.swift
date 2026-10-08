import SwiftUI
import UIKit

/// SafePlace design system — soft "powder blush" palette.
/// Fully adaptive: every semantic color resolves for light and dark automatically.
/// Dark mode is a true deep black (no grey cast), with the palette adapted on top.
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
                : UIColor(white: 0.16, alpha: lightAlpha)
        })
    }

    // MARK: - New palette (raw values)
    static let powderBlush   = Color(hex: "FEC5BB")
    static let almondSilk    = Color(hex: "FCD5CE")
    static let softBlush     = Color(hex: "FAE1DD")
    static let seashell      = Color(hex: "F8EDEB")
    static let alabasterGrey = Color(hex: "E8E8E4")
    static let alabasterGrey2 = Color(hex: "D8E2DC")
    static let linen         = Color(hex: "ECE4DB")
    static let powderPetal   = Color(hex: "FFE5D9")
    static let peachFuzz     = Color(hex: "FFD7BA")
    static let peachGlow     = Color(hex: "FEC89A")

    // MARK: - Surfaces (white & sober, mood tint comes from AppTheme)
    static let canvas        = dyn("FCFBFA", "000000")   // near-white / pure black
    static let surfaceSoft   = dyn("F6F4F2", "141414")   // subtle grouping
    static let surfaceCard   = dyn("FFFFFF", "0E0E0E")   // white card / near-black
    static let surfaceStrong = dyn("EFEBE7", "1C1C1C")   // pressed / raised
    static let hairline      = dynWhiteInk(0.09, 0.12)

    // MARK: - Ink (text)
    static let ink          = dyn("2B2320", "F5F0EC")
    static let inkSecondary = dyn("6B5E57", "B8AFA8")
    static let muted        = dynWhiteInk(0.45, 0.42)

    // MARK: - Accent (peach glow)
    static let accent    = peachGlow
    static let accentDeep = Color(hex: "E8A56B")
    static let primary   = dyn("FEC89A", "FEC89A")
    static let onPrimary = dyn("2B2320", "241703")

    // MARK: - Card colors (kept vivid so notes stay distinct)
    static let pink     = Color(hex: "FF4D8B")
    static let teal     = Color(hex: "1A3A3A")
    static let lavender = Color(hex: "B8A4ED")
    static let peach    = Color(hex: "FFB084")
    static let ochre    = Color(hex: "E8B94A")
    static let mint     = Color(hex: "A4D4C5")
    static let coral    = Color(hex: "FF6B5A")
    static let cream    = Color(hex: "F5F0E0")

    // MARK: - Mood colors (palette-adapted)
    static let moodBright  = Color(hex: "FEC89A")   // peach glow
    static let moodCalm    = Color(hex: "D8E2DC")   // alabaster grey 2
    static let moodHopeful = Color(hex: "FEC5BB")   // powder blush
    static let moodMixed   = Color(hex: "FFD7BA")   // peach fuzz
    static let moodHeavy   = Color(hex: "A9BCD0")   // soft sad blue

    // MARK: - Functional
    static let success = Color(hex: "22C55E")
    static let warning = Color(hex: "F59E0B")
    static let error   = Color(hex: "EF4444")

    // MARK: - Typography (SF, rounded for figures)
    static let heroFont    = Font.system(size: 30, weight: .bold, design: .rounded)
    static let displayFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let largeTitle  = Font.system(size: 26, weight: .bold)
    static let title       = Font.system(size: 20, weight: .bold)
    static let headline    = Font.system(size: 16, weight: .semibold)
    static let body        = Font.system(size: 15, weight: .medium)
    static let caption     = Font.system(size: 13, weight: .medium)
    static let micro       = Font.system(size: 11, weight: .medium)
    static let tabLabel    = Font.system(size: 9.5, weight: .semibold)

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
        horizontal == .regular ? 96 : 116
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
