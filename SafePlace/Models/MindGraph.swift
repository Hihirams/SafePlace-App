import Foundation
import SwiftUI

// MARK: - Mind graph data (clustered by category)

/// A category cluster hub — a big ball the notes orbit around.
struct MindHub: Identifiable {
    let id: String            // category name
    let category: String
    let count: Int
    var radius: CGFloat
    var color: Color
}

/// A note inside a category cluster.
struct MindNode: Identifiable {
    let id: String
    let entry: Entry
    let category: String
    var radius: CGFloat
    var color: Color
}

/// A member-to-hub connection.
struct MindEdge: Identifiable {
    let id: String
    let from: String          // member id
    let to: String            // hub id (category)
    let weight: CGFloat
}

enum MindColorMode: String, CaseIterable, Identifiable {
    case wave, category

    var id: String { rawValue }

    var label: String {
        switch self {
        case .wave: return "Wave"
        case .category: return "Category"
        }
    }

    var icon: String {
        switch self {
        case .wave: return "drop.fill"
        case .category: return "tag.fill"
        }
    }
}

struct MindGraph {
    let hubs: [MindHub]
    let nodes: [MindNode]
    let edges: [MindEdge]

    static let maxNodes = 160

    private static let palette: [Color] = [
        SafeDesign.pink, SafeDesign.teal, SafeDesign.lavender,
        SafeDesign.peach, SafeDesign.ochre, SafeDesign.mint, SafeDesign.coral
    ]

    static func color(forCategory category: String) -> Color {
        let hash = category.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7fffffff }
        return palette[hash % palette.count]
    }

    static func build(from entries: [Entry]) -> MindGraph {
        let limited = entries.count > maxNodes ? Array(entries.prefix(maxNodes)) : entries

        var groups: [String: [Entry]] = [:]
        for entry in limited { groups[entry.category, default: []].append(entry) }

        let categories = groups.keys.sorted()

        let hubs = categories.map { category -> MindHub in
            let count = groups[category]?.count ?? 0
            return MindHub(
                id: category,
                category: category,
                count: count,
                radius: hubRadius(count),
                color: color(forCategory: category)
            )
        }

        var nodes: [MindNode] = []
        var edges: [MindEdge] = []
        for category in categories {
            let color = color(forCategory: category)
            for entry in groups[category] ?? [] {
                nodes.append(MindNode(id: entry.id, entry: entry, category: category, radius: memberRadius(entry), color: color))
                edges.append(MindEdge(id: "\(entry.id)-\(category)", from: entry.id, to: category, weight: 1))
            }
        }

        return MindGraph(hubs: hubs, nodes: nodes, edges: edges)
    }

    static func hubRadius(_ count: Int) -> CGFloat {
        26 + min(CGFloat(count), 14) * 2.0
    }

    static func memberRadius(_ entry: Entry) -> CGFloat {
        min(9 + CGFloat(entry.description.count) * 0.01, 16)
    }

    // MARK: - Mood energy / dominance

    /// The mood that shows up most across the notes, with how dominant it is.
    static func dominantMood(of entries: [Entry]) -> (mood: Mood, dominance: CGFloat)? {
        guard !entries.isEmpty else { return nil }
        var counts: [String: Int] = [:]
        for entry in entries { counts[entry.mood, default: 0] += 1 }
        guard let top = counts.max(by: { $0.value < $1.value }) else { return nil }
        let mood = Mood.mood(for: top.key)
        let dominance = CGFloat(top.value) / CGFloat(entries.count)
        return (mood, dominance)
    }

    /// Average mood energy across all notes — 0 (heavy) ... 1 (bright).
    static func averageEnergy(of entries: [Entry]) -> CGFloat {
        guard !entries.isEmpty else { return 0.5 }
        let sum = entries.reduce(CGFloat(0)) { $0 + Mood.mood(for: $1.mood).energy }
        return sum / CGFloat(entries.count)
    }
}
