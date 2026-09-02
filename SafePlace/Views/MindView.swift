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

    private var minWeight: CGFloat {
        0.2 + (1 - sensitivity) * 1.6
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

    private var connectedIDs: Set<String> {
        guard let selectedID else { return [] }
        var result: Set<String> = [selectedID]
        for edge in graph.edges where edge.from == selectedID || edge.to == selectedID {
            result.insert(edge.from == selectedID ? edge.to : edge.from)
        }
        return result
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

            controls
                .padding(.horizontal, SafeLayout.pageInset(h, v))
                .padding(.bottom, SafeLayout.tabBarClearance(h))

            if let entry = selectedEntry {
                selectionCard(entry)
                    .padding(.horizontal, SafeLayout.pageInset(h, v))
                    .padding(.bottom, SafeLayout.tabBarClearance(h) + 60)
            }
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
            TimelineView(.animation(minimumInterval: 1.0 / 40)) { _ in
                Canvas { context, size in
                    if !paused, let simulation {
                        simulation.step(iterations: 2, energy: energy)
                    }
                    drawGraph(in: &context, size: size)
                }
            }
            .onAppear { canvasSize = geo.size }
            .onChange(of: geo.size) { _, newSize in canvasSize = newSize }
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
                        zoom = min(max(zoomStart * value.magnification, 0.4), 3.2)
                    }
                    .onEnded { _ in zoomStart = zoom }
            )
        }
    }

    private func toScreen(_ world: CGPoint) -> CGPoint {
        CGPoint(
            x: (world.x - MindSimulation.worldSize / 2) * zoom + canvasSize.width / 2 + pan.width,
            y: (world.y - MindSimulation.worldSize / 2) * zoom + canvasSize.height / 2 + pan.height
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
            var alpha = 0.10 + (edge.weight / 3.0) * 0.35
            if selectedID != nil && !connectedIDs.contains(edge.from) {
                alpha *= 0.18
            }
            var path = Path()
            path.move(to: sa)
            path.addLine(to: sb)
            context.stroke(
                path,
                with: .color(SafeDesign.ink.opacity(alpha)),
                lineWidth: 1 + (edge.weight / 3.0) * 1.6
            )
        }

        // Nodes on top.
        for node in graph.nodes {
            guard let position = simulation.position(for: node.id) else { continue }
            let center = toScreen(position)
            let radius = max(node.radius * zoom, 4)

            var alpha: CGFloat = 1
            if selectedID != nil && !connectedIDs.contains(node.id) {
                alpha = 0.22
            }

            // Soft glow.
            let glow = Path(ellipseIn: CGRect(x: center.x - radius * 1.7, y: center.y - radius * 1.7, width: radius * 3.4, height: radius * 3.4))
            context.fill(glow, with: .color(node.color.opacity(0.16 * alpha)))

            // Body.
            let body = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            context.fill(body, with: .color(node.color.opacity(alpha)))

            // Hairline ring (stronger when focused).
            context.stroke(
                body,
                with: .color(.white.opacity(0.5 * alpha)),
                lineWidth: node.id == selectedID ? 2.5 : 1
            )

            // Pinned ring.
            if simulation.isPinned(node.id) {
                let ring = Path(ellipseIn: CGRect(x: center.x - radius - 3, y: center.y - radius - 3, width: radius * 2 + 6, height: radius * 2 + 6))
                context.stroke(ring, with: .color(SafeDesign.ink.opacity(0.55)), lineWidth: 1.2)
            }

            // Focused label.
            if node.id == selectedID {
                let title = node.entry.title.isEmpty ? "Untitled" : node.entry.title
                context.draw(
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SafeDesign.ink),
                    at: CGPoint(x: center.x, y: center.y + radius + 16)
                )
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
            let hitRadius = max(node.radius * zoom, 22)
            let distance = hypot(center.x - point.x, center.y - point.y)
            if distance < hitRadius && distance < bestDistance {
                bestDistance = distance
                bestID = node.id
            }
        }

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
                    HStack(spacing: SafeDesign.s) {
                        ForEach(MindColorMode.allCases) { mode in
                            SelectionPill(title: mode.label, icon: mode.icon, isSelected: colorMode == mode) {
                                withAnimation(SafeDesign.spring) { colorMode = mode }
                            }
                        }
                    }
                }
                .scrollClipDisabled()

                GlassIconButton(icon: paused ? "play.fill" : "pause.fill", size: 38) {
                    paused.toggle()
                }
                GlassIconButton(icon: "arrow.counterclockwise", size: 38) {
                    recenter()
                }
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
                .tint(SafeDesign.ochre)
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
        .shadow(color: .black.opacity(0.12), radius: 20, y: 10)
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
                    Circle()
                        .fill(entry.cardColor.fill)
                        .frame(width: 12, height: 12)
                    Text(entry.moodValue.label)
                        .font(SafeDesign.caption)
                        .foregroundStyle(SafeDesign.inkSecondary)
                }
                Text(entry.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SafeDesign.ink)
                    .padding(.horizontal, SafeDesign.s)
                    .padding(.vertical, 5)
                    .background(SafeDesign.surfaceCard, in: Capsule())
                Spacer()
                Text(entry.createdAt.formattedShort())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SafeDesign.muted)
            }

            Text(entry.title)
                .font(SafeDesign.title)
                .foregroundStyle(SafeDesign.ink)

            Text(entry.description)
                .font(SafeDesign.body)
                .foregroundStyle(SafeDesign.inkSecondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            HStack(spacing: SafeDesign.s) {
                Spacer()

                Button {
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
                    editingEntry = entry
                    showForm = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(SafeDesign.caption)
                        .foregroundStyle(SafeDesign.onPrimary)
                        .padding(.horizontal, SafeDesign.m)
                        .frame(height: 34)
                        .background(Capsule().fill(SafeDesign.primary))
                }
                .buttonStyle(.plain)
                .pressable(scale: 0.95)

                GlassIconButton(icon: "xmark", size: 34) {
                    withAnimation(SafeDesign.spring) { selectedID = nil }
                }
            }
        }
        .padding(SafeDesign.l)
        .background(SafeDesign.surfaceCard, in: RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SafeDesign.radiusXL, style: .continuous)
                .strokeBorder(SafeDesign.hairline, lineWidth: 0.75)
        }
        .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
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