import SwiftUI
import UIKit

struct DashboardView: View {
    @ObservedObject var store: Store
    @Binding var selectedTab: Tab
    @AppStorage("themeMode") private var themeRaw = ThemeMode.system.rawValue

    @State private var search = ""
    @State private var activeCategory = "all"
    @State private var sortOrder: SortOrder = .newest
    @State private var editingEntry: Entry?
    @State private var showForm = false

    enum SortOrder: String, CaseIterable, Identifiable {
        case newest = "Newest first"
        case oldest = "Oldest first"
        case alphabetical = "A → Z"
        var id: String { rawValue }
    }

    private var theme: ThemeMode { ThemeMode(rawValue: themeRaw) ?? .system }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        case 18..<22: return "Good evening"
        default: return "Good night"
        }
    }

    private var filteredEntries: [Entry] {
        var list = store.entries
        if activeCategory != "all" {
            list = list.filter { $0.category == activeCategory }
        }
        if !search.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = search.trimmingCharacters(in: .whitespaces).lowercased()
            list = list.filter {
                $0.title.lowercased().contains(q)
                    || $0.description.lowercased().contains(q)
                    || $0.category.lowercased().contains(q)
            }
        }
        switch sortOrder {
        case .newest: list.sort { $0.createdAt > $1.createdAt }
        case .oldest: list.sort { $0.createdAt < $1.createdAt }
        case .alphabetical: list.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        return list
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SafeDesign.xxl) {
                header
                hero
                statsPanel
                notesSection
            }
            .padding(.horizontal, SafeDesign.xl)
            .padding(.top, SafeDesign.l)
            .padding(.bottom, 110)
        }
        .sheet(isPresented: $showForm) {
            EntryFormView(
                initial: editingEntry,
                categories: store.categories,
                onSave: saveEntry,
                onClose: { showForm = false; editingEntry = nil }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: SafeDesign.m) {
            ZStack {
                Circle()
                    .fill(SafeDesign.teal)
                    .frame(width: 42, height: 42)
                Text("SP")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle().strokeBorder(SafeDesign.teal.opacity(0.2), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(SafeDesign.caption)
                    .foregroundStyle(SafeDesign.inkSecondary)
                Text("SafePlace")
                    .font(SafeDesign.title)
                    .foregroundStyle(SafeDesign.ink)
            }

            Spacer()

            GlassIconButton(icon: theme.icon) {
                withAnimation(SafeDesign.spring) { themeRaw = theme.next.rawValue }
            }

            Button {
                editingEntry = nil
                showForm = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(SafeDesign.onPrimary)
                    .frame(width: 44, height: 44)
                    .background(Capsule().fill(SafeDesign.primary))
            }
            .buttonStyle(.plain)
            .pressable()
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: SafeDesign.m) {
            BadgePill(text: "your safe place")

            Text("A quiet home for the things that helped you.")
                .font(SafeDesign.heroFont)
                .foregroundStyle(SafeDesign.ink)
                .tracking(-1)
                .fixedSize(horizontal: false, vertical: true)

            Text("Collect the small wins, habits, people and places that gently carried you forward. Come back whenever you need to remember.")
                .font(.system(size: 16))
                .foregroundStyle(SafeDesign.inkSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: SafeDesign.s) {
                Button {
                    editingEntry = nil
                    showForm = true
                } label: {
                    HStack(spacing: SafeDesign.xs) {
                        Image(systemName: "plus")
                        Text("Add what helped")
                    }
                    .font(SafeDesign.headline)
                    .foregroundStyle(SafeDesign.onPrimary)
                    .padding(.horizontal, SafeDesign.xl)
                    .frame(height: 48)
                    .background(Capsule().fill(SafeDesign.primary))
                }
                .buttonStyle(.plain)
                .pressable()

                Button {
                    editingEntry = nil
                    showForm = true
                } label: {
                    Text("Start a note")
                        .font(SafeDesign.headline)
                        .foregroundStyle(SafeDesign.ink)
                        .padding(.horizontal, SafeDesign.xl)
                        .frame(height: 48)
                        .background(Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .pressable()
            }

            Text(store.entries.count == 0
                 ? "No notes yet — this place is ready for you."
                 : "\(store.entries.count) \(store.entries.count == 1 ? "thing" : "things") saved in your safe place.")
                .font(SafeDesign.caption)
                .foregroundStyle(SafeDesign.muted)

            HeroArt()
                .frame(height: 220)
                .padding(.top, SafeDesign.xs)
        }
    }

    // MARK: - Stats

    private var statsPanel: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: SafeDesign.m), GridItem(.flexible())], spacing: SafeDesign.m) {
            statCard(number: "\(store.entries.count)", label: store.entries.count == 1 ? "thing saved" : "things saved")
            statCard(number: "\(store.categories.count)", label: "categories")
            statCardWide {
                VStack(alignment: .leading, spacing: SafeDesign.s) {
                    Text("BY CATEGORY")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(SafeDesign.muted)
                    if categoryCounts.isEmpty {
                        Text("Nothing here yet.")
                            .font(SafeDesign.caption)
                            .foregroundStyle(SafeDesign.muted)
                    } else {
                        VStack(spacing: SafeDesign.s) {
                            ForEach(categoryCounts, id: \.name) { item in
                                HStack(spacing: SafeDesign.xs) {
                                    Text(item.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(SafeDesign.inkSecondary)
                                        .lineLimit(1)
                                        .frame(width: 84, alignment: .leading)
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(SafeDesign.surfaceCard)
                                            Capsule()
                                                .fill(SafeDesign.primary)
                                                .frame(width: geo.size.width * item.fraction)
                                        }
                                    }
                                    .frame(height: 8)
                                    Text("\(item.count)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(SafeDesign.muted)
                                        .frame(width: 22, alignment: .trailing)
                                }
                            }
                        }
                    }
                }
            }
            statCardWide {
                VStack(alignment: .leading, spacing: SafeDesign.s) {
                    Text("FEELINGS")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(SafeDesign.muted)
                    if moodCounts.isEmpty {
                        Text("No moods yet.")
                            .font(SafeDesign.caption)
                            .foregroundStyle(SafeDesign.muted)
                    } else {
                        FlowMoodTags(moods: moodCounts)
                    }
                }
            }
        }
    }

    private func statCard(number: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: SafeDesign.xs) {
            Text(number)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(SafeDesign.ink)
            Text(label.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(1)
                .foregroundStyle(SafeDesign.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SafeDesign.l)
        .background(SafeDesign.surfaceSoft, in: RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous))
    }

    private func statCardWide<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SafeDesign.l)
            .background(SafeDesign.surfaceSoft, in: RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous))
    }

    private var categoryCounts: [CategoryCount] {
        let total = store.entries.count
        let counts = store.categories
            .map { name in (name, store.entries.filter { $0.category == name }.count) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
        guard total > 0 else { return [] }
        return counts.map { CategoryCount(name: $0.0, count: $0.1, fraction: CGFloat($0.1) / CGFloat(total)) }
    }

    private var moodCounts: [MoodCount] {
        Mood.all
            .map { m in MoodCount(mood: m, count: store.entries.filter { $0.mood == m.id }.count) }
            .filter { $0.count > 0 }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: SafeDesign.l) {
            HStack {
                Text("Your notes")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(SafeDesign.ink)
                Spacer()
            }

            ClaySearchBar(text: $search)

            HStack {
                Menu {
                    ForEach(SortOrder.allCases) { order in
                        Button(order.rawValue) { sortOrder = order }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                        Text(sortOrder.rawValue)
                            .font(SafeDesign.caption)
                    }
                    .foregroundStyle(SafeDesign.inkSecondary)
                    .padding(.horizontal, SafeDesign.l)
                    .padding(.vertical, SafeDesign.s)
                    .background(SafeDesign.surfaceSoft, in: Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    editingEntry = nil
                    showForm = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Add")
                            .font(SafeDesign.caption)
                    }
                    .foregroundStyle(SafeDesign.onPrimary)
                    .padding(.horizontal, SafeDesign.l)
                    .padding(.vertical, SafeDesign.s)
                    .background(Capsule().fill(SafeDesign.primary))
                }
                .buttonStyle(.plain)
                .pressable(scale: 0.95)
            }

            categoryTabs

            if filteredEntries.isEmpty {
                VStack(spacing: SafeDesign.s) {
                    Image(systemName: "leaf")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(SafeDesign.muted)
                    Text(search.isEmpty && activeCategory == "all"
                         ? "Your safe place is ready for its first note."
                         : "No notes match right now.")
                        .font(SafeDesign.body)
                        .foregroundStyle(SafeDesign.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SafeDesign.xxxl)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: SafeDesign.m), GridItem(.flexible())], spacing: SafeDesign.m) {
                    ForEach(filteredEntries) { entry in
                        EntryCardView(entry: entry) {
                            editingEntry = entry
                            showForm = true
                        } onDelete: {
                            deleteEntry(entry)
                        }
                        .transition(.opacity)
                    }
                }
                .animation(SafeDesign.spring, value: filteredEntries.map(\.id))
            }
        }
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SafeDesign.xs) {
                categoryTab("All", isActive: activeCategory == "all") { activeCategory = "all" }
                ForEach(store.categories, id: \.self) { category in
                    categoryTab(category, isActive: activeCategory == category) {
                        activeCategory = category
                    }
                }
                categoryTab("+ New", isActive: false) { addCategory() }
            }
        }
    }

    private func categoryTab(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(SafeDesign.caption)
                .foregroundStyle(isActive ? SafeDesign.ink : SafeDesign.muted)
                .padding(.horizontal, SafeDesign.l)
                .padding(.vertical, SafeDesign.s)
                .background {
                    if isActive {
                        Capsule().fill(SafeDesign.surfaceCard)
                    } else {
                        Capsule().fill(.clear)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func saveEntry(_ entry: Entry) {
        if store.entries.contains(where: { $0.id == entry.id }) {
            store.updateEntry(entry)
        } else {
            store.addEntry(entry)
        }
        showForm = false
        editingEntry = nil
    }

    private func deleteEntry(_ entry: Entry) {
        store.deleteEntry(id: entry.id)
    }

    private func addCategory() {
        let alert = UIAlertController(title: "New category", message: "Name of the new category:", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "e.g. Rest" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            if let name = alert.textFields?.first?.text {
                store.addCategory(name)
            }
        })
        rootViewController()?.present(alert, animated: true)
    }

    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
    }
}

