import SwiftUI

struct Mood: Identifiable, Hashable {
    let id: String
    let color: Color
    let deepColor: Color
    let icon: String
    /// -1 (heavy) ... +1 (bright). Drives the app's emotional tint.
    let valence: CGFloat

    /// Calculada, no almacenada: así sigue al idioma que elijas en Ajustes
    /// sin reiniciar. Un `static let` se congelaría en el idioma de arranque.
    var label: String {
        switch id {
        case "bright": return String(localized: "Bright")
        case "hopeful": return String(localized: "Hopeful")
        case "mixed": return String(localized: "Mixed")
        case "heavy": return String(localized: "Heavy")
        default: return String(localized: "Calm")
        }
    }

    static let bright = Mood(
        id: "bright",
        color: SafeDesign.moodBright, deepColor: Color(hex: "E8A85F"),
        icon: "sun.max.fill", valence: 1.0)
    static let calm = Mood(
        id: "calm",
        color: SafeDesign.moodCalm, deepColor: Color(hex: "9DB8B0"),
        icon: "leaf.fill", valence: 0.2)
    static let hopeful = Mood(
        id: "hopeful",
        color: SafeDesign.moodHopeful, deepColor: Color(hex: "E79A8C"),
        icon: "camera.macro", valence: 0.6)
    static let mixed = Mood(
        id: "mixed",
        color: SafeDesign.moodMixed, deepColor: Color(hex: "E8B183"),
        icon: "cloud.sun.fill", valence: -0.2)
    static let heavy = Mood(
        id: "heavy",
        color: SafeDesign.moodHeavy, deepColor: Color(hex: "7E97B3"),
        icon: "cloud.rain.fill", valence: -0.8)

    static let all: [Mood] = [.bright, .calm, .hopeful, .mixed, .heavy]

    /// Stable position in ``all`` — ordering aid for deterministic tie-breaks.
    var rank: Int { Mood.all.firstIndex(of: self) ?? Mood.all.count }

    static func mood(for id: String?) -> Mood {
        all.first { $0.id == id } ?? .calm
    }

    /// How "alive" the mood feels — drives the mind graph's motion energy.
    var energy: CGFloat {
        switch id {
        case "bright": return 1.0
        case "hopeful": return 0.75
        case "calm": return 0.55
        case "mixed": return 0.35
        default: return 0.2
        }
    }
}
