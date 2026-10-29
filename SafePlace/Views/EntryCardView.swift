import SwiftUI

struct EntryCardView: View {
    let entry: Entry
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}
    var onDuplicate: () -> Void = {}

    @State private var confirmDelete = false

    private var color: CardColor { entry.cardColor }

    var body: some View {
        VStack(alignment: .leading, spacing: SafeDesign.s) {
            HStack {
                Label(entry.moodValue.label, systemImage: entry.moodValue.icon)
                    .font(SafeDesign.scaled(12, weight: .medium))
                    .foregroundStyle(color.accent)
                Spacer()
                Text(entry.createdAt.formattedShort())
                    .font(SafeDesign.scaled(12, weight: .medium))
                    .foregroundStyle(color.accent)
            }

            Text(entry.title)
                .font(SafeDesign.scaled(18, weight: .semibold))
                .foregroundStyle(color.foreground)
                .lineLimit(2)

            if !entry.description.isEmpty {
                Text(entry.description)
                    .font(SafeDesign.scaled(14))
                    .foregroundStyle(color.foreground.opacity(0.92))
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            HStack {
                Text(entry.category)
                    .font(SafeDesign.scaled(12, weight: .medium))
                    .foregroundStyle(color.foreground)
                    .padding(.horizontal, SafeDesign.s)
                    .padding(.vertical, 5)
                    .background(color.foreground.opacity(0.16), in: Capsule())

                Spacer()

                Menu {
                    Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
                    Button { onDuplicate() } label: { Label("Duplicate", systemImage: "doc.on.doc") }
                    Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(SafeDesign.scaled(15, weight: .semibold))
                        .foregroundStyle(color.accent)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Note options"))
            }
        }
        .padding(SafeDesign.l)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(color.fill, in: RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(color.foreground.opacity(0.06))
                .frame(width: 110, height: 110)
                .offset(x: 40, y: -50)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous))
        .onTapGesture {
            Haptics.tap()
            onEdit()
        }
        .contextMenu {
            Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
            Button { onDuplicate() } label: { Label("Duplicate", systemImage: "doc.on.doc") }
            Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: "trash") }
        }
        // Borrar una nota no se puede deshacer: se confirma una vez.
        .confirmationDialog(String(localized: "Delete this note?"),
                            isPresented: $confirmDelete,
                            titleVisibility: .visible) {
            Button(String(localized: "Delete"), role: .destructive) { onDelete() }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "It can't be undone."))
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to edit")
    }
}

#Preview {
    VStack(spacing: 16) {
        EntryCardView(entry: Entry(
            id: "1", title: "Caminata por la mañana", description: "A slow reset before work.",
            category: "Hábitos", mood: "calm", color: "mint", createdAt: Date()
        ))
        EntryCardView(entry: Entry(
            id: "2", title: "Llamar a mi hermana", description: "Feels lighter.",
            category: "Personas", mood: "bright", color: "pink", createdAt: Date()
        ))
    }
    .padding()
    .background(SafeDesign.canvas)
}
