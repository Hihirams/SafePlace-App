import SwiftUI

enum Tab: Int, CaseIterable {
    case home, journal, resources, notes

    var title: String {
        switch self {
        case .home: return "Home"
        case .journal: return "Journal"
        case .resources: return "Resources"
        case .notes: return "Notes"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house"
        case .journal: return "book"
        case .resources: return "link"
        case .notes: return "note.text"
        }
    }
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .journal: return "book.fill"
        case .resources: return "link"
        case .notes: return "note.text"
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

    var body: some View {
        ZStack {
            ContentView(store: store)
            if !hasSeenOnboarding {
                OnboardingView().transition(.opacity).zIndex(1)
            } else if showSplash {
                SplashView().transition(.opacity).zIndex(1)
            }
        }
        .preferredColorScheme(mode.colorScheme)
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
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation(.easeInOut(duration: 0.55)) { showSplash = false }
        }
    }
}

// MARK: - Main tab shell

struct ContentView: View {
    @ObservedObject var store: Store
    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack {
            BackgroundOrbs()

            // Swipeable sections — drag horizontally to move between tabs.
            TabView(selection: $selectedTab) {
                DashboardView(store: store, selectedTab: $selectedTab).tag(Tab.home)
                JournalView(store: store).tag(Tab.journal)
                ResourcesView(store: store).tag(Tab.resources)
                NotesView(store: store).tag(Tab.notes)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .overlay(alignment: .bottom) {
            GlassTabBar(selectedTab: $selectedTab)
        }
        .tint(SafeDesign.ochre)
    }
}

// MARK: - Glass Tab Bar

struct GlassTabBar: View {
    @Binding var selectedTab: Tab

    private var selectedIndex: Int { Tab.allCases.firstIndex(of: selectedTab) ?? 0 }
    private let barHeight: CGFloat = 52
    private let inset: CGFloat = 5
    private let selectorAnim = Animation.interactiveSpring(response: 0.26, dampingFraction: 0.74)

    var body: some View {
        GeometryReader { geo in
            let count = CGFloat(Tab.allCases.count)
            let cell = geo.size.width / count

            ZStack(alignment: .leading) {
                // Moving selection lens — a tinted capsule that rides ON the
                // glass bar (no nested glassEffect, so no backing rectangle).
                Capsule(style: .continuous)
                    .fill(SafeDesign.ochre.opacity(0.22))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                    }
                    .frame(width: cell - 6, height: geo.size.height - 6)
                    .offset(x: cell * CGFloat(selectedIndex) + 3)
                    .animation(selectorAnim, value: selectedIndex)

                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        tabLabel(tab).frame(width: cell)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let i = Int(value.location.x / cell)
                        let clamped = min(max(i, 0), Tab.allCases.count - 1)
                        if clamped != selectedIndex {
                            withAnimation(selectorAnim) { selectedTab = Tab.allCases[clamped] }
                        }
                    }
            )
        }
        .frame(height: barHeight)
        .padding(inset)
        .glassCapsule()
        .padding(.horizontal, SafeDesign.xxl)
        .padding(.bottom, SafeDesign.xs)
    }

    private func tabLabel(_ tab: Tab) -> some View {
        let sel = selectedTab == tab
        return VStack(spacing: 3) {
            Image(systemName: sel ? tab.selectedIcon : tab.icon)
                .font(.system(size: 17, weight: sel ? .semibold : .regular))
                .foregroundStyle(sel ? SafeDesign.ink : SafeDesign.muted)
                .bounceEffect(sel)
            Text(tab.title)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(sel ? SafeDesign.ink : SafeDesign.muted)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

// MARK: - Splash

struct SplashView: View {
    @State private var badgeIn = false
    @State private var textIn = false
    @State private var progress: CGFloat = 0

    var body: some View {
        ZStack {
            BackgroundOrbs()

            VStack(spacing: SafeDesign.xl) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(SafeDesign.teal.opacity(0.12), lineWidth: 3)
                        .frame(width: 138, height: 138)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [SafeDesign.ochre.opacity(0.4), SafeDesign.ochre, SafeDesign.teal, SafeDesign.ochre.opacity(0.4)]),
                                center: .center),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 138, height: 138)
                        .rotationEffect(.degrees(-90))
                        .opacity(textIn ? 1 : 0)

                    Circle()
                        .fill(SafeDesign.teal)
                        .frame(width: 104, height: 104)
                        .overlay { Circle().strokeBorder(SafeDesign.teal.opacity(0.25), lineWidth: 1) }
                        .scaleEffect(badgeIn ? 1 : 0.6)
                        .opacity(badgeIn ? 1 : 0)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(badgeIn ? 0 : -25))
                        .scaleEffect(badgeIn ? 1 : 0.4)
                        .opacity(badgeIn ? 1 : 0)
                }
                .shadow(color: SafeDesign.teal.opacity(0.35), radius: 24, y: 10)

                VStack(spacing: SafeDesign.s) {
                    Text("SafePlace")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
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
                        Capsule().fill(SafeDesign.ochre).frame(width: 120 * progress, height: 4)
                    }
                    .opacity(textIn ? 1 : 0)
                    .padding(.bottom, SafeDesign.xxxl)
            }
        }
        .task {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { badgeIn = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) { textIn = true }
            withAnimation(.easeInOut(duration: 1.4).delay(0.2)) { progress = 1 }
        }
    }
}

#Preview {
    RootView()
}