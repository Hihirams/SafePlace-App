import SwiftUI
import UIKit

// MARK: - Haptics

enum Haptics {
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }
    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func soft() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    static func selection() {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

// MARK: - Interface style (immediate theme switching)

enum InterfaceStyle {
    static func apply(_ mode: ThemeMode) {
        let style: UIUserInterfaceStyle
        switch mode {
        case .system: style = .unspecified
        case .light: style = .light
        case .dark: style = .dark
        }
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows { window.overrideUserInterfaceStyle = style }
        }
    }
}

extension View {
    /// Applies the theme both as a preferred scheme and as a window override so
    /// it takes effect immediately on every screen, including cached tab pages.
    func interfaceStyle(_ mode: ThemeMode) -> some View {
        self
            .preferredColorScheme(mode.colorScheme)
            .onAppear { InterfaceStyle.apply(mode) }
            .onChange(of: mode) { _, newMode in InterfaceStyle.apply(newMode) }
    }
}

// MARK: - Symbol Effect Helpers
// Wraps iOS 17+ symbol effects with availability checks

struct BounceEffect: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .symbolEffect(.bounce, value: trigger)
        } else {
            content
        }
    }
}

struct VariableColorEffect: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .symbolEffect(.variableColor.iterative.dimInactiveLayers, value: trigger)
        } else {
            content
        }
    }
}

extension View {
    func bounceEffect(_ trigger: Bool) -> some View {
        modifier(BounceEffect(trigger: trigger))
    }

    func variableColorEffect(_ trigger: Bool) -> some View {
        modifier(VariableColorEffect(trigger: trigger))
    }
}

// MARK: - Pressable Button Style

struct PressableButtonStyle: ButtonStyle {
    let scale: CGFloat
    let springAnimation: Animation

    init(scale: CGFloat = 0.97, spring: Animation = SafeDesign.spring) {
        self.scale = scale
        self.springAnimation = spring
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(springAnimation, value: configuration.isPressed)
    }
}

extension View {
    func pressable(scale: CGFloat = 0.97) -> some View {
        buttonStyle(PressableButtonStyle(scale: scale))
    }
}