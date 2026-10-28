import Testing
import Foundation
import SwiftUI
@testable import SafePlace

// MARK: - Helpers

private func makeEntry(
    _ id: String,
    mood: String = "calm",
    category: String = "Habits",
    title: String = "title",
    description: String = "description",
    createdAt: Date = Date()
) -> Entry {
    Entry(id: id, title: title, description: description, category: category,
          mood: mood, color: "mint", createdAt: createdAt)
}

// MARK: - Categorizer

@Suite("Categorizer")
struct CategorizerTests {
    private let categories = ["Habits", "People", "Places", "Activities", "Music", "Self-care"]

    @Test func suggestsMusic() {
        let result = Categorizer.suggest(
            title: "My favorite playlist",
            description: "lo-fi songs while tidying",
            categories: categories
        )
        #expect(result == "Music")
    }

    @Test func suggestsPeople() {
        let result = Categorizer.suggest(
            title: "Calling my sister",
            description: "we talked for an hour",
            categories: categories
        )
        #expect(result == "People")
    }

    @Test func returnsNilWhenNothingMatches() {
        let result = Categorizer.suggest(
            title: "qwerty",
            description: "zxcvbn",
            categories: categories
        )
        #expect(result == nil)
    }
}

// MARK: - MindGraph

@Suite("MindGraph")
struct MindGraphTests {
    @Test func dominantMoodPicksMostCommon() {
        let entries = [
            makeEntry("1", mood: "heavy"),
            makeEntry("2", mood: "heavy"),
            makeEntry("3", mood: "bright")
        ]
        let dominant = MindGraph.dominantMood(of: entries)
        #expect(dominant?.mood.id == "heavy")
        #expect(abs((dominant?.dominance ?? 0) - (2.0 / 3.0)) < 0.001)
    }

    @Test func dominantMoodIsNilWhenEmpty() {
        #expect(MindGraph.dominantMood(of: []) == nil)
    }

    @Test func averageEnergyStaysInRange() {
        let energy = MindGraph.averageEnergy(of: [
            makeEntry("1", mood: "bright"),
            makeEntry("2", mood: "heavy")
        ])
        #expect(energy >= 0 && energy <= 1)
    }

    @Test func averageEnergyDefaultsWhenEmpty() {
        #expect(MindGraph.averageEnergy(of: []) == 0.5)
    }
}

// MARK: - MoodState

@Suite("MoodState")
struct MoodStateTests {
    @Test func derivesDominantAndNegativeValence() {
        let state = MoodState.derive(from: [
            makeEntry("1", mood: "heavy"),
            makeEntry("2", mood: "heavy"),
            makeEntry("3", mood: "bright")
        ])
        #expect(state.dominant.id == "heavy")
        #expect(state.valence < 0)
    }

    @Test func neutralWhenEmpty() {
        let state = MoodState.derive(from: [])
        #expect(state.dominance == 0)
    }
}

// MARK: - Store

@Suite("Store")
struct StoreTests {
    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("safeplace-test-\(UUID().uuidString).json")
    }

    @Test func startsEmptyWhenNotSeeded() {
        let store = Store(fileURL: tempURL(), seed: false)
        #expect(store.entries.isEmpty)
    }

    @Test func addAndDeleteEntry() {
        let store = Store(fileURL: tempURL(), seed: false)
        store.addEntry(makeEntry("x"))
        #expect(store.entries.count == 1)
        store.deleteEntry(id: "x")
        #expect(store.entries.isEmpty)
    }

    @Test func exportImportRoundTrip() {
        let store = Store(fileURL: tempURL(), seed: false)
        store.addEntry(makeEntry("a", mood: "bright", category: "Music"))
        let data = store.exportJSON()
        #expect(data != nil)
        let restored = Store(fileURL: tempURL(), seed: false)
        #expect(restored.importJSON(data!) == true)
        #expect(restored.entries.first?.id == "a")
    }

    @Test func eraseAllClearsEverything() {
        let store = Store(fileURL: tempURL(), seed: false)
        store.addEntry(makeEntry("a"))
        store.eraseAll()
        #expect(store.entries.isEmpty)
        #expect(store.categories == Store.defaultCategories)
    }
}

// MARK: - SearchRanker

@Suite("SearchRanker")
struct SearchRankerTests {
    @Test func findsExactTitleMatch() {
        let entries = [makeEntry("1", title: "Morning walk", description: "by the park")]
        let results = SearchRanker.results(for: "walk", in: entries, highlight: .black)
        #expect(results.first?.entry.id == "1")
    }

    @Test func emptyQueryReturnsNothing() {
        let results = SearchRanker.results(for: "   ", in: [makeEntry("1")], highlight: .black)
        #expect(results.isEmpty)
    }

    @Test func emotionQueryBoostsMatchingMood() {
        let entries = [
            makeEntry("1", mood: "heavy", title: "a", description: "b"),
            makeEntry("2", mood: "bright", title: "c", description: "d")
        ]
        let results = SearchRanker.results(for: "me siento triste", in: entries, highlight: .black)
        #expect(results.first?.entry.id == "1")
    }

