import SwiftUI

enum Tab: Int, CaseIterable {
    case home, journal, mind, saved

    var title: String {
        switch self {
        case .home: return "Home"
        case .journal: return "Journal"
        case .mind: return "Mind"
        case .saved: return "Saved"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house"
        case .journal: return "book"
        case .mind: return "point.3.connected.trianglepath.dotted"
        case .saved: return "bookmark"
        }
    }
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .journal: return "book.fill"
        case .mind: return "point.3.filled.connected.trianglepath.dotted"
        case .saved: return "bookmark.fill"
        }
    }
}

// MARK: - Theme

enum ThemeMode: String, CaseIterable {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }
    var next: ThemeMode {
        let all = Self.allCases
        let i = all.firstIndex(of: self) ?? 0
        return all[(i + 1) % all.count]
    }
}

// MARK: - Root (splash → app, theme applied here)

struct RootView: View {
    @AppStorage("themeMode") private var themeRaw = ThemeMode.system.rawValue
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var store = Store()
    @State private var showSplash = true

    private var mode: ThemeMode { ThemeMode(rawValue: themeRaw) ?? .system }
    private var moodState: MoodState { MoodState.derive(from: store.entries) }

    var body: some View {
        ZStack {
            ContentView(store: store)
            if !hasSeenOnboarding {
                OnboardingView().transition(.opacity).zIndex(1)
            } else if showSplash {
                SplashView().transition(.opacity).zIndex(1)
            }
        }
        .environment(\.appTheme, AppTheme(moodState: moodState))
        .preferredColorScheme(mode.colorScheme)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .onAppear {
            if hasSeenOnboarding { scheduleSplashDismiss() }
        }
        .onChange(of: hasSeenOnboarding) { _, seen in
            if seen {
                withAnimation(.easeInOut(duration: 0.4)) { showSplash = false }
            }
        }
    }

    private func scheduleSplashDismiss() {
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation(.easeInOut(duration: 0.55)) { showSplash = false }
        }
    }
}

// MARK: - Main tab shell

struct ContentView: View {
    @ObservedObject var store: Store
    @State private var selectedTab: Tab = .home
    @State private var showCreate = false
    @State private var showSettings = false
    @State private var showSearch = false
    @Environment(\.horizontalSizeClass) private var h

