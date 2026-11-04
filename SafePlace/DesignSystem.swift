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

    // MARK: - Surfaces (warm editorial paper)
    static let canvas        = dyn("FAF8F4", "000000")   // warm near-white / pure black
    static let surfaceSoft   = dyn("F3EFE8", "141414")   // soft paper
    static let surfaceCard   = dyn("FFFFFF", "0E0E0E")   // white sheet / near-black
    static let surfaceStrong = dyn("ECE7DF", "1C1C1C")   // pressed / raised
    static let hairline      = dynWhiteInk(0.10, 0.12)

    // MARK: - Ink (text)
    static let ink          = dyn("2A2622", "F3EEE7")
    static let inkSecondary = dyn("6B625A", "B8AFA6")
    static let muted        = dynWhiteInk(0.66, 0.55)

    /// Tinta para escribir **encima de un relleno de color** (tarjetas de nota,
    /// píldoras de mood). Las fichas conservan su pastel en modo oscuro, así que
    /// esta tinta no puede adaptarse: si se invierte, el texto desaparece.
    static let inkOnFill    = Color(hex: "2A2622")

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

    // MARK: - Typography (semantic so it scales with Dynamic Type)
    // Display / titles are serif; body & UI are SF.
    static let serifHero   = Font.system(.largeTitle, design: .serif).weight(.semibold)
    static let serifTitle  = Font.system(.title2, design: .serif).weight(.semibold)
    static let serifHead   = Font.system(.title3, design: .serif).weight(.semibold)
    static let heroFont    = Font.system(.title, design: .serif).weight(.semibold)
    static let displayFont = Font.system(.title, design: .serif).weight(.semibold)
    static let largeTitle  = Font.system(.title2, design: .serif).weight(.semibold)
    static let title       = Font.system(.title3).weight(.bold)
    static let headline    = Font.system(.headline)
    static let body        = Font.system(.subheadline).weight(.medium)
    static let caption     = Font.system(.footnote).weight(.medium)
    static let micro       = Font.system(.caption2).weight(.medium)
    static let tabLabel    = Font.system(.caption2).weight(.semibold)

    /// Fuente del sistema que **sí** respeta Dynamic Type.
    /// `.system(size:)` fija no escala nunca; este helper pasa el tamaño por
    /// UIFontMetrics para que crezca con la preferencia de texto del sistema.
    static func scaled(_ size: CGFloat,
                       weight: Font.Weight = .regular,
                       design: Font.Design = .default) -> Font {
        let style = textStyle(for: size)
        let scaledSize = UIFontMetrics(forTextStyle: style).scaledValue(for: size)
        return .system(size: scaledSize, weight: weight, design: design)
    }

    /// Igual que `scaled`, pero con un techo en puntos. Para arte decorativo que
    /// vive dentro de un círculo de tamaño fijo (llamas, iconos de un botón):
    /// crece con Dynamic Type hasta donde cabe y ahí se detiene.
    static func scaled(_ size: CGFloat,
                       weight: Font.Weight = .regular,
                       design: Font.Design = .default,
                       cappedAt cap: CGFloat) -> Font {
        let style = textStyle(for: size)
        let scaledSize = min(UIFontMetrics(forTextStyle: style).scaledValue(for: size), cap)
        return .system(size: scaledSize, weight: weight, design: design)
    }

    /// Estilo de texto contra el que escala un tamaño custom. Una etiqueta de
    /// 10 pt crece como caption2, no como cuerpo.
    private static func textStyle(for size: CGFloat) -> UIFont.TextStyle {
        switch size {
        case ..<12: return .caption2
        case ..<15: return .footnote
        case ..<18: return .subheadline
        default:    return .body
        }
    }

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

    /// Ancho de la marca en el splash; el mismo tamaño que pinta la launch screen.
    static let splashMarkSize: CGFloat = 128

    // MARK: - Motion
    //
    // La fuente de verdad de las animaciones es `SafeMotion`. Estos alias se
    // mantienen porque medio app los usa; no añadir valores nuevos aquí.
    static let spring = SafeMotion.gentle
    static let springSnappy = SafeMotion.quick
    static let springBouncy = SafeMotion.bouncy
    static let easeOut = Animation.easeOut(duration: 0.25)
}

