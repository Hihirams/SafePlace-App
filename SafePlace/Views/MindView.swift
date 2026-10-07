import SwiftUI
import UIKit

struct MindView: View {
    @ObservedObject var store: Store
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v

    @State private var graph = MindGraph(nodes: [], edges: [])
    @State private var simulation: MindSimulation?
    @State private var colorMode: MindColorMode = .mood
    @State private var sensitivity: CGFloat = 0.5
    @State private var paused = false
    @State private var selectedID: String?
    @State private var zoom: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var canvasSize: CGSize = .zero

    @State private var dragStartPan: CGSize = .zero
    @State private var zoomStart: CGFloat = 1

    @State private var editingEntry: Entry?
    @State private var showForm = false

    private var minWeight: CGFloat { 0.2 + (1 - sensitivity) * 1.6 }

    private var energy: CGFloat {
        let mood = MindGraph.averageEnergy(of: store.entries)
        let countFactor = min(1 + log2(CGFloat(store.entries.count) + 1) * 0.12, 1.7)
        return mood * countFactor
    }

    private var selectedEntry: Entry? {
        guard let selectedID else { return nil }
        return store.entries.first { $0.id == selectedID }
    }

    private var connectedIDs: Set<String> {
        guard let selectedID else { return [] }
        var result: Set<String> = [selectedID]
        for edge in graph.edges where edge.from == selectedID || edge.to == selectedID {
            result.insert(edge.from == selectedID ? edge.to : edge.from)
        }
        return result
    }

