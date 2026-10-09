import SwiftUI
import UIKit

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

/// The recurring brand glyph: a thin eight-point asterisk.
struct BrandMark: View {
    var size: CGFloat = 14
    var color: Color = SafeDesign.ink

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(color)
                    .frame(width: size, height: max(1, size * 0.075))
                    .rotationEffect(.degrees(Double(index) * 45))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// An editorial note row: a colored tick, a serif title, a short snippet and
/// quiet metadata — separated from its siblings by a hairline, not a card.
struct EditorialNoteRow: View {
    let entry: Entry
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}
    var onDuplicate: () -> Void = {}

    var body: some View {
        Button {
            Haptics.tap()
            onEdit()
        } label: {
            HStack(alignment: .top, spacing: SafeDesign.m) {
                Capsule()
                    .fill(entry.cardColor.fill)
                    .frame(width: 4, height: 34)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(entry.moodValue.label.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(SafeDesign.muted)
                        Text("·").font(.system(size: 10)).foregroundStyle(SafeDesign.muted)
                        Text(entry.createdAt.formattedShort())
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(SafeDesign.muted)
                    }

                    Text(entry.title)
                        .font(SafeDesign.serifHead)
                        .foregroundStyle(SafeDesign.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if !entry.description.isEmpty {
                        Text(entry.description)
                            .font(SafeDesign.body)
                            .foregroundStyle(SafeDesign.inkSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 0)

                Menu {
                    Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
                    Button { onDuplicate() } label: { Label("Duplicate", systemImage: "doc.on.doc") }
                    Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SafeDesign.muted)
                        .frame(width: 34, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Note options")
            }
            .padding(.vertical, SafeDesign.s)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
            Button { onDuplicate() } label: { Label("Duplicate", systemImage: "doc.on.doc") }
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
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

// MARK: - Profile photo

enum ProfilePhotoStore {
    static var url: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return docs.appendingPathComponent("ProfilePhoto.jpg")
    }

    static func load() -> UIImage? {
        UIImage(contentsOfFile: url.path)
    }

    static func save(_ data: Data) {
        try? data.write(to: url, options: .atomic)
    }

    static func delete() {
        try? FileManager.default.removeItem(at: url)
    }
}

final class ProfilePhotoModel: ObservableObject {
    @Published var image: UIImage?

    init() { image = ProfilePhotoStore.load() }

    func update(data: Data) {
        ProfilePhotoStore.save(data)
        image = ProfilePhotoStore.load()
    }

    func clear() {
        ProfilePhotoStore.delete()
        image = nil
    }
}

/// The user avatar: their photo, or a soft mood-tinted fallback (no letter).
struct ProfileAvatar: View {
    var size: CGFloat = 42
    var image: UIImage?

    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(RadialGradient(colors: [theme.tint, theme.tintStrong],
                                         center: .topLeading, startRadius: 2, endRadius: size))
                    .frame(width: size, height: size)
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(SafeDesign.onPrimary.opacity(0.85))
            }
        }
        .overlay { Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1) }
        .frame(width: size, height: size)
    }
}