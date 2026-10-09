import SwiftUI
import UIKit

struct ResourcesView: View {
    @ObservedObject var store: Store
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v
    @Environment(\.appTheme) private var theme
    @State private var text = ""
    @State private var url = ""
    @State private var filter: Filter = .all
    @State private var contentWidth: CGFloat = 0
    @State private var copiedID: String?

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case link = "Links"
        case note = "Notes"
        var id: String { rawValue }
    }

    private var filtered: [Resource] {
        store.resources.filter { r in
            switch filter {
            case .all: return true
            case .link: return r.isLink
            case .note: return !r.isLink
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: SafeDesign.xl) {
                header
                addForm
                filterBar

                if filtered.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        ForEach(filtered) { resource in
                            resourceRow(resource)
                            if resource.id != filtered.last?.id { Hairline() }
                        }
                    }
                    .animation(SafeDesign.spring, value: filter)
                }
            }
            .pageColumn(h, v)
            .padding(.top, SafeDesign.l)
            .padding(.bottom, SafeLayout.tabBarClearance(h))
            .readingWidth($contentWidth)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SafeDesign.xxs) {
            BadgePill(text: "saved")
            Text("Links, quotes & reminders.")
                .font(SafeDesign.largeTitle)
                .foregroundStyle(SafeDesign.ink)
            Text("Keep the things worth keeping close — a playlist, an article, a line that made sense at the right time.")
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.inkSecondary)
        }
    }

    private var addForm: some View {
        VStack(spacing: SafeDesign.s) {
            ClayTextField(icon: "textformat", placeholder: "What do you want to keep?", text: $text)
            ClayTextField(icon: "link", placeholder: "Paste a link (optional)", text: $url)
            PrimaryButton(title: "Save", icon: "plus") {
                saveResource()
            }
        }
        .padding(SafeDesign.l)
        .background(SafeDesign.surfaceSoft, in: RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous))
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SafeDesign.s) {
                ForEach(Filter.allCases) { f in
                    SelectionPill(title: f.rawValue, isSelected: filter == f) {
                        Haptics.selection()
                        withAnimation(SafeDesign.spring) { filter = f }
                    }
                }
            }
        }
        .scrollClipDisabled()
    }

    private var emptyState: some View {
        VStack(spacing: SafeDesign.s) {
            Image(systemName: "bookmark")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(SafeDesign.muted)
            Text("Nothing saved here yet.")
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SafeDesign.xxxl)
    }

    private func resourceRow(_ resource: Resource) -> some View {
        HStack(alignment: .top, spacing: SafeDesign.m) {
            Image(systemName: resource.isLink ? "link" : "text.quote")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.tintStrong)
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 4) {
                if resource.isLink, let link = URL(string: resource.url) {
                    Link(destination: link) {
                        Text(resource.text)
                            .font(SafeDesign.serifHead)
                            .foregroundStyle(SafeDesign.ink)
                            .underline(true, color: SafeDesign.hairline)
                            .multilineTextAlignment(.leading)
                    }
                } else {
                    Text(resource.text)
                        .font(SafeDesign.serifHead)
                        .foregroundStyle(SafeDesign.ink)
                        .multilineTextAlignment(.leading)
                }

                if resource.isLink, let host = URL(string: resource.url)?.host {
                    Text(host)
                        .font(SafeDesign.micro)
                        .foregroundStyle(SafeDesign.muted)
                }

                if copiedID == resource.id {
                    Text("Copied")
                        .font(SafeDesign.micro)
                        .foregroundStyle(theme.tintStrong)
                        .transition(.opacity)
                }
            }

            Spacer(minLength: 0)

            Menu {
                Button { copy(resource) } label: { Label("Copy", systemImage: "doc.on.doc") }
                if resource.isLink, let link = URL(string: resource.url) {
                    ShareLink(item: link) { Label("Share link", systemImage: "square.and.arrow.up") }
                } else {
                    ShareLink(item: resource.text) { Label("Share", systemImage: "square.and.arrow.up") }
                }
                Button { convertToNote(resource) } label: { Label("Save as note", systemImage: "note.text.badge.plus") }
                Button(role: .destructive) {
                    Haptics.warning()
                    withAnimation(SafeDesign.spring) { store.deleteResource(id: resource.id) }
                } label: { Label("Delete", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SafeDesign.muted)
                    .frame(width: 34, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Saved item options")
        }
        .padding(.vertical, SafeDesign.s)
    }

    private func saveResource() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            Haptics.warning()
            return
        }
        let urlTrimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        store.addResource(Resource(
            id: "r-\(UUID().uuidString)",
            text: trimmed,
            url: urlTrimmed,
            type: !urlTrimmed.isEmpty ? "link" : "note",
            createdAt: Date()
        ))
        Haptics.success()
        text = ""
        url = ""
    }

    private func copy(_ resource: Resource) {
        UIPasteboard.general.string = resource.isLink ? resource.url : resource.text
        Haptics.tap()
        withAnimation { copiedID = resource.id }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation { if copiedID == resource.id { copiedID = nil } }
        }
    }

    private func convertToNote(_ resource: Resource) {
        store.addEntry(Entry(
            id: "e-\(UUID().uuidString)",
            title: String(resource.text.prefix(40)),
            description: resource.isLink ? "\(resource.text)\n\(resource.url)" : resource.text,
            category: "Saved",
            mood: "calm",
            color: CardColor.cream.rawValue,
            createdAt: Date()
        ))
        Haptics.success()
    }
}

#Preview {
    ZStack {
        BackgroundOrbs()
        ResourcesView(store: Store())
    }
}
