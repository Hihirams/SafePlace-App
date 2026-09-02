import SwiftUI

/// The app canvas — a warm off-white with two very faint brand glows so the
/// frosted glass tab bar has something soft to refract. Deliberately subtle:
/// it should read as clean paper, not a gradient wallpaper.
struct BackgroundOrbs: View {
    var body: some View {
        ZStack {
            SafeDesign.canvas
                .ignoresSafeArea()

            // Warm clay glow — top trailing
            RadialGradient(
                colors: [
                    SafeDesign.peach.opacity(0.12),
                    SafeDesign.peach.opacity(0.03),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 320
            )
            .ignoresSafeArea()

            // Soft lavender glow — bottom leading
            RadialGradient(
                colors: [
                    SafeDesign.lavender.opacity(0.08),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 260
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    BackgroundOrbs()
}