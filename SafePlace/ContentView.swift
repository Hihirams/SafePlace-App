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
    @StateObject private var profile = ProfilePhotoModel()
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
        .environmentObject(profile)
        .interfaceStyle(mode)
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-uitesting") {
                hasSeenOnboarding = true
                showSplash = false
            } else if hasSeenOnboarding {
                scheduleSplashDismiss()
            }
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
            CreateView(store: store) { showCreate = false }
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
    @State private var selectionCount = 0

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

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(theme.tint.opacity(0.30))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(.white.opacity(0.28), lineWidth: 0.5)
                    }
                    .frame(width: max(cell - 6, 0), height: barHeight - 6)
                    .offset(x: cell * CGFloat(selectedIndex) + 3)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let i = Int(value.location.x / cell)
                        guard i >= 0, i < slots.count, case .tab(let tab) = slots[i] else { return }
                        if tab != selectedTab {
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
        .dynamicTypeSize(...DynamicTypeSize.large)
        .sensoryFeedback(.selection, trigger: selectedIndex)
        .onChange(of: selectedTab) { _, _ in selectionCount += 1 }
    }

    private var createSlot: some View {
        Button {
            Haptics.tap()
            onCreate()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.tintStrong)
                Text("Create")
                    .font(.system(size: 10, weight: .semibold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .foregroundStyle(SafeDesign.muted)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.94)
        .accessibilityLabel("Create a note")
        .accessibilityIdentifier("tab-create")
    }

    private func tabLabel(_ tab: Tab) -> some View {
        let sel = selectedTab == tab
        return VStack(spacing: 3) {
            Image(systemName: sel ? tab.selectedIcon : tab.icon)
                .font(.system(size: 18, weight: sel ? .semibold : .regular))
                .foregroundStyle(sel ? SafeDesign.ink : SafeDesign.muted)
                .symbolEffect(.bounce, value: sel ? selectionCount : -1)
            Text(tab.title)
                .font(SafeDesign.tabLabel)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .foregroundStyle(sel ? SafeDesign.ink : SafeDesign.muted)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: minTouchTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(sel ? [.isButton, .isSelected] : [.isButton])
        .accessibilityIdentifier("tab-\(tab.title.lowercased())")
        .accessibilityAction {
            Haptics.selection()
            withAnimation(selectorAnim) { selectedTab = tab }
        }
    }
}

// MARK: - Splash

struct SplashView: View {
    @Environment(\.appTheme) private var theme
    @State private var fillIn = false
    @State private var revealed = 0
    private let word = "SafePlace"

    var body: some View {
        ZStack {
            theme.tint
                .ignoresSafeArea()
                .opacity(fillIn ? 1 : 0)

            RadialGradient(
                colors: [.clear, theme.tintStrong.opacity(0.35)],
                center: .center,
                startRadius: 40,
                endRadius: 520
            )
            .ignoresSafeArea()
            .opacity(fillIn ? 1 : 0)

            Text(String(word.prefix(revealed)))
                .font(.system(size: 46, weight: .semibold, design: .serif))
                .tracking(2)
                .foregroundStyle(SafeDesign.onPrimary)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { fillIn = true }
            Task {
                for index in 0...word.count {
                    try? await Task.sleep(nanoseconds: 85_000_000)
                    withAnimation(.easeOut(duration: 0.12)) { revealed = index }
                }
            }
        }
    }
}

#Preview {
    RootView()
}
