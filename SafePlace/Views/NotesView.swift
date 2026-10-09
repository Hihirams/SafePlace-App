import SwiftUI

struct NotesView: View {
    @ObservedObject var store: Store
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v
    @State private var notes: [SharedNote] = []
    @State private var previewing: SharedNote?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SafeDesign.xl) {
                header
                howToCard

                if notes.isEmpty {
                    emptyState
                } else {
                    HStack {
                        Text("\(notes.count) waiting")
                            .font(SafeDesign.caption)
                            .foregroundStyle(SafeDesign.inkSecondary)
                        Spacer()
                        Button {
                            keepAll()
                        } label: {
                            Label("Keep all", systemImage: "checkmark.circle")
                                .font(SafeDesign.caption)
                                .foregroundStyle(SafeDesign.onPrimary)
                                .padding(.horizontal, SafeDesign.l)
                                .padding(.vertical, SafeDesign.s)
                                .background(Capsule().fill(SafeDesign.accent))
                        }
                        .buttonStyle(.plain)
                        .pressable(scale: 0.95)
                    }

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
        .sheet(item: $previewing) { note in
            NotePreviewSheet(note: note, store: store, onDone: {
                previewing = nil
                reload()
            })
        }
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
            step(1, color: SafeDesign.pink, text: "Open a note in Apple Notes, tap the Share button, then choose SafePlace.")
            step(2, color: SafeDesign.mint, text: "The note lands in this tab, where you can read it and decide what to keep.")
            step(3, color: SafeDesign.accentDeep, text: "Tap Keep it to move it into your safe place as a note card.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SafeDesign.l)
        .background(SafeDesign.surfaceSoft, in: RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous))
    }

    private func step(_ n: Int, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: SafeDesign.m) {
            Text("\(n)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(SafeDesign.onPrimary)
                .frame(width: 24, height: 24)
                .background(color, in: Circle())
            Text(text)
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.inkSecondary)
        }
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
                    .foregroundStyle(SafeDesign.accentDeep)
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

            AdaptiveStack(spacing: SafeDesign.s) {
                Button {
                    keep(note)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Keep it")
                    }
                    .font(SafeDesign.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(SafeDesign.onPrimary)
                    .padding(.horizontal, SafeDesign.l)
                    .frame(minHeight: 40)
                    .background(Capsule().fill(SafeDesign.accent))
                }
                .buttonStyle(.plain)
                .pressable(scale: 0.95)

                Button {
                    Haptics.tap()
                    previewing = note
                } label: {
                    Label("Open", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(SafeDesign.caption)
                        .foregroundStyle(SafeDesign.inkSecondary)
                        .padding(.horizontal, SafeDesign.l)
                        .frame(minHeight: 40)
                        .background(Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    discard(note)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SafeDesign.inkSecondary)
                        .frame(width: 40, height: 40)
                        .background(Circle().strokeBorder(SafeDesign.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, SafeDesign.xs)
        }
        .padding(SafeDesign.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SafeDesign.surfaceCard, in: RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous)
                .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
        }
    }

    // MARK: - Actions

    private func keep(_ note: SharedNote) {
        store.importSharedNote(note)
        Haptics.success()
        reload()
    }

    private func discard(_ note: SharedNote) {
        store.discardSharedNote(note)
        Haptics.tap()
        reload()
    }

    private func keepAll() {
        for note in notes { store.importSharedNote(note) }
        Haptics.success()
        reload()
    }

    private func reload() {
        notes = SharedNoteStore.load()
    }
}

// MARK: - Preview sheet

private struct NotePreviewSheet: View {
    let note: SharedNote
    @ObservedObject var store: Store
    var onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var text: String

    init(note: SharedNote, store: Store, onDone: @escaping () -> Void) {
        self.note = note
        self.store = store
        self.onDone = onDone
        _title = State(initialValue: note.title)
        _text = State(initialValue: note.text)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: SafeDesign.l) {
                    SheetHeader(title: "Shared note", subtitle: "Edit before keeping it.", onClose: { dismiss(); onDone() })
                    ClayTextField(icon: "textformat", placeholder: "Title", text: $title)
                    ClayTextArea(placeholder: "Note text", text: $text)
                    HStack(spacing: SafeDesign.s) {
                        SecondaryButton(title: "Dismiss", icon: "xmark") {
                            store.discardSharedNote(note)
                            dismiss()
                            onDone()
                        }
                        PrimaryButton(title: "Keep it", icon: "checkmark") {
                            save()
                        }
                    }
                }
                .padding(.horizontal, SafeDesign.l)
                .padding(.bottom, SafeDesign.xxl)
            }
            .background(SafeDesign.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func save() {
        var updated = note
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.text = text
        store.importSharedNote(updated)
        store.discardSharedNote(note)
        Haptics.success()
        dismiss()
        onDone()
    }
}

#Preview {
    ZStack {
        BackgroundOrbs()
        NotesView(store: Store())
    }
}
