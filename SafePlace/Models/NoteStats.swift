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

    /// Longest run of consecutive days with at least one note. Gentle, not punitive.
    static func personalBest(_ entries: [Entry]) -> Int {
        let cal = Calendar.current
        let days = Set(entries.map { cal.startOfDay(for: $0.createdAt) }).sorted()
        guard !days.isEmpty else { return 0 }
        var best = 0
        var current = 0
        var previous: Date?
        for day in days {
            if let prev = previous, cal.date(byAdding: .day, value: 1, to: prev) == day {
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
            .sorted { $0.count > $1.count }
    }

    static func moodCounts(_ entries: [Entry]) -> [MoodCount] {
        Mood.all
            .map { mood in MoodCount(mood: mood, count: entries.filter { $0.mood == mood.id }.count) }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
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
        return counts.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }
}
