import SwiftUI

// MARK: - Liquid Glass
// On the Xcode 26 SDK this becomes Apple's real Liquid Glass at runtime on
// iOS 26. Everywhere else it renders a genuinely translucent frosted material
// that blurs whatever content scrolls behind it. The illusion only works when
// live content passes *under* the surface — the layout is built so it does.

/// Floating glass surface for the tab bar (single clean glass — not interactive,
/// so the bar itself never deforms while you drag the selector inside it).
struct GlassCapsule: ViewModifier {
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: .capsule)
        } else {
            content.modifier(FrostedCapsule())
        }
        #else
        content.modifier(FrostedCapsule())
        #endif
    }
}

/// The moving selection lens inside the tab bar — glass, but NOT interactive,
/// so it translates with the finger instead of stretching.
struct SelectorGlass: ViewModifier {
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 0.5) }
        }
        #else
        content
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 0.5) }
        #endif
    }
}

private struct FrostedCapsule: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Capsule())
            // faint brand wash so the glass carries a hint of the clay palette
            .overlay {
                Capsule().fill(SafeDesign.accent.opacity(0.08))
            }
            // top specular highlight + hairline edge = refraction cue
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.55),
                                .white.opacity(0.08),
                                .clear,
                                .white.opacity(0.14)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
            .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }
}

/// A frosted pill for small controls (action buttons, segmented items).
/// On iOS 26 it uses interactive Liquid Glass so the button deforms on touch.
struct GlassPill: ViewModifier {
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 0.75) }
                .overlay { Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 0.5) }
        }
        #else
        content
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 0.75) }
            .overlay { Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 0.5) }
        #endif
    }
}

/// Optional frosted rounded surface (used sparingly).
struct LiquidGlass: ViewModifier {
    var cornerRadius: CGFloat = SafeDesign.radiusL
    var padding: CGFloat = SafeDesign.xl

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
            }
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}

// MARK: - Convenience

extension View {
    func glassCapsule() -> some View { modifier(GlassCapsule()) }
    func selectorGlass() -> some View { modifier(SelectorGlass()) }
    func glassPill() -> some View { modifier(GlassPill()) }
    func liquidGlass(cornerRadius: CGFloat = SafeDesign.radiusL, padding: CGFloat = SafeDesign.xl) -> some View {
        modifier(LiquidGlass(cornerRadius: cornerRadius, padding: padding))
    }
}