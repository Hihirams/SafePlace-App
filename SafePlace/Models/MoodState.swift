import SwiftUI

/// The emotional state derived from all notes. It quietly drives the whole
/// app's tint — the character, accents, graphs and a very faint background glow.
struct MoodState {
    var dominant: Mood
    var dominance: CGFloat   // share of the dominant mood, 0...1
    var valence: CGFloat     // -1 (heavy) ... +1 (bright)
    var energy: CGFloat      // 0...1

    static let neutral = MoodState(dominant: .calm, dominance: 0, valence: 0, energy: 0.55)

    static func derive(from entries: [Entry]) -> MoodState {
        guard !entries.isEmpty else { return .neutral }
        // Delegate the dominant mood to MindGraph so both agree on ties.
        guard let dominant = MindGraph.dominantMood(of: entries) else { return .neutral }
        var valenceSum: CGFloat = 0
        var energySum: CGFloat = 0
        for entry in entries {
            let mood = Mood.mood(for: entry.mood)
            valenceSum += mood.valence
            energySum += mood.energy
        }
        return MoodState(
            dominant: dominant.mood,
            dominance: dominant.dominance,
            valence: valenceSum / CGFloat(entries.count),
            energy: energySum / CGFloat(entries.count)
        )
    }
}

/// A soft, adaptive tint passed down the view tree.
struct AppTheme: Equatable {
    var tint: Color
    var tintStrong: Color

    static let standard = AppTheme(tint: SafeDesign.accent, tintStrong: SafeDesign.accentDeep)

    init(tint: Color, tintStrong: Color) {
        self.tint = tint
        self.tintStrong = tintStrong
    }

    init(moodState: MoodState) {
        self.tint = moodState.dominant.color
        self.tintStrong = moodState.dominant.deepColor
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .standard
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}
