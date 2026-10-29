import SwiftUI

/// The app canvas — near-white (light) or pure black (dark) with a very faint
/// glow in the current emotional tint. Deliberately subtle: the app stays sober
/// and the color only whispers.
struct BackgroundOrbs: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            SafeDesign.canvas
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    theme.tint.opacity(0.20),
                    theme.tint.opacity(0.06),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 360
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    theme.tintStrong.opacity(0.12),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()

            PaperGrain()
                .ignoresSafeArea()
        }
        .animation(SafeDesign.spring, value: theme)
    }
}

/// Textura de papel: puntos deterministas a opacidad muy baja. El contrato de
/// diseño pide "subtle paper grain" y no existía. Es estática (no anima, no
/// cuesta frames) y no intercepta toques.
struct PaperGrain: View {
    var opacity: Double = 0.03
    var dotSize: CGFloat = 1

    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 0x9E37_79B9_7F4A_7C15
            func next() -> UInt64 {
                seed ^= seed << 13
                seed ^= seed >> 7
                seed ^= seed << 17
                return seed
            }
            let density = max(1, Int(size.width * size.height / 900))
            for _ in 0..<density {
                let x = CGFloat(next() % 10_000) / 10_000 * size.width
                let y = CGFloat(next() % 10_000) / 10_000 * size.height
                let dot = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                context.fill(Path(ellipseIn: dot), with: .color(SafeDesign.ink.opacity(opacity)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    BackgroundOrbs()
}
