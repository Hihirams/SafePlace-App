import SwiftUI
import UIKit

/// Per-frame animation state. Kept as a reference type so the TimelineView can
/// advance it every frame without triggering SwiftUI state churn.
private final class MindCamera {
    var zoom: CGFloat = 1
    var pan: CGSize = .zero
    var targetZoom: CGFloat = 1
    var targetPan: CGSize = .zero

    var contagion: Double = 0        // 0...1 wave ramp
    var waveMix: CGFloat = 1        // 0 = category, 1 = wave
    var waveTarget: CGFloat = 1
    var focusProgress: CGFloat = 0  // 0 = hubs only, 1 = members shown
    var focusTarget: CGFloat = 0
    var pulse: CGFloat = 0          // pop on the focused hub

    private var zoomVel: CGFloat = 0
    private var panVel: CGSize = .zero
    private var lastDate: Date?

    func setDirect(zoom: CGFloat, pan: CGSize) {
        self.zoom = zoom
        self.pan = pan
        self.targetZoom = zoom
        self.targetPan = pan
        self.zoomVel = 0
        self.panVel = .zero
    }

    func setTarget(zoom: CGFloat, pan: CGSize) {
        self.targetZoom = zoom
        self.targetPan = pan
    }

    func advance(to date: Date) {
        let dt: CGFloat
        if let last = lastDate {
            dt = min(max(CGFloat(date.timeIntervalSince(last)), 0), 0.05)
        } else {
            dt = 0
        }
        lastDate = date
        guard dt > 0 else { return }

        // Slightly underdamped spring → smooth with a gentle settle.
        spring(&zoom, &zoomVel, targetZoom, dt)
        var px = pan.width, py = pan.height
        var vx = panVel.width, vy = panVel.height
        spring(&px, &vx, targetPan.width, dt)
        spring(&py, &vy, targetPan.height, dt)
        pan = CGSize(width: px, height: py)
        panVel = CGSize(width: vx, height: vy)

        contagion = min(contagion + Double(dt) / 4.0, 1)
        waveMix += (waveTarget - waveMix) * min(1, dt * 6)
        focusProgress += (focusTarget - focusProgress) * min(1, dt * 8)
        pulse = max(pulse - dt * 3, 0)
    }

    /// Reduce Motion: jump straight to the resting values.
    func snap() {
        zoom = targetZoom
        pan = targetPan
        zoomVel = 0
        panVel = .zero
        contagion = 1
        waveMix = waveTarget
        focusProgress = focusTarget
        pulse = 0
    }

    func reset() {
        zoom = 1; pan = .zero
        targetZoom = 1; targetPan = .zero
        zoomVel = 0; panVel = .zero
        contagion = 0
        waveMix = 1; waveTarget = 1
        focusProgress = 0; focusTarget = 0
        pulse = 0
        lastDate = nil
    }

    private func spring(_ value: inout CGFloat, _ velocity: inout CGFloat, _ target: CGFloat, _ dt: CGFloat) {
        let stiffness: CGFloat = 130
        let damping: CGFloat = 20
        let force = (target - value) * stiffness - velocity * damping
        velocity += force * dt
        value += velocity * dt
    }
}

struct MindView: View {
    @ObservedObject var store: Store
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v

    @State private var graph = MindGraph(hubs: [], nodes: [], edges: [])
    @State private var simulation: MindSimulation?
    @State private var colorMode: MindColorMode = .wave
    @State private var focusCategory: String?
    @State private var selectedID: String?
    @State private var canvasSize: CGSize = .zero
    @State private var dragStartPan: CGSize = .zero
    @State private var zoomStart: CGFloat = 1
    @State private var isVisible = false
    @State private var camera = MindCamera()

