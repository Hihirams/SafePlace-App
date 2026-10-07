import SwiftUI

enum Tab: Int, CaseIterable {
    case home, journal, mind, resources, notes

    var title: String {
        switch self {
        case .home: return "Home"
        case .journal: return "Journal"
        case .mind: return "Mind"
        case .resources: return "Saved"
        case .notes: return "Notes"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house"
        case .journal: return "book"
        case .mind: return "point.3.connected.trianglepath.dotted"
        case .resources: return "bookmark"
        case .notes: return "note.text"
        }
    }
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .journal: return "book.fill"
        case .mind: return "point.3.filled.connected.trianglepath.dotted"
        case .resources: return "bookmark.fill"
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
    @State private var showQuickCapture = false
    @State private var showSettings = false
    @Environment(\.horizontalSizeClass) private var h

    var body: some View {
        ZStack {
            BackgroundOrbs()

            TabView(selection: $selectedTab) {
                DashboardView(store: store, selectedTab: $selectedTab, onOpenSettings: { showSettings = true })
                    .tag(Tab.home)
                JournalView(store: store).tag(Tab.journal)
                MindView(store: store).tag(Tab.mind)
                ResourcesView(store: store).tag(Tab.resources)
                NotesView(store: store).tag(Tab.notes)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .overlay(alignment: .bottomTrailing) {
            if selectedTab != .mind {
                QuickCaptureButton { showQuickCapture = true }
                    .padding(.trailing, h == .regular ? SafeDesign.xxxl + 8 : SafeDesign.l)
                    .padding(.bottom, SafeLayout.tabBarClearance(h) - 22)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottom) {
            GlassTabBar(selectedTab: $selectedTab)
        }
        .tint(SafeDesign.accent)
        .sheet(isPresented: $showQuickCapture) {
            QuickCaptureView(store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(store: store)
        }
    }
}

// MARK: - Quick capture button

struct QuickCaptureButton: View {
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(SafeDesign.onPrimary)
                .frame(width: 54, height: 54)
                .background(
                    Circle()
                        .fill(SafeDesign.accent)
                        .shadow(color: SafeDesign.accentDeep.opacity(0.45), radius: 12, y: 6)
                )
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.35), lineWidth: 0.75)
                }
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.9)
        .accessibilityLabel("Quick capture")
    }
}

// MARK: - Glass Tab Bar

struct GlassTabBar: View {
    @Binding var selectedTab: Tab
    @Environment(\.horizontalSizeClass) private var h

    private var selectedIndex: Int { Tab.allCases.firstIndex(of: selectedTab) ?? 0 }
    private let barHeight: CGFloat = 56
    private let inset: CGFloat = 5
    private let selectorAnim = Animation.interactiveSpring(response: 0.26, dampingFraction: 0.74)

    var body: some View {
        GeometryReader { geo in
            let count = CGFloat(Tab.allCases.count)
            let cell = geo.size.width / count

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(SafeDesign.accent.opacity(0.30))
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(.white.opacity(0.28), lineWidth: 0.5)
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
                            Haptics.selection()
                            withAnimation(selectorAnim) { selectedTab = Tab.allCases[clamped] }
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

    var body: some View {
        ZStack {
            BackgroundOrbs()

            VStack(spacing: SafeDesign.xl) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(SafeDesign.accent.opacity(0.18), lineWidth: 3)
                        .frame(width: 138, height: 138)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [SafeDesign.accent.opacity(0.4), SafeDesign.accent, SafeDesign.accentDeep, SafeDesign.accent.opacity(0.4)]),
                                center: .center),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 138, height: 138)
                        .rotationEffect(.degrees(-90))
                        .opacity(textIn ? 1 : 0)

                    Circle()
                        .fill(SafeDesign.surfaceCard)
                        .frame(width: 104, height: 104)
                        .overlay { Circle().strokeBorder(SafeDesign.accent.opacity(0.35), lineWidth: 1) }

                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(SafeDesign.accentDeep)
                        .scaleEffect(badgeIn ? 1 : 0.5)
                        .opacity(badgeIn ? 1 : 0)
                }
                .scaleEffect(badgeIn ? 1 : 0.7)
                .opacity(badgeIn ? 1 : 0)
                .shadow(color: SafeDesign.accentDeep.opacity(0.30), radius: 24, y: 10)

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
                        Capsule().fill(SafeDesign.accent).frame(width: 120 * progress, height: 4)
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
