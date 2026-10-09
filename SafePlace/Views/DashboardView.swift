import SwiftUI
import UIKit

struct DashboardView: View {
    @ObservedObject var store: Store
    @Binding var selectedTab: Tab
    var onOpenSettings: () -> Void = {}
    var onOpenSearch: () -> Void = {}
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v
    @Environment(\.appTheme) private var theme

    @State private var editingEntry: Entry?
    @State private var showForm = false
    @State private var contentWidth: CGFloat = 0
    @State private var mode: DashboardMode = .overview
    @State private var justCheckedIn = false

    enum DashboardMode: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case insights = "Insights"
        var id: String { rawValue }
    }

    private var todayEntries: [Entry] {
        store.entries.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    private var daysThisWeek: Int { NoteStats.daysThisWeek(store.entries) }

    private var personalBest: Int { NoteStats.personalBest(store.entries) }

    private var onThisDay: [Entry] { NoteStats.onThisDay(store.entries) }

    private var recentEntries: [Entry] {
        Array(store.entries.sorted { $0.createdAt > $1.createdAt }.prefix(6))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SafeDesign.xl) {
                header
                mascotHero
                todayCard
                if !onThisDay.isEmpty { onThisDaySection }
                modePicker

                if mode == .overview {
                    statsPanel
                    recentSection
                } else {
                    InsightsView(store: store)
                }
            }
            .pageColumn(h, v)
            .padding(.top, SafeDesign.m)
            .padding(.bottom, SafeLayout.tabBarClearance(h))
            .readingWidth($contentWidth)
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
        ZStack {
            Text("SafePlace")
                .font(.system(size: 27, weight: .semibold, design: .serif))
                .foregroundStyle(SafeDesign.ink)

            HStack {
                Button {
                    Haptics.tap()
                    onOpenSettings()
                } label: {
                    ZStack {
                        Circle().fill(theme.tint.opacity(0.35)).frame(width: 40, height: 40)
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.tintStrong)
                    }
                    .overlay { Circle().strokeBorder(SafeDesign.hairline, lineWidth: 1) }
                }
                .buttonStyle(.plain)
                .pressable(scale: 0.92)
                .accessibilityLabel("Profile and settings")

                Spacer()

                Button {
                    Haptics.tap()
                    onOpenSearch()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(SafeDesign.ink)
                        .frame(width: 40, height: 40)
                        .background(SafeDesign.surfaceSoft, in: Circle())
                        .overlay { Circle().strokeBorder(SafeDesign.hairline, lineWidth: 1) }
                }
                .buttonStyle(.plain)
                .pressable(scale: 0.92)
                .accessibilityLabel("Search notes")
            }
        }
    }

    // MARK: - Character

    private var mascotHero: some View {
        VStack(spacing: SafeDesign.xs) {
            MascotView(size: 200, animate: true)
                .frame(height: 224)
            Text("I'm here with you.")
                .font(SafeDesign.caption)
                .foregroundStyle(SafeDesign.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, SafeDesign.xs)
    }

    // MARK: - Today

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: SafeDesign.m) {
            AdaptiveStack(spacing: SafeDesign.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(SafeDesign.muted)
                    Text(todayEntries.isEmpty ? "How are you feeling?" : "\(todayEntries.count) \(todayEntries.count == 1 ? "moment" : "moments") saved today")
                        .font(SafeDesign.headline)
                        .foregroundStyle(SafeDesign.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: SafeDesign.xs) {
                    miniStat("\(daysThisWeek)", "this week")
                    miniStat("\(personalBest)", "best run")
                }
            }

            HStack(spacing: SafeDesign.xs) {
                ForEach(Mood.all) { m in
                    Button {
                        checkIn(m)
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle().fill(m.color).frame(width: 44, height: 44)
                                Image(systemName: m.icon)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(SafeDesign.ink)
                            }
                            .overlay { Circle().strokeBorder(SafeDesign.ink.opacity(0.08), lineWidth: 1) }
                            Text(m.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(SafeDesign.inkSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .pressable(scale: 0.9)
                }
            }

            if justCheckedIn {
                Label("Saved. Nice check-in.", systemImage: "checkmark.circle.fill")
                    .font(SafeDesign.caption)
                    .foregroundStyle(theme.tintStrong)
                    .transition(.opacity)
            }
        }
        .padding(SafeDesign.l)
        .background(SafeDesign.surfaceCard, in: RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous)
                .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
        }
    }

    private func miniStat(_ number: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(number)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(SafeDesign.ink)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(SafeDesign.muted)
        }
        .padding(.horizontal, SafeDesign.s)
        .padding(.vertical, 6)
        .background(SafeDesign.surfaceSoft, in: Capsule())
    }

    // MARK: - On this day

    private var onThisDaySection: some View {
        VStack(alignment: .leading, spacing: SafeDesign.s) {
            Label("On this day", systemImage: "sparkles")
                .font(SafeDesign.headline)
                .foregroundStyle(SafeDesign.ink)
            ForEach(onThisDay.prefix(3)) { entry in
                Button {
                    Haptics.tap()
                    editingEntry = entry
                    showForm = true
                } label: {
                    HStack(spacing: SafeDesign.s) {
                        Circle().fill(entry.cardColor.fill).frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.title).font(SafeDesign.body).foregroundStyle(SafeDesign.ink).lineLimit(1)
                            Text(entry.createdAt.formattedMedium()).font(SafeDesign.micro).foregroundStyle(SafeDesign.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(SafeDesign.muted)
                    }
                    .padding(SafeDesign.s)
                    .background(SafeDesign.surfaceSoft, in: RoundedRectangle(cornerRadius: SafeDesign.radiusM, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Mode picker

    private var modePicker: some View {
        HStack(spacing: SafeDesign.xs) {
            ForEach(DashboardMode.allCases) { m in
                SelectionPill(title: m.rawValue, isSelected: mode == m) {
                    Haptics.selection()
                    withAnimation(SafeDesign.spring) { mode = m }
                }
            }
            Spacer()
        }
    }

    // MARK: - Stats

    private var statsPanel: some View {
        let columns = SafeLayout.columns(forWidth: contentWidth)
        return LazyVGrid(columns: columns, spacing: SafeDesign.m) {
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
                            ForEach(categoryCounts) { item in
                                HStack(spacing: SafeDesign.xs) {
                                    Text(item.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(SafeDesign.inkSecondary)
                                        .lineLimit(1)
                                        .frame(width: 84, alignment: .leading)
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(SafeDesign.surfaceStrong)
                                            Capsule().fill(theme.tintStrong)
                                                .frame(width: geo.size.width * fraction(for: item.count))
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
            .gridCellColumns(columns.count)

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
            .gridCellColumns(columns.count)
        }
    }

    private func statCard(number: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: SafeDesign.xs) {
            Text(number)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(SafeDesign.ink)
            Text(label.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(1)
                .foregroundStyle(SafeDesign.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SafeDesign.l)
        .background(SafeDesign.surfaceCard, in: RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous)
                .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
        }
    }

    private func statCardWide<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SafeDesign.l)
            .background(SafeDesign.surfaceCard, in: RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous)
                    .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
            }
    }

    private var categoryCounts: [NoteStats.CategoryCount] {
        NoteStats.categoryCounts(store.entries, categories: store.categories)
    }

    private var moodCounts: [NoteStats.MoodCount] {
        NoteStats.moodCounts(store.entries)
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: SafeDesign.m) {
            HStack {
                Text("Recent")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(SafeDesign.ink)
                Spacer()
                Button {
                    Haptics.tap()
                    selectedTab = .journal
                } label: {
                    HStack(spacing: 4) {
                        Text("See all").font(SafeDesign.caption)
                        Image(systemName: "arrow.right").font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(theme.tintStrong)
                }
                .buttonStyle(.plain)
            }

            if recentEntries.isEmpty {
                VStack(spacing: SafeDesign.s) {
                    Image(systemName: "leaf")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(SafeDesign.muted)
                    Text("Your safe place is ready for its first note.")
                        .font(SafeDesign.body)
                        .foregroundStyle(SafeDesign.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SafeDesign.xxl)
            } else {
                LazyVGrid(columns: SafeLayout.columns(forWidth: contentWidth), spacing: SafeDesign.m) {
                    ForEach(recentEntries) { entry in
                        EntryCardView(entry: entry) {
                            editingEntry = entry
                            showForm = true
                        } onDelete: {
                            deleteEntry(entry)
                        } onDuplicate: {
                            duplicateEntry(entry)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func checkIn(_ mood: Mood) {
        let entry = Entry(
            id: "checkin-\(UUID().uuidString)",
            title: "Feeling \(mood.label.lowercased())",
            description: "",
            category: "Check-in",
            mood: mood.id,
            color: moodCheckInColor(mood).rawValue,
            createdAt: Date()
        )
        store.addEntry(entry)
        Haptics.success()
        withAnimation(SafeDesign.spring) { justCheckedIn = true }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { justCheckedIn = false }
        }
    }

    private func moodCheckInColor(_ mood: Mood) -> CardColor {
        switch mood.id {
        case "bright": return .peach
        case "calm": return .mint
        case "hopeful": return .lavender
        case "mixed": return .ochre
        default: return .pink
        }
    }

    private func saveEntry(_ entry: Entry) {
        if store.entries.contains(where: { $0.id == entry.id }) { store.updateEntry(entry) } else { store.addEntry(entry) }
        Haptics.success()
        showForm = false
        editingEntry = nil
    }

    private func deleteEntry(_ entry: Entry) {
        Haptics.warning()
        store.deleteEntry(id: entry.id)
    }

    private func duplicateEntry(_ entry: Entry) {
        var copy = entry
        copy.id = "e-\(UUID().uuidString)"
        copy.createdAt = Date()
        store.addEntry(copy)
        Haptics.success()
    }

    private func fraction(for count: Int) -> CGFloat {
        let total = max(store.entries.count, 1)
        return CGFloat(count) / CGFloat(total)
    }
}

// MARK: - Mood tag flow

private struct FlowMoodTags: View {
    let moods: [NoteStats.MoodCount]

    var body: some View {
        FlowLayout(spacing: SafeDesign.xs) {
            ForEach(moods) { item in
                HStack(spacing: 5) {
                    Image(systemName: item.mood.icon).font(.system(size: 12, weight: .semibold))
                    Text("\(item.count)").font(.system(size: 12, weight: .semibold))
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
