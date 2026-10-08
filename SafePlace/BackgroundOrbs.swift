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
        }
        .animation(SafeDesign.spring, value: theme)
    }
}

#Preview {
    BackgroundOrbs()
}