/// Tokens de movimiento de SafePlace.
///
/// Los números están alineados con `design/SafePlace-Motion.figcraft` y con el
/// contrato de `.opencode/skills/safeplace-motion/SKILL.md`: si cambia uno,
/// cambian los tres. Ninguna vista debe escribir una duración literal.
enum SafeMotion {

    // MARK: Cambios de estado

    /// Cambio con peso: entrada de pantalla, aparición de una sección.
    static let gentle = Animation.spring(response: 0.35, dampingFraction: 0.78)

    /// Respuesta a un toque, navegación, cambio de icono.
    static let quick = Animation.spring(response: 0.28, dampingFraction: 0.82)

    /// Momento emocional: elegir un mood, confirmar un check-in.
    static let bouncy = Animation.spring(response: 0.42, dampingFraction: 0.68)

    /// Selector de la tab bar, que sigue un arrastre y debe retargetear.
    static let selector = Animation.interactiveSpring(response: 0.26, dampingFraction: 0.74)

    // MARK: Loops ambientales
    //
    // `easeInOut` con autoreverse, nunca spring: un spring en bucle se lee
    // como temblor nervioso. Todos se detienen con Reduce Motion.

    /// La llama de la racha: respira como una vela.
    static let flame = Animation.easeInOut(duration: 1.15).repeatForever(autoreverses: true)

    /// El personaje flota.
    static let float = Animation.easeInOut(duration: 4.2).repeatForever(autoreverses: true)

    /// El personaje respira.
    static let breathe = Animation.easeInOut(duration: 3.4).repeatForever(autoreverses: true)

    // MARK: Entrada de pantalla

    /// Separación entre bloques de la cascada de entrada.
    static let entranceStep: Double = 0.04

    /// Cuánto sube cada bloque al entrar.
    static let entranceRise: CGFloat = 12

    /// Fundido con el que el splash deja ver la app.
    static let splashFade: Double = 0.55

    /// El tinte del splash entra.
    static let splashTintIn = Animation.easeOut(duration: 0.6)

    /// Cada letra del wordmark, al teclearse.
    static let splashType = Animation.easeOut(duration: 0.18)

    /// Salida de una capa que tapa la app (splash, onboarding).
    static let dismiss = Animation.easeInOut(duration: 0.4)
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

/// Minimum tappable size (Apple HIG).
let minTouchTarget: CGFloat = 44

// MARK: - Entrada de pantalla

/// La cascada de entrada: cada bloque aparece y sube 12 pt, separado 40 ms del
/// anterior. Con Reduce Motion no hay desplazamiento ni espera: todo visible.
struct RevealModifier: ViewModifier {
    let stage: Int
    let threshold: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(stage >= threshold ? 1 : 0)
            .offset(y: stage >= threshold || reduceMotion ? 0 : SafeMotion.entranceRise)
    }
}

extension View {
    /// Aplica el estado de la cascada de entrada a un bloque.
    /// - Parameters:
    ///   - stage: bloque alcanzado por la cascada (0 = nada visible todavía).
    ///   - threshold: bloque en el que este elemento entra.
    func reveal(stage: Int, at threshold: Int) -> some View {
        modifier(RevealModifier(stage: stage, threshold: threshold))
    }
}

/// A stack that folds from horizontal to vertical at accessibility text sizes,
/// so labels never truncate. Uses `AnyLayout` to keep identity/state across the swap.
struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var spacing: CGFloat = SafeDesign.s
    var verticalAlignment: HorizontalAlignment = .leading
    @ViewBuilder var content: Content

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: verticalAlignment, spacing: spacing))
            : AnyLayout(HStackLayout(alignment: .center, spacing: spacing))
        layout { content }
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