    var body: some View {
        ZStack {
            BackgroundOrbs()

            TabView(selection: $selectedTab) {
                DashboardView(
                    store: store,
                    selectedTab: $selectedTab,
                    onOpenSettings: { showSettings = true },
                    onOpenSearch: { showSearch = true }
                )
                .tag(Tab.home)
                JournalView(store: store).tag(Tab.journal)
                MindView(store: store).tag(Tab.mind)
                ResourcesView(store: store).tag(Tab.saved)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .overlay(alignment: .bottom) {
            GlassTabBar(selectedTab: $selectedTab) { showCreate = true }
        }
        .tint(SafeDesign.accent)
        .fullScreenCover(isPresented: $showCreate) {
            EntryFormView(
                initial: nil,
                categories: store.categories,
                onSave: { entry in
                    store.addEntry(entry)
                    Haptics.success()
                    showCreate = false
                },
                onClose: { showCreate = false }
            )
        }
        .fullScreenCover(isPresented: $showSearch) {
            SearchView(store: store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(store: store)
        }
    }
}

// MARK: - Glass Tab Bar (4 tabs + raised center Create)

struct GlassTabBar: View {
    @Binding var selectedTab: Tab
    var onCreate: () -> Void
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.appTheme) private var theme

    private enum Slot: Hashable {
        case tab(Tab)
        case create
    }

    private let slots: [Slot] = [.tab(.home), .tab(.journal), .create, .tab(.mind), .tab(.saved)]
    private let barHeight: CGFloat = 58
    private let inset: CGFloat = 5
    private let selectorAnim = Animation.interactiveSpring(response: 0.26, dampingFraction: 0.74)

    private var selectedIndex: Int {
        slots.firstIndex(of: .tab(selectedTab)) ?? 0
    }

    var body: some View {
        GeometryReader { geo in
            let count = CGFloat(slots.count)
            let cell = geo.size.width / count

            ZStack(alignment: .topLeading) {
                Capsule(style: .continuous)
                    .fill(theme.tint.opacity(0.28))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(.white.opacity(0.28), lineWidth: 0.5)
                    }
                    .frame(width: cell - 6, height: barHeight - 6)
                    .offset(x: cell * CGFloat(selectedIndex) + 3, y: 3)
                    .animation(selectorAnim, value: selectedIndex)

                HStack(spacing: 0) {
                    ForEach(Array(slots.enumerated()), id: \.offset) { _, slot in
                        switch slot {
                        case .tab(let tab):
                            tabLabel(tab).frame(width: cell)
                        case .create:
                            createSlot.frame(width: cell)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let i = Int(value.location.x / cell)
                        guard i >= 0, i < slots.count, case .tab(let tab) = slots[i] else { return }
                        if tab != selectedTab {
                            Haptics.selection()
                            withAnimation(selectorAnim) { selectedTab = tab }
                        }
                    }
            )
        }
        .frame(height: barHeight)
        .padding(inset)
        .glassCapsule()
        .padding(.horizontal, h == .regular ? SafeDesign.xxxl : SafeDesign.l)
        .padding(.bottom, SafeDesign.xs)
        .sensoryFeedback(.selection, trigger: selectedIndex)
    }

    private var createSlot: some View {
        Button {
            Haptics.tap()
            onCreate()
        } label: {
            ZStack {
                Circle()
                    .fill(theme.tintStrong)
                    .frame(width: 54, height: 54)
                    .shadow(color: theme.tintStrong.opacity(0.40), radius: 12, y: 6)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay { Circle().strokeBorder(.white.opacity(0.45), lineWidth: 1) }
            .offset(y: -14)
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.9)
        .accessibilityLabel("Create a note")
    }

    private func tabLabel(_ tab: Tab) -> some View {
        let sel = selectedTab == tab
        return VStack(spacing: 3) {
            Image(systemName: sel ? tab.selectedIcon : tab.icon)
                .font(.system(size: 18, weight: sel ? .semibold : .regular))
                .foregroundStyle(sel ? SafeDesign.ink : SafeDesign.muted)
                .bounceEffect(sel)
            Text(tab.title)
                .font(.system(size: 10, weight: .semibold))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .foregroundStyle(sel ? SafeDesign.ink : SafeDesign.muted)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityLabel(tab.title)
    }
}

// MARK: - Splash

struct SplashView: View {
    @State private var badgeIn = false
    @State private var textIn = false
    @State private var progress: CGFloat = 0
    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            BackgroundOrbs()

            VStack(spacing: SafeDesign.xl) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(theme.tint.opacity(0.18), lineWidth: 3)
                        .frame(width: 138, height: 138)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [theme.tint.opacity(0.4), theme.tint, theme.tintStrong, theme.tint.opacity(0.4)]),
                                center: .center),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 138, height: 138)
                        .rotationEffect(.degrees(-90))
                        .opacity(textIn ? 1 : 0)

                    Circle()
                        .fill(SafeDesign.surfaceCard)
                        .frame(width: 104, height: 104)
                        .overlay { Circle().strokeBorder(theme.tint.opacity(0.35), lineWidth: 1) }

                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(theme.tintStrong)
                        .scaleEffect(badgeIn ? 1 : 0.5)
                        .opacity(badgeIn ? 1 : 0)
                }
                .scaleEffect(badgeIn ? 1 : 0.7)
                .opacity(badgeIn ? 1 : 0)
                .shadow(color: theme.tintStrong.opacity(0.30), radius: 24, y: 10)

                VStack(spacing: SafeDesign.s) {
                    Text("SafePlace")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundStyle(SafeDesign.ink)
                        .tracking(textIn ? 1 : 8)
                        .opacity(textIn ? 1 : 0)
                    Text("A quiet home for the things that helped you.")
                        .font(SafeDesign.caption)
                        .foregroundStyle(SafeDesign.inkSecondary)
                        .opacity(textIn ? 1 : 0)
                }

                Spacer()

                Capsule()
                    .fill(SafeDesign.hairline)
                    .frame(width: 120, height: 4)
                    .overlay(alignment: .leading) {
                        Capsule().fill(theme.tintStrong).frame(width: 120 * progress, height: 4)
                    }
                    .opacity(textIn ? 1 : 0)
                    .padding(.bottom, SafeDesign.xxxl)
            }
        }
        .task {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { badgeIn = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) { textIn = true }
            withAnimation(.easeInOut(duration: 1.3).delay(0.15)) { progress = 1 }
        }
    }
}

#Preview {
    RootView()
}