    /// Scale that fits the fixed physics "world" into the current canvas.
    private var baseScale: CGFloat {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return 1 }
        let usable = min(canvasSize.width, canvasSize.height)
        return usable / MindSimulation.worldSize
    }

    var body: some View {
        ZStack {
            BackgroundOrbs()

            if store.entries.isEmpty {
                emptyState
            } else {
                graphArea
            }

            VStack {
                header
                Spacer()
            }
            .padding(.horizontal, SafeLayout.pageInset(h, v))
            .padding(.top, SafeDesign.s)

            VStack(spacing: SafeDesign.s) {
                if let entry = selectedEntry {
                    selectionCard(entry)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                controls
            }
            .padding(.horizontal, SafeLayout.pageInset(h, v))
            .padding(.bottom, SafeLayout.tabBarClearance(h))
        }
        .onAppear(perform: rebuildNodes)
        .onChange(of: store.entries) { _, _ in rebuildNodes() }
        .onChange(of: colorMode) { _, _ in rebuildNodes() }
        .onChange(of: sensitivity) { _, _ in refreshEdges() }
        .sheet(isPresented: $showForm) {
            EntryFormView(
                initial: editingEntry,
                categories: store.categories,
                onSave: { entry in
                    store.updateEntry(entry)
                    showForm = false
                    editingEntry = nil
                },
                onClose: { showForm = false; editingEntry = nil }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Graph canvas

    private var graphArea: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { _ in
                Canvas { context, size in
                    if !paused, let simulation {
                        simulation.step(iterations: 1, energy: energy)
                    }
                    drawGraph(in: &context, size: size)
                }
            }
            .onAppear { canvasSize = geo.size }
            .onChange(of: geo.size) { _, newSize in canvasSize = newSize }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { value in
                    handleTap(at: value.location)
                }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        pan = CGSize(
                            width: dragStartPan.width + value.translation.width,
                            height: dragStartPan.height + value.translation.height
                        )
                    }
                    .onEnded { _ in dragStartPan = pan }
            )
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        zoom = min(max(zoomStart * value.magnification, 0.5), 3.5)
                    }
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

    private func drawGraph(in context: inout GraphicsContext, size: CGSize) {
        guard let simulation else { return }
        _ = size

        // Edges underneath.
        for edge in graph.edges {
            guard let a = simulation.position(for: edge.from),
                  let b = simulation.position(for: edge.to) else { continue }
            let sa = toScreen(a)
            let sb = toScreen(b)
            var alpha = 0.12 + (edge.weight / 3.0) * 0.42
            if selectedID != nil && !connectedIDs.contains(edge.from) { alpha *= 0.15 }

            var path = Path()
            path.move(to: sa)
            path.addLine(to: sb)
            context.stroke(
                path,
                with: .color(SafeDesign.ink.opacity(alpha)),
                style: StrokeStyle(lineWidth: 0.8 + (edge.weight / 3.0) * 1.8, lineCap: .round)
            )
        }

        // Nodes on top.
        for node in graph.nodes {
            guard let position = simulation.position(for: node.id) else { continue }
            let center = toScreen(position)
            let radius = max(node.radius * baseScale * zoom, 7)

            var alpha: CGFloat = 1
            if selectedID != nil && !connectedIDs.contains(node.id) { alpha = 0.20 }
            let isSelected = node.id == selectedID

            // Soft colored glow.
            let glow = Path(ellipseIn: CGRect(x: center.x - radius * 1.9, y: center.y - radius * 1.9, width: radius * 3.8, height: radius * 3.8))
            context.fill(glow, with: .color(node.color.opacity(0.18 * alpha)))

            // Body with a soft vertical gradient.
            let bodyRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            let body = Path(ellipseIn: bodyRect)
            let gradient = Gradient(colors: [
                node.color.opacity(0.98 * alpha),
                node.color.opacity(0.72 * alpha)
            ])
            context.fill(body, with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: center.x, y: center.y - radius),
                endPoint: CGPoint(x: center.x, y: center.y + radius)
            ))

            // Top highlight for a glossy orb.
            let highlight = Path(ellipseIn: CGRect(
                x: center.x - radius * 0.5,
                y: center.y - radius * 0.72,
                width: radius * 1.0,
                height: radius * 0.7
            ))
            context.fill(highlight, with: .color(.white.opacity(0.28 * alpha)))

            // Selected ring.
            if isSelected {
                let ring = Path(ellipseIn: bodyRect.insetBy(dx: -3, dy: -3))
                context.stroke(ring, with: .color(SafeDesign.ink.opacity(0.85)), lineWidth: 2.5)
            }

            // Pinned ring.
            if simulation.isPinned(node.id) {
                let ring = Path(ellipseIn: bodyRect.insetBy(dx: -5, dy: -5))
                context.stroke(ring, with: .color(SafeDesign.accentDeep.opacity(0.9)), lineWidth: 1.5)
            }

            // Focused label chip.
            if isSelected {
                let title = node.entry.title.isEmpty ? "Untitled" : node.entry.title
                let text = Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SafeDesign.ink)
                let resolved = context.resolve(text)
                let textSize = resolved.measure(in: CGSize(width: 220, height: 40))
                let chipRect = CGRect(
                    x: center.x - textSize.width / 2 - 8,
                    y: center.y + radius + 10,
                    width: textSize.width + 16,
                    height: textSize.height + 8
                )
                context.fill(Path(roundedRect: chipRect, cornerRadius: 10), with: .color(SafeDesign.surfaceCard))
                context.stroke(Path(roundedRect: chipRect, cornerRadius: 10), with: .color(SafeDesign.hairline), lineWidth: 0.75)
                context.draw(resolved, at: CGPoint(x: chipRect.midX, y: chipRect.midY), anchor: .center)
            }
        }
    }

    private func handleTap(at point: CGPoint) {
        guard let simulation else { selectedID = nil; return }
        var bestID: String?
        var bestDistance = CGFloat.infinity

        for node in graph.nodes {
            guard let position = simulation.position(for: node.id) else { continue }
            let center = toScreen(position)
            let hitRadius = max(node.radius * baseScale * zoom, 26)
            let distance = hypot(center.x - point.x, center.y - point.y)
            if distance < hitRadius && distance < bestDistance {
                bestDistance = distance
                bestID = node.id
            }
        }

        if bestID != nil { Haptics.selection() }
        withAnimation(SafeDesign.spring) { selectedID = bestID }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            BadgePill(text: "mind")
            Spacer()
            energyPill
        }
    }

    private var energyPill: some View {
        Label(
            "\(store.entries.count) notes · energy \(Int(energy * 100))%",
            systemImage: paused ? "pause.fill" : "sparkles"
        )
        .font(SafeDesign.caption)
        .foregroundStyle(SafeDesign.ink)
        .padding(.horizontal, SafeDesign.m)
        .padding(.vertical, 6)
        .background(SafeDesign.surfaceCard, in: Capsule())
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: SafeDesign.s) {
            HStack(spacing: SafeDesign.s) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SafeDesign.xs) {
                        ForEach(MindColorMode.allCases) { mode in
                            SelectionPill(title: mode.label, icon: mode.icon, isSelected: colorMode == mode) {
                                Haptics.selection()
                                withAnimation(SafeDesign.spring) { colorMode = mode }
                            }
                        }
                    }
                }
                .scrollClipDisabled()

                GlassIconButton(icon: paused ? "play.fill" : "pause.fill", size: 38) {
                    Haptics.tap()
                    paused.toggle()
                }
                GlassIconButton(icon: "minus.magnifyingglass", size: 38) { zoomBy(0.8) }
                GlassIconButton(icon: "plus.magnifyingglass", size: 38) { zoomBy(1.25) }
                GlassIconButton(icon: "scope", size: 38) { recenter() }
            }

            HStack(spacing: SafeDesign.m) {
                Image(systemName: "circle.dashed")
                    .font(.system(size: 13))
                    .foregroundStyle(SafeDesign.muted)
                Slider(
                    value: Binding(
                        get: { Double(sensitivity) },
                        set: { sensitivity = CGFloat($0) }
                    ),
                    in: 0...1
                )
                .tint(SafeDesign.accentDeep)
                Image(systemName: "circle.grid.cross.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(SafeDesign.muted)
            }
        }
        .padding(SafeDesign.m)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous)
                .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
        }
        .shadow(color: .black.opacity(0.14), radius: 20, y: 10)
    }

    private func zoomBy(_ factor: CGFloat) {
        Haptics.tap()
        withAnimation(SafeDesign.springSnappy) {
            zoom = min(max(zoom * factor, 0.5), 3.5)
        }
        zoomStart = zoom
    }

    private func recenter() {
        withAnimation(SafeDesign.springSnappy) {
            zoom = 1
            pan = .zero
        }
        zoomStart = 1
        dragStartPan = .zero
    }

    // MARK: - Selection card

    private func selectionCard(_ entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: SafeDesign.s) {
            HStack(spacing: SafeDesign.xs) {
                HStack(spacing: 6) {
                    Circle().fill(entry.cardColor.fill).frame(width: 12, height: 12)
                    Text(entry.moodValue.label)
                        .font(SafeDesign.caption)
                        .foregroundStyle(SafeDesign.inkSecondary)
                }
                Text(entry.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SafeDesign.ink)
                    .padding(.horizontal, SafeDesign.s)
                    .padding(.vertical, 5)
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
                .font(SafeDesign.title)
                .foregroundStyle(SafeDesign.ink)
                .lineLimit(2)

            if !entry.description.isEmpty {
                Text(entry.description)
                    .font(SafeDesign.body)
                    .foregroundStyle(SafeDesign.inkSecondary)
                    .lineLimit(3)
            }

            HStack(spacing: SafeDesign.s) {
                Spacer()
                Button {
                    Haptics.soft()
                    withAnimation(SafeDesign.spring) { simulation?.togglePin(entry.id) }
                } label: {
                    Label(simulation?.isPinned(entry.id) == true ? "Pinned" : "Pin",
                          systemImage: simulation?.isPinned(entry.id) == true ? "pin.fill" : "pin")
                        .font(SafeDesign.caption)
                        .foregroundStyle(SafeDesign.inkSecondary)
                        .padding(.horizontal, SafeDesign.m)
                        .frame(height: 34)
                        .background(Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.tap()
                    editingEntry = entry
                    showForm = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(SafeDesign.caption)
                        .foregroundStyle(SafeDesign.onPrimary)
                        .padding(.horizontal, SafeDesign.m)
                        .frame(height: 34)
                        .background(Capsule().fill(SafeDesign.accent))
                }
                .buttonStyle(.plain)
                .pressable(scale: 0.95)
            }
        }
        .padding(SafeDesign.l)
        .background(SafeDesign.surfaceCard, in: RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous)
                .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
        }
        .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: SafeDesign.s) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(SafeDesign.muted)
            Text("Your mind, connected.")
                .font(SafeDesign.largeTitle)
                .foregroundStyle(SafeDesign.ink)
            Text("Add a few notes and this space turns into a living network of your thoughts, moods and topics.")
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SafeDesign.xxl)
        }
        .padding(.horizontal, SafeLayout.pageInset(h, v))
    }

    // MARK: - Rebuild

    private func rebuildNodes() {
        graph = MindGraph.build(from: store.entries, colorMode: colorMode, minWeight: minWeight)
        simulation = MindSimulation(nodes: graph.nodes, edges: graph.edges)
        selectedID = nil
        recenter()
    }

    private func refreshEdges() {
        graph = MindGraph.build(from: store.entries, colorMode: colorMode, minWeight: minWeight)
        simulation?.update(edges: graph.edges)
    }
}

#Preview {
    ZStack {
        BackgroundOrbs()
        MindView(store: Store())
    }
}