    @Test func fuzzyMatchesPrefix() {
        #expect(SearchRanker.fuzzy("tristeza profunda", "triste") == true)
        #expect(SearchRanker.fuzzy("hola mundo", "zzzz") == false)
    }
}

// MARK: - NoteStats

@Suite("NoteStats")
struct NoteStatsTests {
    private func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }

    @Test func personalBestCountsConsecutiveDays() {
        let entries = [makeEntry("1"), makeEntry("2"), makeEntry("3")].enumerated().map { index, entry -> Entry in
            var copy = entry
            copy.createdAt = daysAgo(index)
            return copy
        }
        #expect(NoteStats.personalBest(entries) == 3)
    }

    @Test func personalBestZeroWhenEmpty() {
        #expect(NoteStats.personalBest([]) == 0)
    }

    @Test func categoryCountsAreSortedDescending() {
        let entries = [
            makeEntry("1", category: "Music"),
            makeEntry("2", category: "Music"),
            makeEntry("3", category: "Habits")
        ]
        let counts = NoteStats.categoryCounts(entries, categories: [])
        #expect(counts.first?.name == "Music")
        #expect(counts.first?.count == 2)
    }

    @Test func last14DaysAlwaysHas14Buckets() {
        #expect(NoteStats.last14Days([]).count == 14)
    }

    @Test func topKeywordsFilterStopwords() {
        let entries = [makeEntry("1", title: "playlist playlist", description: "the and songs")]
        let keywords = NoteStats.topKeywords(entries)
        #expect(keywords.contains("playlist"))
        #expect(!keywords.contains("the"))
    }
}

// MARK: - Date helpers

@Suite("Date helpers")
struct DateHelperTests {
    @Test func formattingIsNonEmpty() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(!date.formattedShort().isEmpty)
        #expect(!date.formattedMedium().isEmpty)
    }
}

// MARK: - Determinismo (regresiones)

/// Dictionary ordering in Swift is seeded per process, so any `.max(by:)` or `.sorted`
/// that only compares counts used to return a different winner on every launch — the
/// app tint changed color by itself. These tests pin the tie-breaks.
@Suite("Determinismo")
struct DeterminismTests {
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func dominantMoodTieGoesToMostRecentNote() {
        let entries = [
            makeEntry("1", mood: "heavy", createdAt: base),
            makeEntry("2", mood: "bright", createdAt: base.addingTimeInterval(60))
        ]
        #expect(MindGraph.dominantMood(of: entries)?.mood.id == "bright")
    }

    @Test func dominantMoodTieWithSameDateUsesMoodOrder() {
        let entries = [
            makeEntry("1", mood: "heavy", createdAt: base),
            makeEntry("2", mood: "bright", createdAt: base)
        ]
        #expect(MindGraph.dominantMood(of: entries)?.mood.id == "bright")
    }

    @Test func dominantMoodStillCountsFirst() {
        let entries = [
            makeEntry("1", mood: "heavy", createdAt: base),
            makeEntry("2", mood: "heavy", createdAt: base),
            makeEntry("3", mood: "bright", createdAt: base.addingTimeInterval(600))
        ]
        #expect(MindGraph.dominantMood(of: entries)?.mood.id == "heavy")
    }

    @Test func moodStateAgreesWithDominantMood() {
        let entries = [
            makeEntry("1", mood: "mixed", createdAt: base),
            makeEntry("2", mood: "calm", createdAt: base.addingTimeInterval(30))
        ]
        let state = MoodState.derive(from: entries)
        #expect(state.dominant.id == MindGraph.dominantMood(of: entries)?.mood.id)
        #expect(state.dominant.id == "calm")
    }

    @Test func categoryCountsTieBreakAlphabetically() {
        let entries = [
            makeEntry("1", category: "Music"),
            makeEntry("2", category: "Habits")
        ]
        let counts = NoteStats.categoryCounts(entries, categories: [])
        #expect(counts.map(\.name) == ["Habits", "Music"])
    }

    @Test func moodCountsTieBreakInMoodOrder() {
        let entries = [
            makeEntry("1", mood: "heavy"),
            makeEntry("2", mood: "hopeful")
        ]
        let counts = NoteStats.moodCounts(entries)
        #expect(counts.map(\.mood.id) == ["hopeful", "heavy"])
    }

    @Test func topKeywordsTieBreakAlphabetically() {
        let entries = [makeEntry("1", title: "zebra apple", description: "mango")]
        #expect(NoteStats.topKeywords(entries) == ["apple", "mango", "zebra"])
    }

    @Test func searchResultsTieBreakNewestFirst() {
        let entries = [
            makeEntry("old", title: "playlist", createdAt: base),
            makeEntry("new", title: "playlist", createdAt: base.addingTimeInterval(3_600))
        ]
        let results = SearchRanker.results(for: "playlist", in: entries, highlight: .black)
        #expect(results.map(\.entry.id) == ["new", "old"])
    }
}

