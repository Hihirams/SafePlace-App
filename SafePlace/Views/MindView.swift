import SwiftUI
import UIKit

struct MindView: View {
    @ObservedObject var store: Store
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v

    @State private var graph = MindGraph(hubs: [], nodes: [], edges: [])
    @State private var simulation: MindSimulation?
    @State private var colorMode: MindColorMode = .wave
    @State private var focusCategory: String?
    @State private var selectedID: String?
    @State private var zoom: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var canvasSize: CGSize = .zero
    @State private var dragStartPan: CGSize = .zero
    @State private var zoomStart: CGFloat = 1
    @State private var contagionStart = Date()
    @State private var isVisible = false

    @State private var editingEntry: Entry?
    @State private var showEdit = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Derived

    private var dominant: (mood: Mood, dominance: CGFloat)? {
        MindGraph.dominantMood(of: store.entries)
    }

    private var energy: CGFloat {
        let mood = MindGraph.averageEnergy(of: store.entries)
        let countFactor = min(1 + log2(CGFloat(store.entries.count) + 1) * 0.12, 1.7)
        return mood * countFactor
    }

    private var selectedEntry: Entry? {
        guard let selectedID else { return nil }
        return store.entries.first { $0.id == selectedID }
    }

    private var baseScale: CGFloat {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return 1 }
        return min(canvasSize.width, canvasSize.height) / MindSimulation.worldSize
    }

    var body: some View {
        ZStack {
            BackgroundOrbs()

            if store.entries.isEmpty {
                emptyState
            } else {
                graphArea
            }

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, SafeLayout.pageInset(h, v))
                    .padding(.top, SafeDesign.s)

                Spacer(minLength: SafeDesign.s)

                VStack(spacing: SafeDesign.s) {
                    if let entry = selectedEntry {
                        selectionCard(entry)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    viewSwitcher
                }
                .padding(.horizontal, SafeLayout.pageInset(h, v))
                .padding(.bottom, SafeLayout.tabBarClearance(h))
            }
        }
        .onAppear(perform: rebuild)
        .onChange(of: store.entries) { _, _ in rebuild() }
        .onChange(of: colorMode) { _, _ in rebuild() }
        .fullScreenCover(isPresented: $showEdit) {
            CreateView(store: store, editing: editingEntry) {
                showEdit = false
                editingEntry = nil
            }
        }
    }

    // MARK: - Graph canvas

    private var graphArea: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                Canvas { context, size in
                    if !reduceMotion, isVisible, let simulation {
                        simulation.step(iterations: 1, energy: energy)
                    }
                    drawGraph(in: &context, size: size, date: timeline.date)
                }
            }
            .onAppear { isVisible = true; canvasSize = geo.size }
            .onDisappear { isVisible = false }
            .onChange(of: geo.size) { _, newSize in canvasSize = newSize }
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { handleTap(at: $0.location) })
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        pan = CGSize(width: dragStartPan.width + value.translation.width,
                                     height: dragStartPan.height + value.translation.height)
                    }
                    .onEnded { _ in dragStartPan = pan }
            )
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in zoom = min(max(zoomStart * value.magnification, 0.6), 3.0) }
                    .onEnded { _ in zoomStart = zoom }
            )
        }
    }

    private func toScreen(_ world: CGPoint) -> CGPoint {
        let s = baseScale * zoom
        return CGPoint(
            x: (world.x - MindSimulation.worldSize / 2) * s + canvasSize.width / 2 + pan.width,
            y: (world.y - MindSimulation.worldSize / 2) * s + canvasSize.height / 2 + pan.height
        )
    }

    private func contagionAmount(_ date: Date) -> CGFloat {
        guard let dominant else { return 0 }
        let elapsed = date.timeIntervalSince(contagionStart)
        let progress = min(max(elapsed / 4.0, 0), 1)
        return CGFloat(progress) * (0.55 + 0.4 * dominant.dominance)
    }

    private func color(base: Color, date: Date) -> Color {
        guard colorMode == .wave, let dominant else { return base }
        return base.blended(with: dominant.mood.color, amount: contagionAmount(date))
    }

    private func drawGraph(in context: inout GraphicsContext, size: CGSize, date: Date) {
        guard let simulation else { return }
        _ = size

        let focused = focusCategory

        // Edges: only for the focused category's members.
        if let focused {
            for edge in graph.edges where edge.to == focused {
                guard let a = simulation.position(for: edge.from),
                      let b = simulation.position(for: edge.to) else { continue }
                var path = Path()
                path.move(to: toScreen(a))
                path.addLine(to: toScreen(b))
                context.stroke(path, with: .color(SafeDesign.ink.opacity(0.22)), lineWidth: 1)
            }
        }

        // Members (only inside the focused category).
        if let focused {
            for node in graph.nodes where node.category == focused {
                guard let position = simulation.position(for: node.id) else { continue }
                let center = toScreen(position)
                let radius = max(node.radius * baseScale * zoom, 6)
                let nodeColor = color(base: node.color, date: date)
                let isSelected = node.id == selectedID

                context.fill(Path(ellipseIn: CGRect(x: center.x - radius * 1.8, y: center.y - radius * 1.8, width: radius * 3.6, height: radius * 3.6)),
                             with: .color(nodeColor.opacity(0.16)))
                let bodyRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: bodyRect), with: .color(nodeColor))
                context.fill(Path(ellipseIn: CGRect(x: center.x - radius * 0.5, y: center.y - radius * 0.7, width: radius, height: radius * 0.7)),
                             with: .color(.white.opacity(0.3)))
                if isSelected {
                    context.stroke(Path(ellipseIn: bodyRect.insetBy(dx: -3, dy: -3)), with: .color(SafeDesign.ink.opacity(0.85)), lineWidth: 2.5)
                }
            }
        }

        // Hubs always.
        for hub in graph.hubs {
            guard let position = simulation.position(for: hub.id) else { continue }
            let center = toScreen(position)
            let radius = max(hub.radius * baseScale * zoom, 18)
            let hubColor = color(base: hub.color, date: date)
            let isFocused = hub.id == focusCategory

            context.fill(Path(ellipseIn: CGRect(x: center.x - radius * 1.5, y: center.y - radius * 1.5, width: radius * 3, height: radius * 3)),
                         with: .color(hubColor.opacity(0.16)))
            let bodyRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: bodyRect), with: .color(hubColor))
            context.fill(Path(ellipseIn: CGRect(x: center.x - radius * 0.5, y: center.y - radius * 0.72, width: radius, height: radius * 0.7)),
                         with: .color(.white.opacity(0.28)))
            context.stroke(Path(ellipseIn: bodyRect.insetBy(dx: isFocused ? -4 : -2, dy: isFocused ? -4 : -2)),
                           with: .color(isFocused ? SafeDesign.ink.opacity(0.8) : .white.opacity(0.45)),
                           lineWidth: isFocused ? 2.5 : 1)

            let label = Text("\(hub.category) · \(hub.count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(SafeDesign.ink)
            let resolved = context.resolve(label)
            let textSize = resolved.measure(in: CGSize(width: 240, height: 30))
            let chipRect = CGRect(x: center.x - textSize.width / 2 - 8, y: center.y + radius + 8,
                                  width: textSize.width + 16, height: textSize.height + 6)
            context.fill(Path(roundedRect: chipRect, cornerRadius: 9), with: .color(SafeDesign.surfaceCard))
            context.stroke(Path(roundedRect: chipRect, cornerRadius: 9), with: .color(SafeDesign.hairline), lineWidth: 0.75)
            context.draw(resolved, at: CGPoint(x: chipRect.midX, y: chipRect.midY), anchor: .center)
        }

        // Focused member label.
        if let selectedID, let node = graph.nodes.first(where: { $0.id == selectedID }),
           let position = simulation.position(for: node.id) {
            let center = toScreen(position)
            let radius = max(node.radius * baseScale * zoom, 6)
            let title = node.entry.title.isEmpty ? "Untitled" : node.entry.title
            let resolved = context.resolve(Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(SafeDesign.ink))
            let textSize = resolved.measure(in: CGSize(width: 220, height: 40))
            let chipRect = CGRect(x: center.x - textSize.width / 2 - 8, y: center.y + radius + 10, width: textSize.width + 16, height: textSize.height + 8)
            context.fill(Path(roundedRect: chipRect, cornerRadius: 10), with: .color(SafeDesign.surfaceCard))
            context.stroke(Path(roundedRect: chipRect, cornerRadius: 10), with: .color(SafeDesign.hairline), lineWidth: 0.75)
            context.draw(resolved, at: CGPoint(x: chipRect.midX, y: chipRect.midY), anchor: .center)
        }
    }

    // MARK: - Interaction

    private func handleTap(at point: CGPoint) {
        guard let simulation else { return }

        // Hub hit?
        var bestHub: MindHub?
        var bestHubDistance = CGFloat.infinity
        for hub in graph.hubs {
            guard let position = simulation.position(for: hub.id) else { continue }
            let center = toScreen(position)
            let hitRadius = max(hub.radius * baseScale * zoom, 34)
            let distance = hypot(center.x - point.x, center.y - point.y)
            if distance < hitRadius && distance < bestHubDistance {
                bestHubDistance = distance
                bestHub = hub
            }
        }
        if let bestHub {
            focus(on: bestHub)
            return
        }

        // Member hit inside the focused category?
        if let focused = focusCategory {
            var bestID: String?
            var bestDistance = CGFloat.infinity
            for node in graph.nodes where node.category == focused {
                guard let position = simulation.position(for: node.id) else { continue }
                let center = toScreen(position)
                let hitRadius = max(node.radius * baseScale * zoom, 26)
                let distance = hypot(center.x - point.x, center.y - point.y)
                if distance < hitRadius && distance < bestDistance {
                    bestDistance = distance
                    bestID = node.id
                }
            }
            if let bestID {
                Haptics.selection()
                withAnimation(SafeDesign.spring) { selectedID = bestID }
                return
            }
        }

        clearFocus()
    }

    private func focus(on hub: MindHub) {
        guard let position = simulation?.position(for: hub.id) else { return }
        Haptics.selection()
        let targetZoom: CGFloat = 1.9
        let s = baseScale * targetZoom
        let newPan = CGSize(
            width: -((position.x - MindSimulation.worldSize / 2) * s),
            height: -((position.y - MindSimulation.worldSize / 2) * s)
        )
        withAnimation(SafeDesign.spring) {
            focusCategory = hub.id
            selectedID = nil
            zoom = targetZoom
            pan = newPan
        }
        zoomStart = targetZoom
        dragStartPan = newPan
    }

    private func clearFocus() {
        withAnimation(SafeDesign.spring) {
            focusCategory = nil
            selectedID = nil
            zoom = 1
            pan = .zero
        }
        zoomStart = 1
        dragStartPan = .zero
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            BadgePill(text: "mind")
            Spacer()
            statusPill
        }
    }

    private var statusPill: some View {
        let text: String
        let icon: String
        if colorMode == .wave, let dominant {
            text = "mostly \(dominant.mood.label.lowercased()) · \(Int(dominant.dominance * 100))%"
            icon = dominant.mood.icon
        } else {
            text = "\(graph.hubs.count) categories · \(store.entries.count) notes"
            icon = "tag.fill"
        }
        return Label(text, systemImage: icon)
            .font(SafeDesign.caption)
            .foregroundStyle(SafeDesign.ink)
            .padding(.horizontal, SafeDesign.m)
            .padding(.vertical, 6)
            .background(SafeDesign.surfaceCard, in: Capsule())
            .overlay { Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1) }
    }

    // MARK: - View switcher (Wave / Category)

    private var viewSwitcher: some View {
        HStack {
            Menu {
                ForEach(MindColorMode.allCases) { mode in
                    Button {
                        Haptics.selection()
                        withAnimation(SafeDesign.spring) { colorMode = mode }
                    } label: {
                        Label(mode.label, systemImage: mode.icon)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: colorMode.icon).font(.system(size: 13, weight: .semibold))
                    Text(colorMode.label).font(SafeDesign.caption)
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(SafeDesign.ink)
                .padding(.horizontal, SafeDesign.m)
                .frame(minHeight: 40)
                .background(SafeDesign.surfaceCard, in: Capsule())
                .overlay { Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1) }
            }
            .accessibilityLabel("Mind view")
            .accessibilityIdentifier("mind-view")

            Spacer()
        }
    }

    // MARK: - Selection card

    private func selectionCard(_ entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: SafeDesign.s) {
            HStack(spacing: SafeDesign.xs) {
                Text(entry.moodValue.label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(SafeDesign.muted)
                Text(entry.category)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SafeDesign.ink)
                    .padding(.horizontal, SafeDesign.s)
                    .padding(.vertical, 4)
                    .background(SafeDesign.surfaceStrong, in: Capsule())
                Spacer()
                Button {
                    Haptics.tap()
                    withAnimation(SafeDesign.spring) { selectedID = nil }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(SafeDesign.inkSecondary)
                        .frame(width: 30, height: 30)
                        .background(SafeDesign.surfaceStrong, in: Circle())
                }
                .buttonStyle(.plain)
            }

            Text(entry.title)
                .font(SafeDesign.serifHead)
                .foregroundStyle(SafeDesign.ink)
                .lineLimit(2)

            if !entry.description.isEmpty {
                Text(entry.description)
                    .font(SafeDesign.body)
                    .foregroundStyle(SafeDesign.inkSecondary)
                    .lineLimit(3)
            }

            HStack {
                Spacer()
                Button {
                    Haptics.tap()
                    editingEntry = entry
                    showEdit = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(SafeDesign.caption)
                        .foregroundStyle(SafeDesign.canvas)
                        .padding(.horizontal, SafeDesign.m)
                        .frame(minHeight: 34)
                        .background(Capsule().fill(SafeDesign.ink))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(SafeDesign.l)
        .background(SafeDesign.surfaceCard, in: RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous)
                .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
        }
        .shadow(color: .black.opacity(0.16), radius: 20, y: 10)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: SafeDesign.s) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(SafeDesign.muted)
            Text("Your mind, connected.")
                .font(SafeDesign.serifTitle)
                .foregroundStyle(SafeDesign.ink)
            Text("Add a few notes and this space turns into a living map of your thoughts, grouped by what matters.")
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SafeDesign.xxl)
        }
        .padding(.horizontal, SafeLayout.pageInset(h, v))
    }

    // MARK: - Rebuild

    private func rebuild() {
        graph = MindGraph.build(from: store.entries)
        simulation = MindSimulation(hubs: graph.hubs, nodes: graph.nodes)
        selectedID = nil
        focusCategory = nil
        zoom = 1
        pan = .zero
        zoomStart = 1
        dragStartPan = .zero
        contagionStart = Date()
    }
}

#Preview {
    ZStack {
        BackgroundOrbs()
        MindView(store: Store())
    }
}
