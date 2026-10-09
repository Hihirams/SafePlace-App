import SwiftUI

struct JournalView: View {
    @ObservedObject var store: Store
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v
    @State private var editingEntry: Entry?
    @State private var showForm = false
    @State private var contentWidth: CGFloat = 0
    @State private var search = ""
    @State private var moodFilter = "all"
    @State private var collapsed: Set<Date> = []

    private var filtered: [Entry] {
        var list = store.entries
        if moodFilter != "all" { list = list.filter { $0.mood == moodFilter } }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.title.lowercased().contains(q) || $0.description.lowercased().contains(q) || $0.category.lowercased().contains(q)
            }
        }
        return list
    }

    private var grouped: [JournalGroup] {
        let sorted = filtered.sorted { $0.createdAt > $1.createdAt }
        var result: [JournalGroup] = []
        for entry in sorted {
            if let last = result.last, Calendar.current.isDate(last.day, inSameDayAs: entry.createdAt) {
                result[result.count - 1].entries.append(entry)
            } else {
                result.append(JournalGroup(day: Calendar.current.startOfDay(for: entry.createdAt), entries: [entry]))
            }
        }
        return result
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SafeDesign.xl) {
                header
                ClaySearchBar(text: $search)
                moodFilterBar

                if grouped.isEmpty {
                    emptyState
                } else {
                    ForEach(grouped) { group in
                        VStack(alignment: .leading, spacing: SafeDesign.m) {
                            dayHeader(group)

                            if !collapsed.contains(group.day) {
                                LazyVGrid(columns: SafeLayout.columns(forWidth: contentWidth), spacing: SafeDesign.m) {
                                    ForEach(group.entries) { entry in
                                        EntryCardView(entry: entry) {
                                            editingEntry = entry
                                            showForm = true
                                        } onDelete: {
                                            Haptics.warning()
                                            store.deleteEntry(id: entry.id)
                                        } onDuplicate: {
                                            duplicate(entry)
                                        }
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                }
            }
            .pageColumn(h, v)
            .padding(.top, SafeDesign.l)
            .padding(.bottom, SafeLayout.tabBarClearance(h))
            .readingWidth($contentWidth)
        }
        .sheet(isPresented: $showForm) {
            EntryFormView(
                initial: editingEntry,
                categories: store.categories,
                onSave: { entry in
                    store.updateEntry(entry)
                    Haptics.success()
                    showForm = false
                    editingEntry = nil
                },
                onClose: { showForm = false; editingEntry = nil }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SafeDesign.xxs) {
            BadgePill(text: "journal")
            Text("A gentle timeline.")
                .font(SafeDesign.largeTitle)
                .foregroundStyle(SafeDesign.ink)
            Text("Everything you've saved, one step at a time.")
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.inkSecondary)
        }
    }

    private var moodFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SafeDesign.xs) {
                moodChip("all", label: "All", icon: "circle.grid.2x2", color: SafeDesign.surfaceCard)
                ForEach(Mood.all) { m in
                    moodChip(m.id, label: m.label, icon: m.icon, color: m.color)
                }
            }
        }
        .scrollClipDisabled()
    }

    private func moodChip(_ id: String, label: String, icon: String, color: Color) -> some View {
        let sel = moodFilter == id
        return Button {
            Haptics.selection()
            withAnimation(SafeDesign.spring) { moodFilter = id }
        } label: {
            Label(label, systemImage: icon)
                .font(SafeDesign.caption)
                .foregroundStyle(SafeDesign.ink)
                .padding(.horizontal, SafeDesign.l)
                .padding(.vertical, SafeDesign.s)
                .background(sel ? color : SafeDesign.surfaceSoft, in: Capsule())
                .overlay { Capsule().strokeBorder(sel ? SafeDesign.ink.opacity(0.15) : SafeDesign.hairline, lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }

    private func dayHeader(_ group: JournalGroup) -> some View {
        let isCollapsed = collapsed.contains(group.day)
        return Button {
            Haptics.tap()
            withAnimation(SafeDesign.spring) {
                if isCollapsed { collapsed.remove(group.day) } else { collapsed.insert(group.day) }
            }
        } label: {
            HStack(spacing: SafeDesign.xs) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SafeDesign.muted)
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                Text(group.day.formattedDay().uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(SafeDesign.inkSecondary)
                Spacer()
                Text("\(group.entries.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SafeDesign.muted)
                    .padding(.horizontal, SafeDesign.xs)
                    .padding(.vertical, 2)
                    .background(SafeDesign.surfaceSoft, in: Capsule())
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isCollapsed ? "Collapsed" : "Expanded")
    }

    private var emptyState: some View {
        VStack(spacing: SafeDesign.s) {
            Image(systemName: "book")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(SafeDesign.muted)
            Text("Nothing to show yet.")
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SafeDesign.xxxl)
    }

    private func duplicate(_ entry: Entry) {
        var copy = entry
        copy.id = "e-\(UUID().uuidString)"
        copy.createdAt = Date()
        store.addEntry(copy)
        Haptics.success()
    }
}

#Preview {
    ZStack {
        BackgroundOrbs()
        JournalView(store: Store())
    }
}

private struct JournalGroup: Identifiable {
    let day: Date
    var entries: [Entry]
    var id: Date { day }
}
