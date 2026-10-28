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

    /// Último fallo al escribir en disco. `nil` cuando todo se guardó bien.
    /// Antes los errores se descartaban con `try?` y la UI seguía como si nada.
    @Published private(set) var lastSaveError: String?

    static let defaultCategories = [
        "Hábitos", "Personas", "Lugares", "Actividades", "Música", "Autocuidado"
    ]

    init(fileURL: URL? = nil, seed: Bool = true) {
        let resolved = fileURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
                .appendingPathComponent("SafePlaceData.json")
            ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("SafePlaceData.json")
        self.fileURL = resolved

        if let data = try? Data(contentsOf: resolved),
           let saved = try? JSONDecoder().decode(PersistedData.self, from: data) {
            entries = saved.entries
            categories = saved.categories
            resources = saved.resources
            if CategoryMigration.apply(entries: &entries, categories: &categories) {
                persist()
            }
        } else if seed {
            entries = Self.seedEntries
            categories = Self.defaultCategories
            resources = []
            persist()
        } else {
            entries = []
            categories = Self.defaultCategories
            resources = []
            persist()
        }
    }

    // MARK: - Migración de categorías heredadas

    /// La app se escribió primero en inglés. Estas categorías eran nuestras, no del
    /// usuario, así que se renombran una sola vez al cargar (la operación es idempotente:
    /// después de migrar ya no queda ningún nombre legacy).
    enum CategoryMigration {
        static let legacyNames: [String: String] = [
            "Habits": "Hábitos",
            "People": "Personas",
            "Places": "Lugares",
            "Activities": "Actividades",
            "Music": "Música",
            "Self-care": "Autocuidado",
            "Notes": "Notas"
        ]

        @discardableResult
        static func apply(entries: inout [Entry], categories: inout [String]) -> Bool {
            var changed = false
            entries = entries.map { entry in
                guard let migrated = legacyNames[entry.category] else { return entry }
                var copy = entry
                copy.category = migrated
                changed = true
                return copy
            }
            let mapped = categories.map { legacyNames[$0] ?? $0 }
            if mapped != categories {
                var seen: [String] = []
                for name in mapped where !seen.contains(name) { seen.append(name) }
                categories = seen
                changed = true
            }
            return changed
        }
    }

    // MARK: - Persistence

    private static func write(entries: [Entry], categories: [String], resources: [Resource], to url: URL) throws {
        let data = PersistedData(entries: entries, categories: categories, resources: resources)
        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: url, options: .atomic)
    }

    private func persist() {
        do {
            try Store.write(entries: entries, categories: categories, resources: resources, to: fileURL)
            lastSaveError = nil
        } catch {
            lastSaveError = String(localized: "Your changes couldn't be saved to this device.")
        }
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

    // MARK: - Backup

    struct Backup: Codable {
        var entries: [Entry]
        var categories: [String]
        var resources: [Resource]
    }

    func exportJSON() -> Data? {
        let backup = Backup(entries: entries, categories: categories, resources: resources)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(backup)
    }

    /// Todas las notas en Markdown, agrupadas por día (más reciente primero).
    /// Sirve para sacar el contenido de la app sin depender del respaldo JSON.
    func exportMarkdown(calendar: Calendar = .current, locale: Locale = .current) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.calendar = calendar
        dayFormatter.locale = locale
        dayFormatter.setLocalizedDateFormatFromTemplate("MMMMd yyyy")

        var out = ["# SafePlace", ""]
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.createdAt) }
        for day in grouped.keys.sorted(by: >) {
            let dayEntries = (grouped[day] ?? []).sorted { $0.createdAt > $1.createdAt }
            out.append("## \(dayFormatter.string(from: day))")
            out.append("")
            for entry in dayEntries {
                let title = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
                out.append("### \(title.isEmpty ? String(localized: "Untitled") : title)")
                out.append("")
                let body = entry.description.trimmingCharacters(in: .whitespacesAndNewlines)
                if !body.isEmpty {
                    out.append(body)
                    out.append("")
                }
                out.append("- \(String(localized: "Category")): \(entry.category)")
                out.append("- \(String(localized: "Mood")): \(entry.moodValue.label)")
                out.append("")
            }
        }
        if !resources.isEmpty {
            out.append("## \(String(localized: "Saved"))")
            out.append("")
            for resource in resources {
                let link = resource.url.isEmpty ? "" : " — \(resource.url)"
                out.append("- \(resource.text)\(link)")
            }
            out.append("")
        }
        return out.joined(separator: "\n")
    }

    @discardableResult
    func importJSON(_ data: Data) -> Bool {
        guard let backup = try? JSONDecoder().decode(Backup.self, from: data) else { return false }
        entries = backup.entries
        categories = backup.categories.isEmpty ? Self.defaultCategories : backup.categories
        resources = backup.resources
        CategoryMigration.apply(entries: &entries, categories: &categories)
        persist()
        return true
    }

    func eraseAll() {
        entries = []
        resources = []
        categories = Self.defaultCategories
        persist()
    }

    // MARK: - Shared notes (from Apple Notes / Share sheet)

    /// Move a shared note into the safe place as a regular entry.
    func importSharedNote(_ note: SharedNote) {
        let title = note.title.isEmpty ? String(localized: "From my notes") : note.title
        addEntry(Entry(
            id: "shared-\(UUID().uuidString)",
            title: title,
            description: note.text,
            category: "Notas",
            mood: "calm",
            color: CardColor.cream.rawValue,
            createdAt: note.createdAt
        ))
        if !categories.contains("Notas") {
            categories.append("Notas")
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
                title: "Caminata por el parque",
                description: "Veinte minutos de caminata lenta antes del trabajo me reinician la cabeza. Sin audífonos, solo los sonidos de alrededor.",
                category: "Hábitos",
                mood: "calm",
                color: CardColor.mint.rawValue,
                createdAt: daysAgo(2)
            ),
            Entry(
                id: "seed-2",
                title: "Llamar a mi hermana",
                description: "Hablar con ella por teléfono siempre hace que el día se sienta más ligero. Nos reímos mucho juntas.",
                category: "Personas",
                mood: "bright",
                color: CardColor.peach.rawValue,
                createdAt: daysAgo(4)
            ),
            Entry(
                id: "seed-3",
                title: "Mi playlist favorita",
                description: "Poner lo-fi mientras ordeno mi cuarto convierte un pendiente en algo tranquilo y agradable.",
                category: "Música",
                mood: "hopeful",
                color: CardColor.lavender.rawValue,
                createdAt: daysAgo(6)
            ),
            Entry(
                id: "seed-4",
                title: "Escribir las cosas",
                description: "Nombrar lo que siento en vez de guardármelo. Unas cuantas frases bastan para sentirme más ligera.",
                category: "Autocuidado",
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