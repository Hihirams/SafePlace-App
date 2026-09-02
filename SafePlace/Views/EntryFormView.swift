import SwiftUI

struct EntryFormView: View {
    let initial: Entry?
    let categories: [String]
    let onSave: (Entry) -> Void
    let onClose: () -> Void

    @State private var title: String
    @State private var description: String
    @State private var category: String
    @State private var mood: String
    @State private var color: CardColor
    @State private var showNewCategory = false
    @State private var newCategory = ""

    init(initial: Entry?, categories: [String], onSave: @escaping (Entry) -> Void, onClose: @escaping () -> Void) {
        self.initial = initial
        self.categories = categories
        self.onSave = onSave
        self.onClose = onClose
        _title = State(initialValue: initial?.title ?? "")
        _description = State(initialValue: initial?.description ?? "")
        _category = State(initialValue: initial?.category ?? categories.first ?? "")
        _mood = State(initialValue: initial?.mood ?? Mood.calm.id)
        _color = State(initialValue: initial?.cardColor ?? .cream)
    }

    private var isEditing: Bool { initial != nil }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: SafeDesign.xl) {
                    SheetHeader(
                        title: isEditing ? "Edit this note" : "What helped you?",
                        subtitle: isEditing ? "Tweak what you saved." : "Add something that gently carried you.",
                        onClose: onClose
                    )

                    field("Title") {
                        ClayTextField(icon: "textformat", placeholder: "e.g. A slow morning coffee", text: $title)
                    }

                    field("What happened") {
                        ClayTextArea(placeholder: "Write a little about why it helped...", text: $description)
                    }

                    field("Category") {
                        VStack(alignment: .leading, spacing: SafeDesign.s) {
                            HStack(spacing: SafeDesign.s) {
                                Menu {
                                    ForEach(effectiveCategories, id: \.self) { c in
                                        Button(c) { category = c }
                                    }
                                } label: {
                                    HStack {
                                        Text(category.isEmpty ? "Choose a category" : category)
                                            .font(SafeDesign.body)
                                            .foregroundStyle(category.isEmpty ? SafeDesign.muted : SafeDesign.ink)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(SafeDesign.muted)
                                    }
                                    .padding(.horizontal, SafeDesign.l)
                                    .padding(.vertical, SafeDesign.m)
                                    .background(SafeDesign.surfaceSoft, in: Capsule())
                                    .overlay { Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1) }
                                }
                                .buttonStyle(.plain)

                                Button {
                                    withAnimation(SafeDesign.spring) { showNewCategory.toggle() }
                                } label: {
                                    Text(showNewCategory ? "Cancel" : "+ New")
                                        .font(SafeDesign.caption)
                                        .foregroundStyle(SafeDesign.ink)
                                        .padding(.horizontal, SafeDesign.l)
                                        .frame(height: 44)
                                        .background(SafeDesign.surfaceCard, in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .pressable(scale: 0.95)
                            }

                            if showNewCategory {
                                ClayTextField(icon: "plus", placeholder: "New category name...", text: $newCategory)
                            }
                        }
                    }

                    field("How did it make you feel?") {
                        moodPicker
                    }

                    field("Card color") {
                        colorSwatches
                    }

                    HStack(spacing: SafeDesign.s) {
                        SecondaryButton(title: "Cancel", icon: "xmark") { onClose() }
                        PrimaryButton(title: isEditing ? "Save changes" : "Save note", icon: "checkmark") {
                            save()
                        }
                    }
                    .padding(.top, SafeDesign.xs)
                }
                .padding(.horizontal, SafeDesign.xl)
                .padding(.top, SafeDesign.xs)
                .padding(.bottom, SafeDesign.xxxl)
            }
            .background(SafeDesign.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var effectiveCategories: [String] {
        var result = categories
        let trimmed = newCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !result.contains(trimmed) {
            result.append(trimmed)
        }
        return result
    }

    private var moodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SafeDesign.s) {
                ForEach(Mood.all) { m in
                    Button {
                        withAnimation(SafeDesign.spring) { mood = m.id }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: m.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(m.label)
                                .font(SafeDesign.caption)
                        }
                        .foregroundStyle(mood == m.id ? SafeDesign.onPrimary : SafeDesign.inkSecondary)
                        .padding(.horizontal, SafeDesign.l)
                        .padding(.vertical, SafeDesign.s)
                        .background {
                            if mood == m.id {
                                Capsule().fill(m.color)
                            } else {
                                Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .pressable(scale: 0.95)
                }
            }
        }
    }

    private var colorSwatches: some View {
        HStack(spacing: SafeDesign.s) {
            ForEach(CardColor.allCases) { c in
                Button {
                    withAnimation(SafeDesign.spring) { color = c }
                } label: {
                    Circle()
                        .fill(c.fill)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Circle()
                                .strokeBorder(color == c ? SafeDesign.ink : .clear, lineWidth: 2)
                        }
                        .overlay {
                            if color == c {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(c.foreground)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private func field(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: SafeDesign.xs) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SafeDesign.inkSecondary)
            content()
        }
    }

    private func save() {
        let finalCategory = newCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        let chosenCategory = finalCategory.isEmpty ? category : finalCategory
        let entry = Entry(
            id: initial?.id ?? "e-\(UUID().uuidString)",
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: chosenCategory.isEmpty ? "Uncategorized" : chosenCategory,
            mood: mood,
            color: color.rawValue,
            createdAt: initial?.createdAt ?? Date()
        )
        onSave(entry)
    }
}

#Preview {
    EntryFormView(initial: nil, categories: Store.defaultCategories, onSave: { _ in }, onClose: {})
}