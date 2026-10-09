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
    description: String = "description"
) -> Entry {
    Entry(id: id, title: title, description: description, category: category,
          mood: mood, color: "mint", createdAt: Date())
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
