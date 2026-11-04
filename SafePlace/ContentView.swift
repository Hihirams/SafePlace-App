import SwiftUI

enum Tab: Int, CaseIterable {
    case home, journal, mind, saved

    var title: String {
        switch self {
        case .home: return String(localized: "Home")
        case .journal: return String(localized: "Journal")
        case .mind: return String(localized: "Mind")
        case .saved: return String(localized: "Saved")
        }
    }
    /// Identificador estable para accessibilityIdentifier y UI tests.
    /// Nunca se deriva de ``title``: eso hacía que traducir la app rompiera los tests.
    var slug: String {
        switch self {
        case .home: return "home"
        case .journal: return "journal"
        case .mind: return "mind"
        case .saved: return "saved"
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
        case .system: return String(localized: "System")
        case .light: return String(localized: "Light")
        case .dark: return String(localized: "Dark")
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

// MARK: - Language

/// Idioma de la app. `system` sigue el idioma del iPhone; las otras dos
/// escriben el override de `AppleLanguages`, que iOS aplica al reabrir.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, spanish = "es", english = "en"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return String(localized: "System")
        case .spanish: return "Español"
        case .english: return "English"
        }
    }

    var icon: String {
        switch self {
        case .system: return "iphone"
        case .spanish: return "character.book.closed"
        case .english: return "character.book.closed.fill"
        }
    }

    /// Deja el override como lo pide la opción. `system` lo borra para que
    /// vuelva a mandar el idioma del iPhone.
    func apply() {
        let defaults = UserDefaults.standard
        switch self {
        case .system:
            defaults.removeObject(forKey: "AppleLanguages")
        case .spanish:
            defaults.set(["es"], forKey: "AppleLanguages")
        case .english:
            defaults.set(["en"], forKey: "AppleLanguages")
        }
    }
}

// MARK: - Root (splash → app, theme applied here)

struct RootView: View {
    @AppStorage("themeMode") private var themeRaw = ThemeMode.system.rawValue
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var store = Store()
    @StateObject private var profile = ProfilePhotoModel()
    @State private var showSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// HIG pide minimizar la UI con temporizador: 5 s en cada arranque es un
    /// bloqueo, no una animación de marca. 1.9 s alcanza para que la marca se
    /// lea y el wordmark termine de escribirse.
    private let splashDuration: TimeInterval = 1.9
    private let splashFade: TimeInterval = SafeMotion.splashFade
    private let splashTail: TimeInterval = 0.4

    private var mode: ThemeMode { ThemeMode(rawValue: themeRaw) ?? .system }
    private var moodState: MoodState { MoodState.derive(from: store.entries) }

    var body: some View {
        ZStack {
            ContentView(store: store, covered: showSplash || !hasSeenOnboarding)
            if !hasSeenOnboarding {
                OnboardingView().transition(.opacity).zIndex(1)
            } else if showSplash {
                SplashView(typingDuration: max(1.0, splashDuration - splashFade - splashTail))
                    .transition(.opacity).zIndex(1)
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
                withAnimation(SafeMotion.dismiss) { showSplash = false }
            }
        }
    }

    private func scheduleSplashDismiss() {
        Task {
            let total = reduceMotion ? 0.7 : splashDuration
            let hold = max(0, total - splashFade)
            try? await Task.sleep(nanoseconds: UInt64(hold * 1_000_000_000))
            withAnimation(.easeInOut(duration: splashFade)) { showSplash = false }
        }
    }
}

// MARK: - Main tab shell

struct ContentView: View {
    @ObservedObject var store: Store
    /// El splash o el onboarding tapan la app: la tab bar espera a que se
    /// descubra para aparecer, igual que el contenido.
    var covered: Bool = false
    @State private var selectedTab: Tab = .home
    @State private var showCreate = false
    @State private var showSettings = false
    @State private var showSearch = false
    @State private var showStreak = false
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            BackgroundOrbs()

