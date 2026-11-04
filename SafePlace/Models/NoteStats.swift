import Foundation

/// Pure aggregations over notes. Shared by Home and Insights so the logic lives
/// in one place and can be unit-tested without touching the views.
enum NoteStats {

    struct CategoryCount: Identifiable {
        let name: String
        let count: Int
        var id: String { name }
    }

    struct MoodCount: Identifiable {
        let mood: Mood
        let count: Int
        var id: String { mood.id }
    }

    struct DayCount: Identifiable {
        let date: Date
        let count: Int
        var id: Date { date }
    }

    /// Un día de la semana de la racha, ya resuelto para pintar: si hubo nota,
    /// si es hoy y si todavía no llega.
    struct StreakDay: Identifiable {
        enum State: Equatable { case done, missed, upcoming }

        let date: Date
        let count: Int
        let state: State
        let isToday: Bool
        var id: Date { date }
    }

    /// La meta de constancia a la que apunta el modal: siempre el siguiente
    /// hito, nunca un número inventado por la vista.
    struct StreakGoal {
        let target: Int
        let remaining: Int
        let progress: Double   // 0...1
    }

    /// Hitos de racha, de menor a mayor.
    static let streakMilestones = [3, 7, 14, 30, 60, 100, 365]

    static func todayCount(_ entries: [Entry], now: Date = Date()) -> Int {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.createdAt, inSameDayAs: now) }.count
    }

    static func daysThisWeek(_ entries: [Entry], now: Date = Date()) -> Int {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        let days = Set(entries.filter { interval.contains($0.createdAt) }.map { cal.startOfDay(for: $0.createdAt) })
        return days.count
    }

    /// Dias consecutivos con al menos una nota, contando desde hoy (o desde ayer,
    /// para no castigar a quien todavía no escribe hoy). Si la última nota es más
    /// vieja, la racha está en cero.
    static func currentStreak(_ entries: [Entry], now: Date = Date()) -> Int {
        let cal = Calendar.current
        let days = Set(entries.map { cal.startOfDay(for: $0.createdAt) })
        guard !days.isEmpty else { return 0 }
        let today = cal.startOfDay(for: now)
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: today) else { return 0 }
        var cursor: Date
        if days.contains(today) {
            cursor = today
        } else if days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    /// "1 día" / "3 días": la unidad que faltaba en las métricas de racha.
    static func daysLabel(_ count: Int) -> String {
        count == 1 ? String(localized: "1 day") : String(localized: "\(count) days")
    }

    /// La corrida de días de la semana en curso, en orden y según el primer día
    /// del calendario del usuario. Los días que todavía no llegan van como
    /// `.upcoming`: no son un fallo, son futuro.
    static func weekSnapshot(_ entries: [Entry], now: Date = Date()) -> [StreakDay] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        guard let week = cal.dateInterval(of: .weekOfYear, for: today) else { return [] }
        let counts = Dictionary(grouping: entries) { cal.startOfDay(for: $0.createdAt) }
            .mapValues { $0.count }
        let start = cal.startOfDay(for: week.start)
        return (0..<7).compactMap { offset in
            guard let raw = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            // Normalizar tras el salto: en DST, sumar un día puede caer a las
            // 23:00 del día anterior y romper el bucket.
            let day = cal.startOfDay(for: raw)
            let count = counts[day, default: 0]
            let state: StreakDay.State
            if day > today {
                state = .upcoming
            } else if count > 0 {
                state = .done
            } else {
                state = .missed
            }
            return StreakDay(date: day, count: count, state: state, isToday: day == today)
        }
    }

    /// El siguiente hito por encima de la racha actual. Al llegar al último
    /// (un año) la meta queda cumplida en vez de dispararse al infinito.
    static func streakGoal(for streak: Int) -> StreakGoal {
        let safe = max(streak, 0)
        let target = streakMilestones.first { $0 > safe } ?? streakMilestones[streakMilestones.count - 1]
        let remaining = max(target - safe, 0)
        let progress = target > 0 ? min(Double(safe) / Double(target), 1) : 1
        return StreakGoal(target: target, remaining: remaining, progress: progress)
    }

    /// Longest run of consecutive days with at least one note. Gentle, not punitive.
    static func personalBest(_ entries: [Entry]) -> Int {
        let cal = Calendar.current
        let days = Set(entries.map { cal.startOfDay(for: $0.createdAt) }).sorted()
        guard !days.isEmpty else { return 0 }
        var best = 0
        var current = 0
        var previous: Date?
        for day in days {
            // Compare calendar days, not `+86_400s`: adding one day across a DST change
            // lands on a different hour and used to break the streak.
            if let prev = previous, cal.dateComponents([.day], from: prev, to: day).day == 1 {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = day
        }
        return best
    }

    static func onThisDay(_ entries: [Entry], now: Date = Date()) -> [Entry] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.month, .day], from: now)
        return entries.filter { entry in
            let c = cal.dateComponents([.month, .day], from: entry.createdAt)
            return c.month == comps.month && c.day == comps.day && !cal.isDateInToday(entry.createdAt)
        }
    }

    static func categoryCounts(_ entries: [Entry], categories: [String]) -> [CategoryCount] {
        guard !entries.isEmpty else { return [] }
        let names = Set(categories).union(entries.map { $0.category })
        return names
            .map { name in CategoryCount(name: name, count: entries.filter { $0.category == name }.count) }
            .filter { $0.count > 0 }
            .sorted { lhs, rhs in
                // Ties break by name so the list order is stable between launches.
                lhs.count == rhs.count
                    ? lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                    : lhs.count > rhs.count
            }
    }

    static func moodCounts(_ entries: [Entry]) -> [MoodCount] {
        Mood.all
            .map { mood in MoodCount(mood: mood, count: entries.filter { $0.mood == mood.id }.count) }
            .filter { $0.count > 0 }
            .sorted { lhs, rhs in
                lhs.count == rhs.count ? lhs.mood.rank < rhs.mood.rank : lhs.count > rhs.count
            }
    }

    static func last14Days(_ entries: [Entry], now: Date = Date()) -> [DayCount] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        return (0..<14).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            return DayCount(date: day, count: entries.filter { cal.isDate($0.createdAt, inSameDayAs: day) }.count)
        }
    }

    private static let stopwords: Set<String> = [
        "the", "and", "for", "with", "that", "this", "from", "have", "was", "are", "not",
        "but", "all", "about", "into", "out", "your", "you", "just", "very", "really",
        "que", "los", "las", "una", "uno", "para", "con", "por", "como", "más", "mas",
        "pero", "porque", "cuando", "todo", "esta", "este", "esto", "muy", "del", "mis",
        "se", "su", "sus", "lo", "le", "ya", "sin", "sobre", "entre", "también", "hay"
    ]

    static func topKeywords(_ entries: [Entry], limit: Int = 8) -> [String] {
        var counts: [String: Int] = [:]
        for entry in entries {
            let words = "\(entry.title) \(entry.description)"
                .lowercased()
                .split(whereSeparator: { !$0.isLetter })
                .map(String.init)
                .filter { $0.count > 3 && !stopwords.contains($0) }
            for word in Set(words) { counts[word, default: 0] += 1 }
        }
        return counts
            .sorted { lhs, rhs in
                lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
            }
            .prefix(limit)
            .map(\.key)
    }
}
