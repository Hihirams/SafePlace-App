import SwiftUI

/// The app canvas — a soft powder-blush wash with two faint palette glows so the
/// frosted glass tab bar has something gentle to refract. Deliberately subtle:
/// it should read as clean paper (light) or deep black (dark), not a wallpaper.
struct BackgroundOrbs: View {
    var body: some View {
        ZStack {
            SafeDesign.canvas
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    SafeDesign.peachGlow.opacity(0.28),
                    SafeDesign.peachFuzz.opacity(0.10),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 340
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    SafeDesign.powderBlush.opacity(0.24),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    BackgroundOrbs()
}
