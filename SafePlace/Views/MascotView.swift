import SwiftUI

/// A soft, faceless little character: a dumpling-ish blob that is narrower at
/// the top and gets chubbier toward the bottom. It only bobs and breathes.
struct DumplingShape: Shape {
    /// 0 = slim oval, 1 = extra chubby.
    var roundness: CGFloat = 0.6

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let r = max(0, min(roundness, 1))

        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * w, y: rect.minY + y * h)
        }

        // Shoulders get a little wider and the belly a little rounder as
        // roundness grows.
        let shoulderX = 0.30 - 0.04 * r
        let bellyX = 0.02 + 0.03 * (1 - r)

        var p = Path()
        p.move(to: pt(0.5, 0.04))
        // top-right shoulder -> right belly
        p.addCurve(to: pt(0.98, 0.56),
                   control1: pt(0.66, 0.03),
                   control2: pt(0.99, 0.26))
        // right belly -> bottom center
        p.addCurve(to: pt(0.5, 0.99),
                   control1: pt(0.99, 0.82),
                   control2: pt(0.80, 0.99))
        // bottom center -> left belly
        p.addCurve(to: pt(bellyX, 0.56),
                   control1: pt(0.20, 0.99),
                   control2: pt(bellyX, 0.82))
        // left belly -> top-left shoulder -> back to top
        p.addCurve(to: pt(0.5, 0.04),
                   control1: pt(bellyX, 0.26),
                   control2: pt(0.34, 0.03))
        _ = shoulderX
        p.closeSubpath()
        return p
    }
}

struct MascotView: View {
    var color: Color = SafeDesign.accent
    var size: CGFloat = 190
    var animate: Bool = true

    @State private var float = false
    @State private var breathe = false

    var body: some View {
        let height = size * 0.92

        ZStack {
            // Soft ground shadow.
            Ellipse()
                .fill(color.opacity(0.28))
                .frame(width: size * 0.62, height: size * 0.12)
                .blur(radius: 10)
                .offset(y: height * 0.52)

            DumplingShape(roundness: 0.62)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.98), color.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    DumplingShape(roundness: 0.62)
                        .stroke(.white.opacity(0.4), lineWidth: 1)
                }
                .overlay(alignment: .top) {
                    // Glossy top highlight.
                    Ellipse()
                        .fill(.white.opacity(0.35))
                        .frame(width: size * 0.28, height: size * 0.12)
                        .blur(radius: 4)
                        .offset(x: -size * 0.08, y: height * 0.16)
                        .allowsHitTesting(false)
                }
                .shadow(color: .black.opacity(0.16), radius: 18, y: 12)
                .scaleEffect(x: breathe ? 1.03 : 0.99, y: breathe ? 0.98 : 1.02, anchor: .bottom)
                .offset(y: float ? -6 : 6)
        }
        .frame(width: size, height: height + size * 0.2)
        .animation(animate ? .easeInOut(duration: 4.2).repeatForever(autoreverses: true) : .default, value: float)
        .animation(animate ? .easeInOut(duration: 3.4).repeatForever(autoreverses: true) : .default, value: breathe)
        .onAppear {
            guard animate else { return }
            float = true
            breathe = true
        }
        .accessibilityHidden(true)
    }
}

/// Colors offered for the character.
enum MascotColorOption: String, CaseIterable, Identifiable {
    case peach = "FEC89A"
    case blush = "FEC5BB"
    case sage = "D8E2DC"
    case lavender = "B8A4ED"
    case coral = "FF6B5A"
    case mint = "A4D4C5"

    var id: String { rawValue }
    var color: Color { Color(hex: rawValue) }
}

#Preview {
    ZStack {
        BackgroundOrbs()
        MascotView()
    }
}
