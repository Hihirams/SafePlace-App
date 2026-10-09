import SwiftUI

struct SearchView: View {
    @ObservedObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    @State private var query = ""
    @State private var recents: [String] = []
    @State private var editingEntry: Entry?
    @State private var showEdit = false
    @FocusState private var focused: Bool

    private let recentsKey = "recentSearches"

    private struct SearchResult: Identifiable {
        let entry: Entry
        let score: Double
        let snippet: AttributedString
        var id: String { entry.id }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                Divider().overlay(SafeDesign.hairline)
                content
            }
            .background(SafeDesign.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            recents = UserDefaults.standard.stringArray(forKey: recentsKey) ?? []
            focused = true
        }
        .sheet(isPresented: $showEdit) {
            if let entry = editingEntry {
                EntryFormView(
                    initial: entry,
                    categories: store.categories,
                    onSave: { store.updateEntry($0); showEdit = false },
                    onClose: { showEdit = false }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: SafeDesign.s) {
            HStack(spacing: SafeDesign.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundStyle(SafeDesign.muted)
                TextField("Search your notes…", text: $query)
                    .font(SafeDesign.body)
                    .foregroundStyle(SafeDesign.ink)
                    .tint(theme.tintStrong)
                    .focused($focused)
                    .submitLabel(.search)
                    .onSubmit { remember(query) }
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(SafeDesign.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, SafeDesign.m)
            .padding(.vertical, SafeDesign.s)
            .background(SafeDesign.surfaceSoft, in: Capsule())

            Button("Cancel") { dismiss() }
                .font(SafeDesign.caption)
                .foregroundStyle(theme.tintStrong)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, SafeDesign.l)
        .padding(.top, SafeDesign.m)
        .padding(.bottom, SafeDesign.s)
    }

    @ViewBuilder
    private var content: some View {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            suggestions
        } else if results.isEmpty {
            emptyResults(trimmed)
        } else {
            resultsList
        }
    }

    private var suggestions: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SafeDesign.l) {
                if !recents.isEmpty {
                    VStack(alignment: .leading, spacing: SafeDesign.s) {
                        HStack {
                            Text("RECENT")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.5)
                                .foregroundStyle(SafeDesign.muted)
                            Spacer()
                            Button("Clear") {
                                recents = []
                                UserDefaults.standard.removeObject(forKey: recentsKey)
                            }
                            .font(SafeDesign.micro)
                            .foregroundStyle(SafeDesign.muted)
                            .buttonStyle(.plain)
                        }
                        ForEach(recents, id: \.self) { term in
                            Button {
                                Haptics.selection()
                                query = term
                            } label: {
                                HStack(spacing: SafeDesign.s) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 14))
                                        .foregroundStyle(SafeDesign.muted)
                                    Text(term)
                                        .font(SafeDesign.body)
                                        .foregroundStyle(SafeDesign.ink)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: SafeDesign.s) {
                    Text("TRY")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(SafeDesign.muted)
                    FlowLayout(spacing: SafeDesign.xs) {
                        ForEach(["me siento triste", "agradecido", "calma", "música", "amigos"], id: \.self) { term in
                            Button {
                                Haptics.selection()
                                query = term
                            } label: {
                                Text(term)
                                    .font(SafeDesign.caption)
                                    .foregroundStyle(SafeDesign.ink)
                                    .padding(.horizontal, SafeDesign.m)
                                    .padding(.vertical, 8)
                                    .background(SafeDesign.surfaceSoft, in: Capsule())
                                    .overlay { Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1) }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(SafeDesign.l)
        }
    }

    private var resultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: SafeDesign.s) {
                Text("\(results.count) \(results.count == 1 ? "match" : "matches")")
                    .font(SafeDesign.micro)
                    .foregroundStyle(SafeDesign.muted)
                    .padding(.horizontal, SafeDesign.l)

                ForEach(results) { result in
                    Button {
                        Haptics.tap()
                        remember(query)
                        editingEntry = result.entry
                        showEdit = true
                    } label: {
                        resultRow(result)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, SafeDesign.s)
            .padding(.bottom, SafeDesign.xxl)
        }
    }

    private func resultRow(_ result: SearchResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: SafeDesign.xs) {
                Circle().fill(result.entry.cardColor.fill).frame(width: 9, height: 9)
                Text(highlight(result.entry.title, terms: terms))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SafeDesign.ink)
                    .lineLimit(1)
                Spacer()
                Text(result.entry.createdAt.formattedShort())
                    .font(SafeDesign.micro)
                    .foregroundStyle(SafeDesign.muted)
            }
            Text(result.snippet)
                .font(.system(size: 14))
                .foregroundStyle(SafeDesign.inkSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            HStack(spacing: SafeDesign.xs) {
                Label(result.entry.moodValue.label, systemImage: result.entry.moodValue.icon)
                    .font(SafeDesign.micro)
                    .foregroundStyle(SafeDesign.inkSecondary)
                Text(result.entry.category)
                    .font(SafeDesign.micro)
                    .foregroundStyle(SafeDesign.muted)
            }
        }
        .padding(SafeDesign.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SafeDesign.surfaceCard, in: RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous)
                .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
        }
        .padding(.horizontal, SafeDesign.l)
    }

    private func emptyResults(_ text: String) -> some View {
        VStack(spacing: SafeDesign.s) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(SafeDesign.muted)
            Text("No notes match “\(text)”.")
                .font(SafeDesign.headline)
                .foregroundStyle(SafeDesign.ink)
            Text("Try different words, or search by how you felt.")
                .font(SafeDesign.caption)
                .foregroundStyle(SafeDesign.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, SafeDesign.xxxl)
    }

    // MARK: - Ranking

    private var terms: [String] {
        query.lowercased()
            .split(whereSeparator: { !$0.isLetter })
            .map(String.init)
            .filter { $0.count > 2 }
    }

    private var results: [SearchResult] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        let searchTerms = terms
        let emotionMoods = emotions(in: q)

        var out: [SearchResult] = []
        for entry in store.entries {
            let title = entry.title.lowercased()
            let desc = entry.description.lowercased()
            let category = entry.category.lowercased()
            let hay = "\(title) \(desc) \(category)"

            var score: Double = 0
            if title.contains(q) { score += 12 }
            if desc.contains(q) { score += 7 }
            for term in searchTerms {
                if title.contains(term) { score += 4 }
                else if desc.contains(term) { score += 2 }
                else if fuzzy(hay, term) { score += 1 }
            }
            if !emotionMoods.isEmpty && emotionMoods.contains(entry.mood) { score += 5 }

            if score > 0 {
                out.append(SearchResult(entry: entry, score: score, snippet: snippet(for: entry, query: q, terms: searchTerms)))
            }
        }
        return out.sorted { $0.score > $1.score }.prefix(30).map { $0 }
    }

    private func fuzzy(_ hay: String, _ term: String) -> Bool {
        guard term.count >= 4 else { return false }
        return hay.split(whereSeparator: { !$0.isLetter }).contains { word in
            let w = String(word)
            return w.count >= 3 && (w.hasPrefix(term) || term.hasPrefix(w))
        }
    }

    private func emotions(in text: String) -> Set<String> {
        let map: [String: [String]] = [
            "heavy": ["triste", "tristeza", "sad", "mal", "bajón", "bajon", "deprimido", "llorar", "solo", "sola"],
            "bright": ["feliz", "contento", "alegre", "happy", "genial", "increíble", "increible", "bueno"],
            "calm": ["tranquilo", "tranquila", "calma", "relajado", "paz", "calmado"],
            "hopeful": ["esperanza", "ilusión", "ilusion", "motivado", "hope"],
            "mixed": ["ansioso", "ansiosa", "nervioso", "estrés", "estres", "confundido", "raro"]
        ]
        var result: Set<String> = []
        for (mood, words) in map where words.contains(where: { text.contains($0) }) {
            result.insert(mood)
        }
        return result
    }

    // MARK: - Snippet + highlight

    private func snippet(for entry: Entry, query: String, terms: [String]) -> AttributedString {
        let source = entry.description.isEmpty ? entry.title : entry.description
        guard !source.isEmpty else { return AttributedString(entry.title) }

        var anchor = source.startIndex
        var found = false
        if let q = source.range(of: query, options: .caseInsensitive)?.lowerBound {
            anchor = q
            found = true
        }
        for term in terms {
            if let r = source.range(of: term, options: .caseInsensitive)?.lowerBound {
                if !found || r < anchor {
                    anchor = r
                    found = true
                }
            }
        }
        let start = anchor
        let from = source.index(start, offsetBy: -70, limitedBy: source.startIndex) ?? source.startIndex
        let to = source.index(start, offsetBy: 150, limitedBy: source.endIndex) ?? source.endIndex

        var text = String(source[from..<to])
        if from != source.startIndex { text = "…" + text }
        if to != source.endIndex { text += "…" }
        return highlight(text, terms: terms)
    }

    private func highlight(_ text: String, terms: [String]) -> AttributedString {
        var attr = AttributedString(text)
        for term in terms where term.count >= 2 {
            var searchStart = text.startIndex
            while searchStart < text.endIndex,
                  let range = text.range(of: term, options: [.caseInsensitive, .diacriticInsensitive], range: searchStart..<text.endIndex) {
                if let lower = AttributedString.Index(range.lowerBound, within: attr),
                   let upper = AttributedString.Index(range.upperBound, within: attr) {
                    attr[lower..<upper].foregroundColor = theme.tintStrong
                    attr[lower..<upper].inlinePresentationIntent = .stronglyEmphasized
                }
                searchStart = range.upperBound
            }
        }
        return attr
    }

    private func remember(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        var list = recents.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        list.insert(trimmed, at: 0)
        recents = Array(list.prefix(8))
        UserDefaults.standard.set(recents, forKey: recentsKey)
    }
}

#Preview {
    SearchView(store: Store())
}
