import SwiftUI

struct EntryCardView: View {
    let entry: Entry
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}

    private var color: CardColor { entry.cardColor }

    var body: some View {
        VStack(alignment: .leading, spacing: SafeDesign.s) {
            HStack {
                Label(entry.moodValue.label, systemImage: entry.moodValue.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color.accent)
                Spacer()
                Text(entry.createdAt.formattedShort())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color.accent)
            }

            Text(entry.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color.foreground)
                .lineLimit(2)

            Text(entry.description)
                .font(.system(size: 14))
                .foregroundStyle(color.foreground.opacity(0.92))
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 4)

            HStack {
                Text(entry.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color.foreground)
                    .padding(.horizontal, SafeDesign.s)
                    .padding(.vertical, 5)
                    .background(color.foreground.opacity(0.16), in: Capsule())

                Spacer()

                HStack(spacing: 2) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(color.accent)
                            .frame(width: 34, height: 34)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(color.accent)
                            .frame(width: 34, height: 34)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(SafeDesign.l)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(color.fill, in: RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(color.foreground.opacity(0.06))
                .frame(width: 110, height: 110)
                .offset(x: 40, y: -50)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous))
    }
}

#Preview {
    VStack(spacing: 16) {
        EntryCardView(entry: Entry(
            id: "1", title: "Morning walk", description: "A slow reset before work.",
            category: "Habits", mood: "calm", color: "mint", createdAt: Date()
        ))
        EntryCardView(entry: Entry(
            id: "2", title: "Calling my sister", description: "Feels lighter.",
            category: "People", mood: "bright", color: "pink", createdAt: Date()
        ))
    }
    .padding()
    .background(SafeDesign.canvas)
}