// MARK: - Hero art (floating mood blobs)

private struct HeroArt: View {
    var body: some View {
        ZStack {
            blob(color: SafeDesign.pink, icon: "sun.max.fill", foreground: .white, size: 96, offset: CGPoint(x: -110, y: -78), rotation: -3, delay: 0)
            blob(color: SafeDesign.teal, icon: "leaf.fill", foreground: .white, size: 96, offset: CGPoint(x: 120, y: 80), rotation: 3, delay: 1.5)
            blob(color: SafeDesign.lavender, icon: "flower2.fill", foreground: SafeDesign.ink, size: 72, offset: CGPoint(x: -128, y: 74), rotation: 2, delay: 3)
            blob(color: SafeDesign.peach, icon: "drop.fill", foreground: SafeDesign.ink, size: 72, offset: CGPoint(x: 116, y: -82), rotation: -2, delay: 4.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func blob(
        color: Color,
        icon: String,
        foreground: Color,
        size: CGFloat,
        offset: CGPoint,
        rotation: Double,
        delay: Double
    ) -> some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .light))
                    .foregroundStyle(foreground)
            }
            .shadow(color: .black.opacity(0.18), radius: 20, y: 10)
            .offset(x: offset.x, y: offset.y)
            .rotationEffect(.degrees(rotation))
            .modifier(FloatAnimation(delay: delay))
    }
}

private struct FloatAnimation: ViewModifier {
    let delay: Double
    @State private var floating = false

    func body(content: Content) -> some View {
        content
            .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true).delay(delay), value: floating)
            .onAppear { floating = true }
            .offset(y: floating ? -12 : 12)
    }
}

// MARK: - Mood tag flow

private struct FlowMoodTags: View {
    let moods: [MoodCount]

    var body: some View {
        HStack(spacing: SafeDesign.xs) {
            ForEach(moods) { item in
                HStack(spacing: 5) {
                    Image(systemName: item.mood.icon)
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(item.count)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(SafeDesign.ink)
                .padding(.horizontal, SafeDesign.s)
                .padding(.vertical, 6)
                .background(item.mood.color, in: Capsule())
            }
        }
    }
}

#Preview {
    ZStack {
        BackgroundOrbs()
        DashboardView(store: Store(), selectedTab: .constant(.home))
    }
}

// MARK: - Stat data

private struct CategoryCount: Identifiable {
    let name: String
    let count: Int
    let fraction: CGFloat
    var id: String { name }
}

private struct MoodCount: Identifiable {
    let mood: Mood
    let count: Int
    var id: String { mood.id }
}