import SwiftUI

struct Mood: Identifiable, Hashable {
    let id: String
    let label: String
    let color: Color
    let icon: String

    static let bright = Mood(id: "bright", label: "Bright", color: SafeDesign.moodBright, icon: "sun.max.fill")
    static let calm = Mood(id: "calm", label: "Calm", color: SafeDesign.moodCalm, icon: "leaf.fill")
    static let hopeful = Mood(id: "hopeful", label: "Hopeful", color: SafeDesign.moodHopeful, icon: "flower2.fill")
    static let mixed = Mood(id: "mixed", label: "Mixed", color: SafeDesign.moodMixed, icon: "cloud.sun.fill")
    static let heavy = Mood(id: "heavy", label: "Heavy", color: SafeDesign.moodHeavy, icon: "cloud.rain.fill")

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