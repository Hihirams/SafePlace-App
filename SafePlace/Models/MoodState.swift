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
        var counts: [String: Int] = [:]
        var valenceSum: CGFloat = 0
        var energySum: CGFloat = 0
        for entry in entries {
            counts[entry.mood, default: 0] += 1
            let mood = Mood.mood(for: entry.mood)
            valenceSum += mood.valence
            energySum += mood.energy
        }
        guard let top = counts.max(by: { $0.value < $1.value }) else { return .neutral }
        return MoodState(
            dominant: Mood.mood(for: top.key),
            dominance: CGFloat(top.value) / CGFloat(entries.count),
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
