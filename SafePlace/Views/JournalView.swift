import SwiftUI

struct JournalView: View {
    @ObservedObject var store: Store
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v
    @State private var editingEntry: Entry?
    @State private var showForm = false
    @State private var contentWidth: CGFloat = 0

    private var grouped: [JournalGroup] {
        let sorted = store.entries.sorted { $0.createdAt > $1.createdAt }
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

                if grouped.isEmpty {
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
                } else {
                    ForEach(grouped) { group in
                        VStack(alignment: .leading, spacing: SafeDesign.m) {
                            Text(group.day.formattedDay().uppercased())
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(1.5)
                                .foregroundStyle(SafeDesign.muted)

                            LazyVGrid(columns: SafeLayout.columns(forWidth: contentWidth), spacing: SafeDesign.m) {
                                ForEach(group.entries) { entry in
                                    EntryCardView(entry: entry) {
                                        editingEntry = entry
                                        showForm = true
                                    } onDelete: {
                                        store.deleteEntry(id: entry.id)
                                    }
                                }
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