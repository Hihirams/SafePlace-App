import SwiftUI
import UIKit

struct DashboardView: View {
    @ObservedObject var store: Store
    @Binding var selectedTab: Tab
    /// El splash (o el onboarding) sigue tapando la app: la cascada de entrada
    /// espera a que se descubra, para que se vea de verdad.
    var covered: Bool = false
    var onOpenSettings: () -> Void = {}
    var onOpenSearch: () -> Void = {}
    var onOpenStreak: () -> Void = {}
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var profile: ProfilePhotoModel

    @State private var editingEntry: Entry?
    @State private var showForm = false
    @State private var contentWidth: CGFloat = 0
    @State private var mode: DashboardMode = .overview
    @State private var justCheckedIn = false
    /// 0 = nada visible; 4 = todo. Lo mueve `runEntrance()`.
    @State private var revealStage = 0
    @State private var revealTask: Task<Void, Never>?

    enum DashboardMode: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case insights = "Insights"
        var id: String { rawValue }

        var title: String {
            switch self {
            case .overview: return String(localized: "Overview")
            case .insights: return String(localized: "Insights")
            }
        }
    }

    private var todayEntries: [Entry] {
        store.entries.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    private var currentStreak: Int { NoteStats.currentStreak(store.entries) }

    private var personalBest: Int { NoteStats.personalBest(store.entries) }

    private var onThisDay: [Entry] { NoteStats.onThisDay(store.entries) }

    private var recentEntries: [Entry] {
        Array(store.entries.sorted { $0.createdAt > $1.createdAt }.prefix(6))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, SafeLayout.pageInset(h, v))
                .padding(.top, SafeDesign.s)
                .padding(.bottom, SafeDesign.s)
                .reveal(stage: revealStage, at: 1)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: SafeDesign.xl) {
                    mascotHero
                        .reveal(stage: revealStage, at: 1)
                    todayCard
                        .reveal(stage: revealStage, at: 2)
                    if !onThisDay.isEmpty {
                        onThisDaySection
                            .reveal(stage: revealStage, at: 3)
                    }
                    modePicker
                        .reveal(stage: revealStage, at: 2)

                    if mode == .overview {
                        statsPanel
                            .reveal(stage: revealStage, at: 3)
                        recentSection
                            .reveal(stage: revealStage, at: 4)
                    } else {
                        InsightsView(store: store)
                            .reveal(stage: revealStage, at: 3)
                    }
                }
                .pageColumn(h, v)
                .padding(.top, SafeDesign.m)
                .padding(.bottom, SafeLayout.tabBarClearance(h))
                .readingWidth($contentWidth)
            }
        }
        .onAppear { runEntranceIfNeeded() }
        .onChange(of: covered) { _, isCovered in
            if !isCovered { runEntranceIfNeeded() }
        }
        .fullScreenCover(isPresented: $showForm) {
            CreateView(store: store, editing: editingEntry) {
                showForm = false
                editingEntry = nil
            }
        }
    }

    // MARK: - Entrance

    /// Una sola vez: los bloques entran escalonados 40 ms, subiendo 12 pt.
    /// Con Reduce Motion aparecen todos a la vez, ya colocados.
    private func runEntranceIfNeeded() {
        guard revealStage == 0, !covered else { return }
        guard !reduceMotion else {
            revealStage = 4
            return
        }
        revealTask?.cancel()
        revealTask = Task { @MainActor in
            withAnimation(SafeMotion.gentle) { revealStage = 1 }
            for stage in 2...4 {
                try? await Task.sleep(nanoseconds: UInt64(SafeMotion.entranceStep * 1_000_000_000))
                guard !Task.isCancelled else { return }
                withAnimation(SafeMotion.gentle) { revealStage = stage }
            }
        }
    }

    // MARK: - Header

    /// Cabecera original: el wordmark centrado, con avatar y buscador a los lados.
    /// (Se probó una versión editorial alineada a la izquierda con el glifo y la
    /// fecha; el usuario prefirió esta.)
    private var header: some View {
        ZStack {
            Text("SafePlace")
                .font(SafeDesign.serifTitle)
                .foregroundStyle(SafeDesign.ink)

            HStack {
                avatar
                Spacer()
                searchButton
            }
        }
    }

    private var avatar: some View {
        Button {
            Haptics.tap()
            onOpenSettings()
        } label: {
            ProfileAvatar(size: 42, image: profile.image)
                .shadow(color: theme.tintStrong.opacity(0.25), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.92)
        .accessibilityLabel("Profile and settings")
        .accessibilityIdentifier("home-avatar")
    }

    private var searchButton: some View {
        Button {
            Haptics.tap()
            onOpenSearch()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(SafeDesign.scaled(16, weight: .semibold))
                .foregroundStyle(SafeDesign.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(SafeDesign.surfaceCard))
                .overlay { Circle().strokeBorder(SafeDesign.hairline, lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.92)
        .accessibilityLabel("Search notes")
        .accessibilityIdentifier("home-search")
    }

    // MARK: - Character

    private var mascotHero: some View {
        VStack(spacing: SafeDesign.xs) {
            MascotView(size: 168, animate: true)
                .frame(height: 186)
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
            Text("How are you feeling?")
                .font(SafeDesign.serifHero)
                .foregroundStyle(SafeDesign.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: SafeDesign.xs) {
                ForEach(Mood.all) { m in
                    Button {
                        checkIn(m)
                    } label: {
                        VStack(spacing: 7) {
                            ZStack {
                                Circle().fill(m.color).frame(width: 52, height: 52)
                                Image(systemName: m.icon)
                                    .font(SafeDesign.scaled(20, weight: .semibold))
                                    .foregroundStyle(SafeDesign.ink)
                            }
                            .overlay { Circle().strokeBorder(SafeDesign.ink.opacity(0.08), lineWidth: 1) }
                            Text(m.label)
                                .font(SafeDesign.scaled(10, weight: .semibold))
                                .foregroundStyle(SafeDesign.inkSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
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
            } else {
                Button {
                    Haptics.tap()
                    onOpenStreak()
                } label: {
                    HStack(spacing: SafeDesign.xs) {
                        StreakFlameBadge(active: currentStreak > 0)
                        Text(streakLine)
                            .font(SafeDesign.caption)
                            .foregroundStyle(SafeDesign.muted)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: SafeDesign.xs)
                        Image(systemName: "chevron.right")
                            .font(SafeDesign.scaled(11, weight: .semibold))
                            .foregroundStyle(SafeDesign.muted)
                    }
                    .frame(minHeight: minTouchTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pressable(scale: 0.98)
                .accessibilityLabel(streakLine)
                .accessibilityHint("Opens your streak")
                .accessibilityIdentifier("home-streak")
            }
        }
    }

    /// Contexto de constancia en palabras completas: racha activa y récord.
    /// Antes era "0 esta semana · mejor 2", que además de no traer unidades se
    /// ponía en cero cada vez que arrancaba la semana.
    private var streakLine: String {
        let best = NoteStats.daysLabel(personalBest)
        if currentStreak == 0 {
            return personalBest > 0
                ? String(localized: "No note today · your record is \(best)")
                : String(localized: "A note today starts your streak.")
        }
        return String(localized: "Streak of \(NoteStats.daysLabel(currentStreak)) · record \(best)")
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
                        Image(systemName: "chevron.right").font(SafeDesign.scaled(12, weight: .semibold)).foregroundStyle(SafeDesign.muted)
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
                SelectionPill(title: m.title, isSelected: mode == m) {
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
        return LazyVGrid(columns: columns, spacing: SafeDesign.l) {
            statCard(number: "\(store.entries.count)", label: store.entries.count == 1 ? String(localized: "thing saved") : String(localized: "things saved"))
            statCard(number: "\(store.categories.count)", label: String(localized: "categories"))

            statSection {
                sectionTitle("BY CATEGORY")
                if categoryCounts.isEmpty {
                    emptyNote("Nothing here yet.")
                } else {
                    VStack(spacing: 10) {
                        ForEach(categoryCounts) { item in
                            categoryRow(item)
                        }
                    }
                }
            }
            .gridCellColumns(columns.count)

            statSection {
                sectionTitle("FEELINGS")
                if moodCounts.isEmpty {
                    emptyNote("No moods yet.")
                } else {
                    FlowMoodTags(moods: moodCounts)
                }
            }
            .gridCellColumns(columns.count)
        }
    }

    /// Una fila de la distribución por categoría: etiqueta, barra y conteo.
    /// La columna de etiquetas y la de conteo tienen ancho fijo para que todas
    /// las barras empiecen y terminen en la misma x, sin importar el nombre.
    private func categoryRow(_ item: NoteStats.CategoryCount) -> some View {
        HStack(spacing: SafeDesign.s) {
            Text(item.name)
                .font(SafeDesign.scaled(12, weight: .medium))
                .foregroundStyle(SafeDesign.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(width: 92, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(SafeDesign.surfaceStrong)
                    Capsule().fill(theme.tintStrong)
                        .frame(width: barWidth(in: geo.size.width, for: item.count))
                }
            }
            .frame(height: 8)
            Text("\(item.count)")
                .font(SafeDesign.scaled(12, weight: .medium).monospacedDigit())
                .foregroundStyle(SafeDesign.muted)
                .frame(width: 24, alignment: .trailing)
        }
    }

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(SafeDesign.scaled(11, weight: .medium))
            .tracking(1)
            .foregroundStyle(SafeDesign.muted)
    }

    private func emptyNote(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(SafeDesign.caption)
            .foregroundStyle(SafeDesign.muted)
    }

    private func statCard(number: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(number)
                .font(SafeDesign.scaled(36, weight: .semibold, design: .serif))
                .foregroundStyle(SafeDesign.ink)
            Text(label.uppercased())
                .font(SafeDesign.scaled(10, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(SafeDesign.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, SafeDesign.s)
    }

    /// Sección ancha del panel de stats. Sin hairline: las secciones se separan
    /// por el espaciado del grid, no por una línea.
    private func statSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: SafeDesign.s) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, SafeDesign.xxs)
    }

    private var categoryCounts: [NoteStats.CategoryCount] {
        NoteStats.categoryCounts(store.entries, categories: store.categories)
    }

    private var moodCounts: [NoteStats.MoodCount] {
        NoteStats.moodCounts(store.entries)
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent")
                    .font(SafeDesign.serifTitle)
                    .foregroundStyle(SafeDesign.ink)
                Spacer()
                Button {
                    Haptics.tap()
                    selectedTab = .journal
                } label: {
                    HStack(spacing: 4) {
                        Text("See all").font(SafeDesign.caption)
                        Image(systemName: "arrow.right").font(SafeDesign.scaled(11, weight: .semibold))
                    }
                    .foregroundStyle(theme.tintStrong)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, SafeDesign.s)

            if recentEntries.isEmpty {
                VStack(spacing: SafeDesign.s) {
                    Image(systemName: "leaf")
                        .font(SafeDesign.scaled(34, weight: .light))
                        .foregroundStyle(SafeDesign.muted)
                    Text("Your safe place is ready for its first note.")
                        .font(SafeDesign.body)
                        .foregroundStyle(SafeDesign.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SafeDesign.xxl)
            } else {
                ForEach(recentEntries) { entry in
                    EditorialNoteRow(
                        entry: entry,
                        onEdit: { editingEntry = entry; showForm = true },
                        onDelete: { deleteEntry(entry) },
                        onDuplicate: { duplicateEntry(entry) }
                    )
                    if entry.id != recentEntries.last?.id { Hairline() }
                }
            }
        }
    }

    // MARK: - Actions

    private func checkIn(_ mood: Mood) {
        let entry = Entry(
            id: "checkin-\(UUID().uuidString)",
            title: String(localized: "Feeling \(mood.label.lowercased())"),
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

    /// Ancho de la barra: proporcional al total, con un mínimo legible para que
    /// una categoría con 1 nota no desaparezca, y sin pasarse del carril.
    private func barWidth(in trackWidth: CGFloat, for count: Int) -> CGFloat {
        guard count > 0, trackWidth > 0 else { return 0 }
        let total = max(store.entries.count, 1)
        let proportional = trackWidth * CGFloat(count) / CGFloat(total)
        return min(trackWidth, max(proportional, 6))
    }
}

// MARK: - Streak flame

/// Llama de la racha. Usa el pastel del mood "Con energía" para no salirse de la
/// paleta de los sentimientos. La animación vive en `StreakFlameGlyph`, que
/// comparte con el héroe del modal. Sin racha activa queda en contorno, en gris,
/// y sin animación.
private struct StreakFlameBadge: View {
    let active: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(active ? SafeDesign.moodBright : SafeDesign.surfaceStrong)
                .frame(width: 22, height: 22)
            StreakFlameGlyph(size: 11, active: active, color: SafeDesign.inkOnFill)
        }
        .overlay { Circle().strokeBorder(SafeDesign.ink.opacity(0.06), lineWidth: 1) }
        .shadow(color: active ? SafeDesign.moodBright.opacity(0.55) : .clear, radius: 6, y: 1)
        .accessibilityHidden(true)
    }
}

// MARK: - Mood tag flow
private struct FlowMoodTags: View {
    let moods: [NoteStats.MoodCount]

    var body: some View {
        FlowLayout(spacing: SafeDesign.xs) {
            ForEach(moods) { item in
                HStack(spacing: 5) {
                    Image(systemName: item.mood.icon).font(SafeDesign.scaled(12, weight: .semibold))
                    Text("\(item.count)").font(SafeDesign.scaled(12, weight: .semibold))
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
