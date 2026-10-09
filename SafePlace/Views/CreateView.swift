import SwiftUI

/// A blank canvas to pour thoughts onto: no fields, no boxes — just paper,
/// a serif prompt, and a quiet row of controls at the bottom.
struct CreateView: View {
    @ObservedObject var store: Store
    var onClose: () -> Void

    @Environment(\.appTheme) private var theme

    @State private var text = ""
    @State private var mood: String = Mood.calm.id
    @State private var category = ""
    @State private var userChoseCategory = false
    @FocusState private var focused: Bool

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ZStack {
            SafeDesign.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                canvas
                bottomBar
            }
        }
        .onAppear { focused = true }
        .onChange(of: text) { _, _ in applySuggestion() }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                Haptics.tap()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SafeDesign.ink)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(SafeDesign.surfaceSoft))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
            .accessibilityIdentifier("create-close")

            Spacer()

            BrandMark(size: 11, color: theme.tintStrong)

            Spacer()

            Button {
                save()
            } label: {
                Text("Keep")
                    .font(SafeDesign.headline)
                    .foregroundStyle(SafeDesign.canvas)
                    .padding(.horizontal, SafeDesign.l)
                    .frame(minHeight: 40)
                    .background(Capsule().fill(SafeDesign.ink))
            }
            .buttonStyle(.plain)
            .disabled(trimmed.isEmpty)
            .opacity(trimmed.isEmpty ? 0.35 : 1)
            .accessibilityIdentifier("create-save")
        }
        .padding(.horizontal, SafeDesign.l)
        .padding(.top, SafeDesign.m)
        .padding(.bottom, SafeDesign.s)
    }

    // MARK: - Canvas

    private var canvas: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(SafeDesign.ink)
                .tint(theme.tintStrong)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, SafeDesign.l)
                .focused($focused)
                .accessibilityLabel("Your thought")
                .accessibilityIdentifier("create-text")

            if text.isEmpty {
                Text("What's on your mind?")
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(SafeDesign.muted)
                    .padding(.horizontal, SafeDesign.l + 5)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: SafeDesign.s) {
            ForEach(Mood.all) { m in
                Button {
                    Haptics.selection()
                    withAnimation(SafeDesign.springSnappy) { mood = m.id }
                } label: {
                    Circle()
                        .fill(mood == m.id ? m.color : SafeDesign.surfaceSoft)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Image(systemName: m.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SafeDesign.ink)
                        }
                        .overlay {
                            Circle().strokeBorder(mood == m.id ? SafeDesign.ink.opacity(0.25) : SafeDesign.hairline, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(m.label)
            }

            Spacer()

            Menu {
                ForEach(store.categories, id: \.self) { name in
                    Button(name) {
                        category = name
                        userChoseCategory = true
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                        .font(.system(size: 11, weight: .semibold))
                    Text(category.isEmpty ? "Category" : category)
                        .font(SafeDesign.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(SafeDesign.inkSecondary)
                .padding(.horizontal, SafeDesign.m)
                .frame(minHeight: 34)
                .background(Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Category")
            .accessibilityIdentifier("create-category")
        }
        .padding(.horizontal, SafeDesign.l)
        .padding(.top, SafeDesign.s)
        .padding(.bottom, SafeDesign.l)
        .background(SafeDesign.canvas)
        .overlay(alignment: .top) { Hairline() }
    }

    // MARK: - Actions

    private func applySuggestion() {
        guard !userChoseCategory else { return }
        if let suggested = Categorizer.suggest(title: trimmed, description: "", categories: store.categories) {
            category = suggested
        }
    }

    private func save() {
        let body = trimmed
        guard !body.isEmpty else { return }
        let firstLine = body.split(separator: "\n").first.map(String.init) ?? body
        let title = firstLine.trimmingCharacters(in: .whitespaces)
        let resolvedCategory = category.isEmpty
            ? (Categorizer.suggest(title: body, description: "", categories: store.categories) ?? "Self-care")
            : category
        let entry = Entry(
            id: "e-\(UUID().uuidString)",
            title: title.isEmpty ? "Untitled" : String(title.prefix(80)),
            description: body,
            category: resolvedCategory,
            mood: mood,
            color: color(for: mood).rawValue,
            createdAt: Date()
        )
        store.addEntry(entry)
        Haptics.success()
        onClose()
    }

    private func color(for mood: String) -> CardColor {
        switch mood {
        case "bright": return .peach
        case "calm": return .mint
        case "hopeful": return .lavender
        case "mixed": return .ochre
        default: return .pink
        }
    }
}

#Preview {
    CreateView(store: Store(), onClose: {})
}
