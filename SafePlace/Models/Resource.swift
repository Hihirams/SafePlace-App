import Foundation

struct Resource: Identifiable, Codable, Hashable {
    var id: String
    var text: String
    var url: String
    var type: String
    var createdAt: Date

    var isLink: Bool { type == "link" && !url.isEmpty }
}