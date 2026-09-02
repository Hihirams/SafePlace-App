import SwiftUI

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