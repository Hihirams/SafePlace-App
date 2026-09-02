import Foundation

// MARK: - Shared container (main app + Share extension)

let appGroupID = "group.com.hihirams.safeplace"

/// A note captured from the iOS Share sheet (e.g. text shared from Apple Notes).
struct SharedNote: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var text: String
    var createdAt: Date
}

enum SharedNoteStore {
    static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("SharedNotes.json")
    }

    static func load() -> [SharedNote] {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([SharedNote].self, from: data)) ?? []
    }

    static func save(_ notes: [SharedNote]) {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: url, options: .atomic)
        } catch { }
    }
}

// MARK: - Store

private struct PersistedData: Codable {
    var entries: [Entry]
    var categories: [String]
    var resources: [Resource]
}

final class Store: ObservableObject {
    @Published var entries: [Entry]
    @Published var categories: [String]
    @Published var resources: [Resource]

    private let fileURL: URL

    static let defaultCategories = [
        "Habits", "People", "Places", "Activities", "Music", "Self-care"
    ]

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("SafePlaceData.json")

        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(PersistedData.self, from: data) {
            entries = saved.entries
            categories = saved.categories
            resources = saved.resources
        } else {
            entries = Self.seedEntries
            categories = Self.defaultCategories
            resources = []
            Store.save(entries: entries, categories: categories, resources: resources, to: fileURL)
        }
    }

    // MARK: - Persistence

    private static func save(entries: [Entry], categories: [String], resources: [Resource], to url: URL) {
        let data = PersistedData(entries: entries, categories: categories, resources: resources)
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? encoded.write(to: url, options: .atomic)
    }

    private func persist() {
        Store.save(entries: entries, categories: categories, resources: resources, to: fileURL)
    }

    // MARK: - Entries

    func addEntry(_ entry: Entry) {
        entries.insert(entry, at: 0)
        if !entry.category.isEmpty && !categories.contains(entry.category) {
            categories.append(entry.category)
        }
        persist()
    }

    func updateEntry(_ entry: Entry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
        }
        if !entry.category.isEmpty && !categories.contains(entry.category) {
            categories.append(entry.category)
        }
        persist()
    }

    func deleteEntry(id: String) {
        entries.removeAll { $0.id == id }
        persist()
    }

    func addCategory(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !categories.contains(trimmed) else { return }
        categories.append(trimmed)
        persist()
    }

    // MARK: - Resources

    func addResource(_ resource: Resource) {
        resources.insert(resource, at: 0)
        persist()
    }

    func deleteResource(id: String) {
        resources.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Shared notes (from Apple Notes / Share sheet)

    /// Move a shared note into the safe place as a regular entry.
    func importSharedNote(_ note: SharedNote) {
        let title = note.title.isEmpty ? "From my notes" : note.title
        addEntry(Entry(
            id: "shared-\(UUID().uuidString)",
            title: title,
            description: note.text,
            category: "Notes",
            mood: "calm",
            color: CardColor.cream.rawValue,
            createdAt: note.createdAt
        ))
        if !categories.contains("Notes") {
            categories.append("Notes")
            persist()
        }
    }

    /// Remove a shared note without importing it.
    func discardSharedNote(_ note: SharedNote) {
        var notes = SharedNoteStore.load()
        notes.removeAll { $0.id == note.id }
        SharedNoteStore.save(notes)
    }

    // MARK: - Seed data (mirrors the web version)

    private static func daysAgo(_ days: Double) -> Date {
        Date().addingTimeInterval(-86_400 * days)
    }

    private static var seedEntries: [Entry] {
        [
            Entry(
                id: "seed-1",
                title: "Morning walk by the park",
                description: "A slow 20-minute walk before work resets my head. No headphones, just the sounds around me.",
                category: "Habits",
                mood: "calm",
                color: CardColor.mint.rawValue,
                createdAt: daysAgo(2)
            ),
            Entry(
                id: "seed-2",
                title: "Calling my sister",
                description: "Talking to her on the phone always makes the day feel lighter. We laugh a lot together.",
                category: "People",
                mood: "bright",
                color: CardColor.peach.rawValue,
                createdAt: daysAgo(4)
            ),
            Entry(
                id: "seed-3",
                title: "My favorite playlist",
                description: "Putting on lo-fi while tidying my room turns a chore into something calm and pleasant.",
                category: "Music",
                mood: "hopeful",
                color: CardColor.lavender.rawValue,
                createdAt: daysAgo(6)
            ),
            Entry(
                id: "seed-4",
                title: "Writing things down",
                description: "Naming what I feel instead of keeping it inside. A few sentences are enough to feel lighter.",
                category: "Self-care",
                mood: "mixed",
                color: CardColor.pink.rawValue,
                createdAt: daysAgo(9)
            )
        ]
    }
}

// MARK: - Date formatting helpers

extension Date {
    func formattedShort() -> String {
        formatted(.dateTime.month(.abbreviated).day().year())
    }

    func formattedDay() -> String {
        formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
    }

    func formattedMedium() -> String {
        formatted(.dateTime.month(.wide).day().year())
    }

    var isSameDayAs: (Date) -> Bool { { Calendar.current.isDate(self, inSameDayAs: $0) } }
}