    @State private var editingEntry: Entry?
    @State private var showEdit = false
    @State private var showAll = false
    @State private var dominantMood: Mood?
    @State private var dominance: CGFloat = 0
    @State private var energyValue: CGFloat = 0.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .onChange(of: colorMode) { _, newMode in
            camera.waveTarget = newMode == .wave ? 1 : 0
        }
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
            TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                Canvas { context, size in
                    if reduceMotion {
                        camera.snap()
                    } else if isVisible {
                        camera.advance(to: timeline.date)
                        if let simulation {
                            simulation.step(iterations: 1, energy: energyValue)
                        }
                    }
                    drawGraph(in: &context, size: size)
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
                        camera.setDirect(zoom: camera.zoom, pan: CGSize(
                            width: dragStartPan.width + value.translation.width,
                            height: dragStartPan.height + value.translation.height))
                    }
                    .onEnded { _ in dragStartPan = camera.pan }
            )
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        camera.setDirect(zoom: min(max(zoomStart * value.magnification, 0.6), 3.0), pan: camera.pan)
                    }
                    .onEnded { _ in zoomStart = camera.zoom }
            )
        }
    }

    private func toScreen(_ world: CGPoint) -> CGPoint {
        let s = baseScale * camera.zoom
        return CGPoint(
            x: (world.x - MindSimulation.worldSize / 2) * s + canvasSize.width / 2 + camera.pan.width,
            y: (world.y - MindSimulation.worldSize / 2) * s + canvasSize.height / 2 + camera.pan.height
        )
    }

    private func color(base: Color) -> Color {
        guard let dominantMood else { return base }
        let amount = camera.contagion * Double(camera.waveMix) * (0.55 + 0.4 * Double(dominance))
        return base.blended(with: dominantMood.color, amount: CGFloat(amount))
    }

    private func drawGraph(in context: inout GraphicsContext, size: CGSize) {
        guard let simulation else { return }
        _ = size

        let focused = focusCategory
        let focusAlpha = camera.focusProgress
        let zoom = camera.zoom
        let showMembers = showAll || focused != nil

        // Edges.
        if showMembers, focusAlpha > 0.01 {
            for edge in graph.edges {
                if !showAll, edge.to != focused { continue }
                guard let a = simulation.position(for: edge.from),
                      let b = simulation.position(for: edge.to) else { continue }
                var path = Path()
                path.move(to: toScreen(a))
                path.addLine(to: toScreen(b))
                context.stroke(path, with: .color(SafeDesign.ink.opacity(0.18 * Double(focusAlpha))), lineWidth: 1)
            }
        }

        // Members (focused category, or all when Show all).
        if showMembers, focusAlpha > 0.01 {
            for node in graph.nodes {
                if !showAll, node.category != focused { continue }
                guard let position = simulation.position(for: node.id) else { continue }
                let center = toScreen(position)
                let radius = max(node.radius * baseScale * zoom * focusAlpha, 4)
                drawOrb(&context, center: center, radius: radius, color: color(base: node.color), alpha: focusAlpha,
                        ring: node.id == selectedID ? SafeDesign.ink.opacity(0.85) : nil, ringWidth: 2.5)
            }
        }

        // Hubs.
        for hub in graph.hubs {
            guard let position = simulation.position(for: hub.id) else { continue }
            let center = toScreen(position)
            let isFocused = hub.id == focusCategory
            let pop = isFocused ? (1 + camera.pulse * 0.18) : 1
            let radius = max(hub.radius * baseScale * zoom, 18) * pop
            drawOrb(&context, center: center, radius: radius, color: color(base: hub.color), alpha: 1,
                    ring: isFocused ? SafeDesign.ink.opacity(0.8) : .white.opacity(0.45),
                    ringWidth: isFocused ? 2.5 : 1)

            if isFocused {
                let resolved = context.resolve(
                    Text("\(hub.category) · \(hub.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SafeDesign.ink)
                )
                let textSize = resolved.measure(in: CGSize(width: 240, height: 30))
                let chipRect = CGRect(x: center.x - textSize.width / 2 - 8, y: center.y + radius + 8,
                                      width: textSize.width + 16, height: textSize.height + 6)
                context.fill(Path(roundedRect: chipRect, cornerRadius: 9), with: .color(SafeDesign.surfaceCard))
                context.stroke(Path(roundedRect: chipRect, cornerRadius: 9), with: .color(SafeDesign.hairline), lineWidth: 0.75)
                context.draw(resolved, at: CGPoint(x: chipRect.midX, y: chipRect.midY), anchor: .center)
            } else {
                context.draw(
                    Text("\(hub.category) · \(hub.count)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(SafeDesign.muted),
                    at: CGPoint(x: center.x, y: center.y + radius + 12),
                    anchor: .center
                )
            }
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

    /// A single-pass orb with a soft drop shadow (no overlapping glow → no shimmer).
    private func drawOrb(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, alpha: CGFloat, ring: Color?, ringWidth: CGFloat) {
        let body = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: .black.opacity(0.16 * Double(alpha)), radius: radius * 0.7, x: 0, y: radius * 0.35))
            layer.fill(body, with: .color(color.opacity(Double(alpha))))
        }
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - radius * 0.5, y: center.y - radius * 0.7, width: radius, height: radius * 0.7)),
            with: .color(.white.opacity(0.28 * Double(alpha)))
        )
        if let ring {
            context.stroke(body, with: .color(ring), lineWidth: ringWidth)
        }
    }

    // MARK: - Interaction

    private func handleTap(at point: CGPoint) {
        guard let simulation else { return }

        var bestHub: MindHub?
        var bestHubDistance = CGFloat.infinity
        for hub in graph.hubs {
            guard let position = simulation.position(for: hub.id) else { continue }
            let center = toScreen(position)
            let hitRadius = max(hub.radius * baseScale * camera.zoom, 34)
            let distance = hypot(center.x - point.x, center.y - point.y)
            if distance < hitRadius && distance < bestHubDistance {
                bestHubDistance = distance
                bestHub = hub
            }
        }
        if let bestHub {
            if bestHub.id == focusCategory {
                clearFocus()
            } else {
                focus(on: bestHub)
            }
            return
        }

        if let focused = focusCategory {
            var bestID: String?
            var bestDistance = CGFloat.infinity
            for node in graph.nodes where node.category == focused {
                guard let position = simulation.position(for: node.id) else { continue }
                let center = toScreen(position)
                let hitRadius = max(node.radius * baseScale * camera.zoom, 26)
                let distance = hypot(center.x - point.x, center.y - point.y)
                if distance < hitRadius && distance < bestDistance {
                    bestDistance = distance
                    bestID = node.id
                }
            }
            if let bestID {
                Haptics.selection()
                selectedID = bestID
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
        camera.setTarget(zoom: targetZoom, pan: newPan)
        camera.focusTarget = 1
        camera.pulse = 1
        focusCategory = hub.id
        selectedID = nil
        showAll = false
        zoomStart = targetZoom
        dragStartPan = newPan
    }

    private func clearFocus() {
        camera.setTarget(zoom: 1, pan: .zero)
        camera.focusTarget = 0
        focusCategory = nil
        selectedID = nil
        showAll = false
        zoomStart = 1
        dragStartPan = .zero
    }

    private func toggleShowAll() {
        Haptics.tap()
        if showAll {
            showAll = false
            camera.focusTarget = 0
            camera.setTarget(zoom: 1, pan: .zero)
            zoomStart = 1
            dragStartPan = .zero
        } else {
            showAll = true
            focusCategory = nil
            selectedID = nil
            camera.focusTarget = 1
            let fitZoom: CGFloat = 0.85
            camera.setTarget(zoom: fitZoom, pan: .zero)
            zoomStart = fitZoom
            dragStartPan = .zero
        }
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
        if colorMode == .wave, let dominantMood {
            text = "mostly \(dominantMood.label.lowercased()) · \(Int(dominance * 100))%"
            icon = dominantMood.icon
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

            Button {
                toggleShowAll()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showAll ? "circle.grid.cross.fill" : "circle.grid.cross")
                        .font(.system(size: 13, weight: .semibold))
                    Text(showAll ? "Hide all" : "Show all")
                        .font(SafeDesign.caption)
                }
                .foregroundStyle(showAll ? SafeDesign.canvas : SafeDesign.ink)
                .padding(.horizontal, SafeDesign.m)
                .frame(minHeight: 40)
                .background { Capsule().fill(showAll ? SafeDesign.ink : SafeDesign.surfaceCard) }
                .overlay { Capsule().strokeBorder(SafeDesign.hairline, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showAll ? "Hide all" : "Show all")
            .accessibilityIdentifier("mind-show-all")
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
        let dominant = MindGraph.dominantMood(of: store.entries)
        dominantMood = dominant?.mood
        dominance = dominant?.dominance ?? 0
        let mood = MindGraph.averageEnergy(of: store.entries)
        energyValue = mood * min(1 + log2(CGFloat(store.entries.count) + 1) * 0.12, 1.7)
        selectedID = nil
        focusCategory = nil
        showAll = false
        camera.reset()
        camera.waveTarget = colorMode == .wave ? 1 : 0
        zoomStart = 1
        dragStartPan = .zero
    }
}

#Preview {
    ZStack {
        BackgroundOrbs()
        MindView(store: Store())
    }
}
