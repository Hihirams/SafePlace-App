import Foundation
import SwiftUI

// MARK: - Mind graph data

/// A node is one note in your safe place.
struct MindNode: Identifiable {
    let id: String
    let entry: Entry
    var position: CGPoint
    var radius: CGFloat
    var color: Color
    var degree: Int
}

/// A weighted connection between two nodes.
struct MindEdge: Identifiable {
    let id: String
    let from: String
    let to: String
    let weight: CGFloat
}

enum MindColorMode: String, CaseIterable, Identifiable {
    case mood, category, card, contagion

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mood: return "Mood"
        case .category: return "Category"
        case .card: return "Card"
        case .contagion: return "Wave"
        }
    }

    var icon: String {
        switch self {
        case .mood: return "heart.fill"
        case .category: return "tag.fill"
        case .card: return "square.fill"
        case .contagion: return "drop.fill"
        }
    }
}

/// The full graph derived from the user's notes.
struct MindGraph {
    let nodes: [MindNode]
    let edges: [MindEdge]

    /// Node count (used to keep graphs tractable).
    static let maxNodes = 160

    static func build(from entries: [Entry], colorMode: MindColorMode, minWeight: CGFloat) -> MindGraph {
        // Keep the simulation fast even with many notes.
        let limited = entries.count > maxNodes ? Array(entries.prefix(maxNodes)) : entries

        var degree: [String: Int] = [:]
        var edges: [MindEdge] = []

        for i in 0..<limited.count {
            for j in (i + 1)..<limited.count {
                let a = limited[i]
                let b = limited[j]
                let w = weight(between: a, b)
                if w >= minWeight {
                    let eid = a.id < b.id ? "\(a.id)-\(b.id)" : "\(b.id)-\(a.id)"
                    edges.append(MindEdge(id: eid, from: a.id, to: b.id, weight: w))
                    degree[a.id, default: 0] += 1
                    degree[b.id, default: 0] += 1
                }
            }
        }

        let nodes = limited.map { entry -> MindNode in
            MindNode(
                id: entry.id,
                entry: entry,
                position: .zero,
                radius: radius(for: entry, degree: degree[entry.id, default: 0]),
                color: color(for: entry, mode: colorMode),
                degree: degree[entry.id, default: 0]
            )
        }

        return MindGraph(nodes: nodes, edges: edges)
    }

    // MARK: - Heuristics

    private static func weight(between a: Entry, _ b: Entry) -> CGFloat {
        var w: CGFloat = 0
        if a.category == b.category { w += 1.0 }
        if a.mood == b.mood { w += 0.8 }
        if a.color == b.color { w += 0.3 }
        w += CGFloat(sharedKeywords(a, b)) * 0.6
        return min(w, 3.0)
    }

    private static let stopwords: Set<String> = [
        "the", "and", "for", "with", "that", "this", "from", "have", "was",
        "are", "not", "but", "all", "about", "into", "out", "my", "your",
        "a", "an", "i", "to", "of", "in", "on", "it", "me", "we", "you",
        "he", "she", "they", "is", "be", "at", "by", "so", "when", "what",
        "them", "their", "just", "can", "will", "like", "make", "get"
    ]

    private static func keywords(_ entry: Entry) -> Set<String> {
        let text = "\(entry.title) \(entry.description)".lowercased()
        return Set(
            text.split(whereSeparator: { !$0.isLetter })
                .map(String.init)
                .filter { $0.count > 3 && !stopwords.contains($0) }
        )
    }

    private static func sharedKeywords(_ a: Entry, _ b: Entry) -> Int {
        keywords(a).intersection(keywords(b)).count
    }

    // MARK: - Appearance

    private static func color(for entry: Entry, mode: MindColorMode) -> Color {
        switch mode {
        case .mood, .contagion:
            return Mood.mood(for: entry.mood).color
        case .category:
            let palette: [Color] = [
                SafeDesign.pink, SafeDesign.teal, SafeDesign.lavender,
                SafeDesign.peach, SafeDesign.ochre, SafeDesign.mint, SafeDesign.coral
            ]
            let hash = abs(entry.category.hashValue)
            return palette[hash % palette.count]
        case .card:
            return entry.cardColor.fill
        }
    }

    /// The mood that shows up most across the notes, with how dominant it is
    /// (its share of all notes, 0...1). Drives the "wave" contagion view.
    static func dominantMood(of entries: [Entry]) -> (mood: Mood, dominance: CGFloat)? {
        guard !entries.isEmpty else { return nil }
        var counts: [String: Int] = [:]
        for entry in entries { counts[entry.mood, default: 0] += 1 }
        guard let top = counts.max(by: { $0.value < $1.value }) else { return nil }
        let mood = Mood.mood(for: top.key)
        let dominance = CGFloat(top.value) / CGFloat(entries.count)
        return (mood, dominance)
    }

    /// Bigger for connected notes and for notes with more to say.
    private static func radius(for entry: Entry, degree: Int) -> CGFloat {
        let connected = log2(CGFloat(degree) + 2) * 4.5
        let written = CGFloat(entry.description.count) * 0.012
        return min(16 + connected + written, 34)
    }

    // MARK: - Mood energy

    /// Average mood energy across all notes — 0 (heavy) ... 1 (bright).
    static func averageEnergy(of entries: [Entry]) -> CGFloat {
        guard !entries.isEmpty else { return 0.5 }
        let sum = entries.reduce(CGFloat(0)) { $0 + Mood.mood(for: $1.mood).energy }
        return sum / CGFloat(entries.count)
    }
}