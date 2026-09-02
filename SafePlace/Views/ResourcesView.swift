import SwiftUI

struct ResourcesView: View {
    @ObservedObject var store: Store
    @State private var text = ""
    @State private var url = ""
    @State private var filter: Filter = .all

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
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: SafeDesign.m), GridItem(.flexible())], spacing: SafeDesign.m) {
                        ForEach(filtered) { resource in
                            resourceCard(resource)
                        }
                    }
                    .animation(SafeDesign.spring, value: filter)
                }
            }
            .padding(.horizontal, SafeDesign.xl)
            .padding(.top, SafeDesign.l)
            .padding(.bottom, 110)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SafeDesign.xxs) {
            BadgePill(text: "resources")
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
        HStack(spacing: SafeDesign.s) {
            ForEach(Filter.allCases) { f in
                SelectionPill(title: f.rawValue, isSelected: filter == f) {
                    withAnimation(SafeDesign.spring) { filter = f }
                }
            }
        }
    }

    private func resourceCard(_ resource: Resource) -> some View {
        VStack(alignment: .leading, spacing: SafeDesign.m) {
            if resource.isLink {
                Link(destination: URL(string: resource.url) ?? URL(string: "https://")!) {
                    Text(resource.text)
                        .font(SafeDesign.body)
                        .fontWeight(.medium)
                        .foregroundStyle(SafeDesign.ink)
                        .underline(true, color: SafeDesign.ink.opacity(0.3))
                        .multilineTextAlignment(.leading)
                }
            } else {
                Text(resource.text)
                    .font(SafeDesign.body)
                    .fontWeight(.medium)
                    .foregroundStyle(SafeDesign.ink)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            HStack {
                Label(resource.isLink ? "link" : "note", systemImage: resource.isLink ? "link" : "doc.text")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SafeDesign.muted)
                Spacer()
                Button {
                    withAnimation(SafeDesign.spring) {
                        store.deleteResource(id: resource.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(SafeDesign.muted)
                        .frame(width: 34, height: 34)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(SafeDesign.l)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .background(
            resource.isLink ? SafeDesign.surfaceSoft : SafeDesign.surfaceCard,
            in: RoundedRectangle(cornerRadius: SafeDesign.radiusL, style: .continuous)
        )
    }

    private func saveResource() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let urlTrimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        store.addResource(Resource(
            id: "r-\(UUID().uuidString)",
            text: trimmed,
            url: urlTrimmed,
            type: !urlTrimmed.isEmpty ? "link" : "note",
            createdAt: Date()
        ))
        text = ""
        url = ""
    }
}

#Preview {
    ZStack {
        BackgroundOrbs()
        ResourcesView(store: Store())
    }
}