// MARK: - Rachas (regresiones)

@Suite("Personal best")
struct PersonalBestTests {
    private func day(_ offset: Int) -> Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return cal.date(byAdding: .day, value: offset, to: today) ?? today
    }

    @Test func ignoresGapsAndDuplicateDays() {
        let entries = [
            makeEntry("1", createdAt: day(-10)),
            makeEntry("2", createdAt: day(-9)),
            makeEntry("3", createdAt: day(-9)),
            makeEntry("4", createdAt: day(-2))
        ]
        #expect(NoteStats.personalBest(entries) == 2)
    }

    @Test func spansMonthBoundary() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let entries = [
            makeEntry("1", createdAt: today),
            makeEntry("2", createdAt: cal.date(byAdding: .day, value: -1, to: today) ?? today),
            makeEntry("3", createdAt: cal.date(byAdding: .day, value: -2, to: today) ?? today)
        ]
        #expect(NoteStats.personalBest(entries) == 3)
    }

    @Test func singleDayIsOne() {
        #expect(NoteStats.personalBest([makeEntry("1", createdAt: Date())]) == 1)
    }
}

// MARK: - Localización / migración a español

@Suite("Categorías en español")
struct LocalizationTests {
    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("safeplace-i18n-\(UUID().uuidString).json")
    }

    @Test func defaultCategoriesAreSpanish() {
        let store = Store(fileURL: tempURL(), seed: false)
        #expect(store.categories == Store.defaultCategories)
        #expect(store.categories.contains("Hábitos"))
        #expect(!store.categories.contains("Habits"))
    }

    @Test func migratesLegacyEnglishCategoriesFromDisk() throws {
        let url = tempURL()
        let backup = Store.Backup(
            entries: [makeEntry("1", category: "Habits"), makeEntry("2", category: "Music")],
            categories: ["Habits", "Music", "Notes"],
            resources: []
        )
        try JSONEncoder().encode(backup).write(to: url)

        let store = Store(fileURL: url, seed: false)
        #expect(store.entries.map(\.category) == ["Hábitos", "Música"])
        #expect(store.categories == ["Hábitos", "Música", "Notas"])

        // La migración se guarda: al recargar ya está en español.
        let reloaded = Store(fileURL: url, seed: false)
        #expect(reloaded.entries.map(\.category) == ["Hábitos", "Música"])
    }

    @Test func migrationIsIdempotent() throws {
        let url = tempURL()
        let backup = Store.Backup(entries: [makeEntry("1", category: "Hábitos")],
                                  categories: ["Hábitos"], resources: [])
        try JSONEncoder().encode(backup).write(to: url)
        let store = Store(fileURL: url, seed: false)
        #expect(store.entries.first?.category == "Hábitos")
        #expect(store.categories == ["Hábitos"])
    }

    @Test func keepsUserCategoriesUntouched() throws {
        let url = tempURL()
        let backup = Store.Backup(entries: [makeEntry("1", category: "Mi categoría")],
                                  categories: ["Mi categoría"], resources: [])
        try JSONEncoder().encode(backup).write(to: url)
        let store = Store(fileURL: url, seed: false)
        #expect(store.entries.first?.category == "Mi categoría")
        #expect(store.categories == ["Mi categoría"])
    }

    @Test func categorizerUnderstandsSpanish() {
        let categories = Store.defaultCategories
        #expect(Categorizer.suggest(title: "Mi playlist favorita",
                                    description: "escuché canciones nuevas",
                                    categories: categories) == "Música")
        #expect(Categorizer.suggest(title: "Rutina de la mañana",
                                    description: "caminar y meditar",
                                    categories: categories) == "Hábitos")
    }

    @Test func moodLabelsAreLocalized() {
        // En un build en inglés el catálogo devuelve la clave; en español, la traducción.
        #expect(!Mood.bright.label.isEmpty)
        #expect(Mood.all.map(\.label).allSatisfy { !$0.isEmpty })
    }
}
// MARK: - Persistencia (regresión: errores silenciosos)

@Suite("Guardado en disco")
struct PersistenceErrorTests {
    @Test func reportsFailureInsteadOfSwallowingIt() {
        // El directorio padre no existe: la escritura falla de verdad.
        let bad = FileManager.default.temporaryDirectory
            .appendingPathComponent("safeplace-missing-\(UUID().uuidString)")
            .appendingPathComponent("data.json")
        let store = Store(fileURL: bad, seed: false)
        #expect(store.lastSaveError != nil)
    }

    @Test func clearsErrorAfterASuccessfulSave() throws {
        let good = FileManager.default.temporaryDirectory
            .appendingPathComponent("safeplace-ok-\(UUID().uuidString).json")
        let store = Store(fileURL: good, seed: false)
        #expect(store.lastSaveError == nil)
        store.addEntry(makeEntry("1"))
        #expect(store.lastSaveError == nil)
        #expect(FileManager.default.fileExists(atPath: good.path))
    }
}
