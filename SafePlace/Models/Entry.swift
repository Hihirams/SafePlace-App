import Foundation

struct Entry: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var description: String
    var category: String
    var mood: String
    var color: String
    var createdAt: Date

    var cardColor: CardColor { CardColor(rawValue: color) ?? .cream }
    var moodValue: Mood { Mood.all.first { $0.id == mood } ?? .calm }
}