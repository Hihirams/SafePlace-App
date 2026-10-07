import SwiftUI

/// A 3-second capture: pick a mood, optionally say what it was, save.
/// Designed to lower the barrier to daily logging.
struct QuickCaptureView: View {
    @ObservedObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var mood: String = Mood.calm.id
    @State private var title: String = ""
    @State private var note: String = ""
    @State private var category: String = ""
    @State private var userChoseCategory = false

    private let moodToColor: [String: CardColor] = [
        "bright": .peach, "calm": .mint, "hopeful": .lavender,
        "mixed": .ochre, "heavy": .pink
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: SafeDesign.xl) {
                    SheetHeader(
                        title: "How are you, really?",
                        subtitle: "Tap a feeling and save it in seconds.",
                        onClose: { dismiss() }
                    )

                    moodRow

                    ClayTextField(icon: "textformat", placeholder: "What's this about? (optional)", text: $title)

                    ClayTextArea(placeholder: "A line or two, if you feel like it…", text: $note)

                    categoryRow

                    PrimaryButton(title: "Save to SafePlace", icon: "checkmark") {
                        save()
                    }
                    .padding(.top, SafeDesign.xs)
                }
                .padding(.horizontal, SafeDesign.l)
                .padding(.bottom, SafeDesign.xxl)
            }
            .background(SafeDesign.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            if category.isEmpty { category = store.categories.first ?? "Self-care" }
        }
        .onChange(of: title) { _, _ in applySuggestion() }
        .onChange(of: note) { _, _ in applySuggestion() }
    }

    private func applySuggestion() {
        guard !userChoseCategory else { return }
        if let suggested = Categorizer.suggest(title: title, description: note, categories: store.categories) {
            withAnimation(SafeDesign.springSnappy) { category = suggested }
        }
    }

    private var moodRow: some View {
        HStack(spacing: SafeDesign.xs) {
            ForEach(Mood.all) { m in
                let sel = mood == m.id
                Button {
                    Haptics.selection()
                    withAnimation(SafeDesign.springSnappy) { mood = m.id }
                } label: {
                    VStack(spacing: SafeDesign.xs) {
                        ZStack {
                            Circle()
                                .fill(sel ? m.color : SafeDesign.surfaceSoft)
                                .frame(width: 52, height: 52)
                            Image(systemName: m.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(sel ? SafeDesign.ink : SafeDesign.inkSecondary)
                        }
                        .overlay {
                            Circle().strokeBorder(sel ? SafeDesign.ink.opacity(0.25) : SafeDesign.hairline, lineWidth: 1)
                        }
                        .scaleEffect(sel ? 1.08 : 1)
                        Text(m.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(sel ? SafeDesign.ink : SafeDesign.muted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: SafeDesign.xs) {
            Text("Category")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SafeDesign.inkSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SafeDesign.xs) {
                    ForEach(store.categories, id: \.self) { c in
                        SelectionPill(title: c, isSelected: category == c) {
                            Haptics.selection()
                            userChoseCategory = true
                            withAnimation(SafeDesign.springSnappy) { category = c }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = Entry(
            id: "e-\(UUID().uuidString)",
            title: trimmedTitle.isEmpty ? Mood.mood(for: mood).label + " moment" : trimmedTitle,
            description: trimmedNote,
            category: category.isEmpty ? "Self-care" : category,
            mood: mood,
            color: (moodToColor[mood] ?? .cream).rawValue,
            createdAt: Date()
        )
        store.addEntry(entry)
        Haptics.success()
        dismiss()
    }
}

#Preview {
    QuickCaptureView(store: Store())
}
