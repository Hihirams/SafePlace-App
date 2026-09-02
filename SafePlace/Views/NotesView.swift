import SwiftUI

struct NotesView: View {
    @ObservedObject var store: Store
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v
    @State private var notes: [SharedNote] = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SafeDesign.xl) {
                header

                howToCard

                if notes.isEmpty {
                    emptyState
                } else {
                    ForEach(notes) { note in
                        sharedNoteCard(note)
                    }
                }
            }
            .pageColumn(h, v)
            .padding(.top, SafeDesign.l)
            .padding(.bottom, SafeLayout.tabBarClearance(h))
        }
        .onAppear(perform: reload)
        .onChange(of: store.entries.count) { _, _ in reload() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SafeDesign.xxs) {
            BadgePill(text: "notes")
            Text("Notes from your iPhone.")
                .font(SafeDesign.largeTitle)
                .foregroundStyle(SafeDesign.ink)
            Text("Share a note from the Apple Notes app (or any app) straight into SafePlace. It arrives here, ready to keep.")
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.inkSecondary)
        }
    }

    private var howToCard: some View {
        VStack(alignment: .leading, spacing: SafeDesign.s) {
            Label("How it works", systemImage: "square.and.arrow.up")
                .font(SafeDesign.headline)
                .foregroundStyle(SafeDesign.ink)
            HStack(alignment: .top, spacing: SafeDesign.m) {
                stepNumber(1, color: SafeDesign.pink)
                Text("Open a note in Apple Notes, tap the Share button, then choose **SafePlace**.")
                    .font(SafeDesign.body)
                    .foregroundStyle(SafeDesign.inkSecondary)
            }
            HStack(alignment: .top, spacing: SafeDesign.m) {
                stepNumber(2, color: SafeDesign.teal)
                Text("The note lands in this tab, where you can read it and decide what to keep.")
                    .font(SafeDesign.body)
                    .foregroundStyle(SafeDesign.inkSecondary)
            }
            HStack(alignment: .top, spacing: SafeDesign.m) {
                stepNumber(3, color: SafeDesign.ochre)
                Text("Tap **Keep it** to move it into your safe place as a note card.")
                    .font(SafeDesign.body)
                    .foregroundStyle(SafeDesign.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SafeDesign.l)
        .background(SafeDesign.surfaceSoft, in: RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous))
    }

    private func stepNumber(_ n: Int, color: Color) -> some View {
        Text("\(n)")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(color, in: Circle())
    }

    private var emptyState: some View {
        VStack(spacing: SafeDesign.s) {
            Image(systemName: "note.text")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(SafeDesign.muted)
            Text("No shared notes yet.")
                .font(SafeDesign.headline)
                .foregroundStyle(SafeDesign.ink)
            Text("Share text from Apple Notes using the iOS share sheet and it will show up here.")
                .font(SafeDesign.caption)
                .foregroundStyle(SafeDesign.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SafeDesign.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SafeDesign.xxxl)
    }

    private func sharedNoteCard(_ note: SharedNote) -> some View {
        VStack(alignment: .leading, spacing: SafeDesign.s) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SafeDesign.ochre)
                Text(note.title.isEmpty ? "Untitled note" : note.title)
                    .font(SafeDesign.headline)
                    .foregroundStyle(SafeDesign.ink)
                    .lineLimit(2)
                Spacer()
                Text(note.createdAt.formattedShort())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SafeDesign.muted)
            }

            Text(note.text)
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.inkSecondary)
                .lineLimit(6)
                .multilineTextAlignment(.leading)

            HStack {
                Button {
                    withAnimation(SafeDesign.spring) {
                        store.importSharedNote(note)
                        reload()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Keep it")
                    }
                    .font(SafeDesign.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(SafeDesign.onPrimary)
                    .padding(.horizontal, SafeDesign.l)
                    .frame(height: 40)
                    .background(Capsule().fill(SafeDesign.primary))
                }
                .buttonStyle(.plain)
                .pressable(scale: 0.95)

                Spacer()

                Button {
                    withAnimation(SafeDesign.spring) {
                        store.discardSharedNote(note)
                        reload()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                        Text("Dismiss")
                    }
                    .font(SafeDesign.caption)
                    .foregroundStyle(SafeDesign.inkSecondary)
                    .padding(.horizontal, SafeDesign.l)
                    .frame(height: 40)
                    .background(Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .pressable(scale: 0.95)
            }
            .padding(.top, SafeDesign.xs)
        }
        .padding(SafeDesign.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SafeDesign.surfaceCard, in: RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous))
    }

    private func reload() {
        notes = SharedNoteStore.load()
    }
}

#Preview {
    ZStack {
        BackgroundOrbs()
        NotesView(store: Store())
    }
}