            TabView(selection: $selectedTab) {
                DashboardView(
                    store: store,
                    selectedTab: $selectedTab,
                    covered: covered,
                    onOpenSettings: { showSettings = true },
                    onOpenSearch: { showSearch = true },
                    onOpenStreak: { withAnimation(SafeMotion.quick) { showStreak = true } }
                )
                .tag(Tab.home)
                JournalView(store: store).tag(Tab.journal)
                MindView(store: store).tag(Tab.mind)
                ResourcesView(store: store).tag(Tab.saved)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .accessibilityHidden(showStreak)
            .allowsHitTesting(!showStreak)
        }
        .overlay(alignment: .bottom) {
            GlassTabBar(selectedTab: $selectedTab) { showCreate = true }
                .opacity(covered ? 0 : 1)
                .offset(y: covered && !reduceMotion ? 8 : 0)
                .animation(SafeMotion.gentle, value: covered)
                .accessibilityHidden(showStreak)
                .allowsHitTesting(!showStreak)
        }
        .overlay {
            if showStreak {
                StreakView(store: store) {
                    withAnimation(SafeMotion.quick) { showStreak = false }
                }
                .transition(.opacity)
                .zIndex(2)
            }
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
    private let selectorAnim = SafeMotion.selector

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
            ZStack {
                Circle()
                    .fill(SafeDesign.ink)
                    .frame(width: 44, height: 44)
                Image(systemName: "plus")
                    .font(SafeDesign.scaled(18, weight: .bold))
                    .foregroundStyle(SafeDesign.canvas)
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
                .font(SafeDesign.scaled(18, weight: sel ? .semibold : .regular))
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
        .accessibilityIdentifier("tab-\(tab.slug)")
        .accessibilityAction {
            Haptics.selection()
            withAnimation(selectorAnim) { selectedTab = tab }
        }
    }
}

// MARK: - Splash

struct SplashView: View {
    var typingDuration: Double = 4.05
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var settled = false
    @State private var glow = false
    @State private var revealed = 0
    private let word = "SafePlace"

    /// El icono de la app es el protagonista: la misma marca que pinta la launch
    /// screen, sobre el papel del canvas, con el wordmark escribiéndose debajo.
    ///
    /// La marca va centrada en la ZStack (no dentro de un VStack) para que su
    /// posición sea exactamente la de la launch screen: así el salto entre las
    /// dos pantallas no se ve.
    var body: some View {
        ZStack {
            SafeDesign.canvas
                .ignoresSafeArea()

            RadialGradient(
                colors: [.clear, theme.tintStrong.opacity(0.35)],
                center: .center,
                startRadius: 40,
                endRadius: 520
            )
            .ignoresSafeArea()
            .opacity(glow ? 1 : 0)

            Image("SplashMark")
                .resizable()
                .scaledToFit()
                .frame(width: SafeDesign.splashMarkSize)
                .scaleEffect(settled ? 1 : 0.94)
                .opacity(settled ? 1 : 0)
                .accessibilityHidden(true)

            Text(String(word.prefix(revealed)))
                .font(SafeDesign.scaled(40, weight: .semibold, design: .serif))
                .tracking(2)
                .foregroundStyle(SafeDesign.ink)
                .offset(y: SafeDesign.splashMarkSize / 2 + 54)
                .accessibilityLabel(word)
        }
        .task {
            // Reduce Motion: marca y wordmark ya colocados, sin tecleo ni fundidos.
            if reduceMotion {
                settled = true
                glow = true
                revealed = word.count
                return
            }
            withAnimation(SafeMotion.gentle) { settled = true }
            withAnimation(SafeMotion.splashTintIn) { glow = true }

            let steps = word.count + 1
            let perStep = typingDuration / Double(steps)
            for index in 0...word.count {
                try? await Task.sleep(nanoseconds: UInt64(perStep * 1_000_000_000))
                guard !Task.isCancelled else { return }
                withAnimation(SafeMotion.splashType) { revealed = index }
            }
        }
    }
}

#Preview {
    RootView()
}
