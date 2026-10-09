import SwiftUI

/// Shared building blocks for the sectioned layout.

/// A full-width hairline used to separate rows without boxing them.
struct Hairline: View {
    var leading: CGFloat = 0
    var body: some View {
        Rectangle()
            .fill(SafeDesign.hairline)
            .frame(height: 1)
            .padding(.leading, leading)
    }
}

/// A lightweight section header: title on the left, optional trailing accessory.
struct SectionHeader<Trailing: View>: View {
    let title: String
    let trailing: Trailing

    init(_ title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(SafeDesign.headline)
                .foregroundStyle(SafeDesign.ink)
            Spacer()
            trailing
        }
    }
}

/// A soft rounded surface used for stat cards and resource cards.
struct ClayCard<Content: View>: View {
    let fill: Color
    let cornerRadius: CGFloat
    let content: Content

    init(fill: Color = SafeDesign.surfaceSoft,
         cornerRadius: CGFloat = SafeDesign.radiusL,
         @ViewBuilder content: () -> Content) {
        self.fill = fill
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(SafeDesign.l)
            .background(fill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// A pill-shaped badge (uppercase micro text).
struct BadgePill: View {
    let text: String
    var fill: Color = SafeDesign.surfaceCard

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .medium))
            .tracking(1.5)
            .foregroundStyle(SafeDesign.ink)
            .padding(.horizontal, SafeDesign.s)
            .padding(.vertical, 6)
            .background(fill, in: Capsule())
    }
}

/// Reusable glass icon button.
struct GlassIconButton: View {
    let icon: String
    var size: CGFloat = 44
    var label: String? = nil
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(SafeDesign.ink)
                .frame(width: max(size, minTouchTarget), height: max(size, minTouchTarget))
                .glassPill()
        }
        .buttonStyle(.plain)
        .pressable()
        .accessibilityLabel(label ?? icon)
    }
}