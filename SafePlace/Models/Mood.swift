import SwiftUI

struct Mood: Identifiable, Hashable {
    let id: String
    let label: String
    let color: Color
    let deepColor: Color
    let icon: String
    /// -1 (heavy) ... +1 (bright). Drives the app's emotional tint.
    let valence: CGFloat

    static let bright = Mood(
        id: "bright", label: "Bright",
        color: SafeDesign.moodBright, deepColor: Color(hex: "E8A85F"),
        icon: "sun.max.fill", valence: 1.0)
    static let calm = Mood(
        id: "calm", label: "Calm",
        color: SafeDesign.moodCalm, deepColor: Color(hex: "9DB8B0"),
        icon: "leaf.fill", valence: 0.2)
    static let hopeful = Mood(
        id: "hopeful", label: "Hopeful",
        color: SafeDesign.moodHopeful, deepColor: Color(hex: "E79A8C"),
        icon: "flower2.fill", valence: 0.6)
    static let mixed = Mood(
        id: "mixed", label: "Mixed",
        color: SafeDesign.moodMixed, deepColor: Color(hex: "E8B183"),
        icon: "cloud.sun.fill", valence: -0.2)
    static let heavy = Mood(
        id: "heavy", label: "Heavy",
        color: SafeDesign.moodHeavy, deepColor: Color(hex: "7E97B3"),
        icon: "cloud.rain.fill", valence: -0.8)

    static let all: [Mood] = [.bright, .calm, .hopeful, .mixed, .heavy]

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
